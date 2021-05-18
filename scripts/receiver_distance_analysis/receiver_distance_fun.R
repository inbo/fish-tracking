##
## Derive distance matrix for a given set of receivers within the boundaries
## af the provided water bodies - support functions
##
## Van Hoey S., Oldoni D.
## Oscibio - INBO (LifeWatch project)
## 2016-2020

library("sp")
library("sf")
library("geosphere")
library("rgdal")
library("rgeos")
library("raster")
library("gdistance")
library("assertthat")
library("glue")

## --------------------------------------------
## General functionalities
## --------------------------------------------

#' Load shapefile
#'
#' Load a shapefile, subselect the required elements and
#' transform to the given projection
#'
#' @param file filename of the shapefile (absolute or relative path)
#' @param layer layer of the shapefile to select (check e.g. in qgis in the properties of the file)
#' @param subset.names list of names to subselect from NAME column
#' @param projection proj4string like string defining the projection, or
#' define the projection with the EPSG code: e.g. CRS("+init=epsg:32631")
#'
#' @return SpatialPolygonsDataFrame
#' @export
#'
#' @examples
#' nete <- load.shapefile("./data/europe_water/nete.shp", "nete",
#'                        coordinate.string, subset.names = NULL)
load.shapefile <- function(file, layer, projection, subset.names = NULL) {
    waterbody <- readOGR(dsn = file,
                         layer = layer)
    if (!is.null(subset.names)) {
        waterbody.subset <- subset(waterbody, NAME %in% subset.names)
    } else {
        waterbody.subset <- waterbody
    }

    waterbody.subset <- spTransform(waterbody.subset, projection)
    return(waterbody.subset)
}

#' Load receiver info
#'
#' Load the receivers information and transform to chosen projection
#'
#' @param file filename of CSV containing receiver info
#' @param projection proj4string like string defining the projection, or
#' define the projection with the EPSG code: e.g. CRS("+init=epsg:32631")
#'
#' @return SpatialPointsDataFrame
#' @export
#'
#' @examples
#' locations.receivers <- load.receivers("./data/receivernetwork_20160526.csv",
#'                                       coordinate.string)
load.receivers <- function(file, projection){
    loc <- read.csv(file, header = TRUE, stringsAsFactors = FALSE)

    # project coordinates
    loc[, c("longitude", "latitude")] <- project(as.matrix(loc[, c("longitude", "latitude")]),
                                                 as.character(projection))

    locations.receivers <- SpatialPointsDataFrame(coords = loc[, c("longitude","latitude")],
                                                  data = loc,
                                                  proj4string = projection)
    return(locations.receivers)
}

#' Find the receiver projection on river body shapefile
#'
#' @param shape.study.area a shapefile (sp object), lines or polygons, of the
#'   river body
#' @param receivers SpatialPointsDataFrame
#' @param projection a projection string, the CRS of both river body and
#'   receivers
#'
#' @return SpatialPointsDataFrame
#' @export
#'
#' @examples
#' find.projections.receivers(shape.study.area = study.area,
#'   receivers = locations.receivers,
#'   projection = coordinate.string)
find.projections.receivers <- function(shape.study.area,
                                       receivers,
                                       projection) {
    # transform to sf because it is much easier to get coordinates out of sf than sp
    # objects
    shape.study.area <- st_as_sf(shape.study.area)

    # calculate nearest point to line/polygon (transform to CRS 4326 first)
    # this is done using crs 4326
    dist_receiver_river <- dist2Line(
        p = spTransform(receivers, CRS("+init=epsg:4326"))@coords,
        line = st_coordinates(st_transform(shape.study.area, crs = 4326))[,1:2]
    )

    projections.receivers <- st_as_sf(
        as.data.frame(dist_receiver_river),
        coords = c("lon", "lat"),
        crs = 4326)

    # add columns with receivers info to projections
    projections.receivers$animal_project_code <- receivers@data$animal_project_code
    projections.receivers$station_name <- receivers@data$station_name
    # transform sf to sp object
    projections.receivers <- as_Spatial(projections.receivers)

    # transform back to original CRS and return
    spTransform(projections.receivers, projection)
}

#' Spatial objects to binary raster
#'
#' Convert (river) shapes (polygons or lines) to a raster binary image. As
#' receivers (points) could be out of the boundaries of the river shape, we need
#' them to be sure to include them in the binary raster.
#'
#' @param shape.study.area SpatialPolygonsDataFrame or SpatialLinesDataFrame to
#'   convert to raster
#' @param receivers SpatialPointsDataFrame to convert to raster
#' @param nrows number of rows to use in the raster
#' @param ncols number of columns to use in the raster
#'
#' @return RasterLayer
#' @export
#'
#' @examples
shape.to.binarymask <- function(shape.study.area, receivers,  nrows, ncols){
    # get extents rivers and receivers
    extent_river <- extent(shape.study.area)
    extent_receivers <- extent(receivers)
    # merge extents
    extent_for_raster <- merge(extent_receivers, extent_river)
    # convert to a binary raster image
    r <- raster(nrow = nrows, ncol = ncols, crs = shape.study.area@proj4string)
    extent(r) <- extent_for_raster
    # we use getcover to make sure we have the entire river captured:
    study.area.binary <- rasterize(shape.study.area, r, 1., getCover = TRUE)
    # make binary: set all non zero to 1
    study.area.binary[study.area.binary > 0] <- 1
    # make binary: set NA to 0
    study.area.binary[is.na(study.area.binary)] <- 0
    return(study.area.binary)
}

## --------------------------------------------
## Functions as support for the mask adaptation
## to ensure the incorporation of the receivers
## --------------------------------------------

#' cell number to row/col index
#'
#' Transform cell number to row/col indices
#' (support function for adapt.binarymask)
#'
#' @param ids cell number in matrix
#' @param nrows number of rows of the matrix
#'
#' @return (id of row, id of column)
#'
#' @examples
get_rowcol <- function(ids, nrows){
    rem <- ids %% nrows
    if (rem == 0) {
        row <- nrows
        col <- ids %/% nrows
    } else {
        row <- ids %% nrows
        col <- (ids %/% nrows) + 1
    }
    rowcol <- c(row, col)
    return(rowcol)
}

#' Extend small patches
#'
#' Change a mooring environment to 1 values around the provided cell ids
#' (support function for adapt.binarymask)
#'
#' @param inputmat RasterLayer to adjust the cells from
#' @param ids the identifiers defining the cells for which the environment is
#' added
#'
#' @return RasterLayer
#'
#' @examples
extend_patches <- function(inputmat, ids){
    # inputmat -> matrix
    ncols <- ncol(inputmat)
    nrows <- nrow(inputmat)
    crdnts <- sapply(ids, get_rowcol, nrows)
    for (i in 1:ncol(crdnts) ) {
        row = crdnts[1, i]
        col = crdnts[2, i]

        inputmat[row, col] <- 1
        if (col > 1) {
            inputmat[row , col - 1] <- 1
        }
        if (col < ncols) {
            inputmat[row , col + 1] <- 1
        }

        if (row > 1) {
            inputmat[row - 1, col] <- 1
            if (col > 1) {
                inputmat[row - 1, col - 1] <- 1
            }
            if (col < ncols) {
                inputmat[row - 1, col + 1] <- 1
            }
        }

        if (row < nrows) {
            inputmat[row + 1, col] <- 1
            if (col > 1) {
                inputmat[row + 1, col - 1] <- 1
            }
            if (col < ncols) {
                inputmat[row + 1, col + 1] <- 1
            }
        }
    }
    return(inputmat)
}

#' Get patch info
#'
#' Extract the information about the patches and their respective sizes
#' (support function for adapt.binarymask)
#'
#' @param inputlayer RasterLayer for which to extract the patch information
#'
#' @return vector with zone id and the number of cells for each zone
#' @export
#'
#' @examples
#' get_patches_info(study.area.binary)
get_patches_info <- function(binary.raster){
    # detect clumps (patches) of connected cells
    patch_count <- clump(binary.raster)
    # derive surface (cell count) for each patch
    patch_cells <- zonal(binary.raster, patch_count, "sum")
    # sort to make last row main one and return
    patch_cells[sort.list(patch_cells[, 2]),, drop = FALSE]
}

#' Check patch characteristics
#'
#' Control the charactersitics of the binary mask: 1. patch of connected cells
#' 2. all receivers are within the patch
#'
#' @param binary.mask RasterLayer with the patch(es) of waterbodies
#' @param receivers SpatialPointsDataFrame with receiver location info
#' @param n_patches.mask number of patches of waterbodies (before extension to
#'   include receivers)
#'
#' @return TRUE if both tests are valid
#' @export
#'
#' @examples
control.mask <- function(binary.mask, receivers, n_patches.mask){
    match_ids <- raster::extract(binary.mask, receivers)
    match_ids[is.na(match_ids)] <- 0
    matched.receivers <- receivers[as.logical(match_ids), ]
    # CHECK:
    assert_that(length(receivers) == length(matched.receivers))

    # Check number of clumps of binary.mask
    clumps_binary.mask <- clump(binary.mask)
    # at least one clump is present
    assert_that(cellStats(clumps_binary.mask, stat = 'min', na.rm = TRUE) == 1,
                msg = "At least one clump (patch) must be present")
    # number of clumps should be the same as the initial number of clumps before
    # adding receivers (typically 1 if all river bodies are connected)
    assert_that(
        cellStats(clumps_binary.mask, stat = 'max', na.rm = TRUE) == n_patches.mask,
        msg = "Number of clumps (patches) not equal to initial number of patches"
    )
}

#' Extend binary mask
#'
#' Extend the binary mask to incorporate the receivers itself into the mask.
#' Receivers are in the mask if the number of clumps (patches) of connected
#' cells is equal to one.
#'
#' @param binary.mask RasterLayer (0/1 values)
#' @param receivers SpatialPointsDataFrame
#'
#' @return RasterLayer
#' @export
#'
#' @examples
adapt.binarymask <- function(binary.mask, receivers){

    # get initial number of patches  and their respective sizes (start point)
    # if the entire study area is connected then we have one patch
    patchCells <- get_patches_info(binary.mask)
    n_patches.mask <- nrow(patchCells)
    message(glue("Number of patches of binary.mask (river body): {n_patches.mask}"))
    if (n_patches.mask > 1) {
        message("The binary.mask (river body) is not connected. Extension needed")
    }
    # add locations itself to raster as well:
    locs2ras <- rasterize(receivers, binary.mask, 1.)
    locs2ras[is.na(locs2ras)] <- 0
    binary.mask <- max(binary.mask, locs2ras)

    # extract the information about the patches and their respective sizes
    # detect initial clumps (patches) of connected cells
    patchCount <- clump(binary.mask)
    # derive surface (cell count) for each patch of mask
    patchCells <- zonal(binary.mask, patchCount, "sum")
    # sort to make last row main one and return
    patchCells <- patchCells[sort.list(patchCells[, 2]),, drop = FALSE]
    # check initial number of patches
    n.patches <- nrow(patchCells)
    n.patches <- nrow(patchCells)
    message(glue("Number of patches after adding receivers: {n.patches}"))

    if (n.patches == n_patches.mask) {
        message("No binary mask extension needed.")
    }
    while (n.patches > n_patches.mask) {
        # first row indexes of the single patches extended
        ids <- which(as.matrix(patchCount) == patchCells[1, 1])
        temp <- as.matrix(binary.mask)
        temp <- extend_patches(temp, ids)
        binary.mask <- raster(temp, template = binary.mask)

        # detect clumps (patches) of connected cells
        patchCount <- clump(binary.mask)
        # derive surface (cell count) for each patch
        patchCells <- zonal(binary.mask, patchCount, "sum")
        # sort to make last row main one and return
        patchCells <- patchCells[sort.list(patchCells[, 2]),, drop = FALSE]
        # get current number of patches
        n.patches <- nrow(patchCells)
        message(glue("Number of patches: {n.patches}"))
        if (n.patches == n_patches.mask) {
            message("Done: all receivers included")
        }
    }
    # Control the mask characteristics and receiver location inside mask:
    # (if an error occurs, this need to be checked before deriving distances)
    control.mask(binary.mask, receivers, n_patches.mask)
    return(binary.mask)
}

#' Get distance matrix
#'
#' Calculate the cost distance matrix of the receivers
#'
#' @param binary.mask RasterLayer with the patch of waterbodies
#' @param receivers SpatialPointsDataFrame with receiver location info
#'
#' @return data.frame
#' @export
#'
#' @examples
get.distance.matrix <- function(binary.mask, receivers){
    tr <- transition(binary.mask, max, directions = 8)
    tr_geocorrected <- geoCorrection(tr, type = "c")

    cst.dst <- costDistance(tr_geocorrected, receivers)
    cst.dst.arr <- as.matrix(cst.dst)
    receiver_names <- receivers$station_name
    rownames(cst.dst.arr) <- receiver_names
    colnames(cst.dst.arr) <- receiver_names
    return(as.data.frame(cst.dst.arr))
}





