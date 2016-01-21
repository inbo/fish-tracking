library(igraph)
library(plyr)
library(lubridate)

detections2graph <- function(detectionsDF, receiversDF, transmitter.id) {
  # sort the detections DF by transmitter and timestamp
  d <- detectionsDF[order(detectionsDF$transmitter, detectionsDF$timestamp), ]
  # create a list of unique receivers
  receivers <- unique(receiversDF[, c("station_name", "longitude", "latitude")])
  # add a flag when a new transmitter starts
  d$new.transm <- c(1, diff(as.factor(d$transmitter)))
  # add a flag when the station name of the detection differs from the previous detection
  d$stationdiff <- c(1, diff(as.factor(d$stationname)))
  # create a matrix with column1 containing the previous station (reveiver1) and column2
  # containing the next station (receiver2)
  all.edges <- cbind(
    c(0,
      d[d$stationdiff != 0 & d$transmitter==transmitter.id, "stationname"]
    ),
    c(d[d$stationdiff != 0 & d$transmitter==transmitter.id, "stationname"],
    0)
  )
  edges.df <- data.frame(all.edges[2:(length(all.edges[,1]) - 1),])
  colnames(edges.df) <- c("receiver1", "receiver2")
  # select all station names that where visited
  all.vertices <- c(as.character(edges.df$receiver1),
                    as.character(edges.df$receiver2))
  # create a dataframe containing the edges and their counts
  edges <- count(edges.df)
  # create a dataframe containing all station names and their counts
  unique.vertices <- count(all.vertices)
  colnames(unique.vertices) <- c("station_name", "count")
  # join the vertices (station names) with the receivers dataframe
  vertices <- merge(unique.vertices, receivers)
  # create a graph with the edges and vertices
  g <- graph.data.frame(edges, vertices=vertices)
  return(g)
}

intervals2graph <- function(intervalsDF, transmitter.id) {
  # sort the intervals DF by transmitter and arrival time
  d <- intervalsDF[order(intervalsDF$Transmitter, intervalsDF$Arrival_time), ]
  station.attr <- ddply(d[, c("Transmitter", "X", "Y", "Station.Name",
                                 "residencetime", "Departure_time")],
                           .(Transmitter, Station.Name, X, Y), # aggregate by transmitter and station
                           summarize, total_time=sum(residencetime), # add total residencetime
                           avg_time=mean(residencetime), # add mean residencetime
                           last_departure=max(ymd_hms(Departure_time))
                        ) # add last departure time
  # add a flag when a new transmitter starts
  d$new.transm <- c(1, diff(as.factor(d$Transmitter)))
  # add a flag when the station name of the interval differs from the previous interval
  d$stationdiff <- c(1, diff(as.factor(d$Station.Name)))
  # create a matrix with column1 containing the previous station (reveiver1) and column2
  # containing the next station (receiver2)
  all.edges <- cbind(
    c(0,
      d[d$stationdiff != 0 & d$Transmitter==transmitter.id, "Station.Name"]
    ),
    c(d[d$stationdiff != 0 & d$Transmitter==transmitter.id, "Station.Name"],
    0)
  )
  edges.df <- data.frame(all.edges[2:(length(all.edges[,1]) - 1),])
  colnames(edges.df) <- c("receiver1", "receiver2")
  # select all station names that where visited
  all.vertices <- c(as.character(edges.df$receiver1),
                    as.character(edges.df$receiver2))
  # create a dataframe containing the edges and their counts
  edges <- count(edges.df)
  # create a dataframe containing all station names and their counts
  unique.vertices <- count(all.vertices)
  colnames(unique.vertices) <- c("Station.Name", "count")
  # join the vertices (station names) with the station.attr. The one holding the additional
  # attributes such as total_time and last_departure
  vertices <- merge(unique.vertices, station.attr[station.attr$Transmitter==transmitter.id, ])
  # create a graph with the edges and vertices
  g <- graph.data.frame(edges, vertices=vertices)
  return(g)
}

plot.migration.detections <- function(graph) {
  plot(graph,
    layout=cbind(V(graph)$longitude, V(graph)$latitude),
    edge.curved=TRUE,
    edge.width=E(graph)$freq*2,
    vertex.size=6,
    edge.arrow.size=0.5,
    vertex.label.cex=0.7,
  )
}

# scale.color is used to create a color scale based on datetimes
# datetimes are expected to be character vectors in iso format (ymd_hms)
scale.color <- function(datetimes) {
  min.red <- 255
  min.green <- 212
  min.blue <- 00
  max.red <- 16
  max.green <- 130
  max.blue <- 255
  unix.times <- as.numeric(datetimes)
  scale <- (unix.times - min(unix.times)) / (max(unix.times) - min(unix.times))
  blue <- as.character(as.hexmode(round(scale * (max.blue - min.blue) + min.blue)))
  red <- as.character(as.hexmode(round(scale * (max.red - min.red) + min.red)))
  green <- as.character(as.hexmode(round(scale * (max.green - min.green) + min.green)))
  return(paste(c("#"), red, green, blue, sep=""))
}

plot.migration.intervals <- function(graph) {
    plot(graph,
         layout=cbind(V(graph)$X, V(graph)$Y),
         edge.curved=TRUE,
         edge.width=E(graph)$freq*2,
         vertex.size=6,
         #vertex.size=V(graph)$total_time * 50 / sum(V(graph)$total_time),
         edge.arrow.size=0.5,
         vertex.label.cex=0.7,
         vertex.color=scale.color(V(graph)$last_departure)
         )
}
