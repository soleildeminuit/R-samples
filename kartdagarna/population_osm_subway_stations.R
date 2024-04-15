# Funktion för att installera och ladda paket
ensure_packages <- function(packages) {
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg)
    }
    library(pkg, character.only = TRUE)
  }
}

# Ladda nödvändiga paket
ensure_packages(c("dplyr", "sf", "tmap", "areal", "httr", "osmdata"))

# URL till ZIP-filen och temporär filhantering
url <- "https://www.scb.se/contentassets/923c3627a8a042a5b9215e8ff3bde0a3/deso_2018_2021-10-21.zip"
temp_zip <- tempfile(fileext = ".zip")
download.file(url, temp_zip, mode = "wb")
temp_dir <- tempdir()
unzip(temp_zip, exdir = temp_dir)
gpkg_file <- list.files(temp_dir, pattern = "\\.gpkg$", full.names = TRUE)

# Läs in geopackage-filen
deso <- st_read(gpkg_file) %>%
  filter(substr(deso, 1, 4) %in% c("0180", "0127", "0184", "0183", "0162")) %>%
  st_transform(crs = 3011) %>%
  rename(desokod = deso)

# Städa upp temporära filer
unlink(temp_zip)
unlink(temp_dir, recursive = TRUE)

# Läsa in befolkningsdata från SCB
pop_deso <- read.csv("https://www.statistikdatabasen.scb.se/sq/147782",
                     sep = ",", fileEncoding = "ISO8859-1") %>%
  rename(antal = X2023) %>%
  filter(substr(region, 1, 4) %in% c("0180", "0127", "0184", "0183", "0162")) %>%
  rename(desokod = region)

# Kombinera spatial data med befolkningsdata
deso <- left_join(deso, pop_deso, by = "desokod")

# Lägg till en kolumn för logaritmisk skalning
deso$log_antal <- log(deso$antal + 1)  # För att undvika log(0)
deso$exp_antal <- (deso$log_antal) ^ 1.5  # Exponentiell justering

# Normalisera 'antal' genom att dela varje värde med maxvärdet
deso$normalized_antal <- deso$antal / max(deso$antal)

# För att öka skillnaderna i storlek på symbolerna kan vi multiplicera de normaliserade värdena
# med en faktor, till exempel 100 om det behövs
deso$scaled_antal <- deso$normalized_antal * 100

# Hämta bounding box-koordinater för Stockholms kommun i WGS84
stockholm_bbox_polygon <- getbb("Stockholm, Sweden", format_out = "sf_polygon") %>% 
  st_set_crs(4326)  # Ange koordinatsystemet till WGS84

# Omvandla bounding box till en spatial bounding box (bbox) objekt
stockholm_bbox <- st_bbox(stockholm_bbox_polygon)

# För att hämta tunnelbanestationer (punkter)
subway_stations_query <- opq(bbox = stockholm_bbox) %>%
  add_osm_feature(key = 'station', value = 'subway') %>%
  osmdata_sf()

# För att hämta tunnelbanelinjer (linjer)
subway_lines_query <- opq(bbox = stockholm_bbox) %>%
  add_osm_feature(key = 'railway', value = 'subway') %>%
  osmdata_sf()

subway_lines <- subway_lines_query$osm_lines

# Transformera Stockholm polygon till det lokala koordinatsystemet (SWEREF99 TM)
stockholm_polygon_projected <- st_transform(stockholm_bbox_polygon, 3011)

subway_stations <- subway_stations_query$osm_points

grona_linjen <- c("Slussen", "Medborgarplatsen", 
                  "Skanstull", "Gullmarsplan", 
                  "Skärmarbrink", "Blåsut", 
                  "Sandsborg", "Skogskyrkogården", 
                  "Tallkrogen", "Gubbängen", 
                  "Hökarängen", "Globen", 
                  "Enskede gård", "Sockenplan", 
                  "Svedmyra", "Stureby", 
                  "Hötorget", 
                  "Rådmansgatan", "Odenplan", 
                  "Sankt Eriksplan", "Fridhemsplan", 
                  "Thorildsplan", "Kristineberg", 
                  "Alvik", "Stora mossen", 
                  "Abrahamsberg", "Brommaplan", 
                  "Åkeshov", "Ängbyplan", 
                  "Islandstorget", "Blackeberg", 
                  "Råcksta", "Vällingby", 
                  "Bandhagen", "Högdalen", 
                  "Johannelund", "Hässelby gård", 
                  "T-Centralen", "Gamla stan", 
                  "Hammarbyhöjden", "Björkhagen", 
                  "Kärrtorp", "Bagarmossen", 
                  "Farsta", "Hässelby strand", 
                  "Rågsved", "Hagsätra", 
                  "Farsta strand", "Skarpnäck")

roda_linjen <- c("Alby", "Aspudden", "Axelsberg", "Bergshamra", "Bredäng", "Danderyds sjukhus", "Fittja", "Fruängen", "Gamla stan", "Gärdet", "Hallunda", "Hornstull", "Hägerstensåsen", "Karlaplan", "Liljeholmen", "Mariatorget", "Masmo", "Midsommarkransen", "Mälarhöjden", "Mörby centrum", "Norsborg", "Ropsten", "Skärholmen", "Slussen", "Stadion", "Sätra", "Tekniska högskolan", "Telefonplan", "Universitetet", "Vårberg", "Vårby gård", "Västertorp", "Zinkensdamm", "Örnsberg", "Östermalmstorg")

bla_linjen <- c("Akalla", "Duvbo", "Fridhemsplan", "Hallonbergen", "Hjulsta", "Husby", "Huvudsta", "Kista", "Kungsträdgården", "Näckrosen", "Rinkeby", "Rissne", "Rådhuset", "Solna centrum", "Solna strand", "Stadshagen", "Sundbybergs centrum")

subway_stations_gron <- subway_stations %>% filter(name %in% grona_linjen)
subway_stations__roda <- subway_stations %>% filter(name %in% roda_linjen)
subway_stations__bla <- subway_stations %>% filter(name %in% bla_linjen)

# create buffer
buffer_gron <- st_buffer(subway_stations_gron, 500) %>% 
  dplyr::select(name, osm_id) %>% 
  st_transform(., crs = 3011)
buffer_rod <- st_buffer(subway_stations__roda, 500) %>% 
  dplyr::select(name, osm_id) %>% 
  st_transform(., crs = 3011)
buffer_bla <- st_buffer(subway_stations__bla, 500) %>% 
  dplyr::select(name, osm_id) %>% 
  st_transform(., crs = 3011)

#
x <- aw_interpolate(buffer_gron, tid = osm_id, source = deso, sid = desokod, 
                    weight = "sum", output = "tibble", extensive = "normalized_antal")

buffer_gron <- left_join(buffer_gron, x)
#
x <- aw_interpolate(buffer_bla, tid = osm_id, source = deso, sid = desokod, 
                    weight = "sum", output = "tibble", extensive = "normalized_antal")

buffer_bla <- left_join(buffer_bla, x)
#
x <- aw_interpolate(buffer_rod, tid = osm_id, source = deso, sid = desokod, 
                    weight = "sum", output = "tibble", extensive = "normalized_antal")

buffer_rod <- left_join(buffer_rod, x)

#
t <- tm_shape(stockholm_polygon_projected) + tm_polygons(alpha = 0, border.col = "black") +
  tm_shape(buffer_bla) + 
  tm_dots(col = "normalized_antal", style = "jenks", palette = "Blues", border.col = "black", size = "normalized_antal") +
  
  tm_shape(buffer_gron) + 
  tm_dots(col = "normalized_antal", style = "jenks", palette = "Greens", border.col = "black", size = "normalized_antal") +
  
  tm_shape(buffer_rod) + 
  tm_dots(col = "normalized_antal", style = "jenks", palette = "Reds", border.col = "black", size = "normalized_antal") +
  # tm_view(alpha = 1, basemaps = "Stamen.TonerLines") +
  tm_layout(legend.show = F, frame = F) +
  tm_shape(subway_lines) + tm_lines(lwd = 2)

t
