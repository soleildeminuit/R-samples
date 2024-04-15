library(sf)
library(httr)

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

mapview::mapview(features_wgs84)
