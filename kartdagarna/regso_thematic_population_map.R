# Installera och ladda nödvändiga paket
if (!requireNamespace("dplyr", quietly = TRUE))
  install.packages("dplyr")
if (!requireNamespace("tidyr", quietly = TRUE))
  install.packages("tidyr")
if (!requireNamespace("sf", quietly = TRUE))
  install.packages("sf")
if (!requireNamespace("tmap", quietly = TRUE))
  install.packages("tmap")
if (!requireNamespace("readr", quietly = TRUE))
  install.packages("readr")

library(dplyr)
library(tidyr)
library(sf)
library(tmap)
library(readr)

# https://www.statistikdatabasen.scb.se/sq/148233

# Läs in befolkningsdata från CSV-fil
# population_file_path <- "kartdagarna/data/000005FF_20240414-181616.csv"

# Ange URL till CSV-filen
population_url <- "https://www.statistikdatabasen.scb.se/sq/148233"

# Ange teckenkodning när du läser in CSV-filen
population_data <- read_csv(population_url, locale = locale(encoding = "ISO-8859-1"))

# Dela upp 'region' kolumnen till 'kommun' och 'regso'
population_data <- population_data %>%
  mutate(kommunnamn = gsub("\\s*\\(.*\\)$", "", region),  # Skapar 'kommun' genom att ta bort parentesinnehållet
         regso = gsub(".*\\((.*)\\)", "\\1", region)) %>%  # Extraherar strängen inom parentes för 'regso'
  select(-region)  # Tar bort den gamla 'region' kolumnen

# Läs in geodata
geo_file_path <- "kartdagarna/data/RegSO_2018_v2.gpkg"
geodata <- st_read(geo_file_path)

# Kontrollera att geodata innehåller kolumnerna 'kommun' och 'regso'
# Detta antas vara korrekt enligt din beskrivning, men du bör verifiera detta.

# Sammanfoga 'population_data' med 'geodata' baserat på både 'kommun' och 'regso'
merged_data <- geodata %>%
  left_join(population_data, by = c("kommunnamn", "regso"))

# Ändra namn på kolumnen '2023' till 'antal'
# Kolumnnamnet '2023' är olämpligt eftersom det börjar med en siffra och kan orsaka problem i många programmeringssammanhang,
# särskilt i R där sådana namn måste citeras särskilt och inte kan hanteras lika direkt som standardnamn.
merged_data <- merged_data %>% 
  rename(antal = `2023`)

# Välj om kolumnordningen så att 'regso' och 'antal' kommer först
# Detta steg förbättrar datans överskådlighet genom att placera viktiga kolumnerna främst,
# vilket gör det enklare att få en överblick över datan när den visas eller analyseras.
merged_data <- merged_data %>% 
  select(regso, antal, everything())


# Skapa en tematisk karta över befolkningsdata
tmap_mode("view")  # Aktiverar interaktivt läge för visning i webbläsare
tm_shape(
  merged_data %>% filter(kön == "totalt", kommun == "1480")) +
  tm_fill(col = "antal",  # Använder kolumnen '2023' för att färglägga baserat på befolkningsdata
              alpha = 0.5,
              style = "jenks",
              title = "Total population 2023") +
  tm_borders() +
  tm_layout(title = "Tematisk karta över befolkning efter regso och kommun")
