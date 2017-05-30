## fish-tracking

This private repository contains a collection of (personal) scripts for processing and analyzing fish tracking data. The plan is to move common functions to the [glatos R package](https://github.com/inbo/glatos).

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


### ...


