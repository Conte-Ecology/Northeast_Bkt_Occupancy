# Northeast Brook Trout Occupancy
Daniel J Hocking  
`r format(Sys.time(), '%d %B, %Y')`  



## Abstract

The USGS Conte Laboratory developed an occupancy model for Brook Trout based on presence/absence data from agencies (see below) and landscape data housed in [SHEDS: http://ecosheds.org/](http://ecosheds.org/). The aim of the model was to provide predictions of occupancy (probability of presence) for catchments smaller than 200 km2 in the northeastern US from Virginia to Maine. We provide predictions under current environmental conditions and for future increases in stream temperature.

## Objectives

1.	Evaluate landscape, land-use, and climate factors affecting the probability of Brook Trout occupancy in the eastern United States
2.	Predict current Brook Trout occupancy in each stream reach (confluence to confluence) across the region 
3.	Forecast Brook Trout occupancy under future conditions

## Approach 

We used a logistic mixed effects model to include the effects of landscape, land-use, and climate variables on the probability of Brook Trout occupancy in stream reaches (confluence to confluence). We included random effects of HUC10 (watershed) to allow for the chance that the probability of occupancy and the effect of covariates were similar within a watershed. Our fish data came from state and federal agencies that sample streams for Brook Trout as part of regular monitoring (see below). We considered a stream occupied if any Brook Trout were ever caught during an electrofishing survey between 1991 and 2010.


## Observed Presence-Absence Data (Dependent Data)


|  state  |  data_source  |  n_reaches  |  min_yr  |  max_yr  |  range_yrs  |
|:-------:|:-------------:|:-----------:|:--------:|:--------:|:-----------:|
|   CT    |    CTDEEP     |    1267     |   1991   |   2010   |     19      |
|   CT    |     NYDEC     |      2      |   1991   |   2010   |     19      |
|   MA    |    CTDEEP     |      9      |   1991   |   2010   |     19      |
|   MA    |     MADFW     |     321     |   1991   |   2010   |     19      |
|   MA    |     NYDEC     |      4      |   2008   |   2010   |      2      |
|   MD    |     Hitt      |      2      |   1991   |   2010   |     19      |
|   MD    |     PFBC      |      1      |   1991   |   2010   |     19      |
|   ME    |     MEIFW     |    1881     |   1991   |   2010   |     19      |
|   NH    |    CTDEEP     |      1      |   1991   |   2010   |     19      |
|   NH    |     MADFW     |      4      |   1991   |   2010   |     19      |
|   NH    |     MEIFW     |      6      |   1995   |   2010   |     15      |
|   NH    |     VTFWD     |      1      |   1991   |   2010   |     19      |
|   NJ    |     NYDEC     |      2      |   1992   |   1994   |      2      |
|   NY    |    CTDEEP     |      3      |   1991   |   2010   |     19      |
|   NY    |     MADFW     |      2      |   2008   |   2010   |      2      |
|   NY    |     NYDEC     |    4350     |   1991   |   2010   |     19      |
|   PA    |     Hitt      |      5      |   1999   |   2005   |      6      |
|   PA    |     NYDEC     |      6      |   1991   |   2010   |     19      |
|   PA    |     PFBC      |     857     |   1991   |   2010   |     19      |
|   RI    |    CTDEEP     |      2      |   1991   |   2010   |     19      |
|   VT    |     MADFW     |      1      |   2004   |   2004   |      0      |
|   VT    |     NYDEC     |      1      |   1995   |   1995   |      0      |
|   VT    |     VTFWD     |     319     |   1991   |   2010   |     19      |
|   NA    |     MEIFW     |      6      |   2007   |   2007   |      0      |
|   NA    |     VTFWD     |      2      |   2006   |   2009   |      3      |

## Predictor Variables

Documentation related to the landscape, land-use, streams, catchment delineation, and climate variable data sources and processing can be found at [http://conte-ecology.github.io/shedsGisData/](http://conte-ecology.github.io/shedsGisData/). We used an AICc model selection approach to find the best combination of variables balancing model fit with model complexity. The model set was based on the literature and author experience and followed closely with [Kanno et al. 2015](http://afs.tandfonline.com/doi/abs/10.1080/00028487.2014.991446).

| Variable | Description | Source | Processing | GitHub Repository |
|:--------:| --------------------------- | --------------- | ------------------------- | ----------------- |
| Total Drainage Area | The total contributing drainage area from the entire upstream network | [The SHEDS Data project](http://conte-ecology.github.io/shedsGisData/) | The individual polygon areas are summed for all of the catchments in the contributing network| [NHDHRDV2](https://github.com/Conte-Ecology/shedsGisData/tree/master/NHDHRDV2) |
| Riparian Forest Cover | The percentage of the upstream 200ft riparian buffer area that is covered by trees taller than 5 meters | [The National LandCover Database (NLCD)](http://www.mrlc.gov/nlcd06_data.php) | All of the NLCD forest type classifications are combined and attributed to each riparian buffer polygon  using GIS tools. All upstream polygon values are then aggregated.| [nlcdLandCover](https://github.com/Conte-Ecology/shedsGisData/tree/master/basinCharacteristics/rasterPrep/nlcdLandCover) |
| Precipition | The mean of the summer daily precipitation for the individual local catchment | [Daymet Daily Surface Weather and Climatological Summaries](https://daymet.ornl.gov/) | Daily precipitation records are spatially assigned to each catchment based on overlapping grid cells using the [zonalDaymet](https://github.com/Conte-Ecology/zonalDaymet) R package| [daymet](https://github.com/Conte-Ecology/shedsGisData/tree/master/daymet) |
Mean July Stream Temperature | Estimated stream temperature from the SHEDS regional model |	SHEDS stream temperature model | Daily stream temperature estimates were aggregated to a mean July value for each catchment |	conteStreamTemperature_northeast
| Upstream Impounded Area| The total area in the contributing drainage basin that is covered by wetlands, lakes, or ponds that intersect the stream network | [U.S. Fish & Wildlife Service (FWS) National Wetlands Inventory](http://www.fws.gov/wetlands/Data/Data-Download.html)| All freshwater surface water bodies are attributed to each catchment using GIS tools. All upstream polygon values are then aggregated.| [fwsWetlands](https://github.com/Conte-Ecology/shedsGisData/tree/master/basinCharacteristics/rasterPrep/fwsWetlands) |
| Percent Agriculture | The percentage of the contributing drainage area that is covered by agricultural land (e.g. cultivated crops, orchards, and pasture) including fallow land. | [The National LandCover Database](http://www.mrlc.gov/nlcd06_data.php)| All of the NLCD agricutlural classifications are combined and attributed to each catchment polygon using GIS tools. All upstream polygon values are then aggregated.| [nlcdLandCover](https://github.com/Conte-Ecology/shedsGisData/tree/master/basinCharacteristics/rasterPrep/nlcdLandCover) |
| Percent High Intensity Developed | The percentage of the contributing drainage area covered by places where people work or live in high numbers (typically defined as areas  covered by more than 80% impervious surface) | [The National LandCover Database](http://www.mrlc.gov/nlcd06_data.php)| The NLCD high intensity developed classification is attributed to each catchment polygon using GIS tools. All upstream polygon values are then aggregated. | [nlcdLandCover](https://github.com/Conte-Ecology/shedsGisData/tree/master/basinCharacteristics/rasterPrep/nlcdLandCover) |


## General Results

### Table of Model Results

**Fixed Effects:**


|       Parameter       |  Estimate  |  Std. Error  |  z value  |  P-value  |
|:---------------------:|:----------:|:------------:|:---------:|:---------:|
|      (Intercept)      |   0.314    |     0.11     |   2.84    |  0.00445  |
|         area          |   -0.416   |    0.0591    |   -7.04   | 1.89e-12  |
|    summer_prcp_mm     |   0.385    |    0.0978    |   3.94    | 8.14e-05  |
|     meanJulyTemp      |   -0.706   |    0.0719    |   -9.82   | 9.03e-23  |
|        forest         |   0.413    |    0.0686    |   6.02    | 1.71e-09  |
|      surfcoarse       |   0.165    |    0.0586    |   2.81    |  0.00494  |
|       allonnet        |   -0.291   |    0.0568    |   -5.13   | 2.83e-07  |
|       devel_hi        |  -0.0996   |    0.0569    |   -1.75   |  0.0799   |
|      agriculture      |   -0.664   |    0.0995    |   -6.67   | 2.57e-11  |
|  area:summer_prcp_mm  |   0.0217   |    0.0503    |   0.432   |   0.666   |
|  meanJulyTemp:forest  |   -0.034   |    0.0501    |  -0.678   |   0.498   |
| summer_prcp_mm:forest |   0.127    |    0.0585    |   2.17    |  0.0302   |

**Random Effects (HUC10):**


|   Parameter    |  SD   |  Variance  |
|:--------------:|:-----:|:----------:|
|  (Intercept)   | 1.34  |    1.79    |
|      area      | 0.211 |   0.0443   |
|  agriculture   | 0.353 |   0.124    |
| summer_prcp_mm | 0.534 |   0.285    |
|  meanJulyTemp  | 0.235 |   0.0553   |

These results indicate that mean July stream temperature had the largest (negative) effect on the probability of Brook Trout occupancy. Forest cover within the 200 foot riparian buffer had a strong positive effect on occupancy, whereas agriculture within the entire upstream drainage had a negative effect on occupancy. Mean summer precipitation has a positive effect on occupancy and the effect was larger with increasing levels of riparian forest cover, but was not dependent on stream drainage area. The total impounded area on the stream network had a negative effect on Brook Trout occupancy as did the upstream drainage area. Surficial coarseness was positively correlated with the presence of Brook Trout, which may be a result of better physical habitat structure or as an indication of local groundwater upwelling.

![Effect of mean July stream temperature on Brook Trout Occupancy](Output/July_Temp_Effect.png)

![Effect of riparian forest cover on Brook Trout Occupancy](Output/Forest_Effects.png)

The average occupancy across the range of observed catchments was 0.58.

The effects of these landscape and climate characteristics are similar to what has been observed in other Brook Trout studies.

### Model Fit

We examined the false positive and false negative rates and used the Area Under the Receiver Operating Characteristic ROC) curve (AUC) to assess the model fit.

<u>Definitions</u>

* AUC - measures a model's ability to determine which locations are occupied (Zipkin et al. (2012) *Ecological Applications*)
* Sensitivity - true positive rate (="recall rate")
* Specificity - true negative rate
* 1-Specificity - false positive rate (Type I Error rate; ="fall-out rate")
* 1-Sensitivity - false negative rate (Type II Error rate; ="miss rate")
* Accuracy - ability to identify true positives and true negatives
* ROC - The curve is created by plotting the true positive rate (sensitivity) against the false positive rate (1-specificity) at various threshold settings

The model output (predictions) are the probability of occupancy but the data are observed presence and absence (1 or 0). Therefore, it is difficult to evaluate how well the model predicts the data. The probabilities of occupancy must be converted to presence-absences for comparison. We do this over a range of thresholds (= cutoffs). The threshold is the probability above which the stream is assumed to be occupied (Brook Trout = present). For example, if the probability of occupancy for a stream is 0.45 and we set a threshold = 0.50, we would assign the stream as unoccupied (absent). However, if we used a threshold of 0.4 then this same stream would be assigned as occupied (present). If the true (observed) state of the stream was occupied, then using a threshold of 0.5 would result in a false absence (predicted absent when really present) but if we used a threshold of 0.4 we would correct assign the stream as occupied (true positive). Assigning a threshold is a balance of trade-offs between false positives and false negatives. The balance is based on the risk tolerance to the consequences of type I and type II errors.

AUC can range from 0-1. An AUC value of 0.5 indicates the model does no better than random chance in discriminating occupancy. Models with AUC >0.7 are considered to have good discrimination in assessing the probability of occupancy.

![Model fit and discrimination ability](Output/AUC_plots.png)

Our model is a good fit (AUC = 0.95) to the data and has a very strong ability to assess the probability of occupancy.

### Model Validation

More important than how well the model works with the data used to fit the model is the ability of the model to predict occupancy at unsurveyed locations. To assess this predictive power, we used data from the 1933 stream reaches withheld from model fitting. We use the term "fitted data" to refer to the data we used to fit (estimate) the model. For comparison, others use the terms "training data" or "calibration data" synonymously. Validation data are the independent data withheld from model fitting for the purpose of understanding how well a model predicts to unobserved space and time. To evaluate this predictive power, we plotted the false positive rate (1-specificity) vs. the true positive rate (sensitivity) and calculated the AUC.

![Model predictive discrimination ability using validation data](Output/AUC_valid_plots.png)

The AUC when predicting for the validation data was 0.75, which indicates that the model has good ability to discriminated between occupied and unoccupied stream reaches (catchments) for locations without survey data. From this we are highly confident in the model's ability to predict occupancy across the region.

## Future conditions

We provide estimates of the probability of occupancy for each catchment with increases in stream temperature of either 2 or 4 C. To provide these estimates, we simply increased input values for mean July stream temperature by 2 or 4 C and estimated occupancies. Maps of current and predicted future occupancies are available at ice.ecosheds.org. 

## Comparison with Other Models

DeWeber and Wagner (2014) used a similar model to predict Brook Trout occupancy throughout the native eastern range. Downstream Stategies (DSS) also modeled the probability of Brook Trout occupancy for the Chesapeake Bay watershed. DSS used a different approach, employing boosted regression trees to fit the presence-absence data. This is a machine learning method that allows for non-parametric correlations between dependent (predictor) and independent (response) variables. We present a comparison of the error rates reported for each group over a range of occupancy thresholds. Information about the False Negative Rates (FNR) and False Positive Rates (FPR) along with ROC AUC can be found above.


|     justification      |  thresholds  |  sensitivity  |  specificity  |  FNR  |  FPR  |  total_error_rate  |
|:----------------------:|:------------:|:-------------:|:-------------:|:-----:|:-----:|:------------------:|
|       FNR = 10%        |     0.23     |     0.90      |     0.33      | 0.10  | 0.67  |        0.77        |
|     Compare w/DSS      |     0.40     |     0.79      |     0.53      | 0.21  | 0.47  |        0.68        |
|   Compare w/DeWeber    |     0.46     |     0.76      |     0.59      | 0.24  | 0.41  |        0.65        |
|   Equal error rates    |     0.56     |     0.68      |     0.68      | 0.32  | 0.32  |        0.64        |
| Fitted data prevalence |     0.61     |     0.64      |     0.73      | 0.36  | 0.27  |        0.63        |
|       FPR = 10%        |     0.77     |     0.43      |     0.90      | 0.57  | 0.10  |        0.67        |



|  Threshold  |  Conte_FNR  |  Conte_FPR  |  DSS_FNR  |  DSS_FPR  |  DeWeber_FNR  |  DeWeber_FPR  |
|:-----------:|:-----------:|:-----------:|:---------:|:---------:|:-------------:|:-------------:|
|    0.23     |    0.10     |    0.67     |    NA     |    NA     |      NA       |      NA       |
|    0.40     |    0.21     |    0.47     |   0.09    |    0.1    |      NA       |      NA       |
|    0.46     |    0.24     |    0.41     |    NA     |    NA     |     0.34      |     0.22      |
|    0.56     |    0.32     |    0.32     |    NA     |    NA     |      NA       |      NA       |
|    0.61     |    0.36     |    0.27     |    NA     |    NA     |      NA       |      NA       |
|    0.77     |    0.57     |    0.10     |    NA     |    NA     |      NA       |      NA       |

The least biased comparison is when holding one of the error rates constant (e.g. 10%) and calculating the other error rate. The threshold for this will differ for each data set and model but is roughly comparable.


|  Group  |  FNR  |  FPR  |
|:-------:|:-----:|:-----:|
|  Conte  |  0.1  | 0.67  |
| DeWeber |  0.1  |  0.5  |
|   DSS   |  0.1  | 0.09  |
|  Conte  | 0.57  |  0.1  |
| DeWeber | 0.58  |  0.1  |
|   DSS   | 0.09  |  0.1  |

Although we compared errors rates over a range of thresholds, there are still differences in the interpretation of error rates among studies. We used similar methods and data as DeWeber and Wagner (2014) and the error rates should be closely comparable, especially the comparison of error rates when using the observed prevalence to establish the thresholds (cutoffs). DSS used very different data sources and different methods making even their predictive performance less comparable. For example, they included rivers up to 17,000 $km^2$, whereas we limited our analysis to streams < 200 $km^2$ and only used streams where surveys were done targeting trout using electrofishing methods. Larger rivers in this region have virtually zero probability of wild Brook Trout occupancy. Therefore, including these rivers, which are nearly all 0, makes for easier prediction and inflates the model performance in relation to more restrictive models such as ours. Neither method is right or wrong, but rather provide slightly different inference. Our model focuses on distinguishing the probability of occurrence for headwater streams potentially suitable for wild trout populations throughout the northeast U.S. The DSS analysis provides a broader overview of streams and rivers likely to support Brook Trout across all flowing waters in the Chesapeake Bay Watershed. Even accounting for those differences, the high accuracy and balance of false positives and negatives suggests that the DSS model likely produces more consistently accurate predictions of Brook Trout occurrence within the Chesapeake Bay Watershed compared with either of the larger regional models.

### Direct Comparison

Our predictions were on slightly different flowlines and catchment delineations than those used by Downstream Strategies. To make explicit comparision of predictions from the two models, we rasterized the DSS predictions and performed zonal statistics to calculate the area-weighted average in each of our catchments (associated with each stream reach). 


![](index_files/figure-html/dss comparison-1.png)<!-- -->




