library(shiny)
library(leaflet)
library(htmltools)
library(dplyr)
library(ggplot2)
library(lubridate)
library(data.table)

# Load prepared data files and convert them to data tables so they can be
# manipulated quickly
load("data/allstnloc.Rda")
allstnloc <- data.table(allstnloc, key = "JoinName")
load("data/allstndata.Rda")
allstndata <- data.table(allstndata, key = "JoinName")

# Join the location table with the measurement table so that each measurement
# has its coordinates, and then remove the JoinName and second Name columns for
# the display. Finally, set all rows with "NA" for an Ice Thickness to 0

allstndata <- allstnloc[allstndata][, c("JoinName", "i.Name") := NULL][, 
        Ice := ifelse(is.na(Ice), 0, Ice)
]

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
        
        # Subset the data based on the bounds of the map and the years selected
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
        
        # Calculate the number of Ice Thickness measurements in the subset
        output$meascount <- renderText(
                paste(
                        "Total measurements recorded:", 
                        nrow(stnDataInBounds())
                )
        )
        
        # Create a boxplot of the measurement data, complete with a linear
        # regression line and confidence range
        output$plot <- renderPlot({
                if (nrow(stnDataInBounds()) == 0)
                        return(NULL)
                
                # This function allows us to add a text label just above the
                # x-axis showing the count of measurements for the year
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
                        stat_summary(fun.y = mean, geom = "point", 
                                     shape = 5, size = 4) + 
                        stat_summary(fun.data = give.n, 
                                     geom = "text", size = 3) +
                        geom_jitter(
                                position = position_jitter(width = .2), 
                                size = 2, alpha = .1
                        ) + 
                        geom_smooth(aes(group = 1), method = "lm", 
                                    se = TRUE, na.rm = TRUE)
        })
        
        # Data table for the application (removing coordinates before display)
        output$icedata <- renderDataTable(select(allstndata, -(lng:lat)),
                                          options = list(pageLength = 10)
        )
        
})

