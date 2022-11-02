#!/bin/bash

#SBATCH --job-name=cpac_02
#SBATCH --partition=RM-shared
#SBATCH --ntasks=14
#SBATCH --mem=28000
#SBATCH --time=6:00:00
#SBATCH --array=1,11,21
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=clane@jhu.edu

# Set some environment variables
EXP_DIR="/ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation"
cd $EXP_DIR

JOB_NAME="cpac_03"
JOB_FILE="jobs/$JOB_NAME/job.txt"

# Run particular job from job list.
tail -n +$SLURM_ARRAY_TASK_ID $JOB_FILE | head -n 1 | sh
