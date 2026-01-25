#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task6
#SBATCH --cpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --output=task6.out
#SBATCH --error=task6.err

cd $SLURM_SUBMIT_DIR
./task6 6
