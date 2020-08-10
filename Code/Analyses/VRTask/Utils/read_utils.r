
# Author         : Aleksander Molak
# Date           : May 4, 2019

###############################################################################
#                                                                             #
# This file contains a set of functions for reading and transforming the data #
#                                                                             #
###############################################################################

library(dplyr)
library(openxlsx)


get_folders <- function(path, ignore = '_') {
  
  # We read files to get a list of all available data folders with participant's data (e.g. "S06", "S19")
  
  folders = list.files(path)
  
  folders_ready = list()
  
  j = 1
  
  # The code below removes folders which have names starting with `ignore` string.
  # This lets the script to work in an uninterupted manner without removeing `_problematic` folder from 
  # the data folder
  
  if (!is.null(ignore)) {
    
    warning('\nWARNING: get_folders() set to ignore folders starting with ', ignore, '\n\n')
    
    for (i in seq_along(folders)) {
      
      if (!startsWith(folders[i], ignore)) {
        
        folders_ready[j] = folders[i]
        j = j + 1
      }
    }
    
    folders_ready
    
  } else {
    
    folders
  }
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
    df$PhaseLenght <- as.numeric(df$PhaseLenght)    # There are some values that force type == factor
    df$EstimatedDistance <- as.numeric(df$EstimatedDistance)
    tables[i] <- list(df)
    
  }
  
  bind_rows(tables)   
  
}


read_questionnaire_data <- function(path, sheet = 'Aggregated Scores', filter_pilot = TRUE) {
  
  data <- readWorkbook(path, sheet = sheet)
  
  if (filter_pilot == TRUE) {
    data <- data %>% filter(SUBJECT != "PILOT")
    
  }
  
  data

}

