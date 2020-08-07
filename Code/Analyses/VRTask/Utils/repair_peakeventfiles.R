


library(here)
library(tidyverse)

DebugMode <- FALSE

trials_to_insert_per_sub <- list('S01' = 1:11, 
                                 'S02' = 1:6, 
                                 'S25' = 688:690, 
                                 'S41' = 1:68)

VRCC_dir <- here()
data_dir_virt <- file.path(file.path('S:', 'Meine Bibliotheken'), 
                                  strsplit(VRCC_dir, 'Seafile')[[1]][2], 
                                  'Data')
data_dir_logs <- file.path(data_dir_virt, 
                           'VRTask', 
                           'Logfiles', 
                           'ExpSubjects')
                           
data_dir_peaks <- here("Data", 
                       "VRTask", 
                       "Cardio", 
                       "ExpSubjects", 
                       "02_Peaks", 
                       "Events")


subs <- list.files(file.path(data_dir_peaks), pattern = "S")

for (sub in subs) {
  sub_id <- str_split(sub, "_|\\.", simplify = T)[2]
  
  in_path <- file.path(data_dir_logs, sub_id)
  
  # get Events DF:
  df_events <- read_delim(file.path(data_dir_peaks, sub), delim = '\t')
    
  # Get stimulus to mrkr mapping: 
  pattern = "(SetupLog).*\\.txt$"
  in_file <- list.files(in_path, 
                        pattern = pattern)
  ll <- scan(file.path(in_path, in_file), 
       what = "", 
       skip = 64, 
       nlines = 8*2)
  
  idx_discard <- grep("(Stim)|(Unity)", ll)
  stim_seq <- ll[-idx_discard]
  # make mapping 
  named_mrkrs <- str_c('S  ',1:8)
  names(named_mrkrs) <- stim_seq
  
  # Get logfile:
  pattern = "(PlayerLog).*\\.txt$"
  in_file <- list.files(in_path, 
                        pattern = pattern)
  filepath <- file.path(in_path, in_file)
  
  # read data:
  df_logs <- read.table(filepath,
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
                                     "!col_to_remove"))[-19] 
  
  df_mrkr <- df_logs %>%  filter(Phase == 'Estimation', Training == "False", Round > 0) %>% 
                      select(Stimulus) %>% 
                      mutate(Stimulus = as.character(Stimulus)) %>% 
                      mutate(mrkr = recode(.$Stimulus, !!!named_mrkrs)) 
  
  trials_to_insert <- trials_to_insert_per_sub[[sub_id]]
  if (!sum(df_events$type == 'S 11') + length(trials_to_insert) == 720) {
    warning("Missmatch in trials.")
    stop()
  }
  

  trial_mrkrs <- tibble(number = 1:5, 
                       latency = rep(NA_real_, 5),
                       duration = rep(1.00, 5), 
                       channel = rep(NA_real_, 5),
                       bvtime = rep(NA_real_, 5), 
                       bvmknum = rep(NA_real_, 5),
                       type = c('S 11', 'S 41', 'S 42', NA_character_, 'S 44'), 
                       code = rep('Stimulus', 5), 
                       urevent = rep(NA_integer_, 5))
                
  for (tt in trials_to_insert) {
    
    
    df_events %>%  mutate(n = row_number()) %>% 
      filter(type == 'S 11') %>% 
      slice(tt) %>% 
      pull(n) -> idx
    upper_df <- df_events %>%  slice(1:idx-1)
    lower_df <- df_events %>%  slice(idx:nrow(df_events))
    
    max_num <- upper_df$number[nrow(upper_df)]
    trial_fill <- trial_mrkrs %>% 
      mutate(number = number + max_num)
    trial_fill$type[4] <- df_mrkr$mrkr[tt]
    trial_fill$type <- as.character(trial_fill$type)
    
    upper_df <- bind_rows(upper_df, trial_fill)  
    
    # adapt row counts in lower df:
    max_num <- upper_df$number[nrow(upper_df)]
    lower_df <- lower_df %>% mutate(number = number + max_num)
    
    df_events <- bind_rows(upper_df, lower_df)
  }
  
  write_delim(df_events, file.path(data_dir_peaks, 'repaired', sub), delim = '\t')
}
  