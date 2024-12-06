import librosa
import numpy as np

# Load the audio file
y, sr = librosa.load("metronome_timing_test.wav", sr=None)

# Set parameters for onset detection
onset_frames = librosa.onset.onset_detect(
    y=y,
    sr=sr,
    delta=0.5,  # Adjust sensitivity: higher = less sensitive 
    backtrack=True,  # Enable for more precise alignment with tone start
    pre_max=10,  # Number of frames to consider before a peak
    post_max=10  # Number of frames to consider after a peak
)

# Convert onset frames to time
onset_times = librosa.frames_to_time(onset_frames, sr=sr)

# Print results
print("Onset Times:", onset_times)

# Calculate inter-onset intervals (IOIs)
iois = np.diff(onset_times)
print("Inter-Onset Intervals:", iois)
