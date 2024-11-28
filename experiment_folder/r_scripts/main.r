# main.R
source("r_scripts/rating_scales.R")
source("r_scripts/instructions.R")

library(rstudioapi)
pacman::p_load(tcltk)

cleanup_terminals <- function() {
    # Get all terminals
    terminals <- rstudioapi::terminalList()
    
    # Kill any existing BelaTerm terminals
    for(term in terminals) {
        if(grepl("BelaTerm", term$caption)) {
            rstudioapi::terminalKill(term$id)
        }
    }
    Sys.sleep(2)  # Wait for cleanup
}

get_trial_data <- function(term, group_id, condition, trial) {
    # Debug output at start
    cat("\nStarting get_trial_data with terminal_id:", term, "\n")
    
    # Create local data directory if it doesn't exist
    dir.create("data", showWarnings = FALSE)
    
    # Construct file paths
    remote_file <- sprintf("/root/Bela/projects/mainB/data/trial_%d_%s_%d.csv",
                          group_id, condition, trial)
    local_file <- sprintf("data/trial_%d_%s_%d.csv",
                         group_id, condition, trial)
    
    # Try to copy the file
    tryCatch({
        cat("Copying data from Bela...\n")
        scp_command <- sprintf('scp root@192.168.6.2:%s %s\r',
                              remote_file, local_file)
        cat("Executing command:", scp_command, "\n")
        rstudioapi::terminalSend(term, scp_command)
        Sys.sleep(5)  # Increased sleep time
    }, error = function(e) {
        cat("Error during file transfer:", e$message, "\n")
        return(FALSE)
    })
    
    # Verify file was copied
    if(file.exists(local_file)) {
        cat(sprintf("Data saved to: %s\n", local_file))
        return(TRUE)
    } else {
        cat("Warning: Data file not found at:", local_file, "\n")
        return(FALSE)
    }
}


run_experiment_trial <- function(group_id, condition, trial) {
    cat(sprintf("\nStarting trial: Group %d, Condition %s, Trial %d\n", 
                group_id, condition, trial))
    
    # Create new terminal
    terminal_name <- sprintf("BelaTerm_%d_%s_%d", group_id, condition, trial)
    term <- rstudioapi::terminalCreate(terminal_name)
    Sys.sleep(4)
    
    # Connect to Bela
    cat("Connecting to Bela...\n")
    rstudioapi::terminalSend(term, "ssh root@192.168.6.2\r")
    Sys.sleep(5)
    rstudioapi::terminalSend(term, "ssh root@192.168.6.2\r")

    cat("Checking Bela data directory...\n")
    rstudioapi::terminalSend(term, "mkdir -p /root/Bela/projects/mainB/data\r")
    Sys.sleep(1)
    
    cat("Checking Bela directory contents before trial...\n")
    rstudioapi::terminalSend(term, "ls -l /root/Bela/projects/mainB/data/\r")
    Sys.sleep(1)
    
    # Set parameters
    cat("Setting parameters...\n")
    param_command <- sprintf("echo '%d %s %d' > /root/Bela/projects/mainB/current_params\r",
                           group_id, condition, trial)
    rstudioapi::terminalSend(term, param_command)
    Sys.sleep(1)
    
    # Run project
    cat(sprintf("Running %s ...\n", condition))
    rstudioapi::terminalSend(term, "cd /root/Bela && ./scripts/run_project.sh mainB\r")
    
    cat("Trial is running. Press Enter when the trial is complete...\n")
    readline("Press Enter to stop...")
    
    # Stop the project
    cat("Stopping project...\n")
    rstudioapi::terminalSend(term, "\x03")  # Send Ctrl+C
    Sys.sleep(2)
    
    # NEW: Exit Bela before retrieving data
    cat("Exiting Bela...\n")
    rstudioapi::terminalSend(term, "exit\r")
    Sys.sleep(2)
    
    # Get data using the get_trial_data function
    cat("Retrieving data...\n")
    if(!get_trial_data(term, group_id, condition, trial)) {
        cat("Warning: Failed to retrieve data for trial\n")
    }
    
    # Collect ratings if this is not a practice trial (condition != 0)
    cat("\nCollecting ratings for this trial...\n")
    ratings <- collect_ratings(group_id, condition, trial)
    if (trial != 0 ) {   #lave om når practice vbliver genintroducert
         save_ratings(ratings)
    }
    
    # Cleanup terminal
    rstudioapi::terminalKill(term)
}

process_experiment_data <- function(group_id) {
    cat("Processing experiment data...\n")
    
    # List all data files for this group
    files <- list.files("data", 
                        pattern = "trial_.*\\.csv",
                        full.names = TRUE)
    
    cat("Found", length(files), "files to process\n")
    
    # Debugging: Print all found files
    cat("All found files:\n")
    print(files)
    
    # Filter files based on group_id
    selected_files <- files[sapply(files, function(file) {
        # Extract the trial number from the file name
        matches <- regmatches(file, regexpr("trial_(\\d+)_", basename(file), perl = TRUE))
        
        # Debugging: Print matches
        cat("Matches for file", file, ":", matches, "\n")
        
        # Check if matches are found and if they match the group_id
        if (length(matches) > 0) {
            # Extract the numeric part from the match
            trial_number <- as.numeric(sub("trial_(\\d+)_.*", "\\1", matches))
            return(trial_number == group_id)
        } else {
            return(FALSE)  # No match found
        }
    })]
    
    cat("Selected", length(selected_files), "files matching group ID:", group_id, "\n")
    
    # Debugging: Print selected files
    cat("Selected files:\n")
    print(selected_files)
    
    # Read and combine all selected files
    all_data <- data.frame()
    
    for(file in selected_files) {
        if (!is.na(file)) {  # Check if the file path is not NA
            cat("Reading file:", file, "\n")
            data <- tryCatch({
                read.csv(file, header = TRUE, stringsAsFactors = FALSE, na.strings = c("", "NA"))
            }, error = function(e) {
                cat("Error reading file:", file, ":", e$message, "\n")
                return(NULL)  # Return NULL if there's an error
            })
            
            if (!is.null(data)) {
                cat("  Found", nrow(data), "rows\n")
                all_data <- rbind(all_data, data)
            } else {
                cat("Warning: No data read from file:", file, "\n")
            }
        } else {
            cat("Warning: File path is NA, skipping...\n")
        }
    }
    
    if(nrow(all_data) > 0) {
        # Save combined data
        combined_file <- sprintf("data/group_%d_all_data.csv", group_id)
        write.csv(all_data, combined_file, row.names = FALSE)
        cat("\nCombined data saved to:", combined_file, "\n")
        cat("Total rows:", nrow(all_data), "\n")
    } else {
        cat("No data was found to combine\n")
    }
    
    return(all_data)
}


run_full_experiment <- function(group_id) {
    #ask for group number
    group_id <- as.integer(readline("Enter group number: "))

    # Welcome and initial instructions
    first_window()

    # Practice trial
   # cat("\nStarting practice trial...\n")
  #  run_experiment_trial(group_id, "Practice", 0)
    
    # Run experimental trials
    conditions <- c("23-1",  "1-23", "Simultaneous", "123", "231", "312")  # Add more conditions as needed. evt. randomize 
    for(condition in conditions) {
        condition_window(condition)
        #readline("Enter group number: ")

        run_experiment_trial(group_id, condition, 0)

        # Display test instructions
        experiment_instructions(condition)
        #readline("Enter group number: ")
    
        for(trial in 1:1) {  # Adjust number of trials as needed
            run_experiment_trial(group_id, condition, trial)
        }
        condition_complete()
    }
    
    # Process and save all data
    process_experiment_data(group_id)
    
    # Complete
    experiment_complete()
}

#Running the experiment
tryCatch({
    run_full_experiment()
}, error = function(e) {
    cat("Error in experiment:", e$message, "\n")
    # Final cleanup on error
    cleanup_terminals()
})