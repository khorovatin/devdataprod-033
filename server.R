library(shiny)
library(leaflet)
library(htmltools)
library(dplyr)
library(ggplot2)
library(lubridate)

load("data/allstnloc.Rda")
load("data/allstndata.Rda")

allstndata <- left_join(allstndata, allstnloc, by = c("Collection", "Name"))

# Infix "between" function. Designed to behave like a SQL BETWEEN, where the
# comparison includes both endpoints.
# `%between%` <- function(x, rng) x >= rng[1] & x <= rng[2]
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
                print(input$year)
                print(lats)
                print(lngs)
                print(nrow(filter(allstndata, year(Date) %between% input$year)))
                print(nrow(filter(allstndata, lng %between% lngs, lat %between% lats)))
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
                
                leafletProxy("icemap", session, data = allstnloc) %>% 
                        clearMarkers() %>% 
                        addMarkers( ~lng, ~lat, popup = ~htmlEscape(Name),
                                    clusterOptions = markerClusterOptions())
        })
        
        output$plot <- renderPlot({
                if (nrow(stnDataInBounds()) == 0)
                        return(NULL)
                
                qplot(
                        as.factor(year(Date)), 
                        Ice, 
                        data = stnDataInBounds(), 
                        geom = "boxplot") + 
                        xlab("Years") + 
                        ylab("Ice Thickness (cm)") +
                        stat_summary(fun.y = mean, 
                                     geom = "point", shape = 5, size = 4) + 
                        geom_jitter(position = position_jitter(width = .2), 
                                    size = 3) + 
                        geom_smooth(aes(group = 1), method = "lm", se = TRUE)
        })
        
        # Data
        output$icedata <- renderDataTable(allstndata,
                                          options = list(
                                                  pageLength = 10
                                          ))
        
})
