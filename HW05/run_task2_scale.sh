#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task2_scale
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=8
#SBATCH --time=00:10:00
#SBATCH --output=task2_scale.out
#SBATCH --error=task2_scale.err
cd $SLURM_SUBMIT_DIR

./task2_scale
