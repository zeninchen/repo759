#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=5
#SBATCH --time=00:10:00
#SBATCH --output=task3.out
#SBATCH --error=task3.err
cd $SLURM_SUBMIT_DIR

./task3_scale 
./task3_scale 16 task3_16.csv