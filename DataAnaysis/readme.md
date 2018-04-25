# Environment Setup
All the related packages have been included in the list under 	`src/lib_setup.R`. Before running any other files, please set up your environment using by running 

`source("src/lib-setup.R")`


# Data Loading and preparation
The file `src/data_prep.R` contains code for loading and processing data from MySQL DB, which stores raw data crawled from Github API. The processed data is then stored at "data/model_inputs_v2_g_201804.RData" for exploration purposes. 


# Exploration
The relationship among features and impact-fulness is explored and plot as coded in `src/exploration_plot.R`


# Correlation and Modelling  
The Pearson correlation is shown in a plot coded in the file `src/pearson_correlation.R`. Besides Pearson correlation, non-linear relationship is also obtained via visualising feature importance and tree relationship from RandomeForest model and C50 tree model respectively. The modelling details are coded in `src/model_training.R`


# Reading and Exploring the graph
The tree from C50 model is too large to be viewed clearly in one graph. Therefore, one may need to zoom in to certain node and view its subtree. The code `src/c50_tree_tunning.R` is provided to further zoom in to the tree graph and have a deeper understanding on its relationship. 