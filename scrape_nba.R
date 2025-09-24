library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)

# endpoints
urls <- list(
  high_low = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/high_low.txt",
  leaders = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/leaders.txt",
  leaders_rookies = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/leaders_rookies.txt",
  team_opp_misc = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/team_opp_misc.txt"
)

# generic fetch function
fetch_json <- function(url) {
  res <- GET(url)
  stop_for_status(res)
  content(res, as = "text", encoding = "UTF-8") %>%
    fromJSON(flatten = TRUE)
}

# helper to safely flatten lists into a data frame
to_df <- function(x) {
  if (is.data.frame(x)) return(x)
  if (is.list(x)) return(map_dfr(x, ~as.data.frame(.x)))
  return(data.frame(value = x))
}

dir.create("data", showWarnings = FALSE)

# iterate over endpoints
walk2(urls, names(urls), function(url, name) {
  dat <- fetch_json(url)
  
  # flatten the structure – most Elias JSON has a top-level "resultSets" or "rowSet"
  df <- NULL
  if ("resultSets" %in% names(dat)) {
    df <- map_dfr(dat$resultSets, ~to_df(.x$rowSet))
  } else if ("rowSet" %in% names(dat)) {
    df <- to_df(dat$rowSet)
  } else {
    df <- to_df(dat)
  }
  
  # save tidy table
  out_path <- file.path("data", paste0(name, ".csv"))
  write_csv(df, out_path)
  message("Saved: ", out_path)
})
