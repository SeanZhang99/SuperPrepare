# SuperPrepare

> A multi-dataset EEG preprocessing pipeline for Auditory Attention Detection (AAD) research.  
> Unifies heterogeneous EEG datasets into a standardized, machine-learning-ready format.

---

## Table of Contents

- [Overview](#overview)
- [Supported Datasets](#supported-datasets)
- [Pipeline Architecture](#pipeline-architecture)
- [Output Format](#output-format)
- [Dependencies](#dependencies)
- [Setup](#setup)
- [Quick Start](#quick-start)
- [Adding a New Dataset](#adding-a-new-dataset)
- [Repository Structure](#repository-structure)
- [Contributing](#contributing)
- [References](#references)
- [License](#license)

---

## Overview

SuperPrepare standardizes EEG data from **16+ AAD datasets** collected across different labs, with different hardware, channel layouts, sampling rates, and experimental paradigms. It preprocesses raw EEG signals, extracts aligned audio features, and outputs consistent `.npy` arrays ready for downstream machine learning.

**What you get per trial:**
| Feature | Description |
|---------|-------------|
| `exg` | EEG time series, resampled to a common sampling rate |
| `wav` | Raw audio waveform (16 kHz) |
| `env` | Acoustic envelope via gammatone filterbank + power-law compression |
| `mel` | Mel spectrogram (via librosa) |
| `wav2vec2` | Deep speech embeddings from wav2vec2.0 (with optional PCA) |
| `metadata.pkl` | Per-dataset metadata (channels, sampling rate, trial count, etc.) |
| `scaling_factor.pkl` | Per-subject trimmed-mean scaling factors for normalization |

---

## Supported Datasets

| # | Dataset ID | Full Name | Channels | Sampling Rate (Hz) | Trials | Subjects | Speakers |
|---|-----------|-----------|----------|--------------------|--------|----------|----------|
| 1 | NJU | NJU-15class-Emotiv-AAD | 32 | 128 | 24 | 21 | 2 |
| 2 | KUL | KU Leuven AAD | 64 | 128 | 20 | — | 2 |
| 3 | Alices | Brennan's Alice Story | 61 | 500 | 12 | — | 1 |
| 4 | sparKULee | sparrKULee | 64 | 128 | — | — | 1 |
| 5 | DTU | Technical Univ. of Denmark | 64 | 128 | 60 | — | 2 |
| 6 | PKU | PKU 4-talker EEG | 59 | 128 | 40 | 16 | 4 |
| 7 | PKU-NBD | PKU 4-talker NBD EEG | 59 | 128 | 40 | 16 | 4 |
| 8 | ICL | Estart 2019 (ICL) | 61 | 128 | 8 | 20 | 2 |
| 9 | AHU | Anhui University | 32 | 128 | 16 | 20 | — |
| 10 | KUL-AV-GC | KU Leuven Audio-Visual | 64 | 128 | 6 | — | 2 |
| 11 | NUS | NUS ASA | 64 | 128 | 20 | — | — |
| 12 | CocktailParty | Cocktail Party | 64 | 128 | 30 | — | 2 |
| 13 | USTC | USTC | 64 | 128 | 20 | — | 2 |
| 14 | SCUT | South China Univ. of Tech. | 64/32/16 | 128 | — | — | — |

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    STAGE 1: Per-Dataset Preprocessing           │
│  (MATLAB + Python, stored in pre-processing-code/)              │
│                                                                 │
│  Raw EEG ──► Bandpass/Notch Filter ──► Bad Channel Interp.    │
│                ──► ICA (EEGLAB/MNE) ──► CAR Re-reference        │
│                                                                 │
│  Raw Audio ──► Resample ──► Envelope Extraction (Hilbert)      │
└───────────────────────────────┬─────────────────────────────────┘
                                │ Preprocessed .mat / .npy
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STAGE 2: Unified Pipeline                     │
│  (MATLAB: matlab-preprocessing-code/split_datasets.m)           │
│                                                                 │
│  EEG ──► Channel Selection ──► Resample ──► Silent Trimming    │
│                                                                 │
│  Audio ──► Gammatone Envelope (MATLAB)                          │
│        ──► Mel Spectrogram (Python/librosa)                     │
│        ──► wav2vec2 Embeddings (Python/PyTorch)                 │
│                                                                 │
│  All ──► SubjectwiseScaler ──► Save as .npy + metadata.pkl     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Output Format

```
save_path/
├── exg/
│   └── dataset-XXX-subject-XXX-trial-XXX.npy
├── wav/
│   └── dataset-XXX-subject-XXX-trial-XXX.npy
├── env/
│   └── dataset-XXX-subject-XXX-trial-XXX.npy
├── mel/
│   └── dataset-XXX-subject-XXX-trial-XXX.npy
├── wav2vec2/
│   └── dataset-XXX-subject-XXX-trial-XXX.npy
└── meta/
    ├── metadata.pkl           # Per-dataset metadata dict
    ├── scaling_factor.pkl     # Per-subject scaling factors
    └── channelwise_scaling_factor.pkl
```

---

## Dependencies

### MATLAB

| Toolbox / Package | Purpose |
|-------------------|---------|
| [EEGLAB](https://sccn.ucsd.edu/eeglab/) | ICA, bad channel removal (ASR), ICLabel |
| [AMToolbox](http://www.amtoolbox.org/) | Gammatone filterbank, ERB-spaced filters |
| Signal Processing Toolbox | `butter`, `filtfilt`, `fir1`, `resample`, `hilbert` |
| Statistics & Machine Learning Toolbox | `trimmean` |
| MATLAB Python bridge | Calls Python from within MATLAB |

### Python

| Package | Purpose |
|---------|---------|
| `numpy` | Array I/O, computation |
| `librosa` | Mel spectrogram |
| `scipy` | `.mat` I/O, `scipy.signal.hilbert`, `scipy.stats.zscore` |
| `mne` | EEG filtering, ICA, resampling, montage |
| `scikit-learn` | PCA for wav2vec2 reduction |
| `h5py` | HDF5 I/O (Estart dataset) |
| `torch` (PyTorch) | wav2vec2.0 model inference |
| `transformers` (Hugging Face) | wav2vec2.0 model loading |

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/SeanZhang99/SuperPrepare.git
cd SuperPrepare
```

### 2. Configure MATLAB

- Install [EEGLAB](https://sccn.ucsd.edu/eeglab/) and add it to the MATLAB path.
- Install [AMToolbox](http://www.amtoolbox.org/) and add it to the MATLAB path.
- Ensure the MATLAB Python bridge can find your Python environment:
  ```matlab
  pyenv('Version', 'C:\path\to\python.exe');
  ```

### 3. Configure Python environment

```bash
pip install numpy librosa scipy mne scikit-learn h5py torch transformers
```

### 4. Configure paths

Update the `config.mlx` MATLAB Live Script with:
- `raw_path` — path to your raw/preprocessed datasets
- `save_path` — path where standardized outputs will be saved
- `all_datasets` — list of dataset names to process

---

## Quick Start

### Step 1: Preprocess a single dataset (optional)

Some datasets provide ready-to-use preprocessed data. For others, run the dataset-specific preprocessing first:

```matlab
% Example: Preprocess KU Leuven dataset
cd pre-processing-code/KUL/
kul_preprocess('/path/to/KUL/data/');
```

### Step 2: Run the unified pipeline

```matlab
cd matlab-preprocessing-code/
% Edit config.mlx to set your dataset list, paths, and flags
split_datasets
```

The pipeline will iterate through the configured datasets and produce standardized `.npy` files.

### Step 3: Analyze channel layouts (optional)

```matlab
cd matlab-preprocessing-code/utils/

% View all dataset channel layouts
layouts = channel_layout_summary();

% Compute intersection & union of selected datasets
[intersect_ch, union_ch] = channel_layout_summary(["NJU_preprocessed", "KUL_preprocessed"]);
```

---

## Adding a New Dataset

To add support for a new dataset, modify **three files**:

1. **`config.mlx`** — Add your dataset name to `all_datasets`.

2. **`matlab-preprocessing-code/utils/get_dataset_info.m`** — Add a new `case` in the `switch` block with:
   ```matlab
   case "MyDataset_raw"
       base_path = fullfile(raw_path, "MyDataset", "exg", type);
       audio_path = fullfile(raw_path, "MyDataset", "stimuli");
       fs = 128;
       filelists = dir(fullfile(base_path, "S*.mat"));
       channel_indices = 1:64;
       f_upper = 64;
       num_trial = 20;
       desired_length = fs * trial_duration_seconds;
       channel = ["Fz"; "Cz"; ...];  % Channel names in order
       num_speaker = 2;
   ```

3. **`matlab-preprocessing-code/utils/extract_trials.m`** — Add a new `case` that extracts trial-level EEG, labels, and stimuli from your data format.

See existing dataset implementations for reference.

---

## Repository Structure

```
SuperPrepare/
├── matlab-preprocessing-code/         # Core unified pipeline
│   ├── config.mlx                     # Configuration (Live Script)
│   ├── split_datasets.m               # Main entry point
│   └── utils/
│       ├── get_dataset_info.m         # Dataset metadata registry
│       ├── extract_trials.m           # Trial extraction (per-dataset)
│       ├── calculateEnvelopeERBGammatone.m  # Gammatone envelope
│       ├── extract_wav2vec.m          # wav2vec2 + PCA
│       ├── SubjectwiseScaler.m        # Per-subject normalization
│       ├── mel.py                     # Mel spectrogram (Python)
│       ├── channel_layout_summary.m   # Channel analysis
│       └── ...                        # Other utilities
│
├── pre-processing-code/               # Dataset-specific preprocessing
│   ├── NJU/                           # MWF-based artifact removal
│   ├── KUL/                           # Gammatone envelope + bandpass
│   ├── Estart/                        # ICA pipeline (EEGLAB)
│   └── ASA/                           # MNE-based (SCUT/NUS)
│
└── recently_presented_datasets.xlsx   # Dataset tracking spreadsheet
```

---

## Contributing

Issues and pull requests are welcome. When proposing changes:

1. Ensure compatibility with existing dataset `case` statements in `get_dataset_info.m`.
2. Follow the existing naming convention: `dataset-XXX-subject-XXX-trial-XXX`.
3. Test with at least one full dataset before submitting.

---

## References

This pipeline builds on methods from the following work:

- Das, N., Vanthornhout, J., Francart, T., & Bertrand, A. (2019). *Stimulus-aware spatial filtering for single-trial neural response and temporal response function estimation in high-density EEG with applications in auditory research.* bioRxiv, 541318. [doi:10.1101/541318](https://doi.org/10.1101/541318)

---

## License

This project does not currently have a license. All rights reserved by default. If you intend to use or distribute this code, please contact the author.
