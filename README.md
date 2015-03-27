# Welcome to the Mystical Trip Matching Algorithm v 0.99

This code takes as its input the binary driver data.

It then looks at the x and y data from driver trips and rotates them so that the last point in each trip is on the x-axis.

Next, it compares all unique pairs of trips. First, it ensures the range of x and y data are similar (within 20%) of each other. Special thanks to Jialiu (aka JSon) for the idea--this cuts calculation time considerably.

Trips that have a close match are trimmed to the length of rows of the shortest trip

For each trip I then: 1) calculate the distance to each point on the trip from the origin and 2) calculate the euclidian distance between those two 1-dimensional vectors.
IMPORTANT: these absolute distances are then normalized by the average maximum R from each trip


## Using this information
Filter the data by the eucDist (lower is a closer match). My own experience has shown that this should be lower than 1.5 work best. Use the trip grouper to form clusters and check a few drivers to see if the clusters worked for that given threshold.

### Trip Grouper
Trip Grouper.R takes the matched trips created in the previous section and groups them using connected components and puts them into a dataframe. The cluster size is counted and the information is stored by driver as a comma separated list. Split a cluster on commas to retreive a vector of trips for a driver.
