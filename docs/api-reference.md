# API Reference

This page documents the core functions, classes, and scripts in SuperPrepare.

---

## Main Pipeline

### `split_datasets.m` — Main Entry Point

**Path:** `matlab-preprocessing-code/split_datasets.m`

The central pipeline script. Iterates through all configured datasets, subjects, and trials, producing standardized `.npy` output files.

**Behavior:**
- Reads configuration from `config.mlx`
- Loads dataset metadata via `get_dataset_info()`
- For each subject: initializes `SubjectwiseScaler` instances, loads data, iterates trials
- For each trial: extracts EEG + labels, processes audio features, resamples, trims silence, saves

**Flags (from `config.mlx`):**
- `DEBUG_MODE` — Process only first trial
- `APPEND_MODE` — Resume from existing metadata
- `EXTRACT_WAV2VEC2` — Enable neural speech features

**Output:** `.npy` files + `metadata.pkl` + `scaling_factor.pkl` + `channelwise_scaling_factor.pkl`

---

## Dataset Management

### `get_dataset_info()` — Dataset Metadata Registry

**Path:** `matlab-preprocessing-code/utils/get_dataset_info.m`

```matlab
dataset_infos = get_dataset_info(dataset_names, raw_path)
```

Returns a struct array with one entry per dataset, containing all metadata needed by the pipeline.

**Parameters:**

| Arg | Type | Description |
|-----|------|-------------|
| `dataset_names` | `string[]` | Dataset names (e.g., `["NJU_raw", "KUL_preprocessed"]`) |
| `raw_path` | `string` | Root path to raw datasets |

**Returns:** `struct[]` with fields:

| Field | Type | Description |
|-------|------|-------------|
| `filelists` | `struct` | `dir()` output of subject files |
| `num_subject` | `double` | Number of subjects |
| `nch` | `double` | Number of channels |
| `channel_indices` | `double[]` | 1-based channel indices |
| `fs` | `double` | Sampling rate (Hz) |
| `f_upper` | `double` | Upper frequency bound |
| `num_trial` | `double` | Trials per subject |
| `desired_length` | `double` | Expected signal length (samples) |
| `audio_path` | `string` | Path to audio stimuli |
| `base_path` | `string` | Path to EEG data |
| `channel_infos` | `py.dict` | Channel name metadata |
| `num_speaker` | `double` | Number of competing speakers |

**Adding a dataset:** See [Datasets - Adding a New Dataset](datasets.md#adding-a-new-dataset).

---

### `extract_trials()` — Per-Dataset Trial Extraction

**Path:** `matlab-preprocessing-code/utils/extract_trials.m`

```matlab
trial_data = extract_trials(data_struct, dataset_path, trial_idxs, subject_id, dataset_name, desired_length)
```

Extracts trial-level EEG, labels, and stimuli from a dataset's subject data structure. This is the most dataset-specific function — each dataset has its own `case` block.

**Parameters:**

| Arg | Type | Description |
|-----|------|-------------|
| `data_struct` | `struct` | Subject data (from `load_data_struct`) |
| `dataset_path` | `string` | Path to dataset directory |
| `trial_idxs` | `double[]` | Trial indices to extract |
| `subject_id` | `double` | Subject number |
| `dataset_name` | `string` | Dataset name (e.g., `"NJU_raw"`) |
| `desired_length` | `double` | (unused, kept for compatibility) |

**Returns:** `struct[]` with fields:

| Field | Type | Description |
|-------|------|-------------|
| `exg` | `double[][]` | EEG data (time x channels), or `NaN` if trial doesn't exist |
| `label` | `string` | Attention label |
| `stimuli` | `double[]` | Attended audio waveform |
| `compet_stimuli` | `double[]` | Unattended audio waveform |
| `stimuli_fs` | `double` | Audio sampling rate |
| `stimuli_path` | `string` | Path to attended audio |
| `compet_stimuli_path` | `string` | Path to competing audio |
| `stimuli_name` | `string` | Stimulus identifier |
| `compet_stimuli_name` | `string` | Competing stimulus identifier |
| `env` | `double[]` | Pre-computed envelope (or `NaN`) |
| `compet_env` | `double[]` | Pre-computed competing envelope (or `NaN`) |
| `env_path` | `string` | Path to envelope file |
| `mel_path` | `string` | Path to mel spectrogram |
| `mel` | `double[][]` | Pre-computed mel (or `NaN`) |
| `wav2vec2` | `double[][]` | Pre-computed wav2vec2 (or `NaN`) |
| `wav2vec2_path` | `string` | Path to wav2vec2 file |
| `wav2vec2_fs` | `double` | wav2vec2 feature rate |

---

### `load_data_struct()` — Data File Loader

**Path:** `matlab-preprocessing-code/utils/load_data_struct.m`

```matlab
s = load_data_struct(dataset_path, dataset_name)
```

Loads a subject's data file. Handles different formats per dataset:
- `.mat` files → `load()` (most datasets)
- `.csv` files → `readtable()` (AHU)
- BIDS-like structure → returns `[]` (sparKULee, PKU-NBD — file listing done elsewhere)

### `load_stimuli()` — Audio Stimulus Loader

**Path:** `matlab-preprocessing-code/utils/load_stimuli.m`

```matlab
[stimuli, fs] = load_stimuli(path, stimuli_path)
```

Loads audio stimuli from various formats:
- `.wav` → `audioread()`
- `.mat` → loads `envelope` and `Fs` fields
- `.npy` → loads via `py.numpy.load()`

### `get_attention_directions()` — Label Extraction

**Path:** `matlab-preprocessing-code/utils/get_attention_directions.m`

Extracts attention direction labels from experiment metadata for dichotic listening datasets (NJU, CocktailParty, etc.).

### `get_num_trials()` — Trial Count

**Path:** `matlab-preprocessing-code/utils/get_num_trials.m`

Returns the number of valid trials for a given subject in a given dataset.

### `channel_layout_summary()` — Channel Analysis Tool

**Path:** `matlab-preprocessing-code/utils/channel_layout_summary.m`

```matlab
layouts = channel_layout_summary()
[intersect_ch, union_ch] = channel_layout_summary(["NJU_preprocessed", "KUL_preprocessed"])
[intersect_ch, union_ch, layouts] = channel_layout_summary(selected_datasets)
```

Analyzes and compares channel layouts across datasets:
- Without arguments: Returns all dataset channel layouts
- With dataset list: Computes intersection and union of channels

**Output:**
- `layouts` — Struct array with dataset name, channel count, and sorted channel list
- `intersect_ch` — Channels common to all selected datasets
- `union_ch` — All channels across selected datasets (sorted by 10-20/10-10 system)

---

## Audio Feature Extraction

### `calculateEnvelopeERBGammatone()` — Gammatone Envelope

**Path:** `matlab-preprocessing-code/utils/calculateEnvelopeERBGammatone.m`

```matlab
[combinedEnvelope, subbandEnvelopes] = calculateEnvelopeERBGammatone(signal, fs, freq_range, numBands, p)
```

Computes the acoustic envelope using an ERB-scaled gammatone filterbank.

**Parameters:**

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `signal` | `double[]` | — | Input audio waveform |
| `fs` | `double` | — | Sampling rate (Hz) |
| `freq_range` | `double[2]` | `[150, 4000]` | Frequency range for filterbank |
| `numBands` | `double` | 17 | Number of subbands |
| `p` | `double` | 0.6 | Power-law exponent |

**Returns:**
- `combinedEnvelope` — `(T,)` broadband envelope (sum across subbands)
- `subbandEnvelopes` — `(T, numBands)` per-subband envelopes

**Method:**
1. ERB-spaced gammatone filterbank (Glasberg & Moore, 1990)
2. Absolute value + power-law compression: `|x|^p`
3. Sum across subbands for combined envelope

### `mel.calculate_mel_spectrogram()` — Mel Spectrogram (Python)

**Path:** `matlab-preprocessing-code/utils/mel.py`

```python
mel_spec = calculate_mel_spectrogram(audio, fs, target_fs=64, fmin=0, fmax=5000, nb_filters=10, hop_length=None, win_length=None)
```

Computes mel spectrogram via librosa with consistent output length.

**Parameters:**

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `audio` | `ndarray` | — | 1D audio array |
| `fs` | `int` | — | Sampling rate (Hz) |
| `target_fs` | `int` | 64 | Output frame rate |
| `fmin` | `float` | 0 | Minimum frequency (Hz) |
| `fmax` | `float` | 5000 | Maximum frequency (Hz) |
| `nb_filters` | `int` | 10 | Number of mel bands |
| `hop_length` | `int` | auto | Hop length (default: `fs / target_fs`) |
| `win_length` | `int` | auto | Window length (default: 25 ms) |

**Returns:** `ndarray` of shape `(n_mels, time_frames)`

**Called from MATLAB as:**
```matlab
mel = py.mel.calculate_mel_spectrogram(py.numpy.array(audio), int32(fs));
```

### `extract_wav2vec()` — wav2vec2 Feature Extraction

**Path:** `matlab-preprocessing-code/utils/extract_wav2vec.m`

```matlab
[wav2vec_feature, feat_fs] = extract_wav2vec(feature_extractor, model, audio, fs, run_pca, n_components)
```

Extracts deep speech embeddings from wav2vec2.0.

**Parameters:**

| Arg | Type | Default | Description |
|-----|------|---------|-------------|
| `feature_extractor` | Python obj | — | Hugging Face `Wav2Vec2FeatureExtractor` |
| `model` | Python obj | — | Hugging Face `Wav2Vec2Model` in fp16 on CUDA |
| `audio` | `double[:,n]` | — | Audio waveform (time x channels) |
| `fs` | `double` | — | Audio sampling rate |
| `run_pca` | `logical` | `true` | Apply PCA reduction |
| `n_components` | `double` | `64` | PCA target dimensions |

**Returns:**
- `wav2vec_feature` — `(T, n_components, n_channels)` float32
- `feat_fs` — `50` Hz

**Method:**
1. Resample to 16 kHz
2. Segment into 30-second windows (GPU memory)
3. Run wav2vec2.0 inference in fp16 on CUDA
4. Extract last hidden layer (1024-dim)
5. Optionally apply sklearn PCA to `n_components`
6. Reassemble segments

---

## Processing Utilities

### `SubjectwiseScaler` — Per-Subject Normalization

**Path:** `matlab-preprocessing-code/utils/SubjectwiseScaler.m`

```matlab
scaler = SubjectwiseScaler(num_channels);
```

MATLAB class for accumulating signal power across trials and computing per-subject scaling factors.

**Constructor:**

```
scaler = SubjectwiseScaler(num_channels)
```

**Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `update` | `scaler = scaler.update(sample)` | Accumulate power stats from `sample` (T x nch). Must call before `get_scaling_factor`. |
| `get_scaling_factor` | `[scaler, sf, csf] = scaler.get_scaling_factor()` | Stop accumulation and compute scaling factor: `sqrt(trimmean(channel_power, 20%))`. Returns NaN if no data. |
| `rescale` | `sample = scaler.rescale(sample)` | Apply stored scaling factor. Only valid after `get_scaling_factor`. |

**Example usage:**

```matlab
% Initialize
exg_scaler = SubjectwiseScaler(64);

% Accumulate
for trial = trials
    exg_scaler = exg_scaler.update(eeg_data);
end

% Compute
[exg_scaler, sf, csf] = exg_scaler.get_scaling_factor();

% Apply
eeg_scaled = exg_scaler.rescale(eeg_data);
% or manually:
eeg_scaled = eeg_data / double(sf);
```

**Scaling formula:**
- Per-channel power: `sum(sample.^2) / T`
- Trimmed mean across channels (20% trimming)
- Factor: `sqrt(median(trimmed_mean))`

### `detect_silent_tailing()` — Silence Trimming

**Path:** `matlab-preprocessing-code/utils/detect_silent_tailing.m`

```matlab
silent_idx = detect_silent_tailing(signal, threshold, fs)
```

Detects trailing silent segments (>1 second) in a multi-channel signal.

**Parameters:**

| Arg | Type | Description |
|-----|------|-------------|
| `signal` | `double[T, ...]` | Multi-channel signal |
| `threshold` | `double` | Amplitude threshold for silence |
| `fs` | `double` | Sampling rate (Hz) |

**Returns:** `logical[T]` — Binary mask (1 = silent, 0 = active)

### `save_pickle()` — Pickle Export

**Path:** `matlab-preprocessing-code/utils/save_pickle.m`

```matlab
save_pickle(pickle_pkg, path, obj)
```

Saves a MATLAB/Python object as a Python pickle file via the MATLAB Python bridge.

### `append_additional_info()` — Metadata Enrichment

**Path:** `matlab-preprocessing-code/utils/append_additional_info.m`

Appends additional per-dataset metadata to the output metadata dictionary.

### `to_column_vector()`, `split_camel_case()` — String Helpers

**Paths:**
- `matlab-preprocessing-code/utils/to_column_vector.m`
- `matlab-preprocessing-code/utils/split_camel_case.m`

Utility functions for data formatting and string manipulation.

---

## Dataset-Specific Preprocessing

### NJU: `prepoc_ica.m`

**Path:** `pre-processing-code/NJU/prepoc_ica.m`

EEGLAB-based preprocessing pipeline:
1. High-pass filter at 0.5 Hz
2. Interpolate large artifacts (>500 µV)
3. Multi-channel Wiener Filter (MWF) artifact removal
4. ICA via EEGLAB (`pop_runica`)
5. Common Average Reference (CAR)

**Supporting functions:**
- `compute_mwf.m`, `apply_mwf.m`, `artifact_removal_mwf.m` — MWF computation
- `interpolate_artifacts.m` — Linear interpolation of large spikes
- `get_artifact_segments.m` — Detect artifact segments
- `stack_delayed.m` — Delayed stacking for MWF

### Estart: `Estart_pipeline.m`

**Path:** `pre-processing-code/Estart/Estart_pipeline.m`

EEGLAB-based pipeline:
1. Resample to 128 Hz
2. FIR high-pass filter
3. IIR bandpass (0.5–62 Hz) + notch (50 Hz)
4. ASR bad channel removal (`pop_clean_rawdata`)
5. Bad channel interpolation (`pop_interp`)
6. ICA via `pop_runica` with ICLabel classification

### KUL: `kul_preprocess.m`

**Path:** `pre-processing-code/KUL/kul_preprocess.m`

AMToolbox-based envelope extraction:
1. Gammatone subband envelope computation (1.5 ERB spacing, 150–4000 Hz)
2. Power-law compression (0.6)
3. EEG bandpass (1–40 Hz) and downsample to 128 Hz

### SCUT/NUS: `preprocess.py`

**Path:** `pre-processing-code/ASA/preprocess.py`

MNE-based Python preprocessing:
1. MNE ICA with corrmap for component matching
2. Bandpass filter
3. Resample to 128 Hz
4. Train/test split

**Supporting modules:**
- `ASA/db/database.py` — Channel definitions (64/32/16/10 ch)
- `ASA/eutils/crop.py` — Trial cropping from BrainVision files
- `ASA/preproc/util.py` — Label selection, normalization

---

## Configuration

### `config.mlx`

**Path:** `matlab-preprocessing-code/config.mlx`

MATLAB Live Script defining all pipeline parameters. See [Configuration Guide](configuration.md) for full details.

**Key variables:**

| Variable | Type | Description |
|----------|------|-------------|
| `raw_path` | `string` | Root path to datasets |
| `save_path` | `string` | Output directory |
| `all_datasets` | `string[]` | Datasets to process |
| `common_fs` | `double` | Target sampling rate (default: 128) |
| `EXTRACT_WAV2VEC2` | `logical` | Enable wav2vec2 features |
| `RUN_PCA` | `logical` | Apply PCA to wav2vec2 |
| `N_COMPONENTS` | `double` | PCA target dims (default: 64) |
| `DEBUG_MODE` | `logical` | Single-trial test mode |
| `APPEND_MODE` | `logical` | Resume from existing output |
| `dataset_name_id_pair` | `containers.Map` | Dataset name → numeric ID |
| `raw_dataset_names` | `string[]` | Datasets needing stimulus extraction |
| `desired_wav2vec2_fs` | `double` | wav2vec2 output rate (default: 50) |
