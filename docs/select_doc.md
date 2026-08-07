---
format: md
---

## User Guide

This section defines the key inputs used to configure the analysis, including the selection of a caribou herd, disturbance classifications, and any additional user-provided data.

### Step 1. Select caribou herd

All required data for each herd are embedded within the app. 

- If the Little Rancheria or Finlayson herd is selected, users will be prompted to choose from a list of available ranges and corridors.
For some ranges, users can further specify whether to use the core area or the full extent of use. 
- All other herds include only a single dataset corresponding to the annual range defined by the Yukon Government.

Press **Confirm herd** 

<br>

### Step 2. Change disturbance layer classification (OPTIONAL) 

Disturbances are classified by default by INDUSTRY_TYPE (e.g., transporation) and DISTURBANCE_TYPE (e.g., highway). 
This classification generates a table summarizing the industry and/or disturbance types and their associated length (km) or area (km2). 
The table is found under the **Custom buffers** tab located across the top. To change the classification, check the box and select the drop-down menus to identify 
the industry and/or disturbance attributes for linear and areal disturbance features associated to the selected herd range. If attributes are not assigned, 
the table will simply summarize the features as "linear" and "areal".
   
*Note*: The option will be disable if the herd range only include fires
   
Press **Submit and Continue** to apply the new classification.

<br>

### Step 3. Upload other disturbances (OPTIONAL)

Here, the user has the option to upload additional linear and areal disturbances (e.g., proposed development, insect outbreaks, etc.) as shapefiles which can be included in the mapping workflow or used solely for visualization. 
Use the drop-down menus to browse to the shapefile. Shapefiles are comprised of multiple files, and all files must be selected (e.g., shp, shx, dbf, prj, etc.). 
Once selected, click **Confirm upload** to load the spatial layers. The layers will appear on a map. Each layers can be turned on and off. 

From here, users may proceed to **Add display elements** if needed, or go directly to **Buffer features.**


