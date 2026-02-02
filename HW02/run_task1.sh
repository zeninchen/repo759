#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --output=task1.out
#SBATCH --error=task1.err
cd $SLURM_SUBMIT_DIR
./task1 3