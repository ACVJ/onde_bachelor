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
                "\nWelcome to the experiment!\n
-----------------------------------------------\n
******************Instructions******************\n
- Listen to 4 metronome beats\n
- Continue tapping at the tempo given by the metronome beats\n
- When your taps no longer produce sounds, stop tapping. Experimenter will start the next trial\n\n", 
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
    "The experiment has 6 conditions. \n 
At the beginning of each experiment condition, there will be a practice trial.\n\n
After each trial, there will be a scale: \n
Each participant is asked to rate their experience of the trial. More information will be provided at that time\n 
While rating the experience, the other participants must *****TURN AWAY FROM THE SCREEN*****\n\n
Estimated time to complete: 20min. \n",
    "Continue")
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
    paste("Instructions for upcoming experimental condition \n\n", instructions, "\nRemember:\n
Listen to metronome speed\n
Continue at the same tempo\n
You'll tap for 24 tones total\n
Numbers and text will flow across the screen in the background. Do not pay attention to the screen\n
You only need to focus on listening and tapping.\n\n"),
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
    paste("\nBeginning Experiment Trials\n
Now starting the recorded trials. Same procedure as practice.\n
Remember, the order is as follows:", instructions, "
This order will remain until further instructions"),
    "Begin experiment trials")
}

trial_complete <- function() {
    create_window("Trial complete", 
    "Everybody get ready, the next trial is coming up",
    "Proceed to next trial")
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
", please provide your rating. OTHER PARTICIPANTS, PLEASE TURN AWAY FROM THE SCREEN \n A new window will open. Click in it to rate your experience of the task. How was your experience of control over the sounds generated.\n
X-axis: \n
Independent control - Shared control \n 
0 = Control is independent of the others', 1 = 'Control shared with the others\n
Y-axis: \n
No control - Full control \n
0 = Can't control the task, 1 = Full control of the task\n\n"), 
"Proceed to rating example")
}
#img <- tkimage.create('photo', file='Example_rating.png')
#imglab <- tklabel(pdlg, image = img)


library(tcltk)
library(tidyverse)

rating_instructions <- function() {
    # Create a new window for instructions
    instructions_window <- tktoplevel()
    tkwm.title(instructions_window, "Rating Instructions")
    
    # Add text instructions
    instructions_text <- "Please follow the instructions below to rate the items."
    tklabel(instructions_window, text = instructions_text, padx = 20, pady = 20) %>%
        tkpack()
    
    # Load and display the PNG image
    img_path <- "Example_rating.png"  # Specify the path to your PNG image
    img <- tcltk::tclVar(img_path)  # Store the image path in a Tcl variable
    tkimage <- tcltk::tcl("image", "create", "photo", "img", "-file", img)
    
    # Create a label to display the image
    imglab <- tklabel(instructions_window, image = tkimage)
    imglab %>% tkpack()
    
    # Add additional instructions or buttons as needed
    tkbutton(instructions_window, text = "OK", command = function() tkdestroy(instructions_window)) %>%
        tkpack(pady = 10)
    
    # Start the GUI event loop
    tkwait.window(instructions_window)
}

# Call the function to display the instructions
#rating_instructions()

library(tcltk)
library(magick)

# Function to display an image
display_image <- function(image_path) {
    # Preprocess the image
    resized_image <- image_read(image_path) %>%
        image_resize("90%")  # Resize to 50% of the original size

    # Save the resized image to a temporary file
    temp_image_path <- tempfile(fileext = ".png")
    image_write(resized_image, path = temp_image_path)

    # Create a main window
    window <- tktoplevel()

    # Load the resized image in Tcl/Tk
    photo <- tkimage.create("photo", file = temp_image_path)

    # Create a label widget and set the image
    label <- tklabel(window, image = photo)

    # Pack the label to display it in the window
    tkpack(label)

    # Create a button to close the window
    close_button <- tkbutton(window, text = "Proceed to rating scale", command = function() tkdestroy(window))
    tkpack(close_button, pady = 10)  # Add some padding for aesthetics

    # Run the event loop
    tkwait.window(window)
}


display_image_1 <- function() {
    display_image("Example_ratings.png")  # Replace with your first image path
}

display_image_2 <- function() {
    display_image("Example_rating2.png")  # Replace with your first image path
}

display_image_3 <- function() {
    display_image("Example_rating3.png") # Replace with your first image path
}
