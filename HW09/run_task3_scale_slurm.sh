#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task3_scale
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:10:00
#SBATCH --output=task3_scale.out
#SBATCH --error=task3_scale.err
#SBATCH --mem=4G

cd $SLURM_SUBMIT_DIR

bash ./run_task3_scale.sh