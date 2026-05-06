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
library(tmap)
library(pagedown)
library(kableExtra)
library(knitr)

r_files <- list.files(
  file.path(getwd(), "R"),
  pattern = "\\.[rR]$",
  full.names = TRUE
)

invisible(lapply(r_files, source))


caribouherds <- st_read("www/CaribouHerds.shp") %>% st_transform(4326)
caribou_list <- c("Little Rancheria", "Coal River", "Finlayson", "Horseranch", "Labiche", "Liard Plateau","Pelly", "Redstone", "South Nahanni", "Swan Lake","Tay River", "Wolf Lake")

rge_list <- c("Fall high use areas", "Fall main corridor", "Annual range","Early winter","Late winter", "Fall rut", "Summer", "Spring high use areas", "Spring main corridor")

# LFN bnd
IPCA_PL <- st_read("www/lfn_boundaries.gpkg", layer = "ipca_planning_area") %>% 
  st_zm(drop = TRUE, what = "ZM") %>% 
  st_transform(4326)
kdtt <- st_read("www/lfn_boundaries.gpkg", layer = "kdtt") %>% st_transform(4326)
proposed_ipcas <- st_read("www/lfn_boundaries.gpkg", layer = "proposed_ipcas_all") %>% 
  st_zm(drop = TRUE, what = "ZM") %>% 
  st_transform(4326)

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



build_map <- function(rv){
  tmap_mode("plot")
  
  visible <- rv$visible_groups()

  # palette 
  fire_pal <- c(
    "Lightning" = "#996633",
    "Human" = "#663300",
    "Unknown" = "pink"
  )
  
  herd_pal <- colorRampPalette(
    c('#a6cee3','#1f78b4','#b2df8a','#33a02c',
      '#fb9a99','#e31a1c','#fdbf6f','#ff7f00',
      '#cab2d6','#6a3d9a','#ffff99','#b15928')
  )
  
  caribouherds$pal <- herd_pal(length(unique(caribouherds$HERD)))[
    match(caribouherds$HERD, unique(caribouherds$HERD))
  ]
  
  sa <- rv$sa()
  sa_buff <- sf::st_buffer(sa, dist = 20000)
  bb <- sf::st_bbox(sa_buff)
  
  # start map
  map <- tm_shape(sa) +
    tm_borders(col = '#663399', lwd = 3) +
    tm_view(
      bbox = bb
    )
  
  # base layers (equivalent to basemap in Leaflet is not truly available in static tmap,
  # so we just build vector layers in correct order)
  if(rv$herd() == "www/littlerancheria.gpkg"){
    if(rv$herd_range() != "Annual range (YG)"){
      if("Annual range (YG)" %in% visible){
        poly <- st_read(rv$herd(), layer = "studyarea") %>% st_transform(4326)
        map <- map +
          tm_shape(poly) +
          tm_borders(col = "black", lwd = 1)
      }
    }
      
  }
  
  # Protected areas
  if ("Protected areas" %in% visible) {
    poly <- rv$statslayers_rv$pa2021
    map <- map +
      tm_shape(poly) +
      tm_polygons(
        col = '#699999',
        border.col = NA,
        alpha = 1,
        lwd = 0,
        border.col = '#699999'
      )
  }
  
  # Intact FL 2000
  if ("Intact FL 2000" %in% visible) {
    poly <- rv$statslayers_rv$ifl2000
    map <- map +
      tm_shape(poly) +
      tm_polygons(
        col = '#3366FF',
        border.col = NA,
        lwd= 0,
        alpha = 1
      )
  }
  
  # Intact FL 2020
  if ("Intact FL 2020" %in% visible) {
    poly <- rv$statslayers_rv$ifl2020
    map <- map +
      tm_shape(poly) +
      tm_polygons(
        col = '#000066',
        border.col = NA,
        lwd= 0,
        alpha = 1
      )
  }
  # Lakes
  if ("Lakes" %in% visible) {
    map <- map +
      tm_shape(lakes) +
      tm_polygons(col = "#97FFFF", alpha = 0, border.col = "#97FFFF", lwd = 2)
  }
  
  # Rivers
  if ("Rivers" %in% visible) {
    map <- map +
      tm_shape(rivers) +
      tm_lines(col = "#97FFFF", lwd = 2)
  }
  
  # Proposed IPCAs
  if ("Proposed IPCAs*" %in% visible) {
    map <- map +
      tm_shape(proposed_ipcas) +
      tm_polygons(
        col = "black",
        border.col = NA,
        lwd= 0,
        alpha = 0.2
      )
  }
  
  # Caribou herds (usually always visible)
  if ("Caribou herds" %in% visible) {
    map <- map +
      tm_shape(caribouherds) +
      tm_polygons(
        col = "HERD",
        border.col = NA,
        lwd= 0,
        palette = herd_pal(length(unique(caribouherds$HERD))),
        alpha = 0.6
      )
  }
  
  # Critical mineral occurrences
  if ("Critical mineral occurrences" %in% visible) {
    map <- map +
      tm_shape(critical_occ) +
      tm_symbols(
        col = "#8B7D6B",
        size = 0.4,
        shape = 21,
        border.col = "#8B7D6B"
      )
  }
  
  if ("Priority critical mineral occurrences" %in% visible) {
    map <- map +
      tm_shape(priority_occ) +
      tm_symbols(
        col = "#EE6363",
        size = 0.4,
        shape = 21,
        border.col = "#EE6363"
      )
  }
  
  # Placers Claims
  if ("Placer Claims" %in% visible) {
    placers <- rv$layers_rv$placers
    map <- map +
      tm_shape(placers) +
      tm_polygons(
        col = '#666666',
        border.col = NA,
        lwd= 0,
        alpha = 1
      )
  }
  
  # Quartz Claims
  if ("Quartz Claims" %in% visible) {
    quartz <- rv$layers_rv$quartz
    map <- map +
      tm_shape(quartz) +
      tm_polygons(
        col = '#CCCCCC',
        border.col = NA,
        lwd= 0,
        alpha = 1
      )
  }
  
  # Mining Claims
  if ("Mining Claims" %in% visible) {
    mines <- rv$statslayers_rv$mines
    map <- map +
      tm_shape(mines) +
      tm_polygons(
        col = '#666666',
        border.col = NA,
        lwd= 0,
        alpha = 1
      )
  }
  
  # Areal disturbances
  if ("Areal disturbances" %in% visible) {
    poly <- rv$statslayers_rv$poly
    map <- map +
      tm_shape(poly) +
      tm_polygons(
        col = '#660000',
        border.col = NA,
        lwd= 0,
        alpha = 1
      )
  }
  
  # Linear disturbances
  if ("Linear disturbances" %in% visible) {
    line <- rv$statslayers_rv$line
    map <- map +
      tm_shape(line) +
      tm_lines(col = "#CC3333", lwd = 1)
  }
  
  # Fires
  if ("Fires" %in% visible) {
    fires <- rv$statslayers_rv$fires
    fires$CAUSE_LABEL <- dplyr::case_when(
      fires$CAUSE == "Natural" ~ "Lightning",
      fires$CAUSE == "Human" ~ "Human",
      is.na(fires$CAUSE) | fires$CAUSE == "Undetermined" ~ "Unknown",
      TRUE ~ "Unknown"  # Catch any other unexpected cases
    )
    
    map <- map +
      tm_shape(fires) +
      tm_polygons(
        col = "CAUSE_LABEL",
        border.col = NA,
        lwd= 0,
        palette = fire_pal,
        alpha = 1,
        legend.show = FALSE
      )
  }
  
  #######################
  # Footprint
  #######################
  if ("Disturbed areas (human)" %in% visible) {
    footprint_sf <- rv$footprint_sf()
    map <- map +
      tm_shape(footprint_sf) +
      tm_polygons(
        col = 'black',
        border.col = NA,
        lwd= 0,
        alpha = 0.5
      )
  }
  if ("Disturbed areas (human + fires)" %in% visible) {
    footprintfire_sf <- rv$footprintfire_sf()
    map <- map +
      tm_shape(footprintfire_sf) +
      tm_polygons(
        col = 'black',
        border.col = NA,
        lwd= 0,
        alpha = 0.5
      )
  }
  if ("Undisturbed areas" %in% visible) {
    intactness_sf <- rv$intactness_sf()
    map <- map +
      tm_shape(intactness_sf) +
      tm_polygons(
        col = '#336633',
        border.col = NA,
        lwd= 0,
        alpha = 0.5
      )
  }
  
  #######################
  # Other dist
  #######################
  if ("Other linear disturbances" %in% visible) {
    other_line <- rv$other_linedist()
    map <- map +
      tm_shape(other_line) +
      tm_lines(col = "#FF6600", lwd = 1)
  }
  if ("Other areal disturbances" %in% visible) {
    other_poly <- rv$other_polydist()
    map <- map +
      tm_shape(other_poly) +
      tm_polygons(col = "#FF9966", 
                  border.col = NA,
                  lwd= 0,
                  alpha = 0.5,
                  lwd = 1
      )
  }
  
  # IPCA planning area
  if ("LFN IPCA planning area" %in% visible) {
    map <- map +
      tm_shape(IPCA_PL) +
      tm_borders(col = "#555555", lwd = 2)
  }
  
  # KDTT
  if ("Kaska Dene Traditional Territory" %in% visible) {
    map <- map +
      tm_shape(kdtt) +
      tm_borders(col = "#660066", lwd = 2)
  }
  
  
  # final layout
  final_map <- map +
    tm_layout(
      frame = FALSE,
      legend.outside = TRUE,
      main.title = rv$herd_range(),
      main.title.position = "center"
    )
}

square_box <- function(x, y, size_in_in = 0.25, col) {
  # Convert from inches to user coordinates
  x1 <- grconvertX(x, "ndc", "user")
  y1 <- grconvertY(y, "ndc", "user")
  w  <- grconvertX(size_in_in, "inches", "user") - grconvertX(0, "inches", "user")
  h  <- grconvertY(size_in_in, "inches", "user") - grconvertY(0, "inches", "user")
  
  rect(x1, y1, x1 + w, y1 + h, col = col, border = NA)
}

create_legend_png <- function(path, visible_layers) {
  legend_report <- data.frame(
    group = c(
      "Annual range (YG)",
      "LFN IPCA planning area",
      "Kaska Dene Traditional Territory",
      "Undisturbed areas",
      "Disturbed areas (human)", 
      "Areal disturbances", 
      "Linear disturbances", 
      "Other areal disturbances",
      "Other linear disturbances",
      "Fires", "Fires", "Fires",
      "Quartz Claims", 
      "Placer Claims", 
      "Mining Claims",
      "Critical mineral occurrences",
      "Priority critical mineral occurrences",
      "Protected areas", 
      "Intact FL 2000", 
      "Intact FL 2020"
    ),
    label = c("Annual range (YG)",
              "LFN IPCA planning area",
              "Kaska Dene Traditional Territory",
              "Undisturbed areas\u00B9", 
              "Disturbed areas\u00B2", 
              "Areal disturbances", 
              "Linear disturbances", 
              "Other areal disturbances",
              "Other linear disturbances",
              "Fires (Lightning)", 
              "Fires (Human)", 
              "Fires (Unknown)",
              "Quartz Claims", 
              "Placer Claims", 
              "Mining Claims",
              "Critical mineral occurrences",
              "Priority critical mineral occurrences",
              "Protected areas", 
              "Intact FL 2000", 
              "Intact FL 2020"
    ),
    color = c('black',
              '#555555',
              "#660066",
              "#33663380", 
              "#333333", 
              "#660000", 
              "#CC3333", 
              "#FF9966",
              "#FF6600",
              "#996633", 
              "#663300", 
              "pink",
              "#999999",
              "#666666", 
              "#999999",
              "#8B7D6B",
              "#EE6363",
              "#699999",
              "#3366FF", 
              "#000066"
    ),
    type = c("line", 
             "line", 
             "line", 
             "polygon", 
             "polygon", 
             "polygon", 
             "line", 
             "polygon", 
             "line",
             "polygon", 
             "polygon", 
             "polygon", 
             "polygon", 
             "polygon", 
             "polygon", 
             "point",
             "point",
             "polygon", 
             "polygon", 
             "polygon"
    ),
    stringsAsFactors = FALSE
  )
  
  legend_report <- legend_report %>%
    dplyr::filter(group %in% visible_layers)
  n <- nrow(legend_report)
  
  png(path, width = 600, height = 800, res = 120)
  par(mar = c(1, 1, 1, 1), oma = c(0, 0, 0, 0))
  plot(NULL, xlim = c(0, 1), ylim = c(0, n+2), xaxt = "n", yaxt = "n",
       xlab = "", ylab = "", bty = "n")
  
  box_size <- 0.5   # square size in row units
  
  for (i in seq_len(n)) {
    # Row center
    y <- n - i + 0.5
    
    # Draw square
    if (legend_report$type[i] == "polygon") {
      rect(0.05, y - box_size/2, 0.2,  y + box_size/2, col = legend_report$color[i], border = NA)
    } else if (legend_report$type[i] == "line") {
      segments(0.05, y, 0.2, y, col = legend_report$color[i], lwd = 3)
    }else{
      points(0.125, y, pch = 21,  bg = legend_report$color[i], col = "black", cex = 1.5)
    }
    
    # Draw text (bigger font OK)
    text(0.25, y, legend_report$label[i], pos = 4, cex = 1.4)
  }
  
  dev.off()
}
