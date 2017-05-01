# List of required packages
#   foreign: Read Stata version 5 - 12 files
#   haven::read_dta Read Stata version 8 - 14 files
#   haven::read_sas Read SAS files (sas7bdat files and accompanying)
#   haven::read_sav Read SPSS files (sas7bdat files and accompanying)
#   readr::read_csv Read csv files
#   optparse: command line options/arguments
#   tools: extract file extension
packages = c("haven",
             "foreign",
             "readr",
             "dplyr",
             "purrr",
             "optparse",
             "tools")

# Suppress warnings
oldw <- getOption("warn")
options(warn = -1)

# Check for required packages
package.check <- lapply(
  packages,
  FUN = function(x) {
    if ((!require(x, character.only = TRUE, quietly = TRUE, 
                  warn.conflicts = FALSE))) {
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
  ),
  make_option(
    c("-s", "--strict"),
    type = "logical",
    action="store_true",
    default = FALSE,
    help = "Use stric matching when comparing strings. For example, match 'lat' but not 'latin'."
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

# Set strict
strict = opt$strict

# Set PII status
PII_Found <- FALSE

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
    "compound",
    "panchayat"

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
    "child",
    "beneficiary",
    "mother",
    "wife",
    "father",
    "husband"
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


# Get list of files (.dta or .sas7bdat) to scan for PII
files = list.files(path,
                   pattern = "\\.dta$|\\.sas7bdat$|\\.sav$|\\.csv$",
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
             cols <- attr(data, "names")
             var.labels <- data %>%
               map_at(cols, attr, "label")
           },
           error = function(cond) {
             data <- foreign::read.dta(file, warn.missing.labels = FALSE)
             cols <- attr(data, "names")
             var.labels <- attr(data, "var.labels")
             return(NA)
           })
           
         },

         # Open SAS files
         sas7bdat = {
           data <- haven::read_sas(file)
           cols <- attr(data, "names")
           var.labels <- cols
         },

         # Open SPSS files
         sav = {
           data <- haven::read_spss(file)
           cols <- attr(data, "names")
           var.labels <- data %>%
             map_at(cols, attr, "label")
         },

         # Open CSV files
         csv = {
           data <- readr::read_csv(file, col_names = TRUE, col_types = cols())
           cols <- attr(data, "names")
           var.labels <- cols
         },

         # Warn and exit about unknown file types
         {
           printf("Unknown file type %s: %s\n", ext, file)
           stop()
         })

  # Loop over variable names in file
  for (var in names(data)) {
    FOUND <- FALSE
    for (string in pii_strings) {
      
      # Match on word boundary if strict
      if (strict) {
        string <- paste("\b",string,"\b")
      }
      
      # Compare string to var, ignoring case
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
             varlab <- var.labels[v]
           },
           sav = {
             varlab <- var.labels[v]
           },
           csv ={
           	 varlab <- var.labels[v]
           },
           {
             printf("Unknown file type %s: %s\n", ext, file)
             stop()
           })

    if (FOUND) {
      PII_Found <- TRUE
      printf("Possible PII found in %s:\n", file)

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

if ( PII_Found ) {
  quit(save = "no", status = 10, runLast = FALSE)
} else {
  quit(save = "no", status = 0, runLast = FALSE)
}
