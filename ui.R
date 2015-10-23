library(shiny)
library(leaflet)

shinyUI(
  navbarPage(
    "Canadian Ice Thickness Program", id = "nav",
    tabPanel("Introduction"),
    tabPanel("Data",
             dataTableOutput("icedata")),
    tabPanel("Map",
             leafletOutput("icemap"))
  )
)
