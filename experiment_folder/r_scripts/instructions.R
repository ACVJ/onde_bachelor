library(tcltk)

# General function to create a window with a label and button
create_window <- function(title, message, button_text, next_function = NULL, position_offset = 0) {
  win <- tktoplevel()
  tkwm.title(win, title)
  
  # Add a label with instructions
  label <- tklabel(win, text = message, font = "Helvetica 16", justify = "center", padx = 20, pady = 20)
  tkpack(label, padx = 20, pady = 20)
  
  # Add a button with customized appearance
  action_button <- tkbutton(win, text = button_text, font = "Helvetica 14", relief = "raised", 
                            width = 20, height = 2, # Adjust width and height to give it more size
                            command = function() {
                              tkdestroy(win)  # Close the current window
                              if (!is.null(next_function)) next_function()  # Call next window function
                            })
    tkpack(action_button, padx = 20, pady = 20)
    tkwait.window(win)
}

# Function to create the first window
first_window <- function() {
  create_window("WELCOME!!", 
                "\nWelcome to the Rhythm Synchronization Experiment!\n
-----------------------------------------------\n
******************Instructions******************\n
- Listen to 4 metronome beats\n
- Continue tapping at the tempo given by the metronome beats\n\n", 
"Continue to assigned key", second_window)
}

# Function to create the second window
second_window <- function() {
  create_window("Participant roles", 
                "- Each participant uses their assigned key:\n
- Participant to the left: Blue dot. \n
Role-name: 'Blue' \n\n
- Participant in the middle: Black dot:\n
Role-name: 'Black' \n\n
- Participant to the right: Pink dot  \n
Role-name: 'Pink' \n\n.", 
                "continue to instructions", third_window)
}

third_window <- function() {
    create_window("Experiment Instructions", 
    "When your taps no longer produce sounds, stop tapping and move on to the next trial\n
The experiment has 3 conditions. \n 
At the beginning of each experiment condition, there will be a practice trial.\n\n
After each trial, there will be a scale: \n
Each participant is asked to rate their experience of xyz \n 
While rating the experience, the other participants must *****TURN AWAY FROM THE SCREEN*****\n\n
Estimated time to complete: 20min. \n",
    "Begin practice")
}

# Start the application with the first window


condition_window <- function(condition) {
    instructions <- switch(condition,
        "123" = "Tap in sequence: First Blue, then Black, then Pink",
        "231" = "Tap in sequence: First Black, then Pink, then Blue",
        "312" = "Tap in sequence: First Pink, then Blue, then Black",
        "Simultaneous" = "All participants tap together at the same time - one tap together makes one tone",
        "23-1" = "Black and Pink tap together, then Blue taps alone",  
        "1-23" = "Blue taps alone, then Black and Pink tap together",
        "Unknown condition"
    )
    create_window("Instructions for upcoming experimental condition", 
    paste(instructions, "\nRemember:\n
    Listen to metronome speed\n
    Continue at the same tempo\n
    You'll tap for 24 tones total\n\n"),
    "Begin practice")
}

experiment_instructions <- function(condition) {
    instructions <- switch(condition,
        "123" = "Tap in sequence: First Blue, then Black, then Pink",
        "231" = "Tap in sequence: First Black, then Pink, then Blue",
        "312" = "Tap in sequence: First Pink, then Blue, then Black",
        "Simultaneous" = "All participants tap together at the same time - one tap together makes one tone",
        "23-1" = "Black and Pink tap together, then Blue taps alone",  
        "1-23" = "Blue taps alone, then Black and Pink tap together",
        "Unknown condition"
    )
    create_window("Experiment Instructions", 
    paste("\nBeginning Test Trials\n
Now starting the recorded trials. Same procedure as practice.\n
Remember, the order is as follows:", instructions, "
This order will remain until further instructions"),
    "Begin experiment trials")
}

condition_complete <- function() {
    create_window("Condition complete", 
    "Condition Complete",
    "Proceed to next condition")
}

experiment_complete <- function() {
    create_window("Experiment Complete", 
    "Thank you for participating!",
    "Exit experiment")
}

rating_instructions_window <- function(participant) {
    create_window("Rating Instructions", 
    paste("\nParticipant", participant, 
", please provide your rating. \n A new window will open. Click in it to rate your experience of the task.\n
X-axis: \n
No control - Full control \n
0 = Can't control the task, 1 = Full control of the task)\n\n
Y-axis: \n
Independent control - Shared control \n 
0 = 'Control is independent of the others', 1 = 'Control shared with the others)\n"), 
"Proceed to rating")
}
