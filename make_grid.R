library(dplyr)
library(sf)

CELL_SIZE_M <- 100

sdn <- st_read("../data/sbk/Adm_area.shp", stringsAsFactors = F) %>% 
  st_transform(crs = 3006)

RoundUp <- function(from,to) ceiling(from/to)*to
RoundDown <- function(from,to) floor(from/to)*to

bb <- st_bbox(sdn)

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
    crs = 3006)) %>% 
  rename(geometry = x) %>% mutate(id = row_number())

coords <- as.data.frame(st_coordinates(new_grid)) %>% 
  mutate(r = row_number()) %>% filter(r %% 5 == 0)

new_grid$Rut_id <- paste(coords$X, coords$Y, sep = "")

m <- st_intersects(new_grid, sdn, sparse = FALSE)
new_grid <- new_grid[m,]

plot(st_geometry(new_grid))
