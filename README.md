<!-- README.md is generated from README.Rmd. Please edit that file -->

# TiRank

<!-- badges: start -->

[![R-CMD-check](https://github.com/Exceret/rTiRank/actions/workflows/R-CMD-check.yaml/badge.svghttps://github.com/Exceret/rTiRank/actions/workflows/R-CMD-check.yaml/badge.svghttps://github.com/Exceret/rTiRank/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Exceret/rTiRank/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This is the R package fork of TiRank, as an extension for
[SigBridgeR](https://github.com/WangLabCSU/SigBridgeR).

To install:

    pak::pkg_install("Exceret/rTiRank")

<img src="./docs/source/_static/TiRank_white.png" alt="TiRank Logo" width="50%" />

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<tbody>
<tr>
<td style="text-align: left;"><strong>Full Documentation</strong></td>
<td style="text-align: left;">📖 <a
href="https://tirank.readthedocs.io"><strong>https://tirank.readthedocs.io</strong></a></td>
</tr>
<tr>
<td style="text-align: left;"><strong>Bioconda</strong></td>
<td style="text-align: left;"><a
href="http://bioconda.github.io/recipes/tirank/README.html"><img
src="https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat"
alt="install with bioconda" /></a></td>
</tr>
<tr>
<td style="text-align: left;"><strong>PyPI</strong></td>
<td style="text-align: left;"><a
href="https://pypi.org/project/TiRank/"><img
src="https://img.shields.io/pypi/v/tirank?style=flat-square"
alt="PyPI" /></a></td>
</tr>
<tr>
<td style="text-align: left;"><strong>License</strong></td>
<td style="text-align: left;"><a
href="https://github.com/LenisLin/TiRank/blob/main/LICENSE"><img
src="https://img.shields.io/github/license/LenisLin/TiRank?style=flat-square"
alt="License" /></a></td>
</tr>
<tr>
<td style="text-align: left;"><strong>Build Status</strong></td>
<td style="text-align: left;"><a
href="https://tirank.readthedocs.io/en/latest/"><img
src="https://readthedocs.org/projects/tirank/badge/?version=latest&amp;style=flat-square"
alt="Documentation Status" /></a></td>
</tr>
</tbody>
</table>

## Table of Contents

- 📚 [a) Overview](#a-overview)
- 🌟 [b) Features](#b-features)
- ⚙️ [c) Requirements](#c-requirements)
- 🛠️ [d) Installation](#d-installation)
- 🗂️ [e) Configuration (Files & Layout)](#e-configuration-files--layout)
- ▶️ [f) Usage (How to Run)](#f-usage-how-to-run)
- 📊 [g) Output Structure](#g-output-structure)
- ✅ [h) Testing](#h-testing)
- 📚 [Full Documentation](#full-documentation)
- 🧑‍💻 [Support](#support)
- 📜 [License](#license)

------------------------------------------------------------------------

## a) Overview

**TiRank** integrates bulk RNA‐seq with single-cell or spatial
transcriptomics to identify phenotype-associated regions or cell
clusters. It supports Cox survival analysis, classification, and
regression, and ships with standalone Python scripts, a standardized
Snakemake workflow, and a user-friendly web GUI.

<figure>
<img src="./docs/source/_static/Fig1.png" alt="TiRank Workflow" />
<figcaption aria-hidden="true">TiRank Workflow</figcaption>
</figure>

------------------------------------------------------------------------

## b) Features

- **🔗 Integration**: Bulk + scRNA-seq or spatial transcriptomics
- **🔄 Modes**: Cox survival, classification, regression
- **📈 Visualization**: UMAPs, spatial maps, score distributions
- **⚙️ Tunable**: Key hyperparameters exposed
- **🧰 Interfaces**: Scripts/CLI, Snakemake Workflow, Python API, Web
  GUI

------------------------------------------------------------------------

## c) Requirements

### System

- **OS**: Tested on `Ubuntu 22.04`, `Ubuntu 20.04`
- **Python**: `3.9`
- **RAM**: ≥ **16 GB** (more for large datasets)
- **GPU (important)**: **CUDA-compatible GPU required**
  - Tested with `RTX 2080Ti (CUDA 11.2)`, `RTX 3090 (CUDA 12.1)`,
    `RTX 4090 (CUDA 12.5)`
- **Disk**: Enough for datasets and intermediate files

### Data

- **Spatial or Single-Cell data**: To characterize heterogeneity
- **Bulk data**: Expression matrix + clinical metadata aligned by sample
  IDs

------------------------------------------------------------------------

## d) Installation

TiRank supports multiple setups.

### Method 1: Bioconda (Recommended)

1.  **Clone the repository:** (Required to access example scripts and
    the Snakemake workflow)

<!-- -->

    git clone https://github.com/LenisLin/TiRank.git
    cd TiRank

1.  **Create and activate the environment:**

<!-- -->

    conda create -n tirank python=3.9
    conda activate tirank

1.  **Install TiRank:**

<!-- -->

    conda install -c bioconda -c conda-forge tirank leidenalg python-igraph

### Method 2: Docker

    docker pull lenislin/tirank_v1:latest
    docker run -it --gpus all -p 8050:8050 -v $PWD:/workspace lenislin/tirank_v1:latest /bin/bash

### Method 3: Interactive Web Tool (GUI)

See **[GUI
Tutorial](https://tirank.readthedocs.io/en/latest/tutorial_web.html)**.

**TiRank GUI Video**

<p align="center">
<a href="https://www.youtube.com/watch?v=YMflTzJF6s8">
<img src="docs/source/_static/TiRank_Youtub.png" alt="Watch the video" width="400">
</a>
</p>

### (Required for examples) Download example data

If you plan to run the example scripts in **f) Usage**, please download
the testing datasets:

- 📥 **Sample data (Zenodo)**:
  [18275554](https://zenodo.org/records/18275554)
- 🧠 **Pretrained Model**: Required for Spatial Transcriptomics
  analysis. Download `ctranspath.pth` from the Zenodo link above.
- **Setup**:
  1.  Unzip the sample data folders under `data/ExampleData/`.
  2.  Create a folder `data/pretrainModel/` and place `ctranspath.pth`
      inside it.

  **Final structure should look like:** \`\`\`text data/ ├──
  ExampleData/ │ └── CRC\_ST\_Prog/ └── pretrainModel/ └──
  ctranspath.pth —

## e) Configuration (Files & Layout)

This section shows **where files live** and **which scripts exist**.
(How to run is in [f) Usage](#f-usage)

### CLI & Workflow

    TiRank/
    ├── tirank/                       # CLI entry point for workflows
    │   └── tirank_cli.py
    ├── workflow/                     # Snakemake workflow files
    │   ├── Snakefile
    │   ├── config/           
    │   │   └── config.yaml
    │   └── envs/
    │       └── tirank.yaml
    ├── Example/                      # default output location
    │   ├── SC-Response-SKCM.py       # scRNA-seq → bulk (melanoma response)
    │   └── ST-Cox-CRC.py             # Spatial transcriptomics → bulk (CRC survival)
    ├── data/
    │   ├── pretrainModel/
    │   │   └── ctranspath.pth
    │   └── ExampleData/
    │       ├── SKCM_SC_Res/
    │       │   ├── GSE120575.h5ad    # scRNA-seq datatirank_cli.py
    │       │   ├── Liu2019_meta.csv
    │       │   └── Liu2019_exp.csv
    │       └── CRC_ST_Prog/
    │           ├── GSE39582_clinical_os.csv
    │           ├── GSE39582_exp_os.csv
    │           └── SN048_A121573_Rep1/   # ST folder

### Web GUI

    Web/
    ├── assets/
    ├── components/
    ├── img/
    ├── layout/
    ├── data/
    │   ├── pretrainModel/
    │   │   └── ctranspath.pth
    │   ├── ExampleData/
    │       ├── CRC_ST_Prog/
    │       └── SKCM_SC_Res/
    ├── tiRankWeb/
    └── app.py

> Tip: Keep filenames exactly as shown. Scripts create needed subfolders
> under `results/` automatically.

------------------------------------------------------------------------

## f) Usage (How to Run)

You can run TiRank using standalone Python scripts or the standardized
Snakemake workflow.

### Option A: Python Scripts

(Optional) Edit **two variables** in each script—`dataPath` and
`savePath`—then run from the repo root.

#### 1) scRNA-seq → bulk (Melanoma response)

**Script:** `Example/SC-Response-SKCM.py` **Data:**
`data/ExampleData/SKCM_SC_Res`

**Run:**

    python Example/SC-Response-SKCM.py

**Tutorial:**
<https://tirank.readthedocs.io/en/latest/tutorial_sc_classification.html>

#### 2) Spatial transcriptomics → bulk (CRC survival)

**Script:** `Example/ST-Cox-CRC.py` **Data:**
`data/ExampleData/CRC_ST_Prog`

**Run:**

    python Example/ST-Cox-CRC.py

**Tutorial:**
<https://tirank.readthedocs.io/en/latest/tutorial_st_survival.html>

------------------------------------------------------------------------

### Option B: Standardized Workflow (Snakemake)

For reproducible, automated runs on new datasets.

1.  **Install Snakemake** (We recommend version 7.32.4 for maximum
    compatibility):

<!-- -->

    conda install -c bioconda snakemake=7.32.4 pulp=2.7.0

1.  **Run the workflow:**

<!-- -->

    cd workflow
    # The --use-conda flag enables automatic environment creation via Bioconda
    snakemake --use-conda --conda-frontend conda -c1

*(Replace `-c1` with the number of CPU cores available, e.g., `-c16`)*

------------------------------------------------------------------------

### Notes

- Use `os.path.join(...)` for portability in custom scripts.
- Ensure `Example/` is writable.

------------------------------------------------------------------------

## g) Output Structure

Each run writes to `<savePath>/` with a consistent structure:

    <savePath>/
    ├── 1_loaddata/
    │   ├── anndata.pkl
    │   ├── bulk_clinical.pkl
    │   └── bulk_exp.pkl
    │
    ├── 2_preprocessing/
    │   ├── 'bulk gene pair heatmap.png'
    │   ├── qc_violins.png
    │   ├── scAnndata.pkl
    │   ├── sc_gene_pairs_mat.pkl
    │   ├── similarity_df.pkl
    │   ├── split_data/
    │   ├── train_bulk_gene_pairs_mat.pkl
    │   └── val_bulkExp_gene_pairs_mat.pkl
    │
    └── 3_Analysis/
        ├── checkpoints/
        ├── data2train/
        ├── final_anndata.h5ad
        ├── model_para.pkl
        ├── saveDF_bulk.pkl
        ├── saveDF_sc.pkl
        ├── 'TiRank Pred Score Distribution.png'
        ├── 'UMAP of TiRank Label Score.png'
        ├── 'UMAP of TiRank Pred Score.png'
        └── spot_predict_score.csv   <-- **FINAL RESULT FILE**

### Final output interpretation

The file **`spot_predict_score.csv`** contains **`Rank_Label`**:

- **Cox (survival)**: `TiRank+` → worse survival, `TiRank-` → better
  survival
- **Classification**: `TiRank+` ↔ phenotype `1`, `TiRank-` ↔ phenotype
  `0`
- **Regression**: `TiRank+` → higher phenotype score, `TiRank-` → lower
  phenotype score

Use this for downstream tasks like subpopulation discovery, DEG, and
pathway enrichment.

------------------------------------------------------------------------

## h) Testing

### Quick installation test

    python - <<'PY'
    import tirank
    print("TiRank version:", getattr(tirank, "__version__", "unknown"))
    PY

### Workflow test (Snakemake)

Verify pipeline integrity and configuration without running full
analysis:

    cd workflow
    snakemake -n

*(If successfully configured, this will print the list of jobs to be
executed)*

------------------------------------------------------------------------

## Full Documentation

Complete guides, tutorials, API reference, and result interpretation:

### ➡️ **<https://tirank.readthedocs.io>**

------------------------------------------------------------------------

## Support

Questions or issues? Open an issue on GitHub:
<https://github.com/LenisLin/TiRank/issues>

------------------------------------------------------------------------

## License

TiRank is released under the **MIT License**.
