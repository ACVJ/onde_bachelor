# data_collection.R
library(udp)

# Setup UDP receiver
setup_udp_receiver <- function(port = 7562) {
    u <- udp_socket()
    udp_bind(u, port = port)
    return(u)
}

# Function to process received data
process_tap_data <- function(data) {
    # Split the received string into values
    values <- as.numeric(strsplit(data, ",")[[1]])
    
    # Create data frame
    tap <- data.frame(
        participant = values[1],
        timestamp = values[2],
        condition = values[3],
        trial = values[4],
        tap_number = values[5],
        group = values[6]
    )
    
    return(tap)
}

# Main data collection function
collect_tap_data <- function(duration = 30) {
    socket <- setup_udp_receiver()
    tap_data <- data.frame()
    
    cat("Collecting tap data...\n")
    start_time <- Sys.time()
    
    while (difftime(Sys.time(), start_time, units="secs") < duration) {
        data <- udp_recv(socket)
        if (!is.null(data)) {
            cat("Received:", data, "\n")
            new_tap <- process_tap_data(data)
            tap_data <- rbind(tap_data, new_tap)
        }
        Sys.sleep(0.001)
    }
    
    udp_close(socket)
    return(tap_data)
}

# Test the connection
test_udp_connection <- function() {
    socket <- setup_udp_receiver()
    cat("Waiting for data from Bela...\n")
    cat("Press Ctrl+C to stop\n")
    
    while(TRUE) {
        data <- udp_recv(socket)
        if (!is.null(data)) {
            cat("Received:", data, "\n")
        }
        Sys.sleep(0.001)
    }
}