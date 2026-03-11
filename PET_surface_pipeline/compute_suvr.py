#!/usr/bin/env python
import argparse
import json
from pathlib import Path

import nibabel as nib
import numpy as np


def main():
    parser = argparse.ArgumentParser(
        description="Compute volume-level SUVR using a reference-region mask."
    )
    parser.add_argument("--pet", required=True, help="PET volume in T1 space (.nii/.nii.gz)")
    parser.add_argument("--mask", required=True, help="Binary reference mask (.nii/.nii.gz)")
    parser.add_argument("--out", required=True, help="Output SUVR volume (.nii.gz)")
    parser.add_argument("--stats", required=True, help="Output JSON for summary stats")
    args = parser.parse_args()

    pet_img = nib.load(args.pet)
    mask_img = nib.load(args.mask)

    pet = pet_img.get_fdata().astype(np.float32)
    mask = mask_img.get_fdata() > 0

    if pet.shape != mask.shape:
        raise ValueError(f"PET shape {pet.shape} != mask shape {mask.shape}")

    ref_values = pet[mask]
    if ref_values.size == 0:
        raise ValueError("Reference mask is empty.")

    ref_mean = float(np.mean(ref_values))
    ref_std = float(np.std(ref_values))

    if ref_mean <= 0:
        raise ValueError(f"Reference mean is non-positive: {ref_mean}")

    suvr = pet / ref_mean

    out_img = nib.Nifti1Image(
        suvr.astype(np.float32),
        affine=pet_img.affine,
        header=pet_img.header
    )
    nib.save(out_img, args.out)

    stats = {
        "reference_region": "cerebellar_cortex",
        "reference_mean": ref_mean,
        "reference_std": ref_std,
        "pet_min": float(np.min(pet)),
        "pet_max": float(np.max(pet)),
        "suvr_min": float(np.min(suvr)),
        "suvr_max": float(np.max(suvr)),
        "num_reference_voxels": int(ref_values.size),
    }

    Path(args.stats).write_text(json.dumps(stats, indent=2))
    print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main()