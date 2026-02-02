#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=ece759_task1_scaling
#SBATCH --output=task1_scaling.out
#SBATCH --error=task1_scaling.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=20G



# Go to the folder containing scan.cpp/task1.cpp
cd $SLURM_SUBMIT_DIR

./task1_scale > task1_times.csv


