# rating_scales.R
show_2d_rating <- function(participant) {
    # Create a new window for the rating
    x11(width = 8, height = 8)
    
    # Initialize variables
    rating <- NULL
    
    # Create the plot
    plot(0, 0, type = "n", 
         xlim = c(0, 1), ylim = c(0, 1),
         xlab = "No control - Full control", ylab = "Independent control - Shared control",
         main = sprintf("Participant %s: Click to rate your experience", participant))
    
    # Add grid
    grid()
    
    # Get mouse click
    cat("\nClick in the window to place your rating.\n")
    rating <- locator(1)
    
    # Close the window
    dev.off()
    
    # Return the rating
    return(list(
        x = rating$x,
        y = rating$y
    ))
}

# Collect ratings from all participants
collect_ratings <- function(group_id, condition, trial) {
    ratings <- data.frame()
    
    for(participant in c("Blue", "Black", "Pink")) {
        rating_instructions_window(participant)
       
         
        rating <- show_2d_rating(participant)
        
        ratings <- rbind(ratings, data.frame(
            group_id = group_id,
            condition = condition,
            trial = trial,
            participant = participant,
            control = rating$x,
            shared = rating$y,
            timestamp = Sys.time()
        ))
        
        cat(sprintf("Rating recorded: Control = %.2f, Synchronization = %.2f\n", 
            rating$x, rating$y))
    }
    
    return(ratings)
}

# Save ratings to file
save_ratings <- function(ratings) {
    filename <- file.path("data", 
        sprintf("group%s_ratings.csv", ratings$group_id[1]))
    
    # Append to file if it exists, create if it doesn't
    write.table(ratings, filename, 
        append = file.exists(filename),
        sep = ",",
        row.names = FALSE,
        col.names = !file.exists(filename))
}