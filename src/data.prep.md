---
title: "data.prep"
date: "03 September, 2021, 18:14"
output: 
  html_document:
    df_print: paged
    toc: true
    toc_float: true
knit: (function(inputFile, encoding) {
    rmarkdown::render(inputFile, encoding = encoding, output_dir = "../output")
  })
---



The internet archive data is saved on /hdd


```r
data.folder <- "/hdd/internet_archive/archive/data/"
data.path <- paste0(data.folder, "all.csv")

all <- fread(data.path)
```

```
## System errno 22 unmapping file: Invalid argument
```

```
## Error in fread(data.path): Opened 73.8GB (79286660455 bytes) file ok but could not memory map it. This is a 64bit process. There is probably not enough contiguous virtual memory available.
```

```r
#glimpse(all)
unique(all$year)
```

```
## Error in all$year: object of type 'builtin' is not subsettable
```

```r
all$id <- seq.int(nrow(all))
```

```
## Error in all$id <- seq.int(nrow(all)): object of type 'builtin' is not subsettable
```

```r
# for test at the end
test.all <- dim(all[1])
```

```
## Error in all[1]: object of type 'builtin' is not subsettable
```

```r
# data.path_ <- paste0(data.folder, "all_sample.csv")
# all_ <-fread(data.path_)
```

Postcode lookup.

[source](https://geoportal.statistics.gov.uk/datasets/postcode-to-output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-august-2021-lookup-in-the-uk/about)


```r
path.lookup <- paste0(path,"/data/raw/PCD_OA_LSOA_MSOA_LAD_AUG21_UK_LU.csv")
lookup <- fread(path.lookup)
#glimpse(lookup)
```
Merge


```r
setkey(lookup, pcds)
setkey(all, pc)
```

```
## Error in setkeyv(x, cols, verbose = verbose, physical = physical): x is not a data.table
```

```r
all.msoa <- lookup[all]
```

```
## Error in `[.data.table`(lookup, all): i has evaluated to type builtin. Expecting logical, integer or double.
```

```r
sapply(all.msoa, function(x) sum(is.na(x)))
```

```
## Error in lapply(X = X, FUN = FUN, ...): object 'all.msoa' not found
```

The next snippet drops URLS from the same host referring to same postcode, which
were observed more than once per year. 
In other words, it drops URLs, which were archived multiple times per year.


```r
all.msoa <- unique(all.msoa, by = c("host", "year", "pcds"))
```

```
## Error in unique(all.msoa, by = c("host", "year", "pcds")): object 'all.msoa' not found
```

Aggregate


```r
msoa <- all.msoa[, .(count.url=.N), by = .(year, msoa11cd)]
```

```
## Error in eval(expr, envir, enclos): object 'all.msoa' not found
```

Test to see if i have missed any of the original urls


```r
test.msoa <- sum(msoa$count.url)
```

```
## Error in eval(expr, envir, enclos): object 'msoa' not found
```

```r
ifelse(test.all==test.msoa, yes = "OK", no = "problem")
```

```
## Error in ifelse(test.all == test.msoa, yes = "OK", no = "problem"): object 'test.all' not found
```

```r
missing <- msoa[is.na(msoa$msoa11cd)]
```

```
## Error in eval(expr, envir, enclos): object 'msoa' not found
```

```r
print(sum(missing$count.url)) #
```

```
## Error in missing$count.url: object of type 'special' is not subsettable
```

Drop the observations without MSOA code


```r
msoa <- msoa[!is.na(msoa11cd)]
```

```
## Error in eval(expr, envir, enclos): object 'msoa' not found
```

Export


```r
path.out <- paste0(path, "/data/temp/msoa.csv")
fwrite(msoa, path.out) # for all obs
```

```
## Error in fwrite(msoa, path.out): object 'msoa' not found
```
