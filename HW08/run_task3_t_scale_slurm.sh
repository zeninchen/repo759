#!/usr/bin/env zsh
#SBATCH -p instruction
#SBATCH --job-name=task3_t
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --time=00:10:00
#SBATCH --output=task3_t.out
#SBATCH --error=task3_t.err
#SBATCH --mem=8G

cd $SLURM_SUBMIT_DIR

g++ task3.cpp msort.cpp -Wall -O3 -std=c++17 -o task3 -fopenmp

bash ./task3_t_scale.sh