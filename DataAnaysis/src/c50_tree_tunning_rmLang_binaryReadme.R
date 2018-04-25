## For plotting the tree graph from C50 model
# by Gui Lin
# Date: 2018-04

source("src/lib-setup.R")
require("C50")
require("partykit")

# load data
load("data/20180425_mod_c50_10_ReadTree.RData")


# plot without preprocess to better visualize the graph

# model info: 
	# model 8, prepare the final tree model. we can use all the trainingSet_bl for training
	# to better visualize the graph, the model is trained (1) without preprocess (2) with some mix sampling to better balance the set while keep the size small for as.party.C5.0 
# comment out as model has already trained. 	
#set.seed(1)
#mod_c50_10<- C5.0(x = trainingSet_smaller_2%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent,-lang),
#     y = trainingSet_smaller_2$Class,
#     trials = 50,
#     rules=FALSE,
#     winnow = "FALSE")
#confusionMatrix(predict(mod_c50_8,newdata = data_two_class_test_2%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) #%>% select(-parent)),data_two_class_test_2$Class,mode=c('everything'))



# for plotting the tree
pdf(file="data/20180425_mod_c50_10_Tree.pdf", width=100/2.54, height=60/2.54)
# plot the whole tree
plot(mod_c50_10)
myTree2 <- C50:::as.party.C5.0(mod_c50_10)
# plot the partial tree by specifying the node number, i.e., 217
plot(myTree2[3])
plot(myTree2[34])
plot(myTree2[57])
plot(myTree2[112])
plot(myTree2[153])
dev.off()

