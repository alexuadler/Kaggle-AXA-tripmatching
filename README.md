# Welcome to the Mystical Trip Matching Algorithm v 0.99

This code takes as its input the binary driver data (all x-y data of all of each driver's trips in a binary file)

It then looks at the x and y data from driver trips and rotates them so that the last point in each trip is on the x-axis.

Next, it compares all unique pairs of trips. First, it ensures the range of x and y data are similar (within 20%) of each other. Special thanks to Jialiu (aka JSon) for the idea--this cuts calculation time considerably.

Trips that have a close match are trimmed to the length of rows of the shortest trip. Euclidean distances are calculated using the y values for each of the two trips and are then normalized by the average maximum y's from each trip. This produces a `eucDist` metric (smaller is a closer match).
