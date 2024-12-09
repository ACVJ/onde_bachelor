import librosa
import numpy as np
import matplotlib.pyplot as plt

# Load the audio file
y, sr = librosa.load("metronome_timing_test.wav", sr=None)

# Set parameters for onset detection
onset_frames = librosa.onset.onset_detect(
    y=y,
    sr=sr,
    delta=0.6,  # Increased threshold to be more selective
    wait=3,     # Minimum number of frames between consecutive onsets
    pre_max=20,  # Increased window before peak
    post_max=20, # Increased window after peak
    pre_avg=100, # Longer window for baseline calculation
    post_avg=100,
    backtrack=True
)

# Convert onset frames to time
onset_times = librosa.frames_to_time(onset_frames, sr=sr)

# Calculate inter-onset intervals (IOIs)
iois = np.diff(onset_times)

# Print results
print("Number of onsets detected:", len(onset_times))
print("\nOnset Times (seconds):")
for i, t in enumerate(onset_times):
    print(f"Onset {i+1}: {t:.3f}")

print("\nInter-Onset Intervals (seconds):")
for i, ioi in enumerate(iois):
    print(f"IOI {i+1}: {ioi:.3f}")

# ... previous code remains the same until visualization part ...

# Visualize the waveform and onsets
plt.figure(figsize=(15, 5))

# Plot waveform
plt.plot(librosa.times_like(y), y, label='Waveform', alpha=0.7)

# Calculate a good y-position for markers (slightly above the waveform)
marker_height = np.max(np.abs(y)) * 1.1

# Plot onset markers with stems to make them more visible
plt.stem(onset_times, 
         np.ones_like(onset_times) * marker_height, 
         'r', 
         label='Onsets', 
         basefmt=' ',  # Hide the baseline
         markerfmt='rv')  # Red triangles as markers

plt.xlabel('Time (s)')
plt.ylabel('Amplitude')
plt.title(f'Waveform with {len(onset_times)} Detected Onsets')
plt.legend()
plt.grid(True)
plt.show()

# ... rest of the code remains the same ...

# Calculate and print statistics
mean_ioi = np.mean(iois)
std_ioi = np.std(iois)
print(f"\nIOI Statistics:")
print(f"Mean IOI: {mean_ioi:.3f} seconds")
print(f"Standard Deviation: {std_ioi:.3f} seconds")
print(f"Coefficient of Variation: {(std_ioi/mean_ioi)*100:.2f}%")