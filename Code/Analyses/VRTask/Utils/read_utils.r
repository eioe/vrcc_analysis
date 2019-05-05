
# Author         : Aleksander Molak
# Date           : May 4, 2019

###############################################################################
#                                                                             #
# This file contains a set of functions for reading and transforming the data #
#                                                                             #
###############################################################################



get_folders <- function(path) {
  
  # We read files to get a list of all available data folders with participant's data (e.g. "S06", "S19")
  
  list.files(path)
}

#---------------------------------------------------------------------------------------#

get_single_table <- function(path, 
                             pattern = "(PlayerLog).*\\.txt$") {
  
  # To get the data for a single participant we read-in and transform the data
  
  in_file <- list.files(path, 
                        pattern = pattern)
  
  filepath <- file.path(path, in_file)
    
    
  # In this read.table() call we deal with an artifact of data collection - 
  # an extra semicolon at the end of each data row (but not header). 
  # read.table() interprets the extra semicolon as an indicator that an extra col exists. 
  # That's why we need to use the scan() part - to manually adjust column names, 
  # preventing read_table() to interpret `Timestamp` column as `row.names`.
    
  df <- read.table(filepath,
                   skip      = 7,
                   header    = F,
                   sep       = ";",
                   row.names = NULL,
                   na.string = "-1.0000",
                   col.names = c(scan(filepath,
                                      what = "",
                                      sep  = ";",
                                      n    = 18,
                                      skip = 6),
                                 "!col_to_remove"))[-19]    # Beacuse of the data artifact we add this column 
                                                            # to make # of cols consistent 

    
  # To make subjects identifiable we add ID to the table
  
  df$ID <- substr(in_file, 1, 3)
  
  df
}

#---------------------------------------------------------------------------------------#


filter_data <- function(df) {
  
  # To get the rows relevant to the further analysis we filter the data 
  # according to the original criteria from `VRCC_behav_pilots.Rmd`
  
  df %>% filter(Phase == "Estimation" & 
                Training == "False" & 
                Round > 0)
}

#---------------------------------------------------------------------------------------#

build_dataset <- function(path) {
  
  # To get the full dataset we iterate over folders, read, transform and concatenate the data
  
  folders <- get_folders(path)
  
  tables  <- list()
  
  for (i in seq_along(folders)) {
    
    df <- get_single_table(file.path(path, folders[i]))
    df <- filter_data(df)
    
    tables[i] <- list(df)
  }
  
  bind_rows(tables)
  
}

