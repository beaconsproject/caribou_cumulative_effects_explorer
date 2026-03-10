# Check and install packages if missing
#required_packages <- c("leaflet", "tidyverse", "cli","shinydashboard", "shinycssloaders", "shiny", "shinyjs",
#   "markdown", "dplyr", "tidyr", "sf", "shinyMatrix", "utils")
#
# Install any missing packages
#missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
#if (length(missing_packages) > 0) {
#  install.packages(missing_packages)
#}
# Load the packages
#invisible(lapply(required_packages, library, character.only = TRUE))

options(shiny.maxRequestSize=500*1024^2) 

library(leaflet)
library(tidyverse)
library(cli)
library(shinydashboard)
library(shinycssloaders)
library(shiny)
library(shinyjs)
library(markdown)
library(dplyr)
library(tidyr)
library(sf)
library(shinyMatrix)
library(utils)


caribouherds <- st_read("www/CaribouHerds.shp") %>% st_transform(4326)
caribou_list <- c("Little Rancheria", "Coal River", "Finlayson", "Horseranch", "Labiche", "Pelly", "Redstone", "South Nahanni", "Tay River", "Wolf Lake")

rge_list <- c("Annual range (YG)","fall_high_use_areas", "fall_main_corridor", "kde_annual","kde_winter","kde_latewinter","kde_earlywinter","kde_fallrut", "kde_summer", "kde_latesummer", "kde_earlysummer","spring_high_use_areas", "spring_main_corridor")

# LFN bnd
IPCA_PL <- st_read("www/lfn_boundaries.gpkg", layer = "ipca_planning_area") %>% 
  st_zm(drop = TRUE, what = "ZM") %>% 
  st_transform(4326)
kdtt <- st_read("www/lfn_boundaries.gpkg", layer = "kdtt") %>% st_transform(4326)
proposed_ipcas <- st_read("www/lfn_boundaries.gpkg", layer = "proposed_ipcas") %>% st_transform(4326)

rivers <- st_read("www/KDTT_lakes_and_rivers.gpkg", layer = "large_rivers") %>% st_transform(4326)
lakes <- st_read("www/KDTT_lakes_and_rivers.gpkg", layer = "frances_and_toobally_lakes") %>% st_transform(4326)

critical_occ <- st_read("www/KDTT_mineral_occurrences.gpkg", layer = "kdtt_critical_mineral_occurrences") %>% st_transform(4326)
mine_occ <- st_read("www/KDTT_mineral_occurrences.gpkg", layer = "kdtt_mineral_occurrences") %>% st_transform(4326)
priority_occ <- st_read("www/KDTT_mineral_occurrences.gpkg", layer = "kdtt_priority_critical_mineral_occurrences") %>% st_transform(4326)

isMappable <- function(x) {
  !is.null(x) && inherits(x, "sf") && nrow(x) > 0
}

stats <- tibble(Name = character(),
                Area_km2 = numeric(),
                Undisturbed_per = numeric(),
                Disturbed_per = numeric(),
                Lineardist_km = numeric(),
                Arealdist_km2 = numeric(),
                otherLinear_km = numeric(),
                otherAreal_km2 = numeric(),
                Fires_per = numeric(),
                Mines_per = numeric(),
                PA2021_per = numeric(),
                IntactFL2000_per = numeric(),
                IntactFL2020_per = numeric(),
                set_custom = character(),
                set_includeOthers = character(),
                set_mines = character(),
                set_fires = character()
)


# read_shp_from_upload: read a shapefile from fileInput
read_shp_from_upload <- function(upload_input) {
  req(upload_input)
  required_extensions <- c("shp", "shx", "dbf", "prj")
  infile <- upload_input
  file_extensions <- tools::file_ext(infile$name)
  if (all(required_extensions %in% file_extensions)) {
    dir <- unique(dirname(infile$datapath))
    outfiles <- file.path(dir, infile$name)
    name <- tools::file_path_sans_ext(infile$name[1])
    purrr::walk2(infile$datapath, outfiles, ~file.rename(.x, .y))
    shp_path <- file.path(dir, paste0(name, ".shp"))
    if (file.exists(shp_path)) {
      #return(sf::st_read(shp_path))
      shp <- sf::st_read(shp_path)
      assign(name, shp)
      return(shp)
    } else {
      showModal(modalDialog(
        title = "Shapefile (.shp) is missing.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      return()
    }
  } else {
    showModal(modalDialog(
      title = "Extension file is missing",
      "Please upload all necessary files for the shapefile (.shp, .shx, .dbf and .prj).",
      easyClose = TRUE,
      footer = modalButton("OK")
    ))
    return()
  }
}

#viridis
gradient_rast1 <- "display:inline-block; width:80px; height:15px; 
                 background: linear-gradient(to right, #440154, #31688e, #35b779, #fde725);
                 margin-right:8px; border:1px solid #000;"

#heat
gradient_rast2 <- "display:inline-block; width:80px; height:15px; 
                 background: linear-gradient(to right, #0000FF, #FFFF00, #FF0000);
                 margin-right:8px; border:1px solid #000;"

