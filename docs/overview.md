## Welcome to the Caribou Cumulative Effects Disturbance Explorer 

**Caribou Cumulative Effects Disturbance Explorer** generates custom maps of undisturbed and disturbed landscapes with tools to explore the influence of buffer size 
(or zone of influence), minimum patch size, fire, and potential future disturbances (e.g., mining claims) on these landscapes. A built-in **User Guide** tab provides 
step-by-step instructions and function descriptions, while the **Dataset Requirements** tab details data formats and spatial layers needed to run the app.


### Input data
  
**Caribou Cumulative Effects Disturbance Explorer** relies on several key spatial layers. The app has already embedded the caribou herds crossing the LFN IPCA planning 
region with all their associated layers. It is possible for the user to add extra linear and/or areal disturbances as well as display elements as vector and/or raster 
format. Please refer to the **Dataset Requirements** tab for details on associated attributes and formatting.

### Functionality
    
The app consists of four sections:
<br>

#### Select caribou herd

  - Select a caribou herd.Embedded spatial alyers associated to the herd will display on the map (i.e., linear and areal human disturbances, fires, mining claims, etc.).
  
  - (OPTIONAL) Change disturbance layer classification. Embedded disturbances are classified by default using industry type and disturbance type. 
  
  - (OPTIONAL) Upload other disturbances: Users can upload additional linear and areal disturbance features as shapeFiles. These can be incorporated into the mapping process or used for viewing purposes only.
    

#### Add display elements (OPTIONAL)

This section allows users to add additional features for visualization. These features must be vector data (points, lines, or polygons) or continuous rasters. A maximum of 
three additional features and 2 continuous raster can be added. The file or layer names are automatically used as display names on the map. Colors are assigned 
by the app and cannot be modified.

<br>

#### Buffer features
    
  - Apply buffers to disturbance features. Choose between:
    
    - A uniform buffer size applied to all features, or

    - Custom buffer sizes specific to disturbance types.

  - Optional: Set a minimum patch size for undisturbed areas after buffering. Smaller patches will be removed. Default is 0 km2.
  
  - Optional: Include other linear and areal disturbances not in the GeoPackage, such as future disturbances (e.g., proposed road network and/or cutblocks) or natural disturbances other than fire (e.g., insect outbreaks) and specify a buffer.

  - Optional: Include mining claims and specify a buffer.

  - Optional: Include fires and specify a minimum size threshold and the years to include.

 
#### Download undisturbed and disturbed areas
    
  - Download a GeoPackage of the **undisturbed areas** and **disturbed areas** created by the app, as well as the input spatial layers (e.g., linear and areal disturbances).
  
### Caribou Cumulative Effects Disturbance Explorer workflow diagram

The worflow diagram below provides an overview of the process.

<br><br>
<center><img src="pics/workflow.png" width="800"></center>
<br><br>
