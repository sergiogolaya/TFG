# EMG Signal Processing and Analysis

## Overview
This project focuses on processing, normalizing, and analyzing electromyography (EMG) signals recorded from multiple muscles during movement. The provided MATLAB scripts perform key tasks such as filtering, event detection, normalization, dynamic time warping (DTW) alignment, cross-correlation analysis, and combining repetitions for refined interpretation of EMG data.

## Project Structure
The repository contains the following MATLAB scripts:

### 1. `a1_event_detection.m`
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

### 2. `b_normalization.m`
**Purpose:**
- Loads previously processed EMG data.
- Normalizes each movement repetition to a standard time scale (0–100%).
- Uses interpolation to align EMG envelopes across repetitions for comparison.
- Saves the normalized data into new `.mat` files.

**Key Features:**
- Ensures consistent time scaling for all repetitions.
- Uses linear interpolation to align different movement durations.
- Provides visual comparison between original and normalized envelopes.

### 3. `c0_dtw_alignment.m` & `c0_median_dtw_alignment.m`
**Purpose:**
- Aligns EMG repetitions using Dynamic Time Warping (DTW).
- `c0_dtw_alignment.m` selects the best repetition (based on DTW distance) as the reference.
- `c0_median_dtw_alignment.m` uses the median repetition as the reference.
- Saves DTW-aligned EMG data into `.mat` files.

**Key Features:**
- Improves consistency of EMG data across repetitions.
- Supports different reference selection strategies.
- Ensures aligned signals for further analysis.

### 4. `c1_intra_cross_correlation.m` & `c12_dtw_intra_cross_correlation.m`
**Purpose:**
- Computes cross-correlation matrices between repetitions for each muscle.
- `c1_intra_cross_correlation.m` works on normalized EMG data.
- `c12_dtw_intra_cross_correlation.m` works on DTW-aligned data.
- Saves computed correlation matrices for further analysis.

**Key Features:**
- Measures similarity between repetitions for consistency analysis.
- Visualizes results using heatmaps.
- Saves structured correlation results for each patient.

### 5. `d1_combine_reps_mean.m` & `d2_combine_reps_pca.m`
**Purpose:**
- Combines multiple EMG repetitions into a single representation.
- `d1_combine_reps_mean.m` uses mean and standard deviation.
- `d2_combine_reps_pca.m` applies Principal Component Analysis (PCA) to extract the dominant component.

**Key Features:**
- Provides a robust way to summarize multiple repetitions.
- PCA-based combination captures the most representative EMG pattern.

### 6. `e1_inter_cross_correlation.m` & `e2_pca_inter_cross_correlation.m`
**Purpose:**
- Computes cross-correlation across subjects to evaluate inter-subject similarity.
- `e1_inter_cross_correlation.m` works on combined EMG data.
- `e2_pca_inter_cross_correlation.m` works on PCA-combined EMG data.
- Saves structured correlation results for further analysis.

**Key Features:**
- Measures similarity across different individuals.
- Supports visualization of subject-to-subject correlation.

### 7. `f1_emg_curve.m` & `f2_pca_emg_curve.m`
**Purpose:**
- Computes representative EMG curves across subjects.
- `f1_emg_curve.m` generates mean EMG curves with standard deviation shading.
- `f2_pca_emg_curve.m` generates PCA-based EMG profiles.
- Saves visualizations and structured results.

**Key Features:**
- Provides a smooth EMG curve representation.
- Uses mean or PCA to create generalized EMG curves.

### 8. `plot_muscle.m`
**Purpose:**
- Allows visualization of individual EMG repetitions per muscle.
- Supports selection between normalized or DTW-aligned data.
- Provides options to plot all muscles or select one interactively.

**Key Features:**
- Facilitates visual inspection of EMG envelopes.
- Uses interactive selection for user convenience.

## How to Use
1. **Preprocess Raw Data:** Run `a1_event_detection.m` to filter and segment EMG data.
2. **Normalize Data:** Use `b_normalization.m` to standardize the time scale of repetitions.
3. **Align Data:** Execute `c0_dtw_alignment.m` or `c0_median_dtw_alignment.m` to perform DTW alignment.
4. **Analyze Intra-Subject Consistency:** Run `c1_intra_cross_correlation.m` or `c12_dtw_intra_cross_correlation.m`.
5. **Combine Repetitions:** Use `d1_combine_reps_mean.m` or `d2_combine_reps_pca.m`.
6. **Analyze Inter-Subject Similarity:** Run `e1_inter_cross_correlation.m` or `e2_pca_inter_cross_correlation.m`.
7. **Generate Representative EMG Curves:** Use `f1_emg_curve.m` or `f2_pca_emg_curve.m`.
8. **Visualize Individual Muscle Repetitions:** Run `plot_muscle.m`.

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

