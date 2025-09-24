library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)

# Where to save
dir.create("data", showWarnings = FALSE)

urls <- list(
  high_low = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/high_low.txt",
  leaders = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/leaders.txt",
  leaders_rookies = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/leaders_rookies.txt",
  team_opp_misc = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/team_opp_misc.txt"
)

# Function to clean and parse JSON-like text
fetch_json <- function(url) {
  res <- GET(url)
  raw_txt <- content(res, as = "text", encoding = "UTF-8")

  # remove non-printable chars
  clean_txt <- gsub("[[:cntrl:]]", "", raw_txt)

  # attempt parse
  parsed <- tryCatch(
    fromJSON(clean_txt, flatten = TRUE),
    error = function(e) {
      message("⚠️ Failed to parse: ", url)
      return(NULL)
    }
  )
  parsed
}

# Iterate and save each dataset
walk2(urls, names(urls), function(url, name) {
  message("Processing: ", name)
  data <- fetch_json(url)
  if (!is.null(data)) {
    saveRDS(data, file = file.path("data", paste0(name, ".rds")))
    write_json(data, path = file.path("data", paste0(name, ".json")), pretty = TRUE, auto_unbox = TRUE)
  }
})

# Always write a log so data/ isn’t empty
log_file <- file.path("data", "scrape_log.txt")
writeLines(
  paste("Last run:", Sys.time(), "UTC"),
  log_file
)
