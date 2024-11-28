# test_ssh.R
library(rstudioapi)

test_ssh_connection <- function() {
    # Introduce a loop to simulate multiple attempts
    for (i in 1:10) {
        Sys.sleep(runif(1, 1, 3))  # Random delay between 1 to 3 seconds
        
        # Create a new terminal for each attempt
        terminal_name <- sprintf("TestBelaTerm_%d", i)
        term <- rstudioapi::terminalCreate(terminal_name)
        
        cat("Attempting to connect to Bela (Attempt", i, ")\n")
        
        # Send the SSH command
        ssh_command <- "ssh root@192.168.6.2\r"
        rstudioapi::terminalSend(term, ssh_command)
        cat("Sent command:", ssh_command, "\n")  # Log the command sent
        
        # Wait for a moment to allow the command to process
        Sys.sleep(2)  # Adjust this delay as needed
        
        # Check the terminal output by sending a command to list the current directory
        ls_command <- "ls\r"
        rstudioapi::terminalSend(term, ls_command)
        cat("Sent command:", ls_command, "\n")  # Log the command sent
        
        # Wait for the output to be processed
        Sys.sleep(2)
        
        # Close the terminal after each attempt
        rstudioapi::terminalKill(term)
    }
}

# Run the test
test_ssh_connection()