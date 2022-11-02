#!/bin/bash

data_dir="/ocean/projects/cis210040p/shared/RBC-testing/data/UPenn"
exp_dir="/ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation"
subs_file="${exp_dir}/etc/30_subs.txt"

link_dir="${exp_dir}/data"
rm -rf $link_dir 2>/dev/null

datasets=( "NKI" "PNC" "HBN" )
patterns=( "sub-A" "sub-[0-9]" "sub-NDA" )
tasks=( "task-rest_acq-1400" "task-rest_acq-singleband" "task-rest_run-1" )

for ii in {0..2}; do
    ds=${datasets[ii]}
    pattern=${patterns[ii]}
    task=${tasks[ii]}
    subs=$(cat $subs_file | grep $pattern)
    echo $ds
    echo $subs | wc -w
    for subses in $subs; do
        ses=$(echo $subses | cut -d _ -f 2)
        sub=$(echo $subses | cut -d _ -f 1)
        ses=${ses#ses-}
        sub=${sub#sub-}
        echo $sub $ses
        sesdir="${data_dir}/${ds}/sub-${sub}/ses-${ses}"
        if [[ ! -d $sesdir ]]; then
            echo "$subses" >> missing_subs.txt
            continue
        fi
        link_sub_dir="${link_dir}/sub-${sub}/ses-${ses}"
        mkdir -p $link_sub_dir
        for dirbase in anat fmap; do
            dirpath="${sesdir}/${dirbase}"
            if [[ -d $dirpath ]]; then
                mkdir $link_sub_dir/$dirbase
                ln -s $dirpath/* $link_sub_dir/$dirbase/
            fi
        done
        funcs=$(echo $sesdir/func/*${task}_bold*)
        mkdir $link_sub_dir/func
        ln -s $funcs $link_sub_dir/func/
    done
done

cp ${exp_dir}/etc/dataset_description.json ${link_dir}/
