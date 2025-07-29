# A multi-scale story of the diffusion of a new technology: the Web

[Emmanouil Tranos](https://etranos.info/)

University of Bristol and The Alan Turing Institute, [e.tranos\@bristol.ac.uk](mailto:e.tranos@bristol.ac.uk), [etranos.info](https://etranos.info/)

To cite this article:

Tranos, E. (2025) A multi-scale story of the diffusion of a new technology: the Web, *Journal of Economic Geography*, [in press](https://academic.oup.com/joeg)

## Abstract

This paper investigates the spatial diffusion of a new technology that is the Web in the UK. It employs novel data and machine learning methods to model the influence of well-established diffusion mechanisms. Contrary to previous studies, it adopts multiple scales, high spatial granularity and a long study period that captures the early stages of the Web until its maturity (1996-2012). Findings reveal the importance of such spatial mechanisms (namely distance, urban hierarchy and the S-shaped pattern of the cumulative level of adoption) even at granular scales. They also highlight spatial heterogeneity and instances of leapfrogging.

## Data availability

The data used in this paper can be obtained from [https://doi.org/10.5281/zenodo.16575238](https://doi.org/10.5281/zenodo.16575238)
and has been derived from the [JISC UK Web Domain Dataset (1996-2013)](https://data.webarchive.org.uk/opendata/ukwa.ds.2/). 
DOI: [https://doi.org/10.5259/ukwa.ds.2/1](https://doi.org/10.5259/ukwa.ds.2/1)

## Reproduce the analysis

The different analyses of the paper can be represented as a 2x2 matrix:

|   | Local Authorities | Output Areas |
|------------------------------|-----------------------|-------------------|
| **Websites with one unique postcode** | Main body of the paper; `problem_years.Rmd`,`s_la_per_firm_corrected.Rmd`, `la_RF_corrected.Rmd` | Main body of the paper; `problem_years.Rmd`, `oa_RF_corrected.Rmd` |
| **Websites with up to 10 unique postcode** | Appendix (robustness check); ; `problem_years_10.Rmd`,`s_la_per_firm_corrected_10.Rmd`, `la_RF_corrected_10.Rmd` | Appendix (robustness check); `problem_years_10.Rmd`, `oa_RF_corrected_10.Rmd` |

The first step is the removal of some outliers (`problem_years.Rmd`) as described in Section 3. Then, the data are aggregated at the Local Authority (LA) and the Output Areas (OA) levels and the analysis is produced for both levels of aggregation including only commercial websites with one unique postcode (`problem_years.Rmd`,`s_la_per_firm_corrected.Rmd`, `la_RF_corrected.Rmd` and `problem_years.Rmd`, `oa_RF_corrected.Rmd` for LA and OA accordingly). Then, the analysis is repeated as a robustness check for both LA and OA for an extended sample of websites with up to 10 unique postcodes (`problem_years_10.Rmd`,`s_la_per_firm_corrected_10.Rmd`, `la_RF_corrected_10.Rmd` and `problem_years_10.Rmd`, `oa_RF_corrected_10.Rmd` for LA and OA accordingly).

Lastly, there is an extra layer of robustness checks regarding the outlier removal. Specifically, the predictive models are estimated for both LA and OA for the data inclusive the outiers (`la_RF.Rmd` and `oa_RF.Rmd`).

The `/submission4/tranos2025.qmd` file, which contains the text of the paper, uses inputs from all the `.Rmd` discussed here.
