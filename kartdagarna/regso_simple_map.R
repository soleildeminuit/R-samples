# Installera och ladda nödvändiga paket
if (!requireNamespace("sf", quietly = TRUE))
  install.packages("sf")
if (!requireNamespace("ggplot2", quietly = TRUE))
  install.packages("ggplot2")

library(sf)
library(ggplot2)

# Ange sökväg till den geopaket-fil som extraherades
file_path <- "kartdagarna/data/RegSO_2018_v2.gpkg"

# Läs in geodata
geodata <- st_read(file_path)

# Filtrera ut data för Göteborgs kommun (kommunkod för Göteborg är '1480')
goteborg_data <- geodata[geodata$kommun == '1480', ]

# Kontrollera datastrukturen för Göteborg
print(goteborg_data)

# Plotta en enkel karta över Göteborgs kommun
ggplot(goteborg_data) +
  geom_sf() +
  ggtitle("Karta över Göteborgs kommun") +
  theme_minimal()
