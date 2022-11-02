#!/bin/bash

#SBATCH --job-name=test_cpac_02
#SBATCH --partition=RM-shared
#SBATCH --ntasks=8
#SBATCH --mem=16000
#SBATCH --time=05:00:00
#SBATCH --array=1-2
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=clane@jhu.edu

# Set some environment variables
EXP_DIR="/ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation"
cd $EXP_DIR

JOB_NAME="test_cpac_02"
JOB_FILE="jobs/$JOB_NAME/job.txt"

# Run particular job from job list.
tail -n +$SLURM_ARRAY_TASK_ID $JOB_FILE | head -n 1 | sh
