source("src/lib-setup.R")
load(file="data/model_inputs_v2_g_201804.RData")
languageSet <- c("JavaScript","Java","Python","HTML","Ruby","PHP","C++","C","CSS","C#")
f.convert.lang <- function(data){
  data %>% mutate(lang = ifelse(is.element(language,languageSet),as.character(language),"Others")) %>% mutate(lang=as.factor(lang))
}
f.check.cm.test <- function(model=mod2,data=data_two_class_test){
  confusionMatrix(predict(model,newdata = data),data$Class,mode=c('everything'))
}
f.check.cm.train <- function(model=mod2,data=data_two_class_test){
 confusionMatrix(predict(model,newdata = trainingSet),trainingSet$Class,mode=c('everything'))
}
f.plot.train.model <- function(model){plot.train(model)}
f.age.rename <- function(data){
   data %>% mutate(yr_creation=age) %>% select(-age)
}
data_train_cut <- data_train_cut %>%f.convert.lang() %>%  mutate(hasReadme=!is.na(url_num)) %>% f.age.rename
data_vali_cut <- data_vali_cut %>% f.convert.lang() %>%  mutate(hasReadme=!is.na(url_num)) %>% f.age.rename
data_two_class <- data_train_cut %>% mutate(imp_cut = as.character(imp_cut)) %>% mutate(label = ifelse(imp_cut=="2","event","nonEvent")) %>% mutate(label=as.factor(label))
predictors <- c("branches","releases","issues","commits","size","yr_creation","label", "isfork","yr_active", "avg_following","ave_followers","contributors","url_num","wiki","command","contact","copyright","rsize","hasReadme","lang","parent")
data_two_class_test <- data_vali_cut %>% mutate(imp_cut = as.character(imp_cut)) %>% mutate(label = ifelse(imp_cut=="2","event","nonEvent")) %>% mutate(label=as.factor(label)) %>% select(-imp_cut)%>% mutate(Class=label) %>% select(-label)
trainingSet <- data_two_class %>% select(-imp_cut)%>% select(one_of(predictors))%>% mutate(Class=label) %>% select(-label)
trainingSet%>% group_by(Class)%>% summarise(nt=n())
trainingSet[is.na(trainingSet)] <- 0
data_two_class_test[is.na(data_two_class_test)] <-0

fiveStats <- function(data, lev = levels(data$obs), model = NULL){
  out <- c(multiClassSummary(data, lev = levels(data$obs), model = NULL))
  # The best possible model has sensitivity of 1 and specificity of 1.
  # How far are we from that value?
  coords <- matrix(c(1, 1, out["Specificity"], out["Sensitivity"]), ncol = 2, byrow = TRUE)
  colnames(coords) <- c("Spec", "Sens")
  rownames(coords) <- c("Best", "Current")
  c(out, Dist = dist(coords)[1])
}

f.caret.returnBest <- function(model,metric="F1",maximize=TRUE){
	best_ind <- best(x=model$results, metric=metric, maximize=TRUE)
	model$results[best_ind, ]
}

### 1
mod_rf_1 <- train(y=trainingSet$Class,
              x=trainingSet%>%select(-Class),
              method = 'rf',
              metric = "F1",
              maximize = TRUE,
              trControl = trainControl(method = "cv",
                          number = 3,#10,
                          repeats = 3,#5,
                          classProbs = TRUE,
                          summaryFunction = fiveStats,
                          verboseIter=TRUE,
                          trim=TRUE, returnData = FALSE #to make the model size smaller.
                          ))
						  
f.check.cm.test(model = mod_rf_1)
saveRDS(mod_rf_1,file="data/20180420_model_rf_1.RDS")

pdf(file="data/20180420_model_rf_1.pdf")
plot(mod_rf_1)
varImpPlot(mod_rf_1)
varImpPlot(mod_rf_1$finalModel)
dev.off()

### 2
trainingSet_bl <- upSample(x=trainingSet%>%select(-Class),y=trainingSet$Class)
mod_rf_2 <- train(y=trainingSet_bl$Class,
              x=trainingSet_bl%>%select(-Class),
              method = 'rf',
              metric = "F1",
              maximize = TRUE,
              trControl = trainControl(method = "cv",
                          number = 3,#10,
                          repeats = 3,#5,
                          classProbs = TRUE,
                          summaryFunction = fiveStats,
                          verboseIter=TRUE,
                          trim=TRUE, returnData = FALSE #to make the model size smaller.
                          ))
						  
f.check.cm.test(model = mod_rf_2)
saveRDS(mod_rf_2,file="data/20180420_model_rf_2.RDS")

pdf(file="data/20180420_model_rf_2.pdf")
plot(mod_rf_2)
varImpPlot(mod_rf_2$finalModel)
dev.off()


### try nnet
# nnet(x, y, weights, size, Wts, mask,
     # linout = FALSE, entropy = FALSE, softmax = FALSE,
     # censored = FALSE, skip = FALSE, rang = 0.7, decay = 0,
     # maxit = 100, Hess = FALSE, trace = TRUE, MaxNWts = 1000,
     # abstol = 1.0e-4, reltol = 1.0e-8, ...)
#mod_neuralnet_1 <- nnet( y=trainingSet_sc$Class,
#              x=x,
#			  size=4,linout=TRUE,softmax=TRUE,
#			  preProcess = c('center', 'scale'))
dummy <- dummyVars(~., data=trainingSet%>%select(-parent,-Class), fullRank=TRUE)
mod_neuralnet_1 <- train(y=trainingSet$Class,
              x=predict(dummy,trainingSet%>%select(-parent,-Class)) ,
              method = 'nnet',
              metric = "F1",
              maximize = TRUE,
							preProcess = c('center', 'scale'))
              trControl = trainControl(method = "cv",
                          number = 3,#10,
                          repeats = 3,#5,
                          classProbs = TRUE,
                          summaryFunction = fiveStats,
                          verboseIter=TRUE,
                          trim=TRUE, returnData = FALSE #to make the model size smaller.
                          ))
f.caret.returnBest(mod_neuralnet_1) #warning: fiveStats is not used, use Accuracy intead of F1 for scoring.
confusionMatrix(predict(mod_neuralnet_1,newdata = predict(dummy,trainingSet%>%select(-parent,-Class)) ),trainingSet$Class,mode=c('everything'))
confusionMatrix(predict(mod_neuralnet_1,newdata = predict(dummy,data_two_class_test%>%select(-parent,-Class)) ),data_two_class_test$Class,mode=c('everything'))
saveRDS(mod_neuralnet_1,file="data/20180420_mod_neuralnet_1.RDS")
pdf(file="data/20180420_mod_neuralnet_1.pdf")
plot(mod_neuralnet_1)
dev.off()
# try c5.0 standard, but with center and scale

set.seed(1) 
mod_c50_1 <- train(y=trainingSet$Class,
              x=trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent),
                   method = "C5.0",
                   tuneGrid = expand.grid(
						trials = c(1:9, (1:10)*10),
						model = c("tree", "rules"),
						winnow = c(TRUE, FALSE)),
                   metric = "F1",
                   importance=TRUE, # not needed
                   preProc = c("center", "scale"),
				    trControl = trainControl(method = "cv",
                          number = 3,#10,
                          repeats = 3,#5,
                          classProbs = TRUE,
                          summaryFunction = fiveStats,
                          verboseIter=TRUE,
                          trim=TRUE, returnData = FALSE #to make the model size smaller.
                          )
				    ) 

f.check.cm.test(model = mod_c50_1,data = data_two_class_test %>% mutate(hasReadme=as.factor(hasReadme)))
f.caret.returnBest(mod_c50_1)
saveRDS(mod_c50_1,file="data/20180420_mod_c50_1.RDS")
pdf(file="data/20180420_mod_c50_1.pdf")
plot(mod_c50_1)
dev.off()


set.seed(1) 
mod_c50_2 <- train(y=trainingSet$Class,
              x=trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent),
                   method = "C5.0",
                   tuneGrid = expand.grid(
						trials = c(70),
						model = c("tree"),
						winnow = c(FALSE)),
                   metric = "F1",
                   importance=TRUE, # not needed
                   preProc = c("center", "scale"),
				    trControl = trainControl(method = "cv",
                          number = 3,#10,
                          repeats = 3,#5,
                          classProbs = TRUE,
                          summaryFunction = fiveStats,
                          verboseIter=TRUE,
                          trim=TRUE, returnData = FALSE #to make the model size smaller.
                          )
				    ) 
f.check.cm.test(model = mod_c50_2 ,data = data_two_class_test %>% mutate(hasReadme=as.factor(hasReadme)))
f.caret.returnBest(mod_c50_2 )
saveRDS(mod_c50_2 ,file="data/20180420_mod_c50_2 .RDS")
pdf(file="data/20180420_mod_c50_2.pdf")
plot(mod_c50_2 )
plot(mod_c50_2$FinalModel)
dev.off()

# get a single tree model
set.seed(1)
preprocessParams <- preProcess(trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent), method=c("center", "scale"))
mod_c50_3 <- C5.0(x = predict(preprocessParams,trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent)),
     y=trainingSet$Class,
     trials = 50,
     rules=FALSE,
     winnow = "FALSE")
confusionMatrix(predict(mod_c50_3,newdata = predict(preprocessParams,trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent))),trainingSet$Class,mode=c('everything'))
confusionMatrix(predict(mod_c50_3,newdata = predict(preprocessParams,data_two_class_test%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent))),data_two_class_test$Class,mode=c('everything'))
saveRDS(mod_c50_2 ,file="data/20180420_mod_c50_3.RDS")
pdf(file="data/20180420_mod_c50_3.pdf", width=100/2.54, height=60/2.54)
plot(mod_c50_3)
dev.off()

# get a single tree model
set.seed(1)
preprocessParams <- preProcess(trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent), method=c("center", "scale"))
mod_c50_4 <- C5.0(x = predict(preprocessParams,trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent)),
     y=trainingSet$Class,
     trials = 70,
     rules=FALSE,
     winnow = "FALSE")
confusionMatrix(predict(mod_c50_4,newdata = predict(preprocessParams,trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent))),trainingSet$Class,mode=c('everything'))
confusionMatrix(predict(mod_c50_4,newdata = predict(preprocessParams,data_two_class_test%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent))),data_two_class_test$Class,mode=c('everything'))
saveRDS(mod_c50_4 ,file="data/20180420_mod_c50_4.RDS")
pdf(file="data/20180420_mod_c50_4.pdf", width=100/2.54, height=60/2.54)
plot(mod_c50_4)
dev.off()

# plot without preprocess to better visualize the graph
set.seed(1)
mod_c50_5 <- C5.0(x = trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent),
     y=trainingSet$Class,
     trials = 50,
     rules=FALSE,
     winnow = "FALSE")
confusionMatrix(predict(mod_c50_5,newdata = trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent)),trainingSet$Class,mode=c('everything'))
confusionMatrix(predict(mod_c50_5,newdata = data_two_class_test%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent)),data_two_class_test$Class,mode=c('everything'))
saveRDS(mod_c50_5 ,file="data/20180420_mod_c50_5.RDS")
pdf(file="data/20180420_mod_c50_5.pdf", width=100/2.54, height=60/2.54)
plot(mod_c50_5)
myTree2 <- C50:::as.party.C5.0(mod_c50_5)
plot(myTree2[217])
dev.off()

pdf(file="data/20180420_mod_c50_5_b.pdf", width=100/2.54, height=60/2.54)



# run a rule model
set.seed(1) 
mod_c50_6 <- train(y=trainingSet$Class,
              x=trainingSet%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent),
                   method = "C5.0",
                   tuneGrid = expand.grid(
						trials = c(50),
						model = c("rules"),
						winnow = c(FALSE)),
                   metric = "F1",
                   importance=TRUE, # not needed
                   preProc = c("center", "scale"),
				    trControl = trainControl(method = "cv",
                          number = 3,#10,
                          repeats = 3,#5,
                          classProbs = TRUE,
                          summaryFunction = fiveStats,
                          verboseIter=TRUE,
                          trim=FALSE, returnData = TRUE #to make the model size smaller.
                          )
				    ) 
summary(mod_c50_6$finalModel)
f.check.cm.test(model = mod_c50_6 ,data = data_two_class_test %>% mutate(hasReadme=as.factor(hasReadme)))
f.caret.returnBest(mod_c50_6 )
saveRDS(mod_c50_6 ,file="data/20180420_mod_c50_6.RDS")
pdf(file="data/20180420_mod_c50_6.pdf")
plot(mod_c50_6)
plot.new()
mtext(summary(mod_c50_6))
#plot(mod_c50_6$FinalModel)
dev.off()


# model 7, same as model 5, but on balanced training set
# plot without preprocess to better visualize the graph
set.seed(9237)
trainingSet_bl <- upSample(x=trainingSet%>%select(-Class),y=trainingSet$Class)
split<-createDataPartition(y = trainingSet_bl$Class, p = 0.7, list = FALSE)
trainingSet_bl_train<-trainingSet_bl[split,]
trainingSet_bl_val<-trainingSet_bl[-split,]
set.seed(1)
mod_c50_7 <- C5.0(x = trainingSet_bl_train%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent),
     y=trainingSet_bl_train$Class,
     trials = 50,
     rules=FALSE,
     winnow = "FALSE")
confusionMatrix(predict(mod_c50_7,newdata = trainingSet_bl_val%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent)),trainingSet_bl_val$Class,mode=c('everything'))
confusionMatrix(predict(mod_c50_7,newdata = data_two_class_test%>%select(-Class) %>% mutate(hasReadme=as.factor(hasReadme)) %>% select(-parent)),data_two_class_test$Class,mode=c('everything'))
saveRDS(mod_c50_7 ,file="data/20180420_mod_c50_7.RDS")
pdf(file="data/20180420_mod_c50_7.pdf", width=100/2.54, height=60/2.54)
plot(mod_c50_7)
myTree2 <- C50:::as.party.C5.0(mod_c50_7)
plot(mod_c50_7[217])
dev.off()

pdf(file="data/20180420_mod_c50_5_b.pdf", width=100/2.54, height=60/2.54)

