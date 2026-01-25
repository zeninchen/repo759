#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task6
#SBATCH --cpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --output=task6_%j.out
#SBATCH --error=task6_%j.err

cd $SLURM_SUBMIT_DIR
./task6 6