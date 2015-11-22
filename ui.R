library(shiny)
library(leaflet)

shinyUI(
        navbarPage("Canadian Ice Thickness Program",
                tabPanel("Introduction",
                         mainPanel(
                                 includeMarkdown("intro.md")
                         )),
                tabPanel("Data",
                         dataTableOutput("icedata")),
                tabPanel("Map",
                         sidebarPanel(
                                 h4("Filter"),
                                 sliderInput("year", "Year", sep = "",
                                             1947, 2014, value = c(2003, 2013),
                                             dragRange = TRUE
                                 ),
                                 textOutput("meascount")
                         ),
                         mainPanel(
                                 leafletOutput("icemap"),
                                 plotOutput("plot")
                         )
                )
        )
)
