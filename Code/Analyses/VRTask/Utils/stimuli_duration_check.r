
library(dplyr)
library(openxlsx)

data_dir <- here("Data/VRTask/Logfiles/ExpSubjects")

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
  
  df %>% filter(Phase == "Stimuli" & 
                  Round > 0)
}

#---------------------------------------------------------------------------------------#

build_dataset <- function(path) {
  
  # To get the full dataset we iterate over folders, read, transform and concatenate the data

  folders <- get_folders(path)
  
  tables  <- list()
  
  for (i in seq_along(folders)) {
    print(i)
    
    df <- get_single_table(file.path(path, folders[i]))
    df <- filter_data(df)
    ifelse(df$ID == "S41" |  df$ID == "S44" | df$ID == "S11" , df$PhaseLenght <- as.double(levels(df$PhaseLenght))[df$PhaseLenght],  df$PhaseLenght <- as.numeric(df$PhaseLenght))
    ifelse(df$ID == "S09" |  df$ID == "S18" | df$ID == "S22" | df$ID == "S36", df$EstimatedDistance <- as.double(levels(df$EstimatedDistance))[df$EstimatedDistance],  df$EstimatedDistance <- as.numeric(df$EstimatedDistance))
    tables[i] <- list(df)
    
  }
  
  bind_rows(tables)   
  
}

# Checking whether duration of stimuli presentation equaled ~100 ms in each trial
data_check <- build_dataset(data_dir)

# Explore the data
plot(data_check$PhaseLenght)
hist(data_check$PhaseLenght, xlim = c(0.07,0.13), breaks = 100)
View(data_check$PhaseLenght)

