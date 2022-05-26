# TO READ

## [spatial cul-de-sac](https://journals.sagepub.com/doi/abs/10.1177/030913257800200204)
from 1978, for lit rev

## [Spatial diffusion and spatial statistics: revisting Hägerstrand’s study of innovation diffusion](https://reader.elsevier.com/reader/sd/pii/S1878029615003151?token=1F5BE4CD8B569369C435D2F382C4EF750BBEF159CFF5A2AA9810A1E8AFCDFE385C7499F8823108B1E995C872E2E09D74&originRegion=eu-west-1&originCreation=20210901165007)


## [Survavival analysis R package](https://cran.microsoft.com/snapshot/2017-04-05/web/packages/spBayesSurv/vignettes/Intro_to_spBayesSurv.pdf)

Rscript -e "require ('knitr'); knit ('data.prep.Rmd')"
R CMD BATCH data.prep.Rmd [outfile]
Rscript -e "rmarkdown::render('data.prep.Rmd')"

Rscript -e 'library(rmarkdown); rmarkdown::render("data.prep.Rmd", "html_document")
Rscript -e "rmarkdown::render('data.prep.Rmd')"

git config --global user.name "etranos"
    git config --global user.email you@example.com

After doing this, you may fix the identity used for this commit with:

    git commit --amend --reset-author


    Support for password authentication was removed on August 13, 2021. Please use a personal access token instead.
   remote: Please see https://github.blog/2020-12-15-token-authentication-requirements-for-git-operations/ for more information.
   fatal: Authentication failed for 'https://github.com/etranos/broadband.speed.covid.git/'

   Quitting from lines 56-61 (data.prep.Rmd)
   Error: cannot allocate vector of size 3.9 Gb

   Execution halted
   Warning message:
   system call failed: Cannot allocate memory

rsession-memory-limit-mb=4000

**Book**: Spatial Point Patterns: Methodology and Applications with R


# Spatial diffusion of the web

- active vs. passive adoption
- granular scale: 2000-2010 MSOA ready.
I could use 1996-2012 to whatever level of aggregation

# Ideas

## logistic curves for each spatial unit for cumulative number of websites.
- plot the points and then estimate the logistic curves.
  - first for regions to give the big picture and then for the spatial units
  - qual comparison of the curves, see Bento_Fontes_2015.pdf
- decide spatial level. Maybe MSOAs?
- Time clustering or geoshiloutes to end up with clusters / regions of similar
internet diffusion patters
- explain the clusters
- TODO: find how to estimate the logistic curves

## survival analysis, individual

y_ijt ~ Wy_ijt + y_t-1 + geog_j + soc_econ_jt + website_i

- level of observation: unique website
- dependent variable: time a website started being archived since, e.g. 1996
- geog variables:
  - distance from London / other cities
  - density of websites in neighbouring spatial units
  - other socioeconomic variables
- individual variables
  - something based on website keywords **need to scrape!**
  - ratio of gyration for local / global reach
  - size of website based on pages included in the data
  - archival frequency
- censored? yes, right censored. probably not because nobody had a website before
1996 -- i.e. no left censoring. But we only observe websites since their first archival
poit -- i.e. rgiht censoring. They might have died after that or not. I care for
how long the website stayed alive because, after broad adoption, new websites might
be competitive to old ones.

https://peopleanalytics-regression-book.org/survival.html

## aggregated
- websites or website density or growth_i,t ~  Wy_{t-1} + geog_ + X_i,t + T_t
- spatial panel?
- space, space-time clustering (space-time kernel density estimation (STKDE))
- actor-based clustering (Brenner, 2017) – a spatial smoothing technique that allows one to depict distributional patterns without imposing any prefixed higher level spatial boundaries
Brenner, T. (2017). Identification of clusters: An actor-based approach. Working Papers on Innovation and Space, 2(17

- [aggregated RF spatial explanatory](https://blasbenito.github.io/spatialRF/)
It is a good framework for an explanatory model, but the spatial variables are
not clearly defined. I think they are spatially lagged Xs.

## steps
- xy of websites, hex density plot; repeated LISA and DBSCAN, time?
=> clusters of engagining with web activities and how they change over time, descritptive analysis of thei locations, distance to London and other cities
=> individual level model??? no, can;t think of a LHS

- aggregated at MSOA, choropleth map, level and growth, panel
=> spatial panel about growth?    

- [x] [OA for GB](https://github.com/lvalnegri/projects-geography_uk/blob/master/92-prepare_oa_boundaries.R)
- [x] data for 2011-2012
- [x] cities on the map

1. hex heatmaps for n=1, shows concentration in London/cities, present as GIF time laps, *TODO: log*

2. Spatial stats, n=1, `level_lisa_oa.Rmd`:
    - **Moran's I increases over time.**
    - Gini over time: inequality increases over time and over n
    - Getis-Ord
    - web density to London, nearest city, nearest retail centre:
    the further away the lower the density over time until 2008, then the trend reverses `level_lisa_oa.Rmd`

    website density function for n = 1 and m < 12 for OA and different urban centres
      - both for n=1 and n<12 the 0s screw the pattern.
      - R^2 decreases over time: website location is less dependent to the distance to urban centres
      - b decreases over time, almost: over time, the further away an OA is from an urban centre, the lower the number of websites located there.

    - *todo* LA

3. LISA at OA level for level and growth for n=1. use level n=1, present as GIF. `level_lisa_oa.Rmd`

4. S for LA

  - All country  => matches the curve, midway through 2002 is when it reaches 50%
  - Xmid frequency graph
  - LA fast/slow, gif with sample
  - time-clusters



- [ ] distribution of postcodes for all the period and yearly
- [ ] n > 1
- [ ] time-space LISA and DBSCAN, see EPA paper
- [ ] [repeated hdbscan](https://cran.r-project.org/web/packages/dbscan/vignettes/hdbscan.html)
- [ ] [py-st-dbscan](https://github.com/eubr-bigsea/py-st-dbscan)
- [ ] [st-dbscan for R](https://github.com/CKerouanton/ST-DBSCAN/blob/master/stdbscan.R)
- [ ] [geosilhouttes](https://pysal.org/esda/notebooks/geosilhouettes.html)
- [x] sppt difference between years. *No real diff over time*. I need to fully understand the metric
- [x] Kernel Density Estimation, *not useful*, hex show the effect better

- [ ] website density function with spatia lag
- [ ] points: distribution of distance over time
- [ ] HH clusters ~ distance to centres???
  - done it for one year and for all OA. *need to loop it for all years and consider clusters as one unit*

> 17*227759
[1] 3871903

This paper maps the diffusion of web technologies at a very granular spatial level. The diffusion of innovation literature illustrates the adoption pace of innovations and new technologies. We know that the adoption of such developments tend to follow an *S* curve, with early adopters and late comers. Although this is widely discussed in the literature, we know little about how such processes differentiate over space. Importantly, we know very little about such spatial processes at a detailed level the reason being usually the lack of granular enough data to illustrate technological adoption.

However, there is value in exposing the spatial patterns of technological diffusion at a granular geographical level. Such spatial knowledge can provide valuable insights for policy makers and particularly those interested in supporting the uptake of new technologies to design relevant support frameworks. ADD SOMETHING ABOUT PLACE-BASED POLICIES

Here the focus is on active adoption of the web and how this diffused over space and time in the UK.
