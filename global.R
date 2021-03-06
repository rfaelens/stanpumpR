# Load Libraries
library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinyBS)
library(ggpubr)
library(mailR)
library(ggplot2)
library(grid)
library(RColorBrewer)
library(openxlsx)
library(dplyr)
library(officer)
library(rvg)
library(R.utils)
library(jpeg)
library(egg)
library(ggpubr)
library(splines)
library(randomcoloR)
library(rhandsontable)
library(DT)
library(config)
library(purrr)
library(data.table)
library(stringi)
library(png)
library(jsonlite)
# library(ggplotify)
#library(facetscales)
library(tidyr)
library(dqshiny)
library(shinyWidgets)


# tell shiny to log all reactivity
library(reactlog)
options(warn = 2)
isShinyLocal <- Sys.getenv('SHINY_PORT') == ""
# cat("isShinyLocal",isShinyLocal,"\n")

if (!isShinyLocal) {
  Sys.setenv(R_CONFIG_ACTIVE = "production")  # Running on Shinyapps
  internetConnected <- TRUE
} else {
  Sys.unsetenv("R_CONFIG_ACTIVE") # Running on laptop
  internetConnected <- FALSE
  appFiles <- dir()
  appFiles <- appFiles[grepl("\\.",appFiles)]
  appFiles <- c(appFiles, "helpers","data","www", "misc")

  source("helpers/havingIP.R")
  if (havingIP() && ping("google.com")) internetConnected <- TRUE
  library(rsconnect)
  options(shiny.reactlog=TRUE)
  source("misc/deployActive.R")
  source("misc/deployTest.R")
}
config <- config::get()

# Load stanpumpR routines
for (file in list.files("helpers", pattern = "\\.R$")) {
  source(file.path("helpers", file), local = TRUE)
}

# Load other files
#CANCEL <- readPNG("www/cancel.png", native=TRUE)
enableBookmarking(store = "url")

eventDefaults_global <- read.csv("data/Event Defaults.csv", stringsAsFactors = FALSE)
eventDefaults <- eventDefaults_global

drugDefaults_global <- read.csv("data/Drug Defaults.csv", stringsAsFactors = FALSE, na.strings = "")

# Load individual drug routines
for (drug in drugDefaults_global$Drug)
{
  source(file.path("data", "drugs", paste0(drug, ".R")))
}

facetFont <-      c(  20,   18,   18,   16,   14,   14,   14,   13,   13,   12,   11,   10,    9,    9,   8,  8)
labelFont <-      c(  16,   15,   14,   13,   12,   11,   9,    8,    8,    7,    6,    6,    5,    5,   5,  5)
facetSeperator <- c( " ",  "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n", "\n")
facetAngle <-     c( 270,  270,  180,  180,  180,  180,  180,  180,  180,  180,  180,  180,  180,  180,  180, 180)
facetSpacing <-   c(2.25,    2,  1.75,  1.5,    1,    1,  0.8,  0.7,  0.6,  0.6,  0.5,  0.5,  0.4,  0.3,  0.3, 0.2)


#default variables
defaultAge <- 50      # Years
defaultAgeUnit <- 1   # Year
defaultWeight <- 60   # Kg
defaultWeightUnit <- 1  # Kg
defaultHeight <- 66    # Centimeters
defaultHeightUnit <- 2.56  # Inches
defaultSex <- "female"

# defaultAge <- NULL
# defaultAgeUnit <- character(0)
# defaultWeight <- NULL
# defaultWeightUnit <- character(0)
# defaultHeight <- NULL
# defaultHeightUnit <- character(0)
# defaultSex <- character(0)

# Default aspect ratio
aspect <- 0.6

# Resolution for linear interpolation
resolution <- 100

# Be sure there are more items below then potential facets on the simulation plot
#                     1     2     3     4     5     6     7     8     9    10    11    12    13    14   15
bolusUnits <- c("g","mg","mcg", "ng","g/kg","mg/kg","mcg/kg","ng/kg")
infusionUnits <- c("mg/min","mg/hr","mg/kg/min","mg/kg/hr","mcg/min","mcg/hr","mcg/kg/min","mcg/kg/hr")
poUnits <- c("g PO", "g/kg PO", "mg PO", "mg/kg PO", "mcg PO", "mcg/kg PO")
inUnits <- c("g IN", "g/kg IN", "mg IN", "mg/kg IN", "mcg IN", "mcg/kg IN")
imUnits <- c("g IM", "g/kg IM", "mg IM", "mg/kg IM", "mcg IM", "mcg/kg IM")

allUnits <- c(bolusUnits, infusionUnits, poUnits, inUnits, imUnits)


maxtimes <- data.frame(
  times = c(10, 30, 60, 90, 120, 180, 240, 300, 360, 480, 600, 720, 1440, 1680, 1920, 2880, 4320, 5760,7200, 1000000 ),
  steps = c( 1,  5, 10, 15,  15,  30,  30,  60,  60,  60, 120, 120, 240,  240, 240,  480,   480,  720, 720, 1440)
)


x <- system.time({
  havingIP <- function() {
    if (.Platform$OS.type == "windows") {
      ipmessage <- system("ipconfig", intern = TRUE)
    } else {
      ipmessage <- system("ifconfig", intern = TRUE)
    }
    validIP <- "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)[.]){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    any(grep(validIP, ipmessage))
  }
  ping <- function(x, stderr = FALSE, stdout = FALSE, ...){
    pingvec <- system2("ping", x,
                       stderr = FALSE,
                       stdout = FALSE,...)
    if (pingvec == 0) TRUE else FALSE
  }
})
cat("Time to determine if it has an internet connection\n")
print(x)
cat("\n")

# Setup Theme
theme_update(panel.background = element_rect(fill = "white", color = "white"))
theme_update(legend.box.background = element_rect(fill = "white", color = "white"))
theme_update(panel.grid.major.y = element_line(color = "lightgrey"))
theme_update(panel.grid.major.x = element_line(color = "lightgrey"))
theme_update(axis.ticks = element_line(color = "lightgrey"))
theme_update(axis.ticks.length = unit(.25, "cm"))
theme_update(axis.title = element_text(size = rel(1.5)))
theme_update(axis.text = element_text(size = rel(1.2)))
theme_update(axis.line = element_line(size = 1, color = "black"))
theme_update(axis.title = element_text(size = rel(1.5)))
theme_update(legend.key = element_rect(fill = "white"))
theme_update(aspect.ratio = 0.6)
theme_update(plot.title = element_text(size = rel(1.5)))
theme_update(legend.text = element_text(size = rel(0.9)))
theme_update(legend.position = "right")
theme_update(legend.key = element_blank())


introductionPlot <- staticPlot(
  paste(
    "Initializing your session.",
    sep = "\n"
  )
)

nothingtoPlot <- staticPlot(
  paste(
    "Welcome to stanpumpR.",
    "",
    "Please enter the drugs in the table to the left.",
    "Use the pull down menu to select each drug.",
    "Drugs and doses can be entered in any order",
    "Set the units in the last column.",
    "",
    "After plots appear here, you can enter new doses",
    "by clicking on the plot. You can enter new drugs",
    "by double clicking on any plot.",
    sep = "\n"
  )
)


originalUnits <- drugDefaults_global$Units
drugDefaults_global$Units <- strsplit(drugDefaults_global$Units, ",")

blanks <- rep("", 6)
doseTableInit <- data.frame(
  Drug = c("propofol","fentanyl","remifentanil","rocuronium", blanks),
  Time = c(as.character(rep(0,4)), blanks),
  Dose = c(as.character(rep(0,4)), blanks),
  Units = c("mg","mcg","mcg/kg/min","mg", blanks),
  stringsAsFactors = FALSE
)
doseTableNewRow <-  doseTableInit[5, ]

`%then%` <- shiny:::`%OR%`

