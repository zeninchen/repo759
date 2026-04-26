# Custom SIMD Accelerator (Mini-GPU Architecture)

*[Design Schematic Here](https://github.com/zeninchen/repo759/blob/main/final_project/top_level_schematic.svg)*

A highly parametrizable Single Instruction, Multiple Data (SIMD) accelerator built from scratch in SystemVerilog for UW-Madison's ECE 759 (High Performance Computing). 

This project isolates the core of GPU-style parallel execution, stripping away traditional CPU overhead (fetch logic, branch prediction, etc.) to focus entirely on maximizing vector compute throughput.

## 🚀 Microarchitecture & Features

* **Parametrizable Data Lanes:** The architecture is built with a scalable `n_of_lanes` parameter, allowing the accelerator to instantly synthesize as a 4-lane, 8-lane, or 16-lane execution unit without changing the underlying logic.
* **Command-Based FSM Control:** Orchestrated by a custom Finite State Machine (`control.sv`) that decodes high-level vector commands. Currently supports Vector Addition, Vector Subtraction, and Vector Reduction.
* **Pipelined Datapath:** Implements a streamlined Execute (EX) and Write-Back (WB) pipeline to maintain high throughput across all active vector lanes.
* **Idealized Memory Model:** Utilizes a 0-delay memory model (as per academic scoping). This intentional simplification removes memory hierarchy bottlenecks, allowing the design to be evaluated strictly on its parallel compute efficiency and datapath utilization.

## 📂 Core Module Breakdown

* `simd_accerlator_top_level.sv` - The main module that instantiates the parametrizable ALU array and pipeline registers.
* `control.sv` - The FSM orchestrator handling vector operations, lane masking, and memory address generation for the lanes.
* `alu.sv` - The individual compute units instantiated across the vector lanes.
* `tb_simd.sv` - A comprehensive SystemVerilog testbench validating vector operations across arrays of data.

## ⚙️ How to Run / Simulate

The RTL was compiled and verified using **Siemens ModelSim**. To run the full vector testbench:

1. Launch ModelSim and create a new project in the cloned directory.
2. Add all the `.sv` source files (`simd_accerlator_top_level.sv`, `control.sv`, `alu.sv`) and the testbench (`tb_simd.sv`).
3. Compile all files.
4. Load the `tb_simd` module for simulation.
5. Add the relevant datapath signals to the wave window and run the simulation. The ModelSim transcript will automatically output the results of the vector operations and array memory contents.
