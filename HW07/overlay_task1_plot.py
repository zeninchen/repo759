import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Input files
n_sweep_file = Path('task2_1024.csv')
cub_file = Path('task1_cub_times.csv')
thrust_file = Path('task1_thrust_times.csv')

# Read CSVs
n_sweep = pd.read_csv(n_sweep_file)
cub = pd.read_csv(cub_file)
thrust = pd.read_csv(thrust_file)

# Keep only the columns we need from n_sweep
if 'n' not in n_sweep.columns or 'time_ms' not in n_sweep.columns:
    raise ValueError("n_sweep.csv must contain columns 'n' and 'time_ms'.")
if 'n' not in cub.columns or 'time_ms' not in cub.columns:
    raise ValueError("task1_cub_times.csv must contain columns 'n' and 'time_ms'.")
if 'n' not in thrust.columns or 'time_ms' not in thrust.columns:
    raise ValueError("task1_thrust_times.csv must contain columns 'n' and 'time_ms'.")

n_sweep_plot = n_sweep[['n', 'time_ms']].copy().dropna()
n_sweep_plot = n_sweep_plot.sort_values('n')

cub_plot = cub[['n', 'time_ms']].copy().dropna()
cub_plot = cub_plot.sort_values('n')

thrust_plot = thrust[['n', 'time_ms']].copy().dropna()
thrust_plot = thrust_plot.sort_values('n')

# Plot all three curves together.
# Because n_sweep may use different n values, matplotlib will still overlay them correctly.
plt.figure(figsize=(8, 6))
plt.loglog(n_sweep_plot['n'], n_sweep_plot['time_ms'], marker='o', label='HW05 task2_1024')
plt.loglog(cub_plot['n'], cub_plot['time_ms'], marker='s', label='CUB reduction')
plt.loglog(thrust_plot['n'], thrust_plot['time_ms'], marker='^', label='Thrust reduction')

plt.xlabel('n')
plt.ylabel('Time (ms)')
plt.title('Task1 Runtime Comparison (log-log scale)')
plt.grid(True, which='both', linestyle='--', alpha=0.5)
plt.legend()
plt.tight_layout()

# Save outputs
plt.savefig('task1.pdf')
plt.savefig('task1_overlay.png', dpi=200)
print('Saved: task1.pdf and task1_overlay.png')
