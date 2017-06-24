# Northeast_Bkt_Occupancy

Daniel J Hocking   

## Abstract

The USGS Conte Laboratory developed an occupancy model for Brook Trout based on presence/absence data from agencies (see below) and landscape data housed in [SHEDS: http://ecosheds.org/](http://ecosheds.org/). The aim of the model was to provide predictions of occupancy (probability of presence) for catchments smaller than 200 $km^2$ in the northeastern US from Virginia to Maine. We provide predictions under current environmental conditions and for future increases in stream temperature.

## Objectives

1.  Evaluate landscape, land-use, and climate factors affecting the probability of Brook Trout occupancy in the eastern United States
2.  Predict current Brook Trout occupancy in each stream reach (confluence to confluence) across the region 
3.  Forecast Brook Trout occupancy under future conditions

## Project Summary

**Project summary can be found at: [http://conte-ecology.github.io/Northeast_Bkt_Occupancy/](http://conte-ecology.github.io/Northeast_Bkt_Occupancy/)**

## Updating the Project Webpage

run `git pull origin master` to ensure the local project is synched with the GitHub version.

1. Edit the `index.Rmd` file on the master branch
2. knit the index file in RStudio. The following YAML code at the top of the Rmd file calls to the html template to incorporate css and javascript during the knitting:

```
output: 
  html_document: 
    keep_md: yes
    template: sheds-template.html
```

3. Edit any table details such as column and row names in the resulting `index.html` file.
4. git add, commit, and push the master branch files.
5. On the command line run `git checkout gh-pages`
5. Now in the gh-pages branch that generates the webpage, run `git checkout master --index.html`. This brings the file over from the master branch.
7. Add and commit the changes
8. `git push origin gh-pages`
9. `git checkout master` to get back on the master branch.

