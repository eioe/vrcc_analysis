
library(tidyverse)
library(here)

add_cardio_info <- function(fulldat, subj_ID) {
  
  fpath <- paste0("/Data/VRTask/Cardio/Pilots/SETwithRPeaks/", 
                  subj_ID, 
                  "-mrkrs.csv"
                  )
  
  mrks <- read_delim(here(fpath), 
                     delim = '\t')
  
  mrks <- mrks %>% select(latency, type)
  mrks <- mrks %>% filter(type != 'boundary')
  mrks$class[mrks$type == 'RP'] <- 'RP'
  mrks$class[mrks$type == 'S 41'] <- 'stimOn'
  mrks$class[mrks$type == 'S 42'] <- 'stimOff'
  mrks$class[mrks$type == 'S 11'] <- 'trialStart'
  mrks$class[mrks$type == 'S 44'] <- 'resp'
  mrks$class[is.na(mrks$class)] <- 'stimID'
  
  getID <- filter(mrks, class == 'stimID')
  getAnim <- fulldat %>% 
    filter(who == 'P04') %>% 
    select(Animal) %>% 
    droplevels()
  
  getAnim$trueType <- 'hansi'
  for (A in levels(getAnim$Animal)) {
    allIdx <- which(A == getAnim$Animal)
    idx <- min(allIdx)
    getAnim$trueType[allIdx] <- getID$type[idx]
  }
  
  while (sum(getID$type[1:720] != getAnim$trueType)>0) {
    delIdx <- min(which(getID$type[1:720] != getAnim$trueType))
    if(getID$type[delIdx] == getID$type[delIdx-1]) {
      if(abs(getID$latency[delIdx-1] - getID$latency[delIdx-2]) < 1000) {
        delIdx <- delIdx-1
      }
    }
    
    getID <- getID[-delIdx, ]
  }
  hansi <- cbind(getID, getAnim)
  
  getOns <- mrks %>%
    filter(type == 'S 41')
  getOffs <- mrks %>%
    filter(type == 'S 42')
  
  
  diff <- length(hansi$latency) - length(getOns$latency)
  if (diff > 0) {
    stimOn <- append(getOns$latency, rep(NA, diff))
  }
  
  hansi <- hansi %>% add_column(stimOn)
  
  while(sum(abs(hansi$latency - hansi$stimOn) > 1000, na.rm = T) > 0) {
    idx <- min(which(abs(hansi$latency - hansi$stimOn) > 1000))
    hansi$stimOn[(idx+1):length(hansi$stimOn)] <- 
      hansi$stimOn[idx:(length(hansi$stimOn)-1)]
    hansi$stimOn[idx] <- getOffs$latency[idx] - 100  
  }
  
  
  if (nrow(getOffs) == nrow(hansi)) {
    hansi$stimOff <- getOffs$latency
    hansi <- hansi %>% 
      mutate(stimDur = stimOff - stimOn)
  }
  
  # find surrounding RPeaks:
  
  RPeakLats <- mrks %>% 
    filter(type == 'RP')
  
  for (i in 1:nrow(hansi)) {
    idx <- max(which(RPeakLats$latency-hansi$stimOn[i] < 0))
    hansi$RPm1[i] <- RPeakLats$latency[idx]
    hansi$RPm2[i] <- RPeakLats$latency[idx-1]
    hansi$RPp1[i] <- RPeakLats$latency[idx+1]
    hansi$RPp2[i] <- RPeakLats$latency[idx+2]
  }
  
  hansi <- hansi %>%
    mutate(RRLength = RPp1 - RPm1, 
           dist2RPm1 = stimOn - RPm1, 
           dist2RPp1 = RPp1 - stimOn, 
           relPosRR = dist2RPm1/RRLength, 
           relPosRRrad = relPosRR *2*pi, 
           isSystTrial = ifelse(dist2RPm1 < 300, TRUE, FALSE))
  
  # add totTrial info:
  hansi <- rowid_to_column(hansi, var = "totTrial")
  hansi$totTrial <- as.numeric(hansi$totTrial)
  
  # add column with participant ID:
  hansi <- add_column(hansi, who = as.factor(subj_ID), .after = "trial")
 
  # export only relevant data to fulldat:
  export_df <- hansi[, c("who",
                         "totTrial", 
                         "Animal",
                         "stimOn", 
                         "stimOff", 
                         "RPm1", 
                         "RPm2",
                         "RPp1",
                         "RPp2", 
                         "RRLength", 
                         "dist2RPm1", 
                         "dist2RPp1",   
                         "relPosRR",
                         "relPosRRrad",
                         "isSystTrial"
                         )
                     ]
                         
  
  # add info to fulldat (Animal col would not be necessary but is a control):
  fulldat <- full_join(fulldat, 
                       export_df, 
                       by = c("totTrial", "who", "Animal")
             )
  
  return(fulldat)
  
}
  
  
  