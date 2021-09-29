## fish-tracking

This repository contains a collection of scripts for processing and analyzing fish tracking data. The plan is to move common functions to relevant R-packages, such as the [glatos R package](https://github.com/inbo/glatos) or other packages, e.g. [actel](https://github.com/hugomflavio/actel/).

To add a script yourself (or a set of scripts with a common purpose), create a **new directory** in the `scripts` folder. Within this folder, put the R/Rmd script(s) together with a `Readme.md` file, describing the scripts in the folder. Make sure the following minimal elements are provided:

* Purpose: *what?*
* Maintainer: *who to contact?*
* Usage: *when/where used?*

Apart from individual scripts, you can also enlist to existing implementations/functions/code snippets available in other repositories you've worked in. However, try to focus on small functionalities and processing steps. For examples, instead of referring to the entire analysis of a paper, extract specific steps of the analysis and enlist these here, with the following template:

```
### Examples functionality

* Purpose: *what?*
* Maintainer: *who to contact?*
* Usage: *when/where used?*
* Link: *link to the specific resource (remark that you can link to specific lines of Github code)*
```

## External code snippets

### Leaflet plot of coordinates

* Purpose: Plot x/y coordinates in data.frame on a map, from given projection
* Maintainer: Stijn Van Hoey
* Usage: Used as part of functions to semi-automatically check the projection of given coordinates
* Link: https://github.com/inbo/inbo-rutils/blob/master/gis/guess_projection.R#L60


### Eel Scheldt analysis

* Purpose: Eel migration behaviour analysis in the Scheldt Estuary
* Maintainer: Pieterjan Verhelst
* Usage: Processing, explorative and analysis scripts for eel migration in the Scheldt Estuary. Of specific interest to other users are:
    - Tripletmethod
    - Graph visualisation (more a visualisation as an analysis step)
    - Swim speed
* Link: https://github.com/PieterjanVerhelst/eel-scheldt-analysis


### Eel Albert Canal analysis

* Purpose: Eel migration behaviour analysis in the Albert Canal
* Maintainer: Pieterjan Verhelst
* Usage: Processing, explorative and analysis scripts for eel migration in the Albert Canal. Of specific interest to other users are:
    - Tripletmethod
    - Graph visualisation (more a visualisation as an analysis step)
    - Swim speed
* Link: https://github.com/PieterjanVerhelst/eel-ak-analysis
* Issue: Script 'Migration_triplets.R' determines downstream migration Specifically, after chronologically ordering the data, a record was considered a migration record if the previous and next detection were at a receiver up- and downstream, respectively, or if the previous two detections were at two subsequent upstream located receivers. To integrate this in a package, it would be interesting to make the code work in the other direction, i.e. upstream migration.
See issue https://github.com/PieterjanVerhelst/eel-ak-analysis/issues/6#issuecomment-305783874


### ...(additional existing functionalities)


## Just ideas, no implemention yet
(In this section, provide some ideas, features,... that could eventually be useful to the user community)

### Position calculation
* Purpose: Calculate exact fish positions based on triangulation (difference in time of arrival)
* Usage: Habitat preference, habitat use, geographic distribution
 

 

