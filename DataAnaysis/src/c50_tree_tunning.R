## For plotting the tree graph from C50 model
# by Gui Lin
# Date: 2018-04

source("src/lib-setup.R")
require("C50")
require("partykit")

# load data
load("data/20180420_mod_C50_8_ReadTree.RData")
	# if model 5 is used, then uncomment the following
	# mod_c50_5 <- readRDS("data/20180420_mod_c50_5.RDS")

# plot without preprocess to better visualize the graph

# model info: 
	# model 8, prepare the final tree model. we can use all the trainingSet_bl for training
	# to better visualize the graph, the model is trained (1) without preprocess (2) with some mix sampling to better balance the set while keep the size small for as.party.C5.0 
# comment out as model has already trained. 	
#set.seed(1)
#mod_c50_8 <- C5.0(x = trainingSet_smaller%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent),
#     y = trainingSet_smaller$Class,
#     trials = 50,
#     rules=FALSE,
#     winnow = "FALSE")
#confusionMatrix(predict(mod_c50_8,newdata = data_two_class_test%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) #%>% select(-parent)),data_two_class_test$Class,mode=c('everything'))



# for plotting the tree
pdf(file="data/20180420_mod_c50_8_Tree.pdf", width=100/2.54, height=60/2.54)
# plot the whole tree
plot(mod_c50_8)
myTree2 <- C50:::as.party.C5.0(mod_c50_8)
# plot the partial tree by specifying the node number, i.e., 217
plot(myTree2[217])
dev.off()

