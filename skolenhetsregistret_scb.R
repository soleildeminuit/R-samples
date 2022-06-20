list.of.packages <- c("dplyr", "plyr", "jsonlite", "sf")
new.packages <- list.of.packages[!(list.of.packages %in%
                                     installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


skolenheter <- fromJSON("https://api.scb.se/UF0109/v2/skolenhetsregister/sv/skolenhet/")
skolenheter <- skolenheter$Skolenheter
skolenheter <- skolenheter %>% filter(Kommunkod=="0180")

my_list = list()
for (i in 1:nrow(skolenheter)){
  skolenhet <- fromJSON(paste("https://api.scb.se/UF0109/v2/skolenhetsregister/sv/skolenhet/",
                              skolenheter[i,]$Skolenhetskod,sep = ""))
  
  if ("Gymnasieskola" %in% skolenhet$SkolenhetInfo$Skolformer$Benamning){
    df <- t(as.data.frame(unlist(skolenhet$SkolenhetInfo)))
    rownames(df) <- NULL
    df <- as.data.frame(df)
    
    if (!is.null(df$Skolformer.NA)){
      if (df$Skolformer.NA == TRUE){
        my_list[[i]] <- df
      }
    }
  }
}

df <- data.frame()
df <- do.call("rbind.fill", my_list)

df$Besoksadress.GeoData.Koordinat_SweRef_E <- 
  as.numeric(gsub(",", ".", df$Besoksadress.GeoData.Koordinat_SweRef_E))
df$Besoksadress.GeoData.Koordinat_SweRef_N <- 
  as.numeric(gsub(",", ".", df$Besoksadress.GeoData.Koordinat_SweRef_N))

df_utan_koord <- df %>% filter(is.na(Besoksadress.GeoData.Koordinat_SweRef_N))
df <- df %>% filter(!is.na(Besoksadress.GeoData.Koordinat_SweRef_N))
df <- st_as_sf(df, 
               coords=c("Besoksadress.GeoData.Koordinat_SweRef_E", 
                        "Besoksadress.GeoData.Koordinat_SweRef_N"),
               crs=3006)
# 
# sdn <- st_read("../data/sbk/Adm_area_ny.shp") %>% st_transform(crs = 3006)
# 
# df <- df %>% st_intersection(sdn)

