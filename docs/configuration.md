# Configuration Guide

All pipeline configuration lives in `matlab-preprocessing-code/config.mlx` (a MATLAB Live Script). Open it in MATLAB's Live Editor for an interactive editing experience, or convert it to a plain `.m` file if you prefer.

---

## Required Settings

### `raw_path`
```matlab
raw_path = "E:\EEG_dataset_Superhuge\";
```
The root directory containing all raw/preprocessed datasets. Each dataset expects a specific subdirectory structure — see [Datasets](datasets.md) for details.

### `save_path`
```matlab
save_path = "E:\SuperPrepare_output\";
```
The directory where standardized `.npy` files and metadata will be written.

### `all_datasets`
```matlab
all_datasets = ["NJU_raw", "KUL_preprocessed", "DTU_raw"];
```
List of dataset names to process. Each name follows the format `DatasetName_type`, where `type` is:
- `raw` — Raw data that needs stimulus/envelope extraction
- `preprocessed` — Already preprocessed with envelopes available

**Available dataset names:**
`NJU_raw`, `NJU_preprocessed`, `KUL_raw`, `KUL_preprocessed`, `Alices_raw`, `sparKULee_raw`, `sparKULee_preprocessed`, `DTU_raw`, `DTU_preprocessed`, `PKU_preprocessed`, `PKU-NBD_preprocessed`, `ICL_preprocessed`, `AHU_preprocessed`, `KUL-AV-GC_preprocessed`, `NUS_preprocessed`, `CocktailParty_preprocessed`, `USTC_preprocessed`

---

## Processing Flags

### `EXTRACT_WAV2VEC2`
```matlab
EXTRACT_WAV2VEC2 = true;
```
Whether to extract wav2vec2.0 speech embeddings. Set to `false` if you don't need neural speech features or want faster processing.

### `RUN_PCA`
```matlab
RUN_PCA = true;
```
Whether to apply PCA dimensionality reduction to wav2vec2 features. When `true`, the 1024-dim embeddings are reduced to `N_COMPONENTS` dimensions.

### `N_COMPONENTS`
```matlab
N_COMPONENTS = 64;
```
Number of PCA components for wav2vec2 reduction. Only relevant when `RUN_PCA = true`.

### `DEBUG_MODE`
```matlab
DEBUG_MODE = true;
```
When enabled, the pipeline processes only the first subject's first trial. Use this to test configuration before a full run.

### `APPEND_MODE`
```matlab
APPEND_MODE = false;
```
When `true`, the pipeline loads existing `metadata.pkl` and `scaling_factor.pkl` and appends new results. When `false`, it starts fresh.

---

## Feature Extraction Parameters

### `common_fs`
```matlab
common_fs = 128;
```
Target sampling rate (Hz) for all output EEG and feature arrays.

### `desired_wav2vec2_fs`
```matlab
desired_wav2vec2_fs = 50;
```
Output sampling rate for wav2vec2 features. The wav2vec2 model outputs features at 50 Hz by default.

---

## Metadata

### `dataset_name_id_pair`
```matlab
dataset_name_id_pair = containers.Map({...}, {...});
```
Maps dataset name prefixes to numeric IDs. These IDs appear in output filenames as `dataset-XXX-`.

### `raw_dataset_names`
```matlab
raw_dataset_names = ["NJU", "KUL", "Alices", ...];
```
List of datasets that provide raw EEG data and need stimulus/envelope computation.

---

## Complete Example

```matlab
% Paths
raw_path = "E:\EEG_dataset_Superhuge\";
save_path = "E:\SuperPrepare_output\";

% Datasets to process
all_datasets = ["NJU_raw", "KUL_preprocessed", "DTU_raw"];

% Flags
EXTRACT_WAV2VEC2 = false;   % Skip neural features for now
DEBUG_MODE = true;          % Test with one trial
APPEND_MODE = false;         % Fresh run

% Processing
common_fs = 128;

% Metadata (update if adding datasets)
dataset_name_id_pair = containers.Map(...
    {"NJU", "KUL", "Alices", "sparKULee", "DTU", "PKU", "PKU-NBD", ...
     "ICL", "AHU", "KUL-AV-GC", "NUS", "CocktailParty", "USTC"}, ...
    {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13});
raw_dataset_names = ["NJU", "KUL", "Alices", "sparKULee", "DTU", "USTC"];
```
