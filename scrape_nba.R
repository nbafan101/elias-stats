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

fetch_and_save <- function(url, name) {
  message("Processing: ", name)
  res <- GET(url)
  raw_txt <- content(res, as = "text", encoding = "UTF-8")

  # Always save raw text for debugging
  write_file(raw_txt, file.path("data", paste0(name, "_raw.txt")))

  # Clean text
  clean_txt <- gsub("[[:cntrl:]]", "", raw_txt)

  # Try parsing JSON
  parsed <- tryCatch(
    fromJSON(clean_txt, flatten = TRUE),
    error = function(e) {
      message("⚠️ Failed to parse JSON for ", name, ": ", e$message)
      return(NULL)
    }
  )

  if (!is.null(parsed)) {
    saveRDS(parsed, file = file.path("data", paste0(name, ".rds")))
    write_json(parsed, path = file.path("data", paste0(name, ".json")),
               pretty = TRUE, auto_unbox = TRUE)
  }
}

walk2(urls, names(urls), fetch_and_save)

# Always write a log so data/ isn’t empty
log_file <- file.path("data", "scrape_log.txt")
writeLines(
  paste("Last run:", Sys.time(), "UTC"),
  log_file
)
