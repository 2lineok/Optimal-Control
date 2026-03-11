# PET Surface SUVR Pipeline

This repository provides a reproducible pipeline for generating **vertex-wise amyloid PET SUVR maps** on the cortical surface from paired **T1-weighted MRI** and **amyloid PET** data.

The pipeline follows the workflow:

**T1 preprocessing with FreeSurfer (`recon-all`) → PET-to-T1 registration with FSL FLIRT → volume-level SUVR computation using cerebellar cortex reference → surface projection → resampling to `fsaverage` → export of vertex-wise outputs**

---

## Overview

This pipeline is designed for studies that require subject-specific cortical amyloid PET measurements in a common surface space for downstream modeling, such as:

- reaction-diffusion modeling
- inverse parameter estimation
- finite element analysis on cortical meshes
- group-level vertex-wise statistical analysis

The current implementation computes **SUVR in volumetric space first**, then projects the SUVR image to the cortical surface. This design improves interpretability, quality control, and reproducibility.

---

## Main scripts

This repository contains three main scripts:

### 1. `run_pet_surface_pipeline.sh`
The main end-to-end pipeline. It performs:

1. FreeSurfer `recon-all` on T1 MRI
2. PET DICOM-to-NIfTI conversion if needed
3. PET-to-T1 registration using **FSL FLIRT**
4. cerebellar-cortex-based **volume-level SUVR computation**
5. projection of SUVR to native cortical surface
6. resampling to `fsaverage`
7. export of vertex-wise outputs

### 2. `compute_suvr.py`
Computes a **volume-level SUVR image** from:

- a PET image already registered to T1 space
- a binary reference-region mask

### 3. `export_surface_csv.py`
Exports surface-based SUVR values from FreeSurfer `.mgh` files into:

- `.csv`
- `.txt`
- `.npy`

---

## Requirements

### Software
- [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/)
- [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)
- [dcm2niix](https://github.com/rordenlab/dcm2niix) (only needed if PET input is DICOM)
- Python 3

### Python packages
- `numpy`
- `nibabel`
- `pandas`

Install Python dependencies with:

```bash
pip install numpy nibabel pandas