## V2
library(shiny)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(DT)
library(plotly)

# Load the fictional dataset
data <- read.csv("Example_GAS_Genomic_Data.csv")

# Identify columns to use for the overview dropdown 
# (Excluding ID and coordinate columns)
genotypic_features <- names(data)[!names(data) %in% c("Sample", "Planet", "Region", "Total_Bases", "N50", "Longest_Contig", "Contig_Num")]

ui <- dashboardPage(
  dashboardHeader(title = "iGAS Surveillance"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("chart-bar")),
      menuItem("Map Visualization", tabName = "map", icon = icon("map")),
      menuItem("Genomic Data", tabName = "data", icon = icon("dna"))
    ),
    hr(),
    # FEATURE SELECTION DROPDOWN
    selectInput("selected_feature", "Select Genotypic Feature:", 
                choices = genotypic_features, selected = "emm_Type"),
    
    selectInput("filter_region", "Filter by Galactic Region:", 
                choices = c("All", unique(data$Region))),
    
    checkboxGroupInput("filter_sir", "Filter by Penicillin SIR:",
                       choices = unique(data$WGS_PEN_SIR),
                       selected = unique(data$WGS_PEN_SIR))
  ),
  
  dashboardBody(
    tabItems(
      # Tab 1: Dynamic Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(plotlyOutput("dynamic_plot"), width = 12, 
                    title = textOutput("plot_title"))
              ),
              fluidRow(
                valueBoxOutput("sample_count"),
                valueBoxOutput("unique_st_count")
              )
      ),
      
      # Tab 2: Map
      tabItem(tabName = "map",
              box(leafletOutput("galactic_map", height = 500), width = 12, 
                  title = "Fictional Galactic Distribution")
      ),
      
      # Tab 3: Data Table
      tabItem(tabName = "data",
              box(DTOutput("raw_table"), width = 12, style = "overflow-x: scroll;")
      )
    )
  )
)

server <- function(input, output) {
  
  # Reactive data filtering
  filtered_data <- reactive({
    df <- data
    if (input$filter_region != "All") {
      df <- df %>% filter(Region == input$filter_region)
    }
    df <- df %>% filter(WGS_PEN_SIR %in% input$filter_sir)
    return(df)
  })
  
  # Dynamic Title for the Plot
  output$plot_title <- renderText({
    paste("Frequency Distribution of", input$selected_feature)
  })
  
  # Dynamic Plot: Updates based on selected dropdown column
  output$dynamic_plot <- renderPlotly({
    req(input$selected_feature)
    
    p <- filtered_data() %>%
      count(!!sym(input$selected_feature)) %>%
      ggplot(aes(x = reorder(!!sym(input$selected_feature), n), y = n, fill = !!sym(input$selected_feature))) +
      geom_col() +
      coord_flip() +
      theme_minimal() +
      theme(legend.position = "none") +
      labs(x = input$selected_feature, y = "Count")
    
    ggplotly(p)
  })
  
  # Dynamic Value Boxes
  output$sample_count <- renderValueBox({
    valueBox(nrow(filtered_data()), "Samples in View", icon = icon("vial"), color = "purple")
  })
  
  output$unique_st_count <- renderValueBox({
    st_count <- length(unique(filtered_data()$ST))
    valueBox(st_count, "Unique STs", icon = icon("fingerprint"), color = "blue")
  })
  
  # Map Visualization
  output$galactic_map <- renderLeaflet({
    # Generating consistent random coords for the fictional planets
    set.seed(42)
    map_df <- filtered_data() %>%
      mutate(lat = runif(n(), -20, 20), lng = runif(n(), -20, 20))
    
    leaflet(map_df) %>%
      addProviderTiles(providers$CartoDB.DarkMatter) %>%
      addCircleMarkers(~lng, ~lat, 
                       popup = ~paste("Sample:", Sample, "<br>Planet:", Planet, "<br>ST:", ST),
                       color = "cyan", radius = 8, fillOpacity = 0.7)
  })
  
  # Data Table
  output$raw_table <- renderDT({
    datatable(filtered_data(), options = list(scrollX = TRUE, pageLength = 10))
  })
}

shinyApp(ui, server)

