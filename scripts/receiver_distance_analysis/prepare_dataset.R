##
## Derive distance matrix for a given set of receivers within the boundaries
## af the provided water bodies - execution
##
## Van Hoey S., Oldoni D.
## Oscibio - INBO (LifeWatch project)
## 2016-2020

library("sp")
library("rgeos")
library("raster")
library("mapview")
library("leaflet")

# --------------------
# INTRODUCTION
# --------------------

# Define the projection for the analysis:
coordinate_epsg <- 32631

# Load the functionalities from the functions file:
source("receiver_distance_fun.R")

# --------------------
# LOAD SHAPEFILES
# --------------------


# 2015 PHD VERHELST EEL
zeeschelde_dijle <- load.shapefile("./data/Belgium_Netherlands/zeeschelde_dijle.shp",
                       "zeeschelde_dijle",
                       coordinate_epsg)
plot(zeeschelde_dijle$geometry)

ws_bpns <- load.shapefile("./data/Belgium_Netherlands/ws_bpns.shp",
                       "ws_bpns",
                       coordinate_epsg)
plot(ws_bpns$geometry)

# Validate waterbodies
zeeschelde_dijle <- validate_waterbody(zeeschelde_dijle)
ws_bpns <- validate_waterbody(ws_bpns)

# Combine shapefiles
zeeschelde_dijle$origin_shapefile = "zeeschelde_dijle"
ws_bpns$origin_shapefile = "ws_bpns_sf"

ws_bpns <- 
  ws_bpns %>%
  dplyr::select(Id, origin_shapefile, geometry)
zeeschelde_dijle <- 
  zeeschelde_dijle %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(zeeschelde_dijle, ws_bpns)

plot(study.area)

#### Chunk underneath becomes redundant when above code works ####
# river section
river.names <- c("Schelde", "Durme", "Rupel", "Netekanaal",
                 "Albertkanaal", "Royerssluis", "Leopolddok",
                 "Amerikadok", "Vijfde Havendok", "Kanaaldok B3", "Delwaidedok",
                 "Schelde-Rijnkanaal", "Berendrechtsluis", "Hansadok",
                 "Kanaaldok B2", "Schelde-Rijn Kanaal",
                 "Zandvlietsluis", "Ringvaart", "Tijarm",
                 "Kanaal van Gent naar Oostende")
                ## for future usage:
                # "Meuse", "Juliana Kanaal", "Canal Albert", "Demer", "Dijle"

rivers <- load.shapefile("./data/lowcountries_water/LowCountries_Water_2004.shp",
                         "LowCountries_Water_2004",
                         projection = coordinate_epsg,
                         subset.names = river.names,
                         name_col = "NAME")

# Nete Section (precompiled as Europe entire file is very large)
nete <- load.shapefile("./data/europe_water/nete.shp",
                       "nete",
                       coordinate_epsg,
                       subset.names = NULL)
## to restart from the entire Europe shapefile:
## nete <- load.shapefile("./data/europe_water/Europe_Water_2008.shp",
##                        "Europe_Water_2008",
##                        projection_code,
##                        c("Nete", "Grote Nete"))

# Westerschelde
westerschelde <- load.shapefile("./data/westerschelde_water/seavox_sea_area_polygons_v13.shp",
                                "seavox_sea_area_polygons_v13",
                                coordinate_epsg)

# Belgian part of the North Sea
sea <- load.shapefile("./data/PJ_manual_water/PJ_ontbrekende_stukken_reduced.shp",
                                "PJ_ontbrekende_stukken_reduced",
                                coordinate_epsg)

# Validate waterbodies
rivers <- validate_waterbody(rivers)
nete <- validate_waterbody(nete)
westerschelde <- validate_waterbody(westerschelde)
sea <- validate_waterbody(sea)

#' Combine shapefiles - Same geometry? Use gUnion()
study.area <- gUnion(as_Spatial(rivers), as_Spatial(nete))
study.area <- gUnion(study.area, as_Spatial(westerschelde))
study.area <- gUnion(study.area, as_Spatial(sea))
study.area <- st_as_sf(study.area)

#### ####


# 2012 LEOPOLDKANAAL
leopoldkanaal <- load.shapefile("./data/Belgium_Netherlands/leopoldkanaal.shp",
                                   "leopoldkanaal",
                                   coordinate_epsg)
plot(leopoldkanaal$geometry)

ws_bpns <- load.shapefile("./data/Belgium_Netherlands/ws_bpns.shp",
                          "ws_bpns",
                          coordinate_epsg)
plot(ws_bpns$geometry)

# Validate waterbodies
leopoldkanaal <- validate_waterbody(leopoldkanaal)
ws_bpns <- validate_waterbody(ws_bpns)

# Combine shapefiles
leopoldkanaal$origin_shapefile = "leopoldkanaal"
ws_bpns$origin_shapefile = "ws_bpns_sf"

ws_bpns <- 
  ws_bpns %>%
  dplyr::select(Id, origin_shapefile, geometry)
leopoldkanaal <- 
  leopoldkanaal %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(leopoldkanaal, ws_bpns)

plot(study.area)



# RIVER FROME (UK)
frome <- load.shapefile("./data/UK/Frome/frome.shp",
                         "frome",
                         coordinate_epsg)
plot(frome)

# RIVER STOUR (UK)
stour <- load.shapefile("./data/UK/Stour/stour.shp",
                        "stour",
                        coordinate_epsg)

# RIVER NENE (UK)
nene <- load.shapefile("./data/UK/Nene/nene.shp",
                        "nene",
                        coordinate_epsg)


# RIVER WARNOW (GERMANY)
warnow <- load.shapefile("./data/Germany/warnow.shp",
                         "warnow",
                         coordinate_epsg)

# RIVER GUDENA (DENMARK)
gudena <- load.shapefile("./data/Denmark/rivers.shp",
                         "rivers",
                         coordinate_epsg)

gudena <- gudena[gudena$rivers_id %in% c(12,22),]
plot(gudena)

# RIVER MONDEGO (PORTUGAL)
mondego <- load.shapefile("./data/Portugal/Mondego.shp",
                         "Mondego",
                         coordinate_epsg)
plot(mondego)

# RIVERS SEMP PROJECT (LITHUANIA)
curonian_lagoon <- load.shapefile("./data/Lithuania/curonian_lagoon.shp",
                          "curonian_lagoon",
                          coordinate_epsg)
main <- load.shapefile("./data/Lithuania/Rivers.shp",
                                  "Rivers",
                                  coordinate_epsg)
zeimena <- load.shapefile("./data/Lithuania/Zeimena.shp",
                                  "Zeimena",
                                  coordinate_epsg)

# Validate waterbodies
curonian_lagoon <- validate_waterbody(curonian_lagoon)
main <- validate_waterbody(main)
zeimena <- validate_waterbody(zeimena)

#' Combine shapefiles - Same geometry? Use gUnion()
semp <- gUnion(as_Spatial(curonian_lagoon), as_Spatial(main))
semp <- gUnion(semp, as_Spatial(zeimena))
semp <- st_as_sf(semp)

plot(semp)


# EMMN project - Alta fjord Norway
emmn <- load.shapefile("./data/Norway/alta.shp",
                          "alta",
                          coordinate_epsg)

plot(emmn)


# ESGL & 2011_loire project
esgl <- load.shapefile("./data/France/loire_final.shp",
                       "loire_final",
                       coordinate_epsg)

plot(esgl)


# 2017_fremur project
fremur <- load.shapefile("./data/France/fremur.shp",
                       "fremur",
                       coordinate_epsg)

plot(fremur)



# 2019_Grotenete
grotenete <- load.shapefile("./data/Belgium_Netherlands/grotenete_zeeschelde.shp",
                                   "grotenete_zeeschelde",
                                   coordinate_epsg)
plot(grotenete)



# -----------------------
# SET STUDY AREA
# -----------------------
#study.area <- study.area  # When the LifeWatch network is taken into account; sea 'Combine the shape files'
study.area <- warnow

# ----------------
# LOAD DETECTION STATION NETWORK
# ----------------

# LifeWatch network
#locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_20160526.csv",
#                                      coordinate_epsg)

# PhD Verhelst eel
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2015_phd_verhelst_eel.csv",
  projection = coordinate_epsg
)

# 2012 Leopoldkanaal
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2012_leopoldkanaal.csv",
  projection = coordinate_epsg
)

# Frome network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2014_Frome.csv",
  projection = coordinate_epsg
)

# Stour network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2013_Stour.csv",
  coordinate_epsg
)

# Nene network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2014_Nene.csv",
  coordinate_epsg
)

# Warnow network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2011_Warnow.csv",
  coordinate_epsg
)

# Gudena network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2004_Gudena.csv",
  coordinate_epsg
)

# Mondego network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_PTN-Silver-eel-Mondego.csv",
  coordinate_epsg
)

# SEMP network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_SEMP.csv",
  coordinate_epsg
)

# EMMN network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_EMMN.csv",
  coordinate_epsg
)

# ESGL network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_ESGL.csv",
  coordinate_epsg
)

# 2011_loire network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2011_loire.csv",
  coordinate_epsg
)

# 2017_fremur network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2017_Fremur.csv",
  coordinate_epsg
)

# 2019_Grotenete network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2019_Grotenete_2.csv",
  coordinate_epsg
)


# Michimit network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_michimit.csv",
  coordinate_epsg
)



# ----------------
# PROJECT RECEIVERS ON WATER SHAPEFILE
# ----------------

# Sometimes the receivers position is way too far from river shapefile and so
# the distance among receivers can be misleading. We find the nearest point to
# location receivers on the river shapefile (orthogonal projection)
# Receivers inside the river body will not be projected

# for study area combined by two study areas made of polygons and lines 
projections.locations.receivers <- find.projections.receivers(
  shape.study.area = leopoldkanaal,
  receivers = locations.receivers,
  projection = coordinate_epsg,
  shape.study.area2 = ws_bpns, 
  shape.study.area_merged = study.area
)

# for homogeneous study areas
projections.locations.receivers <- find.projections.receivers(
  shape.study.area = warnow,
  receivers = locations.receivers,
  projection = coordinate_epsg
)

# ------------------------
# CREATE PLOT TO CHECK ALL NECESSARY WATERWAYS ARE INCLUDED
# ------------------------
# for study.area with all same geometries
mapView(study.area, map.types = "OpenStreetMap") +
mapView(locations.receivers, col.regions = "red", map.types = "OpenStreetMap",
        label = locations.receivers$station_name) +
  mapView(projections.locations.receivers,
          col.regions = "white",
          map.types = "OpenStreetMap",
          label = projections.locations.receivers$station_name)

# for study.area with mixed polygons and lines
leaflet(leopoldkanaal %>% st_transform(crs = 4326)) %>%
  addTiles(group = "OSM (default)") %>%
  addPolylines() %>%
  addPolygons(data = ws_bpns %>% st_transform(4326)) %>%
  addCircleMarkers(data = locations.receivers %>% st_transform(4326),
                   radius = 3,
                   color = "red",
                   label = ~station_name,
                   group = "receivers") %>%
  addCircleMarkers(data = projections.locations.receivers %>% 
                     st_transform(4326),
                   radius = 3,
                   color = "white",
                   label = ~station_name,
                   group = "projection receivers") %>%
  addLayersControl(
    baseGroups = "OSM (default)",
    overlayGroups = c("receivers", "projection receivers"),
    options = layersControlOptions(collapsed = FALSE)
  )

# ------------------------
# CONVERT SHAPE TO RASTER
# ------------------------
res <- 50 # pixel is a square:  res x res (in meters)

# First time running the following function can give an error that can be ignored. The code will provide the output anyway. See stackoverflow link for more info about the bug.
#https://stackoverflow.com/questions/61598340/why-does-rastertopoints-generate-an-error-on-first-call-but-not-second

# for a homogenous study area
study.area.binary <- shape.to.binarymask(
  shape.study.area = study.area,
  receivers = projections.locations.receivers,
  resolution = res)

# for a study area which is a combination of polygons and lines
study.area.binary <- shape.to.binarymask(
  shape.study.area = leopoldkanaal,
  shape.study.area2 = ws_bpns,
  shape.study.area_merged = study.area,
  receivers = projections.locations.receivers,
  resolution = res)


# --------------------------------
# ADJUST MASK TO CONTAIN RECEIVERS
# --------------------------------
#
study.area.binary.extended <- adapt.binarymask(binary.mask = study.area.binary,
                                               receivers = projections.locations.receivers)

# write this to disk for loading in e.g. QGIS
writeRaster(study.area.binary.extended, "./results/study_area_binary", "GTiff",
            overwrite = TRUE)

# remove study.area.binary raster (not needed anymore) to free some memory
remove(study.area.binary)

# -------------------------------
# Derive distances with gdistance
# -------------------------------
cst.dst.frame_corrected <- get.distance.matrix(
  binary.mask = study.area.binary.extended,
  receivers = projections.locations.receivers
)
# inspect distance output
cst.dst.frame_corrected
# save distances
write.csv(cst.dst.frame_corrected, "./results/distances_2011_warnow.csv")


# IDEA ...
# Could be interesting to compare these values with the commute distances:
# see: https://cran.r-project.org/web/packages/gdistance/vignettes/gdistance1.pdf
# commute.dst <- commuteDistance(tr_geocorrected, matched.receivers)
# By running many paths and extracting average statistics about the distance a
# more in-depth insight in travel distance could be achieved
