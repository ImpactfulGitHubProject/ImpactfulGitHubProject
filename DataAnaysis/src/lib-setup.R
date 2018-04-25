## For ex
# by Gui Lin
# Date: 2018-04

# to install and load all the required libraries
list.of.packages <- c(
   "ggplot2",
   "dplyr",
   "RMySQL",
   "data.table",
   "caret",
   "randomForest",
   "doSNOW",
   "C50",
   "corrplot",
   "e1071",
   "MLmetrics",
	 "partykit"
)
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

lapply(list.of.packages, require, character.only = TRUE )
