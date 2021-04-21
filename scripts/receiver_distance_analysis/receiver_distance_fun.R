##
## Derive distance matrix for a given set of receivers within the boundaries
## af the provided water bodies - support functions
##
## Van Hoey S., Oldoni D.
## Oscibio - INBO (LifeWatch project)
## 2016-2020

library("sp")
library("sf")
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

    # add locations itself to raster as well:
    locs2ras <- rasterize(receivers, binary.mask, 1.)
    locs2ras[is.na(locs2ras)] <- 0
    binary.mask <- max(binary.mask, locs2ras)

    patch_count <- clump(binary.mask)
    patchCells <- zonal(binary.mask, patch_count, "sum")
    patchCells <- patchCells[sort.list(patchCells[, 2]), , drop = FALSE]
    n.patches <- nrow(patchCells)

    # check current number of patches
    message(glue("Initial number of patches: {n.patches}"))

    while (n.patches > 1) {
        # first row indices of the single patches extended
        ids <- which(as.matrix(patch_count) == patchCells[1, 1])
        temp <- as.matrix(binary.mask)
        temp <- extend_patches(temp, ids)
        binary.mask <- raster(temp, template = binary.mask)

        # patches definition etc
        patch_count <- clump(binary.mask)
        # derive surface (cell count) for each patch
        patchCells <- zonal(binary.mask, patch_count, "sum")
        # sort to make last row main one
        patchCells <- patchCells[sort.list(patchCells[, 2]),, drop = FALSE]
        # check current number of patches
        n.patches <- nrow(patchCells)
        message(glue("Number of patches: {n.patches}"))
        if (n.patches == 1) {
            message("Done: all receivers included")
        }
    }
    return(binary.mask)
}

#' Check patch characteristics
#'
#' Control the charactersitics of the binary mask:
#' 1. patch of connected cells
#' 2. all receivers are within the patch
#'
#' @param binary.mask RasterLayer with the patch of waterbodies
#' @param receivers SpatialPointsDataFrame with receiver location info
#'
#' @return TRUE is both tests are valid
#' @export
#'
#' @examples
control.mask <- function(binary.mask, receivers){
    match_ids <- raster::extract(binary.mask, receivers)
    match_ids[is.na(match_ids)] <- 0
    matched.receivers <- receivers[as.logical(match_ids), ]
    # CHECK:
    assert_that(length(receivers) == length(matched.receivers))

    # Check if area is one big environment without islands
    temp <- clump(binary.mask)
    # a single clump is what we want: min and max should be both == 1
    # CHECK:
    assert_that(cellStats(temp, stat = 'min', na.rm = TRUE) == 1)
    assert_that(cellStats(temp, stat = 'max', na.rm = TRUE) == 1)
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





