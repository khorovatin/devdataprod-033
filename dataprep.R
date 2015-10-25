library(rgdal)
library(leaflet)
library(htmltools)
library(gdata)
library(dplyr)

newicekml <- "data/Icethickness.kml"
newicexls <- "data/Ice_thickness.xls"

oldicekml <- "data/Originalicethickness.kml"
oldicexls <- "data/original_program_data_20030304.xls"

# Extract Coordinates and Name from KML
oldstations <- readOGR(oldicekml, layer = "Original ice thickness")
newstations <- readOGR(newicekml, layer = "Ice thickness")

oldstnloc <- data.frame(
  Name = oldstations@data$Name,
  lng = oldstations@coords[, "coords.x1"],
  lat = oldstations@coords[, "coords.x2"]
)

newstnloc <- data.frame(
  Name = newstations@data$Name,
  lng = newstations@coords[, "coords.x1"],
  lat = newstations@coords[, "coords.x2"]
)

locNameFactors <- sort(union(levels(oldstnloc$Name), levels(newstnloc$Name)))
colLevels <- c("Original", "New")

oldstnloc <- mutate(oldstnloc, 
                    Name = factor(Name, levels = locNameFactors),
                    Collection = factor("Original", levels = colLevels))
newstnloc <- mutate(newstnloc, 
                    Name = factor(Name, levels = locNameFactors),
                    Collection = factor("New", levels = colLevels))


allstnloc <- union(oldstnloc, newstnloc) %>%  arrange(Name)

allstnloc <- mutate(allstnloc, Name = as.character(Name))

save(oldstnloc, file = "data/oldstnloc.Rda")
save(newstnloc, file = "data/newstnloc.Rda")
save(allstnloc, file = "data/allstnloc.Rda")

# Combine all sheets in XLS to one data frame
oldstndata <- do.call("rbind",
                   lapply(sheetNames(oldicexls),
                          function(n)
                            read.xls(oldicexls,
                                     sheet = n,
                                     header = FALSE,
                                     skip = 2)))

newstndata <- do.call("rbind",
                      lapply(sheetNames(newicexls),
                             function(n)
                               read.xls(newicexls,
                                        sheet = n,
                                        header = TRUE)))

names(oldstndata) <- c("ID", "Name", "Date", "Ice", "Snow",
                       "Method", "Surface", "Water")

names(newstndata) <- c("ID", "Name", "Date", "Ice", "Snow",
                       "Method", "Surface", "Water")

oldstndata$Date <- as.Date(oldstndata$Date, "%Y-%m-%d")

newstndata$Date <- as.Date(newstndata$Date, "%Y-%m-%d")

dataIDFactors <- sort(union(levels(oldstndata$ID), levels(newstndata$ID)))
dataNameFactors <- sort(union(levels(oldstndata$Name), levels(newstndata$Name)))

oldstndata <- mutate(oldstndata, 
                     ID = factor(ID, levels = dataIDFactors),
                     Name = factor(Name, levels = dataNameFactors),
                     Collection = factor("Original", levels = colLevels)
)

newstndata <- mutate(newstndata, 
                     ID = factor(ID, levels = dataIDFactors),
                     Name = factor(Name, levels = dataNameFactors),
                     Collection = factor("New", levels = colLevels)
)

allstndata <- union(oldstndata, newstndata) %>% arrange(ID, Date)

allstndata <- mutate(allstndata, Name = as.character(Name))

save(oldstndata, file = "data/oldstndata.Rda")
save(newstndata, file = "data/newstndata.Rda")
save(allstndata, file = "data/allstndata.Rda")
