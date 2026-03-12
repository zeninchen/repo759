#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task3
#SBATCH --ntasks=1
#SBATCH --nodes=1 --cpus-per-task=4
#SBATCH --gpus-per-task=0
#SBATCH --time=00:10:00
#SBATCH --output=task3.out
#SBATCH --error=task3.err
#SBATCH --mem=32G
cd $SLURM_SUBMIT_DIR

./task3
