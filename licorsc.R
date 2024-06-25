# Convert JSON downloads from a LI-COR smart chamber into a data frame
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

    # header contains info on instrument, dead bane, volume, etc.
    header_df <- as.data.frame(repdat$header)
    
    # convert main observational data into a d.f.
    dat_info <- list()
    for(i in names(repdat$data)) {
      dat_info[[i]] <- unlist(repdat$dat[[i]])
    }
    dat_df <- as.data.frame(dat_info)
    
    # convert footer flux info into a d.f.
    footer_info <- list()
    for(i in seq_along(repdat$footer$fluxes)) {
      fdf <- repdat$footer$fluxes[[i]]
      gasname <- fdf$name
      fdf$name <- NULL
      names(fdf) <- paste(gasname, names(fdf), sep = "_")
      footer_info[[i]] <- as.data.frame(fdf)
    }
    footer_df <- as.data.frame(footer_info)
    
    # Combine and store
    final_dat[[paste(obs, rep)]] <- cbind(rep_df, header_df, dat_df, footer_df)    
  }
}

# Combine everything into a single data frame
out <- do.call("rbind", final_dat)
