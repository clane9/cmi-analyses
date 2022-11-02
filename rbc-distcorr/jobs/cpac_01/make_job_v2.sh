#!/bin/bash

job_file="job.txt"
rm $job_file 2>/dev/null

project_root="/ocean/projects/med220004p"

image_file="${project_root}/clane2/images/c-pac:nightly.sif"
exp_dir="${project_root}/clane2/RBC/experiments/distortion_correction_evaluation"
data_dir="${exp_dir}/data"
out_dir="${exp_dir}/output/cpac"
config="${exp_dir}/etc/cpac_rbc_distcorr_eval.yaml"

# singularity run c-pac:nightly.sif \
#     /ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation/data \
#     /ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation/output/cpac \
#     participant --participant_label 1161831083 \
#     --pipeline_file /ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation/etc/cpac_rbc_distcorr_eval.yaml \
#     --save_working_dir --n_cpus 16 --mem_gb 24

for subdir in ${data_dir}/sub-*; do
    sub=${subdir##*sub-}
    cmd="singularity run -B ${exp_dir}/scripts/run.py:/code/run.py \
--cleanenv ${image_file} \
${data_dir} ${out_dir} participant \
--participant_label ${sub} --pipeline_file ${config} \
--save_working_dir --n_cpus 16 --mem_gb 24"
    echo $cmd >> $job_file
done