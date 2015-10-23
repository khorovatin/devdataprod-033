library(shiny)
library(leaflet)
library(htmltools)

load("data/oldstnloc.Rda")
load("data/oldstndata.Rda")

shinyServer(function(input, output, session) {
  
  # Map
  output$icemap <- renderLeaflet({
    leaflet(data = stnloc) %>%
      addTiles() %>%
      addMarkers( ~Lon, ~Lat,
                  popup = ~htmlEscape(Name),
                  clusterOptions = markerClusterOptions())
  })
  
  # Data
  output$icedata <- renderDataTable(stndata)
  
})
