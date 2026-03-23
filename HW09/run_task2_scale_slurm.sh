#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task2_scale
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --time=00:15:00
#SBATCH --output=task2_scale.out
#SBATCH --error=task2_scale.err
#SBATCH --mem=8G

cd $SLURM_SUBMIT_DIR

# run script
bash ./run_task2_scale.sh