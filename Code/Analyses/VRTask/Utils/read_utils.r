
# Author         : Aleksander Molak
# Date           : May 4, 2019

###############################################################################
#                                                                             #
# This file contains a set of functions for reading and transforming the data #
#                                                                             #
###############################################################################

library(dplyr)
library(openxlsx)
library(tidyr)


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


filter_data <- function(df, part='main') {
  
  # To get the rows relevant to the further analysis we filter the data 
  # according to the original criteria from `VRCC_behav_pilots.Rmd`
  
  if (part == 'main') {
    df %>% filter(Phase == "Estimation" & 
                  Round > 0) -> out
  }
  else if (part == 'training') {
    df %>% filter(Phase == "Estimation" & 
                  Round == 0 &
                  Training == "True") -> out
  }
  else {
    stop("Invalid argument for 'part'; must be 'main' or 'training'.")
  }
  
  return(out)
}

#---------------------------------------------------------------------------------------#

build_dataset <- function(path, part='main') {
  
  # To get the full dataset we iterate over folders, read, transform and concatenate the data
  
  folders <- get_folders(path)
  
  tables  <- list()
  
  for (i in seq_along(folders)) {
    
    df <- get_single_table(file.path(path, folders[i]))
    df <- filter_data(df, part=part)
    ifelse(df$ID == "S41" |  df$ID == "S44" | df$ID == "S11" , 
           df$PhaseLenght <- as.double(levels(df$PhaseLenght))[df$PhaseLenght], 
           df$PhaseLenght <- as.numeric(df$PhaseLenght))  # participant-specific adjustment: for 3 subjects PhaseLenght column was saved as integer value

    ## FK: the following produced issues in my setup -> replacing all values for 3 subjects with NA
    ##     I therefore replaced it by the simpler and (at least for me) more stable version:
    ifelse(df$EstimatedIDstance == "factor", 
           df$EstimatedDistance <- as.double(levels(df$EstimatedDistance))[df$EstimatedDistance], 
           df$EstimatedDistance <- as.numeric(df$EstimatedDistance))
    df$EstimatedDistance <- as.numeric(df$EstimatedDistance)
    # ifelse(df$ID == "S09" |  df$ID == "S18" | df$ID == "S22" | df$ID == "S36", 
    #        df$EstimatedDistance <- as.double(levels(df$EstimatedDistance))[df$EstimatedDistance],  
    #        df$EstimatedDistance <- as.numeric(df$EstimatedDistance)) # for 4 subjects EstimatedDistance column was saved as char value
    tables[i] <- list(df)
    
  }
  
  bind_rows(tables)   
  
}



get_questnr_data <- function(qstnr_filepath, sess_info_folder) {
  
  # Gets and joins questionnaire data and animal information
  
  all_sheets = getSheetNames(qstnr_filepath)
  
  final_df = data.frame()
  
  for (subject in all_sheets) {

    if (startsWith(subject, 'S')) {
      
      # Get session info paths
      sess_info_pattern = paste0(subject, '_RatingLog_')
      sess_info_file = list.files(file.path(sess_info_folder, subject), pattern = sess_info_pattern)
      sess_info_path = file.path(sess_info_folder, subject, sess_info_file)
      
      if (length(sess_info_path) > 0) {
        # cat('Reading session info for subject', subject, 'from:', sess_info_path, '\n')
        
        # Read-in the neccessary files
        qstnr_file = read.xlsx(qstnr_filepath, sheet = subject)
        sess_info_data = read.table(sess_info_path,
                                    skip      = 7,
                                    sep       = ";",
                                    row.names = NULL)
        
        # Read colnames for sess_info_data -> needed because of a data artifact
        sess_info_colnames = gsub(' ', '', scan(sess_info_path, 
                                                sep  = ';', 
                                                what = '', 
                                                n    = 6, 
                                                skip = 6))
        
        
        sess_info_data = sess_info_data %>% select(-7) 
        colnames(sess_info_data) = sess_info_colnames
        
        # Get and fill round information
        round_info = qstnr_file %>% tidyr::fill(Animal) %>% select(Animal)
        qstnr_file$round_info = round_info
        
        # Filter and join the data
        sheet_cleaned = qstnr_file %>% filter(is.na(Animal))
        
        # Check dimensions
        if (dim(sheet_cleaned)[1] != dim(sess_info_data)[1]) {
          cat('\n!!! WARNING! Ignoring', subject, 'due to dimension mismatch! !!!\n\n')
          warning('Dimension mismatch for ', subject, '.\n  !!! `sess_info_data` has ', dim(sess_info_data)[1], ' rows, while questionnaire data has ', dim(sheet_cleaned)[1], ' rows. !!!\n')
          next
        }
        
        # Add info from session info
        sheet_cleaned$Animal = sess_info_data$PresentedAnimal
        sheet_cleaned$subject = subject
        sheet_cleaned$rating_flag = sess_info_data$ratingFlag
        sheet_cleaned$fear_object = sess_info_data$FearObject
        sheet_cleaned$big_object = sess_info_data$BigObject
        sheet_cleaned$Vision.Assesment = sheet_cleaned$Vision.Assesment[1]
        
        # Clean colnames
        colnames(sheet_cleaned) = gsub('\\.', '_', tolower(colnames(sheet_cleaned)))
        
        # Remove notes if exist
        sheet_cleaned = sheet_cleaned %>% select(!contains("notes"))
        
        final_df = bind_rows(final_df, sheet_cleaned)
        
      } else {
        
        cat('\n!!! WARNING! No session data available for subject', subject, ' !!!\n\n')
        warning('!!! No session info available for subject ', subject, ' !!!\n')
        
      }
      
    }
    
  }
  
  
  final_df
  
}



