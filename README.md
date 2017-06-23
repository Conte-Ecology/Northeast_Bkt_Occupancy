# Northeast_Bkt_Occupancy

Daniel J Hocking  
3/28/2016  



## Abstract

Coming Soon

## Objectives

1. Evaluate landscape, land-use, and climate factors affecting the probability of Brook Trout occupancy in the eastern United States
2. Predict Brook Trout occupancy in each stream reach (confluence to confluence) across the region currently
3. Forecast Brook Trout occupancy under future conditions
4. Examine the tolerance  of Brook Trout to warming and forest change across space
5. Visualize climate mitigation potential through forest change

## Approach 

We used a logistic mixed effects model to include the effects of landscape, land-use, and climate variables on the probability of Brook Trout occupancy in stream reaches (confluence to confluence). We included random effects of HUC10 (watershed) to allow for the chance that the probability of occupancy and the effect of covariates were likely to be similar within a watershed. Our fish data came primarily from state and federal agencies (see below). We considered a stream occupied if any Brook Trout were ever caught during an electrofishing survey between 1991 and 2010.

**Project details can be found at: [http://conte-ecology.github.io/Northeast_Bkt_Occupancy/](http://conte-ecology.github.io/Northeast_Bkt_Occupancy/)**

## Updating the Project Webpage

1. Edit the `index.Rmd` file on the master branch
2. knit the index file in RStudio
3. Edit any table details such as column and row names in the resulting `index.md` file.
4. Run pandoc to convert the updated `index.md` file to `index.html`.
5. Add, commit, and push the master branch files.
6. On the command line run `git checkout gh-pages`
7. Now in the gh-pages branch that generates the webpage, run `git checkout master --index.html`. This brings the file over from the master branch.
8. Add and commit the changes
9. `git push origin gh-pages`
10. `git checkout master` to get back on the master branch.
