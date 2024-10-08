
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
  
  # print ID
  print(subj_ID)
  
  # Set paths to ecg files
  fpath <- paste0(here(), "/Data/VRTask/Cardio/ExpSubjects/02_Peaks/Events/VRCC_", 
                  subj_ID, ".csv")
  fpath_noisy_ecg <- paste0(here(), "/Data/VRTask/Cardio/ExpSubjects/02_Peaks/TimesBadECG/VRCC_", 
                  subj_ID, ".txt")
  
  # Get marker info from ECG file:
  mrks <- read_delim(fpath, delim = '\t')
  noisy_ecg <- read_delim(fpath_noisy_ecg, delim = ',')
  
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
  filtered_ecg_fpath <- paste0(here(), "/Data/VRTask/Cardio/ExpSubjects/01_Filtered/VRCC_filt_ecg_",subj_ID, ".txt")
  ecg <- read.table(here(filtered_ecg_fpath)) 
  ecg[,1] <- ecg[,1] * 1000 # frequency: 1000 Hz
  
  # apply low-pass filter to reduce noise
  ecg$V2<- pass.filt(ecg$V2, W = 0.02, type="low", method="Butterworth")
  
  # Invert ecg signal for subject "S16"
  if(subj_ID == "S16") {ecg$V2 <- ecg$V2 * -1} 
  
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
    
    ## Encode R_peaks before and after the stimulus onset:
    StimOnset <- StimOnsets[i]
    
    # start_check: insert NAs for onsets which occurred during noisy ecg interval (then NAs are inserted automaically for other variables)
    
    if (length(row(noisy_ecg)) > 0 & !is.na(StimOnset)) { # perform the check if there were any noisy intervals and if onset is not NA
    for (r in 1:nrow(noisy_ecg)) { 
    if(StimOnset > noisy_ecg[r,1]  & StimOnset < noisy_ecg[r,2]) {StimOnset <- NA}
    if(is.na(StimOnset)) {break} # stop the loop after finding the value within one of noisy intervals
    } # stop checking
    } # skip checking
    
    idx <- max(which(RPeakLats-StimOnset < 0)) #position of R peak just before stimulus onset
    ECG_dat$RPm1[i] <- RPeakLats[idx] # R peak (latency) just before stimulus onset ("m1"- minus 1)
    ECG_dat$RPm2[i] <- RPeakLats[idx-1] # minus2
    ECG_dat$RPm3[i] <- ifelse(length(RPeakLats[idx-2]) == 1, RPeakLats[idx-2], NA) # minus3 (catch missing R-peak for the first trial - perform only if it's present)
    ECG_dat$RPp1[i] <- RPeakLats[idx+1] # R peak just after stimulus onset ("p1" - plus 1)
    ECG_dat$RPp2[i] <- RPeakLats[idx+2] # plus2
    ECG_dat$RPp3[i] <- RPeakLats[idx+3] # plus3
    ECG_dat$RPp4[i] <- RPeakLats[idx+4] # plus4 
    ECG_dat$RRLength[i] <- ECG_dat$RPp1[i] - ECG_dat$RPm1[i] # RR interval length
    ECG_dat$dist2RPm1[i] <- StimOnsets[i] - ECG_dat$RPm1[i] # time from the previous R peak to stimulus
    ECG_dat$dist2RPp1[i] <- ECG_dat$RPp1[i] - StimOnsets[i] # time from the stimulus to the next R peak
    
    ## Encode the T-wave end end related variables:
    
    # buffer at the end of heartbeat interval
    buffer_post = 60
    # optimize for an outlier with respect to ECG signal
    if(subj_ID == "S46") {buffer_post = 150} 
    
    # Define an endpoint for the interval of interest (the post-stimulus R peak - 60 ms) to exclude the possibility of misreading the next R peak as T_wave   
    t_limit <- ECG_dat$RPm1[i] + ECG_dat$RRLength[i] - buffer_post # 60 ms
    
    if(!is.na(t_limit)) {
      
    # buffer at the begining of heartbeat inverval
    buffer_pre = 100
    
    # Extract a relevant part of RR-interval for visualization purposes (from the pre-stimulus R peak (-100 ms) until the endpoint).
    twave_long <- ecg[(ECG_dat$RPm1[i]- buffer_pre):t_limit,]
    #plot(twave_long)
    
    # Extract an interval from: 100 ms after R peak to t_limit
    twave_int <- ecg[(ECG_dat$RPm1[i]+ buffer_pre):t_limit,] 
    #plot(twave_int)
    
    # Interval to be add to buffer after the R peak (likely T-wave peak area)
    t_wave_peak_interval = 200
    # optimize for an outlier with respect to ECG signal
    if(subj_ID == "S46") {t_wave_peak_interval = 150} 
    
    # Search for the maximum within the interval up to 300 ms after the R peak (100 + 200)
    tmaxpos <- which.max(twave_int[1:t_wave_peak_interval, 2]) 
    ## Alternative solution:
   
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
    
    # Optional: Plot visualizations of T-wave end for each trial and export them as jpg files
    jpeg(file = paste0(here(),'/Data/VRTask/Cardio/ExpSubjects/T_waves_plots/VRCC_t_wave_',subj_ID,'_trial', i,".jpg"), width=1024, height=600)
    plot(twave_long,col='black',xlab='Time (ms)', ylab= 'Electric potential (ECG)', cex.lab = 1.5, cex.axis = 1.4)
    points(twave_int[tmaxpos,1],twave_int[tmaxpos,2],col='purple3',pch='+',cex=6)
    points(twave2[tend,1],twave2[tend,2],col='orangered',pch='+',cex=6)
    title(paste('ID',subj_ID,'_trial ', i, sep=''),cex.main = 2, line=-2, outer=TRUE)
    dev.off()

    } else {
      
    ECG_dat$tend[i] <- NA # T wave end position
    ECG_dat$systolength[i] <- NA # Length of systole
      
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
                                   "buffer" = ((dist2RPm1 >= systolength) & (dist2RPm1 <= (systolength + 50))),
                                   "diastole" = ((dist2RPm1 > (systolength + 50)) & (dist2RPp1 > 50)),
                                   .method = "first",
                                   .default = "rwave")) #remaining interval: R peak (+-50 ms)
  
  # Add totTrial info:
  phys_dat <- rowid_to_column(phys_dat, var = "totTrial")
  phys_dat$totTrial <- as.numeric(phys_dat$totTrial)
  
  # Add column with participant ID:
  phys_dat <- add_column(phys_dat, ID = as.factor(subj_ID), .after = "totTrial")
  
  return(phys_dat)
}  

  
  
  
  
  


  
  