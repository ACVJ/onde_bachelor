# experiment_control.R

run_trial <- function(term, group_id, condition, trial, phase) {
    cat("Setting up trial...\n")
    ssh_address <- "root@192.168.6.2"
    
    # Copy parameters to Bela
    cat("Copying parameters to Bela...\n")
    scp_command <- sprintf('scp current_params %s:/root/Bela/projects/rhythm_sync_experiment/\r', 
                          ssh_address)
    rstudioapi::terminalSend(term, scp_command)
    Sys.sleep(3)
    
    # Run the Bela program - MODIFIED to use proper Bela run command
    cat("Starting Bela program...\n")
    run_command <- sprintf('ssh %s "cd /root/Bela && ./scripts/run_project.sh projects/rhythm_sync_experiment"\r', 
                          ssh_address)
    cat("Executing:", run_command, "\n")
    rstudioapi::terminalSend(term, run_command)
    
    # Wait for user to stop the program
    readline("Press Enter to stop the program...")
    
    # Stop the Bela program
    stop_command <- sprintf('ssh %s "cd /root/Bela && ./scripts/stop_running.sh"\r',
                           ssh_address)
    rstudioapi::terminalSend(term, stop_command)
    Sys.sleep(2)
    
    # Get the data files
    cat("Retrieving data files...\n")
    get_data_command <- sprintf('scp %s:/root/Bela/projects/rhythm_sync_experiment/data/*_g%d_c%d_t%d_%s.csv ./data/\r',
                               ssh_address, group_id, condition, trial, phase)
    rstudioapi::terminalSend(term, get_data_command)
    Sys.sleep(3)
    
    cat("Trial complete!\n")
}