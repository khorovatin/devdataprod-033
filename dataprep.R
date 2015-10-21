library(rgdal)
library(leaflet)
library(htmltools)
library(gdata)

icekml <- "data/Icethickness.kml"
icexls <- "data/Ice_thickness.xls"

# Extract Coordinates and Name from KML
stations <- readOGR(icekml, layer = "Ice thickness")

stnloc <- data.frame(
  Name = stations@data$Name,
  Lon = stations@coords[, "coords.x1"],
  Lat = stations@coords[, "coords.x2"]
)

save(stnloc, file = "data/stnloc.Rda")

# Combine all sheets in XLS to one data frame
stndata <- do.call("rbind",
                   lapply(sheetNames(icexls),
                          function(n)
                            read.xls(icexls,
                                     sheet = n,
                                     header = TRUE)))

names(stndata) <- c("ID", "Name", "Date", "Ice", "Snow",
                    "Method", "Surface", "Water")

stndata$Date <- as.Date(stndata$Date, "%Y-%m-%d")

save(stndata, file = "data/stndata.Rda")
