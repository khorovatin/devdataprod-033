#Extracting Coordinates and ID from KML  
library(rgdal)
library(leaflet)
library(htmltools)
stations <- readOGR("data/Icethickness.kml", layer = "Ice thickness")
oldstations <- readOGR("data/Originalicethickness.kml", layer = "Original ice thickness")
newice <- data.frame(ID = stations@data$Name, lon = stations@coords[, "coords.x1"], lat = stations@coords[, "coords.x2"])
oldice <- data.frame(ID = oldstations@data$Name, lon = oldstations@coords[, "coords.x1"], lat = oldstations@coords[, "coords.x2"])
# minlon <- min(stations@bbox["coords.x1", "min"], oldstations@bbox["coords.x1", "min"])-.5
# maxlon <- max(stations@bbox["coords.x1", "max"], oldstations@bbox["coords.x1", "max"])+.5
# minlat <- min(stations@bbox["coords.x2", "min"], oldstations@bbox["coords.x2", "min"])-.5
# maxlat <- max(stations@bbox["coords.x2", "max"], oldstations@bbox["coords.x2", "max"])+.5
# map("worldHires", "Canada", xlim = c(minlon, maxlon), ylim = c(minlat, maxlat), col="gray90", fill = TRUE)
# points(oldice$lon, oldice$lat, pch = 19, col="blue", cex=0.5)
# points(newice$lon, newice$lat, pch = 19, col="red", cex=0.5)
leaflet(data = oldice) %>% 
        addProviderTiles("OpenMapSurfer.Grayscale") %>%
        addMarkers(~lon, ~lat, 
                   popup = ~htmlEscape(ID),
                   clusterOptions = markerClusterOptions())

