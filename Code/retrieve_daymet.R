#library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(RPostgreSQL)
library(ggplot2)
# load profile locally to play with packrat
source("~/.Rprofile")

featureids <- readRDS("Data/survey_featureid.RData")

# Currently run sql manually via command line on Felek - later create a make file to run this R script and the sql query

batch_rbind <- function(x) {
	if (length(x) < 1000) {
		o <- do.call(what=rbind, args=x)
		return(o)
	} else {
		x <- split(x=x, f=factor(gl(n=length(x), k=1000, length=length(x))), drop=TRUE)
		o <- mclapply(X=x, FUN=function(x) do.call(what=rbind, args=x), mc.cores=getOption("mc.cores",12))
		o <- batch_rbind(o)
		rownames(o) <- NULL
		return(o)
	}
}

# batch_size is a performance issue:
batch_size <- 100

drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname="conte_dev", host="127.0.0.1", user="conte", password="conte")
con <- dbConnect(drv, dbname='conte_dev', host='ecosheds.org', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))

qry <- paste0("SELECT featureid, AVG(prcp) FROM daymet WHERE featureid IN (", featureids_string, ") GROUP BY featureid;")

result <- dbSendQuery(con, qry)

eat_more_results <- TRUE
some_records <- NULL
old_records <- NULL 
write_records <- list()
j <- 0
ii <- 0
## It's like writing bad C code, just in R.
while (eat_more_results) {
	j <- j + 1;
	boom <- 0
	repeat {
		fetch_batch <- try( expr = fetch(res=result, n=batch_size) )
		if (class(fetch_batch) != 'try-error') {
			break;
		} else {
			result <- dbSendQuery(con, qry)
			if (j > 1) {
				dump <- fetch(res=result, n=(j-1)*batch_size)
			}
		}
		if (boom > 10) stop("Big Boom.")
		boom <- boom + 1
	}
  
	some_records <- rbind(old_records, fetch_batch)
	old_records <- NULL
  
	cat("rows processed: ", j*batch_size, "\n")

}

dbClearResult(result)

dbSendQuery(link$conn, "DROP TABLE IF EXISTS unique_case_data_by_delivery;")
dbSendQuery(link$conn, paste0(
	'CREATE TABLE unique_case_data_by_delivery AS (',
		'SELECT * FROM temporary_unique_case_data_by_delivery',
	');'
))


#-------------------------Query daymet data-----------------------------

# Get precip data
tbl_daymet_annual <- tbl(db, 'daymet') %>%
  dplyr::filter(featureid %in% featureids) %>%
  dplyr::mutate(year = date_part('year', date)) %>%
  dplyr::group_by(featureid, year) %>%
  dplyr::select(featureid, year, prcp) %>%
  dplyr::summarise_each(funs(mean))

tbl_daymet_monthly <- tbl(db, 'daymet') %>%
  dplyr::filter(featureid %in% featureids) %>%
  dplyr::mutate(year = date_part('year', date)) %>%
  dplyr::mutate(month = date_part('month', date)) %>%
  dplyr::group_by(featureid, year, month) %>%
  dplyr::select(featureid, year, month, prcp) %>%
  dplyr::summarise_each(funs(mean))

featureids.test <- sample(featureids, size = 10, replace = F)

featureids_string <- paste(featureids, collapse=', ')

qry <- paste0("COPY(SELECT featureid, AVG(prcp) FROM daymet WHERE featureid IN (", featureids_string, ") GROUP BY featureid) TO STDOUT CSV HEADER;")  # "select * from whatever where featureid in (80001, 80002, 80003)"

cat(qry, file = "Code/daymet_query.sql")


i = 1
chunk_size = 100
n.loops <- ceiling(length(featureids) / chunk_size)

#while(i <= length(featureids)) {
#for(i in 1:n.loops) { 
featureid_subset <- featureids[i:(i*chunk_size)]
featureids_string <- paste(featureid_subset, collapse=', ')


j <- j + 1;
boom <- 0
repeat {
  fetch_batch <- try( expr = fetch(res=result, n=batch_size) )
  if (class(fetch_batch) != 'try-error') {
    break;
  } else {
    result <- dbSendQuery(link$conn, stmt)
    if (j > 1) {
      dump <- fetch(res=result, n=(j-1)*batch_size)
    }
  }
  if (boom > 10) stop("Big Boom.")
  boom <- boom + 1
}
drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname="conte_dev", host="127.0.0.1", user="conte", password="conte")
con <- dbConnect(drv, dbname='conte_dev', host='ecosheds.org', port='5432', user=options('SHEDS_USERNAME'), password=options('SHEDS_PASSWORD'))

qry <- paste0("SELECT featureid, AVG(prcp) FROM daymet WHERE featureid IN (", featureids_string, ") GROUP BY featureid;")

res <- dbSendQuery(con, qry)
# fetch results
out <- fetch(res, n=-1)

if(exists("df_precip") == FALSE) {
  df_precip <- out
} else {
  df_precip <- rbind(df_precip, out)
}

print(paste0(i, " of ", n.loops, " loops"))
write.table(df_precip, file = 'Data/daymet_precip_loop.csv', sep = ',', row.names = F)

#i = i*chunk.size + 1
dbDisconnect(con)
}

write.table(df_precip, file = "Data/daymet_precip.csv", sep = ",", row.names = F)

