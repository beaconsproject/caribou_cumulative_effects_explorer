server = function(input, output, session) {
  
  # Disable action button at startup
  shinyjs::disable("downloadData")
  shinyjs::disable("confClassify")
  shinyjs::disable("confUpload")
  shinyjs::disable("confExtra")

  ################################################################################################
  # RELOAD
  observeEvent(input$reload_btn, {
    showModal(
      modalDialog(
        title = "Confirm reload",
        tagList(
          p("You are about to reload the application."),
          p("Any unsaved work or pending downloads may be lost."),
          p("Do you want to reload the app?")
        ),
        footer = tagList(
          modalButton("No"),
          actionButton("confirm_reload", "Yes", class = "btn-danger")
        ),
        easyClose = FALSE
      )
    )
  })
  
  observeEvent(input$confirm_reload, {
    removeModal()
    session$reload()
  })
  
  output$overviewMD <- renderUI({
    HTML(markdown::markdownToHTML(text = overview_md_text, fragment.only = TRUE))
  })
  ################################################################################################
  # Control overlayGroups
  reactiveValsList <-  list(herd = reactiveVal(c()),
                            herd_range = reactiveVal(c()),
                            lyr = reactiveVal(c()),
                            sa = reactiveVal(c()),
                            rge_selected = reactiveVal(c()),
                            rge_clear = reactiveVal(c()),
                            group_names = reactiveVal(c("Kaska Dene Traditional Territory","LFN IPCA planning area",  "Proposed IPCAs*", "Caribou herds")),
                            dist_names = reactiveVal(c("Critical mineral occurrences", "Priority critical mineral occurrences")),
                            range_names =reactiveVal(c()),
                            add_names =  reactiveVal(c()),
                            footprint_names_old = reactiveVal(c()),
                            footprint_names_new = reactiveVal(c()),
                            industry_line = reactiveVal(NULL),
                            disttype_line = reactiveVal(NULL),
                            industry_poly = reactiveVal(NULL),
                            disttype_poly = reactiveVal(NULL),
                            display1_sf = reactiveVal(),
                            display2_sf = reactiveVal(),
                            display3_sf = reactiveVal(),
                            display1_name = reactiveVal(),
                            display2_name = reactiveVal(),
                            display3_name = reactiveVal(),
                            rast1_name = reactiveVal(),
                            rast2_name = reactiveVal(),
                            visible_groups = reactiveVal(),
                            summaryStats = reactiveVal(stats),
                            matrix_poly = reactiveVal(),
                            matrix_line = reactiveVal(),
                            matrix_poly_other = reactiveVal(),
                            matrix_line_other = reactiveVal(),
                            intactness_sf = reactiveVal(),
                            footprint_sf = reactiveVal(),
                            footprintfire_sf = reactiveVal(),
                            report_rv = reactiveValues(step1 = NULL,
                                                       map_file = NULL),
                            report_ready = reactiveVal(0),
                            layers_rv = reactiveValues(line = NULL,
                                                       poly = NULL,
                                                       mines = NULL,
                                                       ifl2000 = NULL,
                                                       ifl2025 = NULL,
                                                       pa2021 = NULL,
                                                       herds = NULL, 
                                                       placers = NULL,
                                                       quartz= NULL,
                                                       fires = NULL,
                                                       mines_all = NULL),
                            statslayers_rv = reactiveValues(line = NULL,
                                                             poly = NULL,
                                                             ifl2000 = NULL,
                                                             ifl2025 = NULL,
                                                             pa2021 = NULL,
                                                             herds = NULL, 
                                                             placers = NULL,
                                                             quartz= NULL,
                                                             mines = NULL,
                                                             fires = NULL,
                                                            mines_all = NULL),
                            other_linedist = reactiveVal(NULL),
                            other_polydist = reactiveVal(NULL),
                            aoiAttributes = reactiveVal(NULL),
                            baseAttributes = reactiveVal(NULL),
                            additionalAttributes = reactiveVal(NULL),
                            summaryStats = reactiveVal(),
                            map_path = reactiveVal(),
                            legend_path = reactiveVal()
  )
  
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
  output$map <- renderLeaflet({
    map_bounds1 <- caribouherds %>% st_bbox() %>% as.character()

    herd_pal <- colorFactor(palette = c('#a6cee3','#1f78b4','#b2df8a','#33a02c','#fb9a99','#e31a1c','#fdbf6f','#ff7f00','#cab2d6','#6a3d9a','#ffff99','#b15928'), domain = caribouherds$HERD)
    proposed_ipcas %>%
      mutate(
        geometry = st_cast(geom, "MULTIPOLYGON")
      )
    proposed_ipcas$ipca_name <- c("Dene K'éh Kusān", "Little Rancheria ", "Ross River MOU IPCA Study Area","Toobally", "Tū Chō")
    
    leaflet(options = leafletOptions(attributionControl=FALSE)) %>%
      fitBounds(map_bounds1[1], map_bounds1[2], map_bounds1[3], map_bounds1[4]) %>%
      addMapPane(name = "ground", zIndex=380) %>%
      addMapPane(name = "top", zIndex=420) %>%
      addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = FALSE)) %>%
      addProviderTiles("Esri.WorldImagery", group="Esri.WorldImagery") %>%
      addProviderTiles("Esri.WorldTopoMap", group="Esri.WorldTopoMap")%>% 
      addTiles(urlTemplate = "", group = "Blank Background") %>%
      addPolygons(data=lakes, color='#97FFFF', fill=F,  opacity = 1, weight=2, group="Lakes", options = leafletOptions(pane = "ground")) %>%
      addPolylines(data=rivers, color='#97FFFF', opacity = 1, weight=2, group="Rivers", options = leafletOptions(pane = "ground")) %>%
      addPolygons(data=IPCA_PL, color='black', fill=F,  opacity = 1, weight=2, group="LFN IPCA planning area", options = leafletOptions(pane = "ground")) %>%
      addPolygons(data=kdtt, color='#660066', fill=F, weight=2, group="Kaska Dene Traditional Territory", options = leafletOptions(pane = "ground")) %>%
      addPolygons(data=proposed_ipcas, color = 'black', fill = T, fillOpacity = 0.2, weight=1, layerId = proposed_ipcas$ipca_name, popup = ~ipca_name, group="Proposed IPCAs*", options = leafletOptions(pane = "ground")) %>%
      #addLabelOnlyMarkers(data = label_points, label = ~layer, labelOptions = labelOptions(noHide = TRUE, direction = "center", textOnly = TRUE, style = list("font-weight"="bold","font-size"="12px","color"="black")), group = "Proposed IPCAs*") %>%
      addPolygons(data=caribouherds, color=~herd_pal(HERD), fillColor = ~herd_pal(HERD), fillOpacity = 0.6, weight=3, layerId = caribouherds$HERD, popup = ~HERD, group="Caribou herds", options = leafletOptions(pane = "top")) %>% 
      addLayersControl(position = "topright",
                       baseGroups=c("Esri.WorldTopoMap", "Esri.WorldImagery", "Blank Background"),
                       overlayGroups = c("Kaska Dene Traditional Territory", "LFN IPCA planning area", "Proposed IPCAs*", "Caribou herds"),
                   options = layersControlOptions(collapsed = FALSE))%>%
      hideGroup(c("LFN IPCA planning area", "Proposed IPCAs*")) 
  })
  
  myMap <- leafletProxy("map", session)
  
  
  #Control on tab
  modalServer(input, output, session, project, reactiveValsList)
  
  #Set input parameters
  setHerdServer(input, output, session, project, myMap, reactiveValsList)
  
  # Add display layers
  addDisplayServer(input, output, session, project, myMap, reactiveValsList)

  # Generate intactness
  genIntactServer(input, output, session, project, myMap, reactiveValsList)
  
  # Download stats
  downloadServer(input, output, session, project, reactiveValsList)
 


  ##############################################################################
  # Reporting
  ##############################################################################
  observe({
    addResourcePath("report_images", tempdir())
  })
  
  output$report_preview <- renderUI({
    req(reactiveValsList$report_ready())
    if(reactiveValsList$report_ready() ==0){
      rmarkdown::render(
        input = "report_blank.Rmd",
        output_format = "html_document",
        output_file = "preview.html",
        output_dir = "www",   
        quiet = TRUE,
        envir = new.env(parent = globalenv())
      )
      tags$iframe(
        src = "preview.html",
        style = "width:100%; height:900px; border:none;"
      )
    }else{
        tags$iframe(
          src = "preview.html",
          style = "width:100%; height:1200px; border:none;"
        )
      }
  })
}
