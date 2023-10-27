## ideas for web diffusion paper

- rank of standardised

= > stability vs. volatility; more clear picture when standardise by firms. Not similar picture for n = 1 or up to 11.  Bottom, no labels

When a plot the stable LA for all years, instability is exposed.  

=> TODO: OA

- max = websites/firms

=> nothing changes

=> TODO: find local authority firms stats 1996-2012

- LSOA with TTWA
- hyperlinks

## post AAG
In order to model distance I need to control for econ activities. 
work-placed population classification for 2011 instead of OA.
Run the whole analysis for this level.
distance regressions including controls 
regress fast/slow against classification.
Anything relevant for LADs?

## TODO
- [x] clean level_lisa_la.Rmd from classification
- [x] figures for plm regression
- [x] repeat for OA
- [ ] explain S fast/slow with classification + distance for LA
- [ ] S for OA and explanation

## Google search
- machine learning spatial contagion
- machine learning diffusion prediction technology
- prediction forecasting machine learning multiple time series r
- machine learning diffusion prediction technology over time
- forecast time series logistic function curve in r
	- https://www.sciencedirect.com/science/article/abs/pii/S0169207014000971?casa_token=JcAUkbi7VSYAAAAA:WzayBIy2P5rBLPNj5drD4dIBeoc-XnsNQ73qI696zTgDsfS4stqZyTxJwqtUS_RtgS5diCrqqA
	- https://www.r-bloggers.com/2021/07/forecasting-many-time-series-using-no-for-loops/
	- https://datascience.stackexchange.com/questions/92733/logistics-demand-forecasting-with-20k-different-time-series
	- https://www.r-bloggers.com/2021/07/forecasting-many-time-series-using-no-for-loops/
	- https://cran.r-project.org/web/packages/caretForecast/caretForecast.pdf
	- http://topepo.github.io/caret/available-models.html
	- https://github.com/Rewove/financial-contagion-in-R
	- https://github.com/USCCANA/netdiffuseR
	- https://usccana.github.io/netdiffuser-sunbelt2018/
	- https://www.sciencedirect.com/science/article/pii/S027795361530143X
	- https://cran.r-project.org/web/packages/diffusionMap/diffusionMap.pdf
	- https://rdrr.io/github/mamut86/diffusion/
	- https://github.com/Rishi0812/MacroDiffusionIndex/blob/main/vignettes/ML_for_MacroDiffusionIndexes.Rmd

## My attempt, I think from k-neighbours
- rmse:
	- 1998: t+1 = 0.373, t+2=0.5.15

Check David's email

## hierarchical spatial weights matrix 
https://onlinelibrary.wiley.com/doi/full/10.1111/gean.12049
https://www.tandfonline.com/doi/full/10.1080/00130095.2022.2074830
https://www.tandfonline.com/doi/abs/10.1080/17421772.2023.2199034?journalCode=rsea20&s=03

## searches for prediction

## Spatial panel to model diffusion mechanisms

website density ~ website density in t-1 + website density of nearest city in t-1 + X

y_i,t ~ Wy_i,t-1 + 

On diffusion … you know I like to keep up to date with concepts and methods ?? (time for a comeback perhaps). I’ve never explored it in a research setting but I did use Haggett’s original diffusion of measles as a means to get into a set of spatial modelling with multiple membership multilevel models (week 10 of the course!!). I guess where I’d come from in the sort of questions that I think were underpinning the work yesterday was ‘what kind of spatial structures are present in the data?’ and then explore if there was a nearness based not on x/y point but on a hierarchical spatial weights matrix mased on places size. One thing that often appears in my mind is that geography is not always strictly spatial in the plane sense but in social and other spaces (spatially variable as Ron said). 

PCA???
