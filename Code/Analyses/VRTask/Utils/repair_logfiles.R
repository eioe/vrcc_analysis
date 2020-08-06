
library(here)
library(tidyverse)

vec_magnitude <- function(vec) {
  return(sqrt(sum(vec**2)))
}

ang_deg <- function(v1, v2) {
  for (v in list(v1, v2)) {
    if (class(v) != "list") {
      stop("Need lists as input.")
    }
  }
  v1 <- as.matrix(bind_cols(v1))
  v2 <- as.matrix(bind_cols(v2))
  ang_rad <- (atan2(v2[, 2], v2[, 1]) - atan2(v1[, 2], v1[, 1])) * -1 # remember Unity's left handed coord sys (therefore * -1)
  ang_deg <- ang_rad * (180/pi)
  return(ang_deg)
}

DebugMode <- FALSE

VRCC_dir        <- here()
data_dir        <- here("Data/VRTask/Logfiles/ExpSubjects")
path_data_virt <- data_dir_virt <- paste0(file.path('S:', 'Meine Bibliotheken'), 
                                          strsplit(data_dir, 'Seafile')[[1]][2])

subs <- list.files(file.path(data_dir_virt, '_problematic'), pattern = "S")

for (sub in subs) {

  sub_ID <- sub
  path <- file.path(data_dir_virt, '_problematic', sub_ID)
  path_out <- file.path(data_dir_virt, sub_ID)
  if (!dir.exists(path_out)) dir.create(path_out)
  pattern = "(PlayerLog).*\\.txt$"
  
  in_file <- list.files(path, 
                        pattern = pattern)
  
  filepath <- file.path(path, in_file)
  
  # read and store header: 
  header <- readLines(filepath, 6)
  
  # read data:
  df <- read.table(filepath,
                   skip      = 7,
                   header    = F,
                   sep       = ";",
                   row.names = NULL,
                   na.string = "-1.0000",
                   col.names = c(scan(filepath,
                                      what = "",
                                      sep  = ";",
                                      n    = 17,
                                      skip = 6),
                                 "!col_to_remove"))[-18] 
  
  
  df %>% separate(col = EstimatedPosition, 
                  into = str_c('estpos_', c('x', 'y', 'z')), 
                  sep = ',', 
                  remove = !DebugMode) %>%
    separate(col = TruePosition, 
             into = str_c('truepos_', c('x', 'y', 'z')), 
             sep = ',', 
             remove = !DebugMode) %>%
    mutate_at(.vars = vars(contains("pos_")), .funs=parse_number) %>% 
    mutate(estpos_z = estpos_z + 7) %>% # correct for logging error
    mutate(AngleErrDeg = abs(ang_deg(list(truepos_x, truepos_z), 
                                     list(estpos_x, estpos_z))) %% 180) %>%  # calc abs error angle
    unite("TruePosition", contains("truepos_"), sep=', ', remove = !DebugMode) %>% 
    unite("EstimatedPosition", contains("estpos_"), sep=', ', remove = !DebugMode) %>% 
    mutate_at(.vars = c("EstimatedPosition", "TruePosition"), .funs = ~str_c('(', ., ')')) %>% 
    mutate(delete_me = '') -> repaired_df # add empty column at end to make it compatible with regular DFs -> he
  
  fname <- in_file
  writeLines(header, file.path(path_out, fname))
  write_delim(repaired_df, 
            file.path(path_out, fname), 
            append = TRUE, 
            col_names = TRUE, 
            delim = ';')
  # copy other files:
  for (f in list.files(path)) {
    if (!str_detect(f, 'Player')) {
      file.copy(file.path(path, f), file.path(path_out, f))
    }
  }
}


