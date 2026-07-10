# SuperPrepare Documentation

SuperPrepare is a multi-dataset EEG preprocessing pipeline for Auditory Attention Detection (AAD) research. It unifies heterogeneous EEG datasets — collected across different labs with different hardware, channel layouts, and paradigms — into a single standardized `.npy` format ready for machine learning.

## What You'll Find Here

| Document | Description |
|----------|-------------|
| [Getting Started](getting-started.md) | Installation, dependencies, and running your first pipeline |
| [Configuration](configuration.md) | `config.mlx` reference — all parameters explained |
| [Pipeline Deep Dive](pipeline.md) | What happens at each stage and why |
| [Datasets](datasets.md) | Supported datasets and how to add a new one |
| [Output Format](output-format.md) | `.npy` structure, metadata, and scaling factors |
| [API Reference](api-reference.md) | Key functions, classes, and their signatures |

## Quick Links

- **Main entry point:** `matlab-preprocessing-code/split_datasets.m`
- **Configuration:** `matlab-preprocessing-code/config.mlx`
- **Add a dataset:** Modify `config.mlx`, `get_dataset_info.m`, and `extract_trials.m`
