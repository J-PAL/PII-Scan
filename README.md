## Synopsis

Scan.R searches all Stata (.dta), SAS (.sas7bdat), SPSS (.sav), and comma-separated values (.csv) files found in the specified directory for variables that may contain personally identifiable information (PII) using strings that commonly appear as part of variable names or labels that contain PII. (Note: Scan.R does not search labels in .csv files.) Results are displayed to the screen and saved to a comma-separated values file in the current working directory containing the variables and data flagged as potential PII.

## Instructions

To execute the script, type `Rscript scan.R --path=[Target]` into the command line, replacing [Target] with the folder containing the data to scan. An excel spreadsheet titled "PII_output" will be saved in the current working directory for your review.

##### Options
* `--quiet`: Silent operation; do not display possible PII to the screen
* `--no-output`: Do not output search results to CSV file
* `--output-file=output_filename.csv`: Write csv of possible PII to file "output_filename.csv" instead of "PII_output.csv"
* `--strict`: Use strict matching when comparing strings. For example, match "lat" but not "latin"
* `--nolabels`: Do not scan variable labels for PII search terms

## Requirements

* R must be installed on the local system. Installers can be downloaded at http://cran.us.r-project.org.
* The dplyr, purrr, optparse, rio and tools packages are required. To install missing packages, run install.packages("PACKAGE_NAME") where PACKAGE_NAME is the name of the package to install. Scan.R will warn if any of these packages are missing.

## Exit Codes
scan.R will exit with a value of 10 (ten) when possible PII is found or a value of 0 (zero) when no PII is identified.

## Motivation

The script was written to audit data files for personally identifiable information. It provides a solution to quickly searching a large number of files in a particular directory or searching files that contain a large number of variables. However, it does not fully replace manual detection of PII.

## Search Strings

scan.R searches variables and labels for the following strings:
 address, bday, beneficiary, birth, birthday, block, census, child, city, community, compound, coord, country, daughter, degree, district, dob, email, father, fax, first_name, fname, gender, gps, house, husband, last_name, lat, lname, loc, location, lon, minute, mother, municipality, name, network, panchayat, parish, phone, precinct, school, second, sex, social, spouse, son, street, subcountry, territory, url, village, wife, zip
 
 

## Support

Please use the [issue tracker](https://github.com/J-PAL/PII-Scan/issues) for all support requests.

## License

See [license file](LICENSE.txt).

## Thanks
Special thanks to IPA for their [How to Search Datasets for Personally Identifiable Information](http://www.poverty-action.org/sites/default/files/Guideline_How-to-Search-Datasets-for-PII.pdf) document which inspired this project.
