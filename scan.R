# List of required packages
#   optparse: command line options/arguments
#   rio: load files as data frame
#   tools: extract file extension
packages = c("dplyr",
             "purrr",
             "optparse",
             "rio",
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
    c("-q", "--quiet"),
    type = "logical",
    action="store_true",
    default = FALSE,
    help = "Silent operation; do not display possible PII to the screen"
  ),
  make_option(
    "--no-output",
    dest = "nooutput",
    type = "logical",
    action="store_true",
    default = FALSE,
    help = "Do not output search results to csv file"
  ),
  make_option(
    c("-o", "--output-file"),
    dest = "outputfile",
    type = "character",
    default = "PII_output.csv",
    metavar = "FILE",
    help = "Write csv of possible PII to FILE [default: %default]"
  ),
  make_option(
    c("-s", "--strict"),
    type = "logical",
    action="store_true",
    default = FALSE,
    help = "Use stric matching when comparing strings. For example, match 'lat' but not 'latin'"
  ),
  make_option(
    c("-nl", "--nolabels"),
    type = "logical",
    dest = "noscanlables",
    action="store_true",
    default = FALSE,
    help = "Do not scan variable labels when checking for PII"
  )
)

opt_parser = OptionParser(usage = "usage: %prog --path PATH [options]", option_list = option_list)

opt = parse_args(opt_parser)

# Make sure path is give as option
if (is.null(opt$path)) {
  print_help(opt_parser)
  stop("A search path must be specified.", call. = FALSE)
}

# Make sure path is for a directory
if (!dir.exists(opt$path)) {
  stop("Path must secify a directory.", call. = FALSE)
}

# Set path
path = opt$path

# Set options
strict = opt$strict
quiet = opt$quiet
outputCSV = !opt$nooutput
outputfile = opt$outputfile
no_scan_lables = opt$noscanlables

# Set PII status
PII_Found <- FALSE

# Create prinf function
printf <- function(...)
  cat(sprintf(...))

# Strings to look for in variable names
pii_strings_names <-
  c("name", "fname", "lname", "first_name", "last_name")
pii_strings_dates <- c("birth", "birthday", "bday", "dob")
pii_strings_locations <-
  c(
    "district",
    "city",
    "country",
    "subcountry",
    "parish",
    "loc",
    "street",
    "village",
    "community",
    "address",
    "gps",
    "degree",
    "minute",
    "second",
    "lat",
    "lon",
    "coord",
    "location",
    "house",
    "compound",
    "panchayat",
    "territory",
    "municipality",
    "precinct",
    "block",
    "zip"
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
    "husband",
    "phone",
    "spouse",
    "daughter",
    "son"
  )

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
if (outputCSV) {
  # Create data frame to hold PII matches
  csv_headers <-
    data.frame(
      "file" = character(0),
      "var" = character(0),
      "varlabel" = character(0),
      "samp1" = character(0),
      "samp2" = character(0),
      "samp3" = character(0),
      "samp4" = character(0),
      "samp5" = character(0)
    )
  write.csv(csv_headers, file = outputfile, quote=FALSE, row.names = FALSE)
}

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
  
  # Read file using rio
  data <- import(file)
  
  # Move variable-level attributes to the data frame level
  gather_attrs(data)
  
  # Loop over variable names in file
  for (varname in names(data)) {
    varlabel <- attr(data[[varname]],"label")
    FOUND <- FALSE
    
    # Variable count for var.labels index
    v <- v + 1
    
    for (string in pii_strings) {
      
      # Match on word boundary if strict
      if (strict) {
        string <- paste("\b",string,"\b")
      }
      
      # Compare string to var, ignoring case
      if (grepl(string, varname, ignore.case = TRUE)) {
        FOUND <- TRUE
      } else if ((!is.null(varlabel)) & !(no_scan_lables)) {
        # If no possible PII found in variable name, check label, ignoring case
        if (grepl(string, varlabel, ignore.case = TRUE)) {
          FOUND <- TRUE
        }
      }
    }
    
    if (FOUND) {
      PII_Found <- TRUE
      if (!quiet) printf("Possible PII found in %s:\n", file)
      
      # Print warning and first five non-missing, unique values:
      if (!quiet) {
        if (is.null(varlabel)) {
          message <- paste("\"",varname,"\"",sep="")
        } else {
          message <- paste("\"",varname,"\" with label \"",varlabel,"\"", sep="")
        }
        printf("\tPossible PII in variable %s:\n", message)
      }
      
      #Select the current variable column:
      data_col <- data[varname]
      
      #Update the column to be character values:
      data_col[varname] <- as.character(data_col[[varname]])
      
      #Select just the current variable:
      var_only <- data_col[varname]
      
      #Select unique values of the variable:
      var_unique <- unique(var_only)
      
      #Remove NA values from vector (will only paste NA values if there are fewer than 5 unique, non-missing values)
      var_unique_nona <- na.omit(var_unique)
      
      # Print first five values
      for (i in 1:5) {
        if ((!quiet) & (!is.null(var_unique_nona[i,1])) & (!is.na(var_unique_nona[i,1]))) {
          printf("\t\tSamp %d value: %s\n", i, var_unique_nona[i,1])
        }
      } # for ( i in 1:5 )
      
      # Print newline for readability
      if (!quiet) printf("\n")
      
      # Write to csv file
      if (outputCSV) {
        # Create data frame without row names
        new_row <- data_frame(
          file = paste(file),
          var = paste(varname),
          varlabel = paste( if (is.null(varlabel)) "" else varlabel),
          samp1 = paste(var_unique_nona[1,1]),
          samp2 = paste(var_unique_nona[2,1]),
          samp3 = paste(var_unique_nona[3,1]),
          samp4 = paste(var_unique_nona[4,1]),
          samp5 = paste(var_unique_nona[5,1])
        )
        write.table(new_row, file=outputfile, quote=TRUE, append=TRUE, row.names=FALSE, col.names=FALSE,  sep=",")
      }
      
    } # if ( var %in% pii_strings )
  } # for ( var in names( data ))
} # for ( file in files )

if ( PII_Found ) {
  quit(save = "no", status = 10, runLast = FALSE)
} else {
  quit(save = "no", status = 0, runLast = FALSE)
}
