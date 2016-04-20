rm(list=ls())
gc()

library(dplyr)
library(tidyr)
library(lubridate)
library(RPostgreSQL)
library(ggplot2)
# load profile locally to play with packrat
source("~/.Rprofile")

# featureids <- readRDS("Data/survey_featureid.RData")

df_covariates <- readRDS("Data/covariates.RData")

# until derived metrics in db, load from csv
df_metrics <- read.table("Data/derived_site_metrics.csv", header = T, sep = ",", stringsAsFactors = FALSE)

# add derived metrics to covariates
df_covariates <- df_covariates %>%
  dplyr::left_join(df_metrics) %>%
  dplyr::select(-totalObs, -meanDays.20, -yearsMaxTemp.18, -yearsMaxTemp.20, -yearsMaxTemp.22)


# Then import results
#df_precip <- read.csv("Data/daymet_results.csv", header = T)

# make annual precip from mean daily
# df_precip <- df_precip %>%
#   dplyr::mutate(prcp = prcp * 365)
# str(df_precip)
# summary(df_precip)

df_covariates <- df_covariates %>%
  #dplyr::left_join(df_precip, by = c("featureid")) %>%
  dplyr::rename(area = AreaSqKM,
                prcp = ann_prcp)

# Until trout data in db load from csv
# df_pa <- read.csv("Data/OccupancyHRD.csv", header = T) %>%
#   dplyr::rename(featureid = FEATUREID, pres = Occupancy) %>%
#   dplyr::filter(!is.na(pres), featureid %in% featureids)

df_pa <- read.csv("Data/regional_occupancy_data.csv", header = T, stringsAsFactors = FALSE)

df_pa <- df_pa %>%
  dplyr::mutate(pres = ifelse(catch > 0, 1, catch)) %>%
  dplyr::select(featureid, pres) %>%
  dplyr::filter(!is.na(pres))

df <- dplyr::left_join(df_pa, df_covariates, by = ("featureid"))

str(df)

# filter to sites with water temperature predictions
df <- df %>%
  dplyr::filter(!is.na(meanJulyTemp))

# deciding upper range of watershed size for occupance analysis, to remove large watersheds (i.e. outliers)

hist(df[df$pres == 1, ]$area) 
df2 <- df[df$area <= 200, ]
hist(df2[df2$pres == 1, ]$area)

## Clean up unusual & outliers
summary(df2)

df2 <- dplyr::select(df2, -meanRMSE, -meanDays.22)
#df2 <- na.omit(df2)
#dim(df2)
#summary(df2) # no NA remaining
df2 <- df2 %>%
  dplyr::filter(meanDays.18 < 300)

summary(df2)

saveRDS(df2, file = "Data/data_clean.RData")

# Standardize continuous covariates for analysis instead of using transformations

stdFitCovs <- function(x, var.names){
  x2 <- dplyr::select(x, featureid)
  for(i in 1:length(var.names)){
    #means <- mean(x[ , var.names[i]], na.rm = T)
    #stds <- sd(x[ , var.names[i]], na.rm = T)
    x2[ , var.names[i]] <- (x[ , var.names[i]] - mean(x[ , var.names[i]], na.rm = T)) / sd(x[ , var.names[i]], na.rm = T)
  }
  #std_out <- list(x2, means, stds)
  return(x2)
}

vars <- c("agriculture", "allonnet", "area", "devel_hi", "elevation", "forest", "surfcoarse", "prcp", "meanJulyTemp", "meanSummerTemp", "meanDays.18", "winter_prcp_mm", "spring_prcp_mm", "summer_prcp_mm", "fall_prcp_mm") #"elev_nalcc"

saveRDS(vars, file = "Data/vars.RData")

df.std <- stdFitCovs(df2, vars)
means <- NULL
stds <- NULL
for(i in 1:length(vars)) {
means[i] <- mean(df2[ , vars[i]], na.rm = T)
stds[i] <- sd(df2[ , vars[i]], na.rm = T)
}
means_stds <- data.frame(cbind(vars, means, stds))

data.fit.std <- df2 %>%
  dplyr::mutate(fhuc8 = as.factor(huc8),
                fhuc10 = as.factor(huc10)) %>%
  dplyr::select(featureid, huc8, huc10, huc12, fhuc8, fhuc10, latitude, longitude, pres)
data.fit.std <- dplyr::left_join(data.fit.std, df.std, by = c("featureid"))
  

summary(data.fit.std) 


## Pair plot of environmental covariates
# function for pearson correlation (http://www2.warwick.ac.uk/fac/sci/moac/people/students/peter_cock/r/iris_plots/)

source("/Users/Dan/Documents/Statistics/R/Functions/scatterplot_matrix.R")
# pair plot
pairs1 <- data.fit.std[ , vars]
pairs1 <- na.omit(pairs1)
pairs(pairs1, main = "Pairs plot of standardized covariates", upper.panel=panel.smooth, lower.panel=panel.cor, diag.panel=panel.hist)

# summer precip isn't overly correlated with any 1 variable but moderately correlated with multiple (forest, temp, precip) so probably unnecessary to use in the models

# consider whether want a quadratic effect of area or if the data is just sparse when have small drainages
plot(data.fit.std$area, data.fit.std$pres)
lines(smooth.spline(data.fit.std$area, data.fit.std$pres), col = "red")

hist(data.fit.std$area)


# probably no need to have quadratic area effect.

# elevation is the only variable that can't include b/c of colinarity and can only use tmin or tmax
# might not be able to use slope because moderate collinarity with multiple variables
# also probably just use rising slope of air-water relationship. Rising and falling are correlated but rising has a bit more variability


## Validation Setup

# 01080203 = deerfield

# How many HUC 8, 10, and 12 for leaving out as validation set
length(unique(data.fit.std$huc8)) 
length(unique(data.fit.std$huc10)) # number of HUC10 
length(unique(data.fit.std$huc12)) # number of HUC12
length(data.fit.std$huc10) # number total catchments

summary(data.fit.std)
data.fit.std <- na.omit(data.fit.std)

p.valid <- 0.2 # Percent of data to retain for validation purposes
n.fit <- floor(length(unique(data.fit.std$huc10)) * (1 - p.valid))

set.seed(24744)
huc.fit <- sample(unique(data.fit.std$huc10), n.fit, replace = FALSE) # select HUCs to hold back for testing 
df.valid <- subset(data.fit.std, !huc10 %in% huc.fit) # 10% data for validation
df.fit <- subset(data.fit.std, huc10 %in% huc.fit)    # 90% data for model fitting

# check if deerfield in fit set
"01080203" %in% unique(df.fit$huc8)
"01080203" %in% unique(df.valid$huc8)

n.fit # 138 of 154 HUCs used for model fitting (16 retained for validation)
dim(df.fit)[1] # 3239 of 3645 catchments samples used for fitting


saveRDS(df.fit, file = "Data/fit.RData")
saveRDS(df.valid, file = "Data/valid.RData")
saveRDS(means_stds, file = "Data/means.RData")
