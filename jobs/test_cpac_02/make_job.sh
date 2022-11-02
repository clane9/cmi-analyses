#!/bin/bash

job_file="job.txt"
rm $job_file 2>/dev/null

project_root="/ocean/projects/med220004p"

image_file="${project_root}/clane2/images/c-pac:nightly.sif"
exp_dir="${project_root}/clane2/RBC/experiments/distortion_correction_evaluation"
data_dir="${exp_dir}/data"
out_dir="${exp_dir}/output/test_cpac_2"
config="${exp_dir}/etc/cpac_rbc_distcorr_eval.yaml"

# bindings from steve
# $repo/CPAC:/code/CPAC -v $repo/dev/docker_data/run.py:/code/run.py -v $repo/dev/docker_data:/cpac_resources
cpac_dir="/ocean/projects/med220004p/clane2/code/C-PAC"
bindings="-B ${cpac_dir}/CPAC:/code/CPAC \
-B ${cpac_dir}/dev/docker_data/run.py:/code/run.py \
-B ${cpac_dir}/dev/docker_data:/cpac_resources"

subs="NDARAA306NT2 NDARBE091BGD"

for sub in $subs; do
    subdir="${data_dir}/sub-${sub}"
    cmd="singularity run ${bindings} --cleanenv ${image_file} \
${data_dir} ${out_dir} participant \
--participant_label ${sub} --pipeline_file ${config} \
--save_working_dir --n_cpus 8 --mem_gb 12"
    echo $cmd >> $job_file
done
