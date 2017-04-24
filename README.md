## Synopsis

Scan.r searches Stata .dta files for variables that may contain Personally-identifiable information (PII). It uses a vector of strings that commonly appear as part of variable names or labels that contain PII. Scan.r searches all .dta files in the specified folder and outputs an excel spreadsheet of variables and data flagged as potential PII (by .dta file).

## Instructions

To execute the script, paste the path of the folder containing the .dta files you would like to scan and run the script (line 27 in scan.r). An excel spreadsheet titled, "PII_output" will be saved in the target folder for your review.

## Motivation

This script was written to expedite the process of ensuring that PII has been removed from publically available datasets. 

## Required Libraries

readstata13 and foreign libraries required.

## License

See license file.