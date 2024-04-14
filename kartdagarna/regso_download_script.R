# Importera basbiblioteket (httr är nämnt men används inte här, alla funktioner är inbyggda i R)
library(httr)

# Ange URL till zip-filen
# Detta är den direkta länken till zip-filen du vill ladda ner
url <- "https://www.scb.se/contentassets/e3b2f06da62046ba93ff58af1b845c7e/regso_2018_v2.zip"

# Skapa en sökväg för att spara den nedladdade filen
# 'getwd()' returnerar den aktuella arbetsmappens sökväg
# Filen sparas i den aktuella arbetsmappen under namnet 'regso_2018_v2.zip'
file_path <- paste0(getwd(), "/regso_2018_v2.zip")

# Ladda ner zip-filen
# 'mode="wb"' anger att filen ska sparas i binärt format, vilket är viktigt för att korrekt hantera zip-filer
download.file(url, file_path, mode="wb")

# Packa upp den nedladdade zip-filen
# 'exdir' specifierar mappen där innehållet i zip-filen ska extraheras
# Ändra "data" till önskad destinationsmapp om nödvändigt
unzip(file_path, exdir = "kartdagarna/data")

# (Valfritt) Rensa upp genom att ta bort den nedladdade zip-filen efter extraktion
# Om du inte behöver behålla zip-filen kan du avkommentera nästa rad för att ta bort den
# unlink(file_path)
