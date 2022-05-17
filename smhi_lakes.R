library(dplyr)
library(sf)

url_lake_reg <- "https://opendata-download.smhi.se/svar/Vattenytor_2016.zip"

if (!file.exists("data/Vattenytor_2016.shp")){
  temp <- tempfile()
  download.file(url_lake_reg, temp, mode="wb")
  unzip(temp, exdir = "data")
  unlink(temp)
}

lakes <- st_read("data/Vattenytor_2016.shp")
