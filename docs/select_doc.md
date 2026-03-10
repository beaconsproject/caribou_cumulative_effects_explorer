---
format: md
---

## Select caribou herd

In this step, the user identify the studyarea which will be used in the Caribou Cumulative Effect Disturbance Explorer. The studyarea is defined by 
selecting a caribou herd and an associated range or corridor.


### Select caribou herd

Select caribou herd provides a list of all caribou herds intersecting the LFN IPCA planning region. All required data are embedded within the app,
 including the spatial layers needed for the analysis. 

- If the Little Rancheria herd is selected, the user will have the choice to select the range or corridor to use for the analysis. 
Each range and corridor was generated using an isopleth level derived from Kernel Density Estimation. When multiple isopleth are available, 
the user must select the level that will be used to define the polygon representing the studyarea.

- If another herd is selected, only the annual range for that herd will be available for use in the analysis. 

Press **Confirm herd** 

### Change disturbance layer classification

Click this option if you want to change the way linear and areal disturbances are classified. Default classification are by 
industry (e.g., transporation) and disturbance (e.g., highway) type. This classification generates a table summarizing the industry and/or disturbance types and their associated length (km) or area (km2).   
The table is under the **Custom buffers** tab located across the top and is required in the next step if custom buffer sizes are to be applied to industry and/or disturbance types. Use the drop-down menus to identify the industry and/or disturbance attributes for linear and areal disturbance features. 
If attributes are not assigned, the table will simply summarize the features as "linear" and "areal".
   
*Note*: The option will be disable if the herd only include fires
   
Press **Submit and Continue** if you want the analysis to consider the changes


### Upload other disturbances

Upload other linear disturbances (shp)** and Upload other areal disturbances (shp): Here, the user has the option to upload additional linear and areal disturbances (e.g., proposed development, insect outbreaks, etc.) as shapefiles which can be included in the mapping workflow or used solely for visualization. 
Use the drop-down menus to browse to the shapefile. Shapefiles are comprised of multiple files, and all files must be selected (e.g., shp, shx, dbf, prj, etc.). Once selected, click "Open".

Press the **Confirm Upload** button to load the spatial layers. The layers will appear in a map where the user can turn layers on and off. From here, move on to **Buffer features**.


  📌 Users are responsible for ensuring that all spatial layers being upload uses Yukon Albers coordinate reference system (EPSG:3578).
