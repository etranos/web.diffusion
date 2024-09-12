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

On diffusion Ö you know I like to keep up to date with concepts and methods ?? (time for a comeback perhaps). Iíve never explored it in a research setting but I did use Haggettís original diffusion of measles as a means to get into a set of spatial modelling with multiple membership multilevel models (week 10 of the course!!). I guess where Iíd come from in the sort of questions that I think were underpinning the work yesterday was ëwhat kind of spatial structures are present in the data?í and then explore if there was a nearness based not on x/y point but on a hierarchical spatial weights matrix mased on places size. One thing that often appears in my mind is that geography is not always strictly spatial in the plane sense but in social and other spaces (spatially variable as Ron said). 

PCA???


I want to model the diffusion of a technology among UK Local Authorities (LA). I need a spatial panel model with the following characteristics:
Dependent variable: adoption rate in LA i and time t
Independent variables:
- Spatial lag of adoption rate of LA i in time t-1
- Adoption rate in the nearest to i city in t-1
- A matrix of control variables X 

## Cast
- we need to repeatedly leave the complete time series of one or more data loggers out and use them as test data during CV.
indices <- CreateSpacetimeFolds(trainDat,spacevar = "SOURCEID",
                                k=3)
set.seed(10)
model_LLO <- train(trainDat[,predictors],trainDat$VW,
                   method="rf",tuneGrid=data.frame("mtry"=2), importance=TRUE,
                   trControl=trainControl(method="cv",
                                          index = indices$index))


## to do
- [x] ideal: (i) train RF for all years and all (1) LADs and (2) OAs with CAST and report metrics. (ii) train for all years and per region for (1) LADs and (2) OAs, and predict to the other regions. Reports predictions as region similarities
- [x] check features
- [x] remove objects and save df for RF
- [x] NI for OA

## RF for all OA
> time.taken
Time difference of 1.21 days
> 
> print(model.all)
Random Forest 

3716736 samples
     10 predictor

No pre-processing
Resampling: Cross-Validated (10 fold) 
Summary of sample sizes: 2926910, 2926924, 3136005, 2926924, 3136005, 2926924, ... 
Resampling results across tuning parameters:

  mtry  splitrule   RMSE      Rsquared   MAE      
   2    variance    3.865809  0.5809699  0.5313035
   2    extratrees  3.730542  0.6168954  0.5884731
   6    variance    3.761356  0.6063340  0.5366004
   6    extratrees  3.612670  0.6273041  0.5331196
  10    variance    3.929176  0.5775066  0.5449132
  10    extratrees  3.617598  0.6278302  0.5403551

Tuning parameter 'min.node.size' was held constant at a value of 5
RMSE was used to select the optimal model using the smallest value.
The final values used for the model were mtry = 6, splitrule =
 extratrees and min.node.size = 5.

## After QuSS
- [ ] Rui's point: control for types of companies, is it because of diffusion or because of types of firms?

- [ ] lisa markov model: 
fraction of time LL in to vs t1, probability to go through classes

conditional being a LL, what is the provability of a neighbour to be a LL.
==> diffusion 

- [x] model log odds, standard model and then transform back to get the plot, tail behaviour
I fit a logistic curve (y = asym/(1+e^((xmid-x)/scal))) using a self-starter function that estimates suitable start values for the necessary parameters: asymptote and scale 
https://stat.ethz.ch/R-manual/R-devel/library/stats/html/SSlogis.html
fit <- nls(n ~ SSlogis(year, Asym, xmid, scal), data = df.test)


- [ ] MLM to borrow form the country's S curve, deviation from the country

- [ ] Firm GINI, conditional of the firms being unequal,
Decomposition of GINI Serge used for inequalities 
GINI for firm 

- Local Authorities levels WRONG DISTANCES
	- [x] y ~ n.l.slag + lag(n.nearest.city) + lag(n.London) + year
	R^2: 0.7953016  

	- [x] divide by d
	R^2: 0.8000562, d^2: 0.7970405
	
	- [x] Train to all but one, test on one: for n NI .62, NW.65, SC.8, L.81, rest > .86 
	
- Local Authorities growth  
	- for year > 1999, R^2 =  0.7381668. For 1998, 2 cases with growth = Inf, NI .83, NW .84, NE .86, SC .89, L .89 	
	- growth for n + .001, for year > 1999 similar order to levels, all years much lower R^2 and different order 
	- abs. growth, for year > 1999 NW, L, SW, SC lower R^2, all years NW, L, NI, SC
	- INCLUDE: growth rate for year > 1999 and abs. growth for all years

- OA levels
	- [ ] y ~ n.l.slag + lag(n.nearest.city)/d + lag(n.nearest.retail)/d + lag(London)/d + year
	This tests for continuity, hierarchy and time. No rank dynamics
	
n:   2     extratrees  3.774361  0.10143994  0.7419166
	
	the old OA level RF takes 1.2 days. The new OA level and growth took 2.3 h, but when I re-run the new OA takes a few hours. First time I run it, it crushed. I need to think about London and city n and fix the code re: retail centres. Grouped? For retail, take the sum of the retail polygon. For cities, maybe the local authority? 

2     variance    5.085630  0.1787893  1.057603, 
20.5h

dist	100.000000			
London	98.084009			
dist.retail	64.841641			
n.l.slag	40.710252			
n.nearest.retail.lag	29.226725			
n.nearest.city.lag	11.928686			
year	1.469731			
n.London.lag	0.000000

2     extratrees  5.231046  0.1275830  1.135169
n ~ London.v + city.v + retail.v + n.l.slag + year
retail.v	100.00000			
London.v	78.46748			
city.v	72.62728			
n.l.slag	68.04044			
year	0.00000	

  2     variance    4.999920  0.2053697  1.047293
n.London.lag + n.nearest.city.lag + n.nearest.retail.lag + n.l.slag + year + London + dist + dist.retail,

London               100.000
dist                  90.710
dist.retail           57.471
n.nearest.retail.lag  42.193
n.l.slag              34.319
n.nearest.city.lag    10.568
year                   3.231
n.London.lag           0.000	

- OA abs.growth, nothing, 19h
mtry  splitrule   RMSE      Rsquared     MAE      
  2     variance    4.019052  0.032595435  0.5413159

- [ ] Granger


- Temporal clustering for ranking instead of n: hopefully leapfrogging etc.

## GfR
- [x] Infection points because of data structure problems, e.g. 2004
	  I need to find how the 2004-2005 problem. LAD: E08000006 for 2005 and 2006.
	  Problem postcode is M28 2SL
- [x] Check the line plot to decide which PC i will impute
- [x] redo m: replace summarise(n = n()) with summarise(n = 
- [x] redo the PC line plots as both problem_years.Rmd and problem_years_10_.Rmd pointed to the same .png. Drop year from xlab. 
- [x] find distinct(postcodes). n=1: 557,808, m=10: 
- [x] lisa maps
- [x] S UK the same and title. Ranking remove year and remove mid years
- [x] correct Gini and S. For S UK, take the sum() not mean(), theme_minimal()_
- [x] run problem and s for 1 and 10 
- [x] lisa for 10

- [x] > 2001 instead of > 2003 for RF
- [x] > 2001 instead of > 2003 for text
- [x] la_RF_corrected.Rmd, 10,
- [x] check oa resutls for one hold
- [x] oa_RF_corrected.Rmd all
- [x] oa_RF_corrected.Rmd 10 all
- [x] oa_RF_corrected.Rmd one hold
- [ ] oa_RF_corrected.Rmd 10 one hold

- [ ] Spatial variable, distnce ARP
- [ ] correlations instead of signs

- [x] play with 2001 2003 for diffs in OA Moran's I 

- [x] rerun LAD RF to have a .csv for importance
- [x] write up the data cleaning process, find examples
- [ ] London and year
- [ ] End points for S curve
- [ ] Differentiate hierarchy with neighbourhood, maybe interaction with time these variables
- [ ] idea for further research: Diffusion distance plumber to plumber
- [ ] For 2004, emerald said Google fixed their algorithm 
- [ ] Marcus Janser For green (for Emerald)
- [x] Rank plots, average start and end

## Kemeny_2011

**GEOGRAPHY**
Geographically removed agents face
effective exclusion from adoption and imitation because technologies, at least initially,
‘cross hallways and streets more easily than oceans and continents’ (Glaeser et al., 1992,
1127). Hence, much tacit and context-dependent knowledge remains spatially ‘sticky,’
even in a global knowledge economy that has increasingly facilitated the exchange of
codified information. This stickiness creates technology gaps, reinforces agglomeration
and upholds the uneven distribution of production and income.

## what did the paper do
- tests the three spatial diffusion mechansisms at a very fine geographical scale for the first time and for a digital new technology: (i) the cumulative level of adoption follows an S-shaped pattern just like purely temporal models; (ii) diffusion is shaped by a hierarchy mechanisms in a form of a centrifugal force: from core to periphery; and (iii) diffusion is also shaped by distance and proximity.
- the combination of data sources which escape the traditional social science domain and adequate research methods can offer new lenses to geographical research regarding the 
understanding of technological diffusion.

## contribution
- economic geography: re-focus on diffusion studies, better understand geographical patterns of uneven development; turn the focus on active engagement with the digital instead of infrastructural approaches, always difficult to observe @zook2022mapping. 
- stakeholders 
	
## previous studies 
- [x] @beardsell1999spatial for heterogeneity (computer industry with employment data)
- [ ] @haller2011determinants for distance mechanism (firms with website in Ireland)
- [x] @perkins2005international latecomer advantage
- [ ] similar spatial autocorrelation with @ding2010modeling albeit in much more detailed spatial scale 
- [x] S curves in accordance with @PAPAGIANNIDIS2015308; @lengyel2020role
- contrary to results from future studies regarding social media
[@lengyel2020role], web technologies did not exclusively spread from a
central location. ???
- [ ] range of xmid, how small the differences are in speed across LAD?


