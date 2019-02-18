




library(tidyverse)
#install.packages("tidyverse")

library(here)
here()
dr_here()
print(here)

# dat <- read_csv2(here('/Data/VRTask/Prerating/results_n94.csv'), skip = 1, col_names = TRUE)
# 
# colnames(dat)[1:7] <- c('nbr', 'ID', 'date', 'lang', 'age', 'sex', 'yoEdu') 
# 
# 
# 
# dat <- gather(dat, animal, rating, colnames(dat)[8:52])
# 
# 
# 
# dat$dimension[grepl('_1', dat$animal)] <- "disgust"
# 
# dat$dimension[grepl('_2', dat$animal)] <- "speed"
# 
# dat$dimension[is.na(dat$dimension)] <- "threat"
# 
# 
# 
# dat$animal <- gsub(c('_1|_2'), '', dat$animal)