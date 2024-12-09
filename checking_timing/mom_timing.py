#import madmom
from madmom.features.onsets import OnsetPeakPickingProcessor, SpectralOnsetProcessor
import numpy as np
import matplotlib.pyplot as plt

# Load audio and process
proc = SpectralOnsetProcessor()
onset_proc = OnsetPeakPickingProcessor(threshold=0.7)

# Onset times
onset_times = onset_proc(proc("metronome_timing_test.wav"))
print("Madmom Onset Times:", onset_times)


onset_intervals =  np.diff(onset_times)
print("Madmom Onset Intervals:", onset_intervals)

# Plot the onset times
plt.figure(figsize=(10, 6))
plt.plot(onset_times, np.zeros_like(onset_times), 'bo', markersize=8)  # Onsets as blue dots
plt.yticks([])  # Hide y-axis labels
plt.xlabel("Time (seconds)")
plt.title("Onset Times")
plt.grid(True)
plt.show()


print("Onset Times (more precision):", onset_times)
print("Onset Intervals (more precision):", np.diff(onset_times))