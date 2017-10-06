#
#
# S. Van Hoey
#

#' Function to clean the data format (prepending and trailing "?)
#'
#' @param filename string name of the file to remove the redundant "
#' @param cleaned_name string name of the file to save the result
#'
clean_dataformat <- function(filename, cleaned_name) {
    # read file as text strings
    con <- file(filename, "r",
                blocking = FALSE)
    data <- readLines(con)
    data <- gsub("\"", "", data) # remove overload of ""
    close(con)

    # write a cleaned version of the file
    con <- file(cleaned_name, "w", blocking = FALSE)
    data <- writeLines(data, con)
    close(con)
}