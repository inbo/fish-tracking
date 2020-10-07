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

# RIVER SECTION
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

# NETE SECTION (precompiled as Europe entire file is very large)
nete <- load.shapefile("./data/europe_water/nete.shp",
                       "nete",
                       coordinate.string,
                       subset.names = NULL)
## to restart from the entire Europe shapefile:
## nete <- load.shapefile("./data/europe_water/Europe_Water_2008.shp",
##                        "Europe_Water_2008",
##                        coordinate.string,
##                        c("Nete", "Grote Nete"))

# WESTERSCHELDE
westerschelde <- load.shapefile("./data/westerschelde_water/seavox_sea_area_polygons_v13.shp",
                                "seavox_sea_area_polygons_v13",
                                coordinate.string)

# SEA
sea <- load.shapefile("./data/PJ_manual_water/PJ_ontbrekende_stukken_reduced.shp",
                                "PJ_ontbrekende_stukken_reduced",
                                coordinate.string)


# RIVER FROME (UK)
frome <- load.shapefile("./data/UK/Frome/Statutory_Main_River_Map.shp",
                         "Statutory_Main_River_Map",
                         coordinate.string)


# -----------------------
# COMBINE THE SHAPE FILES
# -----------------------
study.area <- gUnion(rivers, nete)
study.area <- gUnion(study.area, westerschelde)
study.area <- gUnion(study.area, sea)

# clean workspace from individual shapefiles
rm(rivers, nete, westerschelde, sea)

# -----------------------
# SET STUDY AREA
# -----------------------
#study.area <- study.area  # When the LifeWatch network is taken into account; sea 'Combine the shape files'
study.area <- frome

# ----------------
# LOAD DETECTION STATION NETWORK
# ----------------

# LifeWatch network
#locations.receivers <- load.receivers("./data/receivernetwork_20160526.csv",
#                                      coordinate.string)

# Frome network
locations.receivers <- load.receivers("./data/receivernetwork_frome_2014.csv",
                                      coordinate.string)

# ------------------------
# CONVERT SHAPE TO RASTER
# ------------------------
# for alternative resolutions, change the number of rows/columns
nrows <- 2000
ncols <- 4000
study.area.binary <- shape.to.binarymask(study.area, nrows, ncols)

# --------------------------------
# ADJUST MASK TO CONTAIN RECEIVERS
# --------------------------------
study.area.binary.extended <- adapt.binarymask(study.area.binary, locations.receivers)

# write this to disk for loading in e.g. QGIS
writeRaster(study.area.binary.extended, "./results/study_area_binary", "GTiff",
            overwrite = TRUE)

# --------------------------------
# CONTROL MASK
# --------------------------------
# Control the mask characterstics and receiver location inside mask:
# (if an error occurres, this need to be checked before deriving distances again)
control.mask(study.area.binary.extended, locations.receivers)

# -------------------------------
# Derive distances with gdistance
# -------------------------------
cst.dst.frame <- get.distance.matrix(study.area.binary.extended, locations.receivers)
write.csv(cst.dst.frame, "./results/cst_dist_receivers.csv")


# IDEA ...
# Could be interesting to compare these values with the commute distances:
# see: https://cran.r-project.org/web/packages/gdistance/vignettes/gdistance1.pdf
# commute.dst <- commuteDistance(tr_geocorrected, matched.receivers)
# By running many paths and extracting average statistics about the distance a
# more in-depth insight in travel distance could be achieved















