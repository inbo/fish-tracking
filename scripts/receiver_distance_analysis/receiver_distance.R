##
## Derive distance matrix for a given set of receivers within the boundaries
## af the provided water bodies - execution
##
## Van Hoey S., Oldoni D.
## Oscibio - INBO (LifeWatch project)
## 2016-2020

library("sf")
library("raster")
library("mapview")
library("leaflet")

# --------------------
# INTRODUCTION
# --------------------

# Define the projection for the analysis:
coordinate_epsg <- 32631

# Shakimardan projection: UTM Zone 42 found using
# https://mangomap.com/robertyoung/maps/69585/#
# Related EPSG code: https://epsg.io/32642
coordinate_epsg <- 32642

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

#' Validate waterbodies before combining them together, 
#' otherwise just validate the study.area
rivers <- validate_waterbody(rivers)
nete <- validate_waterbody(nete)
westerschelde <- validate_waterbody(westerschelde)
sea <- validate_waterbody(sea)

#' Combine shapefiles - Same geometry? Use `sf::st_union()`
study.area <- sf::st_union(rivers, nete)
study.area <- sf::st_union(study.area, westerschelde)
study.area <- sf::st_union(study.area, sea)

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
# Validate waterbodies
frome <- validate_waterbody(frome)


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
semp <- load.shapefile("./data/Lithuania/semp_rivers.shp",
                          "semp_rivers",
                          coordinate_epsg)
plot(semp$geometry)


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

ws_bpns <- load.shapefile("./data/Belgium_Netherlands/ws_bpns.shp",
                          "ws_bpns",
                          coordinate_epsg)
plot(ws_bpns$geometry)

# Validate waterbodies
grotenete <- validate_waterbody(grotenete)
ws_bpns <- validate_waterbody(ws_bpns)

# Combine shapefiles
grotenete$origin_shapefile = "grotenete"
ws_bpns$origin_shapefile = "ws_bpns_sf"

ws_bpns <- 
  ws_bpns %>%
  dplyr::select(Id, origin_shapefile, geometry)
grotenete <- 
  grotenete %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(grotenete, ws_bpns)

plot(study.area)


# DAK SUPERPOLDER
superpolder <- load.shapefile("./data/Belgium_Netherlands/superpolder.shp",
                            "superpolder",
                            coordinate_epsg)
plot(superpolder)

# DAK MARKIEZAATSMEER
zeeschelde_dijle <- load.shapefile("./data/Belgium_Netherlands/zeeschelde_dijle.shp",
                                          "zeeschelde_dijle",
                                          coordinate_epsg)
plot(zeeschelde_dijle$geometry)

markiezaatsmeer <- load.shapefile("./data/Belgium_Netherlands/markiezaatsmeer_westerschelde.shp",
                        "markiezaatsmeer_westerschelde",
                        coordinate_epsg)
plot(markiezaatsmeer$geometry)


# Validate waterbodies
zeeschelde_dijle <- validate_waterbody(zeeschelde_dijle)
markiezaatsmeer <- validate_waterbody(markiezaatsmeer)


# Combine shapefiles
zeeschelde_dijle$origin_shapefile = "zeeschelde_dijle"
markiezaatsmeer$origin_shapefile = "markiezaatsmeer_sf"
markiezaatsmeer <- dplyr::rename(markiezaatsmeer, Id = ID)

markiezaatsmeer <- 
  markiezaatsmeer %>%
  dplyr::select(Id, origin_shapefile, geometry)
zeeschelde_dijle <- 
  zeeschelde_dijle %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(zeeschelde_dijle, markiezaatsmeer)

plot(study.area)



# NOORDZEEKANAAL
noordzeekanaal <- load.shapefile("./data/Belgium_Netherlands/noordzeekanaal_polygons.shp",
                              "noordzeekanaal_polygons",
                              coordinate_epsg)
plot(noordzeekanaal)



# 2013 ALBERTKANAAL
albertkanaal_zeeschelde <- load.shapefile("./data/Belgium_Netherlands/albertkanaal_zeeschelde.shp",
                                   "albertkanaal_zeeschelde",
                                   coordinate_epsg)
plot(albertkanaal_zeeschelde$geometry)

meuse <- load.shapefile("./data/Belgium_Netherlands/meuse_total.shp",
                                   "meuse_total",
                                   coordinate_epsg)
plot(meuse$geometry)


# Validate waterbodies
albertkanaal_zeeschelde <- validate_waterbody(albertkanaal_zeeschelde)
meuse <- validate_waterbody(meuse)


# Combine shapefiles
albertkanaal_zeeschelde$origin_shapefile = "albertkanaal_zeeschelde"
meuse$origin_shapefile = "meuse_sf"
meuse <- dplyr::rename(meuse, Id = ID)

meuse <- 
  meuse %>%
  dplyr::select(Id, origin_shapefile, geometry)
albertkanaal_zeeschelde <- 
  albertkanaal_zeeschelde %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(albertkanaal_zeeschelde, meuse)

plot(study.area)


# life4fish project
meuse <- load.shapefile("./data/Belgium_Netherlands/meuse.shp",
                         "meuse",
                         coordinate_epsg)

plot(meuse)



# 2015 Fint
shad <- load.shapefile("./data/Belgium_Netherlands/shad.shp",
                                   "shad",
                                   coordinate_epsg)
plot(shad$geometry)

shad_marine <- load.shapefile("./data/Belgium_Netherlands/shad_marine.shp",
                          "shad_marine",
                          coordinate_epsg)
shad_marine$Id_2 <- NULL # remove extra id column
shad_marine <- shad_marine %>%   # rename id column
  rename(
    Id = id)
plot(shad_marine$geometry)

# Validate waterbodies
shad <- validate_waterbody(shad)
shad_marine <- validate_waterbody(shad_marine)

# Combine shapefiles
shad$origin_shapefile = "shad"
shad_marine$origin_shapefile = "shad_marine_sf"

shad_marine <- 
  shad_marine %>%
  dplyr::select(Id, origin_shapefile, geometry)
shad <- 
  shad %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(shad, shad_marine)

plot(study.area)


# Reelease project
danish_straits <- load.shapefile("./data/Denmark/danish_straits_final.shp",
                         "danish_straits_final",
                         coordinate_epsg)

plot(danish_straits)


# Michimit
michimit <- load.shapefile("./data/Belgium_Netherlands/michimit_rivers.shp",
                            "michimit_rivers",
                           coordinate_epsg)
plot(michimit$geometry)

ws_bpns <- load.shapefile("./data/Belgium_Netherlands/ws_bpns.shp",
                          "ws_bpns",
                          coordinate_epsg)
plot(ws_bpns$geometry)

# Validate waterbodies
michimit <- validate_waterbody(michimit)
ws_bpns <- validate_waterbody(ws_bpns)

# Combine shapefiles
michimit$origin_shapefile = "michimit"
ws_bpns$origin_shapefile = "ws_bpns_sf"

ws_bpns <- 
  ws_bpns %>%
  dplyr::select(Id, origin_shapefile, geometry)
michimit <- 
  michimit %>% 
  dplyr::select(Id = OIDN, origin_shapefile, geometry)

study.area <- rbind(michimit, ws_bpns)

plot(study.area)


# UK River Wyre
wyre <- load.shapefile("./data/UK/Wyre/wyre.shp",
                                 "wyre",
                                 coordinate_epsg)

plot(wyre)



# nedap_meuse project
nedap_meuse <- load.shapefile("./data/Belgium_Netherlands/nedap_meuse.shp",
                        "nedap_meuse",
                        coordinate_epsg)

plot(nedap_meuse)


# Tyne
river <- load.shapefile("./data/UK/Tyne/Tyne river merged.shp",
                        "Tyne river merged",
                        coordinate_epsg)
plot(river)

estuary <- load.shapefile("./data/UK/Tyne/Tyne_estuary.shp",
                          "Tyne_estuary",
                          coordinate_epsg)

estuary <- estuary %>%
  rename(Id = rbd_id)

plot(estuary$geometry)

# Validate waterbodies
river <- validate_waterbody(river)
estuary <- validate_waterbody(estuary)

# Combine shapefiles
river$origin_shapefile = "river"
estuary$origin_shapefile = "estuary_sf"

estuary <- 
  estuary %>%
  dplyr::select(Id, origin_shapefile, geometry)
river <- 
  river %>% 
  dplyr::select(Id = OBJECTID, origin_shapefile, geometry)

study.area <- rbind(river, estuary)

plot(study.area)



# Shakimardan project
shakimardan <- load.shapefile("./data/Shakimardan/shakimardan_riversystem.shp",
                       "shakimardan_riversystem",
                       coordinate_epsg)

plot(shakimardan)




# Azores Ribeira Cruz
cruz <- load.shapefile("./data/Azores/ribeira_cruz.shp",
                              "ribeira_cruz",
                              coordinate_epsg)

plot(cruz)


# UK River Test
test <- load.shapefile("./data/UK/Test/River_Test.shp",
                       "river_test",
                       coordinate_epsg)

plot(test)



test <- load.shapefile("./data/UK/Test/River_Test.shp",
                       "river_test",
                       coordinate_epsg)
plot(test$geometry)

test_marine <- load.shapefile("./data/UK/Test/test_marine.shp",
                              "test_marine",
                              coordinate_epsg)

test_marine <- test_marine %>%   # rename id column
  rename(
    Id = id)
plot(test_marine$geometry)

# Validate waterbodies
test <- validate_waterbody(test)
test_marine <- validate_waterbody(test_marine)

# Combine shapefiles
test$origin_shapefile = "test"
test_marine$origin_shapefile = "test_marine_sf"

test_marine <- 
  test_marine %>%
  dplyr::select(Id, origin_shapefile, geometry)
test <- 
  test %>% 
  dplyr::select(Id = OBJECTID, origin_shapefile, geometry)

study.area <- rbind(test, test_marine)

plot(study.area)



# Scheldt River basin for DVW analysis
study.area <- load.shapefile("./data/Belgium_Netherlands/dvw_study_area.shp",
                          "dvw_study_area",
                          coordinate_epsg)

study.area <- study.area %>%   # rename id column
  rename(
    Id = ID)

study.area <- study.area %>%   # select required columns
  select(Id, geometry)

plot(study.area$geometry)




# UK River Frome 2026
frome <- load.shapefile("./data/UK/Frome/frome.shp",
                        "frome",
                        coordinate_epsg)
plot(frome)


frome_estuary <- load.shapefile("./data/UK/Frome/frome_estuary.shp",
                              "frome_estuary",
                              coordinate_epsg)

frome_estuary <- frome_estuary %>%   # rename id column
  rename(
    Id = id)
plot(frome_estuary$geometry)

# Validate waterbodies
frome <- validate_waterbody(frome)
frome_estuary <- validate_waterbody(frome_estuary)

# Combine shapefiles
frome$origin_shapefile = "frome"
frome$Id = '2'
frome_estuary$origin_shapefile = "frome_estuary_sf"

frome_estuary <- 
  frome_estuary %>%
  dplyr::select(Id, origin_shapefile, geometry)
frome <- 
  frome %>% 
  dplyr::select(Id, origin_shapefile, geometry)

study.area <- rbind(frome, frome_estuary)

plot(study.area)






# -----------------------
# SET STUDY AREA
# -----------------------
#study.area <- study.area  # When the LifeWatch network is taken into account; sea 'Combine the shape files'
study.area <- frome

# validate the study.area
study.area <- validate_waterbody(study.area)

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
  "./data/receivernetworks/receivernetwork_2019_Grotenete.csv",
  coordinate_epsg
)

# DAK_superpolder network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_DAK_SUPERPOLDER.csv",
  coordinate_epsg
)

# DAK_markiezaatsmeer network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_DAK_MARKIEZAAT.csv",
  coordinate_epsg
)

# Noordzeekanaal network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_Noordzeekanaal.csv",
  coordinate_epsg
)

# 2013_Albertkanaal network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2013_albertkanaal.csv",
  coordinate_epsg
)

# life4fish network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_life4fish.csv",
  coordinate_epsg
)

# Michimit network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_michimit.csv",
  coordinate_epsg
)

# Shad network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_shad.csv",
  projection = coordinate_epsg
)

# Reelease network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_reelease.csv",
  projection = coordinate_epsg
)

# Wyre network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_wyre.csv",
  projection = coordinate_epsg
)

# nedap_meuse network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_nedap_meuse.csv",
  projection = coordinate_epsg
)

# Tyne network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_tyne.csv",
  projection = coordinate_epsg
)


# Shakimardan positions
locations.receivers <- load.receivers(
  "./data/receivernetworks/detectionnetwork_marinkas.csv",
  projection = coordinate_epsg
)

# Azores Ribeira Cruz
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_cruz.csv",
  projection = coordinate_epsg
)


# Test network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_test.csv",
  projection = coordinate_epsg
)


# Scheldt River basin network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2024_dvw_Scheldt.csv",
  projection = coordinate_epsg
)

# River Frome 2026 network
locations.receivers <- load.receivers(
  "./data/receivernetworks/receivernetwork_2026_frome.csv",
  projection = coordinate_epsg
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
  shape.study.area = test,
  receivers = locations.receivers,
  shape.study.area2 = test_marine, 
  shape.study.area_merged = study.area
)

# for homogeneous study areas
projections.locations.receivers <- find.projections.receivers(
  shape.study.area = study.area,
  receivers = locations.receivers
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
leaflet(test %>% st_transform(crs = 4326)) %>%
  addTiles(group = "OSM (default)") %>%
  addPolylines() %>%
  addPolygons(data = test_marine %>% st_transform(4326)) %>%
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
res <- 10 # pixel is a square:  res x res (in meters)

# First time running the following function can give an error that can be ignored. The code will provide the output anyway. See stackoverflow link for more info about the bug.
#https://stackoverflow.com/questions/61598340/why-does-rastertopoints-generate-an-error-on-first-call-but-not-second

# for a homogenous study area
study.area.binary <- shape.to.binarymask(
  shape.study.area = study.area,
  receivers = projections.locations.receivers,
  resolution = res)

# for a study area which is a combination of polygons and lines
study.area.binary <- shape.to.binarymask(
  shape.study.area = test,
  shape.study.area2 = test_marine,
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
write.csv(cst.dst.frame_corrected, "./results/distancematrix_leie_scheldt_all_fish2.csv")


# IDEA ...
# Could be interesting to compare these values with the commute distances:
# see: https://cran.r-project.org/web/packages/gdistance/vignettes/gdistance1.pdf
# commute.dst <- commuteDistance(tr_geocorrected, matched.receivers)
# By running many paths and extracting average statistics about the distance a
# more in-depth insight in travel distance could be achieved
