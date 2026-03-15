#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task1_scale
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --time=00:10:00
#SBATCH --output=task1_scale.out
#SBATCH --error=task1_scale.err
#SBATCH --mem=8G

cd $SLURM_SUBMIT_DIR

bash ./task1_scale.sh