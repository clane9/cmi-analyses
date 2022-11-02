#!/bin/bash

job_file="job.txt"
rm $job_file 2>/dev/null

project_root="/ocean/projects/med220004p"

image_file="${project_root}/clane2/images/c-pac:nightly-2210271554.sif"
exp_dir="${project_root}/clane2/RBC/experiments/distortion_correction_evaluation"
data_dir="${exp_dir}/data"
out_dir="${exp_dir}/output/cpac"
config="${exp_dir}/etc/cpac_rbc_distcorr_eval.yaml"

# bindings from steve
# $repo/CPAC:/code/CPAC -v $repo/dev/docker_data/run.py:/code/run.py -v $repo/dev/docker_data:/cpac_resources
# commit hash: 20f06d7
# updated to: 0967851 to fix the phasediff fieldmap file discovery
# updated to: 4203333 to fix the phasediff fieldmap file discovery (again) and
# output directory manifest
cpac_dir="/ocean/projects/med220004p/clane2/code/C-PAC"
bindings="-B ${cpac_dir}/CPAC:/code/CPAC \
-B ${cpac_dir}/dev/docker_data/run.py:/code/run.py \
-B ${cpac_dir}/dev/docker_data:/cpac_resources"
args="--cleanenv"


for subdir in ${data_dir}/sub-*; do
    sub=${subdir##*sub-}
    
    if [[ $sub == A* ]]; then
        # callback_arg="--runtime_usage ${exp_dir}/etc/sub-A00031893_ses-BAS1_callback.log"
        callback_arg=""
    elif [[ $sub == ND* ]]; then
        # callback_arg="--runtime_usage ${exp_dir}/etc/sub-NDARAA306NT2_ses-HBNsiteRU_callback.log"
        callback_arg=""
    else
        callback_arg=""
    fi

    cmd="singularity run ${bindings} ${args} ${image_file} \
${data_dir} ${out_dir} participant \
--participant_label ${sub} --pipeline_file ${config} \
--save_working_dir --n_cpus 14 --mem_gb 26 ${callback_arg}"
    echo $cmd >> $job_file
done
