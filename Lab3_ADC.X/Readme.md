# Lab 3: Real-Time Dual-Channel Data Acquisition System (ADC)

## 📌 Project Overview
This project implements a multi-channel **Data Acquisition System (DAQ)** utilizing the internal 10-bit Successive Approximation Analog-to-Digital Converter (**ADC**) module built into the **PIC16F917** microcontroller. 

The application uses an asynchronous polling architecture to sample voltage outputs from two separate source potentiometers (`POT1` and `POT2`) sequentially. The system visualizes the 4 Most Significant Bits (MSBs) of the conversion output across physical diagnostic data indicators (`RD4`-`RD7`) and shifts active tracking channels precisely every **1.0 second**.

---

## 🔬 Mathematical Calibration & Timing Derivation
To execute a long 1.0-second delay loop without blocking high-speed ADC polling cycles, the internal oscillator core clock ($F_{osc}$) is configured to an ultra-low power consumption frequency of **31 kHz**.

The microcontroller establishes its inner instruction execution cycle speed ($F_{cy}$) as:

$$F_{cy} = \frac{F_{osc}}{4} = \frac{31,000\text{ Hz}}{4} = 7,750\text{ Hz}$$

$$\text{Instruction Window Time } (T_{cy}) = \frac{1}{7,750\text{ Hz}} \approx 129.032\ \mu\text{s}$$

By assigning an internal hardware **1:32 Prescaler** multiplier via the `OPTION_REG`, each step tick of the Timer0 counting register matches an exact time delta:

$$\text{Timer0 Tick Rate} = 129.032\ \mu\text{s} \times 32 = 4.129\text{ ms}$$

### 🎛️ Exact Preload Value Calibration
To build a precise 1-second ($1,000\text{ ms}$) streaming window before triggering a channel multiplexer swap, the required hardware count ticks are derived as follows:

$$\text{Required Counts Value} = \frac{\text{Target Delay}}{\text{Timer0 Tick Rate}} = \frac{1,000\text{ ms}}{4.129\text{ ms}} = 242.18 \rightarrow \mathbf{242\text{ ticks}}$$

$$\text{Timer0 Preload Setting} = 256 - 242 = \mathbf{14 \ (0x0E)}$$

By seeding `TMR0` with `D'14'`, the flag trips after exactly $242 \times 4.129\text{ ms} = \mathbf{999.21\text{ ms}}$ ($\approx 1.0\text{ second}$), optimizing accuracy while permitting millions of ADC samples to be recorded during each active window.

---

## 🔀 Peripheral Architecture & Justification
The project relies on **Left-Justification** (`ADCON1 = B'01010000'`) for the ADC module settings. 



Because a 10-bit conversion spans two separate 8-bit registers, left-justifying forces the **8 highest bits** to fill the `ADRESH` register completely, leaving only the remaining 2 minor bits tucked in `ADRESL`. Since the lab requirements focus strictly on monitoring the top 4 MSBs to output data to the indicators, left-justification allows your program to safely extract those bits directly out of `ADRESH` in a single command cycle without execution-heavy mathematical bit-shifting or mask operations.

---

## 🔌 Hardware Mapping Layout
* **Microcontroller Core:** PIC16F917
* **Clock Configuration:** 31 kHz Ultra-Low-Power Internal RC Mode (`OSCCON = 0x00`)
* **Analog Input Channel 0 (AN0):** Potentiometer 1 Terminal (`POT1` ➔ `RA0`)
* **Analog Input Channel 1 (AN1):** Potentiometer 2 Terminal (`POT2` ➔ `RA1`)
* **Data Output indicator Bus:** Port D Bits 4 to 7 (`RD4`, `RD5`, `RD6`, `RD7`)
* **Multiplexer Status Indicator:** Pin `RB0` (LED ON = `AN0` Active | LED OFF = `AN1` Active)