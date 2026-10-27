library(sf)
library(terra)
library(tidyverse)


bp <- 'G:/Shared drives/Beacons data/Public/geopackage_creator/bp_datasets.gpkg'
spp <- 'G:/Shared drives/Beacons data/Public/geopackage_creator/species.gpkg'
projected <- 'G:/Shared drives/Beacons data/Public/geopackage_creator/projected.gpkg'

layer2Update <- c("human_access_where_no_data")
layer2Delete <- c("intact_fl_2020")
herd2update <- c("coalriver", "horseranch","labiche","liardplateau","pelly","redstone","tayriver","southnahanni", "wolflake", "swanlake","littlerancheria")

gpkg_dir <- 'E:/MelinaStuff/BEACONs/git/Caribou_Cumulative_Effects_Explorer/www'


line <- st_read(bp, 'linear_disturbances') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTILINESTRING')

poly <- st_read(bp, 'areal_disturbances') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

fires <- st_read(bp, 'fires') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

ifl_2000 <- st_read(bp, 'ifl_2000') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

ifl_2025 <- st_read(bp, 'ifl_2025') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

pas <- st_read(bp, 'protected_areas') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

fp500 <- st_read(bp, 'footprint_500m') |>
  st_cast('MULTIPOLYGON')|>
  st_make_valid()

human_access <- st_read(bp, 'human_access_where_no_data') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

quartz <- st_read(projected, 'quartz_claims') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')

placers <- st_read(projected, 'placer_claims') |>
  st_zm(drop = TRUE, what = "ZM")  |>
  st_make_valid() |>
  dplyr::select(-any_of(c("fid", "FID"))) |>
  st_cast('MULTIPOLYGON')



# List of datasets already created above
layers <- list(
  linear_disturbances = line,
  areal_disturbances = poly,
  fires = fires,
  intact_fl_2000 = ifl_2000,
  intact_fl_2025 = ifl_2025,
  protected_areas = pas,
  quartz_claims = quartz,
  placers_claims = placers,
  footprint_500m = fp500
)

# Loop through herds
for (h in herd2update) {
  
  message("Processing: ", h)
  
  gpkg <- file.path(
    gpkg_dir,
    paste0(h, ".gpkg")
  )
  
  herd_poly <- if(h == "littlerancheria"){
    st_read(gpkg, layer = "data_extent")
  }else{
    st_read(gpkg, layer = "studyarea")
  }
  
  # Loop through layers
  for(layer_name in layer2Update){
    
    message("  extracting ", layer_name)
    
    x <- layers[[layer_name]]
    
    if(layer_name =="fires"){
      x <- x |>
        dplyr::filter(YEAR>1965)
    }
    # intersect
    extracted <- st_intersection(
      x,
      herd_poly
    )
    
    # clean geometry
    extracted <- extracted |>
      st_zm(drop = TRUE, what = "ZM") |>
      st_make_valid()
    
    # Skip empty layers
    if(nrow(extracted) == 0){
      next
    }
    
    st_write(extracted, gpkg, layer = layer_name, append = FALSE,  quiet = TRUE)
  }
}
  