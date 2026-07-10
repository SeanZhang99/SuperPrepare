# Output Format

After running the pipeline, standardized data is written to `save_path/` with the following structure:

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
    ├── metadata.pkl
    ├── scaling_factor.pkl
    └── channelwise_scaling_factor.pkl
```

---

## File Naming Convention

Every output file follows the pattern:

```
dataset-XXX-subject-XXX-trial-XXX.npy
```

Where:
- `dataset-XXX` — Numeric dataset ID (assigned in `config.mlx` → `dataset_name_id_pair`)
- `subject-XXX` — 1-based subject index
- `trial-XXX` — 1-based trial index

**Example:** `dataset-001-subject-003-trial-012.npy` = NJU dataset, subject 3, trial 12.

---

## Per-Modality Details

### `exg/` — EEG Data

| Property | Value |
|----------|-------|
| Format | `.npy` |
| Shape | `(time_samples, n_channels)` |
| Type | float64 |
| Sampling rate | `common_fs` (default: 128 Hz) |
| Channel order | As defined by `channel_indices` in `get_dataset_info.m` |

### `wav/` — Audio Waveform

| Property | Value |
|----------|-------|
| Format | `.npy` |
| Shape | `(time_samples, n_speakers)` |
| Type | float64 |
| Sampling rate | 16,000 Hz |
| Column order | [attended, competing] |

### `env/` — Acoustic Envelope

| Property | Value |
|----------|-------|
| Format | `.npy` |
| Shape | `(time_samples, n_speakers)` |
| Type | float64 |
| Sampling rate | `common_fs` (128 Hz) |
| Method | ERB gammatone filterbank + power-law compression (0.6) |
| Column order | [attended, competing] |

The envelope is a broadband signal obtained by:
1. Filtering audio through an ERB-spaced gammatone filterbank (~150 Hz to ~4 kHz)
2. Computing the envelope of each subband via power-law compression
3. Summing across subbands

For datasets that provide pre-computed envelopes (KUL), these are loaded as-is.

### `mel/` — Mel Spectrogram

| Property | Value |
|----------|-------|
| Format | `.npy` |
| Shape | `(n_mels=10, time_frames, n_speakers)` |
| Type | float64 |
| Frame rate | 64 Hz (target_fs) |
| Params | `fmin=0, fmax=5000, n_mels=10, hop_length=fs/64` |
| Method | `librosa.feature.melspectrogram` (Slaney norm, non-HTK) |
| Column order | [attended, competing] |

The number of time frames is:
```
time_frames = int(len(audio) / hop_length)
```

If librosa produces fewer frames, the output is zero-padded to match.

### `wav2vec2/` — Neural Speech Embeddings

| Property | Value |
|----------|-------|
| Format | `.npy` |
| Shape | `(time_frames, n_components, n_speakers)` |
| Type | float32 |
| Frame rate | 50 Hz |
| Model | wav2vec2.0 (Hugging Face) |
| Raw dim | 1024 (last hidden layer) |
| PCA dim | `N_COMPONENTS` (default: 64) |

Only produced when `EXTRACT_WAV2VEC2 = true` in `config.mlx`.

---

## Metadata Files

### `metadata.pkl`

A Python dictionary (pickle) with dataset-level metadata. Structure:

```python
{
    "NJU": {
        "nch": 32,
        "fs": 128,
        "nsub": 21,
        "ntrials": 24,
        "ch_names": ["Cz", "Fz", "Fp1", ...],
        "speaker_num": 2,
        "desired_length": 14720
    },
    "KUL": { ... },
    ...
}
```

### `scaling_factor.pkl`

Per-subject scalar scaling factors, computed by `SubjectwiseScaler`:

```python
{
    "NJU": {
        "sub-001": {
            "exg": 12.45,    # sqrt(trimmed_mean(power))
            "env": 0.034,
            "mel": 0.52
        },
        "sub-002": { ... },
        ...
    },
    "KUL": { ... },
    ...
}
```

The scaling factor is `sqrt(trimmean(channel_power, 20%))` — the square root of the 20% trimmed mean of per-channel RMS power.

### `channelwise_scaling_factor.pkl`

Per-subject, per-channel scaling factors for EEG:

```python
{
    "NJU": {
        "sub-001": {
            "exg": array([10.2, 11.8, 12.1, ...])  # shape (32,)
        },
        ...
    },
    ...
}
```

---

## Loading Output Data in Downstream Code

### Python

```python
import numpy as np
import pickle

# Load a single trial
eeg = np.load("save_path/exg/dataset-001-subject-003-trial-012.npy")
env = np.load("save_path/env/dataset-001-subject-003-trial-012.npy")
mel = np.load("save_path/mel/dataset-001-subject-003-trial-012.npy")

# Apply scaling
with open("save_path/meta/scaling_factor.pkl", "rb") as f:
    scaling = pickle.load(f)
scale = scaling["NJU"]["sub-003"]
eeg_scaled = eeg / scale["exg"]
env_scaled = env / scale["env"]

# Load metadata
with open("save_path/meta/metadata.pkl", "rb") as f:
    meta = pickle.load(f)
```

### MATLAB

```matlab
% Load trial
exg = readNPY('save_path/exg/dataset-001-subject-003-trial-012.npy');

% Load scaling factors
fid = py.open('save_path/meta/scaling_factor.pkl', 'rb');
scaling = pickle.load(fid);
fid.close();
scale = scaling{'NJU'}{'sub-003'};
exg_scaled = exg / double(scale{'exg'});
```

---

## Resuming a Previous Run

Set `APPEND_MODE = true` in `config.mlx`. The pipeline will:

1. Load existing `metadata.pkl` and `scaling_factor.pkl`
2. Skip already-processed trials (checks for existing `.npy` files)
3. Append new results to metadata and scaling dictionaries
4. Overwrite pickle files with updated dictionaries

This allows incremental processing — add new datasets or subjects without reprocessing everything.
