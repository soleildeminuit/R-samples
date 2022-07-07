list.of.packages <- c("pxweb", "openxlsx")
new.packages <- list.of.packages[!(list.of.packages %in%
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(pxweb)
library(dplyr)
library(sf)
library(tmap)
library(openxlsx)
library(viridis)

if (!file.exists("data/RegSO_2018.shp")){
  # url_deso <- "https://geodata.scb.se/geoserver/stat/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=stat%3ADeSO.2018&outputFormat=SHAPE-ZIP&format_options=charset:UTF-8"
  url_regso <- "https://geodata.scb.se/geoserver/stat/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=stat%3ARegSO.2018&outputFormat=SHAPE-ZIP&format_options=charset:UTF-8"
  
  # f <- paste(getwd(), "/data/deso.zip", sep = "")
  # download.file(url_deso, f, mode="wb")
  # unzip(f, exdir = "data")
  
  f <- paste(getwd(), "/data/regso.zip", sep = "")
  download.file(url_regso, f, mode="wb")
  unzip(f, exdir = "data")
}

regso <- st_read("data/RegSO_2018.shp", stringsAsFactors = FALSE)
kommuner <- regso %>% st_drop_geometry() %>% 
  group_by(kommun) %>% summarise() %>% ungroup()

l <- list()
for (i in 1:nrow(kommuner)){
  delmos_url <- 
    paste("https://segregationsbarometern.delmos.se/api.php?action=list_regions&recursive=1&region=kommun&code=",
          kommuner[i,]$kommun, sep = "")
  x <- jsonlite::fromJSON(delmos_url) %>% select(-deso)
  x <- x %>% rename(regsokod_delmos = regsokod) %>% select(-c(id))
  l[[i]] <- x
}
df_delmos <- do.call("rbind", l) %>% rename(regso = regso_namn, kommun = kopplad_kommun)

regso <- inner_join(regso, df_delmos, by = c("regso" = "regso", "kommun" = "kommun"))

st_write(regso, "data/RegSO_2018_Delmos.gpkg", delete_dsn = TRUE)