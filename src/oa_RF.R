#' ---
#' title: "Random Forests", OAs
#' date: "`r format(Sys.time(), '%d %B, %Y, %H:%M')`"
#' output: 
#'   html_document:
#'     df_print: paged
#'     toc: true
#'     toc_float: true
#' knit: (function(inputFile, encoding) {
#'     rmarkdown::render(inputFile, encoding = encoding, output_dir = "../output")
#'   })
#' ---
#' 
## ----setup, include=FALSE--------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

library(tidyverse)
library(rprojroot)
#library(rgdal)
#library(rgeos)
library(sf)
library(spdep)
#library(tmap)
#library(maptools)
library(knitr)
library(REAT)
library(tidygeocoder)
library(geosphere)
library(broom)
#library(foreach)
library(doParallel)
library(raster)
library(plm)
#library(lmtest)
library(caret)
library(randomForest)
library(CAST)

options(scipen=10000)

# This is the project path
path <- find_rstudio_root_file()

#' 
#' ## Load data
#' 
#' Postcode lookup.
#' 
#' [source](https://geoportal.statistics.gov.uk/datasets/postcode-to-output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-august-2021-lookup-in-the-uk/about)
#' 
## --------------------------------------------------------------------------
path.lookup <- paste0(path,"/data/raw/PCD_OA_LSOA_MSOA_LAD_AUG21_UK_LU.csv")
lookup <- read_csv(path.lookup) %>% 
  dplyr::select(pcds, oa11cd) %>% 
  dplyr::rename(pc = pcds)
#glimpse(lookup)
# The problems refer to Welsh LAD names. Not a problem for the analysis.
#sapply(lookup, function(x) sum(is.na(x)))
# 10332 missing msoa11cd

#' 
#' The internet archive $1996$-$2010$ data is saved on /hdd.
#' The internet archive $2011$-$2012$ data is saved on ~/projects/web.diffusion/data/temp.
#' 
## --------------------------------------------------------------------------
n = 1 #number of unique postcodes. 
m = 12

data.folder <- "/hdd/internet_archive/archive/data/"
data.path9610 <- paste0(data.folder, "domain_pc_year.csv")
#Created by domain.R, which uses domain instead of host.
#This is what we use for the hyperlinks paper as per George's script

df9610 <- read_csv(data.path9610) 

data.path2011_2012 <- paste0(path, "/data/temp/domain_pc_year1112.csv")
#Created by domain1112.Rmd, which is based on domain.R and uses domain instead of host.
#This is what we use for the hyperlinks paper as per George's script

df1112 <- read_csv(data.path2011_2012)

df <- bind_rows(df9610, df1112) %>% 
  filter(
    #V1.domain < m,             # for multiple pc
    V1.domain == n,             # for n == 1
    year > 1995 & year <2013) %>%   
  left_join(lookup, by = "pc", suffix =c("","")) %>% 
  group_by(year, oa11cd) %>%
  #summarise(n = n()) %>%            # for multiple pc  
  summarise(n = sum(V1.domain)) %>%  # for n == 1 
  ungroup()

# Partially complete panel as not all OAs have a website in at least one year
df <- df %>% filter(!is.na(oa11cd)) %>% 
  complete(oa11cd, year) %>% 
  replace(is.na(.), 0)

# tests for Scotland
# df %>% filter(substr(oa11cd, 1,1) =="S",
#               year==2010) %>% summarise(mean(n, na.rm = T))
# 
# df %>% filter(oa11cd=="S00090182")
# 
# test@data %>% filter(substr(id, 1,1) =="S",
#                      n!=0)
# 
# df %>% filter(substr(oa11cd, 1,1) =="W",
#               year==2003)

#' 
#' ## spatial data OLD
#' 
## ----eval=F----------------------------------------------------------------
## # get OA for England and Wales
## path.geo <- paste0(path, "/data/raw/Output_Areas__December_2011__Boundaries_EW_BGC.geojson")
## oa.ew <- readOGR(path.geo)
## # source: https://geoportal.statistics.gov.uk/
## 
## # spatial transformations
## oa.ew <- spTransform(oa.ew, CRS("+init=epsg:4326"))
## 
## # keep in the data slot only the ONS Output Area id, renaming it as 'id'
## oa.ew <- oa.ew[, c('OA11CD', 'Shape__Area')]
## colnames(oa.ew@data) <- c('id', 'area')
## 
## # reassign the polygon IDs
## oa.ew <- spChFIDs(oa.ew, as.character(oa.ew$id))
## 
## # check the CRS has changed correctly, and the data slot has shrink to only the ID
## summary(oa.ew)
## 
## # # get OA for Scotland
## # path.geo.sc <- paste0(path, "/data/raw/SG_DataZoneBdry_2011")
## # oa.sc <- readOGR(dsn=path.geo.sc, layer = "SG_DataZone_Bdry_2011")
## # # source: https://data.gov.uk/dataset/ab9f1f20-3b7f-4efa-9bd2-239acf63b540/data-zone-boundaries-2011
## #
## # # spatial transformations
## # oa.sc <- spTransform(oa.sc, CRS("+init=epsg:4326"))
## #
## # # Scotland (follows same steps as EW, see notes above)
## # oa.sc <- oa.sc[, 'DataZone']
## # colnames(oa.sc@data) <- c('id')
## #
## # # reassign the polygon IDs
## # oa.sc <- spChFIDs(oa.sc, as.character(oa.sc$id))
## #
## # # check the CRS has changed correctly, and the data slot has shrink to only the ID
## # summary(oa.sc)
## 
## path.geo.sc <- paste0(path, "/data/raw/output-area-2011-mhw")
## oa.sc <- readOGR(dsn=path.geo.sc, layer = "OutputArea2011_MHW")
## # source: https://www.nrscotland.gov.uk/statistics-and-data/geography/our-products/census-datasets/2011-census/2011-boundaries
## 
## # spatial transformations
## oa.sc <- spTransform(oa.sc, CRS("+init=epsg:4326"))
## 
## # Scotland (follows same steps as EW, see notes above)
## oa.sc <- oa.sc[, c('code', 'SHAPE_1_Ar')]
## colnames(oa.sc@data) <- c('id', 'area')
## 
## # reassign the polygon IDs
## oa.sc <- spChFIDs(oa.sc, as.character(oa.sc$id))
## 
## # check the CRS has changed correctly, and the data slot has shrink to only the ID
## summary(oa.sc)
## 
## # build oa for GB
## oa.gb <- maptools::spRbind(oa.ew, oa.sc)
## rm(oa.ew, oa.sc)
## 
## # oa.gb$geometry <- oa.gb$geometry %>%
## #   s2::s2_rebuild() %>%
## #   sf::st_as_sfc()
## 
## # get GB
## path.gb <- "/hdd/internet_archive/archive/gis/Countries_December_2014_Full_Clipped_Boundaries_in_Great_Britain.shp"
## gb <- readOGR(path.gb)
## # spatial transformations
## gb <- spTransform(gb, CRS("+init=epsg:4326"))

#' 
#' ## spatial data NEW
#' 
## --------------------------------------------------------------------------
library(sf)

# Get OA for England and Wales
path.geo <- paste0(path, "/data/raw/Output_Areas__December_2011__Boundaries_EW_BGC.geojson")
oa.ew <- st_read(path.geo)

# Spatial transformations
oa.ew <- st_transform(oa.ew, 4326)  # EPSG code for WGS84

# Rename columns and keep only necessary columns
oa.ew <- oa.ew %>% dplyr::select(OA11CD, Shape__Area) %>% 
  rename(id = OA11CD,
         area = Shape__Area)
# oa.ew <- oa.ew[, c('OA11CD', 'Shape__Area')]
# colnames(oa.ew) <- c('id', 'area')

# Check the data structure
print(summary(oa.ew))

# Get OA for Scotland
path.geo.sc <- paste0(path, "/data/raw/output-area-2011-mhw")
oa.sc <- st_read(dsn = path.geo.sc, layer = "OutputArea2011_MHW")

# Spatial transformations
oa.sc <- st_transform(oa.sc, 4326)  # EPSG code for WGS84

# Rename columns and keep only necessary columns
oa.sc <- oa.sc %>% dplyr::select(code, SHAPE_1_Ar) %>% 
  rename(id = code,
         area = SHAPE_1_Ar)
# oa.sc <- oa.sc[, c('code', 'SHAPE_1_Ar')]
# colnames(oa.sc) <- c('id', 'area')

# Check the data structure
print(summary(oa.sc))

# NI
path.geo.ni <- paste0(path, "/data/raw/ni_small_area/")
oa.ni <- st_read(dsn = path.geo.ni, layer = "SA2011")
oa.ni <- st_transform(oa.ni, 4326)  # EPSG code for WGS84
oa.ni <- oa.ni %>% dplyr::select(SA2011, Hectares) %>% 
  rename(id= SA2011,
         area = Hectares)

# Build OA for UK
oa.uk <- rbind(oa.ew, oa.sc, oa.ni)
rm(oa.ew, oa.sc, oa.ni)

# Get GB
path.gb <- "/hdd/internet_archive/archive/gis/Countries_December_2014_Full_Clipped_Boundaries_in_Great_Britain.shp"
gb <- st_read(path.gb)

# Spatial transformations
gb <- st_transform(gb, 4326)  # EPSG code for WGS84

#' 
#' ## Full panel
#' 
## --------------------------------------------------------------------------
#oa.sf <- st_as_sf(oa.uk)

oa.full <- replicate(17, oa.uk %>% as_tibble(), simplify = FALSE) %>%
  bind_rows(.id = 'id_') %>% 
  rename(year = id_) %>% 
  mutate(year = as.numeric(year) + 1995) %>% 
  dplyr::select(id, year)

df <- oa.full %>% left_join(df, by = c("id" = "oa11cd", "year" = "year")) %>% 
  replace(is.na(.), 0)

sapply(df, function(x) sum(is.na(x)))
rm(oa.full)

#' 
#' ## Distances to cities and retail centres
#' 
#' ### Cities as points
#' 
#' First set up the destinations. Origins are all the OA.
#' 
#' Major cities from [source](https://www.citypopulation.de/en/uk/cities/).
#' Retail centres from [source](https://data.cdrc.ac.uk/dataset/retail-centre-boundaries)
#' 
#' I use the centroids from arcgis API as they better reflect the city centres than 
#' than the geometric centres of the boundaries, which I use for `sum(n)`
#' 
## --------------------------------------------------------------------------
# oa centroids
# oa.uk.c <- (rgeos::gCentroid(oa.uk, byid=TRUE))@coords %>% as.data.frame()
# oa.uk.c$id <- row.names(oa.uk.c)  #as_tibble(rownames = NA) %>% 
#   mutate(id = row.names())

# oa.uk.c <- gCentroid(oa.uk, byid=TRUE)@coords %>% 
#   as.data.frame() %>% 
#   add_rownames(var = "id")
sf_use_s2(FALSE)
oa.uk.c <- st_centroid(oa.uk) %>%
  st_coordinates() %>%
  as.data.frame() %>%
  #add_rownames(var = "id") %>% 
  bind_cols(oa.uk %>% dplyr::select(id))

# cities
city.names <- c("London, UK", 
"Birmingham, UK",
"Glasgow, UK",
"Liverpool, UK",
"Bristol, UK",
"Manchester, UK",
"Sheffield, UK",
"Leeds, UK",
"Edinburgh, UK",
"Leicester, UK",
"Belfast, UK")	

cities <- geo(city.names, no_query = F, method = "arcgis") %>% 
  mutate(address = stringr::str_remove(address, ", UK"))

# # Replace London with Inner London centroid
# # Source: https://data.london.gov.uk/dataset/sub-regions-london-plan-consultation-2009
# london.path <- paste0(path, "/data/raw/London_shape")
# london.sf <- st_read(dsn = london.path, layer = "lp-consultation-oct-2009-subregions")
# # Spatial transformations
# london.sf <- st_transform(london.sf, 4326)  # EPSG code for WGS84
# 
# london.c <- london.sf %>% 
#   filter(Name == "Central") %>% 
#   st_centroid() %>% 
#   st_coordinates() %>%
#   as.data.frame() %>% 
#   rename(lat = Y, long = X) %>% 
#   mutate(address = "London, UK") %>% 
#   dplyr::select(address, lat, long)
# 
# cities <- cities %>% bind_rows(london.c) %>% 
#   slice(2:n()) %>% # to remove the old London centroid based on the cities geometry
#   mutate(address = stringr::str_remove(address, ", UK"))

#' 
#' ### City boundaries
#' 
## --------------------------------------------------------------------------

# # cities
# city.names <- c(
#   "London", 
#   "Birmingham",
#   "Glasgow",
#   "Liverpool",
#   "Bristol",
#   "Manchester",
#   "Sheffield",
#   "Leeds",
#   "Edinburgh",
#   "Leicester",
#   )	

# City boundaries
# Source: https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=name&tags=all(BDY_TCITY%2CDEC_2015)
path.in <- paste0(path, "/data/raw/Major_Towns_and_Cities_Dec_2015_Boundaries_V2_2022_121402779136482658.geojson")

city.names <- city.names %>% stringr::str_remove(", UK")

city.boundaries.ew <- st_read(path.in) %>% 
  st_transform(4326) %>% 
  filter(TCITY15NM %in% city.names) %>% 
  dplyr::select(OBJECTID, TCITY15CD, TCITY15NM) %>% 
  rename(code = TCITY15CD,
         name = TCITY15NM)

# Source: https://geoportal.statistics.gov.uk/
path.in <- paste0(path, "/data/raw/Local_Authority_Districts_(December_2021)_UK_BUC.geojson")
city.boundaries.sc.ni <- st_read(path.in) %>% 
  st_transform(4326) %>% 
  filter(grepl('Edinburgh|Glasgow|Belfast', LAD21NM)) %>% 
  dplyr::select(OBJECTID, LAD21CD, LAD21NM) %>% 
  rename(code = LAD21CD,
         name = LAD21NM)

# merge
city.boundaries <- rbind(city.boundaries.ew, city.boundaries.sc.ni)

#' 
#' ### Retail centres
#' 
## --------------------------------------------------------------------------
# retail centres <- 
geo.path <- paste0(path, "/data/raw/Retail_Boundaries_UK.gpkg")
#retail <-readOGR(geo.path) 
retail <- st_read(geo.path) %>% st_transform(4326)  # EPSG code for WGS84

#retail.major.cetres <- subset(retail, retail$Classification == "Major Town Centre") #%>% 
# retail.major.cetres.help <- gCentroid(retail, byid=TRUE)@coords %>% 
#   as.data.frame() %>% 
#   add_rownames(var = "id") #%>%
retail.major.cetres.help <- st_centroid(retail) %>% 
  #st_transform(4326) %>%
  st_coordinates() %>% 
  as.data.frame() %>% 
  add_rownames(var = "id")

# retail.major.cetres <- retail.major.cetres.help %>% 
#   st_as_sf(coords = c("x", "y"), crs = 27700) %>%
#   st_transform(4326) %>%
#   st_coordinates() %>%
#   as_tibble() %>% 
#   bind_cols(retail.major.cetres.help$id) %>% 
#   rename(id = '...3') %>% 
#   left_join(retail@data %>% mutate(id = rownames(retail@data)), by = 'id')
retail.major.cetres <- retail.major.cetres.help %>% 
  # as_tibble() %>% 
  # bind_cols(retail.major.cetres.help$id) %>% 
  # #rename(id = '...3') %>% 
  left_join(retail %>% rownames_to_column(var = "id"), by = 'id')

#' 
#' ### Distance to cities
#' 
## --------------------------------------------------------------------------
# NI
oa.uk.c.ni <- oa.uk.c %>% filter(str_detect(id, "^N"))

dist.ni <- distm(cbind(oa.uk.c.ni$X, oa.uk.c.ni$Y), cbind(cities$long, cities$lat), fun=distHaversine) 
dist.ni <- round((dist.ni/1000),2) %>% 
  as_tibble()  

names(dist.ni) <- cities$address #city.names 

dist.ni <- dist.ni %>% bind_cols(oa.uk.c.ni$id) %>% 
  rename(oa11cd = last_col()) %>% 
  relocate(oa11cd)

# dist$dist <- names(dist)[apply(dist[-1], MARGIN = 1, FUN = which.min)]
# dist$distMet <- apply(dist[,2:11], 1, min)

# min distance
dist.ni <- transform(dist.ni, dist = do.call(pmin, dist.ni[-1]))

# City name for minimum distance 
dist.ni <- dist.ni %>% mutate(dist.city.name = names(.)[max.col(.[2:12]*-1)+1L])

# GB
oa.uk.c.gb <- oa.uk.c %>% filter(!str_detect(id, "^N"))

dist.gb <- distm(cbind(oa.uk.c.gb$X, oa.uk.c.gb$Y), cbind(cities$long, cities$lat), fun=distHaversine) 
dist.gb <- round((dist.gb/1000),2) %>% 
  as_tibble()  

names(dist.gb) <- cities$address #city.names 

dist.gb <- dist.gb %>% bind_cols(oa.uk.c.gb$id) %>% 
  rename(oa11cd = last_col()) %>% 
  relocate(oa11cd)

# dist$dist <- names(dist)[apply(dist[-1], MARGIN = 1, FUN = which.min)]
# dist$distMet <- apply(dist[,2:11], 1, min)

# min distance
dist.gb <- transform(dist.gb, dist = do.call(pmin, dist.gb[-1]))

# City name for minimum distance 
dist.gb <- dist.gb %>% mutate(dist.city.name = names(.)[max.col(.[2:12]*-1)+1L])

# UK
dist <- rbind(dist.ni, dist.gb)

# calculate area
#oa.uk$area <- st_area(oa.uk) #/ 1000000

# Join with distance and area
df <- df %>% left_join(dist, by = c("id" = "oa11cd")) %>% 
  rename(oa11cd=id)  

sapply(df, function(x) sum(is.na(x)))

#' 
#' ### Distance to retail centres
#' 
## --------------------------------------------------------------------------
# dist.retail <- distm(cbind(oa.uk.c$X, oa.uk.c$Y), cbind(retail.major.cetres$X, retail.major.cetres$Y), fun=distHaversine) 
# dist.retail <- round((dist.retail/1000),2) %>% 
#   as_tibble()  

# NI
oa.uk.c.ni <- oa.uk.c %>% filter(str_detect(id, "^N"))
dist.retail.ni <- distm(cbind(oa.uk.c.ni$X, oa.uk.c.ni$Y), cbind(retail.major.cetres$X, retail.major.cetres$Y), fun=distHaversine) 
dist.retail.ni <- round((dist.retail.ni/1000),2) %>% 
  as_tibble()  

names(dist.retail.ni) <- retail.major.cetres$RC_ID

dist.retail.ni <- dist.retail.ni %>% bind_cols(oa.uk.c.ni$id) %>% 
  rename(oa11cd = last_col()) %>% 
  relocate(oa11cd)

# This efficiently returns the name of the column with the shortest distance
dist.retail.ni <- dist.retail.ni %>% mutate(dist.retail.name = names(.)[max.col(.[2:6424]*-1)+1L])

# dist.retail_ <- dist.retail %>% slice_sample(n=100)
# dist.retail_[,6425:6426]
# dist.retail_ <- transform(dist.retail_, dist.retail = do.call(pmin, dist.retail_[2:6424])) 
# sum(is.na(dist.retail_$dist.retail.name))

# Minimum distance 
dist.retail.ni <- transform(dist.retail.ni, dist.retail = do.call(pmin, dist.retail.ni[2:6424])) 
dist.retail.ni <- dist.retail.ni  %>% dplyr::select(oa11cd, dist.retail.name, dist.retail)

# GB
oa.uk.c.gb <- oa.uk.c %>% filter(!str_detect(id, "^N"))
dist.retail.gb <- distm(cbind(oa.uk.c.gb$X, oa.uk.c.gb$Y), cbind(retail.major.cetres$X, retail.major.cetres$Y), fun=distHaversine) 
dist.retail.gb <- round((dist.retail.gb/1000),2) %>% 
  as_tibble()  

names(dist.retail.gb) <- retail.major.cetres$RC_ID

dist.retail.gb <- dist.retail.gb %>% bind_cols(oa.uk.c.gb$id) %>% 
  rename(oa11cd = last_col()) %>% 
  relocate(oa11cd)

# This efficiently returns the name of the column with the shortest distance
dist.retail.gb <- dist.retail.gb %>% mutate(dist.retail.name = names(.)[max.col(.[2:6424]*-1)+1L])

# dist.retail_ <- dist.retail %>% slice_sample(n=100)
# dist.retail_[,6425:6426]
# dist.retail_ <- transform(dist.retail_, dist.retail = do.call(pmin, dist.retail_[2:6424])) 
# sum(is.na(dist.retail_$dist.retail.name))

# Minimum distance 
dist.retail.gb <- transform(dist.retail.gb, dist.retail = do.call(pmin, dist.retail.gb[2:6424])) 
dist.retail.gb <- dist.retail.gb  %>% dplyr::select(oa11cd, dist.retail.name, dist.retail)

# UK
dist.retail <- rbind(dist.retail.ni, dist.retail.gb)

# Join with complete panel
df <- df %>% left_join(dist.retail, by = c("oa11cd" = "oa11cd")) 
#sapply(df, function(x) sum(is.na(x)))

#' 
#' ## n for London, nearest city and retail
#' 
#' ### TODELETE
#' 
## ----eval=FALSE------------------------------------------------------------
## # ## THIS DROPS L999999... AND NI, WHICH NEEDS TO BE FIXED
## # #df <- df %>% filter(!is.na(area))
## #
## # cities.sf <- st_as_sf(cities, coords = c("long", "lat"))
## # cities.sf <- st_set_crs(cities.sf, 4326)
## #
## # # help1 <- st_filter(oa.sf, cities.sf) %>% as_tibble %>% dplyr::select(id) %>%
## # #   left_join(df, by = c("id"="oa11cd")) %>% dplyr::select(id, year, n)
## #
## # sf_use_s2(FALSE)
## # help1 <- st_filter( oa.gb, cities.sf) %>%
## #   #st_coordinates() %>%
## #   as_tibble() %>%
## #   dplyr::select(id) %>%
## #   mutate(cities = c("London",     # The city names have been manually checked and assigned
## #                     "Leicester",
## #                     "Leeds",
## #                     "Sheffield",
## #                     "Bristol",
## #                     "Birmingham",
## #                     "Manchester",
## #                     "Liverpool",
## #                     "Edinburgh",
## #                     "Glasgow"))
## #
## # # too slow
## # #dist$dist.city.name <- names(dist)[apply(dist[,2:11], MARGIN = 1, FUN = which.min)]
## #
## # # This efficiently returns the name of the column with the shortest distance
## # dist <- dist %>% mutate(dist.city.name = names(.)[max.col(.[2:11]*-1)+1L])
## #
## # help2 <- dist %>% left_join(help1, by = c("dist.city.name" = "cities")) %>%
## #   #rename(nearest.city.oa11cd = id) %>%
## #   dplyr::select(oa11cd, dist.city.name)
## #
## # df <- df %>%  left_join(help2, by = c("oa11cd" = "oa11cd"))

#' 
#' ### n for cities
#' 
## --------------------------------------------------------------------------
#help.retail <- dist.retail

# n nearest city
# df <- df %>% left_join(df %>% dplyr::select(oa11cd,year, n) %>% 
#                          rename(n.nearest.city = n), 
#                        by = c("nearest.city.oa11cd" = "oa11cd",
#                               "year" = "year")) 

sf_use_s2(FALSE)
city.boundaries.oa <- st_join(oa.uk, city.boundaries, join = st_intersects) %>% 
  as_tibble() %>% 
  filter(!is.na(name)) %>% 
  dplyr::select(id, name) %>% 
  mutate(name = ifelse(name == "City of Edinburgh", "Edinburgh", name)) %>% 
  mutate(name = ifelse(name == "Glasgow City", "Glasgow", name))

city.boundaries.help <- df %>% inner_join(city.boundaries.oa, by = c("oa11cd" = "id")) %>% 
  group_by(name, year) %>% 
  summarise(n.nearest.city = sum(n)) %>% 
  mutate(n.nearest.city.lag = dplyr::lag(n.nearest.city)) %>% 
  ungroup()

london.boundaries.help <- city.boundaries.help %>% 
  filter(name == "London") %>% 
  rename(n.London = n.nearest.city,
         n.London.lag = n.nearest.city.lag)

df <- df %>% left_join(city.boundaries.help, by = c("dist.city.name" = "name", "year" = "year"))

df <- df %>% left_join(london.boundaries.help, by = c("year" = "year"))

#sapply(df, function(x) sum(is.na(x)))

#' 
#' ### DELETE n for London 
#' 
## ----eval=FALSE------------------------------------------------------------
## 
## # # OLD London definitions
## # # df <- df %>% left_join(df %>%
## # #                          ungroup() %>%
## # #                          filter(oa11cd == "E00176659") %>%
## # #                          dplyr::select(year, n) %>%
## # #                          rename(n.London = n)) %>%
## # #   group_by(oa11cd) %>%
## # #   mutate(n.London.lag = dplyr::lag(n.London)) %>%
## # #   mutate(n.nearest.city.lag = dplyr::lag(n.nearest.city)) %>%
## # #   ungroup()
## # #
## # # london.help <- df %>% group_by(RGN11NM, year) %>%
## # #   summarise(n.London = sum(n)) %>%
## # #   filter(RGN11NM == "London") %>%
## # #   mutate(n.London.lag = dplyr::lag(n.London)) %>%
## # #   ungroup() %>%
## # #   dplyr::select(-RGN11NM)
## #
## # london.oa <- st_filter(oa.gb, london.sf %>%
## #                          filter(Name == "Central")) %>%
## #   as_tibble() %>%
## #   dplyr::select(id)
## #
## # london.help <- df %>% inner_join(london.oa, by = c("oa11cd" = "id")) %>%
## #   group_by(year) %>%
## #   summarise(n.London = sum(n)) %>%
## #   mutate(n.London.lag = dplyr::lag(n.London)) %>%
## #   ungroup()
## #
## # df <- df %>% left_join(london.help, by = c("year" = "year"))

#' 
#' ### n for nearest retail
#' 
## --------------------------------------------------------------------------
# Old definition for retail centre
# df <- df %>% left_join(df %>% dplyr::select(oa11cd,year, n) %>% 
#                          rename(n.nearest.retail = n), 
#                        by = c("oa11cd.retail" = "oa11cd",
#                               "year" = "year")) %>% 
#   mutate(n.nearest.retail.lag = dplyr::lag(n.nearest.retail))
# 
# 
# #n.nearest.retail IS WRONG. FIX UPSTREAM
# df <- df %>% 
#   rename(oa11cd.retail = n.nearest.retail) %>% 
#   dplyr::select(-n.nearest.retail.lag) %>% 
#   left_join(df %>% dplyr::select(oa11cd,year, n) %>% 
#                          rename(n.nearest.retail = n), 
#                        by = c("oa11cd.retail" = "oa11cd",
#                               "year" = "year")) %>% 
#   mutate(n.nearest.retail.lag = dplyr::lag(n.nearest.retail))
# 
# 
# df <- df %>% dplyr::select(-n.London, -n.London.lag) %>% 
#   left_join(london.help, by = c('year' = 'year'))


retail.oa <- st_join(oa.uk, retail, 
                     join = st_intersects) %>% #, 
                    #largest = TRUE) %>% # returns the x features augmented with 
                                         # the fields of y that have the largest 
                                         # overlap with each of the features of x
  as_tibble() %>% 
  filter(!is.na(RC_ID)) %>% 
  dplyr::select(id, RC_ID) %>% 
  add_row(id = "E00019779", RC_ID = "RC_EW_5951")

# If `larget = FALSE`, we have multiple RC_IDs for OAs.
# Also, RC_ID="RC_EW_5951" would fall in Thames as it is the London Bridge Tube Station.
# To avoid NAs for for n.nearest.retail, I would have assigned dist.retail.name = RC_EW_1935 for E00019779 

# st_join(oa.uk, retail, join = st_is_within_distance, dist = 500) %>% 
#   as_tibble() %>% 
#   filter(!is.na(RC_ID)) %>% 
#   dplyr::select(id, RC_ID)
# 
# st_filter(oa.uk, retail,  .pred = st_is_within_distance, dist = 100) %>% 
#   as_tibble() %>% 
#   filter(!is.na(RC_ID)) %>% 
#   dplyr::select(id, RC_ID)

# h <- oa.uk %>% st_intersects(retail)

# retail.oa_ %>% filter(id == "E00004828"|id == "E00004829"|id == "E00004827")
# # RC_EW_5285
# retail.oa <- retail.oa %>% add_row(id = "E00004828", RC_ID = "RC_EW_5285")
# retail.oa <- retail.oa %>% arrange(id)

retail.help <- df %>% full_join(retail.oa, by = c("oa11cd" = "id")) %>% 
  group_by(RC_ID, year) %>% 
  summarise(n.nearest.retail = sum(n)) %>% 
  mutate(n.nearest.retail.lag = dplyr::lag(n.nearest.retail)) %>% 
  ungroup()

# retail.help2 <- retail.oa %>% left_join(retail.help, by = c("RC_ID" = "RC_ID")) %>% 
#   dplyr::select(-RC_ID)

df <- df %>% left_join(retail.help, by = c("dist.retail.name" = "RC_ID", "year" = "year"))
#sapply(df, function(x) sum(is.na(x)))

#' 
#' ### Urban Rural TODO
#' 
#' ## TODO
#' 
## --------------------------------------------------------------------------
# Lookup: OA to regions
# **FIXED< DELETE IN TEST** NEED TO ADD NI. NOT A PROBLEM FOR NOW AS IT IS FIXED IN THE TEST SECTION
  
# # regional identifier
# df_ <- df %>% mutate(help = substr(oa11cd, start = 1, stop = 2)) %>% 
#   mutate(RGN11CD = ifelse(is.na(RGN11CD), help, RGN11CD)) %>% 
#   ungroup() %>% 
#   dplyr::select(-help)

#sapply(df, function(x) sum(is.na(x)))

#' 
#' ## Spatial and spatio-temporal lags
#' 
## --------------------------------------------------------------------------
# sf_use_s2(FALSE)
# oa.c <- st_centroid(oa.uk)
# kn <- knearneigh(oa.c, k = 5)
# knn <- knn2nb(kn, row.names = NULL, sym = FALSE)
# knn.l <- nb2listw(knn)

path.out <- paste0(path, "/data/temp/knnl.RData")
# save(knn.l, file = path.out)
load(path.out)

df <- df %>% 
  group_by(year) %>% 
  mutate(n.slag = lag.listw(knn.l, n)) %>% 
  group_by(oa11cd) %>% 
  mutate(n.l.slag = dplyr::lag(n.slag, n=1, order_by=year),
         n.lag = dplyr::lag(n, n=1, order_by = year))        # duplicate line

#' 
#' ## RF with CAST
#' 
## --------------------------------------------------------------------------

# Lookup: OA to regions
path.lookup <- paste0(path, "/data/raw/Output_Area_to_Region_(December_2011)_Lookup_in_England.csv")  
lookup.region <- read_csv(path.lookup) %>% dplyr::select(OA11CD, RGN11CD, RGN11NM)

df <- df %>% left_join(lookup.region, by = c("oa11cd" = "OA11CD")) %>% 
  relocate(c(RGN11NM, RGN11CD), .after=year) %>% 
  mutate(help = substring(oa11cd, 1, 1),
         RGN11CD = ifelse(help=="E", RGN11CD,
                         ifelse(help=="W", "Wales",
                                ifelse(help == "S", "Scotland", "NI"))),
         RGN11NM = ifelse(help=="E", RGN11NM,
                         ifelse(help=="W", "Wales",
                                ifelse(help == "S", "Scotland", "NI")))) %>% 
  dplyr::select(-help)

# # North/South
# #lookup.region %>% distinct(RGN21NM, .keep_all = T)
# south <- c("London", "South West", "South West", "East of England")
# df <- df %>% mutate(south = ifelse(RGN11NM %in% south, 1, 0))

# For growth:
df <- df %>% group_by(oa11cd) %>% 
  mutate(#n.lag = dplyr::lag(n),
         growth = log(n/n.lag),
                    abs.growth = n - n.lag) %>% 
  relocate(n.lag, .after = n) %>% 
  ungroup()

# out.path <- paste0(path, "/data/temp/df_for_oa_rf.csv")
# df <- read_csv(out.path)
# df %>% write_csv(file = out.path)

# rm(list=setdiff(ls(), "df"))

# # This is the project path
# path <- find_rstudio_root_file()

# remove not used columns
df <- df %>% dplyr::select(-c("Birmingham", "Glasgow", "Liverpool", "Bristol",
                        "Manchester", "Sheffield", "Leeds", "Edinburgh",
                        "Leicester", "dist.city.name", "dist.retail.name", "name")) 

# There are no lags for 1996, so it is removed
df <- df %>% filter(year > 1996) %>% 
  dplyr::select(oa11cd, year, RGN11CD, n, abs.growth, n.l.slag, n.nearest.city.lag, 
                n.nearest.retail.lag, n.London.lag, London, dist, dist.retail) #%>% #growth, abs.growth, RGN11NM, 
  # mutate(London.v = n.London.lag / London,
  #        city.v = n.nearest.city.lag / dist,
  #        retail.v = n.nearest.retail.lag / (dist.retail + .1)) %>% 
  # dplyr::select(-n.London.lag, -London, -n.nearest.city.lag, -dist, -n.nearest.retail.lag, -dist.retail)

df %>% group_by(year) %>% 
  filter(n == 0) %>% 
  count(n)
# in 2012, 120848 0s  

# df %>% dplyr::select(area, dist, dist.retail, London, south, n.slag, n.lag, n.l.slag, n.nearest.city, year) %>% 
#   #sapply(function(x) sum(is.na(x)))
#   summarise(across(where(is.numeric), .fns = 
#                      list(#n = is.na,
#                           min = min,
#                           median = median,
#                           mean = mean,
#                           stdev = sd,
#                           # q25 = ~quantile(., 0.25),
#                           # q75 = ~quantile(., 0.75),
#                           max = max))) %>%
#   pivot_longer(everything(), names_sep='_', names_to=c('variable', '.value'))
# 
# df %>% dplyr::select(n, n.London.lag, n.nearest.city.lag, n.nearest.retail.lag, n.l.slag, year, London, dist, dist.retail) %>%
#   #sapply(function(x) sum(is.na(x)))
#   summarise(across(where(is.numeric), .fns =
#                      list(#n = is.na,
#                           min = min,
#                           median = median,
#                           mean = mean,
#                           stdev = sd,
#                           # q25 = ~quantile(., 0.25),
#                           # q75 = ~quantile(., 0.75),
#                           max = max))) %>%
#   pivot_longer(everything(), names_sep='_', names_to=c('variable', '.value'))
# 
# df %>% slice_max(order_by = n, n = 5, by = year)

#' 
#' ### unregister_dopar function
#' 
#' This is helpful when the parallel loop collapses. 
#' 
## --------------------------------------------------------------------------
unregister_dopar <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
unregister_dopar()

#' 
#' ### train the model in all data 
#' 
## --------------------------------------------------------------------------
set.seed(123)
indices <- CreateSpacetimeFolds(df, 
                                spacevar = "RGN11CD",
                                timevar = "year", 
                                k = 10)

#length is = (n_repeats*nresampling)+1
seeds <- vector(mode = "list", length = 11)

#(8 is the number of tuning parameter, mtry for rf, here equal to ncol(iris)-2)
for(i in 1:10) seeds[[i]]<- sample.int(n=1000, 8) # It should be RHS variables + 2

#for the last model
seeds[[11]]<-sample.int(1000, 1)

# CV
tc <- trainControl(method = "cv",
                   number = 10,
                   seeds = seeds,
                   allowParallel = T,
                   index = indices$index,
                   savePredictions = 'final')

# detectCores()
# cl <- makePSOCKcluster(2)
# registerDoParallel(cl)

start.time <- Sys.time()
model.all <- train(n ~ #area + dist + dist.retail + London + south + n.slag + n.lag + n.l.slag + n.nearest.city + year,
                     n.London.lag + n.nearest.city.lag + n.nearest.retail.lag + n.l.slag + year + London + dist + dist.retail,
                     #London.v + city.v + retail.v + n.l.slag + year,
                   data = df, 
                   trControl = tc,
                   method = "ranger",
                   na.action = na.omit,
                   #preProc = c("center", "scale"),
                   importance = "impurity",
                   num.threads = 15)

# stopCluster(cl)
end.time <- Sys.time()
time.taken <- round(end.time - start.time,2)
time.taken #20.6h

print(model.all)

# Random Forest 
# 
# 3716736 samples
#       8 predictor
# 
# No pre-processing
# Resampling: Cross-Validated (10 fold) 
# Summary of sample sizes: 2926910, 2926924, 3136005, 2926924, 3136005, 2926924, ... 
# Resampling results across tuning parameters:
# 
#   mtry  splitrule   RMSE      Rsquared   MAE     
#   2     variance    4.999920  0.2053697  1.047293
#   2     extratrees  5.167655  0.1540213  1.103048
#   5     variance    5.187039  0.1710128  1.034382
#   5     extratrees  5.169570  0.1557868  1.122845
#   8     variance    5.633427  0.1247189  1.035171
#   8     extratrees  5.182860  0.1563555  1.137332
# 
# Tuning parameter 'min.node.size' was held constant at a value of 5
# RMSE was used to select the optimal model using the smallest value.
# The final values used for the model were mtry = 2, splitrule =
#  variance and min.node.size = 5.

varimp_mars <- varImp(model.all) 
varimp_mars$importance <- varimp_mars$importance %>% 
  rownames_to_column() %>% 
  mutate(rowname = ifelse(rowname == "dist", "distance to the nearest city",
                          ifelse(rowname == "dist.retail", "distance to the nearest retail centre", 
                                 ifelse(rowname == "London", "distance to London",
                                        ifelse(rowname == "n.nearest.retail.lag", "Nearest retail centre's wensite density, t-1",
                                               ifelse(rowname == "n.London.lag", "London's wensite density, t-1",
                                                      ifelse(rowname == "n.l.slag", "spatial and temporal lag of wensite density",
                                                             ifelse(rowname == "n.nearest.city.lag", "Nearest city's wensite density, t-1", rowname)))))))) %>% 
  column_to_rownames()

path.out <- paste0(path, "/outputs/rf/figures/varimp_OA.png")
ggplot(varimp_mars) + theme_minimal() + labs(x="") #+ theme(panel.background = element_rect(fill = "white"))
ggsave(path.out)

path.out <- paste0(path, "/outputs/rf/models/oa_rf/all_OAs/all_OAs.RData")
save(model.all, file = path.out)