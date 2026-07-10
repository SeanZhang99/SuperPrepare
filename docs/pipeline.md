# Pipeline Deep Dive

This document walks through what `split_datasets.m` does at each stage, so you understand the data flow and can debug issues.

---

## Overview

The pipeline processes data in a nested loop:

```
for each dataset in all_datasets:
    load dataset metadata (channels, fs, trial count, etc.)
    for each subject:
        initialize per-subject scalers (exg, env, mel)
        load subject data structure
        for each trial:
            extract trial-level EEG + labels + stimuli
            resample EEG to common_fs
            process audio (wav, env, mel, wav2vec2)
            trim trailing silence
            accumulate scaling stats
            save .npy files
        compute and save per-subject scaling factors
save metadata.pkl + scaling_factor.pkl
```

---

## Stage 1: Dataset Info Loading

```matlab
dataset_infos = get_dataset_info(dataset_names, raw_path);
```

`get_dataset_info.m` returns a struct array with one entry per dataset:

| Field | Type | Description |
|-------|------|-------------|
| `base_path` | string | Path to the dataset's EEG files |
| `audio_path` | string | Path to the dataset's audio stimuli |
| `fs` | double | Original sampling rate (Hz) |
| `nch` | double | Number of channels |
| `channel_indices` | double[] | Indices of channels to keep (1-based) |
| `num_subject` | double | Number of subjects |
| `num_trial` | double | Trials per subject |
| `desired_length` | double | Expected signal length (samples) |
| `channel_infos` | py.dict | Channel names (for metadata export) |
| `num_speaker` | double | Number of competing speakers |
| `f_upper` | double | Upper frequency bound (Hz) |

---

## Stage 2: Subject Data Loading

```matlab
data_struct = load_data_struct(fullfile(dataset_info.filelists(subject_id).folder, ...), dataset_name);
```

Loads the subject's `.mat` or `.npy` file. The structure varies by dataset — some have `data.eeg`, others have `trials`, `preproc_trials`, etc. This is handled by `load_data_struct.m`.

---

## Stage 3: Per-Trial Processing

### 3.1 Trial Extraction

```matlab
trial_data = extract_trials(data_struct, dataset_info.base_path, trial_id, subject_id, dataset_name, []);
```

`extract_trials.m` is the most dataset-specific function. It handles each dataset's unique format and returns a struct with:

| Field | Content |
|-------|---------|
| `exg` | EEG data matrix (time x channels) |
| `label` | Attention label ("left"/"right" or angle in degrees) |
| `stimuli` / `compet_stimuli` | Attended/competing audio waveforms |
| `stimuli_fs` | Original audio sampling rate |
| `env` / `compet_env` | Pre-computed envelopes (if available) |
| `stimuli_name` | Audio stimulus identifier |

### 3.2 EEG Resampling

```matlab
if fs ~= common_fs
    exg = resample(exg, common_fs, fs);
end
```

Resamples EEG to `common_fs` (typically 128 Hz) using MATLAB's `resample()`.

### 3.3 Audio Feature Extraction

#### Waveform (`wav`)

If the dataset is `raw`, audio is loaded from `.wav` or extracted from `.mat` files, then resampled to 16 kHz.

#### Gammatone Envelope (`env`)

```matlab
env = calculateEnvelopeERBGammatone(stimuli, stimuli_fs);
```

Uses **AMToolbox** to:
1. Apply an ERB-spaced gammatone filterbank (center frequencies: ~150 Hz to ~4 kHz)
2. Compute subband envelopes via power-law compression (exponent = 0.6)
3. Sum across subbands to get a broadband envelope

If pre-computed envelopes exist (e.g., KUL datasets provide `.mat` envelope files), they are loaded instead.

#### Mel Spectrogram (`mel`)

```matlab
mel = py.mel.calculate_mel_spectrogram(audio, fs, target_fs=64, fmin=0, fmax=5000, nb_filters=10);
```

Calls the Python function `mel.py` which:
1. Removes DC offset (`audio - mean(audio)`)
2. Computes mel spectrogram via **librosa** (10 mel bands, 0–5 kHz)
3. Ensures consistent output length matching the EEG

#### wav2vec2 Embeddings

```matlab
[wav2vec2, wav2vec2_fs] = extract_wav2vec(feature_extractor, model, audio, fs, RUN_PCA, N_COMPONENTS);
```

Calls `extract_wav2vec.m` which:
1. Resamples audio to 16 kHz
2. Segments into 30-second windows (GPU memory management)
3. Runs **wav2vec2.0** (Hugging Face + PyTorch) to extract 1024-dim embeddings from the last hidden layer
4. Optionally reduces to `N_COMPONENTS` dimensions via **sklearn PCA**
5. Outputs at 50 Hz

> **GPU required.** The model runs in `float16` on CUDA. See [Getting Started](getting-started.md#troubleshooting) for GPU memory issues.

### 3.4 Silent Trailing Detection

```matlab
silent_idx = detect_silent_tailing(exg, common_fs, desired_length);
```

Trims trailing segments where the signal is silent (>1 second). This handles datasets where recordings extend beyond the actual stimulus.

### 3.5 Per-Subject Scaling

```matlab
exg_scaler = exg_scaler.update(exg);
env_scaler = env_scaler.update(env);
mel_scaler = mel_scaler.update(mel);
```

The `SubjectwiseScaler` class accumulates signal power across all trials for a subject. After all trials:

```matlab
[~, scaling_factor, chanwise_scaling_factor] = exg_scaler.get_scaling_factor();
```

It computes the **20% trimmed mean** of per-channel power, then takes the square root (RMS-based scaling). This gives one scalar per subject for each feature type, plus per-channel scalars for EEG.

### 3.6 Saving

```matlab
py.numpy.save(fullfile(save_path, "exg", entry+".npy"), py.numpy.array(exg));
```

Each trial is saved as a `.npy` file named `dataset-XXX-subject-XXX-trial-XXX.npy`.

---

## Stage 4: Metadata Export

After all datasets are processed:

```matlab
pickle.dump(metadata, fid);
pickle.dump(scaling_factor, fid);
pickle.dump(channelwise_scaling_factor, fid);
```

Three Python pickle files are written to `save_path/meta/`:
- `metadata.pkl` — Dict of dataset metadata (channels, fs, trial counts)
- `scaling_factor.pkl` — Dict of per-subject scalar scaling factors
- `channelwise_scaling_factor.pkl` — Dict of per-subject per-channel scaling factors

---

## Data Flow Diagram

```
┌──────────┐    ┌──────────────┐    ┌───────────────┐
│ Raw EEG  │───►│ Channel      │───►│ Resample to   │
│ (.mat)   │    │ Selection    │    │ common_fs     │
└──────────┘    └──────────────┘    └───────┬───────┘
                                            │
┌──────────┐    ┌──────────────┐            │
│ Audio    │───►│ Envelope     │───►        │
│ (.wav)   │    │ (gammatone)  │            │
└──────────┘    └──────────────┘            │
                     │                      │
                     ▼                      ▼
              ┌─────────────────────────────────┐
              │  Match lengths, trim silence,   │
              │  accumulate scaling stats       │
              └─────────────┬───────────────────┘
                            │
              ┌─────────────▼───────────────────┐
              │  Save .npy (exg, wav, env,      │
              │  mel, wav2vec2) + metadata.pkl  │
              └─────────────────────────────────┘
```
