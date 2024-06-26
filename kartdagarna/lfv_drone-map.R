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
ensure_packages(c("dplyr", "sf", "httr", "tmap"))

# https://daim.lfv.se/echarts/dronechart/API/

# URL till WFS-tjänsten
base_url <- "https://daim.lfv.se/geoserver/wfs"

# Parametrar för WFS-anrop
params <- list(
  service = "WFS",
  version = "1.1.0",
  request = "GetFeature",
  typename = "mais:RSTA",
  CQL_FILTER = "LOWER='GND'",
  outputFormat = "application/json",
  srsname = "EPSG:3857"
)

# Skicka GET-förfrågan till WFS-tjänsten och läs svaret som GeoJSON
response <- httr::GET(url = base_url, query = params)
geojson_data <- httr::content(response, "text", encoding = "UTF-8")

# Konvertera svaret till en sf-objekt
# Notera: Om du vill omprojicera till WGS84 (EPSG:4326), kan du använda st_transform
features <- st_read(geojson_data)
features_wgs84 <- st_transform(features, 4326)

# Visa de första raderna av resultatet
print(head(features_wgs84))

tmap_mode("view")
tm_shape(features_wgs84) + tm_fill(col = "blue") + tm_borders()
                                             