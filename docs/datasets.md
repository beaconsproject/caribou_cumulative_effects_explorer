## Datasets

The Caribou Cumulative Effects Explorer integrates a set of spatial datasets to support the visualization and assessment of cumulative disturbances 
within caribou ranges. These datasets provide the foundation for exploring how different types of disturbances overlap with herd ranges and contribute to overall 
landscape condition.

### Embedded datasets (included in the app)
The application includes data for 10 caribou herds overlapping the LFN IPCA planning area:

- Coal River
- Finlayson
- Horseranch
- Labiche
- Little Rancheria
- Pelly
- Redstone
- South Nahanni
- Tay River
- Wolf Lake

For each herd, the app compiles a consistent set of spatial layers used to represent both natural and anthropogenic disturbances, as well as land use context. 
These layers are used within the app to visualize disturbance patterns, support comparisons, and enable cumulative effects assessment.

Each herd includes the following spatial datasets, where available or where the herd range overlaps them:

- Annual range (YG) – Delineates the herd’s annual distribution
- Fires: https://cwfis.cfs.nrcan.gc.ca/datamart
- Linear disturbance – e.g., roads, seismic lines: https://map-data.service.yukon.ca/geoyukon/Environmental_Monitoring/Surface_Disturbance_Linear_Features/
- Areal disturbance – e.g., cutblocks, mines: https://map-data.service.yukon.ca/geoyukon/Environmental_Monitoring/Surface_Disturbance_Areal_Features/
- Critical mineral occurrences - Identifies 31 critical minerals: https://map-data.service.yukon.ca/GeoYukon/Geological/Mineral_Occurrences_250k/
- Priority critical mineral occurrences - Identifies the six priority minerals (lithium, graphite, nickel, cobalt, copper, and rare earth elements): https://map-data.service.yukon.ca/GeoYukon/Geological/Mineral_Occurrences_250k/
- Quartz claims: https://map-data.service.yukon.ca/geoyukon/Mining/Quartz_Claims_50k/
- Placer claims: https://map-data.service.yukon.ca/geoyukon/Mining/Placer_Claims_50k/
- Protected areas: https://open.canada.ca/data/en/dataset/6c343726-1e92-451a-876a-76e17d398a1c
- Intact FL 2000: https://intactforests.org*
- Intact FL 2020:  https://intactforests.org*
<br><br>


**Note:** The Little Rancheria herd additionally includes seasonal layers (summer range, winter range, fall high-use area, spring high-use area, ...)



*References: Potapov, P., Hansen, M. C., Laestadius L., Turubanova S., Yaroshenko A., Thies C., Smith W., Zhuravleva I., Komarova A., Minnemeyer S., Esipova E. The last frontiers of wilderness: Tracking loss of intact forest landscapes from 2000 to 2013. Science Advances, 2017; 3:e1600821

### Optional user-provided datasets

In addition to the embedded datasets, users can upload their own spatial data to complement the analysis.

#### Disturbance layers 

Users may upload additional:

 - Linear disturbances
 - Areal disturbances

These layers must be uploaded as shapefiles. They can be used alongside the embedded datasets to refine or extend cumulative disturbance analyses. If included in the analysis,
only an overall buffer size can be applied to those disturbances.

📌 For accurate analysis on additional linear and areal disturbances, the range selected must contain the full extent of the additional disturbance layers.


#### Additional display layers 

Users can also add up to five additional layers for visualization: up to three polygon, polyline, or point layers (uploaded as GeoPackage or Shapefile), and up to two raster layers.
