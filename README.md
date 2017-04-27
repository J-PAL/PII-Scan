## Synopsis

Scan.R searches Stata .dta, SAS, and .csv files for variables that may contain personally identifiable information (PII). It uses a vector of strings that commonly appear as part of variable names or labels that contain PII. (Note: Scan.r does not search labels in .csv files.) Scan.r searches all .dta, SAS, and .csv files in the specified folder and outputs an excel spreadsheet of variables and data flagged as potential PII.

## Instructions

To execute the script, type the following in the command line, "Rscript scan.R --path=[Target]", replacing [Target] with the folder containing your data. An excel spreadsheet titled "PII_output" will be saved in the target folder for your review.

## Motivation

The script was written to quickly audit data files for personally identifiable information. It provides a solution to searching a large number of files in a particular directory or searching files that contain a large number of variables. However, it does not fully replace manual detection of PII. 

## Required Libraries

readstata13 and foreign libraries required.

## License

See license file.
