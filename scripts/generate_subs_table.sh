#!/bin/bash

match_pattern () {
    pattern=$1
    firstmatch=$(echo $pattern | cut -d " " -f 1)
    [[ -e $firstmatch ]]
}

data_dir="/ocean/projects/cis210040p/shared/RBC-testing/data/UPenn"

datasets="CCNP  HBN  HRC  NKI  PNC"

echo "dataset,subject,session,fmap,task" > subs_table.csv

for ds in $datasets; do
    dsdir=${data_dir}/${ds}
    for subdir in ${dsdir}/sub-*; do
        sub=${subdir##*/sub-}
        for sesdir in ${subdir}/ses-*; do
            ses=${sesdir##*/ses-}
            fmapdir=${sesdir}/fmap
            funcdir=${sesdir}/func
            anatdir=${sesdir}/anat
            if [[ ! ( -d $funcdir && -d $anatdir ) ]]; then
                continue
            fi
            if ! match_pattern $funcdir/*_bold.nii.gz; then
                continue
            fi

            epiap="${fmapdir}/*_dir-AP_epi.nii.gz"
            epipa="${fmapdir}/*_dir-PA_epi.nii.gz"
            mag1="${fmapdir}/*_magnitude1.nii.gz"
            mag2="${fmapdir}/*_magnitude2.nii.gz"
            phase1="${fmapdir}/*_phase1.nii.gz"
            phase2="${fmapdir}/*_phase2.nii.gz"
            if [[ ! -d $fmapdir ]]; then
                fmaptype="none"
            elif match_pattern $epiap && match_pattern $epipa; then
                fmaptype="epi"
            elif match_pattern $mag1 && match_pattern $mag2 && match_pattern $phase1 && match_pattern $phase2; then
                fmaptype="phasediff"
            else
                fmaptype="unknown"
            fi

            for funcpath in ${funcdir}/*_bold.nii.gz; do
                functype=${funcpath##*sub-${sub}_ses-${ses}_}
                functype=${functype%_bold.nii.gz}
                echo "$ds,$sub,$ses,$fmaptype,$functype" >> subs_table.csv
            done
        done
    done
done