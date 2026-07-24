---
format: md
---


## Buffer features

In this step, the user specifies the disturbance layers and associated buffers for creating the undisturbed and disturbed areas maps. The disturbance layer options 
include linear and areal anthropogenic disturbances, other disturbances, mining claims, and fire, assuming those are available withinh the range selected.

**Select buffer type:** The user has two options.

  1. **Use custom buffers** - Select this option to assign different buffer widths to specific disturbance classes (e.g., 1000 m for highways and 500 m for trails).
Custom buffers are based on the disturbance classification defined in the previous step. By default, disturbances are grouped by industry and disturbance type. 
If you modified this classification earlier, the table will reflect your updated categories, allowing you to assign buffer sizes to each class.
When selected, the app automatically switches to the Custom buffers tab, where a table summarizes linear and areal disturbances. You can edit buffer widths (in metres) 
directly in the BUFFER_SIZE_M column. Disturbance features can be retrieved from an analysis by setting the BUFFER_SIZE_M to NA. The default buffer width for all classes is 500 m.

  2. **Use overall buffers:** Select this option if a single buffer width is to be applied to linear and areal disturbances. Different buffer widths can be applied to the linear and areal disturbances.

     Use the sliders to set buffers. The slider options provide increments of 10-m. If the slider options are not sufficient, use the custom buffers option above. 

   *Note*: The option will be disable if the range of the herd selected doesn't have disturbances. 
   

**Set minimum undisturbed patch size (km2)**: In the left sidebar, a minimum patch size for undisturbed areas can be set using the slider. This function will remove patches smaller than the minimum patch size from the undisturbed areas map. 

<br>

**Include other disturbances**: If additional human or natural disturbance layers (linear or areal) were uploaded during the **Select caribou herd** step, you can include 
them in the analysis. Once enabled, you can either use the sliders to assign a single buffer width to all uploaded linear and areal disturbance layers, or
use Custom buffers, which assigns buffer widths based on the Type_Indus and Type_Distu attributes in the uploaded shapefiles.

The Custom buffers option summarizes disturbances using the Type_Indus and Type_Distu attributes. If these attributes are not present, the app cannot distinguish among disturbance types and instead summarizes all uploaded disturbances into a single category, which is equivalent to using the slider option.In that case, only the slider-based buffering option can be used.

When Custom buffers is selected, the app switches to the Custom buffers tab, where the generated disturbance matrix is displayed at the bottom. You can edit the assigned buffer widths in the table, or set a buffer value to NA to exclude specific disturbance types from the analysis.

This option is disabled when no additional disturbance layers have been uploaded.


<br>

**Include mining claims**: If mining claims are present in the selected herd range, this option becomes available. Check the box and set a buffer width to 
include them in the analysis. This option is disabled if no mining claims layer is provided.

<br>

**Include fires**: If fire data are included in the selected herd range, this option becomes available. Check the box and define the minimum fire size (ha) 
and the range of years to include. This option is disabled if no fire layer is provided. 

<br>

📌 Buffered linear and areal anthropogenic disturbances, along with any selected optional disturbances (e.g., other uploaded disturbances, mining claims, and fires), are combined to define the disturbed areas. 
All remaining regions within the selected herd range that do not intersect these buffered disturbances are considered undisturbed.

<br>

Press the **Generate undisturbed areas** to create the undisturbed and disturbed area maps. Once processing is complete, two new layers (disturbed areas and undisturbed areas) will appear on the map:
(1) a “disturbed” layer representing buffered disturbances, and
(2) an “undisturbed” layer representing all areas within the study region that do not intersect disturbed areas.


## View statistics

The Statistics table in the right panel summarizes the area and length of disturbances within the selected herd range, as well as the percentage of area affected by fires, 
mining, and protected areas (when available).

If Intact Forest Landscapes (IFL) datasets for 2000 and 2020 are available, users can compare their generated undisturbed areas with these reference datasets.