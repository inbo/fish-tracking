## Purpose

Calculate the distances in between a set of receivers (point coordindates) and one or more vectorfiles (shapefiles) defining the spatial extent of the rivers. 

Remarks:
- The accuracy of the calculation is user defined by providing the resolution of the conversion of the vector files to raster images. 
- When the coordinates are not inside the spatial extent of the analysis, a stepwise increase of the coordinate raster cells is applied until overlap between the coorindate extent and the river extent is achieved

## Maintainer

Stijn Van Hoey

### When/where used?

Developed as pre-processing step for a receiver network requested by PieterJan Verhelst
