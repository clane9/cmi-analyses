#!/bin/bash

#SBATCH --job-name=cpac_01
#SBATCH --partition=RM-shared
#SBATCH --ntasks=16
#SBATCH --mem=32000
#SBATCH --time=03:00:00
#SBATCH --array=1
## #SBATCH --array=1,11,21
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=clane@jhu.edu

eval "$(conda shell.bash hook)"
conda activate cpac

# Set some environment variables
EXP_DIR="/ocean/projects/med220004p/clane2/RBC/experiments/distortion_correction_evaluation"
# cd $EXP_DIR
# NOTE: for now, the way I've found to run cpac jobs is from a working "cpac"
# directory
cd ${EXP_DIR}/output/cpac

JOB_NAME="cpac_01"
# JOB_FILE="jobs/$JOB_NAME/job.txt"
JOB_FILE="../../jobs/$JOB_NAME/job.txt"

# Run particular job from job list.
tail -n +$SLURM_ARRAY_TASK_ID $JOB_FILE | head -n 1 | sh
