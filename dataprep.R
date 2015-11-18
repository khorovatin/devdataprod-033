library(rgdal)
library(leaflet)
library(htmltools)
library(gdata)
library(dplyr)

newicekml <- "data/Icethickness.kml"
newicexls <- "data/Ice_thickness.xls"

oldicekml <- "data/Originalicethickness.kml"
oldicexls <- "data/original_program_data_20030304.xls"

join_names <- read.csv(
  "data/JoinNames.csv", header = TRUE, stringsAsFactors = FALSE
)

# Extract Coordinates and Name from KML
oldstations <- readOGR(oldicekml, layer = "Original ice thickness")
newstations <- readOGR(newicekml, layer = "Ice thickness")

oldstnloc <- data.frame(
  Name = oldstations@data$Name,
  lng = oldstations@coords[, "coords.x1"],
  lat = oldstations@coords[, "coords.x2"]
) %>% 
  group_by(Name) %>% 
  filter(row_number() == 1) %>% 
  ungroup()

newstnloc <- data.frame(
  Name = newstations@data$Name,
  lng = newstations@coords[, "coords.x1"],
  lat = newstations@coords[, "coords.x2"]
) %>% 
  group_by(Name) %>% 
  filter(row_number() == 1) %>% 
  ungroup()

locNameFactors <- sort(union(levels(oldstnloc$Name), 
                                 levels(newstnloc$Name)))

oldstnloc <- mutate(oldstnloc, 
                    Name = factor(Name, levels = locNameFactors))
newstnloc <- mutate(newstnloc, 
                    Name = factor(Name, levels = locNameFactors))

allstnloc <- dplyr:::union(oldstnloc, newstnloc) %>%  
  arrange(Name) %>% 
  mutate(Name = as.character(Name), JoinName = toupper(Name))

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

dataIDFactors <- sort(union(levels(oldstndata$ID), 
                            levels(newstndata$ID)))
dataNameFactors <- sort(union(levels(oldstndata$Name), 
                                  levels(newstndata$Name)))

oldstndata <- mutate(oldstndata, 
                     ID = factor(ID, levels = dataIDFactors),
                     Name = factor(Name, levels = dataNameFactors))

newstndata <- mutate(newstndata, 
                     ID = factor(ID, levels = dataIDFactors),
                     Name = factor(Name, levels = dataNameFactors))

allstndata <- dplyr:::union(oldstndata, newstndata) %>% 
  arrange(ID, Date) %>% 
  mutate(Name = as.character(Name)) %>%
  inner_join(join_names)

save(oldstndata, file = "data/oldstndata.Rda")
save(newstndata, file = "data/newstndata.Rda")
save(allstndata, file = "data/allstndata.Rda")
