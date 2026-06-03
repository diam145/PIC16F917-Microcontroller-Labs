# PIC16F917 Microcontroller Labs: Assembly-Language Embedded Systems

## 📌 Repository Overview
This repository contains a collection of professional, bare-metal embedded systems applications written entirely in Assembly for the Microchip **PIC16F917** 8-bit microcontroller. These projects demonstrate a deep understanding of low-level hardware interaction, deterministic timing, peripheral configuration (ADC, PWM, Timers), and state machine architecture.

The projects progress from foundational logic execution to complex hardware-in-the-loop control systems, showcasing skills in memory management, hardware debouncing, analog-to-digital conversions, and high-resolution signal generation using 8-bit registers.

---

## 🛠️ Technical Stack & Skills Demonstrated
* **Language:** PIC Assembly (ASM)
* **Hardware Target:** Microchip PIC16F917 (8-bit)
* **Build System/Tools:** MPLAB X IDE, XC8 Toolchain, Make
* **Core Concepts:**
    * State-Machine (FSM) Design
    * Hardware Debouncing & Timer-based Delays
    * Interrupts & Asynchronous Polling
    * ADC (Analog-to-Digital) Multiplexing
    * PWM (Pulse-Width Modulation) Generation & Duty Cycle Math
    * Register Alignment & Bitwise Manipulation (10-bit data on 8-bit architecture)

---

## Lab 1: Automated Water Level Controller (FSM)
An industrial state-machine that monitors fluid high/low thresholds via physical inputs and automatically toggles an actuator subsystem (fluid pump) while filtering structural contact bounce in hardware switches.

### System State Hysteresis
| Fluid Level Condition | SensorLow (LED1) | SensorHigh (LED2) | Pump Command Status (LED7) |
| :--- | :---: | :---: | :---: |
| **Below Low Threshold** | `OFF (0)` | `OFF (0)` | **ON (1)** (Refilling Tank) |
| **Within Working Limits** | `ON (1)` | `OFF (0)` | *Maintains Previous State* |
| **Above High Threshold**| `ON (1)` | `ON (1)` | **OFF (0)** (Prevent Overflow) |

### Hardware Debouncing & Timing Math
To prevent mechanical switch contact bouncing, a dual-stage confirmation debounce logic was implemented using **Timer0**. With an internal clock ($F_{osc}$) of 8 MHz, the delay is calculated as:

$$\text{Time-Delay} = \text{Timer0}_{\text{MaxCount}} \times \text{Prescaler} \times \left( \frac{1}{\frac{F_{osc}}{4}} \right)$$

$$\text{Time-Delay} = 256 \times 128 \times \left( \frac{1}{2,000,000\text{ Hz}} \right) = 16.384\text{ ms}$$

This guarantees that the controller waits a solid 16.4 ms before unlocking and looking for the next system event, avoiding transient state capture.

---

## Lab 2: Periodic Square Signal Generator
A hardware-timed Square Signal Generator using the internal **Timer0** peripheral. It produces a steady digital waveform with an exact target total period of 320 ms (composed of symmetrical 160 ms ON/OFF windows).

### Calibration & Timing Derivation
Throttling the oscillator to 125 kHz enables long timing delays directly inside an 8-bit register. The instruction cycle execution rate ($F_{cy}$) evaluates to:

$$F_{cy} = \frac{125,000\text{ Hz}}{4} = 31,250\text{ Hz}$$

$$\text{Instruction Cycle Time } (T_{cy}) = \frac{1}{31,250\text{ Hz}} = 32\ \mu\text{s}$$

A **1:32 Prescaler** is utilized to yield an accurate 1.024 ms tick resolution. 
* **Required Counts Calculation:** 160 ms / 1.024 ms = 156 counts.
* **Timer0 Preload:** 256 - 156 = 100 (0x64).

Physical oscilloscope verification confirmed an actual output of 320.10 ms, displaying extremely low systematic drift due to precise instructions overhead management.

---

## Lab 3: Real-Time Dual-Channel DAQ (ADC)
A multi-channel Data Acquisition System (DAQ) utilizing the internal 10-bit ADC. It asynchronously polls voltage outputs from two separate source potentiometers, visualizing the top 4 bits on physical diagnostic data indicators and shifting active channels exactly every 1.0 second.

### Timing and Peripheral Architecture
To execute a 1.0-second delay loop without blocking high-speed ADC polling cycles, the oscillator is set to 31 kHz (ultra-low power). Using a 1:32 prescaler gives a 4.129 ms Timer0 tick rate. Seeding the timer with a preload of 14 yields exactly 242 ticks, translating to a 999.21 ms window.

**Left-Justification (`ADCON1 = B'01010000'`)** is a critical architectural choice. It forces the 8 highest bits into `ADRESH`. Since only the top 4 MSBs are needed for LED visualization, left-justification allows direct extraction from `ADRESH` in a single command cycle without execution-heavy mathematical bit-shifting or mask operations.

---

## Lab 4: Closed-Loop Analog Signal Generation (PWM)
A high-performance 10-bit DAC Emulator leveraging hardware PWM engines and ADC modules. It continuously measures analog feedback from a precision potentiometer and dynamically updates a matched duty-cycle square wave on RD2. When passed through a physical Low-Pass Filter, it yields a smooth analog DC tracking voltage capable of driving a brushed DC motor across 1,024 discrete velocity points.

### PWM Frequency Calculation
Driven by an 8 MHz clock, Timer2 is maximized (`PR2 = 255`) to unlock the absolute maximum 10-bit resolution available:

$$T_{\text{pwm}} = [255 + 1] \times 4 \times \left(\frac{1}{8,000,000\text{ Hz}}\right) \times 1 = 128\ \mu\text{s}$$

$$F_{\text{pwm}} = \frac{1}{128\ \mu\text{s}} = 7.8125\text{ kHz}$$

### Data Realignment Architecture & Software Clamping
To map the 10-bit ADC output to the PWM registers without expensive 16-bit math transformations, Left-Justified mode is utilized:
1.  The high byte (`ADRESH`) maps directly into `CCPR2L`.
2.  The remaining 2 bits in `ADRESL` are logically shifted (`RRF`) into positions `<5:4>` of `CCP2CON` within a single execution pass.

A **"Hard Stop" Software Clamp** branch evaluates the high bits for a zero state. If the input is < 0.05 V, it bypasses the alignment math and forces an absolute zero state on the duty registers. This actively suppresses high-frequency ripple from ground noise and prevents the motor drivers from emitting an audible whine.