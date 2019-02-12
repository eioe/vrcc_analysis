**1. Preprocess behavioral data**

    # send me to VRCC dir:
    VRCC_dir <- "C:/Users/x220t/Seafile/CentralKollegs18/centralkollegs18"

    # Set up the data directory
    #data_dir <- 'N:/VRCC'
    data_dir <- file.path(VRCC_dir, "Data/VRTask")
    setwd(data_dir)

    require(ggplot2)

    ## Loading required package: ggplot2

    require(plyr)

    ## Loading required package: plyr

    ### Pilot 2 ###

    data <- read.table(file.path(data_dir, "VRCC_pilot2.txt"), skip = 6, header = T, sep = ";", na.string ="-1")
    #data <- read.table("VRCC_pilot_pawel.txt", skip = 6, header = T, sep = ";", na.string ="-1")


    data$Stimulus <- as.factor(data$isFearObject)
    data$Stimulus <- revalue(data$Stimulus, c("True"="Threatening", "False"="Non-threatening"))
    # 
    # true_est <- ggplot(data=data, aes(x=trueDistance, y=estDistance)) +
    #   geom_smooth(method = "loess", level=0.95, alpha = 0.2) + geom_point(col = "black")+ scale_fill_manual() + theme_classic() + labs(x = "True distances" , y = "Estimated distances") + scale_x_continuous(limits = c(1.8, 6.5)) + scale_y_continuous(limits = c(1.8, 6.5))


    ## MAIN PLOT
    colorset <- c("dodgerblue3", "firebrick2")

    object_condition <- ggplot(data=data, aes(x=trueDistance, y=estDistance, group = Stimulus)) + geom_abline(intercept = 0, linetype = "dashed") + geom_smooth(aes(color=Stimulus), method = "loess", level=0.95, alpha = 0.2) + geom_point(aes(color=Stimulus), alpha = 0.5) + theme_classic() + labs(x = "True distance" , y = "Estimated distance") + scale_x_continuous(limits = c(1.8, 7)) + scale_y_continuous(limits = c(1.8, 7))  + theme(legend.text = element_text(size = 13), legend.position=c(0.8, 0.2), axis.text=element_text(size=14), axis.title=element_text(size=14)) + scale_colour_manual(values = colorset) 

    # warning is due to x and y limits and outliers beyond and one NA in datatable
    object_condition

    ## Warning: Removed 3 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 3 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-1.png)

    ## Error at different distances

    # Absolute difference
    data$diff <- data$estDistance - data$trueDistance

    error <- ggplot(data=data, aes(x=trueDistance, y=diff)) +
      geom_smooth(method = "loess", level=0.95, alpha = 0.2) + geom_point(col = "black")+ scale_fill_manual() + theme_classic() + labs(x = "True distances (m)" , y = "Absolute error (m)") + scale_x_continuous(limits = c(2, 6)) + scale_y_continuous(limits = c(-4, 4))

    error + geom_hline(yintercept=0, linetype="dashed", color = "red")

    ## Warning: Removed 9 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 9 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-2.png)

    # Proportional difference %

    data$diff_norm <- (data$diff / data$trueDistance) * 100 


    error <- ggplot(data=data, aes(x=trueDistance, y=diff_norm)) +
      geom_smooth(method = "loess", level=0.95, alpha = 0.2) + geom_point(col = "black")+ scale_fill_manual() + theme_classic() + labs(x = "True distances (m)" , y = "Error in proportion to true distance (%)") + scale_x_continuous(limits = c(1.8, 6.2)) + scale_y_continuous(limits = c(-50, 100))

    error + geom_hline(yintercept=0, linetype="dashed", color = "red")

    ## Warning: Removed 9 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 9 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-3.png)

    ## Error at different distances accounting for different objects 

    # Absolute difference
    object_condition <- ggplot(data=data, aes(x=trueDistance, y=diff, group= Stimulus)) +
      geom_smooth(aes(linetype=Stimulus, color=Stimulus), method = "loess", level=0.95, alpha = 0.2) + geom_point(aes(color=Stimulus))+ scale_fill_manual() + theme_classic() + labs(x = "True distances" , y = "Absolut Error") 

    object_condition  + geom_hline(yintercept=0, linetype="dashed", color = "black")

    ## Warning: Removed 1 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 1 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-4.png)

    # Proportional error

    object_condition <- ggplot(data=data, aes(x=trueDistance, y=diff_norm, group= Stimulus)) +
      geom_smooth(aes(linetype=Stimulus, color=Stimulus), method = "loess", level=0.95, alpha = 0.2) + geom_point(aes(color=Stimulus))+ scale_fill_manual() + theme_classic() + labs(x = "True distances" , y = "Proprtional error %") 

    object_condition  + geom_hline(yintercept=0, linetype="dashed", color = "black")

    ## Warning: Removed 1 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 1 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-5.png)

    ### Pilot 3 ###

    data <- read.table(file.path(data_dir, "VRCC_pilot3.txt"), skip = 6, header = T, sep = ";", na.string ="-1.00")
    data <- data[data$Phase == "Estimation",]

    colnames(data)[6] <- "Animal"
    colnames(data)[7] <- "Stimulus"
    colnames(data)[9] <- "trueDistance"
    colnames(data)[10] <- "estDistance"

    data$Stimulus <- revalue(data$Stimulus, c("True"="Threatening", "False"="Non-threatening"))

    data$estDistance <- as.numeric(as.character(data$estDistance))
    typeof(data$estDistance)

    ## [1] "double"

    data$trueDistance <- as.numeric(as.character(data$trueDistance))
    typeof(data$trueDistance)

    ## [1] "double"

    data$trueDistance <- as.numeric(data$trueDistance - 7)



    ## MAIN PLOT
    colorset <- c("dodgerblue3", "firebrick2")

    object_condition <- ggplot(data=data, aes(x=trueDistance, y=estDistance, group = Stimulus)) + geom_abline(intercept = 0, linetype = "dashed") + geom_smooth(aes(color=Stimulus), method = "loess", level=0.95, alpha = 0.2) + geom_point(aes(color=Stimulus), alpha = 0.5) + theme_classic() + labs(x = "True distance" , y = "Estimated distance") + scale_x_continuous(limits = c(1.8, 7)) + scale_y_continuous(limits = c(1.8, 7))  + theme(legend.text = element_text(size = 13), legend.position=c(0.8, 0.2), axis.text=element_text(size=14), axis.title=element_text(size=14)) + scale_colour_manual(values = colorset) 

    # warning is due to x and y limits and outliers beyond and one NA in datatable
    object_condition

    ## Warning: Removed 3 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 3 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-6.png)

    ## Error at different distances

    # Absolute difference
    data$diff <- data$estDistance - data$trueDistance

    error <- ggplot(data=data, aes(x=trueDistance, y=diff)) +
      geom_smooth(method = "loess", level=0.95, alpha = 0.2) + geom_point(col = "black")+ scale_fill_manual() + theme_classic() + labs(x = "True distances (m)" , y = "Absolute error (m)") + scale_x_continuous(limits = c(2, 6)) + scale_y_continuous(limits = c(-4, 4))

    error + geom_hline(yintercept=0, linetype="dashed", color = "red")

    ## Warning: Removed 3 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 3 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-7.png)

    # Proportional difference %

    data$diff_norm <- (data$diff / data$trueDistance) * 100 


    error <- ggplot(data=data, aes(x=trueDistance, y=diff_norm)) +
      geom_smooth(method = "loess", level=0.95, alpha = 0.2) + geom_point(col = "black")+ scale_fill_manual() + theme_classic() + labs(x = "True distances (m)" , y = "Error in proportion to true distance (%)") + scale_x_continuous(limits = c(1.8, 6.2)) + scale_y_continuous(limits = c(-50, 100))

    error + geom_hline(yintercept=0, linetype="dashed", color = "red")

    ## Warning: Removed 3 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 3 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-8.png)

    ## Error at different distances accounting for different objects 

    # Absolute difference
    object_condition <- ggplot(data=data, aes(x=trueDistance, y=diff, group= Stimulus)) +
      geom_smooth(aes(linetype=Stimulus, color=Stimulus), method = "loess", level=0.95, alpha = 0.2) + geom_point(aes(color=Stimulus))+ scale_fill_manual() + theme_classic() + labs(x = "True distances" , y = "Absolut Error") 

    object_condition  + geom_hline(yintercept=0, linetype="dashed", color = "black")

    ## Warning: Removed 2 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 2 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-9.png)

    # Proportional error

    object_condition <- ggplot(data=data, aes(x=trueDistance, y=diff_norm, group= Stimulus)) +
      geom_smooth(aes(linetype=Stimulus, color=Stimulus), method = "loess", level=0.95, alpha = 0.2) + geom_point(aes(color=Stimulus))+ scale_fill_manual() + theme_classic() + labs(x = "True distances" , y = "Proprtional error") 

    object_condition  + geom_hline(yintercept=0, linetype="dashed", color = "black")

    ## Warning: Removed 2 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 2 rows containing missing values (geom_point).

![](VRCC_behavior_files/figure-markdown_strict/unnamed-chunk-1-10.png)

    ## Loading required package: dplyr

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:plyr':
    ## 
    ##     arrange, count, desc, failwith, id, mutate, rename, summarise,
    ##     summarize

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

    ## Warning: Removed 1 rows containing non-finite values (stat_bin).

    ## Warning: Removed 1 rows containing non-finite values (stat_density).

![](VRCC_behavior_files/figure-markdown_strict/opts-1.png)

    ## 
    ##  Welch Two Sample t-test
    ## 
    ## data:  rel by Stimulus
    ## t = 1.6307, df = 38.603, p-value = 0.1111
    ## alternative hypothesis: true difference in means is not equal to 0
    ## 95 percent confidence interval:
    ##  -0.00815354  0.07587737
    ## sample estimates:
    ## mean in group Non-threatening     mean in group Threatening 
    ##                     0.9904303                     0.9565684
