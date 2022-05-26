## Spatial diffusion of web adoption in the UK

searched for terms:
- technology diffusion model spatial

### Shapiro and Mandelman 2021
[Digital adoption, automation, and labor markets in developing countries](https://www.sciencedirect.com/science/article/pii/S0304387821000353)

Some useful stylised facts.
A generative model, not useful

### Leibowicz et al. 2016
[Representing spatial technology diffusion in an energy system optimization model](https://www.sciencedirect.com/science/article/pii/S0040162515001675)

**Very useful review**: 1.4. Technology diffusion: Historical evidence

"An illustrative empirically based theory for technology diffusion across multiple regions is suggested by “Schmidt's Law” (Grubler, 1990). With respect to a specific technology, it divides regions into three groups: core, rim, and periphery. "
...

### Comin and Hobijn 2010, AER
[An Exploration of Technology Diffusion](https://www.aeaweb.org/articles?id=10.1257/aer.100.5.2031)

deviation from average adoption lag for t per country and technology.

Some literature on " Measures of diffusion"

### Yum and  Kwan 2016
[FDI technology spillovers, geography, and spatial diffusion](https://www.sciencedirect.com/science/article/pii/S1059056016000307)

Spatial panel, GMM with explanatory variables

### Ding , Haynes and Li 2010
[Modeling the Spatial Diffusion of Mobile Telecommunications in China](https://www.tandfonline.com/doi/pdf/10.1080/00330120903546528?needAccess=true)

The closest paper I found.

Very useful literature on Technological Diffusion

Logistic curve, determinants of mobile adoption

### Bento et al 2018

[Time to get ready: Conceptualizing the temporal and spatial dynamics of formative phases for energy technologies](https://www.sciencedirect.com/science/article/pii/S0301421518302313#bib65)

Spatial diffusion literature

### Perkins and Neumayer 2005

[The International Diffusion of New Technologies: A Multitechnology Analysis of Latecomer Advantage and Global Economic Integration](https://doi.org/10.1111/j.1467-8306.2005.00487.x)

Spatial diffusion with explanatory variables

semi-parametric methods: [Cox (1975)](https://www.tandfonline.com/doi/full/10.1111/j.1467-8306.2005.00487.x?needAccess=true#) proportional hazards model

good literature

## [New technology in the region – agglomeration and absorptive capacity effects on laser technology research in West Germany, 1960–2005](https://www.tandfonline.com/doi/full/10.1080/10438599.2014.897861?needAccess=true)

[or](https://www.researchgate.net/publication/273403285_New_technology_in_the_region_-_agglomeration_and_absorptive_capacity_effects_on_laser_technology_research_in_West_Germany_1960-2005)

- cox regressions + panel regressions, useful methodology

### Fadly and Fontes 2019

[Geographical proximity and renewable energy diffusion: An empirical approach](https://www.sciencedirect.com/science/article/pii/S030142151930117X)

Literature: Empirical evidence on the link between diffusion and geography

**NOT USED**

### Meade and Islam 2021, Telecommunications Policy

[Modelling and forecasting national introduction times for successive generations of mobile telephony](https://www.sciencedirect.com/science/article/pii/S0308596120301786)

Two modelling approaches:

- Cox model
- k-means for early/late comers and then multinomial

## [Measuring the diffusion of an innovation: A citation analysis](https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/asi.23898)
- literature review on diffusion of innovation
**NOT USED**

## [Modeling Diffusion Processes](https://www.sciencedirect.com/science/article/pii/B0123693985003455)
Cliff and Haggett
- differences between diffusion vs. survival models
- details about logistic model
**NOT USED**

## Next steps

### Data preparation

- decide time period and spatial scale

- MSOA? see CEUS data. Are there enough explanatory variables? Think of distances and location variables on top of pop. density and businesses.

- check prior to 2000

- decide on variable: net or density


### Exploratory
1. plot data for all the country
2. plot data for MSOA
3. timeseries clustering to find groups which experience same growth patterns
4. spatial autocorrelation of the adoption

### Modelling

1. Deviation from average adoption. lag for t per country and technology as per Comin and Hobijn 2010, AER
2. Spatial panel, GMM with explanatory variables
3. Logistic curve, determinants of adoption as per Ding , Haynes and Li 2010
4. Spatial diffusion with explanatory variables -- Cox model aka survival models -- as per Perkins and Neumayer (2005) and Meade and Islam (2021)
5. [spBayesSurv](https://cran.r-project.org/web/packages/spBayesSurv/index.html) for Bayesian survival models for spatial/non-spatial survival data. This is what [Bednarz](https://dspace.library.uu.nl/handle/1874/398470) used. I need to read/understand this better.
