
# Author         : Aleksander Molak
# Date           : Dec 1, 2020


library(lme4)
library(performance)

# get_ICC = function(model) {
#   # Computes intraclass correlation
#   var_ = as.numeric(VarCorr(model)) 
#   cat(var_[1] / (var_[1] + var_[2]))
# }

get_r2_mlm <- function(model) {
  res <- r2_nakagawa(model)
  cat("Variance explained by the model (conditional Nakagawa's R2): ", res$R2_conditional, "\n")
  cat("Variance explained by fixed effects (marginal Nakagawa's R2): ", res$R2_marginal, "\n")
}
