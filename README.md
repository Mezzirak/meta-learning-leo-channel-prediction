# MetaModelNet for LEO Satellite Channel Prediction

Gradient-free meta-learning for adapting a pre-trained channel predictor to rare,
unseen "tail" channel conditions (low-elevation, urban/vehicular) in Low Earth
Orbit links, without any test-time gradient computation.

<!-- One-line status badge line is optional. Add a DOI badge once the Zenodo
     archive is minted (see Data & Weights). -->

## Overview

Channel aging is a core problem for LEO links: by the time channel state
information (CSI) is acquired and fed back, the channel has already moved on. A
hybrid Transformer-LSTM (T-LSTM) predictor handles the common ("head"/"body")
conditions well, but degrades on rare tail conditions that are underrepresented
in training.

This repository implements **MetaModelNet (MMN)**, a meta-network that learns a
transformation in the *weight space* of the T-LSTM decoder. Given a small k-shot
adaptation of the decoder on a new tail task, MMN predicts the fully-adapted
weights in a single forward pass, no test-time gradients required. The result is
near-fine-tuning accuracy at a fraction of the inference cost.

The pipeline spans a MATLAB satellite-constellation simulation (Starlink-like
geometry, Rician fading, UPA, Doppler) and a PyTorch implementation of the
predictor and meta-network.

## Key Results

Evaluated on 24 held-out tail tasks, averaged over 5 seeds, prediction horizons
Fh = 2 to 7. <!-- Reconcile these against a single end-to-end run before publishing. -->

| Method                         | NMSE (dB)        | Tail-task win rate |
|--------------------------------|------------------|--------------------|
| T-LSTM, no adaptation          | ~ -9.4           | baseline           |
| T-LSTM + MetaModelNet          | ~ -16.0 ± 0.21   | 24 / 24            |
| T-LSTM + 50-shot fine-tuning   | ~ -16.3 ± 0.08   | 24 / 24            |

- MMN matches supervised fine-tuning to within ~0.3 dB while being roughly
  **452x faster** at adaptation time (single forward pass vs iterative fine-tuning).
- **Bit error rate** floors: baseline ~1.67%, MMN ~1.21%, 50-shot FT ~1.06%.
  MMN recovers ~63% of the baseline rate loss.
- Achievable-rate gap closed to ~0.07 to 0.08 bits/s/Hz at 10 dB.

![BER vs SNR](figures/ber_vs_snr_report.png)

<!-- The notebook saves ber_vs_snr_report.png/.pdf to the working directory.
     Move the PNG into a figures/ folder and commit it so this embed renders. -->

## Repository Structure

```
.
├── matlab/                     # Constellation + channel simulation
│   ├── CalculateSatellitesLocation.m
│   ├── RicianChannel.m
│   ├── Metalearning_prep.m     # builds MetaLearning_Dataset.mat
│   └── ...                     # geometry, Doppler, steering-vector helpers
├── attempt2_full_pipeline.ipynb   # Canonical notebook: train + evaluate + BER
├── figures/                    # Committed result figures for the README
└── README.md
```

<!-- Adjust paths to match how you actually lay the repo out. The .m files are
     currently flat; grouping them under matlab/ is recommended. -->

The canonical notebook is **`attempt2_full_pipeline.ipynb`**. Any other notebooks
in your local history (earlier drafts, the eval-only variant) should not be
committed, to avoid confusion over which one is authoritative.

## Requirements

- Python 3.10+
- PyTorch (CUDA 12.1 build for GPU training; CPU/MPS also work for evaluation)
- numpy, scipy, h5py, matplotlib
- MATLAB <!-- version --> for regenerating the dataset (not needed if you use the released .mat)

```bash
pip install torch numpy scipy h5py matplotlib
```

<!-- Pin exact versions in a requirements.txt for true reproducibility, e.g.
     run `pip freeze > requirements.txt` in your working environment. -->

## Data & Weights

The dataset and trained weights are released separately from the code (they are
large binaries and do not belong in git history):

- `MetaLearning_Dataset.mat` — the 7-field dataset (head/body/tail chunks with
  `fc` and `Difficulty` fields). <!-- Confirm you are releasing the 7-field
  version, not the 5-field orphan. The committed weights correspond to this one. -->
- `best_model.pt` — pre-trained base T-LSTM.
- `meta_net.pt` — trained MetaModelNet.
- `trajectories_pca.pt` — weight-space trajectories (optional, for the PCA cell).

**Download:** <!-- Zenodo / Figshare DOI link here. Minting a versioned DOI also
gives you something citable in the paper. -->

Place all four files in the same directory as the notebook (the notebook uses
relative paths) before running.

## Reproducing the Results

1. Obtain the dataset and weights (see above) and place them beside the notebook.
2. Open `attempt2_full_pipeline.ipynb`.
3. Run all cells top to bottom (Restart & Run All). The notebook will train the
   base model, train MMN, evaluate on the tail tasks, and produce the NMSE,
   horizon-sweep, PCA, latency, and BER/rate results in order.

To regenerate the dataset from scratch instead, run the MATLAB pipeline
(`Metalearning_prep.m` and dependencies) to produce `MetaLearning_Dataset.mat`.

## Configuration Notes

These settings are deliberate and load-bearing; changing them silently degrades
results:

- **Per-task normalisation** is intended. Global normalisation breaks the
  meta-learning pipeline and must not be substituted.
- **`sample_sizes = [50, 800]`** (a single MMN block) is the correct
  configuration. The multi-block `[50, 100, 200, 400, 800]` variant is an
  ablation only and gives worse results.
- Channels are **unit-normalised** before BER/rate computation. Raw LEO channels
  have norms on the order of 1e-9; skipping normalisation causes path-loss
  underflow and meaningless metrics.

## Citation

<!-- This work is under review at IEEE Communications Letters. Add the BibTeX
     entry on acceptance. Until then, cite the repository / Zenodo DOI. -->

```bibtex
@misc{<!-- key -->,
  title  = {MetaModelNet for LEO Satellite Channel Prediction},
  author = {<!-- author list -->},
  year   = {2026},
  note   = {Under review},
  url    = {<!-- repo / DOI -->}
}
```

## License

<!-- No license = all rights reserved, which prevents others from using your
     code. For academic code, MIT or BSD-3-Clause are common. CONFIRM with your
     supervisor and the institution's IP office before choosing, since this is
     university research with co-authors. Add a LICENSE file once decided. -->

## Acknowledgements

<!-- Supervisor, co-authors, institution, funding. Get co-author sign-off before
     making the repository public. -->
