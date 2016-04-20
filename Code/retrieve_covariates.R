
#library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(RPostgreSQL)
library(ggplot2)

#----------------------- load data not in database--------------------

# Until trout data in db load from csv
df_pa <- read.csv("Data/OccupancyHRD.csv", header = T)

# until derived metrics in db, load from csv
df_temp <- read.table("Data/derived_site_metrics.csv", header = T, sep = ",")

# filter occupancy data to sites with observations
df_pa <- df_pa %>%
  dplyr::filter(!is.na(Occupancy)) %>%
  dplyr::rename(featureid = FEATUREID)

# get unique featureid with obvserved trout data for db queries
featureids <- unique(df_pa$featureid)

saveRDS(featureids, "Data/survey_featureid.RData")

#------------------------Pull covariate data from database--------------

# load profile locally to play with packrat
source("~/.Rprofile")

# set connection to database
db <- src_postgres(dbname='conte_dev', host='ecosheds.org', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))

# table connection
tbl_covariates <- tbl(db, 'covariates') %>%
  dplyr::group_by(featureid) %>%
  dplyr::filter(featureid %in% featureids & zone == "upstream")

# collect the query and organize
df_covariates <- dplyr::collect(tbl_covariates) 
df_covariates <- as.data.frame(unclass(ungroup(df_covariates))) %>%
  tidyr::spread(key = variable, value = value)
summary(df_covariates)

#-------------------------Get HUC8 & add to covariate df---------------
# pass the db$con from dplyr as the connection to RPostgreSQL::dbSendQuery
drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname="conte_dev", host="127.0.0.1", user="conte", password="conte")
con <- dbConnect(drv, dbname='conte_dev', host='ecosheds.org', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))

rs <- dbSendQuery(con, "SELECT c.featureid as featureid, w.huc8 as huc8
FROM catchments c
JOIN wbdhu8 w
ON ST_Contains(w.geom, ST_Centroid(c.geom));")

# fetch results
featureid_huc8 <- fetch(rs, n=-1)

rs <- dbSendQuery(con, "SELECT c.featureid as featureid, w.huc10 as huc10
FROM catchments c
JOIN wbdhu10 w
ON ST_Contains(w.geom, ST_Centroid(c.geom));")

# fetch results
featureid_huc10 <- fetch(rs, n=-1)

df_covariates <- dplyr::left_join(df_covariates, featureid_huc8, by = c("featureid")) %>%
  dplyr::left_join(featureid_huc10, by = c("featureid"))


saveRDS(df_covariates, file = "Data/covariates.RData")

