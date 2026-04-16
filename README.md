# SIMD Accelerator — SystemVerilog

## Overview

Parameterized SIMD accelerator implemented in SystemVerilog with a multi-lane ALU and FSM-based control. 

Supports basic vector operations including add, dot product, reduction, and prefix scan.

[Design Schematic](https://github.com/zeninchen/repo759/blob/main/final_project/top_level_schematic.svg)

---

## ⚙️ How to Run / Simulate

This project's RTL was compiled and verified using **Siemens ModelSim**. To run the testbenches:

1. Launch ModelSim and create a new project in the cloned directory.
2. Add all the `.sv` files  from the `final_project` folder, and compile them.
3. Load the top-level testbench (`tb_simd.svv`).
4. Add the desired signals to the wave window and run the simulation to view the datapath execution.
5. Check the ModelSim transcript window, which outputs the execution results.
6. **Custom Execution:** You can change the lane count and customize your own values to validate the results in the testbench
