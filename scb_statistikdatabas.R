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

if (!file.exists("data/DeSO_2018.shp")){
  url_deso <- "https://geodata.scb.se/geoserver/stat/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=stat%3ADeSO.2018&outputFormat=SHAPE-ZIP&format_options=charset:UTF-8"
  url_regso <- "https://geodata.scb.se/geoserver/stat/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=stat%3ARegSO.2018&outputFormat=SHAPE-ZIP&format_options=charset:UTF-8"
  
  f <- paste(getwd(), "/data/deso.zip", sep = "")
  download.file(url_deso, f, mode="wb")
  unzip(f, exdir = "data")
  
  f <- paste(getwd(), "/data/regso.zip", sep = "")
  download.file(url_regso, f, mode="wb")
  unzip(f, exdir = "data")
}

if (!file.exists("data/pxdf.rds")){
  pxq <- pxweb_query("data/query_befstat.json")
  
  pxd <- pxweb_get("https://api.scb.se/OV0104/v1/doris/sv/ssd/BE/BE0101/BE0101Y/FolkmDesoAldKonN",
                   pxq)
  pxd
  
  pxdf <- as.data.frame(pxd, column.name.type = "text", variable.value.type = "text")
  saveRDS(pxdf, "data/pxdf.rds")
} else {
  pxdf <- readRDS("data/pxdf.rds")
}
head(pxdf)

deso_sthlm_df <- pxdf %>% 
  filter(grepl("^\\d{4}[A-C]\\d{4}$", region) == TRUE,
         substr(region, 1, 4) == "0180",
         ålder == "totalt", kön == "totalt") %>% 
  dplyr::select(-ålder, -kön) %>% 
  rename(deso = region)


deso_sthlm_df <- pxdf %>% 
  filter(grepl("^\\d{4}[A-C]\\d{4}$", region) == TRUE,
         substr(region, 1, 4) == "0180",
         ålder %in% c("0-4 år", "75-79 år", "80- år"), 
         kön == "totalt") %>% 
  #select(-ålder, -kön) %>% 
  rename(deso = region) %>% 
  group_by(deso) %>% summarise(`Folkmängden per region` = sum(`Folkmängden per region`))

st_write(deso_areas_sf, "../miljöförvaltningen/data/deso_pop_young_old.gpkg", delete_dsn = T)
st_write(deso_areas_sf %>% st_transform(., crs = 3011), "data/deso_pop_young.gpkg", delete_dsn = T)

# Read join table, DeSO <-> RegSO
deso_regso <- read.xlsx("https://www.scb.se/contentassets/e3b2f06da62046ba93ff58af1b845c7e/kopplingstabell-deso_regso_20211004.xlsx", 
                        "Blad1",
                        startRow = 4) %>% dplyr::select(-Kommun, -Kommunnamn) %>% 
  rename(deso = DeSO, regso_namn = RegSO, regso = RegSOkod)

# Join DesO and RegSO
deso_sthlm_df <- deso_sthlm_df %>% 
  left_join(., deso_regso, by = c("deso" = "deso")) %>% 
  rename(pop_count = `Folkmängden per region`)

# Join statistics with geography
# NOTE: First run the script scb_wfs.R
deso_areas_sf <- st_read("data/DeSO_2018.shp") %>% 
  filter(kommun == "0180") %>%
  left_join(., deso_sthlm_df, by = c("deso" = "deso"))

# RegSO

# Join statistics with geography
regso_areas_sf <- st_read("data/RegSO_2018.shp") %>% filter(kommun == "0180") %>% 
  rename(regso_namn = regso, regso = regsokod)

# Sum population counts per RegSO
pop_count_regso <- deso_sthlm_df %>% group_by(regso, regso_namn) %>% summarise(pop_count = sum(pop_count)) %>% ungroup()

# Join statistics with geography
regso_areas_sf <- regso_areas_sf %>% left_join(.,
                                               pop_count_regso %>% select(-regso_namn),  # Exclude the name as it's in both sides.
                                               by = "regso")

# Spara geodata, med befolkningssiffror.
st_write(deso_areas_sf, "data/deso_pop.gpkg")
st_write(regso_areas_sf, "data/regso_pop.gpkg")

# # Create a thematic map
tm_shape(regso_areas_sf) + 
  tm_fill(
    "pop_count", 
    style = "jenks", 
    palette = "viridis") + 
  tm_borders() +
  tm_shape(regso_areas_sf) +
  tm_text("regso_namn", remove.overlap = TRUE)
