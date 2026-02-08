#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --output=task2.out
#SBATCH --error=task2.err
cd $SLURM_SUBMIT_DIR

./task2 