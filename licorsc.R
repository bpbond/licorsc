# Convert JSON download from a LI-COR smart chamber into a data frame
# Ben Bond-Lamberty June 2024

library(jsonlite)

x <- jsonlite::read_json("TEMPESTX_20240613.json")

final_dat <- list()

# Loop through all observations (e.g., collars)
for(obs in seq_along(x$datasets)) {
  message("Reading observation = ", obs)
  dat <- x$datasets[[obs]][[1]]
  
  # Loop through all repetitions within an observation
  for(rep in seq_along(dat$reps)) {
    # Info on observation and rep
    rep_df <- data.frame(obs = obs, rep = rep)
    
    message("rep = ", rep)
    repdat <- dat$reps[[rep]]

    # The header section contains information on instrument, 
    # dead band, volume, etc. Store as a 1-row data frame
    header_df <- as.data.frame(repdat$header)
    
    # Convert main observational data into a data frame
    data_info <- list()
    for(i in names(repdat$data)) {
      data_info[[i]] <- unlist(repdat$dat[[i]])
    }
    data_df <- as.data.frame(data_info)
    
    # Convert footer flux info into a 1-row data frame
    footer_info <- list()
    for(i in seq_along(repdat$footer$fluxes)) {
      fdf <- repdat$footer$fluxes[[i]]
      gasname <- fdf$name
      fdf$name <- NULL
      names(fdf) <- paste(gasname, names(fdf), sep = "_")
      footer_info[[i]] <- as.data.frame(fdf)
    }
    footer_df <- as.data.frame(footer_info)
    
    # Combine and store; note that the 1-row data frames get 
    # replicated to have as many rows as the data
    final_dat[[paste(obs, rep)]] <- cbind(rep_df, header_df, data_df, footer_df)    
  }
}

# Combine everything into a single data frame
out <- do.call("rbind", final_dat)

library(lubridate)
out$TIMESTAMP <- ymd_hms(out$Date, tz = out$TimeZone[1])

