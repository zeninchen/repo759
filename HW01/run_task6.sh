#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH -t 0-00:30:00
#SBATCH --job-name=task6
#SBATCH --cpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --output=task6_%j.out
#SBATCH --error=task6_%j.err

./task6 6