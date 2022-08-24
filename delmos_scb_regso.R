list.of.packages <- c("pxweb", "openxlsx")
new.packages <- list.of.packages[!(list.of.packages %in%
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(dplyr)
library(jsonlite)
library(sf)

# Kolla om RegSo laddats ned tidigare, annars hämta på nytt.
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

# Använd RegSo för att lista alla kommuner
regso <- st_read("data/RegSO_2018.shp", stringsAsFactors = FALSE)
kommuner <- regso %>% st_drop_geometry() %>% 
  group_by(kommun, kommunnamn) %>% summarise() %>% ungroup()

l <- list()
for (i in 1:nrow(kommuner)){
  delmos_url <- 
    paste("https://segregationsbarometern.delmos.se/api.php?action=list_regions&recursive=1&region=kommun&code=",
          kommuner[i,]$kommun, sep = "")
  x <- jsonlite::fromJSON(delmos_url) %>% select(-deso)
  x <- x %>% rename(regsokod_delmos = regsokod) %>% select(-c(id))
  
  l2 <- list()
  for (j in 1:nrow(x)){
    delmos_omr_url <- paste("https://segregationsbarometern.delmos.se/api.php?action=get_region&region=regso&code=",
                            x[j,]$regsokod_delmos,"&year=2020",sep="")
    omr <- fromJSON(delmos_omr_url, flatten = TRUE)
    omr_data <- data.frame(t(unlist(omr$meta)))
    l2[[j]] <- omr_data
  }
  x <- cbind(x, do.call("rbind", l2))
  
  l[[i]] <- x
  
  print(paste(i, ":", kommuner[i,]$kommunnamn, sep=""))
}
df_delmos <- do.call("rbind", l) %>% rename(regso = regso_namn, kommun = kopplad_kommun)

regso <- inner_join(regso, df_delmos, by = c("regso" = "regso", "kommun" = "kommun"))

regso <- regso %>% select(uuid, regsokod, regsokod_delmos, regso, everything())

regso <- regso %>% mutate_at(vars(antal_deso:omradestyp_kommun_5),list(as.numeric))

# st_write(regso, "data/RegSO_2018_Delmos.gpkg", delete_dsn = TRUE)