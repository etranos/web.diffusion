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
## ----setup, include=FALSE-----------------------------------------------------
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
library(Hmisc)

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
## -----------------------------------------------------------------------------
path.lookup <- paste0(path,"/data/raw/PCD_OA_LSOA_MSOA_LAD_AUG21_UK_LU.csv")
lookup <- read_csv(path.lookup) %>% 
  dplyr::select(pcds, oa11cd, lsoa11cd, msoa11cd, ladcd, ladnm) %>% 
  dplyr::rename(pc = pcds)
#glimpse(lookup)
# The problems refer to Welsh LAD names. Not a problem for the analysis.
#sapply(lookup, function(x) sum(is.na(x)))
# 10332 missing msoa11cd

#' 
#' The internet archive $1996$-$2010$ data is saved on /hdd.
#' The internet archive $2011$-$2012$ data is saved on ~/projects/web.diffusion/data/temp.
#' 
#' ## Problem postcodes
#' 
#' I use the problem postcodes from n = 1 as these are the true outliers as per the
#' line plots.
#' 
## -----------------------------------------------------------------------------
n = 1 #number of unique postcodes. 
m = 11

data.folder <- "/hdd/internet_archive/archive/data/"
data.path9610 <- paste0(data.folder, "domain_pc_year.csv")
#Created by domain.R, which uses domain instead of host.
#This is what we use for the hyperlinks paper as per George's script

df9610 <- read_csv(data.path9610) %>% 
  filter(
      V1.domain < m,               # for multiple pc
      #V1.domain == n,             # for n == 1
      year > 1995)   

data.path2011_2012 <- paste0(path, "/data/temp/domain_pc_year1112.csv")
#Created by domain1112.Rmd, which is based on domain.R and uses domain instead of host.
#This is what we use for the hyperlinks paper as per George's script

df1112 <- read_csv(data.path2011_2012) %>% 
  filter(
    V1.domain < m)               # for multiple pc
    #V1.domain == n)             # for n == 1

df.long <- bind_rows(df9610, df1112) %>% 
  filter(year > 1995 & year < 2013) %>% 
  group_by(pc, year) %>% 
  summarise(n = sum(V1.domain)) %>%
  ungroup() %>% 
  #arrange(desc(n)) %>% 
  pivot_wider(names_from = year, values_from = n, names_prefix = "n_") %>% 
  dplyr::select(pc, n_1996, n_1999, n_2000, n_2001, n_2002, n_2003, n_2004, n_2005, n_2006, n_2007, n_2008, n_2009, n_2010, n_2011, n_2012) %>%
  arrange(desc(n_2004), desc(n_2005)) %>% 
  slice_head(n=1000) %>% 
  pivot_longer(!pc, names_to = "year", values_to = "n") %>% 
  mutate(year = as.integer(sub("n_", "", year, fixed = TRUE))) %>% 
  replace(is.na(.), 0) %>% 
  mutate(outlier = ifelse(n > 1000 & (year==2004 | year == 2005), pc, ""))

# From n = 1 as these are the 'true' outliers
problem.pcs <- c("SE24 9HP", "CV8 2ED", "GL16 7YA", "CW1 6GL", "M28 2SL", "DE21 7BF")

#' 
#' ## Corrected
#' 
#' The above exploratory analysis indicated that there is a huge increase in 2004-2006
#' in the above postcodes. I turn them to NAs and then use a regression to impute these
#' gaps.
#' 
## -----------------------------------------------------------------------------
df.corrected <- bind_rows(df9610, df1112) %>% 
  filter(year > 1995 & year < 2013) %>% 
  group_by(pc, year) %>% 
  summarise(n = sum(V1.domain)) %>% 
  ungroup() %>% 
  # The next line is different than the same for  n = 1: problem.pcs$pc
  mutate(n = ifelse(pc %in% as.character(problem.pcs) & year > 2001 & year <2007, NA, n))

df.corrected <- pdata.frame(df.corrected)
predictions <- round(predict(plm(n ~ as.factor(year), effect = "individual", 
                                 model = "within", data = df.corrected), newdata = df.corrected), 2)

df.corrected$n[is.na(df.corrected$n)] <- predictions[is.na(df.corrected$n)]

#' 
#' ## OA df
#' 
## -----------------------------------------------------------------------------
df <- df.corrected %>% 
  mutate(year = as.integer(as.character(year))) %>% 
  filter(year > 1995 & year < 2013) %>% 
  left_join(lookup, by = "pc", suffix =c("","")) %>% 
  group_by(year, oa11cd) %>%
  summarise(n = sum(n)) %>% # for multiple pc  
  ungroup() %>% 
  complete(oa11cd, year) %>% 
  filter(!is.na(oa11cd)) %>% # drop c. 10 - 200 per year, which are not assigned to a LAD
  replace(is.na(.), 0) 

#' 
#' ## spatial data
#' 
## -----------------------------------------------------------------------------
# get OA for England and Wales
path.geo <- paste0(path, "/data/raw/Output_Areas__December_2011__Boundaries_EW_BGC.geojson")
oa.ew <- st_read(path.geo)
# source: https://geoportal.statistics.gov.uk/

# spatial transformations
oa.ew <- st_transform(oa.ew, 4326)  # EPSG code for WGS84

# keep in the data slot only the ONS Output Area id, renaming it as 'id'
oa.ew <- oa.ew %>% 
  dplyr::select(OA11CD, Shape__Area) %>% 
  rename(id = OA11CD,
         area = Shape__Area)

path.geo.sc <- paste0(path, "/data/raw/output-area-2011-mhw")
oa.sc <- st_read(dsn=path.geo.sc, layer = "OutputArea2011_MHW")
# source: https://www.nrscotland.gov.uk/statistics-and-data/geography/our-products/census-datasets/2011-census/2011-boundaries

# spatial transformations
oa.sc <- st_transform(oa.sc, 4326)  # EPSG code for WGS84

# Scotland (follows same steps as EW, see notes above)
oa.sc <- oa.sc %>% 
  dplyr::select(code, SHAPE_1_Ar) %>% 
  rename(id = code,
         area = SHAPE_1_Ar)

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

# get UK
path.uk <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Countries_December_2023_Boundaries_UK_BUC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
uk <- st_read(path.uk)
# spatial transformations
uk <- st_transform(uk, 4326)  # EPSG code for WGS84

#' 
#' ## Full panel
#' 
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------

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
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------
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
#' ### n for cities
#' 
## -----------------------------------------------------------------------------
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
#' ### n for nearest retail
#' 
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------
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
## -----------------------------------------------------------------------------

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
## -----------------------------------------------------------------------------
unregister_dopar <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}
unregister_dopar()


#' 
#' ### train the model in a loop for all but one regions
#' 
## -----------------------------------------------------------------------------
rm(list=setdiff(ls(), c("df", "path")))

#' 
#' 64 GB of swap memory to run the below
#' 
## -----------------------------------------------------------------------------

#folds
k <- 10 # 

#length is = (n_repeats*nresampling)+1
seeds <- vector(mode = "list", length = 11)

#(8 is the number of tuning parameter, mtry for rf, here equal to ncol(iris)-2)
for(i in 1:10) seeds[[i]]<- sample.int(n=1000, 8) # It should be RHS variables + 2

#for the last model
seeds[[11]]<-sample.int(1000, 1)

# detectCores()
# cl <- makePSOCKcluster(2)
# registerDoParallel(cl)

# train in every region
start.time <- Sys.time()

regions <- df %>% ungroup() %>% distinct(RGN11CD) 
regions <- as.vector(regions$RGN11CD)

for (i in regions){
  
  print(paste0("start loop for ", i))
  
  set.seed(71)
  indices <- CreateSpacetimeFolds(df %>% filter(RGN11CD!=i), 
                                spacevar = "RGN11CD",
                                timevar = "year", 
                                k = k)
  
  # CV
  tc <- trainControl(method = "cv",
                   number = k,
                   seeds = seeds,
                   allowParallel = T,
                   index = indices$index,
                   savePredictions = 'final')


  model.all <- train(n ~ n.London.lag + n.nearest.city.lag + n.nearest.retail.lag + n.l.slag + year + London + dist + dist.retail,
                   data = df %>% filter(RGN11CD!=i), 
                   trControl = tc,
                   method = "ranger",
                   na.action = na.omit,
                   #preProc = c("center", "scale"),
                   importance = "impurity",
                   num.threads = 15)
  
  file <- paste0("/hdd/tmp/regions/corrected_10/regions_corrected_10", as.character(i), ".RData")  
  save(model.all, file = file)  # file name = region not in the training data
  rm(model.all)
  
  print(paste0("end loop for ", i))
  
}

# stopCluster(cl)
end.time <- Sys.time()
time.taken <- round(end.time - start.time,2)
time.taken

#' 
#' ### Test on one region
#' 
#' THE RESULTS ARE WEIRD. REVISIT. 
#' 
#' The corrected for n = 1 makes sense. Check the name changes below.
#' 
## ----include=TRUE, results= 'markup', message=FALSE, fig.height=15, fig.width=10----

# for a reference point
df %>% group_by(year) %>%
  summarise(min = min(n), max=max(n),
            mean = mean(n), median = median(n)) %>%
  round(2) %>% kable()

#' 
## -----------------------------------------------------------------------------
# train on all but one region, test on that region

regions <- df %>% ungroup() %>% distinct(RGN11CD) 
regions <- as.vector(regions$RGN11CD)

new.path <- "/hdd/tmp/regions/corrected_10/"
#filenames <- list.files(paste0(path, "/outputs/rf/models/oa_rf/regions"), pattern = "*.RData", full.names = T)

df.predictions <- data.frame()

for (i in regions){
  
  print(i)

  load(file = paste0(new.path, "regions_corrected_10", as.character(i), ".RData"))
  #model.name <- gsub("/home/nw19521/projects/web.diffusion/outputs/rf/models/oa_rf/regions/|.RData", "", i)
  #assign(as.character(i), model.all)  
  
  pred <- predict(model.all, df[df$RGN11CD==i,])
  pred <- as.data.frame(pred)
  
  rownames(pred) <- c()
  assign(paste0("region.predict.model.", ".on.", i), pred)
    
  d <- paste0("region.predict.model.", ".on.", i)
  d <- cbind(get(d), df %>% filter(RGN11CD==i)) #%>% arrange(year, ladcd)
    
  d <- d %>% dplyr::select(RGN11CD, oa11cd, year, n, pred)
    
  colnames(d)[5] <- "predictions"
  d <- d %>% mutate(tested.on = i)
  df.predictions <- rbind(d, df.predictions)
  
  rm(model.all)
  
  print(i)
  
}


# df.predictions <- data.frame()
# for (i in regions){
#   #for (j in regions[!regions == i]){
#     pred <- predict(fit.model.all[names(fit.model.all)==paste0("region_", i)], 
#                     df[df$RGN11CD==i,])
#     pred <- as.data.frame(pred)
#     rownames(pred) <- c()
#     assign(paste0("region.predict.model.", ".on.", i), pred)
#     
#     d <- paste0("region.predict.model.", ".on.", i)
#     d <- cbind(get(d), df %>% filter(RGN11CD==i)) #%>% arrange(year, ladcd)
#     
#     #***dplyr::select(RGN21CD, ladcd, year, growth, 1)***
#     
#     d <- d[,c(5, 2, 4, 6, 1)]     
#     colnames(d)[5] <- "predictions"
#     d <- d %>% mutate(trained.on = i)
#     df.predictions <- rbind(d, df.predictions)
#   #}
# }

df.predictions <- df.predictions %>% mutate(test.train = paste0(RGN11CD, ".", tested.on))

# split to list by region pair
pred.by.region.all.list <- split(df.predictions, df.predictions$test.train) 

# calculate metrics for every region pair 
rf.year.all.metrics <- lapply(pred.by.region.all.list, function(x) postResample(pred = x$predictions,
                                                                     obs = x$n))  # CHANGE n WITH growth

path.lookup <- paste0(path, "/data/raw/Local_Authority_District_to_Region_(April_2021)_Lookup_in_England.csv")  
lookup.region <- read_csv(path.lookup) %>% 
  dplyr::select(RGN21CD, RGN21NM) %>% 
  distinct() %>% 
  rename(RGN11CD = RGN21CD) %>% 
  add_row(RGN11CD = c("Scotland", "NI", "Wales"),
          RGN21NM = c("Scotland", "Nortern Ireland", "Wales"))

path.out <- paste0(path, "/outputs/rf/figures/test_regions_OA_corrected_10.csv")
rf.year.all.metrics %>% 
  as.data.frame() %>%
  rownames_to_column(var = "metrics") %>% 
  pivot_longer(!metrics, names_to = "train.test") %>% 
  pivot_wider(names_from = metrics, values_from = value) %>% 
  separate(train.test, c("train", "test"), remove = F) %>% 
  # left_join(lookup.region, by = c("train" = "RGN11CD")) %>% 
  # rename(train.region=RGN21NM) %>% 
  left_join(lookup.region, by = c("test" = "RGN11CD")) %>% 
  rename(test.region=RGN21NM) %>% 
  arrange(Rsquared) %>% 
  dplyr::select(test.region, Rsquared) %>% 
  write_csv(path.out)
