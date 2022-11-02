#!/bin/bash

job_file="job.txt"
rm $job_file 2>/dev/null

project_root="/ocean/projects/med220004p"
exp_dir="${project_root}/clane2/RBC/experiments/distortion_correction_evaluation"
data_dir="${exp_dir}/data"
out_dir="${exp_dir}/output/cpac"
config="${exp_dir}/etc/cpac_rbc_distcorr_eval.yaml"

for subdir in ${data_dir}/sub-*; do
    sub=${subdir##*sub-}
    cmd="cpac --platform singularity --tag nightly run \
${data_dir} ${out_dir} participant \
--participant_label ${sub} --pipeline_file ${config} \
--save_working_dir --n_cpus 16 --mem_gb 24"
    echo $cmd >> $job_file
done