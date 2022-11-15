#!/bin/bash

mkdir -p outbox/rbc_distcorr_outputs 2>/dev/null

# for dc in dc nodc; do
#     rm -r outbox/rbc_distcorr_outputs/fmriprep_${dc} 2>/dev/null
#     for d in output/fmriprep_${dc}/sub-*/ses-*; do
#         sub=$(echo $d | cut -d / -f 3)
#         ses=$(echo $d | cut -d / -f 4)
#         outdir="outbox/rbc_distcorr_outputs/fmriprep_${dc}/${sub}/${ses}"
#         mkdir -p $outdir
#         absd=$(readlink -f $d)
#         ln -s $absd/* ${outdir}/
#     done
# done

for dc in dc nodc; do
    origdir=$(readlink -f output/fmriprep_${dc})
    rm outbox/rbc_distcorr_outputs/fmriprep_${dc} 2>/dev/null
    ln -s $origdir outbox/rbc_distcorr_outputs/
done

for dc in dc nodc; do
    rm -r outbox/rbc_distcorr_outputs/cpac_${dc} 2>/dev/null
    for d in output/cpac/output/pipeline_rbc_distcorr_eval_${dc}/sub-*_ses-*; do
        subses=${d##*/}
        sub=$(echo $subses | cut -d _ -f 1)
        ses=$(echo $subses | cut -d _ -f 2)
        outdir="outbox/rbc_distcorr_outputs/cpac_${dc}/${sub}/${ses}"
        mkdir -p $outdir
        absd=$(readlink -f $d)
        ln -s $absd/* ${outdir}/
    done
done

for dc in dc nodc; do
    origdir=$(readlink -f output/fmriprep_nlin6_${dc})
    rm outbox/rbc_distcorr_outputs/fmriprep_nlin6_${dc} 2>/dev/null
    ln -s $origdir outbox/rbc_distcorr_outputs/
done

# tar \
#     --exclude *_bold.nii.gz --exclude *_xfm.nii.gz --exclude *_xfm.h5 \
#     -h -czvf outbox/rbc_distcorr_outputs.tar.gz outbox/rbc_distcorr_outputs 