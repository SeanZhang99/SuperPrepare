# Datasets

SuperPrepare supports **14+ EEG datasets** for Auditory Attention Detection. This page documents each dataset's characteristics and how to add new ones.

---

## How Dataset Names Work

Each dataset name in `all_datasets` follows the pattern:

```
DatasetName_type
```

Where `type` is:
- **`raw`** — Raw EEG data. The pipeline computes stimuli, envelopes, and mel spectrograms from scratch.
- **`preprocessed`** — Preprocessed EEG with pre-computed envelopes. The pipeline loads existing envelope features.

A dataset can appear as both types (e.g., `NJU_raw` and `NJU_preprocessed`), allowing you to compare raw vs. preprocessed results.

---

## Supported Datasets

### NJU (`NJU_raw`, `NJU_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | NJU-15class-Emotiv-AAD |
| Channels | 32 (Emotiv EPOC+) |
| Sampling rate | 128 Hz |
| Trials | 24 |
| Subjects | 21 |
| Speakers | 2 (dichotic) |
| Data format | `.mat` with `data.eeg` cell array |
| Labels | "left" / "right" (attended ear) |
| Preprocessing | [MWF artifact removal](https://github.com/SeanZhang99/SuperPrepare/blob/matlab-processing-code/pre-processing-code/NJU/prepoc_ica.m), high-pass 0.5 Hz, CAR |

**Channels:** Cz, Fz, Fp1, F7, F3, FC1, C3, FC5, FT9, T7, CP5, CP1, P3, P7, PO9, O1, Pz, Oz, O2, PO10, P8, P4, CP2, CP6, T8, FT10, FC6, C4, FC2, F4, F8, Fp2

### KUL (`KUL_raw`, `KUL_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | KU Leuven AAD |
| Channels | 64 (BioSemi ActiveTwo) |
| Sampling rate | 128 Hz |
| Trials | 20 |
| Speakers | 2 (dichotic) |
| Data format | `.mat` with `trials` / `preproc_trials` structs |
| Labels | "left" / "right" |
| Envelope | Pre-computed gammatone subband envelopes (power-law, 17 subbands) |
| Reference | Das et al. (2019), bioRxiv 541318 |

### Alices (`Alices_raw`)
| Property | Value |
|----------|-------|
| Full name | Brennan's Alice Story |
| Channels | 61 |
| Sampling rate | 500 Hz |
| Trials | 12 |
| Speakers | 1 (single speaker narrative) |
| Data format | `.mat` with `data.exg` cell array |

### sparKULee (`sparKULee_raw`, `sparKULee_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | sparrKULee |
| Channels | 64 |
| Sampling rate | 128 Hz |
| Data format | `.npy` files in BIDS-like structure (`sub-XXX/ses-XXX/`) |
| Speakers | 1 |

### DTU (`DTU_raw`, `DTU_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | Technical University of Denmark |
| Channels | 64 |
| Sampling rate | 128 Hz |
| Trials | 60 |
| Speakers | 2 (male/female) |
| Data format | `.mat` with `data` cell array containing `eeg`, `wavA`, `wavB` |

### PKU (`PKU_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | PKU 4-talker EEG |
| Channels | 59 |
| Sampling rate | 128 Hz |
| Trials | 40 |
| Subjects | 16 |
| Speakers | 4 (spatialized) |
| Labels | Angle: 30°, -30°, 90°, -90° |
| Envelope | Pre-computed spatial envelopes from `space_envall.mat` |

### PKU-NBD (`PKU-NBD_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | PKU 4-talker NBD EEG |
| Channels | 59 |
| Sampling rate | 128 Hz |
| Trials | 40 |
| Subjects | 16 |
| Speakers | 4 |

### ICL / Estart (`ICL_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | Estart 2019 (Imperial College London) |
| Channels | 61 |
| Sampling rate | 128 Hz |
| Trials | 8 |
| Subjects | 20 |
| Speakers | 2 |
| Data format | `.mat` with `eeg`, `condition`, `attended_audio` |
| Preprocessing | [EEGLAB ICA pipeline](https://github.com/SeanZhang99/SuperPrepare/blob/matlab-processing-code/pre-processing-code/Estart/Estart_pipeline.m) |

### AHU (`AHU_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | Anhui University |
| Channels | 32 |
| Sampling rate | 128 Hz |
| Trials | 16 |
| Subjects | 20 |
| Data format | `.csv` (channel x time) |
| Labels | "left" / "right" |
| Note | Data needs `* 1e4` amplitude scaling |

### KUL-AV-GC (`KUL-AV-GC_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | KU Leuven Audio-Visual Gain Control |
| Channels | 64 |
| Sampling rate | 128 Hz |
| Trials | 6 |
| Speakers | 2 (with attention switches) |
| Envelope | Pre-computed in `data_struct.stimulus` |

### NUS (`NUS_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | National University of Singapore ASA |
| Channels | 64 |
| Sampling rate | 128 Hz |
| Trials | 20 |
| Labels | Spatial angles: ±5°, ±30°, ±45°, ±60°, ±90° |

### CocktailParty (`CocktailParty_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | Cocktail Party |
| Channels | 64 |
| Sampling rate | 128 Hz |
| Trials | 30 |
| Speakers | 2 (audiobook + competing) |
| Data format | `.mat` with `preprocessed_data` cell array |

### USTC (`USTC_preprocessed`)
| Property | Value |
|----------|-------|
| Full name | University of Science and Technology of China |
| Channels | 64 |
| Sampling rate | 128 Hz |
| Trials | 20 |
| Speakers | 2 |
| Audio | Separate `.wav` files in `Audio/` |

### SCUT (`SCUT`)
| Property | Value |
|----------|-------|
| Full name | South China University of Technology |
| Channels | 64/32/16/10 (varies) |
| Sampling rate | 128 Hz |
| Preprocessing | [MNE-based pipeline](https://github.com/SeanZhang99/SuperPrepare/blob/matlab-processing-code/pre-processing-code/ASA/preprocess.py) (Python) |
| Note | Not directly supported in `get_dataset_info.m`; processed via `pre-processing-code/ASA/` |

---

## Dataset Preprocessing Pipeline

Some datasets require preprocessing before the unified pipeline. These scripts live in `pre-processing-code/`:

| Script | Dataset | Language | Key Steps |
|--------|---------|----------|-----------|
| `NJU/prepoc_ica.m` | NJU | MATLAB (EEGLAB) | High-pass 0.5 Hz, artifact interpolation, MWF removal, ICA, CAR |
| `KUL/kul_preprocess.m` | KUL | MATLAB (AMToolbox) | Gammatone envelope, bandpass 1–40 Hz, downsample to 128 Hz |
| `Estart/Estart_pipeline.m` | Estart | MATLAB (EEGLAB) | Bandpass 0.5–62 Hz, notch 50 Hz, ASR bad channel removal, ICA (ICLabel) |
| `ASA/preprocess.py` | SCUT/NUS | Python (MNE) | ICA (corrmap), bandpass filter, resample to 128 Hz |

---

## Adding a New Dataset

To add support for a new dataset, you need to modify **3 files**.

### Step 1: `config.mlx`

Add your dataset name to `all_datasets`:

```matlab
all_datasets = [..., "MyDataset_raw", "MyDataset_preprocessed"];
```

Also update `dataset_name_id_pair` to assign a unique numeric ID:

```matlab
dataset_name_id_pair = containers.Map({..., "MyDataset"}, {..., 14});
```

### Step 2: `matlab-preprocessing-code/utils/get_dataset_info.m`

Add a `case` block inside the `switch dataset_name` statement:

```matlab
case {"MyDataset_raw", "MyDataset_preprocessed"}
    base_path = fullfile(raw_path, "MyDataset", "exg", type);
    audio_path = fullfile(raw_path, "MyDataset", "stimuli");
    fs = 256;               % Original sampling rate
    filelists = dir(fullfile(base_path, "S*.mat"));
    channel_indices = 1:64; % Which channels to keep
    f_upper = 128;          % Nyquist frequency / 2
    num_trial = 20;
    desired_length = round(fs * 60);  % 60-second trials
    channel = ["Fz"; "Cz"; "Pz"; ...]; % Channel names in order
    num_speaker = 2;
```

Fields required:

| Field | Type | Description |
|-------|------|-------------|
| `base_path` | string | Path to EEG data files |
| `audio_path` | string | Path to audio stimuli ("" if none) |
| `fs` | double | Original sampling rate (Hz) |
| `filelists` | struct | `dir()` output listing subject files |
| `channel_indices` | double[] | 1-based indices of channels to keep |
| `f_upper` | double | Upper frequency bound for filenames |
| `num_trial` | double | Number of trials per subject |
| `desired_length` | double | Expected signal length in samples |
| `channel` | string[] | Channel names (in order, for metadata) |
| `num_speaker` | double | Number of competing speakers |

### Step 3: `matlab-preprocessing-code/utils/extract_trials.m`

Add a `case` block inside the `switch dataset_name` statement:

```matlab
case "MyDataset_raw"
    if trial_idx <= length(data_struct.data.eeg)
        exg = data_struct.data.eeg{trial_idx};
        label = data_struct.labels{trial_idx};  % "left" or "right"
        stimuli_path = data_struct.stimuli{trial_idx};
        compet_stimuli_path = data_struct.compet_stimuli{trial_idx};
        stimuli_name = extractBefore(stimuli_path, ".wav");
        compet_stimuli_name = extractBefore(compet_stimuli_path, ".wav");
    end
```

The `trial_data` struct returned must include:

| Field | Required | Description |
|-------|----------|-------------|
| `exg` | **Yes** | EEG matrix (time x channels) |
| `label` | **Yes** | String label ("left"/"right" or angle) |
| `stimuli` | If raw | Attended audio waveform |
| `compet_stimuli` | If raw | Unattended audio waveform |
| `stimuli_fs` | If raw | Audio sampling rate |
| `stimuli_name` | If raw | Stimulus identifier string |
| `compet_stimuli_name` | If raw | Competing stimulus identifier |
| `env` | If preprocessed | Pre-computed envelope |
| `compet_env` | If preprocessed | Pre-computed competing envelope |
| `env_path` | Optional | Path to envelope `.mat` file |
| `mel_path` | Optional | Path to mel spectrogram `.npy` file |
| `wav2vec2_path` | Optional | Path to wav2vec2 `.npy` file |

> **Tip:** Study the `KUL_preprocessed` case in `extract_trials.m` for a full example with both EEG extraction and pre-computed envelope loading.

### Step 4 (Optional): Dataset-Specific Preprocessing

If your dataset uses a unique preprocessing pipeline, add scripts under `pre-processing-code/YourDataset/`. See `pre-processing-code/NJU/` for a complete example using EEGLAB.
