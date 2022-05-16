library(dplyr)
library(sf)

CELL_SIZE_M <- 1000
MUNICIPALITY_CODE <- "0180"

RoundUp <- function(from,to) ceiling(from/to)*to
RoundDown <- function(from,to) floor(from/to)*to

url_regso <- "https://geodata.scb.se/geoserver/stat/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=stat%3ARegSO.2018&outputFormat=SHAPE-ZIP&format_options=charset:UTF-8"
temp <- tempfile()
download.file(url_regso, temp, mode="wb")
unzip(temp, exdir = "data")
unlink(temp)

reference_area <- st_read("data/RegSO_2018.shp") %>% 
  filter(kommun == MUNICIPLITY_CODE) %>% 
  group_by(kommun) %>% 
  summarise() %>% 
  st_transform(crs = 3006)

bb <- st_bbox(reference_area)

nrows <- ceiling((bb$ymax-bb$ymin)/CELL_SIZE_M)
ncols <- ceiling((bb$xmax-bb$xmin)/CELL_SIZE_M)

rounded_bb <- c(
  RoundDown(bb$xmin, CELL_SIZE_M), 
  RoundDown(bb$ymin, CELL_SIZE_M)
)

new_grid <- st_as_sf(
  st_make_grid(
    cellsize = CELL_SIZE_M,
    offset = rounded_bb,
    n = c(ncols, nrows
    ),
    crs = st_crs(reference_area))) %>% 
  rename(geometry = x) %>% mutate(id = row_number())

coords <- as.data.frame(st_coordinates(new_grid)) %>% 
  mutate(r = row_number()) %>% filter(r %% 5 == 0)

new_grid$rut_id <- trimws(paste(coords$X, coords$Y, sep = ""))

m <- st_intersects(new_grid, reference_area, sparse = FALSE)
new_grid <- new_grid[m,]

plot(st_geometry(new_grid))

#### Uncomment to run ####

# url_grid <- "https://www.scb.se/contentassets/67248cebde154e009c3bee2ee01dca35/totrut_sweref.zip"
# temp <- tempfile()
# download.file(url_grid, temp, mode="wb")
# unzip(temp, exdir = "data")
# unlink(temp)
# 
# grid_scb <- st_read("data/TotRut_SweRef.gpkg") %>% 
#   st_transform(crs = st_crs(reference_area)) %>% mutate(rut_id = trimws(rut_id))
# 
# m <- grid_scb %>% st_intersects(., reference_area %>% st_union() %>% st_as_sf(), sparse = FALSE)
# 
# new_grid_scb <- grid_scb[m,]

# x <- new_grid_scb %>% filter(!(rut_id %in% new_grid$rut_id))
