
get_cardio_info <- function(fulldat, subj_ID) {
  # gets information about (cardiac) events (from ECG file) for a specific 
  # subject.
  # 
  # Args:
  #   fulldat: Data frame with info from logfile
  #   subj_ID: ID of subject (e.g. S03)
  #
  # Returns: 
  #   Data frame with cardiac information.
  
  # 04/04/2019: FK --- eioe
  
  fpath <- paste0("/Data/VRTask/Cardio/ExpSubjects/SETwithRPeaks/VRCC_", 
                  subj_ID, 
                  "_mrkrs.csv"
  )
  
  # Get marker info from ECG file:
  mrks <- read_delim(here(fpath), delim = '\t')
  
  # Get relevant columns and rows, add info column about type of marker:
  mrks <- mrks %>% 
    select(latency, type) %>%
    filter(type != 'boundary') %>% 
    mutate(class = recode(type,
                          'RP' = 'RP', 
                          'S 41'= 'stimOn', 
                          'S 42' = 'stimOff',
                          'S 11' = 'trialStart', 
                          'S 44' = 'resp',
                          'S  1' = 'stimID',
                          'S  2' = 'stimID',
                          'S  3' = 'stimID',
                          'S  4' = 'stimID',
                          'S  5' = 'stimID',
                          'S  6' = 'stimID',
                          'S  7' = 'stimID',
                          'S  8' = 'stimID',
                          .default = NA_character_
                          )
           )
                          
                  
  # We have to get a mapping between mrks$stimID and fulldat$Stimulus (for each 
  # participant)
  mrk_seq <- mrks %>% 
    filter(class == 'stimID') %>% 
    select(type)
  
  anim_seq <- fulldat %>% 
    filter(who == subj_ID) %>% 
    select(Stimulus) %>%
    mutate(Stimulus = as_factor(Stimulus))
  
  # following line assumes that the (mappings in the) first trials are in order:
  mappingStim2Mrk <- setNames(as.list(unique(anim_seq$Stimulus)), 
                              as.list(unique(mrk_seq$type)))
  
  mrk_seq <- mutate(mrk_seq, 
                    mappedStim = recode(mrk_seq$type, !!!mappingStim2Mrk))
  
  # now we can check for identity:
  if (any(mrk_seq$mappedStim != anim_seq$Stimulus)) {
    stop("Mapping between trials in log file and physio data is incorrect.")
  }
  
  if (nrow(mrk_seq) != nrow(anim_seq)) {
    stop("This won't work out of the box. You'll have to fix the data first.")
  }
  
  # If we survive these checks, it should be sane to move on:
  nTrials = nrow(mrk_seq)
  
  StimOnsets <- mrks %>%
    filter(type == 'S 41') %>%
    select(latency) %>% 
    as_vector()
  StimOffsets <- mrks %>%
    filter(type == 'S 42') %>%
    select(latency) %>% 
    as_vector()
  
  # find StimOnset surrounding RPeaks:
  RPeakLats <- mrks %>% 
    filter(type == 'RP') %>% 
    select(latency) %>% 
    as_vector()
  
  RP_dat <- tibble(RPm1 = numeric(nTrials),
                   RPm2 = numeric(nTrials),
                   RPp1 = numeric(nTrials),
                   RPp2 = numeric(nTrials))
  
  for (i in 1:nTrials) {
    idx <- max(which(RPeakLats-StimOnsets[i] < 0))
    RP_dat$RPm1[i] <- RPeakLats[idx]
    RP_dat$RPm2[i] <- RPeakLats[idx-1]
    RP_dat$RPp1[i] <- RPeakLats[idx+1]
    RP_dat$RPp2[i] <- RPeakLats[idx+2]
  }
  
  # Feed into one DF:
  phys_dat <- tibble(stimOn   = StimOnsets, 
                     stimOff  = StimOffsets)
  
  phys_dat <- bind_cols(phys_dat, RP_dat)
  
  # Calculate further params:
  phys_dat <- phys_dat %>%
    mutate(RRLength    = RPp1 - RPm1, 
           dist2RPm1   = stimOn - RPm1, 
           dist2RPp1   = RPp1 - stimOn, 
           relPosRR    = dist2RPm1/RRLength, 
           relPosRRrad = relPosRR *2*pi, 
           isSystTrial = ifelse(dist2RPm1 < 300, TRUE, FALSE))
  
  # add totTrial info:
  phys_dat <- rowid_to_column(phys_dat, var = "totTrial")
  phys_dat$totTrial <- as.numeric(phys_dat$totTrial)
  
  # add column with participant ID:
  phys_dat <- add_column(phys_dat, who = as.factor(subj_ID), .after = "totTrial")
  
  return(phys_dat)
}  
  
  
  