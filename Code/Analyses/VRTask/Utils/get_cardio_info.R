
get_cardio_info <- function(fulldat, subj_ID) {
  
  # Gets information about (cardiac) events (from ECG file) for a specific 
  # subject.
  # 
  # Args:
  #   fulldat: Data frame with info from logfile
  #   subj_ID: ID of subject (e.g. S03)
  #
  # Returns: 
  #   Data frame with cardiac information.
  
  # 04/04/2019: FK --- eioe, PM
  
  fpath <- paste0("Data/VRTask/Cardio/ExpSubjects/02_Peaks/Events/VRCC_", 
                  subj_ID, ".csv")
  
  # Get marker info from ECG file:
  mrks <- read_delim(here(fpath), delim = '\t')
  
  
  # Get relevant columns and rows, add info column about type of marker:
  mrks <- mrks %>% 
    select(latency, type) %>%
    filter(type != 'boundary') %>% 
    mutate(class = dplyr::recode(type,
                                 'ECG' = 'RP', 
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
    filter(ID == subj_ID) %>% 
    select(Stimulus) %>%
    mutate(Stimulus = as_factor(Stimulus))
  
  # Following line assumes that the (mappings in the) first trials are in order:
  mappingStim2Mrk <- setNames(as.list(unique(anim_seq$Stimulus)), 
                              as.list(unique(mrk_seq$type)))
  
  mrk_seq <- mutate(mrk_seq, 
                    mappedStim = dplyr::recode(mrk_seq$type, !!!mappingStim2Mrk))
  
  # Now we can check for identity:
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
  
  # Find StimOnset surrounding RPeaks:
  RPeakLats <- mrks %>% 
    filter(class == 'RP') %>% 
    select(latency) %>% 
    as_vector()
  
  # Load filtered ECG data (for the t-wave end detection algorithm)
  filtered_ecg_fpath <- paste0("Data/VRTask/Cardio/ExpSubjects/01_Filtered/VRCC_filt_ecg_",subj_ID, ".txt")
  ecg <- read.table(here(filtered_ecg_fpath)) 
  ecg[,1] <- ecg[,1] * 1000 # frequency: 1000 Hz
  
  # Create a data frame with cardiac variables
  ECG_dat <- tibble(RPm1 = numeric(nTrials),
                    RPm2 = numeric(nTrials),
                    RPm3 = numeric(nTrials),
                    RPp1 = numeric(nTrials),
                    RPp2 = numeric(nTrials),
                    RPp3 = numeric(nTrials),
                    RPp4 = numeric(nTrials),
                    RRLength = numeric(nTrials),
                    dist2RPm1 = numeric(nTrials),
                    dist2RPp1 = numeric(nTrials),
                    tend = numeric(nTrials),
                    systolength = numeric(nTrials))
  
  for (i in 1:nTrials) { ## Loop: Cardiac parameters for each trial
    
    ## Encode R_peak related variables:
    idx <- max(which(RPeakLats-StimOnsets[i] < 0))
    ECG_dat$RPm1[i] <- RPeakLats[idx] # R peak just before stimulus onset (m1: minus 1)
    ECG_dat$RPm2[i] <- RPeakLats[idx-1] # minus 2
    # ECG_dat$RPm3[i] <- RPeakLats[idx-2] 
    ECG_dat$RPm3[i] <- ifelse(length(RPeakLats[idx-2]) == 1, RPeakLats[idx-2], NA) # minus 3 (catch missing data for the first trial)
    ECG_dat$RPp1[i] <- RPeakLats[idx+1] # R peak just after stimulus onset (p1: plus 1)
    ECG_dat$RPp2[i] <- RPeakLats[idx+2] # plus 2
    ECG_dat$RPp3[i] <- RPeakLats[idx+3] # plus 3
    ECG_dat$RPp4[i] <- RPeakLats[idx+4] # plus 4 
    ECG_dat$RRLength[i] <- ECG_dat$RPp1[i] - ECG_dat$RPm1[i] # RR interval length
    ECG_dat$dist2RPm1[i] <- StimOnsets[i] - ECG_dat$RPm1[i] # time from the previous R peak to stimulus
    ECG_dat$dist2RPp1[i] <- ECG_dat$RPp1[i] - StimOnsets[i] # time from the stimulus to the next R peak
    
    ## Encode the T-wave end end related variables:
    
    # Define an endpoint for the interval of interest (the post-stimulus R peak - 60 ms) to exclude the possibility of misreading the next R peak as T_wave   
    t_limit <- ECG_dat$RPm1[i] + ECG_dat$RRLength[i] - 60 # 60 ms
    
    if(!is.na(t_limit)) {
    
    # Extract a relevant part of RR-interval for visualization purposes (from the pre-stimulus R peak (-100 ms) until the endpoint).
    twave_long <- ecg[(ECG_dat$RPm1[i]- 100):t_limit,]
    #plot(twave_long)
    
    # Extract an interval from: 50 ms after R peak to t_limit
    twave_int <- ecg[(ECG_dat$RPm1[i]+ 100):t_limit,] # previous 50
    #plot(twave_int)
    
    # Search for the maximum within the interval up to 350 ms after the R peak (50 + 300)
    tmaxpos <- which.max(twave_int[1:200, 2]) # previous 300
    ## Alternative solution:
    #tmaxpos1 <- which.max(twave_int[1:((ECG_dat$RRLength[i] - 50)/3),2]) # alternative/previous solution that looks over ~1/3 of individual RR length (excluding the next R peak)
    # side note: outcomes of both seem matched almost perfectly for S06, although I think that the second one might be to restrictive (too short interval taken into consideration - visual checks seem to support it) 
    
    twave2=twave_int[tmaxpos:dim(twave_int)[1],]
    #plot(twave2)
    
    # Determine a point called xm located in the segment after the T peak, which has a minimum value in the first derivative. The algoritm searches for xm in a 120 ms time window starting from tmax. In case twave2 does not contain 0.12*fs (120 ms) data points, it searches only until the last point of twave2.
    fs <- 1000
    dp <- 0.12*fs # 120 ms
    if (dp>dim(twave2)[1]) {
      xm <- which(diff(twave2[,2])==min(diff(twave2[,2]))) 
    } else {
      xm <- which(diff(twave2[1:dp,2])==min(diff(twave2[1:dp,2]))) 
    }
    xm <- xm[1]
    ym <- twave2[xm,2]
    
    # determine a point xr which is supposed t happen after tend.
    xr <- 150+xm 
    
    # make a vector starting from xm and goes until xr
    xseq <- xm:xr
    yseq <- twave2[xm:xr,2]
    
    # write a function find the end of twave: first calculation of the trapeziums areas of all the points located between “xm“ and “xr“ and then identification of the point which gives the maximum area and label it as the t-wave end
    trapez_area <- function(xm, ym, xseq, yseq, xr) {
      a <- numeric()
      for (i in seq_along(xseq)){
        a[i] <- 0.5 * (ym - yseq[i]) * ((2*xr) - xseq[i] - xm)
      }
      x_tend <- which.max(a)+xm-1
      return(x_tend)
    }
    tend <- trapez_area(xm, ym, xseq, yseq, xr)
    
    ECG_dat$tend[i] <- twave2[tend,1] # T wave end position
    ECG_dat$systolength[i] <- twave2[tend,1]- ECG_dat$RPm1[i] # Length of systole 
    
    # ## Optional: Plot visualizations of T-wave end for each trial and export them as jpg files
    # jpeg(file = paste('N:/vrcc_t_wave_plots/VRCC_twave_ID_',subj_ID,'_trial', i,".jpg"), width=1024, height=600)
    # par(mfrow=c(1,2))
    # plot(twave_long,col='black',xlab='time(ms)', ylab= 'electric potential (normalized)')
    # points(twave_int[tmaxpos,1],twave_int[tmaxpos,2],col='magenta',pch='+',cex=4)
    # points(twave2[tend,1],twave2[tend,2],col='green',pch='+',cex=4)
    # plot(twave2,col='black', xlab='time(s)', ylab='electric potential (normalized)')
    # title(paste('ID',subj_ID,'_trial ', i, sep=''),line=-2, outer=TRUE)
    # points(twave2[xm,1],twave2[xm,2],col='blue',pch='+',cex=2)
    # points(twave2[xr,1],twave2[xr,2],col='blue',pch='+',cex=3)
    # points(twave2[tend,1],twave2[tend,2],col='green',pch='+',cex=4)
    # points(twave_int[tmaxpos,1],twave_int[tmaxpos,2],col='magenta',pch='+',cex=3)
    # dev.off()
    # 
    
    } else {
      
    ECG_dat$tend[i] <- NA # T wave end position
    ECG_dat$systolength[i] <- NA
      
    }
    
    
  } ## Loop: Cardiac parameters for each trial
  
  
  # Feed into one DF:
  phys_dat <- tibble(stimOn   = StimOnsets, 
                     stimOff  = StimOffsets)
  
  phys_dat <- bind_cols(phys_dat, ECG_dat)
  
  # Calculate relative position of stimulus onset within the cardiac cycle:
  phys_dat <- phys_dat %>%
    mutate(relPosRR    = dist2RPm1/RRLength, # relative stimulus onset position (proportion)
           relPosRRrad = relPosRR *2*pi, # normalized stimulus onset position (pi)
           # # Infer whether stimulus onset was delivered during systole diastole or intermediate buffors 
           c_phase = derivedFactor("systole" = ((dist2RPm1 < systolength) & (dist2RPm1 > 50)),
                                   "diastole" = ((dist2RPm1 > (systolength + 50)) & (dist2RPp1 > 50)),
                                   .method = "first",
                                   .default = "buffer")) #Check PEP length!!
  
  # Add totTrial info:
  phys_dat <- rowid_to_column(phys_dat, var = "totTrial")
  phys_dat$totTrial <- as.numeric(phys_dat$totTrial)
  
  # Add column with participant ID:
  phys_dat <- add_column(phys_dat, ID = as.factor(subj_ID), .after = "totTrial")
  
  return(phys_dat)
}  

  
  
  
  
  


  
  