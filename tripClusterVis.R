require(dplyr)
require(igraph)

setwd("~/GitHub/NYCDSA_B001/project/kaggle/axa/alexadler/")

# Trip Matching Directory
tripDir = "~/Dropbox/Shared Kaggle Data/trip matching/"

load(paste0(tripDir,"tripMatches-v2"))

dev.off()
# Don't take every match of eucDist.. Just the "generally similar" ones
threshold = 5

# Filter by threshold values
ofInterest<-filter(tripMatches,eucDist<threshold)

# Get a unique list of driver IDs to call in next portion of script
driverID<-sort(unique(ofInterest$driver))

# Which driver do we want to see?
ourDriver = 1

set.seed(1337)
thisDriver = filter(ofInterest,driver==ourDriver)
# Choose a non-directed approach (it doesn't matter if trip A matches trip B or trip B matches trip A)
tripNetwork <- graph.data.frame(thisDriver[,2:4], directed = FALSE)
# Print the vertices
V(tripNetwork)
# Print the edges
E(tripNetwork)
# See the degree for each vertex
degree(tripNetwork)

# Preliminary glimpse of the trip network
# plot(tripNetwork)

# Remove some of the lower degree trip clusters
bad.vs<-V(tripNetwork)[degree(tripNetwork)<3] #identify vertices part of fewer than three edges
tripNetwork<-delete.vertices(tripNetwork, bad.vs) #remove them from the graph
set.seed(1337)

# Single out specific trips by color, useful for spot checking
# V(tripNetwork)$color<-ifelse(V(tripNetwork)$name==134, 'blue', 'pink')

# Setting vertex size according to degree (scaled in a way that doesn't make huge points)
V(tripNetwork)$size<-log(degree(tripNetwork))*2

# E(tripNetwork)$weight <- 1/round(E(tripNetwork)$eucDist*2)

# E(tripNetwork)$color<-ifelse(E(tripNetwork)$eucDist>5, "grey",
#                              ifelse(E(tripNetwork)$eucDist>4,"Red",
#                                     ifelse(E(tripNetwork)$eucDist>3,"orange",
#                                            ifelse(E(tripNetwork)$eucDist>2,"yellow","green"))))

# Highlight close euclidean distances with a green coloring
E(tripNetwork)$color<-ifelse(E(tripNetwork)$eucDist<2,"green","grey")

# Plot the Trip Clusters
par(mai=c(0,0,1,0))   		
set.seed(1337)
plot(tripNetwork,
     layout=layout.fruchterman.reingold,	# the layout method. Fruchterman Reingold is best
     main=paste0('Trip Clusters Driver ',as.character(ourDriver)),
     vertex.frame.color='blue', 		#the color of the border of the dots 
     vertex.label.color='black',		#the color of the name labels
     vertex.label=NA,		#specifies the lables of the vertices. in this case the 'name' attribute is used
     edge.color = E(tripNetwork)$color # green if particularly close eucDist
)


# Nothing Graphical here, just exporting a list of the drivers in each cluster
####### Clustering #########
grouped<-foreach(i=driverID,.combine=rbind) %dopar%{
  thisDriver<-filter(ofInterest,driver==i)
  graph <- graph.data.frame(thisDriver[,2:3], directed = FALSE)
  cluster <- clusters(graph) #take the graph created above and return the clusters for each driver
  matchTable <- cbind( V(graph)$name, cluster$membership )
  driverGroups<-split(matchTable[,1], matchTable[,2])
  perDriver<-data.frame()
  for(k in 1:length(driverGroups)){
    perDriver<-rbind(perDriver,data.frame(driver=i,group=k,matches=as.character(paste(unlist(as.numeric(driverGroups[[k]])),collapse=", ")),clusterSize=length(driverGroups[[k]])))
  }
  perDriver
}

grouped$matches<-as.character(grouped$matches)