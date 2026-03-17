---
format: md
---


## Buffer features

In this step, the user specifies the disturbance layers and associated buffers for creating the undisturbed and disturbed areas maps. The disturbance layer options 
include linear and areal anthropogenic disturbances, other disturbances, mining claims, and fire, assuming those are available withinh the range selected.

**Select buffer type:** The user has two options.

  1. **Use custom buffers** - Select this option if variable buffer widths are desired e.g., 1000-m buffer for highways and 500-m buffer for trails.
     
     If selected, the **mapview** will be replaced with the table summarizing linear and area disturbances under the **custom buffers** tab. Variable buffer widths are assigned in metres via the table by editing the widths in the column named "BUFFER_SIZE_M". The default buffer width assigned to all disturbances is 500-m.

  2. **Use overall buffers:** Select this option if a single buffer width is to be applied to linear and areal disturbances. Different buffer widths can be applied to the linear and areal disturbances.

     Use the sliders to set buffers. The slider options provide increments of 50-m. If the slider options are not sufficient, use the custom buffers option above. 

   *Note*: The option will be disable if the range of the herd selected doesn't have disturbances. 
   
**Set minimum undisturbed patch size (km2)**: In the left sidebar, a minimum patch size for undisturbed areas can be set using the slider. This function will remove patches smaller than the minimum patch size from the undisturbed areas map. 

**Include other disturbances**: The user can choose to include other human or natural disturbances (linear and areal) if these spatial layers were uploaded during the **Select caribou herd** step.  To include other disturbances, check the box and set the buffer width using the slider(s). The option is disable in the absence of layer representing other disturbances. 

**Include mining claims**: This option becomes available when mining claims intersect the selected herd range. To include them in the analysis, check the box and specify the buffer width using the slider. The option is disabled if no mining claims layer is available.

**Include fires**: This option becomes available when fires intersect the selected herd range. To include them in the analysis, check the box and set the mininum fire size (ha), as well as fire years, to include in the generation of the undisturbed and disturbed areas maps. The option is disable in the absence of fires. 


Press **Generate undisturbed areas** to create maps of disturbed and undisturbed areas. Once processing is complete, two new layers will appear on the map:
(1) a “disturbed” layer representing buffered disturbances, and
(2) an “undisturbed” layer representing all areas within the study region that do not intersect disturbed areas.


## View statistics

The Statistics table in the right panel summarizes the area and length of disturbances within the study area, as well as the percentage of area affected by fires, 
mining, and protected areas (when available).

If Intact Forest Landscapes (IFL) datasets for 2000 and 2020 are available, users can compare their generated undisturbed areas with these reference datasets.