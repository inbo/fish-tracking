##
## Derive distance matrix for a given set of receivers within the boundaries
## af the provided water bodies - support functions
##
## Van Hoey S., Oldoni D.
## Oscibio - INBO (LifeWatch project)
## 2016-2020

library("sp")
library("sf")
library("terra")
library("rgdal")
library("rgeos")
library("raster")
library("gdistance")
library("assertthat")
library("glue")
library("rlang")
library("dplyr")
library(purrr)

## --------------------------------------------
## General functionalities
## --------------------------------------------

#' Load shapefile
#'
#' Load a shapefile, subselect the required elements and
#' transform to the given projection
#'
#' @param file filename of the shapefile (absolute or relative path)
#' @param layer layer of the shapefile to select (check e.g. in qgis in the
#'   properties of the file)
#' @param projection projection defined as a EPSG number, e.g. 4326
#' @param subset.names list of names to filter from a column, whose name is defined in `name_col`. Default: `NULL`
#' @param name_col character with column name to use for filtering based on
#'   `subset.names`. Default: `NULL`
#' @return a simple feature (sf) data.frame
#' @export
#'
#' @examples
#' crs_system <- 32631
#' nete <- load.shapefile("./data/europe_water/nete.shp", "nete", crs_cystem)
#' river.names <- c("Schelde", "Durme", "Rupel", "Netekanaal")
#' rivers <- load.shapefile(
#'   file = "./data/lowcountries_water/LowCountries_Water_2004.shp",
#'   layer = "LowCountries_Water_2004",
#'   crs_cystem,
#'   subset.names = river.names,
#'   name_col = "NAME")
load.shapefile <- function(file,
                           layer,
                           projection, 
                           subset.names = NULL,
                           name_col = NULL) {
    assert_that((is.null(subset.names) & is.null(name_col)) |
                    (!is.null(subset.names) & !is.null(name_col)),
                msg = "subset.names and name_col must be both provided or both NULL (default)")
    waterbody <- st_read(dsn = file, layer = layer)
    if (!is.null(subset.names)) {
        waterbody.subset <- waterbody %>%
            dplyr::filter(!!sym(name_col) %in% subset.names)
    } else {
        waterbody.subset <- waterbody
    }

    waterbody.subset <- st_transform(waterbody.subset, projection)
    return(st_as_sf(waterbody.subset))
}

#' Load receiver info
#'
#' Load the receivers information and transform to chosen projection
#'
#' @param file filename of CSV containing receiver info
#' @param projection projection defined as a EPSG number, e.g. 4326
#' @param original_projection projection used in the csv file, defined as a EPSG number, e.g. 4326. Default: 4326
#' @return a simple feature (sf) data.frame with points (receivers)
#' @export
#'
#' @examples
#' crs_system <- 32631
#' locations.receivers <- load.receivers("./data/receivernetwork_20160526.csv",
#'                                       crs_system)
load.receivers <- function(file, projection, original_projection = 4326){
    loc <- read.csv(file, header = TRUE, stringsAsFactors = FALSE)
    locations.receivers <- st_as_sf(loc,
                                   coords = c("longitude","latitude"),
                                   crs = original_projection)
    locations.receivers %>%
        st_transform(projection)
}

#' Validate waterbody shapefile 
#' 
#' This step is a wrapper around sf functions `st_is_valid()` and
#' `st_make_valid()`. It checkse whether a geometry is valid, or makes an
#' invalid geometry valid
#' @param waterbody a simple feature (sf) data.frame , with polygons or lines as
#'   geometry
#' @return the validated version of input `waterbody`
#' @export
#' @examples
#' /dontrun{
#' crs_system <- 32631
#' ws_bpns <- load.shapefile("./data/Belgium_Netherlands/ws_bpns.shp",
#'   "ws_bpns", crs_system
#' )
#' ws_bpns_validated <- validate_waterbody(ws_bpns)
#' 
#' vhag <- load.shapefile("./data/Belgium_Netherlands/Vhag.shp",
#'   "Vhag",
#'   crs_system
#' )
#' vhag_validated <- validate_waterbody(vhag)
#' }
validate_waterbody <- function(waterbody) {
    if (!all((st_is_valid(waterbody)))) {
        message("Waterbody is an invalid shapefile. Make it valid first.")
        waterbody <- st_make_valid(waterbody)
        message(glue("Validation succeded."))
    } else {
        message("Waterbody is a valid shapefile.")
    }
    return(waterbody)
}

#' Find the receiver projection on river body shapefile
#'
#' @param shape.study.area a simple feature (sf) data.frame, with polygons or
#'   lines as geometry
#' @param receivers a simple feature (sf) data.frame with points (receivers)
#' @param projection a EPSG number, the CRS of both river body and
#'   receivers
#' @param shape.study.area2 a simple feature (sf) data.frame, with polygons or
#'   lines as geometry. This is needed if the study area is a combination of
#'   lines and polygons. Default: `NULL`
#' @param shape.study.area_merged a simple feature (sf) data.frame, with the
#'   combinations of polygons and lines as geometry (done via  `rbind` before).
#'   Default: `NULL`
#' @return a simple feature (sf) data.frame with the projected points
#'   (projection of the receivers)
#' @export
#'
#' @examples
#' find.projections.receivers(shape.study.area = study.area,
#'   receivers = locations.receivers,
#'   projection = 32631)
find.projections.receivers <- function(shape.study.area,
                                       receivers,
                                       projection,
                                       shape.study.area2 = NULL,
                                       shape.study.area_merged = NULL) {
    
    assertthat::assert_that((is.null(shape.study.area2) & is.null(shape.study.area_merged)) |
                    (!is.null(shape.study.area2) & !is.null(shape.study.area_merged)),
                msg = "Second shape study area and merged shape study area must be both provided or both NULL")
    
    assertthat::assert_that(
      st_crs(shape.study.area) != st_crs(4326),
      msg = paste("shape.study.area must have a planar projection (x, y).",
                  "No lon/lat projection (EPSG=4326, WGS84) allowed.")
    )
    
    assertthat::assert_that(
      st_crs(receivers) != st_crs(4326),
      msg = paste("receivers must have a planar projection (x, y).",
                  "No lon/lat projection (EPSG=4326, WGS84) allowed.")
    )

    if (!is.null(shape.study.area2) & !is.null(shape.study.area_merged)) {
      assertthat::assert_that(
        st_crs(shape.study.area2) != st_crs(4326),
        msg = paste("shape.study.area2 must have a planar projection (x, y).",
                    "No lon/lat projection (EPSG=4326, WGS84) allowed.")
      )
      assertthat::assert_that(
        st_crs(shape.study.area_merged) != st_crs(4326),
        msg = paste(
          "shape.study.area_merged must have a planar projection (x, y).",
          "No lon/lat projection (EPSG=4326, WGS84) allowed."
        )
      )
    }
    
    # transform to sf because it is much easier to complete some tasks
    # afterwards
    # shape.study.area <- st_as_sf(shape.study.area)

    # receivers_sf <- st_as_sf(receivers)
    # remove(receivers)

    # calculate nearest point to line/polygon (transform to CRS 4326 first)
    # this is done using crs 4326
    
    # Apply st_coordinates row by row as it could be that shape.study.area is a
    # mix of lines, multilines, polygons and multipolygons
    shape.study.area_coords <- purrr::map(
      1:nrow(shape.study.area), 
      function(x) {
        sf::st_coordinates(shape.study.area[x,])[,1:2]
      }
    )
    shape.study.area_coords <- do.call(rbind, shape.study.area_coords)
    
    if (!is.null(shape.study.area2)) {
      # Apply st_coordinates row by row as it could be that shape.study.area2 is
      # a mix of lines, multilines, polygons and multipolygons
      shape.study.area2_coords <- purrr::map(
        1:nrow(shape.study.area2), 
        function(x) {
          sf::st_coordinates(shape.study.area2[x,])[,1:2]
        }
      )
      shape.study.area2_coords <- do.call(rbind, shape.study.area2_coords)
      # combine coordinates
      shape.study.area_coords <- rbind(shape.study.area_coords,
                                       shape.study.area2_coords)
    }
    
    shape.study.area_geom <- sf::st_as_sf(
      as.data.frame(shape.study.area_coords), 
      coords = c("X", "Y"), 
      crs = st_crs(study.area)
    )
    
    dist_receiver_river <- terra::nearest(terra::vect(receivers), 
                                          terra::vect(shape.study.area_geom),
                                          centroids = FALSE)
    
    # create projection receivers as sf dataframe
    projections.receivers <- st_as_sf(
        as.data.frame(dist_receiver_river),
        coords = c("lon", "lat"),
        crs = 4326)

    # remove distance column from projections
    projections.receivers$distance <- NULL

    # add columns with receivers info to projections
    if ("animal_project_code" %in% names(receivers)) {
        projections.receivers$animal_project_code <- receivers$animal_project_code
    }
    if ("station_name" %in% names(receivers)) {
        projections.receivers$station_name <- receivers$station_name
    }
    coords_projections <- st_coordinates(projections.receivers)
    if ("latitude" %in% names(receivers)) {
        projections.receivers$latitude <- coords_projections[, "Y"]
    }
    if ("longitude" %in% names(receivers)) {
        projections.receivers$longitude <- coords_projections[, "X"]
    }
    # Do receivers and their projections the same number of columns?
    assert_that(ncol(receivers) == ncol(projections.receivers))
    # Are all columns in receivers in projections.receivers as well?
    assert_that(all(names(receivers) %in% names(projections.receivers)))

    # set order columns projections equal to order of cols of receivers
    projections.receivers <- projections.receivers[, names(receivers)]


    # intersect receivers and river body study area
    # intersection has to be done in a planar projection
    receivers <- st_transform(receivers, crs = projection)
    if (!is.null(shape.study.area_merged)) {
        shape.study.area <- shape.study.area_merged
    }
    shape.study.area <-  st_transform(shape.study.area, crs = projection)
    projections.receivers <- st_transform(projections.receivers, crs = projection)

    receivers_are_included <- st_intersects(receivers, shape.study.area)

    # check validity of intersection result
    assert_that(length(receivers_are_included) ==
                    nrow(receivers),
                msg = "Result of intersection not equal to number of receivers")

    # are the receivers IN the river body?
    for (i in 1:nrow(receivers_are_included)) {
        if (length(receivers_are_included[[i]]) != 0) {
            # receiver is IN the river body
            projections.receivers[i,] <- receivers[i,]
            if ("station_name" %in% names(receivers)) {
                station_name <- projections.receivers[i,]$station_name
                msg <- glue("Receiver station {station_name} is in the water",
                            " body. No projection needed")
            } else {
                msg <- glue("Receiver station {i} is in the water body.",
                            " No projection needed")
            }
        } else {
            # receiver is NOT IN the river body
            if ("station_name" %in% names(receivers)) {
                station_name <- projections.receivers[i,]$station_name
                msg <- glue("Receiver station {station_name} is not in the",
                            " water body and will be projected on it.")
            }  else {
                msg <- glue("Receiver station {i} is not in the water body",
                            " and will be projected on it.")
            }
        }
        message(msg)
    }

    return(projections.receivers)
}

#' Simple feature (sf) data.frame to binary raster
#'
#' Convert (river) simple features (polygons or lines) to a raster binary image.
#' As receivers (points) could be out of the boundaries of the river shape, we
#' need them to be sure to include them in the binary raster.
#'
#' @param shape.study.area a simple feature (sf) data.frame to convert to
#'   raster. Geometry column can be polygons or lines
#' @param receivers a simple feature (sf) data.frame (points)
#' @param resolution pixel side in meters (numeric)
#' @param shape.study.area2 a simple feature (sf) data.frame, with polygons or
#'   lines as geometry. This is needed if the study area is a combination of
#'   lines and polygons. Default: `NULL`
#' @param shape.study.area_merged a simple feature (sf) data.frame, with the
#'   combinations of polygons and lines as geometry (done via  `rbind` in a
#'   previous step). Default: `NULL`
#' @return a RasterLayer
#' @export
#'
#' @examples
shape.to.binarymask <- function(shape.study.area, receivers,  resolution,
                                shape.study.area2 = NULL,
                                shape.study.area_merged = NULL){
    # checks
    assert_that((is.null(shape.study.area2) & is.null(shape.study.area_merged)) |
                    (!is.null(shape.study.area2) & !is.null(shape.study.area_merged)),
                msg = "Second shape study area and merged shape study area must be both provided or both NULL")
    if (!is.null(shape.study.area2)) {
        assert_that(
            st_crs(shape.study.area) == st_crs(shape.study.area2) & 
                st_crs(shape.study.area) == st_crs(shape.study.area_merged),
            msg = "Shape study area must have the same CRS")
    }
    
    # get extent of the total shape study area
    if (is.null(shape.study.area_merged)) {
        extent_river <- extent(shape.study.area)
        bbox <- st_bbox(shape.study.area)
    } else {
        extent_river <- extent(shape.study.area_merged)
    }
    
    # get extent receivers and merge it with extent rivers
    extent_receivers <- extent(receivers)
    extent_for_raster <- merge(extent_receivers, extent_river)
    
    # calculate number of rows, columns and actual resolution
    x_size <- extent_for_raster[2] - extent_for_raster[1]
    y_size <- extent_for_raster[4] - extent_for_raster[3]
    nrows <- round(y_size / resolution)
    ncols <- round(x_size / resolution)
    
    # create a template  raster for the total study area to get the right extent
    # and origin
    r <- raster(extent_for_raster,
                nrow = nrows,
                ncols = ncols,
                crs = as_Spatial(shape.study.area[1,])@proj4string)
    # get actual resolution
    res_r <- res(r)
    message(paste("Actual pixel resolution (x,y):",
                  paste0(res_r, collapse = ","),
                  "(meters)"))
    
    # we use getcover to make sure we have the entire study area captured
    message("Rasterizing the shape study area...")
    study.area.binary <- rasterize(x = shape.study.area,
                                   y = r, 1., getCover = TRUE)
    origin(study.area.binary) <- origin(r)
    message("Rasterizing the shape study area completed")
    # make binary: set all non zero to 1
    study.area.binary[study.area.binary > 0] <- 1
    # make binary: set NA to 0
    study.area.binary[is.na(study.area.binary)] <- 0
    if (!is.null(shape.study.area2)) {
        # convert to a binary raster image
        message("Rasterizing the second shape study area...")
        study.area.binary2 <- rasterize(x = shape.study.area2,
                                       y = r, 1., getCover = TRUE)
        origin(study.area.binary2) <- origin(r)
        message("Rasterizing the second shape study area completed")
        # make binary: set all non zero to 1
        study.area.binary2[study.area.binary2 > 0] <- 1
        # make binary: set NA to 0
        study.area.binary2[is.na(study.area.binary2)] <- 0
        # put the binary rasters of the two study areas together
        message("Combine the two shape study areas")
        study.area.binary <- mosaic(study.area.binary,
                                    study.area.binary2,
                                    fun = max)
    }
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
#' @param receivers a simple feature (sf) data.frame (points)
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
#' @param receivers a simple feature (sf) data.frame (points)
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
        msg <- message(
            glue("River body is disconnected. If there are receivers", 
                 "placed in different patches, infinite loops and memory size", 
                 "isues will occur while calculating their distance.",
                 .sep = " ")
        )
        continue <- tolower(readline("Do you want to continue? (Y/n) "))
        if (!continue %in% c("y", "")) {
            return(invisible(NULL))
        }
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
#' @param receivers a simple feature (sf) data.frame (points)
#'
#' @return data.frame
#' @export
#'
#' @examples
get.distance.matrix <- function(binary.mask, receivers){
    tr <- transition(binary.mask, max, directions = 8)
    tr_geocorrected <- geoCorrection(tr, type = "c")

    cst.dst <- costDistance(tr_geocorrected, as_Spatial(receivers))
    cst.dst.arr <- as.matrix(cst.dst)
    receiver_names <- receivers$station_name
    rownames(cst.dst.arr) <- receiver_names
    colnames(cst.dst.arr) <- receiver_names
    return(as.data.frame(cst.dst.arr))
}





