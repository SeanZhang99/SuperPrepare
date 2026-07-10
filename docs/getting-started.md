# Getting Started

## Prerequisites

SuperPrepare requires **both MATLAB and Python**, as the pipeline uses MATLAB's Python bridge to call Python functions from within MATLAB scripts.

### MATLAB Requirements

| Component | Purpose |
|-----------|---------|
| MATLAB (R2020b or later recommended) | Core pipeline execution |
| [EEGLAB](https://sccn.ucsd.edu/eeglab/) (2023.0+) | ICA, ASR bad channel removal, ICLabel |
| [AMToolbox](http://www.amtoolbox.org/) | Gammatone filterbank, ERB-spaced filters |
| Signal Processing Toolbox | `butter`, `filtfilt`, `fir1`, `resample`, `hilbert` |
| Statistics & Machine Learning Toolbox | `trimmean` (for `SubjectwiseScaler`) |

### Python Requirements

Python 3.8+ with the following packages:

```bash
pip install numpy librosa scipy mne scikit-learn h5py torch transformers
```

> **Note:** `torch` and `transformers` are only needed if you enable wav2vec2 feature extraction. If you set `EXTRACT_WAV2VEC2 = false`, you can skip them.

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/SeanZhang99/SuperPrepare.git
cd SuperPrepare
```

---

## Step 2: Configure MATLAB's Python Bridge

MATLAB needs to know which Python to use. In MATLAB:

```matlab
% Check current Python
pyenv

% Set to your Python environment (adjust path as needed)
pyenv('Version', 'C:\Users\YourName\miniconda3\python.exe');

% Verify
pyenv
```

> **Important:** The Python environment you point to must have all required packages installed.

---

## Step 3: Add MATLAB Toolboxes to Path

```matlab
% Add EEGLAB
addpath('C:\path\to\eeglab2023.0');
eeglab nogui;  % Initialize EEGLAB

% Add AMToolbox
addpath('C:\path\to\amtoolbox');
```

---

## Step 4: Configure Paths

Open `matlab-preprocessing-code/config.mlx` and set:

- `raw_path` — Path to your raw/preprocessed EEG datasets
- `save_path` — Path where the pipeline will write standardized outputs
- `all_datasets` — List of dataset names to process

See [Configuration](configuration.md) for a full reference.

---

## Step 5: Run the Pipeline

```matlab
cd matlab-preprocessing-code/
split_datasets
```

The pipeline iterates through all configured datasets, subjects, and trials, producing `.npy` files in the `save_path` directory.

> **Tip:** Set `DEBUG_MODE = true` in `config.mlx` to process only the first subject's first trial. Use this to verify everything works before a full run.

---

## What Happens Next

1. For each dataset, the pipeline reads preprocessed EEG data (`.mat` or `.npy`)
2. It loads or computes audio features: waveform, gammatone envelope, mel spectrogram, and optionally wav2vec2 embeddings
3. Everything is resampled to `common_fs`, trimmed, and scaled
4. Output is saved under `save_path/exg/`, `save_path/env/`, `save_path/mel/`, etc.
5. Metadata and scaling factors are saved as Python pickles in `save_path/meta/`

See [Pipeline Deep Dive](pipeline.md) for a detailed walkthrough.

---

## Troubleshooting

### `py.numpy` not found

MATLAB can't find your Python environment. Run `pyenv` to check, then point it to the correct Python:

```matlab
pyenv('Version', 'C:\path\to\python.exe');
```

### `eeglab` not found

EEGLAB isn't on your path. Add it and initialize:

```matlab
addpath('C:\path\to\eeglab2023.0');
eeglab nogui;
```

### Out of memory on GPU (wav2vec2)

The wav2vec2 inference uses `.half().cuda()`. If your GPU runs out of memory:
- Reduce `n_components` in PCA
- Set `EXTRACT_WAV2VEC2 = false` in `config.mlx`
- Run on CPU by modifying `extract_wav2vec.m`
