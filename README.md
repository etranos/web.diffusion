# web.diffusion

`data.prep.Rmd` takes all the data -- `all.csv` -- and splits it to yearly files.
It then brings MSOA code and aggregate per MSOA.
It counts how many unique pairs of url.no.date (urls without the timestamp) and 
pc exist in every MSOA per year. 
In other words, it provides the number of geo-referenced archived webpages per 
MSOA and year.

`data.prep.2011.2021.Rmd` does the same on the fly.
It downloads the $2011$-$2012$ data files, makes a `all2011_12.csv` file, which is
similar to `all.csv` and then aggregates at the MOSA level:
as per the above, it provides the number of geo-referenced archived webpages per 
MSOA and year.

`diffusion.Rmd` loads the above data, does a yearly line graph, makes and maps time-series
clusters, yearly LISA and choropleth maps for **all** the geo-referenced webpages
per MSOA.
The clusters are not really interpretable.
No visible patterns regarding spatial dependency.
Potential explanation: the use of **all* the data.


 