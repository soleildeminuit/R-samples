list.of.packages <- c("dplyr", "sf", "jsonlite", "osmdata", "tmap","areal")
new.packages <- list.of.packages[!(list.of.packages %in%
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(dplyr)
library(sf)
library(jsonlite)
library(osmdata)
library(tmap)

sdn <- st_read("data/sdn_2020.shp") %>%
  st_zm(drop = TRUE)
# url_webquery <- "http://kartor.stockholm.se/bios/webquery/app/baggis/web/web_query?section="
# methods <- c("locate*stadsdelsnamnd", "stadsdelsnamnd*suggest")
# urlJ <- fromJSON(paste(url_webquery,
#                        methods[1],
#                        "&&resulttype=json",
#                        sep = ""))
# urlJ2 <- fromJSON(paste(url_webquery,
#                         methods[2],
#                         "&&resulttype=json",
#                         sep = ""))
# 
# sfc <- st_as_sfc(urlJ$dbrows$WKT, EWKB = F)
# sdn <- st_sf(sfc, crs = 3011) %>%
#   rename(geometry = sfc) %>%
#   mutate(ADM_ID = as.integer(urlJ$dbrows$ID)) %>% 
#   arrange(ADM_ID)
# 
# sdn$NAMN <-  urlJ2$dbrows$RESULT
# sdn <- sdn %>% dplyr::select(NAMN, ADM_ID)
# 
# sdn <- sdn %>% mutate(ADM_ID = case_when(ADM_ID == 21 ~ 22, TRUE ~ as.numeric(ADM_ID)))

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