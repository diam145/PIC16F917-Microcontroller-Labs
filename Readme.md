# PIC16F917 Microcontroller Labs

A collection of bare-metal Assembly-language embedded systems labs for the **Microchip PIC16F917** 8-bit microcontroller. Built for the ELG4159 — Microprocessors and Microcontrollers course at the University of Ottawa.

---

## Overview

These labs progress from foundational digital logic to complex hardware-in-the-loop control systems, all written in PIC Assembly. Each lab targets a specific embedded concept: FSM design, signal generation, analog data acquisition, and closed-loop PWM motor control.

---

## Labs

### Lab 1 — Automated Water Level Controller (FSM)
- Implements a Finite State Machine to control water level based on sensor input
- Dual-stage debouncing using Timer0 for reliable button detection
- LED indicators show current state transitions

### Lab 2 — Periodic Square Signal Generator
- Generates a configurable periodic square wave using **Timer0**
- Hardware-verified timing with an oscilloscope
- Demonstrates interrupt-driven signal output

### Lab 3 — Real-Time Dual-Channel DAQ (ADC)
- Real-time dual-channel Data Acquisition System
- Uses the 10-bit ADC with Left-Justification (`ADCON1 = B'01010000'`) for efficient bit extraction
- Multiplexes two analog input channels

### Lab 4 — Closed-Loop Analog Signal Generation (PWM)
- Hardware-in-the-loop DC motor velocity control
- Uses **Timer2** and **CCP modules** to generate PWM output
- Closed-loop feedback from analog sensor adjusts duty cycle dynamically

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | PIC Assembly (ASM) |
| Microcontroller | Microchip PIC16F917 (8-bit) |
| IDE | MPLAB X IDE |
| Toolchain | XC8 |
| Build | Make |
| Verification | Oscilloscope + diagnostic LEDs |

---

## Hardware Details

| Feature | Implementation |
|---|---|
| Debouncing | Dual-stage confirmation using Timer0 |
| ADC | 10-bit, left-justified, two-channel multiplexed |
| PWM | Timer2 + CCP module for duty cycle control |
| Timing | Timer0-based software delays and interrupts |

---

## Project Structure

```
PIC16F917-Microcontroller-Labs/
├── LAB1_WaterLevelController/   # FSM water level control
├── Lab2_SignalWaveGenerator/    # Timer0 square wave generation
├── Lab3_ADC/                    # Dual-channel ADC data acquisition
└── Lab4_PWM_Motor_Control/      # Closed-loop PWM motor control
```

Each folder contains:
- `.asm` source file(s)
- MPLAB X project files
- Lab report / documentation

---

## Getting Started

### Prerequisites

- [MPLAB X IDE](https://www.microchip.com/mplab/mplab-x-ide) (v5.0+)
- [XC8 Compiler](https://www.microchip.com/mplab/compilers) (v2.0+)
- A **PIC16F917** development board or compatible PICkit programmer
- Optional: oscilloscope for signal verification

### Build and Flash

1. Clone the repository:

```bash
git clone https://github.com/diam145/PIC16F917-Microcontroller-Labs.git
```

2. Open the desired lab folder in **MPLAB X IDE**.
3. Select your PICkit programmer in Project Properties.
4. Build the project: `Production → Build Main Project`.
5. Flash to the PIC16F917: `Production → Make and Program Device`.

---

## Course Context

These labs were completed for **ELG4159 — Microprocessors and Microcontrollers** at the **University of Ottawa**. They cover PIC assembly programming, FSM design, timer and interrupt configuration, ADC interfacing, and PWM generation for embedded control.

---

## Author

**[@diam145](https://github.com/diam145)**

---

## License

This project does not currently have a license. All rights reserved by the author.
