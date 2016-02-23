library(igraph)
library(plyr)
library(lubridate)
library(Matrix)

# ==================================
# See receiver_network.Rmd for more documentation and examples
# ==================================


# ==================================
# Generate movement edges from a data frame containing raw detections.
# The movement edges is a datafame with columns: "receiver1", "receiver2" and "count"
detections2movementedges <- function(detectionsDF, transmitter.id, allow.loops=FALSE) {
  # sort the detections DF by transmitter and timestamp
  d <- detectionsDF[order(detectionsDF$transmitter, detectionsDF$timestamp), ]
  d$new.transm <- c(1, diff(as.factor(d$transmitter)))
  # add a flag when the station name of the detection differs from the previous detection
  d$stationdiff <- c(1, diff(as.factor(d$stationname)))
  # create a matrix with column1 containing the previous station (reveiver1) and column2
  # containing the next station (receiver2)
  if (allow.loops) {
    all.edges <- cbind(
      c(0,
        d[d$transmitter==transmitter.id, "stationname"]
      ),
      c(d[d$transmitter==transmitter.id, "stationname"],
        0)
    )
  } else {
    all.edges <- cbind(
      c(0,
        d[d$stationdiff != 0 & d$transmitter==transmitter.id, "stationname"]
      ),
      c(d[d$stationdiff != 0 & d$transmitter==transmitter.id, "stationname"],
        0)
    )
  }
  edges.df <- data.frame(
    receiver1=all.edges[2:(length(all.edges[,1]) - 1), 1],
    receiver2=all.edges[2:(length(all.edges[,1]) - 1), 2],
  )
  # create a dataframe containing the edges and their counts
  edges <- count(edges.df)
  return(edges)
}

# ==================================
# Generate a movement matrix based on a data frame containing graph edges.
# This function can be used in `detections2movementmatrix` and
# `intervals2movementmatrix`
edges2movementmatrix <- function(edges) {
  names <- levels(as.factor(c(edges$receiver1, edges$receiver2)))
  m <- sparseMatrix(i=as.numeric(as.factor(edges$receiver1)),
                    j=as.numeric(as.factor(edges$receiver2)),
                    x=edges$freq)
  movementDF <- as.data.frame(as.matrix(m))
  row.names(movementDF) <- levels(as.factor(edges$receiver1))
  colnames(movementDF) <- levels(as.factor(edges$receiver2))
  return(movementDF)
}

# ==================================
# Generate a movement matrix from a data frame containing raw detections.
# A movement matrix has a row and a column for each receiver. Every cell indicates the
# number of times a fish migrated from receiver1 (the row) to receiver2 (the column)
detections2movementmatrix <- function(detectionsDF, transmitter.id, allow.loops=FALSE) {
  edges <- detections2movementedges(detectionsDF, transmitter.id, allow.loops=allow.loops)
  movementDF <- edges2movementmatrix(edges)
  return(movementDF)
}

# ==================================
# Generate a graph representing the movement of the fish carrying the given
# transmitter. Vertices (nodes) in the graph represent receivers while edges (arrows)
# represent movement between receivers.
# Parameters:
#    - `detectionsDF`: a dataframe with raw detections. Expected columns
#            are `stationname`, `timestamp` and `transmitter`. Other columns are ignored.
#    - `receiversDF`: a dataframe containing receiver metadata. Expected columns
#            are `station_name`, `longitude` and `latitude`. Other columns are ignored.
#    - `transmitter.id`: id of the transmitter for which a movement graph should be
#            created.
detections2graph <- function(detectionsDF, receiversDF, transmitter.id, allow.loops=FALSE) {
  edges <- detections2movementedges(detectionsDF, transmitter.id, allow.loops=allow.loops)
  # select all station names that where visited
  all.vertices <- c(as.character(edges$receiver1),
                    as.character(edges$receiver2))
  # create a list of unique receivers
  receivers <- unique(receiversDF[, c("station_name", "longitude", "latitude")])
  # add a flag when a new transmitter starts
  # create a dataframe containing all station names and their counts
  unique.vertices <- count(all.vertices)
  # fix the count. All vertices are counted double, except for the first occurrence of the first vertex and the last occurrence of the last vertex
  unique.vertices$freq <- sapply(unique.vertices$freq,
                                 function(x) {
                                   if (x%%2 == 0) {
                                     return(x/2)
                                   } else {
                                     return((x+1)/2)
                                   }
                                 }
  )
  colnames(unique.vertices) <- c("station_name", "count")
  # join the vertices (station names) with the receivers dataframe
  vertices <- merge(unique.vertices, receivers)
  # create a graph with the edges and vertices
  g <- graph.data.frame(edges, vertices=vertices)
  return(g)
}

# ==================================
# Generate movement edges from a data frame containing detection intervals.
# The movement edges is a datafame with columns: "receiver1", "receiver2" and "count"
# Parameters:
#    - `intervalsDF`: a dataframe with intervals. Expected columns
#            are `Station.Name`, `Arrivalnum` and `Transmitter`. Other columns are ignored.
#    - `transmitter.id`: id of the transmitter for which movement edges should be
#            created.
#    - `allow.loops`: whether edges where receiver1 = receiver 2 (loops) should be included
#    - `unique.edges`: if TRUE, for every combination of receiver1 and receiver2, only one edge will be
#            returned that connects the two receivers. If it is FALSE, every migration event from receiver1
#            to receiver2 is reported as a separate edge.
intervals2movementedges <- function(intervalsDF, transmitter.id, allow.loops=FALSE, unique.edges=TRUE) {
  # sort the intervals DF by transmitter and arrival time
  d <- intervalsDF[order(intervalsDF$Transmitter, intervalsDF$Arrivalnum), ]
  # add a flag when a new transmitter starts
  d$new.transm <- c(1, diff(as.factor(d$Transmitter)))
  # add a flag when the station name of the interval differs from the previous interval
  d$stationdiff <- c(1, diff(as.factor(d$Station.Name)))
  # create a matrix with column1 containing the previous station (reveiver1) and column2
  # containing the next station (receiver2)
  if (allow.loops) {
    all.edges <- cbind(
      c(0,
        d[d$Transmitter==transmitter.id, "Station.Name"]
      ),
      c(d[d$Transmitter==transmitter.id, "Station.Name"],
        0),
      c(d[d$Transmitter==transmitter.id, "swimdistance"],
        0)
    )
  } else {
    all.edges <- cbind(
      c(0,
        d[d$stationdiff != 0 & d$Transmitter==transmitter.id, "Station.Name"]
      ),
      c(d[d$stationdiff != 0 & d$Transmitter==transmitter.id, "Station.Name"],
        0),
      c(d[d$stationdiff != 0 & d$Transmitter==transmitter.id, "swimdistance"],
        0)
    )
  }
  edges.df <- data.frame(
    receiver1=all.edges[2:(length(all.edges[,1]) -1), 1],
    receiver2=all.edges[2:(length(all.edges[,1]) -1), 2],
    swimdistance=all.edges[2:(length(all.edges[,1]) -1), 3]
  )
  # create a dataframe containing the edges and their counts
  if (unique.edges) {
    # if unique.edges = TRUE, we will only return unique edges and add the count for every edge as a separate `freq` attribute
    edges <- count(edges.df)
    return(edges)
  } else {
    return(edges.df)
  }
}

# ==================================
# Generate a movement matrix from a data frame containing detection intervals.
# A movement matrix has a row and a column for each receiver. Every cell indicates the
# number of times a fish migrated from receiver1 (the row) to receiver2 (the column)
intervals2movementmatrix <- function(intervalsDF, transmitter.id, allow.loops=FALSE) {
  edges <- intervals2movementedges(intervalsDF, transmitter.id, allow.loops=allow.loops)
  movementMatrix <- edges2movementmatrix(edges)
  return(movementMatrix)
}

# ==================================
# Generate a graph representing the movement of the fish carrying the given
# transmitter. Vertices (nodes) in the graph represent receivers while edges (arrows)
# represent movement between receivers.
# Parameters:
#    - `intervalsDF`: a dataframe with intervals. Expected columns
#            are `Station.Name`, `Arrivalnum`, `Departure_time`, `Transmitter`, `X`, `Y`,
#            and `residencetime`. Other columns are ignored.
#    - `transmitter.id`: id of the transmitter for which a movement graph should be
#            created.
#    - `allow.loops`: whether the resulting graph should include edges where receiver1 = receiver 2 (loops)
#    - `unique.edges`: if TRUE, for every combination of receiver1 and receiver2, only one edge will be
#            returned that connects the two receivers. If it is FALSE, every migration event from receiver1
#            to receiver2 is reported as a separate edge.
intervals2graph <- function(intervalsDF, transmitter.id, allow.loops=FALSE, unique.edges=TRUE) {
  edges <- intervals2movementedges(intervalsDF, transmitter.id, allow.loops=allow.loops, unique.edges=unique.edges)
  # sort the intervals DF by transmitter and arrival time
  d <- intervalsDF[order(intervalsDF$Transmitter, intervalsDF$Arrivalnum), ]
  station.attr <- ddply(d[, c("Transmitter", "X", "Y", "Station.Name",
                                 "residencetime", "Departure_time")],
                           .(Transmitter, Station.Name, X, Y), # aggregate by transmitter and station
                           summarize, total_time=sum(residencetime), # add total residencetime
                           avg_time=mean(residencetime), # add mean residencetime
                           last_departure=max(ymd_hms(Departure_time))
                        ) # add last departure time
  
  # select all station names that where visited
  all.vertices <- c(as.character(edges$receiver1),
                    as.character(edges$receiver2))

  # create a dataframe containing all station names and their counts
  unique.vertices <- count(all.vertices)
  # fix the count. All vertices are counted double, except for the first occurrence of the first vertex and the last occurrence of the last vertex
  unique.vertices$freq <- sapply(unique.vertices$freq,
                                 function(x) {
                                   if (x%%2 == 0) {
                                     return(x/2)
                                   } else {
                                     return((x+1)/2)
                                   }
                                }
                              )
  colnames(unique.vertices) <- c("Station.Name", "count")
  # join the vertices (station names) with the station.attr. The one holding the additional
  # attributes such as total_time and last_departure
  vertices <- merge(unique.vertices, station.attr[station.attr$Transmitter==transmitter.id, ])
  # create a graph with the edges and vertices
  g <- graph.data.frame(edges, vertices=vertices)
  return(g)
}


# ==================================
# Get a dataframe with the total number of passages per station
# Parameters:
#    - indf: input data frame with interval data
#    - transmitter: character with the transmitter id
#
# The result will be a dataframe with three columns `transmitter`, `station` and `count`
vertex.count.df <- function(indf, transmitter) {
  g <- intervals2graph(indf, transmitter, allow.loops = TRUE, unique.edges=FALSE) # when unique.edges is set to FALSE, V(g)$count corresponds to the actual number of passages
  df <- data.frame(transmitter=rep(transmitter, length(V(g))), station=c(V(g)$name), count=c(V(g)$count))
  return(df)
}

# ==================================
# Get a matrix with a column for every transmitter and a row for every station.
# Each cell in this matrix notes the number of passages for a given individual at
# a station.
passages.matrix <- function(indf) {
  transmitters <- unique(indf$Transmitter)
  outdf <- data.frame(transmitter=c(), station=c(), count=c())
  for (transmitter in transmitters) {
    tmpdf <- vertex.count.df(indf, transmitter)
    outdf <- rbind(outdf, tmpdf)
  }
  m <- sparseMatrix(i=as.numeric(as.factor(outdf$station)),
                    j=as.numeric(as.factor(outdf$transmitter)),
                    x=outdf$count)
  passagesDF <- as.data.frame(as.matrix(m))
  row.names(passagesDF) <- levels(as.factor(outdf$station))
  colnames(passagesDF) <- levels(as.factor(outdf$transmitter))
  return(passagesDF)
}

# ==================================
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

# ==================================
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

# ==================================
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
