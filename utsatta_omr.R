library(dplyr)
library(sf)
library(jsonlite)

omr <- st_read("https://segregationsbarometern.delmos.se/geojson/utsattaomraden.geojson") %>% 
  st_transform(., crs = 3006) %>% 
  st_make_valid() %>% mutate(omr_id = row_number()) %>% 
  st_write(., "data/utsatta_omr.gpkg", delete_dsn = TRUE)

omr %>% filter(ort == "Stockholm") %>% mapview::mapview(.)
