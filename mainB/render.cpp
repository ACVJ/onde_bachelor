#include <Bela.h>
#include <libraries/Midi/Midi.h>
#include <stdlib.h>
#include <cmath>
#include <fstream>
#include <libraries/WriteFile/WriteFile.h>
#include <string>
#include <iomanip>
#include <set>
#include <algorithm>
#include <vector>

std::set<int> activeParticipants;
std::set<int> requiredParticipants = {1, 2, 3}; //all colours 
std::set<int> lonerParticipants = {1}; //blue 
std::set<int> subgroupParticipants = {2, 3}; //black and pink 

// Global variables
WriteFile gDataFile; // Use WriteFile instead of std::ofstream
int gCurrentGroup = 0;
std::string gCurrentCondition = "Simultaneous"; //change later - to not a const 
int gCurrentTrial = 1;

float participant = 0.0;

// MIDI setup
Midi gMidi;
const char* gMidiPort0 = "hw:1,0,0";

std::string gCurrentPhase;

unsigned long gStartTime;
int gTapCount = 0;

// Oscillator state
float gPhase = 0; 
float gFrequency = 0;
float gAmplitude = 0;
double freq[6] = {440.0, 493.88, 554.37, 659.26, 739.99, 880.0};
int tone_nr = 0;

// List of active notes
const int kMaxNotes = 16;
int gActiveNotes[kMaxNotes];
int gActiveNoteCount = 0;

// Cue tone variable
int CueTone = 0; 
int cueTonePlayCount = 0;
int cueToneCounter = 0;
bool playingCueTone = true;

int gTotalTaps = 0;
bool gTrialComplete = false;

float audioSampleRate = 0;
int frameCounter;

// Vector to hold log data
std::vector<float> logs(2); // Adjust size as needed

unsigned int writeFileSize = logs.size() + 5000;

bool setup(BelaContext *context, void *userData)
{
    rt_printf("Audio sample rate: %f\n", context->audioSampleRate);
    audioSampleRate = context->audioSampleRate;

    // Initialise the MIDI device
    if(gMidi.readFrom(gMidiPort0) < 0) {
        rt_printf("Unable to read from MIDI port %s\n", gMidiPort0);
        return false;
    }
    gMidi.writeTo(gMidiPort0);
    gMidi.enableParser(true);
    

    
    // Read parameters
    std::ifstream params("/root/Bela/projects/mainB/current_params");
    if(!params) {
        rt_printf("Warning: Could not read parameters file\n");
        gCurrentGroup = 0;
        gCurrentCondition = "Simultaneous";
        gCurrentTrial = 1;
    } else {
        params >> gCurrentGroup >> gCurrentCondition >> gCurrentTrial;
        rt_printf("Parameters loaded: group=%d, condition=%s, trial=%d\n", 
                 gCurrentGroup, gCurrentCondition.c_str(), gCurrentTrial);
    }
    
    if (strcmp(gCurrentCondition.c_str(),"1-23") == 0 || strcmp(gCurrentCondition.c_str(),"23-1") == 0) { // From https://stackoverflow.com/questions/2603039/warning-comparison-with-string-literals-results-in-unspecified-behaviour 
    	requiredParticipants = {1, 2, 3, 4}; //create a set that can never be fulfilled by adding 4 
    	lonerParticipants = {1};
    	subgroupParticipants = {2, 3};
    } 
    
    if (strcmp(gCurrentCondition.c_str(),"Simultaneous") == 0) { // From https://stackoverflow.com/questions/2603039/warning-comparison-with-string-literals-results-in-unspecified-behaviour 
    	requiredParticipants = {1, 2, 3}; //create sets that can never be fulfilled by adding 4 
    	lonerParticipants = {1, 4};
    	subgroupParticipants = {2, 3, 4};
    }
    
    if (strcmp(gCurrentCondition.c_str(),"123") == 0 || strcmp(gCurrentCondition.c_str(),"231") == 0 || strcmp(gCurrentCondition.c_str(),"312") == 0) { // From https://stackoverflow.com/questions/2603039/warning-comparison-with-string-literals-results-in-unspecified-behaviour 
    	requiredParticipants = {2}; //just making all sets "achivable" 
    	lonerParticipants = {1};
    	subgroupParticipants = {3};
    }
    
    char filename[100];
    sprintf(filename, "/root/Bela/projects/mainB/data/trial_%d_%s_%d.csv", 
            gCurrentGroup, gCurrentCondition.c_str(), gCurrentTrial);
            
    // Setup data logging with WriteFile
    gDataFile.setup(filename);
    gDataFile.setFormat("%f,%f\n"); // Set the format for logging
    gDataFile.setFileType(kText); // Set file type to text
    
    // Write CSV header
    rt_printf("Data logging setup for file: %s\n", filename);
    
    gTotalTaps = 0;
    gTrialComplete = false;
    
    gDataFile.setBufferSize(writeFileSize);
    
    return true;
}

unsigned int logIdx = 0;

void render(BelaContext *context, void *userData)
{		
	//reset log index maybe?
	logIdx = 0;

    // At the beginning of each callback, look for available MIDI messages
    while(gMidi.getParser()->numAvailableMessages() > 0) {
        MidiChannelMessage message;
        message = gMidi.getParser()->getNextChannelMessage();
        message.prettyPrint(); // Print the message data
        
        if(message.getType() == kmmNoteOn) {
            int noteNumber = message.getDataByte(0);
            int velocity = message.getDataByte(1); 
            
            if(velocity > 0) {
                if (!gTrialComplete && gActiveNoteCount < kMaxNotes) {
                    // Determine participant based on note number
                    if (noteNumber == 48) participant = 1;
                    else if (noteNumber == 59) participant = 2;
                    else if (noteNumber == 71) participant = 3;
                    else participant = 0; // Invalid participant key

                    if (participant > 0) {
                        // Log the keypress immediately
                        float timestamp = frameCounter / audioSampleRate;
                        
                        logs[0] = timestamp; // Timestamp
    					logs[1] = participant; // Participant number as float

                        // Log to file if buffer is full
                        if (logIdx < writeFileSize) {
                            logIdx += 2; // Increment log index by 2 for two values
                        }

                        // Check if we need to log to the file
                        if (logIdx >= writeFileSize) {
                            gDataFile.log(logs.data(), logIdx);
                            logIdx = 0; // Reset log index
                        }

                        rt_printf("Logged: time=%.3f, participant=%d\n",
                                  timestamp, participant);

                        // Add participant to activeParticipants for synchronization tracking
                        activeParticipants.insert(participant); // real-time safe? replace with ?? Giuliomoro 
                        // Check if all required participants have pressed their keys
                        if (std::includes(activeParticipants.begin(), activeParticipants.end(),
                                          subgroupParticipants.begin(), subgroupParticipants.end()) ||
                            std::includes(activeParticipants.begin(), activeParticipants.end(),
                                          lonerParticipants.begin(), lonerParticipants.end()) ||
                            std::includes(activeParticipants.begin(), activeParticipants.end(),
                                          requiredParticipants.begin(), requiredParticipants.end())
                                        ) {
                            
                            // All required participants pressed keys simultaneously
                            gActiveNotes[gActiveNoteCount] = noteNumber;
                            gActiveNoteCount++;
                            gFrequency = freq[tone_nr];
                            gAmplitude = 1;

                            // Reset activeParticipants for the next synchronization event
                            activeParticipants.clear();

                            // Increment total taps only for synchronized events
                            gTotalTaps++;
                            if (tone_nr < 5) {
                                tone_nr++;
                            } else {
                                tone_nr = 0;
                            }
                            
                            rt_printf("Tap %d/24: participant=%d\n", gTotalTaps, participant);

                            if (gTotalTaps >= 24) {
                                gTrialComplete = true;
                                rt_printf("\nTrial complete! 24 taps recorded.\n");
                            }
                        }
                    }
                }
            }
        } else if(message.getType() == kmmNoteOff) {
            int noteNumber = message.getDataByte(0);
            bool activeNoteChanged = false;

            // Go through all the active notes and remove any with this number
            for(int i = gActiveNoteCount - 1; i >= 0; i--) {
                if(gActiveNotes[i] == noteNumber) {
                    if (i == gActiveNoteCount-1) {
                        activeNoteChanged = true;
                    }
                    for (int j = i; j < gActiveNoteCount-1; j++) {
                        gActiveNotes[j] = gActiveNotes[j + 1];
                    }
                    gActiveNoteCount--;
                }
            }

            rt_printf("Note off: %d notes remaining\n", gActiveNoteCount);
            
            if(gActiveNoteCount == 0) {
                gAmplitude = 0;
            }
        }
    }

    // Cue Tones 
	for (unsigned int n = 0; n < context->audioFrames; n++) {
    frameCounter++;
    float value = 0;

    if (playingCueTone) {
        if (cueTonePlayCount < 4) { // Play 4 tones
            if (cueToneCounter < audioSampleRate / 3) {
            	//if (cueToneCounter == 1) { En mulighed for timing tjek
            		//float timestamp = frameCounter / audioSampleRate;
            		//#logs[0] = timestamp; // Timestamp
    				//logs[1] = 0.0; // Participant number as float
    				//logIdx += 2;
            	//}
            	gFrequency = 440.0;
                gAmplitude = 1;  // Play tone
            } else {
                gAmplitude = 0.0;  // Silence
            }
            cueToneCounter++;
            
            if (cueTonePlayCount == 3 && cueToneCounter >= audioSampleRate / 3) {
    			// Start preparing for new notes during the last silence period
    			playingCueTone = false; // End cue tone early
			}
            
            if (cueToneCounter >= audioSampleRate / 1.5) { // Cycle complete
                cueToneCounter = 0;
                cueTonePlayCount++;
            }

            value = sin(gPhase) * gAmplitude;
            gPhase += 2.0 * M_PI * gFrequency / audioSampleRate;
            if (gPhase > 2.0 * M_PI) gPhase -= 2.0 * M_PI;
            
        } 

		else {
            // Disable cue tone mode immediately after the last tone
            playingCueTone = false;
            cueToneCounter = 0;
            //gAmplitude = 0.0;  // Silence ensures no residual tone
        }
    }

    if (!playingCueTone && gActiveNoteCount > 0) {
        // Transition quickly to note playback
        gPhase += 2.0 * M_PI * gFrequency / audioSampleRate;
        if (gPhase > 2.0 * M_PI) gPhase -= 2.0 * M_PI;
        value = sin(gPhase) * gAmplitude;
    }
    
        	// Write audio output for each channel
        	for (unsigned int ch = 0; ch < context->audioOutChannels; ++ch) {
            	audioWrite(context, n, ch, value);

        	}
    	}

    // Write any leftover logs to the file
    if (logIdx > 0) {
        gDataFile.log(logs.data(), logIdx);
    }
}

void cleanup(BelaContext *context, void *userData)
{
    gDataFile.log(logs.data(), logIdx); // Ensure any remaining logs are written
    rt_printf("Data file closed\n");
} 