#script to merge site and grid data on bird presence absence
rm(list=ls())
library(ggplot2)
library(plyr)

#import grid data
setwd("C:/Users/Phil/Desktop/All_species/Species_grid_csv_2/")
Sp_grid<-read.csv("Grid_Pres_Abs.csv")
head(Sp_grid)

#import site data
setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Rest_sp_mod/Analysis/Data/Bird biodiversity data/Site_data")
Traits<-read.csv("Bird_locations_SF_grid.csv")
Site_grid<-unique(Traits[,c('ET_ID','SiteID')])
Site_grid<-subset(Site_grid,ET_ID>0)
Count_ID<-count(Site_grid,"ET_ID")
head(Count_ID)


#produce presence absence grid of regional species pools
#so that we can predict presence at the site, not the grid scale

for (i in 1:length(Count_ID$ET_ID)) {
  Sub<-subset(Sp_grid,ET_ID==Count_ID$ET_ID[i])
  Sub2<-do.call("rbind", replicate(Count_ID$freq[i], Sub, simplify = FALSE))
  Sub2$Rep_ID<-rep(x=1:(length(Sub2$Sp_pool)/length(Sub$Sp_pool)),times=length(Sub$Sp_pool))
  Sub2$Unique<-paste(Sub2$ET_ID,Sub2$Sp_ID,Sub2$Rep_ID,sep="")
  setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Rest_sp_mod/Analysis/Data/Bird biodiversity data/Site_data/Pres_abs_grid")
  write.csv(Sub2,paste(Count_ID$ET_ID[i],".csv",sep=""),row.names=F)
}

#stick all these together into one csv
setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Data/Bird biodiversity data/Site_data/Pres_abs_grid")
Pres_grid2<-do.call(rbind, lapply(list.files(path="C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Data/Bird biodiversity data/Site_data/Pres_abs_grid"), read.csv))


#work out number of sites per grid cell
Traits<-Traits[order(Traits$SiteID),]

for (i in 1:length(Count_ID$ET_ID)) {
  Sub<-subset(Traits,ET_ID==Count_ID$ET_ID[i])
  Sub$SiteNo<-NA
  Sub[1,12]<-1
  Sub
  for (y in 1:(length(Sub$SiteID)-1)){
  if (Sub$SiteID[y+1]==Sub$SiteID[y]){
     Sub$SiteNo[y+1]<-Sub$SiteNo[y]
  } else {
        Sub$SiteNo[y+1]<-Sub$SiteNo[y]+1
  }
  }
  Sub$Unique<-paste(Sub$ET_ID,Sub$TaxonID,Sub$SiteNo,sep="")
  setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Rest_sp_mod/Analysis/Data/Bird biodiversity data/Site_data/Pres_abs_grid_site")
  write.csv(Sub,paste(Count_ID$ET_ID[i],".csv",sep=""),row.names=F)
}
  

#stick all these together into one csv
setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Data/Bird biodiversity data/Site_data/Pres_abs_grid_site")
Traits2<-do.call(rbind, lapply(list.files(path="C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Data/Bird biodiversity data/Site_data/Pres_abs_grid_site"), read.table, header=TRUE, sep=","))
head(Traits2)
head(Pres_grid2)

#merge the two datasets
Comb<-merge(x=Pres_grid2,y=Traits2,by="Unique",all.x=T)
head(Comb)


#Set site records as present or absent
Comb$Present<-ifelse(test=Comb$Present==T,1,0)
Comb$Present[is.na(Comb$Present)]<-0
Comb$Sp_pool[is.na(Comb$Sp_pool)]<-0
head(Comb)

#reset age
Age_set<-data.frame(Comb$ET_ID.x,Comb$Rep_ID,Comb$Age)
Age_set<-Age_set[complete.cases(Age_set),]
Age_set<-unique(Age_set)

Comb2<-merge(Comb,Age_set,by.x=c("ET_ID.x","Rep_ID"),by.y=c("Comb.ET_ID.x","Comb.Rep_ID"),all=T)
str(Comb2)

#subset to only include site number
#to enable a spatial join with forest cover data

str(Comb)
Sub_comb<-Comb[c(5,7,10,19,14,15)]
Sub_comb2<-Sub_comb[complete.cases(Sub_comb),]
Sub_comb3<-unique(Sub_comb2)
head(Sub_comb3)
summary(Comb2$ET_ID.x)
summary(Sub_comb3$ET_ID.x)



Comb_coord<-merge(Comb2,Sub_comb3,by=c("ET_ID.x","Rep_ID"),all.x=T,all.y=F)



#combine with traits and forest cover
setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Data/Bird biodiversity data/Site_data/Traits")
Sp_traits<-read.csv("Traits.csv")
head(Sp_traits)
Comb_traits<-merge(Comb_coord,Sp_traits,by.x="Sp_ID",by.y="Species_ID2",all.x=T)
Cover<-read.csv("Forest_cov.csv")
head(Comb_traits)
Comb_traits_cov<-merge(Comb_traits,Cover,by.x="ET_ID.x",by.y="ET_ID",all.x=T)
head(Comb_traits_cov)

#tidy up dataframe to only include data from columns we want
str(Comb_traits_cov)
myvars <- c("ET_ID.x", "Sp_ID", "Rep_ID","Present","Comb.Age","SiteID.y","Lat.y","Long.y","Forest_dep","Av_disp.1","Cover")
Comb_traits2<-Comb_traits_cov[myvars]
str(Comb_traits2)
colnames(Comb_traits2)<-c("Grid","Sp_ID","Rep_ID","Pres","Age","Site_ID","Lat","Long","F_dep","Disp","Cover")

setwd("C:/Users/Phil/Documents/My Dropbox/Work/PhD/Publications, Reports and Responsibilities/Chapters/7. Spatial modelling of restoration/Data/Bird biodiversity data/Site_data")
Range<-read.csv("BL_Range.csv")
head(New_comb2)
head(Range)
New_comb3<-merge(Comb_traits2,Range,by="Sp_ID")
head(New_comb3)

write.csv(New_comb3,"Pres_abs.csv")
write.csv(Comb2,"Pres_abs_sites.csv")
