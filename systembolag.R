# Nödvändiga paket
for (package in c(
  "dplyr", 
  "tibble", 
  "httr", 
  "jsonlite", 
  "osmdata", 
  "sf", 
  "areal",
  "tmap", 
  "viridis")) {
  if (!require(package, character.only=T, quietly=T)) {
    suppressPackageStartupMessages(package)
    suppressWarnings(package)
    install.packages(package)
    library(package, character.only=T)
  }
}

# Installera alla nödvändiga paket, metod 2
# list.of.packages <- c("ggplot2", "ggmap", "osmdata")
# new.packages <- list.of.packages[!(list.of.packages %in% 
#                                      installed.packages()[,"Package"])]
# if(length(new.packages)) install.packages(new.packages)

################################## Systembolaget ##################################
# Hämta alla systembolag inom Stockholms stads gränser från Systembolaget         #
#                                                                                 #
# OBS! API-nyckel måste först skapas på:                                          #
# https://api-portal.systembolaget.se/products/Open%20API                         #
#                                                                                 #
###################################################################################
api_key <- "DIN_API_NYCKEL_HÄR"

# Hämta gränser för stadsdelsnämndsområden
sdn <- st_read("data/sdn_2020.shp") %>%
  st_zm(drop = TRUE) %>% 
  mutate(Namn = Sdn_omarde) %>% 
  st_transform(crs = 4326)

# Hämta alla Systembolagets butiker (API)
systembolaget_url <- "https://api-extern.systembolaget.se/site/V2/Store"

httpResponse <- GET(systembolaget_url, 
                    add_headers("Ocp-Apim-Subscription-Key" = api_key))

stores = fromJSON(
  content(httpResponse, 
          "text", 
          encoding = "UTF-8"
  ),
  flatten = TRUE) %>% 
  select(-openingHours)

# Skapa geografiska objekt av butiksraderna.
stores <- stores %>% 
  st_as_sf(., coords = c("position.longitude", "position.latitude"), crs = 4326)

# För att välja endast de som befinner sig inom Stockholms stads gränser...
stores_sthlm <- st_intersection(stores, sdn)

# Kolla hur många butiker inom resp. stadsdelsområde
table(stores_sthlm$Sdn_omarde)

# Enkel plot
plot(st_geometry(sb_sthlm))

# Statisk kartvy
# Ange tmap_mode("view")för interaktiv webbkarta 
tmap_mode("plot")

t <- tm_shape(sdn) + 
  tm_borders(alpha = 0) +
  tm_shape(stores_sthlm) + 
  tm_symbols(
    col = "ordersToday", 
    size = "ordersToday",
    style = "jenks", 
    palette = "viridis") +
  tm_shape(sdn) + 
  tm_borders(lwd = 3) +
  tm_shape(sdn) + 
  tm_text(
    "Namn",
    size = 0.5,
    auto.placement = TRUE,
    remove.overlap = TRUE,
    col = "black") +
  tm_credits("Datakällor: Systembolaget, Stockholms stad",
             position=c("right", "bottom")) +
  tm_scale_bar(position=c("left", "bottom")) +
  tm_compass(type = "arrow", position=c("right", "top"), show.labels = 3) +
  tm_layout(
    main.title = "Systembolagsbutiker i Stockholms stad",
    legend.format=list(fun=function(x) formatC(x, digits=0, format="d", big.mark = " "), text.separator = "-")
  )
t
