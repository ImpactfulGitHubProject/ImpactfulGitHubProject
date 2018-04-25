## Plot exploration graphs
# by Gui Lin
# Date: 2018-04

source("src/0.lib-setup.R")
# Plot Exploration ######
set.seed(379)
data <- downSample(x=trainingSet %>% select(-Class),y=trainingSet$Class)%>% sample_n(floor(nrow(.)*0.2))
data <- data %>% mutate(hasReadme=ifelse(hasReadme==FALSE,"noReadme","hasReadme")) %>% mutate(isfork=ifelse(isfork==0,"notFork","Fork")) %>% mutate(copyright=ifelse(copyright>=1,"hasCopyRightInfo","noCopyRightInfo")) %>% mutate(contact=ifelse(contact>=1,"hasContact","noContact"))%>% mutate(wiki=ifelse(wiki>=1,"hasWiki","noWiki"))
pdf(file="data/20180420_plot_explore.pdf",width = 10,height = 5)
ggplot(data,aes(x=log10(issues+1),y=contributors,shape=Class,color=Class))+  facet_grid(hasReadme~lang) +geom_point(position=position_jitter(h=0.05,w=0.05)) #->p
#p + stat_ellipse(type = "norm")
ggplot(data,aes(x=log10(commits+1),y=log10(releases+1),shape=Class,color=Class))+  facet_grid(hasReadme~lang) + geom_point(position=position_jitter(h=0.05,w=0.05)) #->p
ggplot(data,aes(x=log10(url_num+1),y=log10(rsize+1),shape=Class,color=Class))+  facet_grid(isfork~lang) + geom_point(position=position_jitter(h=0.05,w=0.05)) #->p
ggplot(data,aes(x=yr_creation,y=yr_active,shape=Class,color=Class))+  facet_grid(copyright~lang) + scale_x_continuous(breaks=seq(1,10,2))+ geom_point(position=position_jitter(h=0.05,w=0.05)) #->p
ggplot(data,aes(x=log10(releases+1),y=branches,shape=Class,color=Class))+  facet_grid(contact~lang) + geom_point(position=position_jitter(h=0.05,w=0.05)) #->p
dev.off()

##

# plot tree
library(C50)
data(churn)
myTree = C5.0(x = churnTrain[, -20], y = churnTrain$churn)
summary(myTree)
pdf(file="test.pdf", width=100/2.54, height=60/2.54)
plot(myTree)
dev.off()
library("partykit")
myTree2 <- C50:::as.party.C5.0(myTree)
plot(myTree2[2])
plot(myTree2[15])

mytree2 <- C50:::as.party.C5.0(mod4)
pdf(file="test.2.pdf", width=100/2.54, height=60/2.54)
plot(mytree2[5])
dev.off()



mod <- readRDS("data/20180420_mod_c50_1.RDS")
mod$results %>% View()
myTree = C5.0(x = churnTrain[, -20], y = churnTrain$churn)
