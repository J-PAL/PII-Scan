## Synopsis

Scan.R searches Stata .dta files and SAS files for variables that may contain Personally-identifiable information (PII). It uses a vector of strings that commonly appear as part of variable names or labels that contain PII. Scan.r searches all .dta and SAS files in the specified folder and outputs an excel spreadsheet of variables and data flagged as potential PII (by .dta file).

## Instructions

To execute the script, type the following in the command line, "Rscript scan.R --path=[Target]", replacing [Target] with the folder containing your data. An excel spreadsheet titled "PII_output" will be saved in the target folder for your review.

## Motivation

The script was written to audit data files for personally identifiable information. 

## Required Libraries

readstata13 and foreign libraries required.

## License

See license file.