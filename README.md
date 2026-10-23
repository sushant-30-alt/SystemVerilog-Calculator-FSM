# 4-Bit SystemVerilog Calculator Using FSM

A modular digital design project integrating **custom arithmetic RTL libraries, SystemVerilog FSM control, Xilinx Vivado XSim, and a Python GUI**.

The calculator performs addition, subtraction, multiplication, and division. It combines reusable arithmetic modules developed separately, a five-state Finite State Machine (FSM), simulation-based verification, FPGA synthesis analysis, and an interactive GUI for demonstrating the calculator's operation.

## GUI Preview

<img width="1600" height="824" alt="image" src="https://github.com/user-attachments/assets/169b67d3-5e29-44dd-9029-9e6cc8d5a008" />


The GUI provides operand entry, arithmetic operation selection, simulated hardware outputs, FSM visualization, and a Vivado XSim execution monitor.

## Demo Video

Watch the calculator demonstration:

[▶ View the RTL Calculator Demo](reports/fsm_calculator_gui_demo.mp4)

The demonstration video is included in the `reports/` directory.

## Key Features

- Custom arithmetic modules developed in separate RTL practice libraries.
- Hierarchical RTL design and module instantiation.
- Four arithmetic operations using 4-bit unsigned operands.
- Five-state FSM for request control and error handling.
- Division-by-zero detection.
- Two SystemVerilog testbenches for RTL verification and GUI integration.
- Vivado XSim simulation and synthesis analysis.
- Python Tkinter GUI integrated with the RTL simulation.
- FSM transition visualization and simulator output monitoring.

## Repository Structure

```text
SystemVerilog-Calculator-FSM/
│
├── rtl/
│   ├── calculator_top.sv
│   ├── ripple_carry_adder_4bit.v
│   ├── subtractor_4bit.v
│   ├── multiplier_4bit.v
│   └── divider_4bit.v
│
├── tb/
│   ├── calculator_top_tb.sv
│   └── calculator_gui_tb.sv
│
├── python/
│   ├── calculator_bridge.py
│   └── calculator_gui.py
│
├── reports/
│   ├── 4-bit_FSM_calculator_report.docx
│   ├── calculator_top_tb_behav.wcfg
│   └── fsm_calculator_gui_demo.mp4
│
└── README.md
```

## Custom Arithmetic RTL Library

An important part of this project is the integration of **reusable arithmetic modules developed in our own RTL practice libraries**.

Instead of treating the calculator as one large design, the arithmetic functions are implemented in separate modules and integrated into `calculator_top.sv`.

| RTL module | Function |
|---|---|
| `ripple_carry_adder_4bit.v` | 4-bit binary addition |
| `subtractor_4bit.v` | 4-bit binary subtraction |
| `multiplier_4bit.v` | Unsigned 4-bit multiplication |
| `divider_4bit.v` | Division and remainder generation |

The supporting arithmetic libraries also include logic modules such as NAND gates, half adders, and full adders where used by the corresponding module hierarchy.

This approach demonstrates reusable RTL development, hierarchical module instantiation, separation of arithmetic and control logic, and integration of independently developed digital design blocks.

## Supported Operations

| Operation code | Operation | Example |
|---|---|---|
| `00` | Addition | 3 + 5 = 8 |
| `01` | Subtraction | 3 − 5 = −2 |
| `10` | Multiplication | 3 × 4 = 12 |
| `11` | Division | 13 ÷ 4 = 3, remainder 1 |

The operands are unsigned 4-bit values ranging from 0 to 15. The result output is 8 bits wide to accommodate multiplication results and negative subtraction results represented using two's-complement encoding.

Division by zero is detected and reported through the FSM error state.

## FSM Architecture

The calculator uses five states to manage the calculation lifecycle.

| State | Encoding | Function |
|---|---|---|
| `IDLE` | `000` | Waits for a new request |
| `EXECUTE` | `001` | Processes the selected operation |
| `DONE` | `010` | Indicates successful completion |
| `ERROR` | `011` | Indicates division by zero |
| `WAIT_RELEASE` | `100` | Waits for the start signal to be released |

**Successful operation**

```text
IDLE → EXECUTE → DONE → WAIT_RELEASE → IDLE
```

**Division by zero**

```text
IDLE → EXECUTE → ERROR → WAIT_RELEASE → IDLE
```

The `WAIT_RELEASE` state prevents a held start request from repeatedly triggering the same calculation.

## RTL Verification

The design was simulated using Xilinx Vivado XSim with two SystemVerilog testbenches.

### Main RTL Testbench

File: `tb/calculator_top_tb.sv`

This testbench verifies arithmetic operations and FSM control behavior independently of the Python GUI.

The recorded simulation covered arithmetic operations, boundary conditions, division-by-zero detection, held-start behavior, input stability, and recovery after an error.

| Verification metric | Result |
|---|---:|
| Tests passed | 14 |
| Tests failed | 0 |
| Final status | ALL TESTS PASSED |

### GUI-Specific Testbench

File: `tb/calculator_gui_tb.sv`

This testbench receives individual calculation requests from the Python bridge, applies them to `calculator_top`, waits for completion or error, and writes the response and recorded FSM transitions to text files.

The two testbenches serve different purposes: comprehensive RTL verification and interactive GUI integration.

## Vivado Synthesis Results

The synthesized schematic reported the following design summary.

| Metric | Reported value |
|---|---:|
| Cells | 135 |
| I/O ports | 27 |
| Nets | 149 |

### FPGA Resource Utilization

| Resource | Used | Available |
|---|---:|---:|
| Slice LUTs | 59 | 32,600 |
| Slice Registers | 27 | 65,200 |
| F7 Muxes | 12 | 16,300 |
| F8 Muxes | 4 | 8,150 |
| Bonded IOBs | 27 | 210 |
| BUFGCTRL | 1 | 32 |

The design uses 59 Slice LUTs and 27 Slice Registers according to the Vivado synthesis report. These figures indicate modest resource usage relative to the reported capacity of the selected FPGA.

The values represent synthesis results and do not independently establish post-implementation timing closure or successful physical FPGA operation.

## Python GUI and RTL Integration

Python is responsible for the software-side calculation workflow. It validates the inputs, launches the simulation, retrieves and processes the results, and visualizes the recorded FSM sequence.

### Division of Responsibilities

| Component | Responsibility |
|---|---|
| Python Tkinter GUI | User interaction and result presentation |
| Python bridge | Input validation, simulation control, and result processing |
| SystemVerilog RTL | Arithmetic computation and FSM logic |
| Vivado XSim | Executes the RTL simulation |
| GUI-specific testbench | Transfers requests to the RTL and returns outputs |

### Computation Workflow

1. The user enters operands and selects an operation in the GUI.
2. Python validates the inputs and writes the request to `request.txt`.
3. The Python bridge launches the precompiled XSim snapshot.
4. The GUI-specific testbench supplies the request to `calculator_top`.
5. The SystemVerilog arithmetic modules perform the calculation, while the FSM manages execution and status.
6. The testbench writes the result, remainder, `done`, and `error` values to `response.txt`.
7. Python retrieves the response and converts negative subtraction results into signed decimal values.
8. Python reads recorded state codes from `fsm_transitions.txt` and animates the FSM sequence.
9. The GUI displays the result, status, and simulator messages.

Python therefore orchestrates the computation workflow and processes the returned data, while **SystemVerilog performs the arithmetic computation and FSM execution within Vivado XSim**.

The GUI uses a replay of the recorded simulation transitions, not a live hardware trace.

### File-Based Communication

| File | Purpose |
|---|---|
| `request.txt` | Sends operands and operation code to the testbench |
| `response.txt` | Returns results and status flags |
| `fsm_transitions.txt` | Provides recorded FSM state codes for visualization |

## Tools and Technologies

- **HDL:** Verilog and SystemVerilog
- **FPGA design and synthesis:** Xilinx Vivado
- **RTL simulation:** Vivado XSim
- **GUI:** Python Tkinter
- **Process control:** Python `subprocess`
- **File management:** Python `pathlib`
- **FSM visualization:** Tkinter Canvas

## Running the Project

### RTL Simulation

1. Open Xilinx Vivado.
2. Add the required RTL files from `rtl/`.
3. Add `tb/calculator_top_tb.sv` as the simulation testbench.
4. Run behavioral simulation.
5. Inspect the waveform and testbench output.

### Python GUI

1. Install Python and configure Xilinx Vivado.
2. Configure `calculator_bridge.py` with the local Vivado executable and simulation directory.
3. Compile and elaborate `calculator_gui_tb.sv` with all required RTL dependencies to generate the `calculator_gui_snapshot` snapshot.
4. Ensure the bridge and simulation use the expected working directory and file paths.
5. Run `python/calculator_gui.py`.

The GUI bridge requires a compatible precompiled XSim snapshot. Recompile it after relevant RTL or testbench changes.

## Learning Outcomes

This project demonstrates practical experience with:

- Developing reusable arithmetic RTL modules.
- Designing hierarchical digital systems.
- Implementing FSM-based control logic.
- Verifying RTL functionality using SystemVerilog testbenches.
- Analyzing synthesized FPGA resource utilization.
- Integrating Python applications with HDL simulation workflows.

---

**Project focus:** Custom arithmetic RTL, SystemVerilog design, FSM control, functional verification, FPGA synthesis, and Python–RTL integration.
