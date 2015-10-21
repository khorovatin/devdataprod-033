library(shiny)
library(leaflet)
library(htmltools)

load("data/stnloc.Rda")

shinyServer(function(input, output, session) {
  # Map
  
  output$icemap <- renderLeaflet({
    leaflet(data = stnloc) %>%
      addTiles() %>%
      addMarkers( ~Lon, ~Lat,
                  popup = ~htmlEscape(Name),
                  clusterOptions = markerClusterOptions())
  })
})
