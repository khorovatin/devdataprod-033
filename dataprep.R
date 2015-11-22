library(rgdal)
library(leaflet)
library(htmltools)
library(gdata)
library(dplyr)
library(data.table)

newicekml <- "data/Icethickness.kml"
newicexls <- "data/Ice_thickness.xls"

oldicekml <- "data/Originalicethickness.kml"
oldicexls <- "data/original_program_data_20030304.xls"

join_names <- read.csv(
  "data/JoinNames.csv", header = TRUE, stringsAsFactors = FALSE
)

# Read and prepare location data ------------------------------------------

# Extract Coordinates and Name from KML
oldstations <- readOGR(oldicekml, layer = "Original ice thickness")
newstations <- readOGR(newicekml, layer = "Ice thickness")

oldstnloc <- data.table(
  Name = oldstations@data$Name,
  lng = oldstations@coords[, "coords.x1"],
  lat = oldstations@coords[, "coords.x2"]
) %>% 
  setkey(Name) %>% 
  unique()

newstnloc <- data.table(
  Name = newstations@data$Name,
  lng = newstations@coords[, "coords.x1"],
  lat = newstations@coords[, "coords.x2"]
) %>% 
  setkey(Name) %>% 
  unique()

locNameFactors <- sort(union(levels(oldstnloc$Name), 
                                 levels(newstnloc$Name)))

oldstnloc[, Name := factor(Name, levels = locNameFactors)]
newstnloc[, Name := factor(Name, levels = locNameFactors)]

allstnloc <- dplyr:::union(oldstnloc, newstnloc) %>%  
  setkey(Name)

allstnloc[, ':=' (Name = as.character(Name), 
                               JoinName = toupper(Name))]

save(allstnloc, file = "data/allstnloc.Rda")


# Read and prepare measurement data ---------------------------------------

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

# Assign common names to all columns so we can merge later
newcolnames <- c("ID", "Name", "Date", "Ice", "Snow", 
                 "Method", "Surface", "Water")
names(oldstndata) <- newcolnames
names(newstndata) <- newcolnames

# Convert the data frames to data tables
oldstndata <- data.table(oldstndata)
newstndata <- data.table(newstndata)

# Convert the Date column to the Date data type
oldstndata[, Date := as.Date(Date, "%Y-%m-%d")]
newstndata[, Date := as.Date(Date, "%Y-%m-%d")]

# Retrieve the ID and Name factors from both old and new datasets, then merge
# them for use during the union
dataIDFactors <- sort(union(levels(oldstndata$ID), 
                            levels(newstndata$ID)))
dataNameFactors <- sort(union(levels(oldstndata$Name), 
                              levels(newstndata$Name)))

# Update the factors for the ID and Name columns to factors for the union
oldstndata[, ':=' (ID = factor(ID, levels = dataIDFactors),
                   Name = factor(Name, levels = dataNameFactors))]

newstndata[, ':=' (ID = factor(ID, levels = dataIDFactors),
                   Name = factor(Name, levels = dataNameFactors))]

# Union the old and new data sets, and set the key to Name for the subsequent
# join
allstndata <- dplyr:::union(oldstndata, newstndata) %>% setkey(Name)

# Add the JoinName column and revert the Name column to characters
allstndata <- allstndata[join_names, nomatch=0][, Name := as.character(Name)] 

# Remove the extra unused data columns
extracols <- c("Snow", "Method", "Surface", "Water")
allstndata[, (extracols) := NULL]

# Remove rows with Ice == NA or with bad date data
allstndata[!is.na(Ice) | year(Date) >= 1947]

save(allstndata, file = "data/allstndata.Rda")
