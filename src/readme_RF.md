## Running the RF models

The RStudio Server was hanging in running the OA RF models, both the ones with
all the data and the ones with the hold-out regions. I converted the .Rmd files
to .R files using the below then and ran them in the terminal. The models ran 
successfully. 

`knitr::purl(input = "src/oa_RF_corrected_10.Rmd", documentation = 2, output = "src/oa_RF_corrected_10.R")`