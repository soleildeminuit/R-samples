# Nödvändiga paket
for (package in c(
  "dplyr", 
  "tibble", 
  "httr", 
  "jsonlite", 
  "osmdata", 
  "sf", 
  "tmap", 
  "viridis")) {
  if (!require(package, character.only=T, quietly=T)) {
    suppressPackageStartupMessages(package)
    suppressWarnings(package)
    install.packages(package)
    library(package, character.only=T)
  }
}

# ############################## Open Street Map (OSM) ##############################
# # Hämta alla systembolag inom Stockholms stads gränser från Open Street Map       #
# ###################################################################################

# Hämta gränser för stadsdelsnämndsområden
sdn <- st_read("data/sdn_2020.shp") %>%
  st_zm(drop = TRUE) %>% 
  mutate(Namn = Sdn_omarde) %>% 
  st_transform(crs = 4326)

# Skapa OpenStreetMap-fråga, med stadsdelsnämndsområden som sökområde
q0 <- opq(bbox = st_bbox(sdn))

# Hämta alla systembolag inom sökområdet
q1 <- add_osm_feature(opq = q0, key = 'shop', value = "alcohol") # add_osm_feature("shop", "supermarket")
res1 <- osmdata_sf(q1)

sb_osm <- res1$osm_points
sb_osm$name <- iconv(sb_osm$name, "UTF-8")
# p <- p %>% dplyr::select(osm_id, name)

# Transformera till SWEREF 99 18 00 TM
sb_osm <- sb_osm %>% st_transform(., crs = 3011)

tmap_mode("plot") # Ange "view" i stället för "plot" om webbkarta

tm_shape(sdn) + 
  tm_borders() +
  tm_text("Namn") +
  tm_shape(sb_osm) + tm_symbols(col = "blue", alpha = 0.7) + 
  tm_layout(main.title = "Systembolag från OpenStreetMap")

# Spara systembolagen som ESRI-shapefiler
# st_write(sb_osm, "data/systembolag_osm.shp", delete_dsn = T)
