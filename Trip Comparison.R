setwd("~/GitHub/Kaggle")

library(dplyr)
library(doParallel)
cl <- makeCluster(1)
registerDoParallel(cores=3)

dataDir <- "data/"
drivers <- list.files(dataDir)
# For selecting a range of drivers
lowBound = 1
highBound = 1

runTime<-system.time({


similarTrips<-foreach(driver=drivers[lowBound:highBound],.combine=rbind) %dopar%{
  load(paste0(dataDir,driver))
  driverID<-gsub(driver,pattern="DriverData",replacement="")
  test<-drives %>%
    group_by(tripID) %>%
    mutate(x = x, y = y,
           r=sqrt(x^2+y^2),
           alpha=atan2(last(y),last(x))-atan2(y,x),
           rot.x=r*cos(alpha),
           rot.y=r*sin(alpha),
           rows=n(),
           rot.x.flip=ifelse(sum(rot.x<0)>floor(rows/2), -rot.x, rot.x),
           rot.y.flip=ifelse(sum(rot.y<0)>floor(rows/2), -rot.y, rot.y)
    )%>%
    select(tripID,rot.x=rot.x.flip,rot.y=rot.y.flip)
  mini2<-NULL
  # begin a nested loop to check all UNIQUE combinations of trips
  for(i in 1:199){
    focus<-select(test[test$tripID==i,],foc.x=rot.x,foc.y=rot.y)
    mini1<-NULL
    for(k in (i+1):200) {
      compare<-select(test[test$tripID==k,], cmp.x=rot.x, cmp.y=rot.y)
      # Necessary to only check trips that are even close to the same footprint (thanks to Jiayi Liu aka. JSon for the idea)
      if(!(diff(range(focus$foc.x))<0.8*diff(range(compare$cmp.x))) &
           !(diff(range(compare$cmp.x))<0.8*diff(range(focus$foc.x))) &
           !(diff(range(focus$foc.y))<0.8*diff(range(compare$cmp.y))) &
           !(diff(range(compare$cmp.y))<0.8*diff(range(focus$foc.y)))
      ){

        trimLength<- min(nrow(compare),nrow(focus)) # Trimming instead of imputing values (Tim's suggestion) improves speed by 10%, catches more true positives
        
        focusTrim<-focus[1:trimLength,]#%>%
#           transmute(r.foc=sqrt(foc.x^2+foc.y^2)) # Option to use distance of point to origin
        
        compareTrim<-compare[1:trimLength,]#%>%
#           transmute(r.cmp=sqrt(cmp.x^2+cmp.y^2)) # Option to use distance of point to origin
        
        eqDistMat<-rbind(focusTrim$foc.y,compareTrim$cmp.y)
        mini1<-rbind(mini1,
                     data.frame(driver=driverID, tripA=i,tripB=k,
                  # this is the euclidian distance between y values of both curves
                  # it was necessary to normalize the result: trips with larger x and y values had higher euclidian distances
                  # I chose to normalize by the average "footprint" of the two trips
                   eucDist=unlist(as.numeric(dist(eqDistMat)))/mean(c(max(focusTrim$foc.y),max(compareTrim$cmp.y)))
                  ))
      } # end if loop
    } # end comparison loop
    mini2<-rbind(mini2,mini1)
  } # end focus loop
  mini2
}
})


outputFileName = paste0('similarTrips-y_',lowBound,'_',highBound)
save(similarTrips,file=outputFileName)




#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

############ Extra beyond this point just for visualization and threshold values
############ I. Visualization
load("data/DriverData1")

test<-drives %>%
  group_by(tripID) %>%
  mutate(x = x, y = y,
         r=sqrt(x^2+y^2),
         alpha=atan2(last(y),last(x))-atan2(y,x),
         rot.x=r*cos(alpha),
         rot.y=r*sin(alpha),
         rot.xmax=max(rot.x),
         rows=n(),
         rot.x.flip=ifelse(sum(rot.x<0)>floor(rows/2), -rot.x, rot.x),
         rot.y.flip=ifelse(sum(rot.y<0)>floor(rows/2), -rot.y, rot.y)
  )%>%
  select(tripID,x,y,rot.xmax,rot.x=rot.x.flip,rot.y=rot.y.flip,rows)
test$tripCount<-c(1:nrow(test))

tripInspector<-unique(c(arrange(similarTrips,eucDist)$tripA[1:10],arrange(similarTrips,eucDist)$tripB[1:10]))

ggplot(data=filter(test,(tripID %in% tripInspector)))+geom_point(aes(x=rot.x,y=rot.y,color=tripID),size=1)+
facet_wrap(~ tripID,scales="free")+theme_bw()+theme(legend.position="none")

