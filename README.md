## Synopsis

Scan.R searches all Stata (.dta), SAS (.sas7bdat), and comma-separated values (.csv) files found in the specified diectory for variables that may contain personally identifiable information (PII) using strings that commonly appear as part of variable names or labels that contain PII. (Note: Scan.R does not search labels in .csv files.) Results are displayed to the screen and saved to a comma-separated values file in the current working directory containing the variables and data flagged as potential PII.

## Instructions

To execute the script, type the following in the command line, "Rscript scan.R --path=[Target]", replacing [Target] with the folder containing the data to scan. An excel spreadsheet titled "PII_output" will be saved in the current working directory for your review.

## Requirements

* R must be installed on the local system. Installers can be downloaded at http://cran.us.r-project.org.
* The haven, foreign, readr, dplyr, readstata13, purrr, optparse and tools packages are required. To install missing packages, run install.packages("PACKAGE_NAME") where PACKAGE_NAME is the name of the package to install. Scan.R will warn if any of these packages are missing.

## Motivation

The script was written to audit data files for personally identifiable information. It provides a solution to quickly searching a large number of files in a particular directory or searching files that contain a large number of variables. However, it does not fully replace manual detection of PII.

## Search Strings

scan.R searches variables and labels for the following strings:
* name
* fname
* lname
* first_name
* last_name
* birth
* birthday
* bday
* district
* country
* subcountry
* parish
* lc
* village
* community
* address
* gps
* lat
* log
* coord
* location
* house
* compound
* school
* social
* network
* census
* gender
* sex
* fax
* email
* url
* child

## Support

Please use the [issue tracker](https://github.com/J-PAL/PII-Scan/issues) for all support requests.

## License

See license file.

## Thanks
Special thanks to IPA for their [How to Search Datasets for Personally Identifiable Information](http://www.poverty-action.org/sites/default/files/Guideline_How-to-Search-Datasets-for-PII.pdf) document which inspired this project.

