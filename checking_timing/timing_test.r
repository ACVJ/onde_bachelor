pacman::p_load(tuneR)
pacman::p_load(seewave)

# Load audio file
sound <- readWave("metronome_timing_test.wav")

# Onset detection (manual tuning required)
onset_times <- timer(sound, threshold = 0.1)  # Adjust threshold

# Calculate IOIs
iois <- diff(onset_times)

print(onset_times)
print(iois)