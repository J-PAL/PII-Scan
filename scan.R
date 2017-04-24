# Activate the `foreign` library
library(foreign)

# Activate the `readstata13` library to read Stata dta-file that only works in version 13 and 14
library(readstata13)

# Activate the read.sas7bdat library
library(sas7bdat)

# Activate the optparse library for using command line options/arguments
library("optparse")

# Set command line options
option_list = list(
  make_option(c("-p", "--path"), type="character", default=NULL,
              help="search path", metavar="character")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

# Make sure path is set
if (is.null(opt$path)){
  print_help(opt_parser)
  stop("A search path must be specified.", call.=FALSE)
}

# Set path
path = opt$path

# Create prinf function
printf <- function(...) cat(sprintf(...))

# Strings to look for in variable names
pii_strings_names <- c("name", "fname", "lname", "first_name", "last_name")
pii_strings_dates <- c("birth", "birthday", "bday")
pii_strings_locations <- c("district", "country", "subcountry", "parish", "lc", "village", "community", "address", "gps", "lat", "log", "coord", "location", "house", "compound")
pii_strings_other <- c("school", "social", "network", "census", "gender", "sex", "fax", "email", "url", "child")
# removed "ip"

# Create single list of all strings, removing duplicates
pii_strings <- unique(c(pii_strings_names, pii_strings_dates, pii_strings_locations, pii_strings_other))

# Change to path
setwd(path)

# Get list of Stata files (.dta) to scan for PII
files = list.files(path = ".", pattern = "\\.dta$", recursive = TRUE)

# Initialize output csv
cat("file,var,varlabel,samp1,samp2,samp3,samp4,samp5",file="PII_output.csv",sep="\n",append=FALSE)

# Loop over files
for ( file in files ) {

  # Clear PII status
  PII_Found <- FALSE

  # Open file, ignore missing value labels.
  tryCatch(
    {
      data <- read.dta13(file, missing.type = FALSE)
    },
    error=function(cond) {
      data <- read.dta(file, warn.missing.labels = FALSE)
      return(NA)
    }
    )

    # Get variable labels and initialize variable count
    var.labels <- attr(data,"var.labels")
    v<-0

  # Loop over variable names in file
  for ( var in names( data )) {
    FOUND <- FALSE
     for ( string in pii_strings) {
     if (grepl(string, var)) {
        FOUND <- TRUE
      }
     }

     # Create in-loop variable that contains varlabel information, add 1 to variable count
     v<-v+1
     varlab<-var.labels[v]

    #if (length(grep(var,pii_strings))>0) {
    #	FOUND<- TRUE
    #}
    # Check to see if variable name mataches our susspect list
    if ( FOUND) {

      # Set PII status
      if ( !PII_Found) {
        PII_Found <- TRUE
        printf("Possible PII found in %s:\n", file)
      }

      # Print warning, and first five data values
      printf("\tPossible PII in variable \"%s\":\n", var)

      # Print first five values
      for ( i in 1:5 ) {
        printf("\t\tRow %d value: %s\n", i, data[i,var])
      } # for ( i in 1:5 )

      # Print newline for readability
      printf("\n")

      # Write to csv file
      cat(paste (file,var,varlab,data[1,var],data[2,var],data[3,var],data[4,var],
      data[5,var], sep = ",", collapse = NULL),file="PII_output.csv",sep="\n",append=TRUE)

    } # if ( var %in% pii_strings )
  } # for ( var in names( data ))
} # for ( file in files )


# Get list of SAS files (.sas7bdat) to scan for PII
files2 = list.files(path = ".", pattern = "\\.sas7bdat$", recursive = TRUE)

# Loop over files
for ( file in files2 ) {

  # Read data and get data attributes. Slightly more complicated than stata
  data <- read.sas7bdat(file)
  data_attr<-attributes(data)

  # Clear PII status
  PII_Found <- FALSE

  # Initialize variable count
  v<-0

  # Loop over variable names in file
  for ( var in names( data )) {
    FOUND <- FALSE
    for ( string in pii_strings) {
      if (grepl(string, var)) {
        FOUND <- TRUE
      }
    }

     # Create in-loop variable that contains varlabel information, add 1 to variable count
     v<-v+1
     varlab<-data_attr$column.info[[v]]$label

    # Check to see if variable name mataches our susspect list
    if ( FOUND) {

      # Set PII status
      if ( !PII_Found) {
        PII_Found <- TRUE
        printf("Possible PII found in %s:\n", file)
      }

      # Get variable label
      data_attr$column.info[[v]]$label

      # Print warning, and first five data values
      printf("\tPossible PII in variable \"%s\":\n", var)

      # Print first five values
      for ( i in 1:5 ) {
        printf("\t\tRow %d value: %s\n", i, data[i,var])
      } # for ( i in 1:5 )

      # Print newline for readability
      printf("\n")

            # Write to csv file
      cat(paste (file,var,varlab,data[1,var],data[2,var],data[3,var],data[4,var],
      data[5,var], sep = ",", collapse = NULL),file="PII_output.csv",sep="\n",append=TRUE)

    } # if ( var %in% pii_strings )
  } # for ( var in names( data ))
} # for ( file in files2 )
