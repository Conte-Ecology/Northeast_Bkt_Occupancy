
#library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(RPostgreSQL)
library(ggplot2)

#----------------------- load data not in database--------------------

# Until trout data in db load from csv
#df_pa <- read.csv("Data/OccupancyHRD.csv", header = T)
df_pa <- read.csv("Data/regional_occupancy_data.csv", header = T, stringsAsFactors = FALSE)
df_pa <- df_pa %>%
  dplyr::mutate(Occupancy = ifelse(catch > 0, 1, catch)) %>%
  dplyr::select(featureid, Occupancy)


# until derived metrics in db, load from csv
df_temp <- read.table("Data/derived_site_metrics.csv", header = T, sep = ",")

# filter occupancy data to sites with observations
df_pa <- df_pa %>%
  dplyr::filter(!is.na(Occupancy))

# get unique featureid with obvserved trout data for db queries
featureids <- unique(df_pa$featureid)

#------------------------Pull covariate data from database--------------

# load profile locally to play with packrat
source("~/.Rprofile")

# connect to database source
db <- src_postgres(dbname='sheds_new', host='osensei.cns.umass.edu', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))

# fetch covariates
# featureid |  variable  | value | zone  | riparian_distance_ft 
#cov_fetch <- c("agriculture", "alloffnet", "allonnet", "AreaSqKM", "devel_hi", "devel_low", "devel_med", "developed", "devel_opn", "drainageclass", "elevation", "forest", "fwsopenwater", "fwswetlands", "herbaceous", "hydrogroup_a", "hydrogroup_ab", "hydrogroup_cd", "hydrogroup_d1", "hydrogroup_d4", "impervious", "openoffnet", "openonnet", "percent_sandy", "slope_pcnt", "surfcoarse", "tree_canopy", "undev_forest", "water", "wetland")

start.time <- Sys.time()
tbl_covariates <- tbl(db, 'covariates') %>%
  dplyr::filter(featureid %in% featureids) # & variable %in% cov_fetch)

df_covariates_long <- dplyr::collect(tbl_covariates)

Sys.time() - start.time

df_covariates <- df_covariates_long %>%
  tidyr::spread(variable, value) # convert from long to wide by variable
summary(df_covariates)

# need to organize covariates into upstream or local by featureid
upstream <- df_covariates %>%
  dplyr::group_by(featureid) %>%
  dplyr::filter(zone == "upstream",
                is.na(riparian_distance_ft)) %>%
  # dplyr::select(-zone, -location_id, -location_name) %>%
  # dplyr::summarise_each(funs(mean)) %>% # needed???
  dplyr::rename(forest_all = forest)

# Get upstream riparian forest
riparian_200 <- df_covariates %>%
  dplyr::group_by(featureid) %>%
  dplyr::select(featureid, forest, zone, riparian_distance_ft) %>%
  dplyr::filter(zone == "upstream",
                riparian_distance_ft == 200)

# create covariateData input dataset
covariateData <- riparian_200 %>%
  dplyr::select(-riparian_distance_ft) %>%
  dplyr::left_join(upstream)

# get average annual precip from monthly
covariateData <- covariateData %>%
  dplyr::group_by(featureid) %>%
  dplyr::mutate(ann_prcp = jan_prcp_mm +
                  feb_prcp_mm +
                  mar_prcp_mm +
                  apr_prcp_mm +
                  may_prcp_mm +
                  jun_prcp_mm +
                  jul_prcp_mm +
                  aug_prcp_mm +
                  sep_prcp_mm +
                  oct_prcp_mm +
                  nov_prcp_mm +
                  dec_prcp_mm,
                winter_prcp_mm = jan_prcp_mm +
                  feb_prcp_mm +
                  mar_prcp_mm,
                spring_prcp_mm = apr_prcp_mm +
                  may_prcp_mm +
                  jun_prcp_mm,
                summer_prcp_mm = jul_prcp_mm +
                  aug_prcp_mm +
                  sep_prcp_mm,
                fall_prcp_mm = oct_prcp_mm +
                  nov_prcp_mm +
                  dec_prcp_mm)


#-------------------------Get HUC8 & add to covariate df---------------
# pass the db$con from dplyr as the connection to RPostgreSQL::dbSendQuery
# drv <- dbDriver("PostgreSQL")
# # con <- dbConnect(drv, dbname="conte_dev", host="127.0.0.1", user="conte", password="conte")
# con <- dbConnect(drv, dbname='sheds_', host='ecosheds.org', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))
# rs <- dbSendQuery(con, "SELECT c.featureid as featureid, w.huc8 as huc8
# FROM catchments c
# JOIN wbdhu8 w
# ON ST_Contains(w.geom, ST_Centroid(c.geom));")
# 
# # fetch results
# featureid_huc8 <- fetch(rs, n=-1)

# connect to database source
#db <- src_postgres(dbname='sheds_new', host='osensei.cns.umass.edu', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))

tbl_huc12 <- tbl(db, 'catchment_huc12') %>%
  dplyr::filter(featureid %in% featureids) %>%
  dplyr::mutate(huc4=substr(huc12, as.integer(1), as.integer(4)),
                huc8=substr(huc12, as.integer(1), as.integer(8)),
                huc10=substr(huc12, as.integer(1), as.integer(10)))

featureid_huc8 <- tbl_huc12 %>%
  dplyr::collect()


df_covariates <- dplyr::left_join(covariateData, featureid_huc8, by = c("featureid"))

#-------------------------Query daymet data-----------------------------

# Get precip data
# tbl_daymet_annual <- tbl(db, 'daymet') %>%
#   dplyr::filter(featureid %in% featureids) %>%
#   dplyr::mutate(year = date_part('year', date)) %>%
#   dplyr::group_by(featureid, year) %>%
#   dplyr::select(featureid, year, prcp) %>%
#   dplyr::summarise_each(funs(mean))
# 
# tbl_daymet_monthly <- tbl(db, 'daymet') %>%
#   dplyr::filter(featureid %in% featureids) %>%
#   dplyr::mutate(year = date_part('year', date)) %>%
#   dplyr::mutate(month = date_part('month', date)) %>%
#   dplyr::group_by(featureid, year, month) %>%
#   dplyr::select(featureid, year, month, prcp) %>%
#   dplyr::summarise_each(funs(mean))
# 
# featureids.test <- sample(featureids, size = 10, replace = F)

featureids_string <- paste(featureids, collapse=', ')

qry <- paste0("COPY(SELECT featureid, AVG(prcp) FROM daymet WHERE featureid IN (", featureids_string, ") GROUP BY featureid) TO STDOUT CSV HEADER;")  # "select * from whatever where featureid in (80001, 80002, 80003)"

cat(qry, file = "Code/daymet_query.sql")

# i = 1
# chunk_size = 100
# n.loops <- ceiling(length(featureids) / chunk_size)
# 
# #while(i <= length(featureids)) {
# #for(i in 1:n.loops) { 
#   featureid_subset <- featureids[i:(i*chunk_size)]
#   featureids_string <- paste(featureid_subset, collapse=', ')
#   
# 
# j <- j + 1;
# boom <- 0
# repeat {
#   fetch_batch <- try( expr = fetch(res=result, n=batch_size) )
#   if (class(fetch_batch) != 'try-error') {
#     break;
#   } else {
#     result <- dbSendQuery(link$conn, stmt)
#     if (j > 1) {
#       dump <- fetch(res=result, n=(j-1)*batch_size)
#     }
#   }
#   if (boom > 10) stop("Big Boom.")
#   boom <- boom + 1
# }
#   drv <- dbDriver("PostgreSQL")
#   # con <- dbConnect(drv, dbname="conte_dev", host="127.0.0.1", user="conte", password="conte")
#   con <- dbConnect(drv, dbname='conte_dev', host='ecosheds.org', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))
#   
#   qry <- paste0("SELECT featureid, AVG(prcp) FROM daymet WHERE featureid IN (", featureids_string, ") GROUP BY featureid;")
#   
#   res <- dbSendQuery(con, qry)
#   # fetch results
#   out <- fetch(res, n=-1)
#   
#   if(exists("df_precip") == FALSE) {
#     df_precip <- out
#   } else {
#     df_precip <- rbind(df_precip, out)
#   }
#   
#   print(paste0(i, " of ", n.loops, " loops"))
#   write.table(df_precip, file = 'Data/daymet_precip_loop.csv', sep = ',', row.names = F)
#   
#   #i = i*chunk.size + 1
#   dbDisconnect(con)
# }
# 
# write.table(df_precip, file = "Data/daymet_precip.csv", sep = ",", row.names = F)





# Currently run sql manually via command line on Felek - later create a make file to run this R script and the sql query

# Then import results
#df_precip <- read.csv("Data/")

saveRDS(df_covariates, file = "Data/covariates.RData")

