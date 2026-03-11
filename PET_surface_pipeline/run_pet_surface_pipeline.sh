#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# ============================================================
# run_pet_surface_pipeline.sh
#
# Pipeline:
#   1. Run FreeSurfer recon-all on T1
#   2. Convert PET DICOM to NIfTI if needed
#   3. Register PET to T1 using FSL FLIRT
#   4. Compute volume-level SUVR using cerebellar cortex
#   5. Project SUVR volume to native surface
#   6. Resample to fsaverage
#   7. Export CSV / TXT / NPY
#
# Usage:
#   bash run_pet_surface_pipeline.sh \
#       <SUBJ_ID> \
#       <T1_INPUT> \
#       <PET_INPUT> \
#       <SUBJECTS_DIR> \
#       <OUTDIR> \
#       <COMPUTE_SUVR_PY> \
#       <EXPORT_SURFACE_CSV_PY> \
#       [PET_IS_DICOM]
#
# Example:
#   bash run_pet_surface_pipeline.sh \
#       SUBJ001 \
#       /path/to/t1.nii.gz \
#       /path/to/pet.nii.gz \
#       /path/to/freesurfer_subjects \
#       /path/to/output/session1 \
#       /path/to/compute_suvr.py \
#       /path/to/export_surface_csv.py \
#       0
# ============================================================

SUBJ_ID=$1
T1_INPUT=$2
PET_INPUT=$3
SUBJECTS_DIR=$4
OUTDIR=$5
COMPUTE_SUVR_PY=$6
EXPORT_SURFACE_CSV_PY=$7
PET_IS_DICOM=${8:-0}

export SUBJECTS_DIR
mkdir -p "${OUTDIR}"

echo "============================================================"
echo "SUBJ_ID               = ${SUBJ_ID}"
echo "T1_INPUT              = ${T1_INPUT}"
echo "PET_INPUT             = ${PET_INPUT}"
echo "SUBJECTS_DIR          = ${SUBJECTS_DIR}"
echo "OUTDIR                = ${OUTDIR}"
echo "COMPUTE_SUVR_PY       = ${COMPUTE_SUVR_PY}"
echo "EXPORT_SURFACE_CSV_PY = ${EXPORT_SURFACE_CSV_PY}"
echo "PET_IS_DICOM          = ${PET_IS_DICOM}"
echo "============================================================"

# ------------------------------------------------------------
# Check required commands
# ------------------------------------------------------------
command -v recon-all >/dev/null 2>&1 || { echo "Error: recon-all not found."; exit 1; }
command -v mri_convert >/dev/null 2>&1 || { echo "Error: mri_convert not found."; exit 1; }
command -v flirt >/dev/null 2>&1 || { echo "Error: flirt not found."; exit 1; }
command -v mri_binarize >/dev/null 2>&1 || { echo "Error: mri_binarize not found."; exit 1; }
command -v mri_vol2surf >/dev/null 2>&1 || { echo "Error: mri_vol2surf not found."; exit 1; }
command -v mri_surf2surf >/dev/null 2>&1 || { echo "Error: mri_surf2surf not found."; exit 1; }
command -v python >/dev/null 2>&1 || { echo "Error: python not found."; exit 1; }

if [[ "${PET_IS_DICOM}" -eq 1 ]]; then
    command -v dcm2niix >/dev/null 2>&1 || { echo "Error: dcm2niix not found."; exit 1; }
fi

[[ -f "${T1_INPUT}" ]] || { echo "Error: T1 input not found: ${T1_INPUT}"; exit 1; }
[[ -f "${COMPUTE_SUVR_PY}" ]] || { echo "Error: compute_suvr.py not found: ${COMPUTE_SUVR_PY}"; exit 1; }
[[ -f "${EXPORT_SURFACE_CSV_PY}" ]] || { echo "Error: export_surface_csv.py not found: ${EXPORT_SURFACE_CSV_PY}"; exit 1; }

FS_SUBJ_DIR="${SUBJECTS_DIR}/${SUBJ_ID}"

# ------------------------------------------------------------
# Step 1. Run recon-all on T1
# ------------------------------------------------------------
if [[ ! -f "${FS_SUBJ_DIR}/scripts/recon-all.done" ]]; then
    echo "[1/8] Running recon-all ..."
    recon-all \
        -sd "${SUBJECTS_DIR}" \
        -s "${SUBJ_ID}" \
        -i "${T1_INPUT}" \
        -all
else
    echo "[1/8] recon-all already completed. Skipping."
fi

# ------------------------------------------------------------
# Step 2. Convert FreeSurfer reference files to NIfTI
# Use orig/001.mgz as FLIRT reference, matching your preference.
# ------------------------------------------------------------
T1_REF_MGZ="${FS_SUBJ_DIR}/mri/orig/001.mgz"
T1_REF_NII="${OUTDIR}/T1_ref_001.nii.gz"

ASEG_MGZ="${FS_SUBJ_DIR}/mri/aparc+aseg.mgz"
ASEG_NII="${OUTDIR}/aparc+aseg.nii.gz"

[[ -f "${T1_REF_MGZ}" ]] || { echo "Error: missing ${T1_REF_MGZ}"; exit 1; }
[[ -f "${ASEG_MGZ}" ]] || { echo "Error: missing ${ASEG_MGZ}"; exit 1; }

if [[ ! -f "${T1_REF_NII}" ]]; then
    echo "[2/8] Converting T1 reference MGZ to NIfTI ..."
    mri_convert "${T1_REF_MGZ}" "${T1_REF_NII}"
else
    echo "[2/8] T1 reference NIfTI already exists. Skipping."
fi

if [[ ! -f "${ASEG_NII}" ]]; then
    echo "[2/8] Converting aparc+aseg MGZ to NIfTI ..."
    mri_convert "${ASEG_MGZ}" "${ASEG_NII}"
fi

# ------------------------------------------------------------
# Step 3. Prepare PET NIfTI
# ------------------------------------------------------------
PET_NII=""

if [[ "${PET_IS_DICOM}" -eq 1 ]]; then
    echo "[3/8] Converting PET DICOM to NIfTI ..."
    mkdir -p "${OUTDIR}/pet_dcm2niix"
    dcm2niix -z y -o "${OUTDIR}/pet_dcm2niix" "${PET_INPUT}"

    pet_candidates=( "${OUTDIR}/pet_dcm2niix"/*.nii "${OUTDIR}/pet_dcm2niix"/*.nii.gz )
    [[ ${#pet_candidates[@]} -gt 0 ]] || { echo "Error: no PET NIfTI generated from DICOM."; exit 1; }
    PET_NII="${pet_candidates[0]}"
else
    PET_NII="${PET_INPUT}"
fi

[[ -f "${PET_NII}" ]] || { echo "Error: PET file not found: ${PET_NII}"; exit 1; }

echo "[3/8] PET NIfTI = ${PET_NII}"

# ------------------------------------------------------------
# Step 4. Register PET to T1 using FLIRT
# ------------------------------------------------------------
PET_IN_T1="${OUTDIR}/pet_in_t1_flirt.nii.gz"
PET2T1_MAT="${OUTDIR}/pet2t1_flirt.mat"

if [[ ! -f "${PET_IN_T1}" ]]; then
    echo "[4/8] Running FLIRT registration (PET -> T1) ..."
    flirt \
        -in "${PET_NII}" \
        -ref "${T1_REF_NII}" \
        -out "${PET_IN_T1}" \
        -omat "${PET2T1_MAT}" \
        -cost normmi \
        -searchrx -90 90 \
        -searchry -90 90 \
        -searchrz -90 90 \
        -dof 6 \
        -interp trilinear
else
    echo "[4/8] Registered PET already exists. Skipping."
fi

# ------------------------------------------------------------
# Step 5. Build cerebellar cortex mask
# FreeSurfer labels:
#   8  = Left-Cerebellum-Cortex
#   47 = Right-Cerebellum-Cortex
# ------------------------------------------------------------
CB_MASK="${OUTDIR}/cerebellar_cortex_mask.nii.gz"

if [[ ! -f "${CB_MASK}" ]]; then
    echo "[5/8] Creating cerebellar cortex mask ..."
    mri_binarize \
        --i "${ASEG_MGZ}" \
        --match 8 47 \
        --o "${CB_MASK}"
else
    echo "[5/8] Cerebellar cortex mask already exists. Skipping."
fi

# ------------------------------------------------------------
# Step 6. Compute volume-level SUVR
# ------------------------------------------------------------
SUVR_NII="${OUTDIR}/pet_suvr.nii.gz"
SUVR_STATS="${OUTDIR}/suvr_stats.json"

if [[ ! -f "${SUVR_NII}" ]]; then
    echo "[6/8] Computing volume-level SUVR ..."
    python "${COMPUTE_SUVR_PY}" \
        --pet "${PET_IN_T1}" \
        --mask "${CB_MASK}" \
        --out "${SUVR_NII}" \
        --stats "${SUVR_STATS}"
else
    echo "[6/8] SUVR image already exists. Skipping."
fi

# ------------------------------------------------------------
# Step 7. Project SUVR volume to native surface and fsaverage
# ------------------------------------------------------------
echo "[7/8] Projecting SUVR to native surface ..."
for hemi in lh rh; do
    out_native="${OUTDIR}/${hemi}.pet_suvr.native.mgh"
    if [[ ! -f "${out_native}" ]]; then
        mri_vol2surf \
            --mov "${SUVR_NII}" \
            --regheader "${SUBJ_ID}" \
            --hemi "${hemi}" \
            --projfrac 0.5 \
            --interp trilinear \
            --o "${out_native}"
    fi
done

echo "[7/8] Resampling to fsaverage ..."
for hemi in lh rh; do
    out_fsavg="${OUTDIR}/${hemi}.pet_suvr.fsaverage.mgh"
    if [[ ! -f "${out_fsavg}" ]]; then
        mri_surf2surf \
            --srcsubject "${SUBJ_ID}" \
            --trgsubject fsaverage \
            --hemi "${hemi}" \
            --sval "${OUTDIR}/${hemi}.pet_suvr.native.mgh" \
            --tval "${out_fsavg}"
    fi
done

# ------------------------------------------------------------
# Step 8. Export vertex-wise data
# ------------------------------------------------------------
echo "[8/8] Exporting vertex-wise SUVR ..."
python "${EXPORT_SURFACE_CSV_PY}" \
    --fsaverage-dir "${SUBJECTS_DIR}/fsaverage" \
    --lh "${OUTDIR}/lh.pet_suvr.fsaverage.mgh" \
    --rh "${OUTDIR}/rh.pet_suvr.fsaverage.mgh" \
    --out-csv "${OUTDIR}/pet_suvr_fsaverage_vertices.csv" \
    --out-npy "${OUTDIR}/pet_suvr_fsaverage_vertices.npy" \
    --out-txt "${OUTDIR}/pet_suvr_fsaverage_vertices.txt" \
    --out-values-txt "${OUTDIR}/pet_suvr_fsaverage_values.txt"

echo "Done."
echo "Outputs saved in: ${OUTDIR}"