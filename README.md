# Digital IIR Filter Design
**Course:** Digital Circuits – ECE311 | Ain Shams University, Faculty of Engineering  
**Department:** Electronics & Communication Engineering  
**Semester:** Fall 2025  
**Tools:** Cadence Virtuoso · ModelSim · VS Code  
**Technology:** 130 nm CMOS

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Filter Equation](#filter-equation)
3. [Repository Structure](#repository-structure)
4. [Design Hierarchy](#design-hierarchy)
   - [Gates](#1-gates)
   - [Adders](#2-adders)
   - [Flip-Flops](#3-flip-flops)
   - [Multipliers](#4-multipliers)
   - [Top-Level Schematic](#5-top-level-schematic)
   - [Sleep Circuit](#6-sleep-circuit)
5. [HDL Model](#hdl-model)
6. [Test Cases](#test-cases)
7. [Performance Summary](#performance-summary)
8. [Layout](#layout)
9. [How to Run](#how-to-run)
10. [Team](#team)

---

## Project Overview

A first-order recursive digital IIR (Infinite Impulse Response) filter implemented entirely at the **transistor level** in 130 nm CMOS using Cadence Virtuoso. Every block — from primitive logic gates up to signed multipliers and clocked registers — was designed, simulated, and verified from scratch. A Verilog RTL model and testbench in ModelSim served as the golden reference throughout.

---

## Filter Equation

$$y[n] = b_0 \cdot x[n] + b_1 \cdot x[n-1] + a_1 \cdot y[n-1]$$

| Signal | Width | Description |
|--------|-------|-------------|
| `x[n]` | 4-bit signed | Current input |
| `x[n-1]` | 4-bit signed | Previous input (stored in 4-bit FF) |
| `y[n-1]` | 8-bit signed | Previous output (stored in 8-bit FF) |
| `y[n]` | 8-bit signed | Current output |
| `b0, b1, a1` | 4-bit signed | Programmable coefficients |

---

## Repository Structure

```
Digital-IIR-filter/
│
├── schematics/               # Cadence Virtuoso schematic views
│   ├── gates/                # nand, and, nor, xor, inv, buffer
│   ├── adders/               # half_adder, full_adder, 8bit_adder
│   ├── flip_flops/           # ff, 4bit_ff, 8bit_ff
│   ├── multipliers/          # 4x4_multiplier, 8x4_multiplier
│   ├── sleep_circuit/
│   └── iir_filter_top/
│
├── hdl/
│   ├── iir_filter.v          # RTL Verilog model
│   └── iir_filter_tb.v       # Testbench (8 test cases)
│
├── simulations/
│   ├── transient/            # Cadence ADE transient waveforms
│   ├── delay/                # Gate & block delay measurements
│   └── modelsim/             # ModelSim RTL simulation screenshots
│
├── layout/
│   ├── nand_layout.png
│   ├── xor_layout.png
│   └── full_adder_layout.png
│
└── README.md
```

---

## Design Hierarchy

### 1. Gates

All logic gates were built from scratch in 130 nm CMOS.

| Gate | Logic Family | Key Design Choice |
|------|-------------|-------------------|
| NAND | CMOS | L = 130 nm, W = 4 µm; rail-to-rail output |
| AND | CMOS | NAND + inverter |
| NOR | CMOS | Near-zero static power; inverting logic saves transistors |
| XOR | CMOS + PTL | Hybrid: CMOS inverters + Transmission Gate core; reduces transistor count, full swing, lower propagation delay |
| Inverter | CMOS | W_P = 4 µm, W_N = 4 µm |
| Buffer | CMOS | Two cascaded inverters; added to FF output to eliminate glitches |

**Measured gate delays:**

| Gate | Delay |
|------|-------|
| Inverter | 8.683 ps |
| NAND | 12.66 ps |
| AND | 25.97 ps |
| Buffer | 22.49 ps |
| XOR | 24.3 ps |

---

### 2. Adders

#### Half Adder
- **Sum** = A ⊕ B (XOR gate)  
- **Carry** = A · B (AND gate)  
- Carry delay: 29.28 ps | Sum delay: 26.63 ps

#### Full Adder
- **Sum** = A ⊕ B ⊕ Cin  
- **Cout** = NAND(NAND(A,B), NAND(Cin, A⊕B))  
- NAND-based carry minimises transistor count vs. OR-gate implementation

#### 8-bit Ripple-Carry Adder
- Eight full adders cascaded; carry ripples from LSB to MSB  
- Simple but speed-limited: each stage waits for the previous carry  
- **Total delay:** 118.4 ps (absolute value)  
- *Note: A carry look-ahead adder would reduce delay at the cost of area*

---

### 3. Flip-Flops

**Type:** Transmission-Gate (TG) Master–Slave D Flip-Flop

**Operation:** Two level-sensitive latches in series controlled by complementary clocks (CKI / CKN). Master is transparent when CLK is low; slave transfers to Q when CLK goes high — giving true edge-triggered behaviour.

**Modifications made for IIR use:**

| Modification | Why |
|---|---|
| Active-low async reset (NAND gates replace inverters 3 & 4) | Clears all state on startup to prevent garbage propagation |
| Output buffer stage | Eliminates glitches at latch transitions |
| 4-bit FF block | Stores x[n-1] (4-bit input delay) |
| 8-bit FF block | Stores y[n-1] (8-bit output feedback) |
| Delayed clock on x[n] FF (300 ps) | Prevents x[n] racing through to x[n-1] in the same cycle; implemented as negative clock skew |

---

### 4. Multipliers

#### Signed 4×4 Multiplier (Baugh-Wooley)
Multiplies two 4-bit 2's complement numbers → 8-bit signed result.

| Component | Quantity | Purpose |
|-----------|----------|---------|
| AND gates | 10 | Standard partial products (i,j < 3) and sign crossing (A3·B3) |
| NAND gates | 6 | Inverted partial products (row/column containing sign bits) |
| Full adders | 12 | Partial product accumulation |
| Half adders | 4 | Initial row reduction and MSB (P7) |

Correction constants: logic '1' injected at weights 2⁴ and 2⁷.  
**Critical path delay: 237.8 ps** (carry propagation dominated)

#### Signed 8×4 Multiplier (Baugh-Wooley + Carry-Save Array)
Multiplies 8-bit multiplicand × 4-bit multiplier → 12-bit result (4 LSBs truncated → 8-bit input to adder).

| Component | Quantity |
|-----------|----------|
| AND gates | 22 |
| NAND gates | 10 |
| Full adders | 21 |
| Half adders | 7 |

Two-stage CSA structure: Stage 1 processes A0/A1 rows; Stage 2 integrates A2/A3 rows with carry interweaving.  
Correction constants: logic '1' at 2⁸ (P8 half-adder) and 2¹¹ (sign bit P11).  
**Critical path delay: 832.5 ps**

---

### 5. Top-Level Schematic

```
x[n] ──► [4-bit FF (delayed clk)] ──► x[n-1]
   │                                       │
   ▼                                       ▼
[4×4 Mult: b0·x[n]]            [4×4 Mult: b1·x[n-1]]
         │                                 │
         └──────────► [8-bit Adder] ◄──────┘
                             │
                     [8×4 Mult: a1·y[n-1]] ◄── [8-bit FF] ◄── y[n]
                             │
                             ▼
                           y[n]  (8-bit signed output)
```

---

### 6. Sleep Circuit

Reduces dynamic power by gating the clock when no activity is detected.

**Mechanism:**
1. XOR each bit of current vs. previous input (x[n] vs. x[n-1]) and output (y[n] vs. y[n-1])
2. OR all XOR outputs → activity-detection signal
3. Pass through a FF (clocked, to prevent glitches on the AND gate) → gate the main clock

**Clock is disabled** when input and output are both unchanged between cycles.  
**Limitation:** Does not help in continuously toggling (overflow) or alternating-input scenarios — a pattern detection circuit would be needed for those cases.

---

## HDL Model

Located in `hdl/iir_filter.v`. Implements the same difference equation as the transistor-level design. Used as the golden reference during verification.

Key implementation detail: `a1` is sign-extended to 8 bits, multiplied by `y_d1` (16-bit product), then **truncated at bits [11:4]** to produce the 8-bit scaled feedback term.

To simulate in ModelSim:
```tcl
vlog hdl/iir_filter.v hdl/iir_filter_tb.v
vsim iir_filter_tb
run -all
```

---

## Test Cases

| # | Test | Coefficients | Input | Expected Steady-State Output |
|---|------|-------------|-------|------------------------------|
| 1 | Low-Pass Filter | b0=3, b1=0, a1=4 | Step 0→5 | 19 (gradual rise) |
| 2 | High-Pass Filter | b0=2, b1=−2, a1=−4 | Step 0→5 | 0 (transient then decay) |
| 3 | Impulse Response | b0=3, b1=3, a1=7 | Pulse 0→5→0 | 0 (decaying, filter stable) |
| 4 | Smoothing Rapid Changes | b0=1, b1=1, a1=4 | Alternating 2↔6 | 10 (variations averaged out) |
| 5 | Positive Overflow | b0=7, b1=7, a1=6 | Step 0→7 | Oscillates (unstable, 2's complement wrap) |
| 6 | Negative Overflow | b0=7, b1=7, a1=6 | Step 0→−7 | Oscillates (negative wrap-around) |
| 7 | Zero Output | b0=1, b1=1, a1=1 | x=0 always | 0 (no bias or leakage) |
| 8 | DC Input | b0=1, b1=0, a1=−1 | x=2 (constant) | 1 (DC gain = (b0+b1)/(1−a1)) |

> **Note:** Settling time in Cadence transient simulation may differ from ModelSim due to RTL abstraction vs. physical propagation delays.

---

## Performance Summary

| Metric | Value |
|--------|-------|
| Technology | 130 nm CMOS |
| Supply Voltage (Vdd) | 1.2 V |
| Maximum Operating Frequency | **450 MHz** |
| Dynamic Power @ 450 MHz | 2.592 mW |
| Dynamic Power @ 10 MHz (normal operation) | **57.6 µW** |
| 4×4 Multiplier Critical Path | 237.8 ps |
| 8×4 Multiplier Critical Path | 832.5 ps |
| 8-bit Adder Delay | 118.4 ps |

> Maximum frequency determined by the point at which Y0 fails to fully discharge within a clock period.

---

## Layout

Implemented for: **NAND gate**, **XOR gate**, and **Full Adder**.

Design rules followed:
- PMOS placed near VDD rail; NMOS near GND
- Inputs routed centrally for access from both transistor stacks
- Gates arranged to match gate-level schematic topology
- Multiple metal layers used to avoid routing congestion
- Minimal wire length between gate outputs and downstream inputs

---

## How to Run

### Cadence Virtuoso (Transistor-Level)
1. Open Cadence Virtuoso and load the library
2. Navigate to `iir_filter_top` → open schematic view
3. Launch ADE L/XL → set up transient simulation (stop time ≥ 1 µs, step ≤ 1 ps)
4. Set coefficient inputs (b0, b1, a1) and input signal (x) as voltage sources
5. Apply reset pulse at startup (active-low, release after 2 clock cycles)
6. Run and probe output bits y[7:0]

### ModelSim (RTL Verification)
```bash
cd hdl/
vlog iir_filter.v iir_filter_tb.v
vsim -c iir_filter_tb -do "run -all; quit"
```

 2300704 |
| Farida Ahmed Mahmoud | 2300363 |
