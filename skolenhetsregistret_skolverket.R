library(jsonlite)
library(httr)
library(plyr)
library(dplyr)
library(sf)

fetchSchholUnitStats <- function(schoolUnitCode){
  my_url <- ""
  
  my_probe_url <- paste("https://api.skolverket.se/planned-educations/school-units/", schoolUnitCode, "/statistics/",
                        sep = "")
  
  httpResponse <- GET(my_probe_url, 
                      add_headers(Accept = "application/vnd.skolverket.plannededucations.api.v2.hal+json"))
  probe_result = fromJSON(content(httpResponse, "text", encoding = "UTF-8"))
  
  if (!is.null(probe_result$body$`_links`$`gr-statistics`)){
    my_url <- probe_result$body$`_links`$`gr-statistics`  
  } else {
    my_url <- probe_result$body$`_links`$`gy-statistics`
  }
  my_url <- gsub("http", "https", my_url)
  
  httpResponse <- GET(my_url, 
                      add_headers(Accept = "application/vnd.skolverket.plannededucations.api.v2.hal+json"))
  stats = fromJSON(content(httpResponse, "text", encoding = "UTF-8"))
  if (stats$status=="NOT_FOUND"){
    return(NA)  
  }
  else{
    points <- 0
    nr <- 0
    for (i in 1:length(stats$body$programMetrics$admissionPointsAverage)){
      p <- stats$body$programMetrics$admissionPointsAverage[i][[1]][1]$value
      if (!is.na(p)){
        p <- gsub(",", ".", p) %>% as.numeric()
        points <- points + p
        nr <- nr + 1
      }
    }
    points <- points / nr
    
    return(as.data.frame(df))
  }
}

fetchSchholUnitInfo <- function(schoolUnitCode){
  my_url <- paste("https://api.skolverket.se/planned-educations/school-units/", schoolUnitCode, sep = "")
  httpResponse <- GET(my_url, 
                      add_headers(Accept = "application/vnd.skolverket.plannededucations.api.v2.hal+json"))
  info = fromJSON(content(httpResponse, "text", encoding = "UTF-8"))
  df <- t(as.data.frame(unlist((info$body))))
  row.names(df) <- NULL
  return(as.data.frame(df))
}

my_url <- "https://api.skolverket.se/planned-educations/school-units" # ?geographicalAreaCode=0180
httpResponse <- GET(my_url, 
                    add_headers(Accept = "application/vnd.skolverket.plannededucations.api.v3.hal+json"))

info = fromJSON(content(httpResponse, "text", encoding = "UTF-8"))

last_page <- info$body$page$totalPages-1

datalist <- list()

for (i in 0:last_page){
  my_url <- 
    paste("https://api.skolverket.se/planned-educations/school-units?&page=",i,sep="") # geographicalAreaCode=0180&
  httpResponse <- GET(my_url, 
                      add_headers(Accept = "application/vnd.skolverket.plannededucations.api.v3.hal+json"))
  
  info = fromJSON(content(httpResponse, "text", encoding = "UTF-8"))
  df <- info$body$`_embedded`$listedSchoolUnits
  
  df$`_links` <- NA
  
  datalist[[i+1]] <- df
}
school_units = do.call(rbind, datalist)

school_units <- school_units %>% 
  filter(geographicalAreaCode == "0180")

l <- list()
for (i in 1:nrow(school_units)){
  sei <- fetchSchholUnitInfo(school_units[i,]$code)
  l[[i]] <- sei
  if (i %% 200 == 0){
    print(i)
  }
}
school_units_info <- data.frame()
school_units_info <- do.call("rbind.fill", l)

school_units_info <- school_units_info %>% filter(!is.na(sweRef_E))
school_units_info <- st_as_sf(school_units_info, coords = c("wgs84_Long", "wgs84_Lat"), crs = 4326)

mapview::mapview(school_units_info)