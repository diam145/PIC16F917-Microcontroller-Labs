# Lab 1: Automated Water Level Controller (FSM)

## 📌 Project Overview
This repository contains a professional assembly-language implementation of a automated **Water Level Hysteresis Controller** designed for the Microchip **PIC16F917** microcontroller. 

The application implements an industrial state-machine that monitors fluid high/low thresholds via physical inputs and automatically toggles an actuator subsystem (a fluid pump) according to structural tank level criteria while fully filtering structural contact bounce in hardware switches.

---

## ⚙️ Control System Specification & Logic
The controller maintains fluid storage between a **LOW** and a **HIGH** threshold limit utilizing liquid state feedback sensors to prevent system over-cycling or dry-running.

### 📊 System State Hysteresis Table
| Fluid Level Condition | SensorLow (LED1) | SensorHigh (LED2) | Pump Command Status (LED7) |
| :--- | :---: | :---: | :---: |
| **Below Low Threshold** | `OFF (0)` | `OFF (0)` | **ON (1)** (Refilling Tank) |
| **Within Working Limits** | `ON (1)` | `OFF (0)` | *Maintains Previous State* |
| **Above High Threshold**| `ON (1)` | `ON (1)` | **OFF (0)** (Prevent Overflow) |

---

## 🧠 Hardware Debouncing & Timing Math
Mechanical switches generate transient electrical noise (contact bouncing) when pressed or released, which can be misread as high-speed input pulses. To prevent this, a dual-stage confirmation debounce logic was implemented using **Timer0**.

### 🔢 Timing Derivation Formula
The system runs on an internal clock frequency ($F_{osc}$) configured at **8 MHz**. The instruction cycle frequency execution rate equals $F_{osc}/4$.

$$\text{Time-Delay} = \text{Timer0}_{\text{MaxCount}} \times \text{Prescaler} \times \left( \frac{1}{\frac{F_{osc}}{4}} \right)$$

Plugging our specific system values into the execution formula:

$$\text{Time-Delay} = 256 \times 128 \times \left( \frac{1}{2,000,000\text{ Hz}} \right) = \mathbf{16.384\text{ ms}}$$

This configuration guarantees that the button state must remain solid and completely unpressed for a minimum of **16.4 ms** before the controller safely unlocks and looks for the next system event, avoiding transient state capture.

---

## 🔌 Hardware Mapping Layout
* **Clock System:** 8 MHz Internal RC Oscillator Block (`OSCCON = 0x70`)
* **Input 1 (SensorLow Toggle):** Tactile Push-Button Switch 2 (`SW2` ➔ `RA2`)
* **Input 2 (SensorHigh Toggle):** Tactile Push-Button Switch 3 (`SW3` ➔ `RA3`)
* **Output 1 (Low Boundary LED):** Diagnostic Pin Output Indicator (`LED1` ➔ `RD5`)
* **Output 2 (High Boundary LED):** Diagnostic Pin Output Indicator (`LED2` ➔ `RD6`)
* **Actuator Output (Pump Driver):** Motor Contactor Relay Actuation Line (`LED7` ➔ `RD7`)