#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task3
#SBATCH --cpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --output=task3.out
#SBATCH --error=task3.err
cd $SLURM_SUBMIT_DIR
./task3 