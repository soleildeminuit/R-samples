# Installera och ladda nödvändiga paket
# Kontrollerar först om paketen 'sf' och 'tmap' är installerade och installerar dem om de inte finns
if (!requireNamespace("sf", quietly = TRUE))
  install.packages("sf")
if (!requireNamespace("tmap", quietly = TRUE))
  install.packages("tmap")

library(sf)   # För hantering av geodata
library(tmap) # För att skapa och visualisera kartor

# Ange sökväg till den geopaket-fil som extraherades
file_path <- "kartdagarna/data/RegSO_2018_v2.gpkg"

# Läs in geodata med st_read från paketet 'sf'
# Funktionen st_read läser geografiska data från olika format
geodata <- st_read(file_path)

# Filtrera ut data för Göteborgs kommun (kommunkod för Göteborg är '1480')
# Göteborgs kommun identifieras genom kommunnumret '1480', vi använder detta för att filtrera dataset
goteborg_data <- geodata[geodata$kommun == '1480', ]

# Kontrollera datastrukturen för Göteborg
# Skriver ut strukturen för dataramen 'goteborg_data' för att verifiera korrekt filtrering
print(goteborg_data)

# Plotta en enkel karta över Göteborgs kommun med tmap
# Sätter tmap i interaktivt läge för att kunna interagera med kartan i RStudio eller webbläsare
tmap_mode("view")

# Använder tm_shape för att definiera datamängden och tm_polygons för att visa polygonerna (kommungränser)
# tm_layout används för att anpassa kartans utseende, inklusive att lägga till en titel
tm_shape(goteborg_data) +
  tm_polygons() +
  tm_layout(title = "Karta över Göteborgs kommun")
