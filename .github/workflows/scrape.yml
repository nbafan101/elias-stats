library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)

# Elias endpoints
urls <- list(
  high_low        = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/high_low.txt",
  leaders         = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/leaders.txt",
  leaders_rookies = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/leaders_rookies.txt",
  team_opp_misc   = "https://cdn.nba.com/static/json/staticData/EliasGameStats/00/team_opp_misc.txt"
)

# Function: fetch, clean, parse JSON safely
fetch_json <- function(url) {
  res <- GET(url)
  stop_for_status(res)

  raw_txt <- content(res, as = "text", encoding = "UTF-8")

  # Clean invalid characters and trim to valid JSON
  clean_txt <- raw_txt |>
    gsub("[[:cntrl:]]", "", .) |>   # remove hidden control chars (^L etc.)
    sub("^[^{]*", "", .) |>         # drop everything before first {
    sub("[^}]*$", "", .)            # drop everything after last }

  # Try parsing; return NULL if fails
  out <- tryCatch(
    fromJSON(clean_txt, flatten = TRUE),
    error = function(e) {
      warning(paste("Failed to parse JSON from:", url, "->", e$message))
      return(NULL)
    }
  )

  list(parsed = out, raw = clean_txt)
}

# Helper: flatten to data frame if possible
to_df <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) return(x)
  if (is.list(x)) return(suppressWarnings(map_dfr(x, ~as.data.frame(.x))))
  return(data.frame(value = x))
}

# Output directory
dir.create("data", showWarnings = FALSE)

# Iterate over all endpoints
walk2(urls, names(urls), function(url, name) {
  message("Processing: ", name)

  res <- fetch_json(url)

  if (is.null(res$parsed)) {
    message(" -> Skipped (could not parse)")
    return(NULL)
  }

  dat <- res$parsed
  df <- NULL

  # Handle Elias JSON structure
  if ("resultSets" %in% names(dat)) {
    df <- map_dfr(dat$resultSets, ~to_df(.x$rowSet))
  } else if ("rowSet" %in% names(dat)) {
    df <- to_df(dat$rowSet)
  } else {
    df <- to_df(dat)
  }

  # Save raw cleaned JSON
  json_out <- file.path("data", paste0(name, ".json"))
  writeLines(res$raw, json_out)

  # Save CSV if dataframe exists
  if (!is.null(df) && nrow(df) > 0) {
    csv_out <- file.path("data", paste0(name, ".csv"))
    write_csv(df, csv_out)
    message(" -> Saved CSV: ", csv_out)
  } else {
    message(" -> No dataframe extracted for ", name)
  }
})
