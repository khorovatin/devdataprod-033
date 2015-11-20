library(shiny)
library(leaflet)
library(htmltools)
library(dplyr)
library(ggplot2)
library(lubridate)
library(data.table)

load("data/allstnloc.Rda")
allstnloc <- data.table(allstnloc, key = "JoinName")
load("data/allstndata.Rda")
allstndata <- data.table(allstndata, key = "JoinName")

allstndata <- allstnloc[allstndata][, c("JoinName", "i.Name") := NULL]

# Infix "between" function. Designed to behave like a SQL BETWEEN, where the
# comparison includes both endpoints.
`%between%` <- function(x, rng) findInterval(x, rng) == 1


shinyServer(function(input, output, session) {
  
  # Map
  output$icemap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>% 
      fitBounds(min(allstnloc$lng), min(allstnloc$lat), 
                max(allstnloc$lng), max(allstnloc$lat))
  })
  
  stnDataInBounds <- reactive({
    if (is.null(input$icemap_bounds))
      return(allstndata[FALSE, ])
    bounds <- input$icemap_bounds
    lats <- range(bounds$north, bounds$south)
    lngs <- range(bounds$west, bounds$east)
    leafletProxy("icemap", session, data = allstnloc) %>% 
      clearMarkers() %>% 
      addMarkers( ~lng, ~lat, popup = ~htmlEscape(Name),
                  clusterOptions = markerClusterOptions())
    allstndata %>% 
      filter(lng %between% lngs, lat %between% lats,
             year(Date) %between% input$year)
  })
  
  output$meascount <- renderText(
    paste(
      "Total measurements recorded:", 
      nrow(stnDataInBounds())
    )
  )
  
  
  observe({
    yearRange <- input$year
    minYear <- yearRange[1]
    maxYear <- yearRange[2]
    
    stnWithMeasurements <- allstndata %>% 
      filter(year(Date) %in% yearRange) %>% 
      select(Name, lng, lat) %>% 
      distinct()
    
    map <- leafletProxy("icemap", session, data = stnWithMeasurements)
    
    map %>% clearMarkers() 
    
    if (nrow(stnWithMeasurements) > 0) { 
      map %>% addMarkers(~lng, ~lat, popup = ~htmlEscape(Name),
                         clusterOptions = markerClusterOptions())
    }
  })
  
  output$plot <- renderPlot({
    if (nrow(stnDataInBounds()) == 0)
      return(NULL)
    
    give.n <- function(x) {
      return(c(y = -10, label = length(x)))
    }
    
    qplot(
      as.factor(year(Date)), 
      Ice, 
      data = stnDataInBounds(), 
      geom = "boxplot",
      main = "All Ice Thickness Measurements and Counts\nfor Time Period and Region Selected",
      xlab = "Years",
      ylab = "Ice Thickness (cm)") +
      stat_summary(fun.y = mean, geom = "point", shape = 5, size = 4) + 
      stat_summary(fun.data = give.n, geom = "text", size = 3) +
#       geom_jitter(
#         position = position_jitter(width = .2), size = 2, alpha = .2
#       ) + 
      geom_smooth(aes(group = 1), method = "lm", se = TRUE, na.rm = TRUE)
  })
  
  # Data
  output$icedata <- renderDataTable(allstndata,
                                    options = list(
                                      pageLength = 10
                                    ))
  
})

