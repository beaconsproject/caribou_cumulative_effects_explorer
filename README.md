## Welcome to the Caribou Cumulative Effects Disturbance Explorer 
*** Reviewed Aug 7, 2026 by ME ***

The **Caribou Cumulative Effects Disturbance Explorer** is an R shiny app that enables users to evaluate cumulative effects from disturbance in caribou ranges and movement corridors overlapping the LFN IPCA planning area. The app allows users to generate human footprint or landscape intactness maps using regional-scale anthropogenic surface disturbance data for caribou ranges or movement corridors. The app includes data for 12 caribou herds:

- Little Rancheria
- Coal River
- Finlayson
- Horseranch
- Labiche
- Liard Plateau
- Pelly
- Redstone
- South Nahanni
- Swan Lake
- Tay River
- Wolf Lake

For each herd, the app compiles a consistent set of spatial layers used to represent both natural and anthropogenic disturbances, as well as land use context. 
These layers are used within the app to visualize disturbance patterns, support comparisons, and enable cumulative effects assessment. It is possible for the user to add extra linear and/or areal disturbances as well as display elements in vector and/or raster format.

### Functionality
    
The app consists of four sections:
<br>

#### Select caribou herd

  - Select a caribou herd. Embedded spatial layers associated with the herd will display on the map (i.e., linear and areal human disturbances, fires, mining claims, etc.).
  
  - (OPTIONAL) Change disturbance layer classification. Embedded disturbances are classified by default using industry type and disturbance type. 
  
  - (OPTIONAL) Upload other disturbances: Users can upload additional linear and areal disturbance features as shapefiles. These can be incorporated into the mapping process or used for viewing purposes only.
    

#### Add display elements (OPTIONAL)

This section allows users to add additional features for visualization. These features must be vector data (points, lines, or polygons) or continuous rasters. A maximum of 
three additional features and 2 continuous raster can be added. The file or layer names are automatically used as display names on the map. Colors are assigned 
by the app and cannot be modified.


#### Buffer features
    
  - Apply buffers to disturbance features. Choose between:
    
    - A uniform buffer size applied to all features, or

    - Custom buffer sizes specific to disturbance types.

  - Optional: Set a minimum patch size for undisturbed areas after buffering. Smaller patches will be removed. Default is 0 km2.
  
  - Optional: Include other linear and areal disturbances not in the GeoPackage, such as future disturbances (e.g., proposed road network and/or cutblocks) or natural disturbances other than fire (e.g., insect outbreaks) and specify a buffer.

  - Optional: Include mining claims and specify a buffer.

  - Optional: Include fires and specify a minimum size threshold and the years to include.


#### Download data and reporting
    
  - Download a GeoPackage of the **undisturbed areas** and **disturbed areas** created by the app, as well as the input spatial layers (e.g., linear and areal disturbances).
  - The app can also generate **summary statistics** based on user-selected disturbance layers and buffers. The statistics table can be downloaded in .csv format.
  - Lastly, the app can be used to generate and download a **report** on the user-defined cumulative effects assessment to further support discussions, refine analyses, or inform decisions. 

## Running the App

The app is located at: <https://beaconsproject.shinyapps.io/caribou_ce_disturbance_explorer>

The app can also be run from a local machine using the following steps (note, the first 2 steps only need to be run once):

1.  Install R (download from [r-project.org](https://www.r-project.org/) and follow instructions)
2.  Install the following additional packages:

```         
install.packages(c("sf","leaflet","tidyverse","shinydashboard","shinycssloaders","shinyjs","markdown","shinyMatrix"))
```

3.  Start the Shiny app:

```         
shiny::runGitHub("beaconsproject/Caribou_CE_Disturbance_Explorer")
```
