# EMG Signal Processing and Analysis

## Overview
This project focuses on processing, normalizing, and analyzing electromyography (EMG) signals recorded from multiple muscles during movement.  
The provided MATLAB scripts perform key tasks such as filtering, event detection, normalization, cross-correlation analysis, and combining repetitions for refined interpretation of EMG data.

---

## Project Structure

### 1. `a_event_detection.m`
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
- Implements adaptive percentile-based thresholding for event detection.
- Provides user interaction for refining segmentation via graphical selection.

---

### 2. `b_normalization.m`
**Purpose:**
- Loads previously processed EMG data.
- Normalizes each movement repetition to a standard time scale (0–100%).
- Uses piecewise cubic Hermite interpolation (pchip) to align EMG envelopes across repetitions.
- Saves the normalized data into new `.mat` files.

**Key Features:**
- Ensures consistent time scaling for all repetitions.
- Provides visual comparison between original and normalized envelopes.
- Processes all files in a directory automatically.

---

### 3. `c_intra_cross_correlation.m`
**Purpose:**
- Computes cross-correlation matrices between repetitions for each muscle within individual subjects.
- Allows time shifts (±25 samples) to find optimal alignment.
- Calculates mean and standard deviation of correlation values.
- Saves correlation results for each patient.

**Key Features:**
- Measures similarity between repetitions for consistency analysis.
- Visualizes results using heatmaps.
- Performs cross-subject analysis to compute average correlations per muscle.

---

### 4. `d_combine_reps_mean.m`
**Purpose:**
- Combines multiple EMG repetitions into a single representation using mean and standard deviation.
- Creates a summarized EMG profile for each muscle across repetitions.
- Saves combined data with standard deviation information.

**Key Features:**
- Provides a robust way to summarize multiple repetitions.
- Visualizes combined signals with standard deviation shading.
- Processes all files in a directory automatically.

---

### 5. `e_inter_cross_correlation.m`
**Purpose:**
- Computes cross-correlation across subjects to evaluate inter-subject similarity.
- Uses standard deviation-weighted envelopes for improved comparison.
- Generates heatmap visualizations of subject-to-subject correlations.
- Saves structured correlation results.

**Key Features:**
- Measures similarity across different individuals.
- Supports exclusion of specific subjects from analysis.
- Creates comprehensive subplot visualizations for all muscles.

---

### 6. `f1_emg_curve.m` & `f2_emg_curve.m`
**Purpose:**
- Computes representative EMG curves across all subjects.  
- `f1_emg_curve.m`: Generates individual and combined EMG plots with movement phase shading.  
- `f2_emg_curve.m`: Creates subplot arrangements suitable for publication.  

**Key Features:**
- Defines four movement phases (Reach, Grasp, Transport, Release) with distinct color coding.
- Provides both individual muscle plots and combined visualizations.
- Generates high-resolution images for publication.

---

### 7. `plot_muscle.m`
**Purpose:**
- Allows visualization of individual EMG repetitions per muscle.
- Supports interactive selection of muscles and data files.
- Provides options to plot all muscles or select one interactively.

**Key Features:**
- Facilitates visual inspection of EMG envelopes.
- Uses interactive selection for user convenience.
- Supports both normalized and DTW-aligned data.

---

## How to Use
1. **Preprocess Raw Data:** Run `a_event_detection.m` to filter and segment EMG data.  
2. **Normalize Data:** Use `b_normalization.m` to standardize the time scale of repetitions.  
3. **Analyze Intra-Subject Consistency:** Run `c_intra_cross_correlation.m` to measure repetition similarity within subjects.  
4. **Combine Repetitions:** Use `d_combine_reps_mean.m` to create summarized EMG profiles.  
5. **Analyze Inter-Subject Similarity:** Run `e_inter_cross_correlation.m` to measure similarity across subjects.  
6. **Generate Representative EMG Curves:** Use `f1_emg_curve.m` or `f2_emg_curve.m` for publication-ready visualizations.  
7. **Visualize Individual Muscle Repetitions:** Run `plot_muscle.m` for detailed inspection.  

---

## Dependencies
- MATLAB with Signal Processing Toolbox  
- EMG data stored in `.xlsx` format for preprocessing  
- `.mat` file compatibility for storing processed data  

---

## Author
**Sergio García Olaya**
