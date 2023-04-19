for (package in c(
  "sf", 
  "osmdata", 
  "dplyr",
  "jsonlite",
  "tmap",
  "viridis")) {
  if (!require(package, character.only=T, quietly=T)) {
    suppressPackageStartupMessages(package)
    suppressWarnings(package)
    install.packages(package)
    library(package, character.only=T)
  }
}

library(osmdata)
library(sf)
library(dplyr)
library(tmap)

sdn <- st_read("data/Adm_area_ny.shp") %>% 
  st_union() %>% st_as_sf() %>% st_transform(crs = 4326)

q0 <- opq(bbox = st_bbox(sdn))

q1 <- add_osm_feature(opq = q0, key = 'leisure', value = "park") # add_osm_feature("shop", "supermarket")
res1 <- osmdata_sf(q1)

p <- res1$osm_polygons
p$name <- iconv(p$name, "UTF-8")
p <- p %>% dplyr::select(osm_id, name)
# st_write(p, "parker.shp", delete_dsn = T)

p <- p %>% mutate(area = st_area(.), area = as.numeric(area))

t <- tm_shape(p) + 
  tm_fill("area", palette = "Greens", style = "jenks", alpha = 0.7) +
  tm_borders()

tmap_mode("view")

t
# tmap_save(t, "t.html", width = 297, height = 210, units ="mm", dpi=300)
