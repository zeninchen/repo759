#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=8
#SBATCH --time=00:10:00
#SBATCH --output=task1_scale.out
#SBATCH --error=task1_scale.err
cd $SLURM_SUBMIT_DIR

./task1_scale
