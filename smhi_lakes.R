for (package in c(
  "dplyr", 
  "jsonlite", 
  "sf",
  "geojsonio",
  "tmap")) {
  if (!require(package, character.only=T, quietly=T)) {
    suppressPackageStartupMessages(package)
    suppressWarnings(package)
    install.packages(package)
    library(package, character.only=T)
  }
}

url_lake_reg <- "https://opendata-download.smhi.se/svar/Vattenytor_2016.zip"

if (!file.exists("data/Vattenytor_2016.shp")){
  temp <- tempfile()
  download.file(url_lake_reg, temp, mode="wb")
  unzip(temp, exdir = "data")
  unlink(temp)
}

lakes <- st_read("data/Vattenytor_2016.shp")

# Simplified (generalized) municipality polygons
sthlm <- geojson_sf("https://segregationsbarometern.delmos.se/geojson/kommuner.geojson") %>% 
  filter(name == "Stockholm") %>% 
  st_cast("POLYGON") %>% 
  st_transform(., st_crs(lakes))

# Keep lakes that are intersecting the boundaries
m <- lakes %>% st_intersects(., sthlm, sparse = FALSE)
lakes_cut <- lakes[m,]

tm_shape(lakes_cut) + tm_polygons(col = "blue") + tm_shape(sthlm) + tm_borders(lwd = 3)

# Keep lakes that are intersecting the boundaries
lakes_cut <- lakes %>% st_intersection(., sthlm)
tm_shape(lakes_cut) + tm_polygons(col = "blue") + tm_shape(sthlm) + tm_borders(lwd = 3)

