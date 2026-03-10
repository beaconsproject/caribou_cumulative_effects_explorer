server = function(input, output, session) {
  
  
  ################################################################################################
  # RELOAD
  observeEvent(input$reload_btn, {
    session$reload()
  })
  
  ################################################################################################
  # Control overlayGroups
  herd <- reactiveVal(c())
  herd_range <- reactiveVal(c())
  rge_selected <- reactiveVal(c())
  rge_clear <- reactiveVal(c())
  group_names <- reactiveVal(c())
  dist_names <- reactiveVal(c())
  footprint_names_old <- reactiveVal(c())
  footprint_names_new <- reactiveVal(c())
  industry_line <- reactiveVal(NULL)
  disttype_line <- reactiveVal(NULL)
  industry_poly <- reactiveVal(NULL)
  disttype_poly <- reactiveVal(NULL)
  display1_name <- reactiveVal()
  display2_name <- reactiveVal()
  display3_name <- reactiveVal()
  rast1_name <- reactiveVal()
  rast2_name <- reactiveVal()
  summaryStats <- reactiveVal(stats)
  matrix_poly <- reactiveVal()
  matrix_line <- reactiveVal()
  layers_rv <- reactiveValues(line = NULL,
                                poly = NULL,
                                mines = NULL,
                                ifl2000 = NULL,
                                ifl2020 = NULL,
                                pa2021 = NULL,
                                herds = NULL, 
                                placers = NULL,
                                quartz= NULL,
                                mines = NULL,
                              fire_sf = NULL)
  statslayers_rv <- reactiveValues(line = NULL,
                              poly = NULL,
                              mines = NULL,
                              ifl2000 = NULL,
                              ifl2020 = NULL,
                              pa2021 = NULL,
                              herds = NULL, 
                              placers = NULL,
                              quartz= NULL,
                              mines = NULL,
                              fire_sf = NULL)
  

  addGroup <- function(new_group) {
    current_groups <- group_names()  # Retrieve the current value
    if (!(new_group %in% current_groups)) {  # Check if the group is not already in the vector
      updated_groups <- c(current_groups, new_group)  # Append the new group
      group_names(updated_groups)  # Update the reactiveVal
    }
  }
  
  removeGroup <- function(group_to_remove) {
    current_groups <- group_names()  # Retrieve the current value
    updated_groups <- current_groups[current_groups != group_to_remove]  # Filter out the specified group
    group_names(updated_groups)  # Update the reactiveVal
  }
  
  ##############################################################################
  # Observe on layers names in gpkg
  lyr_names <- reactive({
    file <- NULL

    if (input$selectInput == 'Little Rancheria') {
      file <- 'www/littlerancheria.gpkg'
    } else if (input$selectInput == 'Finlayson') {
      file <- 'www/finlayson.gpkg'
    } else if (input$selectInput == 'Coal River') {
      file <- 'www/coalriver.gpkg'
    } else if (input$selectInput == 'Horseranch') {
      file <- 'www/horseranch.gpkg'
    } else if (input$selectInput == 'Labiche') {
      file <- 'www/labiche.gpkg'
    } else if (input$selectInput == 'Pelly') {
      file <- 'www/pelly.gpkg'
    } else if (input$selectInput == 'Redstone') {
      file <- 'www/redstone.gpkg'
    } else if (input$selectInput == 'South Nahanni') {
      file <- 'www/southnahanni.gpkg'
    } else if (input$selectInput == 'Tay River') {
      file <- 'www/tayriver.gpkg'
    } else if (input$selectInput == 'Wolf Lake') {
      file <- 'www/wolflake.gpkg'
    } else {
      return(NULL)
    }
    
    # Extract layer names
    herd(file)
    layers <- st_layers(file)$name
    return(layers)
  })
  
  ################################################################################################
  # Render UI for range or corridor selection
  ################################################################################################
  output$saLayerUI <- renderUI({
    req(herd())
    
    layer <- sf::st_layers(herd())
    la <- layer$name[layer$name %in% rge_list]
    if(input$selectInput == "Little Rancheria"){
      div(style = "margin-top: -30px;",  selectInput("saLayer", label = div(style = "font-size:13px;margin-top: -10px;", "Select range/corridor"), 
                    choices = la, selected = "kde_annual"))
    } else{
      div(style = "margin-top: -30px;",  selectInput("saLayer", label = div(style = "font-size:13px;margin-top: -10px;", ""), 
                                                     choices = "Annual range"))
    }
  })

  ################################################################################################
  # Render UI for level selection
  ################################################################################################
  output$polygonSelectUI <- renderUI({
    req(input$selectInput == "Little Rancheria")
    req(input$saLayer != "Annual range")
    
    layer <- sf::st_read(herd(), layer = input$saLayer, quiet = TRUE)
    
    # get unique levels
    lvls <- unique(layer$level)
    if(length(lvls) > 1){
      selectInput("polygonLevel", "Select level", choices = lvls)
    }
  })
  ################################################################################################
  # Observe on Others disturbances 
  observe({
    disable("includeOthers")
    div(
      style = "color: darkgrey;",
      updateCheckboxInput(session = getDefaultReactiveDomain(), "includeOthers", label = "Include others disturbances", value = FALSE)
    )
    req(!is.null(input$upload_lineothers) || !is.null(input$upload_polyothers))
    enable("includeOthers")

  })
  
  observe({
    if(is.null(lyr_names())){
      disable("createMatrix")
    }else{
      req(!is.null(lyr_names())) 
      if(!is.null(layers_rv$line) || !is.null(layers_rv$poly)){
        enable("createMatrix")
      } else {
        disable("createMatrix")
      }
    }
  })
  
  observe({
    disable("otherpolysize")
    req(!is.null(input$upload_polyothers))
    enable("otherpolysize")
  })
  observe({
    disable("otherlinesize")
    req(!is.null(input$upload_lineothers))
    enable("otherlinesize")
  })
  ################################################################################################
  # Observe on Mining claims
  observe({
    req(herd())
    if (is.null(layers_rv$quartz) && is.null(layers_rv$placers) && is.null(layers_rv$mines)) {
       disable("forceclaims")
     div(
        style = "color: darkgrey;",
        updateCheckboxInput(session = getDefaultReactiveDomain(), "forceclaims", label = "Include mining claims", value = FALSE)
      )
    }else{
      enable("forceclaims")
    }
  })
  
  ################################################################################################
  # Observe on Fires (checkboxInput and slider)
  observe({
    req(herd())
    if (is.null(layers_rv$fire_sf)){
      disable("forcefire")
      div(
        style = "color: darkgrey;",
        updateCheckboxInput(session = getDefaultReactiveDomain(), "forcefire", label = "Include fires", value = FALSE)
      )
    }else{
      enable("forcefire")
    }
  })
  
  observe({
    req(input$selectInput)
    req(layers_rv$fire_sf)
    req(input$forcefire)
    
    # Update max upstream slider
    max_fire <- round(max(layers_rv$fire_sf$area_ha, na.rm = TRUE), -2)
    # Update the slider input with the max value
    updateSliderInput(session = getDefaultReactiveDomain(), inputId = "firesize", max = max_fire)
    
    # Update max upstream slider
    minyear <- min(layers_rv$fire_sf$YEAR, na.rm = TRUE)
    maxyear <- max(layers_rv$fire_sf$YEAR, na.rm = TRUE)
    # Update the slider input with the max value
    updateSliderInput(session = getDefaultReactiveDomain(), inputId = "fireyear", min = minyear , max = maxyear)
  })  
  
  ################################################################################################
  # Observe on linear disturbances - disable if missing
  observe({
    req(herd())
    if (!("linear_disturbance") %in% lyr_names()){
      disable("buffer1")
    }else{
      enable("buffer1")
    }
  })

  ################################################################################################
  # Observe on areal disturbances - disable if missing
  observe({
    req(herd())
    if (!("areal_disturbance") %in% lyr_names()){
      disable("buffer2")
    }else{
      enable("buffer2")
    }
  })
  ################################################################################################
  # Observe on linear and areal for custom buffering - disable if both missing
  observe({
    req(herd())
    if (!any(c("linear_disturbance", "areal_disturbance") %in% lyr_names())){
      disable("selectBuffer")
    }else{
      enable("selectBuffer")
    }
  })
  ################################################################################################
  # Observe on Extra layers
  observe({
    req(input$display4)
    file <- input$display4$datapath
    layers <- st_layers(file)$name
    updateSelectInput(session = getDefaultReactiveDomain(), "display4a", choices = c("Select a layer", layers))
  })
  observe({
    req(input$display4)
    file <- input$display4$datapath
    layers <- st_layers(file)$name
    updateSelectInput(session = getDefaultReactiveDomain(), "display4b", choices = c("Select a layer", layers))
  })
  observe({
    req(input$display4)
    file <- input$display4$datapath
    layers <- st_layers(file)$name
    updateSelectInput(session = getDefaultReactiveDomain(), "display4c", choices = c("Select a layer", layers))
  })
  ##############################################################################
  # Read input data - REQUIRED
  ##############################################################################
  studyarea <- eventReactive(input$confHerd, {
    req(herd())
    req(input$saLayer)
    
    rge_selected(paste(input$selectInput, input$saLayer, sep= "-"))
    if (input$selectInput == "Little Rancheria") {
      layer <- st_read(herd(), input$saLayer, quiet = TRUE)
      
      lvls <- unique(layer$level)
      if(length(lvls) > 1 && !is.null(input$polygonLevel)){
        layer %>%
          dplyr::filter(level == input$polygonLevel)
      } else {
        layer
      }
    } else {
      st_read(herd(), "studyarea", quiet = TRUE)
    }
  })
  
  observeEvent(input$confHerd,{
    req(herd(),
        studyarea())
    
    # show pop-up ...
    showModal(modalDialog(
      title = "Uploading layers. Please wait...",
      easyClose = TRUE,
      footer = NULL)
    )
    
    shinyjs::hide("save_stats")

    # create switch to clip
    if (input$selectInput =="Little Rancheria"){
      if(input$saLayer == "studyarea"){
        stat_switch <- FALSE
      }else{
        stat_switch <- TRUE
      }
    }else{
      stat_switch <- FALSE
    }
    
    if ("linear_disturbance" %in% lyr_names()) {
      line_sf <- st_read(herd(), "linear_disturbance", quiet = TRUE)
      layers_rv$line <- line_sf
      statslayers_rv$line <- line_sf
      industry_line("TYPE_INDUSTRY")
      disttype_line("TYPE_DISTURBANCE")
    }
    if ("areal_disturbance" %in% lyr_names()) {
      poly_sf <- st_read(herd(), "areal_disturbance", quiet = TRUE)
      layers_rv$poly <- poly_sf
      statslayers_rv$poly <- poly_sf
      industry_poly("TYPE_INDUSTRY")
      disttype_poly("TYPE_DISTURBANCE")
    }
    if ("fires" %in% lyr_names()) {
      fi <-st_read(herd(), 'fires', quiet=T) %>%
        st_zm(drop = TRUE, what = "ZM")  %>%
        st_make_valid() %>%
        #suppressWarnings(st_cast('MULTIPOLYGON')) %>% 
        mutate(area_ha = as.numeric(st_area(.)/10000))
      addGroup("Fires")
      layers_rv$fire_sf <- fi
      statslayers_rv$fire_sf <- fi
    }
    if ("Intact_FL_2000" %in% lyr_names()) {
      la <-st_read(herd(), 'Intact_FL_2000', quiet=T)
      addGroup("Intact FL 2000")
      layers_rv$ifl2000 <- la
      statslayers_rv$ifl2000 <- la
    }
    if ("Intact_FL_2020" %in% lyr_names()) {
      la <-st_read(herd(), 'Intact_FL_2020', quiet=T)
      addGroup("Intact FL 2020")
      layers_rv$ifl2020 <- la
      statslayers_rv$ifl2020 <- la
    }
    if ("protected_areas" %in% lyr_names()) {
      la <-st_read(herd(), 'protected_areas', quiet=T)
      addGroup("Protected areas")
      layers_rv$pa2021 <- la
      statslayers_rv$pa2021 <- la
    }
    if ("Placer_Claims" %in% lyr_names()) {
      la <-st_read(herd(), 'Placer_Claims', quiet=T)
      addGroup("Placer Claims")
      layers_rv$placers <- la
      statslayers_rv$placers <- la
    }
    if ("Quartz_Claims" %in% lyr_names()) {
      la <-st_read(herd(), 'Quartz_Claims', quiet=T)
      addGroup("Quartz Claims")
      layers_rv$quartz <- la
      statslayers_rv$quartz <- la
    }
    
    if(stat_switch){
      if ("linear_disturbance" %in% lyr_names()) {
        line_sf <- st_read(herd(), "linear_disturbance", quiet = TRUE) %>%
          st_intersection(studyarea()) %>%
          st_make_valid() %>%
          st_collection_extract("LINESTRING") %>%
          st_cast("MULTILINESTRING")
        statslayers_rv$line <- line_sf
      } 
      if ("areal_disturbance" %in% lyr_names()) {
        poly_sf <- st_read(herd(), "areal_disturbance", quiet = TRUE) %>%
          st_intersection(studyarea()) %>%
          st_make_valid() %>%
          st_collection_extract("POLYGON") %>%
          st_cast("MULTIPOLYGON")
        statslayers_rv$poly <- poly_sf
      }
      if ("fires" %in% lyr_names()) {
        fi <-st_read(herd(), 'fires', quiet = TRUE) %>% 
          st_intersection(studyarea()) %>%
          suppressWarnings() %>%
          st_cast('MULTIPOLYGON') %>% 
          st_zm(drop = TRUE, what = "ZM")  %>%
          st_make_valid() %>%
          mutate(area_ha = as.numeric(st_area(geom)/10000))
        if(nrow(fi)>0){
          addGroup("Fires")
          statslayers_rv$fire_sf <- fi
        }
      }
      if ("Intact_FL_2000" %in% lyr_names()) {
        la <-st_read(herd(), 'Intact_FL_2000', quiet = TRUE) %>% 
          st_intersection(studyarea())
        if(nrow(la)>0){
          addGroup("Intact FL 2000")
          statslayers_rv$ifl2000 <- la
        }
      }
      if ("Intact_FL_2020" %in% lyr_names()) {
        la <-st_read(herd(), 'Intact_FL_2020', quiet = TRUE) %>% 
          st_intersection(studyarea())
        if(nrow(la)>0){
          addGroup("Intact FL 2020")
          statslayers_rv$ifl2020 <- la
        }
      }
      if ("protected_areas" %in% lyr_names()) {
        la <-st_read(herd(), 'protected_areas', quiet = TRUE) %>% 
          st_intersection(studyarea())
        if(nrow(la)>0){
          addGroup("Protected areas")
          statslayers_rv$pa2021 <- la
        }
      }
      if ("Caribou_Herds" %in% lyr_names()) {
        la <-st_read(herd(), 'Caribou_Herds', quiet = TRUE)
        addGroup("Caribou Herds")
        statslayers_rv$herds <- la
      }
      if ("Placer_Claims" %in% lyr_names()) {
        la <-st_read(herd(), 'Placer_Claims', quiet = TRUE) %>% 
          st_intersection(studyarea())
        if(nrow(la)>0){
          addGroup("Placer Claims")
          statslayers_rv$placers <- la
        }
      }
      if ("Quartz_Claims" %in% lyr_names()) {
        la <-st_read(herd(), 'Quartz_Claims', quiet = TRUE) %>% 
          st_intersection(studyarea())
        if(nrow(la)>0){
          addGroup("Quartz Claims")
          statslayers_rv$quartz <- la
        }
      }
      if ("Mining_Claims" %in% lyr_names()) {
        la <-st_read(herd(), 'Mining_Claims', quiet = TRUE) %>% 
          st_intersection(studyarea())
        if(nrow(la)>0){
          addGroup("Mining Claims")
          statslayers_rv$mines <- la
        }
      } 
    } 
    
  })

 ##############################################################################
  # Update fires
  ##############################################################################
  fires <- reactive({
    if(!is.null(layers_rv$fire_sf)){
      fire <- statslayers_rv$fire_sf %>%
        dplyr::filter(YEAR >= input$fireyear[1] & YEAR <= input$fireyear[2])
      return(fire)
    }else{
      return(NULL)
    }
  }) 

  ##############################################################################
  # Read input data - OTHERS
  ##############################################################################
  other_linedist <- reactive({
    layer <- NULL
    if(!is.null(input$upload_lineothers)){
      required_extensions <- c("shp", "shx", "dbf", "prj")
      infile <- input$upload_lineothers
      file_extensions <- tools::file_ext(infile$name)
      
      # Check if all required extensions are present
      if (!all(required_extensions %in% file_extensions)) {
        showModal(modalDialog(
          title = "Missing shapefile component for other linear disturbances.",
          "Please upload all required shapefile components: .shp, .shx, .dbf, and .prj.",
          easyClose = FALSE,
          footer = modalButton("OK")
        ))
        req(FALSE)
      }else{
        # Proceed if all components are present
        dir <- unique(dirname(infile$datapath))
        outfiles <- file.path(dir, infile$name)
        name <- tools::file_path_sans_ext(infile$name[1])
        
        purrr::walk2(infile$datapath, outfiles, ~file.rename(.x, .y))
        layer <- sf::st_read(file.path(dir,paste0(name, ".shp")), quiet = TRUE) %>% 
          dplyr::select(-any_of("fid")) %>%
          st_intersection(studyarea())
        
        # Handle cases where 'geometry' might not be named correctly
        if (!"geometry" %in% names(layer) && "geom" %in% names(layer)) {
          layer$geometry <- layer$geom
        }
        
        layer <- layer %>%
          sf::st_set_geometry("geometry") %>%
          sf::st_zm(drop = TRUE, what = "ZM") %>%
          sf::st_transform(st_crs(studyarea()))
      }
    }
    return(layer)
  })
  
  other_polydist <- reactive({
    layer <- NULL
    if(!is.null(input$upload_polyothers)){
      required_extensions <- c("shp", "shx", "dbf", "prj")
      infile <- input$upload_polyothers
      file_extensions <- tools::file_ext(infile$name)
      
      # Check if all required extensions are present
      if (!all(required_extensions %in% file_extensions)) {
        showModal(modalDialog(
          title = "Missing shapefile component for other areal disturbances.",
          "Please upload all required shapefile components: .shp, .shx, .dbf, and .prj.",
          easyClose = FALSE,
          footer = modalButton("OK")
        ))
        req(FALSE)
      } else {
        # Proceed if all components are present
        dir <- unique(dirname(infile$datapath))
        outfiles <- file.path(dir, infile$name)
        name <- tools::file_path_sans_ext(infile$name[1])
        
        purrr::walk2(infile$datapath, outfiles, ~file.rename(.x, .y))
        layer <- sf::st_read(file.path(dir,paste0(name, ".shp")), quiet = TRUE) %>% 
          dplyr::select(-any_of("fid")) %>%
          st_intersection(studyarea())
        
        # Handle cases where 'geometry' might not be named correctly
        if (!"geometry" %in% names(layer) && "geom" %in% names(layer)) {
          layer$geometry <- layer$geom
        }
        
        layer <- layer %>%
          sf::st_set_geometry("geometry") %>%
          sf::st_zm(drop = TRUE, what = "ZM") %>%
          sf::st_transform(st_crs(studyarea()))
      }
    }
    
    return(layer)
  })
  
  ################################################################################################
  ## extra layers
  ################################################################################################
  # Display1
  display1_sf <- reactive({
    i <- NULL
    if(input$confExtra){
      req(input$confExtra)
      if(is.null(input$extraupload)){
        return(NULL)
      } else if (input$extraupload == "extrashp"){
        if(!is.null(input$display1)){
          req(input$display1)
          i <- read_shp_from_upload(input$display1) %>%
            st_zm(drop = TRUE, what = "ZM")  %>%
            st_make_valid()
          
          shp_file <- input$display1$name[grepl("\\.shp$", input$display1$name)][1]
          name <- tools::file_path_sans_ext(shp_file)
          display1_name(name)
          
          geom_type <- unique(sf::st_geometry_type(i))
          if (any(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
            i <- suppressWarnings(sf::st_cast(i, "MULTIPOLYGON"))
          } else if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
            i <- suppressWarnings(sf::st_cast(i, "MULTILINESTRING"))
          } else if (any(geom_type %in% c("POINT", "MULTIPOINT"))) {
            i <- suppressWarnings(sf::st_cast(i, "POINT"))
          }
        }
      } else if (input$extraupload == "extragpkg"){
        req(input$display4)
        req(input$display4a)
        if(input$display4a != "Select a layer"){
          gpkg_path <- file.path(tempdir(), paste0("uploaded_", input$display4$name))
          file.copy(input$display4$datapath, gpkg_path, overwrite = TRUE)
          i <- st_read(gpkg_path, input$display4a, quiet = TRUE)
          name <- substr(input$display4a, 1, 25)
          display1_name(name)
        }
      }
    }
    return(i)
  })
  
  display2_sf <- reactive({
    i <- NULL

    if(input$confExtra){
      req(input$confExtra)
      if(is.null(input$extraupload)){
        return(NULL)
      } else if(input$extraupload == "extrashp"){
        if(!is.null(input$display2)){
          req(input$display2)
          i <- read_shp_from_upload(input$display2) %>%
            st_zm(drop = TRUE, what = "ZM")  %>%
            st_make_valid()
          
          shp_file <- input$display2$name[grepl("\\.shp$", input$display2$name)][1]
          name <- tools::file_path_sans_ext(shp_file)
          display2_name(name)
          
          geom_type <- unique(sf::st_geometry_type(i))
          if (any(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
            i <- suppressWarnings(sf::st_cast(i, "MULTIPOLYGON"))
          } else if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
            i <- suppressWarnings(sf::st_cast(i, "MULTILINESTRING"))
          } else if (any(geom_type %in% c("POINT", "MULTIPOINT"))) {
            i <- suppressWarnings(sf::st_cast(i, "POINT"))
          }
        }
      } else if (input$extraupload == "extragpkg"){
        req(input$display4)
        req(input$display4b)
        if(input$display4b != "Select a layer"){
          gpkg_path <- file.path(tempdir(), paste0("uploaded_", input$display4$name))
          file.copy(input$display4$datapath, gpkg_path, overwrite = TRUE)
          i <- st_read(gpkg_path, input$display4b, quiet = TRUE)
          name <- substr(input$display4b, 1, 25)
          display2_name(name)
        }
      }
    }
    return(i)
  })  
  
  display3_sf <- reactive({
    i <- NULL
    
    if(input$confExtra){
      req(input$confExtra)
      if(is.null(input$extraupload)){
        return(NULL)
      } else if(input$extraupload == "extrashp"){
        if(!is.null(input$display3)){
          req(input$display3)
          i <- read_shp_from_upload(input$display3) %>%
            st_zm(drop = TRUE, what = "ZM")  %>%
            st_make_valid()
          
          shp_file <- input$display3$name[grepl("\\.shp$", input$display3$name)][1]
          name <- tools::file_path_sans_ext(shp_file)
          display3_name(name)
          
          geom_type <- unique(sf::st_geometry_type(i))
          if (any(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
            i <- suppressWarnings(sf::st_cast(i, "MULTIPOLYGON"))
          } else if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
            i <- suppressWarnings(sf::st_cast(i, "MULTILINESTRING"))
          } else if (any(geom_type %in% c("POINT", "MULTIPOINT"))) {
            i <- suppressWarnings(sf::st_cast(i, "POINT"))
          }
        }
      } else if (input$extraupload == "extragpkg"){
        req(input$display4)
        req(input$display4c)
        if(input$display4c != "Select a layer"){
          gpkg_path <- file.path(tempdir(), paste0("uploaded_", input$display4$name))
          file.copy(input$display4$datapath, gpkg_path, overwrite = TRUE)
          i <- st_read(gpkg_path, input$display4c, quiet = TRUE)
          name <- substr(input$display4c, 1, 25)
          display3_name(name)
        }
      }
    }
    return(i)
  })  
  
  rast1 <- reactive({
    i <- NULL
    if(input$confExtra){
      req(input$confExtra)
      if(!is.null(input$rast1)){
        req(input$rast1)
        path <- input$rast1$datapath
        i <- raster::raster(path)  # Load raster using the raster package
        name <- sub("\\..*$", "", input$rast1$name)
        rast1_name(name)
      }
    }
    return(i)
  }) 
  
  rast2 <- reactive({
    i <- NULL
    if(input$confExtra){
      req(input$confExtra)
      if(!is.null(input$rast2)){
        req(input$rast2)
        path <- input$rast2$datapath
        i <- raster::raster(path)  # Load raster using the raster package
        name <- sub("\\..*$", "", input$rast2$name)
        rast2_name(name)
      }
    }
    return(i)
  }) 
  
  ################################################################################################
  # Render UI for the selection of column name for disturbances 
  ################################################################################################
  output$lineIndustryUI <- renderUI({
    req(input$createMatrix == TRUE)
    
    req(layers_rv$line)  # only show if line() is available
    div(
      style = "margin-top: -30px;",  
      selectInput("lineindustry", 
                label = div(style = "font-size:13px;margin-top: -10px;", ""), 
                choices = c("--industry type--",colnames(layers_rv$line)), 
                selected = "--industry type--")
    )
  })
  
  output$lineDistTypeUI <- renderUI({
    req(input$createMatrix == TRUE)
    req(layers_rv$line)
    div(
      style = "margin-top: -30px;",
      selectInput("linedisttype", 
                label = div(style = "font-size:13px;", ""), 
                choices = c("--disturbance type--", colnames(layers_rv$line)), 
                selected = "--disturbance type--")
    )
  })
  
  output$polyIndustryUI <- renderUI({
    req(input$createMatrix == TRUE)
    req(layers_rv$poly)
    div(
      style = "margin-top: -30px;",
      selectInput("polyindustry", 
                label = div(style = "font-size:13px;", ""), 
                choices = c("--industry type--",colnames(layers_rv$poly)), 
                selected = "--industry type--")
    )
  })
  
  output$polyDistTypeUI <- renderUI({
    req(input$createMatrix == TRUE)
    req(layers_rv$poly)
    div(
      style = "margin-top: -30px;",
      selectInput("polydisttype", 
                label = div(style = "font-size:13px;margin: 0px;", ""), 
                choices = c("--disturbance type--",colnames(layers_rv$poly)), 
                selected = "--disturbance type--")
    )
  })

  mines_all <- reactive({
    geoms <- list(layers_rv$quartz, layers_rv$placers, layers_rv$mines) |>
    purrr::compact() |>                # removes NULLs
    purrr::map(sf::st_geometry)       # extract just the geometries

  # If no layers, return NULL
  if (length(geoms) == 0) return(NULL)

  # Combine geometries into one sf object
  sf::st_as_sf(sf::st_union(do.call(c, geoms)))
  })
  
  ########################################################
 observeEvent(input$confClassify, {
   if (input$selectInput == "Please select"){
     showModal(modalDialog(
       title = "Missing herd and range/corridor",
       "Before proceeding, please select a caribou herd and range/corridor.",
       easyClose = TRUE,
       footer = NULL)
     )
   }else{
     req(herd())

     if (!is.null(layers_rv$line)) {
       if(input$createMatrix){
         industry_line(input$lineindustry)
         disttype_line(input$linedisttype)
       }
     }
     if (!is.null(layers_rv$poly)) {
       if(input$createMatrix){
         industry_poly(input$polyindustry)
         disttype_poly(input$polydisttype)
       }
     }
   }
  })
  
  output$linear_matrix_ui <- renderUI({
    if (is.null(layers_rv$line)) {
      tags$p("NONE", style = "color: gray; font-style: italic;")
    } else {
      # Build matrix
      
      #req(industry_line(), disttype_line(), input$buffer1)
      industry_line <- industry_line()
      disttype_line <- disttype_line()
      
      line_tibble <- statslayers_rv$line %>%
        st_drop_geometry() %>%
        {
          data <- .
          industry_col <- if (!is.null(industry_line) && industry_line %in% colnames(data)) data[[industry_line]] else "NONE"
          dist_col <- if (!is.null(disttype_line) && disttype_line %in% colnames(data)) data[[disttype_line]] else "NONE"
          
          data %>%
            mutate(
              TYPE_FEATURE = "Linear",
              BUFFER_SIZE_M = input$buffer2,
              TYPE_INDUSTRY = industry_col,
              TYPE_DISTURBANCE = dist_col
            )
        }
      line_summary <- if (is.null(statslayers_rv$line)) {
        tibble(
          TYPE_INDUSTRY = "NONE",
          TYPE_DISTURBANCE = "NONE",
          AREA_KM2 = 0
        )
      } else {
        data <- statslayers_rv$line
        data <- data %>%
          mutate(
            length_km = st_length(statslayers_rv$line) / 1000,
            TYPE_INDUSTRY = if (!is.null(industry_line) && industry_line %in% colnames(data)) data[[industry_line]] else "NONE",
            TYPE_DISTURBANCE = if (!is.null(disttype_line) && disttype_line %in% colnames(data)) data[[disttype_line]] else "NONE"
          ) %>%
          st_drop_geometry() %>%
          group_by(TYPE_INDUSTRY, TYPE_DISTURBANCE) %>%
          summarize(LENGTH_KM = as.numeric(round(sum(length_km), 2)))
      }
      
      line_tibble <- line_tibble %>%
        left_join(line_summary, by = c("TYPE_INDUSTRY", "TYPE_DISTURBANCE"))
      
      mline <- unique(line_tibble) %>%
        dplyr::select(any_of(c("TYPE_FEATURE", "TYPE_INDUSTRY", "TYPE_DISTURBANCE", "BUFFER_SIZE_M", "LENGTH_KM"))) %>%
        as.matrix()
      
      matrix_line(mline)
      
      # Return the matrixInput to UI
      matrixInput("linear_buffers",
                  value = mline,
                  rows = list(names = FALSE, extend = TRUE),
                  cols = list(names = TRUE))
    }
  })  
      
  output$areal_matrix_ui <- renderUI({
    if (is.null(statslayers_rv$poly)) {
      tags$p("NONE", style = "color: gray; font-style: italic;")
    } else {
      #req(industry_poly, disttype_poly, input$buffer2)
      industry_poly <- industry_poly()
      disttype_poly <- disttype_poly()
      
      poly_tibble <- statslayers_rv$poly %>%
        st_drop_geometry() %>%
        {
          data <- .
          industry_col <- if (!is.null(industry_poly) && industry_poly %in% colnames(data)) data[[industry_poly]] else "NONE"
          dist_col <- if (!is.null(disttype_poly) && disttype_poly %in% colnames(data)) data[[disttype_poly]] else "NONE"
          
          data %>%
            mutate(
              TYPE_FEATURE = "Areal",
              BUFFER_SIZE_M = input$buffer2,
              TYPE_INDUSTRY = industry_col,
              TYPE_DISTURBANCE = dist_col
            )
        }
      
      poly_summary <- if (is.null(statslayers_rv$poly)) {
        tibble(
          TYPE_INDUSTRY = "NONE",
          TYPE_DISTURBANCE = "NONE",
          AREA_KM2 = 0
        )
      } else {
        data <- statslayers_rv$poly
        data <- data %>%
          mutate(
            area_km2 = as.numeric(st_area(data)) / 1e6,
            TYPE_INDUSTRY = if (!is.null(industry_poly) && industry_poly %in% colnames(data)) data[[industry_poly]] else "NONE",
            TYPE_DISTURBANCE = if (!is.null(disttype_poly) && disttype_poly %in% colnames(data)) data[[disttype_poly]] else "NONE"
          ) %>%
          st_drop_geometry() %>%
          group_by(TYPE_INDUSTRY, TYPE_DISTURBANCE) %>%
          summarize(AREA_KM2 = round(sum(area_km2, na.rm = TRUE), 5), .groups = "drop")
      }
      
      poly_tibble <- poly_tibble %>%
        left_join(poly_summary, by = c("TYPE_INDUSTRY", "TYPE_DISTURBANCE"))
      
      mpoly <- unique(poly_tibble) %>%
        dplyr::select(any_of(c("TYPE_FEATURE", "TYPE_INDUSTRY", "TYPE_DISTURBANCE", "BUFFER_SIZE_M", "AREA_KM2"))) %>%
        as.matrix()
      
      matrix_poly(mpoly)
      matrixInput("areal_buffers",
                  value = mpoly,
                  rows = list(names = FALSE, extend = TRUE),
                  cols = list(names = TRUE))
    }
  })    
  
  ################################################################################################
  # Observe on buffer 
  observe({
    req(input$selectBuffer)
    if (input$selectBuffer=='custom_buffers') {
      updateTabsetPanel(getDefaultReactiveDomain(), "one", selected = "Custom buffers")
    } else {
      updateTabsetPanel(getDefaultReactiveDomain(), "one", selected = "Mapview")
    }
  })
  
  # Observe on tabset when generating footprint
  observeEvent(input$goButton,{
    updateTabsetPanel(getDefaultReactiveDomain(), "one", selected = "Mapview")
  })
  ##############################################################################
  # Buffer disturbances and calculate footprint and intactness
  ##############################################################################
  footprint_sf <- reactive({
    
    if(input$confHerd[1]==0){
      showModal(modalDialog(
        title = "Missing source dataset confirmation",
        "Before proceeding, please confirm the source dataset in the Select study area section.",
        easyClose = TRUE,
        footer = NULL)
      )
    }
    
    req(input$confHerd)
    
    if (!is.null(layers_rv$poly) | !is.null(layers_rv$line) | !is.null(fires()) | !is.null(mines_all())  | !is.null(other_linedist()) | !is.null(other_polydist())) {
      if (!is.null(layers_rv$poly) | !is.null(layers_rv$line) ) {
        if(input$selectInput =="usedemo"){
          industry_line <- "TYPE_INDUSTRY"
          disttype_line <- "TYPE_DISTURBANCE"
          industry_poly <- "TYPE_INDUSTRY"
          disttype_poly <- "TYPE_DISTURBANCE"
        }else{
          industry_line <- input$lineindustry
          disttype_line <- input$linedisttype
          industry_poly <- input$polyindustry
          disttype_poly <- input$polydisttype
        }
        
        if (is.null(input$selectBuffer) && (!is.null(layers_rv$line) || !is.null(layers_rv$poly))){
          showModal(modalDialog(
            title = "Missing buffer type confirmation",
            "Before proceeding, please confirm how disturbance layers will be buffered.",
            easyClose = TRUE,
            footer = NULL)
          )
          v1<- NULL
          v2 <- NULL
          
        } else if (input$selectBuffer== "custom_buffers") {
          if (!is.null(layers_rv$line) && nrow(layers_rv$line) > 0) {
            m1sub <- as_tibble(input$linear_buffers) %>% dplyr::select(any_of(c("TYPE_INDUSTRY", "TYPE_DISTURBANCE", "BUFFER_SIZE_M"))) %>%      
              mutate(BUFFER_SIZE_M=as.integer(BUFFER_SIZE_M))
            line <- layers_rv$line %>%
              mutate(
                TYPE_INDUSTRY = if (!is.null(industry_line) && industry_line %in% colnames(.)) .[[industry_line]] else "NONE",
                TYPE_DISTURBANCE = if (!is.null(disttype_line) && disttype_line %in% colnames(.)) .[[disttype_line]] else "NONE"
              ) %>%
              left_join(m1sub, by = c("TYPE_INDUSTRY", "TYPE_DISTURBANCE")) %>% 
              filter(!is.na(BUFFER_SIZE_M))
            v1 <- st_union(st_buffer(line, line$BUFFER_SIZE_M))
          } else { v1 <- NULL}
          if (!is.null(layers_rv$poly) && nrow(layers_rv$poly) > 0) {
            m2sub <- as_tibble(input$areal_buffers) %>% dplyr::select(any_of(c("TYPE_INDUSTRY", "TYPE_DISTURBANCE", "BUFFER_SIZE_M"))) %>% 
              mutate(BUFFER_SIZE_M=as.integer(BUFFER_SIZE_M))
            poly <- layers_rv$poly %>%
              mutate(
                TYPE_INDUSTRY = if (!is.null(industry_line) && industry_line %in% colnames(.)) .[[industry_line]] else "NONE",
                TYPE_DISTURBANCE = if (!is.null(disttype_line) && disttype_line %in% colnames(.)) .[[disttype_line]] else "NONE"
              ) %>%
              left_join(m2sub, by = c("TYPE_INDUSTRY", "TYPE_DISTURBANCE")) %>% 
              filter(!is.na(BUFFER_SIZE_M))
          
            v2 <- st_union(st_buffer(poly, poly$BUFFER_SIZE_M))
          } else { v2 <- NULL}
        }else {
          if (!is.null(layers_rv$line) && nrow(layers_rv$line) > 0) {
            v1 <- st_union(st_buffer(layers_rv$line, input$buffer1)) %>%
              st_sf()
          } else { v1 <- NULL}
          if (!is.null(layers_rv$poly) && nrow(layers_rv$poly) > 0) {
            v2 <- st_union(st_buffer(layers_rv$poly, input$buffer2)) %>%
              st_sf()
          } else { v2 <- NULL}
        } 
      } else{
        v1<- NULL
        v2 <- NULL
      }
      
      if(input$includeOthers) {
        if(!is.null(other_linedist())){
          v3 <- st_union(st_buffer(other_linedist(), input$otherlinesize)) %>% 
            st_sf()
        }else { v3 <- NULL}
        
        if(!is.null(other_polydist())){
          v4 <- st_union(st_buffer(other_polydist(), input$otherpolysize)) %>% 
            st_sf()
        } else { v4 <- NULL}
      } else { 
        v3 <- NULL
        v4 <- NULL
      }
      
      if(input$forceclaims & ('Quartz_Claims' %in% lyr_names() | 'Placer_Claims' %in% lyr_names() | 'Mining_Claims' %in% lyr_names())) {
        if ('Quartz_Claims' %in% lyr_names() & !'Placer_Claims' %in% lyr_names()) {
          v5 <- st_union(st_buffer(layers_rv$quartz, input$minesize)) %>% 
            st_sf()
        } else if ('Placer_Claims' %in% lyr_names() & !'Quartz_Claims' %in% lyr_names()) {
          v5 <- st_union(st_buffer(layers_rv$placers, input$minesize)) %>% 
            st_sf()
        } else if ('Mining_Claims' %in% lyr_names()) {
          v5 <- st_union(st_buffer(layers_rv$mines, input$minesize)) %>% 
            st_sf()
        } else {
          v5a <- st_union(st_buffer(layers_rv$placers, input$minesize)) %>% 
            st_sf()
          v5b <- st_union(st_buffer(layers_rv$quartz, input$minesize)) %>% 
            st_sf()
          v5 <- st_union(v5a, v5b)
        }
      } else { v5 <- NULL}
      v_list <- list(v1, v2, v3, v4, v5)
      v_valid <- Filter(Negate(is.null), v_list)
      if (length(v_valid) > 0) {
        v_combined <- do.call(c, lapply(v_valid, st_geometry))
        v_combined_sf <- st_sf(geometry = v_combined)
        v_union <- st_union(v_combined_sf)
        v <- st_intersection(v_union, studyarea()) %>% 
          st_sf()
      } else {
        v <- NULL
      }
      return(v)
    }
  })
  
  footprintfire_sf <- reactive({
    if(input$forcefire & 'fires' %in% lyr_names()) {
      fires_sf <- fires() %>%
        dplyr::filter(area_ha > input$firesize)
      v6 <- st_union(fires_sf) %>% 
        st_sf()
      if(!is.null(footprint_sf())){
        v_union <- st_union(footprint_sf(), v6) %>% 
          st_sf()
      }else{
        v_union <- v6
      }
      v <- st_intersection(v_union, studyarea())
    } else { v <- NULL}
    
    return(v)
  })
  
  intactness_sf <- reactive({
    req(studyarea())
    
    footprint_names_init <- c()
    if (input$forcefire &  !is.null(footprintfire_sf())) {
      if(is.null(nrow(footprintfire_sf()))){
        ifl <- studyarea()
        footprint_names_init <- "No disturbed areas"
      }else{
        ifl <- st_difference(studyarea(), footprintfire_sf()) %>%
          dplyr::select(any_of(c("geom", "geometry")))
        footprint_names_init <- "Disturbed areas (human + fires)"
      }
    } else {
      if(length(footprint_sf())==0){
        ifl <- studyarea()
        footprint_names_init <- "No disturbed areas"
      }else{
        ifl <- st_difference(studyarea(), footprint_sf()) %>%
          dplyr::select(any_of(c("geom", "geometry")))
        footprint_names_init <- "Disturbed areas (human)"
      }
    }
    
    footprint_names_new(footprint_names_init)
    x <- suppressWarnings(st_cast(ifl, "POLYGON"))
    x <- mutate(x, area_km2=as.numeric(st_area(x)/1000000))
    y <- filter(x, area_km2 > input$area1)
    return(y)
  })
  
  
  ######################################################
  ##  SERVE USER GUIDE SECTION
  ######################################################
  output$guide_ui <- renderUI({
    req(input$tabs)  # 'sidebar' is the id of your sidebarMenu
    
    guide_file <- switch(input$tabs,
                         "select" = "docs/select_guide.md",
                         "buffer" = "docs/buffer_guide.md",
                         "download" = "docs/dwd_guide.md",
                         NULL
    )
    
    if (!is.null(guide_file) && file.exists(guide_file)) {
      includeMarkdown(guide_file)
    } else {
      tags$p("No user guide available for this section.")
    }
  })
  
  
  ##############################################################################
  # View initial set of maps
  ##############################################################################
  output$map1 <- renderLeaflet({
    map_bounds1 <- IPCA_PL %>% st_bbox() %>% as.character()
    
    proposed_pal <- colorFactor(
      palette = c("purple", "orange", "green"),
      domain = proposed_ipcas$Name
    ) 
    label_points <- st_point_on_surface(proposed_ipcas)
    label_points$Name <- c("Little Rancheria", "Tu Ball", "Tū Chō")
    
    group_names(c("Mineral occurences", "Critical mineral occurrences", "Priority critical mineral occurrences"))
    
    leaflet(options = leafletOptions(attributionControl=FALSE)) %>%
      #fitBounds(lng1 = -121, lat1 = 44, lng2 = -65, lat2 = 78) %>%
      fitBounds(map_bounds1[1], map_bounds1[2], map_bounds1[3], map_bounds1[4]) %>%
      addMapPane(name = "ground", zIndex=380) %>%
      addMapPane(name = "top", zIndex=420) %>%
      addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = FALSE)) %>%
      addProviderTiles("Esri.WorldImagery", group="Esri.WorldImagery") %>%
      addProviderTiles("Esri.WorldTopoMap", group="Esri.WorldTopoMap")%>% 
      addTiles(urlTemplate = "", group = "Blank Background") %>%
      addPolygons(data=lakes, color='#97FFFF', fill=F,  opacity = 1, weight=2, group="Lakes", options = leafletOptions(pane = "ground")) %>%
      addPolylines(data=rivers, color='#97FFFF', opacity = 1, weight=2, group="Rivers", options = leafletOptions(pane = "ground")) %>%
      addCircleMarkers(data = critical_occ, radius = 1, color = "#8B7D6B", fillOpacity = 1, group = "Critical mineral occurrences") %>%
      addCircleMarkers(data = mine_occ, radius = 1, color = "#FFD700", fillOpacity = 1, group = "Mineral occurences") %>%
      addCircleMarkers(data = priority_occ, radius = 1, color = "#EE6363", fillOpacity = 1, group = "Priority critical mineral occurrences") %>%
      
      addPolygons(data=IPCA_PL, color='black', fill=F,  opacity = 1, weight=2, group="IPCA planning area", options = leafletOptions(pane = "ground")) %>%
      addPolygons(data=kdtt, color='red', fill=F, weight=2, group="Kaska Dene Traditional Territory", options = leafletOptions(pane = "ground")) %>%
      addPolygons(data=proposed_ipcas, color = ~proposed_pal(Name), fillColor = ~proposed_pal(Name), fillOpacity = 0.2, weight=2, group="Proposed IPCAs", options = leafletOptions(pane = "ground")) %>%
      addLabelOnlyMarkers(data = label_points, label = ~Name, labelOptions = labelOptions(noHide = TRUE, direction = "center", textOnly = TRUE, style = list("font-weight"="bold","font-size"="14px","color"="black")), group = "Proposed IPCAs") %>%
      addPolygons(data=caribouherds, color='black', fill="grey", fillOpacity = 0.1, weight=3, layerId = caribouherds$HERD, popup = ~HERD, group="Caribou herds", options = leafletOptions(pane = "top")) %>% 
      addLayersControl(position = "topright",
                       baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery", "Blank Background"),
                       overlayGroups = c("Caribou herds", "Proposed IPCAs", group_names()),
                   options = layersControlOptions(collapsed = FALSE))%>%
      hideGroup(c(group_names()))
  })
  
  observeEvent(input$confHerd,{
    req(input$confHerd)
    req(studyarea())
  
    leafletProxy("map1") %>% 
      clearGroup(rge_clear()) %>%
      clearGroup("Caribou herds") %>%
      clearGroup("Proposed IPCAs") %>%
      clearGroup("Linear disturbances") %>%
      clearGroup("Areal disturbances") %>%
      clearGroup("Other linear disturbances") %>%
      clearGroup("Other areal disturbances") %>%
      clearGroup("Undisturbed areas") %>%
      clearGroup("Fires") %>%
      clearGroup("Protected areas") %>%
      clearGroup("Intact FL 2000") %>%
      clearGroup("Intact FL 2020") %>%
      clearGroup("Mining Claims") %>%
      clearGroup("Placer Claims") %>%
      clearGroup("Quartz Claims") %>%
      clearGroup("Caribou Herds")
    
    sa <- st_transform(studyarea(), 4326)
    map_bounds1 <- sa %>% st_bbox() %>% as.character()
    
    leafletProxy("map1") %>%
        fitBounds(map_bounds1[1], map_bounds1[2], map_bounds1[3], map_bounds1[4]) %>%
        addPolygons(data=sa, color='#663399', fill=F, opacity = 1, weight=3, group=rge_selected(), options = leafletOptions(pane = "top")) %>%
      
        addLayersControl(position = "topright",
                       baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery"),
                       overlayGroups = c(rge_selected()),
                       options = layersControlOptions(collapsed = FALSE)) 
    
    rge_clear(rge_selected())  
    herd_range(paste0(input$selectInput, "-", rge_selected()))
    dist_names_new <- c()
    group_names_new <- c(group_names())
    # Disturbance
    poly <- isolate(layers_rv$poly)
    if(!is.null(poly)){
      poly <- st_transform(poly, 4326)
      leafletProxy("map1") %>% addPolygons(data=poly, color = '#660000', fill=T, fillColor='#660000', fillOpacity=0.8, weight=1, group="Areal disturbances", options = leafletOptions(pane = "top")) 
      dist_names_new <- c(dist_names_new,"Areal disturbances")
    }
    line <- isolate(layers_rv$line)
    if(!is.null(line)){
      line <- st_transform(line, 4326)
      leafletProxy("map1") %>% addPolylines(data=line, color = "#CC3333",  weight=2, group="Linear disturbances", options = leafletOptions(pane = "top")) 
      dist_names_new <- c(dist_names_new,"Linear disturbances")
    }
    # Optional
    fires <- isolate(layers_rv$fire_sf)
    if(!is.null(fires)){
        fires <- st_transform(fires, 4326)
        
        fires$CAUSE_LABEL <- dplyr::case_when(
          fires$CAUSE == "L" ~ "Lightning",
          fires$CAUSE == "H" ~ "Human",
          is.na(fires$CAUSE) | fires$CAUSE == "" ~ "Unknown",
          TRUE ~ "Unknown"  # Catch any other unexpected cases
        )
        pal <- colorFactor(
          palette = c("#996633", "#663300", "pink"),
          domain = c("Lightning", "Human", "Unknown"),
        )
        
        leafletProxy("map1") %>% addPolygons(data=fires, fill=T, stroke=F, fillColor=~pal(CAUSE_LABEL), fillOpacity=0.8, group="Fires", options = leafletOptions(pane = "top")) 
        group_names_new <- c(group_names_new, "Fires")
    }
    ifl2000 <- isolate(layers_rv$ifl2000)
    if(!is.null(ifl2000)){
      ifl2000 <- st_transform(ifl2000, 4326)
      leafletProxy("map1") %>% addPolygons(data=ifl2000, fill=T, stroke=F, fillColor='#3366FF', fillOpacity=0.5, group="Intact FL 2000", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Intact FL 2000")
    }
    ifl2020 <- isolate(layers_rv$ifl2020)
    if(!is.null(ifl2020)){
      ifl2020 <- st_transform(ifl2020, 4326)
      leafletProxy("map1") %>% addPolygons(data=ifl2020, fill=T, stroke=F, fillColor='#000066', fillOpacity=0.5, group="Intact FL 2020", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Intact FL 2020")
    }
    pa2021 <- isolate(layers_rv$pa2021)
    if(!is.null(pa2021)){
      pa2021 <- st_transform(pa2021, 4326)
      leafletProxy("map1") %>% addPolygons(data=pa2021, fill=T, stroke=F, fillColor='#699999', fillOpacity=1,  group="Protected areas", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Protected areas")
    }
    herds <- isolate(layers_rv$herds)
    if(!is.null(herds)){
      herds <- st_transform(herds, 4326)
      leafletProxy("map1") %>% addPolygons(data=herds, color= '#666666', fill=T, fillColor='#666666', weight=1, fillOpacity = 1, group="Caribou Herds", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Caribou Herds")
    }
    placers <- isolate(layers_rv$placers)
    if(!is.null(placers)){
      placers <- st_transform(placers, 4326)
      leafletProxy("map1") %>% addPolygons(data=placers, color= '#666666', fill=T, fillColor='#666666', weight=1, fillOpacity = 1, group="Placer Claims", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Placer Claims")
    }
    quartz <- isolate(layers_rv$quartz)
    if(!is.null(quartz)){
      quartz <- st_transform(quartz, 4326)
      leafletProxy("map1") %>% addPolygons(data=quartz, color = '#CCCCCC', fill=T, fillColor='#CCCCCC', weight=1, fillOpacity = 1, group="Quartz Claims", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Quartz Claims")
    }
    
    mines <- isolate(layers_rv$mines)
    if(!is.null(mines)){
      mines <- st_transform(mines, 4326)
      leafletProxy("map1") %>% addPolygons(data=mines, color='#666666', fill=T, fillColor='#666666', weight=1, fillOpacity = 1, group="Mining Claims", options = leafletOptions(pane = "ground")) 
      group_names_new <- c(group_names_new, "Mining Claims")
    } 
    
    leafletProxy("map1") %>%
      addLayersControl(position = "topright",
                       baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery"),
                       overlayGroups = c(rge_selected(), dist_names_new, group_names_new),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      hideGroup(c(group_names()))
        
    # Close the modal once processing is done
    dist_names(dist_names_new)
    group_names(group_names_new)
    removeModal()
    
        ################################################################################################
    # Add modal if layers are missing
    if(!any(c('linear_disturbance', 'areal_disturbance', 'fires', 'Placer_Claims', 'Quartz_Claims', 'Mining_Claims') %in% lyr_names())){
      showModal(modalDialog(
        title = "No disturbance provided in the GPKG.",
        "Please provide a GPKG that has either 'linear_disturbance', 'areal_disturbance', 'fires' or 'Mining_Claims' as a layer",
        easyClose = FALSE,
        footer = modalButton("OK")
      ))
      return()  # Stop further execution  
    }
      
      
    if(!any(c('linear_disturbance', 'areal_disturbance', 'Placer_Claims', 'Quartz_Claims', 'Mining_Claims') %in% lyr_names()) &&
       'fires' %in% lyr_names() &&
       is.null(other_linedist()) &&
       is.null(other_polydist())  
      ){
        showModal(modalDialog(
          title = "Only wildfires will be used to generate the footprint and intactness layers",
          "You can proceed with wildfires. ",
          easyClose = FALSE,
          footer =  modalButton("OK"))
        )  
    }
      
    if(!all(c('linear_disturbance', 'areal_disturbance', 'fires') %in% lyr_names()) & any(c('Placer_Claims', 'Quartz_Claims', 'Mining_Claims') %in% lyr_names())){
        showModal(modalDialog(
          title = "Only mining claims will be used to generate the footprint and intactness layers",
          easyClose = FALSE,
          footer =  modalButton("OK"))
        )  
    }
  })
  
  observeEvent(input$confUpload,{ 
    
    if (is.null(other_polydist()) && is.null(other_linedist())){
      showModal(modalDialog(
        title = "Missing upload of other disturbances",
        "Please upload other linear or areal disturbances before confirming the upload.",
        easyClose = TRUE,
        footer = NULL)
      )
    }
    
    leafletProxy("map1") %>% 
      clearGroup("Other linear disturbances") %>%
      clearGroup("Other areal disturbances")
    
   dist_names_new <- dist_names()
    
    other_polydist <- isolate(other_polydist())
    if(!is.null(other_polydist)){
      other_polydist <- st_transform(other_polydist, 4326)
      leafletProxy("map1") %>% addPolylines(data = other_polydist, color = "#FF9966", fill=T, fillColor='#FF9966', fillOpacity=0.8, weight=1, group="Other areal disturbances")
      dist_names_new <- c(dist_names_new, "Other areal disturbances")
    }
    other_linedist <- isolate(other_linedist())
    if(!is.null(other_linedist)){
      other_linedist <- st_transform(other_linedist, 4326)
      leafletProxy("map1") %>% addPolylines(data = other_linedist, color = "#FF6600",  weight=2 , group="Other linear disturbances")
      dist_names_new <- c(dist_names_new, "Other linear disturbances")
    }
  
    leafletProxy("map1") %>%
      addLayersControl(position = "topright",
                       baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery"),
                       overlayGroups = c(rge_selected(), dist_names_new, group_names()),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      hideGroup(c(group_names()))
    
    dist_names(dist_names_new)
  }) 
  ###########################
  # Map extra layers
  observeEvent(input$confExtra,{ 
    
    map1 <- leafletProxy("map1") %>%
      clearGroup(display1_name()) %>%
      clearGroup(display2_name()) %>%
      clearGroup(display3_name()) %>%
      clearGroup(rast1_name())
    
    group_names_new <- group_names()
    
    if (isMappable(display1_sf())) { 
      display1 <- st_transform(display1_sf(), 4326)
      geom_type <- unique(sf::st_geometry_type(display1))
      if (any(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
        map1 <- map1 %>% addPolygons(data=display1,  fillColor='#663300', stroke=F, fill = T, fillOpacity = 0.5, group=display1_name(), options = leafletOptions(pane = "ground"))
      } else if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
        map1 <- map1 %>% addPolylines(data = display1, color = '#663300', weight = 2, group = display1_name(), options = leafletOptions(pane = "ground"))
      } else if (any(geom_type %in% c("POINT", "MULTIPOINT"))) {
        map1 <- map1 %>% addCircleMarkers(data = display1, color = '#663300', radius = 5, fillOpacity = 0.7, group = display1_name(), options = leafletOptions(pane = "ground"))
      } else {
        showNotification("Unsupported geometry type", type = "error")
      }

      group_names_new <- c(group_names_new,display1_name())
    } 
    
    if (isMappable(display2_sf())) { 
      display2 <- st_transform(display2_sf(), 4326)
      geom_type <- unique(sf::st_geometry_type(display2))
      if (any(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
        map1 <- map1 %>% addPolygons(data=display2,  fillColor='#330066', stroke=F, fill = T, fillOpacity = 0.5, group=display2_name(), options = leafletOptions(pane = "ground"))
      } else if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
        map1 <- map1 %>% addPolylines(data = display2, color = '#330066', weight = 2, group = display2_name(), options = leafletOptions(pane = "ground"))
      } else if (any(geom_type %in% c("POINT", "MULTIPOINT"))) {
        map1 <- map1 %>% addCircleMarkers(data = display2, color = '#330066', radius = 5, fillOpacity = 0.7, group = display2_name(), options = leafletOptions(pane = "ground"))
      } else {
        showNotification("Unsupported geometry type", type = "error")
      }

      group_names_new <- c(group_names_new,display2_name())
    } 
    if (isMappable(display3_sf())) { 
      display3 <- st_transform(display3_sf(), 4326)
      geom_type <- unique(sf::st_geometry_type(display3))
      if (any(geom_type %in% c("POLYGON", "MULTIPOLYGON"))) {
        map1 <- map1 %>% addPolygons(data=display3,  fillColor='#003333', stroke=F, fill = T, fillOpacity = 0.5, group=display3_name(), options = leafletOptions(pane = "ground"))
      } else if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
        map1 <- map1 %>% addPolylines(data = display3, color = '#003333', weight = 2, group = display3_name(), options = leafletOptions(pane = "ground"))
      } else if (any(geom_type %in% c("POINT", "MULTIPOINT"))) {
        map1 <- map1 %>% addCircleMarkers(data = display3, color = '#003333', radius = 5, fillOpacity = 0.7, group = display3_name(), options = leafletOptions(pane = "ground"))
      } else {
        showNotification("Unsupported geometry type", type = "error")
      }
      group_names_new <- c(group_names_new,display3_name())
    } 
    
    if (!is.null(rast1())) { 
      rast1 <- raster::projectRaster(rast1(), crs = "EPSG:4326")
      
      values_rast <- raster::values(rast1)
      values_rast <- values_rast[!is.na(values_rast)]  # remove NA values
      
      pal <- colorNumeric(palette = viridis::viridis(256), domain = values_rast, na.color = "transparent")
      map1 <- map1 %>% addRasterImage(rast1,  colors = pal, opacity = 0.5, group=rast1_name(), options = leafletOptions(pane = "ground"))
      
      group_names_new <- c(group_names_new, rast1_name())
    }
    
    if (!is.null(rast2())) { 
      rast2 <- raster::projectRaster(rast2(), crs = "EPSG:4326")
      
      values_rast <- raster::values(rast2)
      values_rast <- values_rast[!is.na(values_rast)]  # remove NA values
      
      pal <- colorNumeric(palette = colorRampPalette(c("#0000FF", "#FFFF00", "#FF0000"))(256), domain = values_rast, na.color = "transparent")
      map1 <- map1 %>% addRasterImage(rast2,  colors = pal, opacity = 0.5, group=rast2_name(), options = leafletOptions(pane = "ground"))
      
      group_names_new <- c(group_names_new, rast2_name())
    }
    leafletProxy("map1") %>%
      addLayersControl(position = "topright",
                       baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery"),
                       overlayGroups = c(rge_selected(), dist_names(), group_names_new),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      hideGroup(c("Streams", "Catchments", group_names()))
    
    group_names(group_names_new)
  })  
  
  ##############################################################################
  # Update map with intactness/footprint
  ##############################################################################
  observeEvent(input$goButton,{
    
    shinyjs::show("save_stats")
    
    if(input$confHerd[1]==0){
      showModal(modalDialog(
        title = "Missing source dataset confirmation",
        "Before proceeding, please confirm the source dataset in the Select study area section.",
        easyClose = TRUE,
        footer = NULL)
      )
    }
    
    req(input$confHerd)
    
    if(is.null(input$selectBuffer) && (!is.null(layers_rv$line) || !is.null(layers_rv$poly))){
      showModal(modalDialog(
        title = "Missing buffer type confirmation",
        "Before proceeding, please confirm how disturbance layers will be buffered.",
        easyClose = TRUE,
        footer = NULL)
      )
    }
    
    # show pop-up ...
    showModal(modalDialog(
      title = "Generating footprint and intactness map. Please wait...",
      easyClose = TRUE,
      footer = NULL)
    )
    
    if(is.null(footprintfire_sf())){
      if(is.null(footprint_sf())){
        showModal(modalDialog(
          title = "No disturbance found inside the studyarea",
          easyClose = FALSE,
          footer = modalButton("OK")
        ))
        fp_sf <- NULL
      }else{
        fp_sf <- footprint_sf() %>% 
          st_as_sf() %>%
          st_transform(4326)
      }  
    }else{
      fp_sf <- footprintfire_sf() %>% 
        st_as_sf() %>%
        st_transform(4326) 
    }
    
    intact_sf <- st_transform(intactness_sf(), 4326)
    
    map1 <- leafletProxy("map1") %>%
      clearGroup('Undisturbed areas') %>%
      clearGroup(footprint_names_old())
    
    if (isMappable(intact_sf)) { 
      map1 <- map1 %>% addPolygons(data=intact_sf, color='#336633', stroke=F, fillOpacity=0.5, group='Undisturbed areas', options = leafletOptions(pane = "top")) %>%
        addLayersControl(position = "topright",
                         baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery"),
                         overlayGroups = c(rge_selected(), "Undisturbed areas", dist_names(), group_names()),
                         options = layersControlOptions(collapsed = FALSE)) %>%
        hideGroup(c(footprint_names_new(), group_names()))
    }  
    if (isMappable(fp_sf)) { 
      map1 <- map1 %>% addPolygons(data=fp_sf, color='black', stroke=F, fillOpacity=0.5, group=footprint_names_new(), options = leafletOptions(pane = "top")) %>%
        addLayersControl(position = "topright",
                         baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery"),
                         overlayGroups = c(rge_selected(), "Undisturbed areas", footprint_names_new(), dist_names(), group_names()),
                         options = layersControlOptions(collapsed = FALSE)) %>%
        hideGroup(c(footprint_names_new(), group_names()))
    } 
    
   # Close the modal once processing is done
    footprint_names_old(footprint_names_new())
    removeModal()
    
  })
  
  ##############################################################################
  # Generate statistics table
  ##############################################################################
  # Reactive for the attributes 
  aoiAttributes <- reactive({
    req(herd())
    aoi <- sum(st_area(studyarea()))

    tibble(Attribute = paste0(rge_selected(), " (range km2)"), Value = as.numeric(round(aoi / 1000000, 0)))
  })

  baseAttributes <- reactive({
    req(herd())
    
    if(input$confHerd && input$saLayer =="Select a layer"){
      showModal(modalDialog(
        title = "Please select the layer name representing the study area before proceeding.",
        easyClose = TRUE,
        footer = NULL)
      ) 
      return()
    }
    req(studyarea())
    aoi <- sum(st_area(studyarea()))
    
    # Other dist --Default to NA
    other_linevalue <- NA
    other_linelabel <- "Other linear disturbances (km)"
    other_polyvalue <- NA
    other_polylabel <- "Other areal disturbances (km2)"
    
    # If the user uploaded a shapefile via `other_dist()`
    if (!is.null(other_linedist())) {
      other_linevalue <- round(sum(st_length(other_linedist())) / 1000, 1)
      other_linelabel <- "Other linear disturbances (km)"
    }
    if (!is.null(other_polydist())) {
      other_polyvalue <- round(sum(st_area(other_polydist())) / 1e6, 1)
      other_polylabel <- "Other areal disturbances (km2)"
    }
    
    tibble(
      Attribute = c(
        "Linear disturbances (km)",
        "Areal disturbances (km2)",
        other_linelabel,
        other_polylabel,
        "Fires (%)",
        "Mining claims (%)",
        "Protected areas (%)",
        "Intact FL 2000 (%)*",
        "Intact FL 2020 (%)**"
      ),
      Value = c(
        if (is.null(statslayers_rv$line)) 0 else as.numeric(round(sum(st_length(statslayers_rv$line)) / 1000, 1)),
        if (is.null(statslayers_rv$poly)) 0 else as.numeric(round(sum(st_area(statslayers_rv$poly)) / 1000000, 1)),
        other_linevalue,
        other_polyvalue,
        if (is.null(fires())) 0 else as.numeric(round(sum(st_area(fires())) / aoi * 100, 1)),
        if (is.null(mines_all())) 0 else as.numeric(round(sum(st_area(mines_all())) / aoi * 100, 1)),
        if (is.null(statslayers_rv$pa2021)) 0 else as.numeric(round(sum(st_area(statslayers_rv$pa2021)) / aoi * 100, 1)),
        if (is.null(statslayers_rv$ifl2000)) 0 else as.numeric(round(sum(st_area(statslayers_rv$ifl2000)) / aoi * 100, 1)),
        if (is.null(statslayers_rv$ifl2020)) 0 else as.numeric(round(sum(st_area(statslayers_rv$ifl2020)) / aoi * 100, 1))
      )
    )
  })  
  output$acronym_definitions <- renderUI({
    req(input$confHerd)
    tagList(
      tags$div(
        style = "font-size: 0.85em; color: grey;",
        tags$em("*"), "Intact Forest Landscape 2000"
      ),
      tags$div(
        style = "font-size: 0.85em; color: grey;",
        tags$em("**"), "Intact Forest Landscape 2020"
      ),
      tags$br(),
      tags$div(
        tags$h5("Map Legend", style = "text-align: left; font-weight: bold; margin-bottom: 0px;"),  # Title above the image
        tags$img(src = "legend.png", width = "60%")
      ),
      tags$div(
        style = "font-size: 0.85em; color: grey;",
        "Elements in Map Legend appear on the map if present in the GeoPackage (gpkg).",
        tags$p("\u00B9",
          tags$strong("Disturbed areas"), " are regions of the study area that have been altered by human disturbance (i.e., mapped linear and areal features) and associated zone of influence (i.e., buffer). Disturbed areas may also include natural disturbances such as fire and/or potential future human disturbances by including mining claims, for example."
        ), 
        tags$p("\u00B2",
          tags$strong("Undisturbed areas"), " are regions within the study area that are not intersected by disturbed areas."
        )
      )
    )
  })
  
  # reactiveVal to store additional attributes
  additionalAttributes <- reactiveVal(NULL)
  
  # Reactive for the attributes updated by `goButton`
  observeEvent(input$goButton, {
    aoi <- sum(st_area(studyarea()))
    if (!is.null(footprintfire_sf())) {
      footprint <- st_union(footprintfire_sf()) 
    }else if (!is.null(footprint_sf())){
      footprint <- st_union(footprint_sf())
    } else{
      footprint <- NULL
    }
    
    additionalAttributes(tibble(
      Attribute = c(
        "Undisturbed areas (%)",
        "Disturbed areas (%)"
      ),
      Value = c(
        if (is.null(intactness_sf())) 0 else as.numeric(round(sum(st_area(intactness_sf())) / aoi * 100, 1)),
        if (is.null(footprint)) 0 else as.numeric(round(sum(st_area(footprint)) / aoi * 100, 1))
      )
    ))
  })
  
  # Reset additional attributes when studyarea or related inputs change
  observeEvent(c(studyarea(), statslayers_rv$poly, statslayers_rv$line, fires(), mines_all(), statslayers_rv$pa2021), {
    additionalAttributes(NULL)
  })
  
  # Combine the two sets of attributes
  output$tab1 <- renderTable({
    req(input$confHerd)
    req(baseAttributes())  # Ensure `baseAttributes` is ready
    aoi <- aoiAttributes()
    base <- baseAttributes()
    
    # Add additional attributes if the button has been pressed
    additional <- additionalAttributes()
    if (!is.null(additional)) {
      all <- bind_rows(aoi, additional, base)
    } else{
      all <- bind_rows(aoi, base)
    }
    all
  })
  
  
  observeEvent(input$save_stats,{
    req(additionalAttributes()) 
    
    aoi <- aoiAttributes()
    base <- baseAttributes()
    
    # Add additional attributes if the button has been pressed
    additional <- additionalAttributes()
    if (!is.null(additional)) {
      all <- bind_rows(aoi, additional, base)
    } else{
      all <- bind_rows(aoi, base)
    }
    all_wide <- all %>%
         tidyr::pivot_wider(names_from = Attribute, values_from = Value)
    
    # set name
    all_wide$name <- herd_range()
    
      
    # set_custom
    if(is.null(statslayers_rv$line) && is.null(statslayers_rv$poly)){
      all_wide$set_custom <- "NA"
    } else if (is.null(statslayers_rv$line) && !is.null(statslayers_rv$poly)){
      all_wide$set_custom <- ifelse(input$selectBuffer=="custom_buffers", "TRUE", paste0("FALSE_line0_poly", as.character(input$buffer2)))
    } else if (!is.null(statslayers_rv$line) && is.null(statslayers_rv$poly)){
      all_wide$set_custom <- ifelse(input$selectBuffer=="custom_buffers", "TRUE", paste0("FALSE_line", as.character(input$buffer1),"_poly0"))
    } else{
      all_wide$set_custom <- ifelse(input$selectBuffer=="custom_buffers", "TRUE", paste0("FALSE_line", as.character(input$buffer1),"_poly", as.character(input$buffer2)))
    }
    
    # include_others
    if(input$includeOthers){
      if(is.null(upload_lineothers()) && is.null(upload_polyothers())){
        all_wide$set_includeOthers <- "FALSE"
      } else if (is.null(upload_lineothers()) && !is.null(upload_polyothers())){
        all_wide$set_includeOthers <- paste0("TRUE_otherline0_otherpoly", as.character(input$otherpolysize))
      } else if (!is.null(upload_lineothers()) && is.null(upload_polyothers())){
        all_wide$set_includeOthers <- paste0("TRUE_otherline", as.character(input$otherlinesize),"_otherpoly0")
      } else{
        all_wide$set_includeOthers <- paste0("TRUE_otherline", as.character(input$otherlinesize),"_otherpoly", as.character(input$otherpolysize))
      } 
    } else{
      all_wide$set_includeOthers <- "FALSE"
    }
     
    # include_mines
    if(input$forceclaims){
      all_wide$set_mines <- paste0("TRUE_", as.character(input$minesize))
    } else{
      all_wide$set_mines <- "FALSE"
    }
    
    # include_fires
    if(input$forcefire){
      all_wide$set_fires <- "TRUE"
    } else{
      all_wide$set_fires <- "FALSE"
    }
    
    colnames(all_wide) <- c("Area_km2", "Undisturbed_per", "Disturbed_per", "Lineardist_km", "Arealdist_km2",
       "otherLinear_km", "otherAreal_km2", "Fires_per", "Mines_per", "PA2021_per", "IntactFL2000_per",
       "IntactFL2020_per", "Name", "set_custom", "set_includeOthers", "set_mines", "set_fires")
    
    updated_tbl <- bind_rows(summaryStats(), all_wide)
    summaryStats(updated_tbl)
  })
  
  output$stat_tab <- renderTable({
    summaryStats()
  })

  ##############################################################################
  # Save features to a geopackage
  ##############################################################################
  output$downloadData <- downloadHandler(
    filename = function() { paste("Caribou_CE_disturbance_explorer-", Sys.Date(), ".gpkg", sep="") },
    content = function(file) {
      
      x <- data.frame(Area_km2 = aoiAttributes()[1,2],
                      Lineardist_km  = baseAttributes()[1,2],
                      Arealdist_km2 = baseAttributes()[2,2],
                      otherLinear_km  = baseAttributes()[3,2],
                      otherAreal_km2  = baseAttributes()[4,2],
                      Fires_per = baseAttributes()[5,2],
                      Mine_per = baseAttributes()[6,2],
                      PA2021_per= baseAttributes()[7,2],
                      IntactFL2000_per = baseAttributes()[8,2],
                      IntactFL2020_per = baseAttributes()[9,2])
      colnames(x) <-c("Area_km2","Lineardist_km","Arealdist_km2","otherLinear_km","otherAreal_km2","Fires_per", "Mines_per", "PA2021_per","IntactFL2000_per","IntactFL2020_per")
      aoi <- cbind(st_union(studyarea()), x)
      if (!is.null(layers_rv$line)) st_write(layers_rv$line, dsn=file, layer='linear_disturbance', append=TRUE)
      if (!is.null(layers_rv$poly)) st_write(layers_rv$poly, dsn=file, layer='areal_disturbance', append=TRUE)
      if (!is.null(fires())) st_write(fires(), dsn=file, layer='fires', append=TRUE)
      if (!is.null(other_linedist())) st_write(other_linedist(), dsn=file, layer='other_linear_disturbances', append=TRUE)
      if (!is.null(other_polydist())) st_write(other_polydist(), dsn=file, layer='other_areal_disturbances', append=TRUE)
      if (!is.null(layers_rv$pa2021)) st_write(layers_rv$pa2021, dsn=file, layer='protected_areas', append=TRUE)
      if (!is.null(layers_rv$placers)) st_write(layers_rv$placers, dsn=file, layer='Placer_Claims', append=TRUE)
      if (!is.null(layers_rv$quartz)) st_write(layers_rv$quartz, dsn=file, layer='Quartz_Claims', append=TRUE)
      if (!is.null(layers_rv$mines)) st_write(layers_rv$mines, dsn=file, layer='mining_claims', append=TRUE)
      if (!is.null(layers_rv$herds)) st_write(layers_rv$herds, dsn=file, layer='Caribou_Herds', append=TRUE)
      if (!is.null(display1_sf())) st_write(display1_sf(), dsn=file, layer=display1_name(), append=TRUE)
      if (!is.null(display2_sf())) st_write(display2_sf(), dsn=file, layer=display2_name(), append=TRUE)
      if (!is.null(display3_sf())) st_write(display3_sf(), dsn=file, layer=display3_name(), append=TRUE)
      
      if (input$goButton) {
        x <- data.frame(Undisturbed_per = additionalAttributes()[1,2],
                        Disturbed_per  = additionalAttributes()[2,2])
        colnames(x) <-c("Undisturbed_per", "Disturbed_per")
        aoi <- cbind(aoi, x)
        st_write(aoi, dsn=file, layer='studyarea', append=FALSE)
        st_write(intactness_sf(), dsn=file, layer='undisturbed', append=TRUE)
        if (!is.null(footprintfire_sf())){
          st_write(footprintfire_sf(), dsn=file, layer='disturbed', append=TRUE)
        } else{
          st_write(footprint_sf(), dsn=file, layer='disturbed', append=TRUE)
        }
      }
       
        
    }
  )
  
  ##############################################################################
  # Save features to a geopackage
  ##############################################################################
  output$downloadStats <- downloadHandler(
    filename = function() { paste("Caribou_CE_disturbance_explorer_stats-", Sys.Date(), ".csv", sep="") },
    content = function(file) {
      
      write.csv(summaryStats(), file, row.names = FALSE)
    }
  )
  
  ##############################################################################
  # Save buffer matrix
  ##############################################################################
  output$downloadMatrix <- downloadHandler(
    filename = function() { paste("Caribou_CE_disturbance_explorer_buffer-", Sys.Date(), ".csv", sep="") },
    content = function(file) {
      line <- as.tibble(matrix_line())
      poly <- as.tibble(matrix_poly())
      matrix <- dplyr::bind_rows(line, poly)
      
      write.csv(matrix, file, row.names = FALSE)
    }
  )
}
