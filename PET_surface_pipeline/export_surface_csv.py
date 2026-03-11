#!/usr/bin/env python
import argparse
from pathlib import Path

import nibabel as nib
import numpy as np
import pandas as pd
from nibabel.freesurfer import read_geometry


def load_mgh_scalar(path):
    arr = nib.load(path).get_fdata()
    arr = np.asarray(arr).squeeze()
    if arr.ndim != 1:
        raise ValueError(f"Expected 1D surface data, got shape {arr.shape} from {path}")
    return arr.astype(np.float32)


def build_hemi_df(fsaverage_dir, hemi, surf_values):
    surf_path = Path(fsaverage_dir) / "surf" / f"{hemi}.white"
    coords, _ = read_geometry(str(surf_path))

    if len(coords) != len(surf_values):
        raise ValueError(
            f"Vertex number mismatch for {hemi}: "
            f"{len(coords)} coords vs {len(surf_values)} values"
        )

    df = pd.DataFrame({
        "hemi": hemi,
        "vertex_id": np.arange(len(surf_values), dtype=np.int32),
        "x": coords[:, 0],
        "y": coords[:, 1],
        "z": coords[:, 2],
        "suvr": surf_values,
    })
    return df


def main():
    parser = argparse.ArgumentParser(description="Export fsaverage surface SUVR to CSV/NPY/TXT.")
    parser.add_argument("--fsaverage-dir", required=True, help="Path to SUBJECTS_DIR/fsaverage")
    parser.add_argument("--lh", required=True, help="Left hemisphere .mgh surface values")
    parser.add_argument("--rh", required=True, help="Right hemisphere .mgh surface values")
    parser.add_argument("--out-csv", required=True, help="Output CSV path")
    parser.add_argument("--out-npy", required=True, help="Output NPY path")
    parser.add_argument("--out-txt", default=None, help="Optional output TXT path for full table")
    parser.add_argument("--out-values-txt", default=None, help="Optional output TXT path for SUVR values only")
    args = parser.parse_args()

    lh_vals = load_mgh_scalar(args.lh)
    rh_vals = load_mgh_scalar(args.rh)

    df_lh = build_hemi_df(args.fsaverage_dir, "lh", lh_vals)
    df_rh = build_hemi_df(args.fsaverage_dir, "rh", rh_vals)

    df = pd.concat([df_lh, df_rh], axis=0, ignore_index=True)

    # Save CSV
    Path(args.out_csv).parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(args.out_csv, index=False)

    # Save NPY
    Path(args.out_npy).parent.mkdir(parents=True, exist_ok=True)
    np.save(args.out_npy, {
        "lh": lh_vals,
        "rh": rh_vals,
        "all": df["suvr"].to_numpy(dtype=np.float32),
    }, allow_pickle=True)

    # Save full TXT table
    if args.out_txt is not None:
        Path(args.out_txt).parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(args.out_txt, sep="\t", index=False, float_format="%.6f")

    # Save SUVR-only TXT
    if args.out_values_txt is not None:
        Path(args.out_values_txt).parent.mkdir(parents=True, exist_ok=True)
        np.savetxt(
            args.out_values_txt,
            df["suvr"].to_numpy(dtype=np.float32),
            fmt="%.6f"
        )

    print(f"Saved CSV: {args.out_csv}")
    print(f"Saved NPY: {args.out_npy}")
    if args.out_txt is not None:
        print(f"Saved TXT table: {args.out_txt}")
    if args.out_values_txt is not None:
        print(f"Saved TXT values: {args.out_values_txt}")
    print(df.head())


if __name__ == "__main__":
    main()