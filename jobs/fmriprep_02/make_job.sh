#!/bin/bash

job_file="job.txt"
rm $job_file 2>/dev/null

project_root="/ocean/projects/med220004p"

fs_license="/ocean/projects/med220004p/clane2/images/fs_license.txt"

image_file="${project_root}/clane2/images/fmriprep_22.0.2.sif"
exp_dir="${project_root}/clane2/RBC/experiments/distortion_correction_evaluation"
data_dir="${exp_dir}/data"

# changing the template space to MNI152NLin6Asym to match C-PAC
space_arg="--output-spaces MNI152NLin6Asym:res-2"
variants=( "fmriprep_dc_nlin6" "fmriprep_nodc_nlin6" )
opts=( "$space_arg" "$space_arg --ignore fieldmaps" )

for subdir in ${data_dir}/sub-*; do
    sub=${subdir##*sub-}
    for ii in {0..1}; do
        variant=${variants[ii]}
        opt=${opts[ii]}
        cmd="singularity run --cleanenv ${image_file} \
${data_dir} ${exp_dir}/output/${variant} \
participant \
--participant-label ${sub} \
-w ${exp_dir}/work/${variant} \
--skip_bids_validation --fs-license-file $fs_license --fs-no-reconall \
--nthreads 8 --omp-nthreads 8 --mem-mb 12000 \
$opt"
        echo $cmd >> $job_file
    done
done