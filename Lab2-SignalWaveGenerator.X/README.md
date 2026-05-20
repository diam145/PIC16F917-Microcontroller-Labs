# Lab 2: Periodic Square Signal Generator

## 📌 Project Overview
This project implements a hardware-timed **Square Signal Generator** using the internal **Timer0** peripheral of the 8-bit **PIC16F917** microcontroller. 

The application runs a high-precision loop that controls output pin **RB0** by cyclically flipping its logical state. It produces a steady digital waveform with an exact target total period of **320 ms** (composed of symmetrical $T = 160\text{ ms}$ ON and OFF time windows).

---

## 🔬 Mathematical Calibration & Timing Derivation
The internal oscillator configuration block (`OSCCON`) is throttled down to a stable low-power frequency ($F_{osc}$) of **125 kHz** to facilitate a long timing delay directly inside an 8-bit register hardware structure. 

The core system processor divides this clock frequency by 4 to establish the hardware instruction execution rate ($F_{cy}$):

$$F_{cy} = \frac{F_{osc}}{4} = \frac{125,000\text{ Hz}}{4} = 31,250\text{ Hz}$$

$$\text{Instruction Cycle Time } (T_{cy}) = \frac{1}{31,250\text{ Hz}} = 32\ \mu\text{s}$$

### 🎛️ Prescaler Resolution Comparison Evaluation
To achieve a target half-period delay of $T = 160\text{ ms}$ ($160,000\ \mu\text{s}$), the required Timer0 count offset is derived using the standard counting formula:

$$\text{Required Counts} = \frac{\text{Target Delay } (T)}{T_{cy} \times \text{Prescaler}}$$

$$\text{Timer0 Preload Value} = 256 - \text{Required Counts}$$

#### Option 1: 1:32 Prescaler (Selected / Highly Accurate)
* **Tick Resolution:** $32\ \mu\text{s} \times 32 = 1.024\text{ ms}$ per count tick.
* **Required Counts Calculation:** $\frac{160\text{ ms}}{1.024\text{ ms}} = 156.25 \rightarrow \mathbf{156 \text{ counts}}$.
* **Timer0 Preload:** $256 - 156 = \mathbf{100 \ (0x64)}$.
* **Timing Precision:** Each step counts in precise increments of $1.024\text{ ms}$, resulting in a tight, accurate resolution.

#### Option 2: 1:64 Prescaler (Alternate / Coarse Option)
* **Tick Resolution:** $32\ \mu\text{s} \times 64 = 2.048\text{ ms}$ per count tick.
* **Required Counts Calculation:** $\frac{160\text{ ms}}{2.048\text{ ms}} = 78.125 \rightarrow \mathbf{78 \text{ counts}}$.
* **Timer0 Preload:** $256 - 78 = \mathbf{108 \ (0xAC)}$.
* **Timing Precision:** Coarser quantization increments ($2.048\text{ ms}$ steps), making it less precise when attempting to compensate for program instruction overhead.

---

## 📈 Real-World Oscilloscope Verification
When compiled and deployed to the Mechatronics board, the physical outputs monitored via an oscilloscope reveal the following operating metrics:

* **Target Symmetrical Period ($2T$):** 320.00 ms
* **Observed Metrics (1:32 Prescaler):** **320.10 ms** (Low systematic drift due to precise instructions overhead management)
* **Observed Metrics (1:64 Prescaler):** **320.22 ms** (Coarser step discretization introduces larger rounding errors)

---

## 🔌 Hardware Mapping Layout
* **Microcontroller Target Core:** PIC16F917
* **Clock Configuration:** 125 kHz Low-Power Internal RC Oscillator Mode (`OSCCON = 0x10`)
* **Target Waveform Output Pin:** Port B Data Register Latch, Pin 0 (`RB0`)