##
## Derive distance matrix for a given set of receivers within the boundaries
## af the provided water bodies - execution
##
## Van Hoey S.
## Lifewatch INBO
## 2016-07-06

library("sp")
library("rgdal")
library("rgeos")
library("raster")
library("gdistance")

library("assertthat")
library(mapview)

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




# RIVER FROME (UK)
frome <- load.shapefile("./data/UK/Frome/Statutory_Main_River_Map.shp",
                         "Statutory_Main_River_Map",
                         coordinate.string)

# RIVER STOUR (UK)
stour <- load.shapefile("./data/UK/Stour/stour.shp",
                        "stour",
                        coordinate.string)


# RIVER WARNOW (GERMANY)
river.names <- c("Unterwarnow", "Warnow")
warnow <- load.shapefile("./data/European_waterways/Europe_Water_2008.shp",
                         "Europe_Water_2008",
                         coordinate.string,
                         river.names)

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





# -----------------------
# SET STUDY AREA
# -----------------------
#study.area <- study.area  # When the LifeWatch network is taken into account; sea 'Combine the shape files'
study.area <- stour

# ----------------
# LOAD DETECTION STATION NETWORK
# ----------------

# Twaite shad network (version 29/11/2020)
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_Alosa_fallax_29112020.csv",
                                      coordinate.string)

# LifeWatch network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_20160526.csv",
                                      coordinate.string)

# PhD Verhelst eel
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2015_phd_verhelst_eel.csv",
                                      coordinate.string)

# Frome network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2014_frome.csv",
                                      coordinate.string)

# Stour network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2013_Stour.csv",
                                      coordinate.string)

# Warnow network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2011_warnow.csv",
                                      coordinate.string)

# Gudena network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_2004_gudena.csv",
                                      coordinate.string)

# Mondego network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_PTN-Silver-eel-Mondego.csv",
                                      coordinate.string)

# SEMP network
locations.receivers <- load.receivers("./data/receivernetworks/receivernetwork_SEMP.csv",
                                      coordinate.string)


# ------------------------
# CREATE PLOT TO CHECK ALL NECESSARY WATERWAYS ARE INCLUDED
# ------------------------
mapView(study.area, map.types = "OpenStreetMap") +
mapView(locations.receivers, col.regions = "red", map.types = "OpenStreetMap")




# ------------------------
# CONVERT SHAPE TO RASTER
# ------------------------
# for alternative resolutions, change the number of rows/columns
nrows <- 2000
ncols <- 4000
# First time running the following function can give an error that can be ignored. The code will provide the output anyway. See stackoverflow link for more info about the bug.
#https://stackoverflow.com/questions/61598340/why-does-rastertopoints-generate-an-error-on-first-call-but-not-second 
study.area.binary <- shape.to.binarymask(study.area, nrows, ncols)

# --------------------------------
# ADJUST MASK TO CONTAIN RECEIVERS
# --------------------------------
study.area.binary.extended <- adapt.binarymask(study.area.binary,
                                               locations.receivers)

# write this to disk for loading in e.g. QGIS
writeRaster(study.area.binary.extended, "./results/study_area_binary", "GTiff",
            overwrite = TRUE)

# --------------------------------
# CONTROL MASK
# --------------------------------
# Control the mask characteristics and receiver location inside mask:
# (if an error occurs, this need to be checked before deriving distances again)
control.mask(study.area.binary.extended, locations.receivers)

# -------------------------------
# Derive distances with gdistance
# -------------------------------
cst.dst.frame <- get.distance.matrix(study.area.binary.extended,
                                     locations.receivers)
write.csv(cst.dst.frame, "./results/distances_alosafallax_29112020.csv")


# IDEA ...
# Could be interesting to compare these values with the commute distances:
# see: https://cran.r-project.org/web/packages/gdistance/vignettes/gdistance1.pdf
# commute.dst <- commuteDistance(tr_geocorrected, matched.receivers)
# By running many paths and extracting average statistics about the distance a
# more in-depth insight in travel distance could be achieved
