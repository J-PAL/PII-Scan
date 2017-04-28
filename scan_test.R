# List of required packages
#   foreign: Read Stata version 5 - 12 files
#   readstata13: Read Stata version 13 and 14 files
#   haven::read_dta Read Stata version 8 - 14 files
#   haven::read_sas Read SAS files (sas7bdat files and accompanying)
#   read.sas7bdat: Read SAS files
#   haven::read_sav Read SPSS files (sas7bdat files and accompanying)
#   data.table::fread Read csv files
#   readr::read_csv Read csv files
#   optparse: command line options/arguments
#   tools: extract file extension
packages = c("haven", "foreign", "data.table", "readr", "optparse", "tools")

# Suppress warnings
oldw <- getOption("warn")
options(warn = -1)

# Check for required packages
package.check <- lapply(
  packages,
  FUN = function(x) {
    if ((!require(x, character.only = TRUE, quietly = TRUE))) {
      stop("Package ", x, " not found and is required.", call. = FALSE)
    }
  }
)

# Un-suppress warnings
options(warn = oldw)

# Set command line options
option_list = list(
  make_option(
    c("-p", "--path"),
    type = "character",
    default = NULL,
    help = "Path to search for PII",
    metavar = "PATH"
  )
)

opt_parser = OptionParser(usage = "usage: %prog --path PATH [options]", option_list = option_list)

opt = parse_args(opt_parser)


# Make sure path is give as option
if (is.null(opt$path)) {
  print_help(opt_parser)
  stop("A search path must be specified.", call. = FALSE)
}

# Set path
path = opt$path

# Create prinf function
printf <- function(...)
  cat(sprintf(...))

# Strings to look for in variable names
pii_strings_names <-
  c("name", "fname", "lname", "first_name", "last_name")
pii_strings_dates <- c("birth", "birthday", "bday")
pii_strings_locations <-
  c(
    "district",
    "country",
    "subcountry",
    "parish",
    "lc",
    "village",
    "community",
    "address",
    "gps",
    "lat",
    "log",
    "coord",
    "location",
    "house",
    "compound"
  )
pii_strings_other <-
  c(
    "school",
    "social",
    "network",
    "census",
    "gender",
    "sex",
    "fax",
    "email",
    "url",
    "child"
  )
# removed "ip"

# Create single list of all strings, removing duplicates
pii_strings <-
  unique(c(
    pii_strings_names,
    pii_strings_dates,
    pii_strings_locations,
    pii_strings_other
  ))


# Get list of files (.dta, .sas7bdat, .sav, and .csv) to scan for PII
files = list.files(path,
                   pattern = "\\.dta$|\\.sas7bdat$|\\.csv$",
                   recursive = TRUE)

# Initialize output csv
cat(
  "file,var,varlabel,samp1,samp2,samp3,samp4,samp5",
  file = "PII_output.csv",
  sep = "\n",
  append = FALSE
)

# Loop over files
for (file in files) {
  # Clear PII status
  PII_Found <- FALSE
  
  # Initialize variable count
  v <- 0
  
  # Create full path to file
  file <- file.path(path,file)
  
  # Get absolute path to file for cleaner output
  file <- normalizePath(file)
  
  # Get file type
  type <- file_ext(file)
  
  # Use correct read function to open file, ignore missing value labels.
  switch(type,
         
         # Open Stata files
         dta = {
           tryCatch({
             data <- haven::read_dta(file)
           },
           error = function(cond) {
             data <- foreign::read.dta(file, warn.missing.labels = FALSE)
             return(NA)
           })
           
           # Get variable labels
           var.labels <- attr(data, "var.labels")
         },
         
         # Open SAS files
         sas7bdat = {
           data <- haven::read_sas(file)
           data_attr <- attributes(data)
         },
         
         # Open SPSS files
         # sav = {
         #   data <- haven::read_spss(file)
         #   data_attr <- attributes(data)
         # },
         
         # Open CSV files
         csv = {
         	data <- readr::read_csv(file, col_names = TRUE)
         	# data <- data.table::fread(file, header=TRUE, sep="auto")
         },
         
         # Warn and exit about unknown file types
         {
           printf("Unknown file type %s: %s\n", type, file)
           # stop()
         })
  
  # Loop over variable names in file
  for (var in names(data)) {
    FOUND <- FALSE
    for (string in pii_strings) {
      if (grepl(string, var, ignore.case = TRUE)) {
        FOUND <- TRUE
      }
    }
    
    # Create in-loop variable that contains varlabel information, add 1 to variable count
    v <- v + 1
    switch(type,
           dta = {
             varlab <- var.labels[v]
           },
           sas7bdat = {
             varlab <- data_attr$column.info[[v]]$label
           },
           csv ={
           	 varlab <- "N/A"
           },
           {
             printf("Unknown file type %s: %s\n", type, file)
             stop()
           })
    
    if (FOUND) {
      # Set PII status
      if (!PII_Found) {
        PII_Found <- TRUE
        printf("Possible PII found in %s:\n", file)
      }
      
      # Get variable label
      if (type == 'sas7bdat') {
        data_attr$column.info[[v]]$label
      }
      
      # Print warning, and first five data values
      printf("\tPossible PII in variable \"%s\":\n", var)
      
      # Print first five values
      for (i in 1:5) {
        printf("\t\tRow %d value: %s\n", i, data[i, var])
      } # for ( i in 1:5 )
      
      # Print newline for readability
      printf("\n")
      
      # Write to csv file
      cat(
        paste (
          file,
          var,
          varlab,
          data[1, var],
          data[2, var],
          data[3, var],
          data[4, var],
          data[5, var],
          sep = ",",
          collapse = NULL
        ),
        file = "PII_output.csv",
        sep = "\n",
        append = TRUE
      )
      
    } # if ( var %in% pii_strings )
  } # for ( var in names( data ))
} # for ( file in files )
