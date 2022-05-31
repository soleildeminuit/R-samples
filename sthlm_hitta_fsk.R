list.of.packages <- c("dplyr", "sf", "jsonlite", "osmdata", "tmap","areal")
new.packages <- list.of.packages[!(list.of.packages %in%
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(dplyr)
library(sf)
library(jsonlite)
library(osmdata)
library(tmap)

start_time <- Sys.time()

# Hämta gränser för stadsdelsnämndsområden
sdn <- st_read("data/sdn_2020.shp") %>%
  st_zm(drop = TRUE) %>% 
  mutate(Namn = Sdn_omarde)

# Hämta förskolor (servicetype = 2)
url_st <- "https://apigw.stockholm.se/NoAuth/VirtualhittaserviceDMZ/Rest/servicetypes"

# Se alla verksamhetstyper med View(st)
st <- fromJSON(url_st)

url_fsk <- "https://apigw.stockholm.se/NoAuth/VirtualhittaserviceDMZ/Rest/serviceunits?filter[servicetype.id]=2&page[limit]=1500&page[offset]=0&sort=name"
fsk <- fromJSON(url_fsk)

df <-  data.frame()
for (i in 1:nrow(fsk$data$attributes)){
  details <- fromJSON(fsk$data[i,]$links$self)
  orgform <- details$data$attributes$details$organizationalForm
  numberOfChildren <- details$data$attributes$details$numberOfChildren
  # l[[i]] <- orgform$displayName
  if (is.null(numberOfChildren)){
    numberOfChildren = 0 # Kanske ska anta värdet 1? => syns i kartan
  }
  df_ <- data.frame(displayName = orgform$displayName, numberOfChildren)
  df <- rbind(df, df_)
}

fsk <- fsk$data$attributes
fsk$orgform <- df$displayName
fsk$numberOfChildren <- df$numberOfChildren

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

# Skapa en interaktiv webbkarta
tmap_mode("view")
tm_shape(fsk) + 
  tm_symbols(
    col = "orgform", palette = "Pastel1",
    alpha = 0.7,
    size = "numberOfChildren", scale = 0.5) + 
  tm_shape(sdn) + 
  tm_borders(lwd = 3) + 
  tm_text("Namn")

end_time <- Sys.time()

print(end_time - start_time)
