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

# --------------------
# INTRODUCTION
# --------------------

# Define the projection for the analysis:
coordinate.string <- CRS("+init=epsg:32631")

# Load the functionalities from the functions file:
source("receiver_distance_fun.R")

# --------------------
# LOAD SHAPEFILES
# --------------------


# 2015 PHD VERHELST EEL
vhag <- load.shapefile("./data/Belgium_Netherlands/Vhag.shp",
                       "Vhag",
                       coordinate.string)
plot(vhag)

ws_bpns <- load.shapefile("./data/Belgium_Netherlands/ws_bpns.shp",
                       "ws_bpns",
                       coordinate.string)
plot(ws_bpns)

# Combine shapefiles
study.area <- gUnion(vhag, ws_bpns)



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
                         coordinate.string,
                         river.names)




# Nete Section (precompiled as Europe entire file is very large)
nete <- load.shapefile("./data/europe_water/nete.shp",
                       "nete",
                       coordinate.string,
                       subset.names = NULL)
## to restart from the entire Europe shapefile:
## nete <- load.shapefile("./data/europe_water/Europe_Water_2008.shp",
##                        "Europe_Water_2008",
##                        projection_code,
##                        c("Nete", "Grote Nete"))

# Westerschelde
westerschelde <- load.shapefile("./data/westerschelde_water/seavox_sea_area_polygons_v13.shp",
                                "seavox_sea_area_polygons_v13",
                                coordinate.string)

# Belgian part of the North Sea
sea <- load.shapefile("./data/PJ_manual_water/PJ_ontbrekende_stukken_reduced.shp",
                                "PJ_ontbrekende_stukken_reduced",
                                coordinate.string)


# Combine shapefiles
study.area <- gUnion(rivers, nete)
study.area <- gUnion(study.area, westerschelde)
study.area <- gUnion(study.area, sea)

# clean workspace from individual shapefiles
rm(rivers, nete, westerschelde, sea)

#### ####



# RIVER FROME (UK)
frome <- load.shapefile("./data/UK/Frome/frome.shp",
                         "frome",
                         coordinate.string)
plot(frome)

# RIVER STOUR (UK)
stour <- load.shapefile("./data/UK/Stour/stour.shp",
                        "stour",
                        coordinate.string)

# RIVER NENE (UK)
nene <- load.shapefile("./data/UK/Nene/nene.shp",
                        "nene",
                        coordinate.string)


# RIVER WARNOW (GERMANY)
warnow <- load.shapefile("./data/Germany/warnow.shp",
                         "warnow",
                         coordinate.string)

# RIVER GUDENA (DENMARK)
gudena <- load.shapefile("./data/Denmark/rivers.shp",
                         "rivers",
                         coordinate.string)

gudena <- gudena[gudena$rivers_id %in% c(12,22),]
plot(gudena)

# RIVER MONDEGO (PORTUGAL)
mondego <- load.shapefile("./data/Portugal/Mondego.shp",
                         "Mondego",
                         coordinate.string)
plot(mondego)

# RIVERS SEMP PROJECT (LITHUANIA)
curonian_lagoon <- load.shapefile("./data/Lithuania/curonian_lagoon.shp",
                          "curonian_lagoon",
                          coordinate.string)
main <- load.shapefile("./data/Lithuania/Rivers.shp",
                                  "Rivers",
                                  coordinate.string)
zeimena <- load.shapefile("./data/Lithuania/Zeimena.shp",
                                  "Zeimena",
                                  coordinate.string)

semp <- gUnion(curonian_lagoon, main)
semp <- gUnion(semp, zeimena)

plot(semp)


# EMMN project - Alta fjord Norway
emmn <- load.shapefile("./data/Norway/alta.shp",
                          "alta",
                          coordinate.string)

plot(emmn)


# ESGL & 2011_loire project
esgl <- load.shapefile("./data/France/loire_final.shp",
                       "loire_final",
                       coordinate.string)

plot(esgl)


# 2017_fremur project
fremur <- load.shapefile("./data/France/fremur.shp",
                       "fremur",
                       coordinate.string)

plot(fremur)


# -----------------------
# SET STUDY AREA
# -----------------------
#study.area <- study.area  # When the LifeWatch network is taken into account; sea 'Combine the shape files'
study.area <- nene

# ----------------
# LOAD DETECTION STATION NETWORK
# ----------------

# LifeWatch network
#locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_20160526.csv",
#                                      coordinate.string)

# PhD Verhelst eel
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2015_phd_verhelst_eel.csv",
                                      coordinate.string)

# Frome network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2014_Frome.csv",
                                      coordinate.string)

# Stour network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2013_Stour.csv",
                                      coordinate.string)

# Nene network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2014_Nene.csv",
                                      coordinate.string)

# Warnow network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2011_Warnow.csv",
                                      coordinate.string)

# Gudena network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2004_Gudena.csv",
                                      coordinate.string)

# Mondego network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_PTN-Silver-eel-Mondego.csv",
                                      coordinate.string)

# SEMP network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_SEMP.csv",
                                      coordinate.string)

# EMMN network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_EMMN.csv",
                                      coordinate.string)

# ESGL network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_ESGL.csv",
                                      coordinate.string)

# 2011_loire network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2011_loire.csv",
                                      coordinate.string)

# 2017_fremur network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2017_Fremur.csv",
                                      coordinate.string)

# ----------------
# PROJECT RECEIVERS ON WATER SHAPEFILE
# ----------------

# Sometimes the receivers position is way too far from river shapefile and so
# the distance among receivers can be misleading. We find the nearest point to
# location receivers on the river shapefile (orthogonal projection)
# Receivers inside the river body will not be projected

projections.locations.receivers <- find.projections.receivers(
  shape.study.area = study.area,
  receivers = locations.receivers,
  projection = coordinate.string
)

# ------------------------
# CREATE PLOT TO CHECK ALL NECESSARY WATERWAYS ARE INCLUDED
# ------------------------
mapView(study.area, map.types = "OpenStreetMap") +
mapView(locations.receivers, col.regions = "red", map.types = "OpenStreetMap",
        label = locations.receivers@data[["station_name"]]) +
  mapView(projections.locations.receivers,
          col.regions = "white",
          map.types = "OpenStreetMap",
          label = projections.locations.receivers@data[["station_name"]])

# ------------------------
# CONVERT SHAPE TO RASTER
# ------------------------
res <- 20 # pixel is a square:  res x res (in meters)

x_size <- study.area@bbox[1,2] - study.area@bbox[1,1]
y_size <- study.area@bbox[2,2] - study.area@bbox[2,1]

nrows <- round(y_size / res)
ncols <- round(x_size / res)

message(glue("Pixel resolution: {res}m"))
message(glue("Number of rows,cols: ({nrows},{ncols})"))
# First time running the following function can give an error that can be ignored. The code will provide the output anyway. See stackoverflow link for more info about the bug.
#https://stackoverflow.com/questions/61598340/why-does-rastertopoints-generate-an-error-on-first-call-but-not-second
study.area.binary <- shape.to.binarymask(
  shape.study.area = study.area,
  receivers = projections.locations.receivers,
  nrows = nrows,
  ncols = ncols
)

# --------------------------------
# ADJUST MASK TO CONTAIN RECEIVERS
# --------------------------------
#
study.area.binary.extended <- adapt.binarymask(binary.mask = study.area.binary,
                                               receivers = projections.locations.receivers)

# write this to disk for loading in e.g. QGIS
writeRaster(study.area.binary.extended, "./results/study_area_binary", "GTiff",
            overwrite = TRUE)

# remove sutdy.area.binary raster (not needed anymore) to free some memory
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
write.csv(cst.dst.frame_corrected, "./results/distancematrix_2014_nene.csv")


# IDEA ...
# Could be interesting to compare these values with the commute distances:
# see: https://cran.r-project.org/web/packages/gdistance/vignettes/gdistance1.pdf
# commute.dst <- commuteDistance(tr_geocorrected, matched.receivers)
# By running many paths and extracting average statistics about the distance a
# more in-depth insight in travel distance could be achieved
