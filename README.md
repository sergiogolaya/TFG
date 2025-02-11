# TFG

# EMG Signal Processing and Analysis

## Overview
This project focuses on processing, normalizing, and analyzing electromyography (EMG) signals recorded from multiple muscles during movement. The provided MATLAB scripts perform key tasks such as filtering, event detection, normalization, and cross-correlation analysis to refine and interpret EMG data effectively.

## Project Structure
The repository contains the following MATLAB scripts:

### 1. `event_detection_refinement.m`
**Purpose:**
- Loads raw EMG data from an Excel file.
- Applies preprocessing, including bandpass filtering and adaptive notch filtering to remove noise and power line interference.
- Extracts signal envelopes and normalizes them.
- Detects movement events using an adaptive percentile-based thresholding method.
- Clusters detected events to refine movement segmentation.
- Allows manual selection of movement repetitions to further refine segmentation.
- Saves the processed data into a structured `.mat` file.

**Key Features:**
- Uses a Butterworth bandpass filter (20–450 Hz) to remove unwanted frequencies.
- Detects movement repetitions based on envelope amplitude thresholds.
- Provides user interaction for refining segmentation.

### 2. `normalization.m`
**Purpose:**
- Loads previously processed EMG data.
- Normalizes each movement repetition to a standard time scale (0–100%).
- Uses interpolation to align EMG envelopes across repetitions for comparison.
- Saves the normalized data into new `.mat` files.

**Key Features:**
- Ensures consistent time scaling for all repetitions.
- Uses linear interpolation to align different movement durations.
- Provides visual comparison between original and normalized envelopes.

### 3. `intra_cross_correlation.m`
**Purpose:**
- Loads normalized EMG data for a patient.
- Computes cross-correlation matrices between repetitions for each muscle.
- Displays heatmaps of the cross-correlation results.
- Saves computed correlation matrices for further analysis.

**Key Features:**
- Measures similarity between repetitions for consistency analysis.
- Visualizes results using heatmaps and overlaid EMG envelope plots.
- Saves structured correlation results for each patient.

## How to Use
1. **Preprocess Raw Data:** Run `event_detection_refinement.m` to filter and segment EMG data.
2. **Normalize Data:** Use `normalization.m` to standardize the time scale of repetitions.
3. **Analyze Repetition Consistency:** Execute `intra_cross_correlation.m` to assess similarity between repetitions.

## Dependencies
- MATLAB with Signal Processing Toolbox.
- EMG data stored in `.xlsx` format for preprocessing.
- `.mat` file compatibility for storing processed data.

## Future Improvements
- Implement automatic parameter tuning for event detection.
- Add support for real-time EMG analysis.
- Improve UI interaction for manual selection.

## Author
Sergio García Olaya

