#!/bin/bash

#SBATCH --job-name=cpac_04
#SBATCH --partition=RM-shared
#SBATCH --ntasks=10
#SBATCH --mem=20000
#SBATCH --time=4:00:00
#SBATCH --array=1-60
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=clane@jhu.edu

# Set some environment variables
EXP_DIR="/ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation"
cd $EXP_DIR

JOB_NAME="cpac_04"
JOB_FILE="jobs/$JOB_NAME/job.txt"

# Run particular job from job list.
tail -n +$SLURM_ARRAY_TASK_ID $JOB_FILE | head -n 1 | sh
