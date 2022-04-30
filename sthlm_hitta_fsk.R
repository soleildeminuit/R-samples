list.of.packages <- c("dplyr", "sf", "jsonlite", "osmdata", "tmap","areal")
new.packages <- list.of.packages[!(list.of.packages %in%
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(dplyr)
library(sf)
library(jsonlite)
library(osmdata)
library(tmap)

url_st <- "https://apigw.stockholm.se/NoAuth/VirtualhittaserviceDMZ/Rest/servicetypes"
st <- fromJSON(url_st)

url_fsk <- "https://apigw.stockholm.se/NoAuth/VirtualhittaserviceDMZ/Rest/serviceunits?filter[servicetype.id]=2&page[limit]=1500&page[offset]=0&sort=name"
fsk <- fromJSON(url_fsk)

fsk <- fsk$data$attributes
fsk$east <- fsk$location$east
fsk$north <- fsk$location$north
fsk$created <- as.Date(fsk$created)
fsk$changed <- as.Date(fsk$changed)

fsk <- fsk %>% 
  st_as_sf(
    coords = c("east", "north"), 
    crs = 3011
  ) %>% 
  select(-location)

tmap_mode("view")
tm_shape(fsk) + 
  tm_symbols(col = "blue")
  # tm_text(
  #   "name", 
  #   remove.overlap = TRUE
  # )