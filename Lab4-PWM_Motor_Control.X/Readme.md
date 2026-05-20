# Lab 4: Closed-Loop Analog Signal Generation via High-Resolution PWM

## 📌 Project Overview
This project implements a high-performance **10-bit Digital-to-Analog Converter (DAC) Emulator** leveraging the hardware **PWM** engines and **ADC** modules built into the **PIC16F917** microcontroller.

The architecture loops indefinitely, measuring analog feedback profiles from a precision potentiometer (`POT1`) and dynamically updating a matched duty-cycle square wave generated on output pin **RD2**. When this digital output passes through the board's physical **Low-Pass Filter**, it smooths into a steady analog DC tracking voltage capable of driving a brushed DC motor across 1,024 discrete velocity points.

---

## 🔬 Mathematical Calibration & Register Derivations
The system utilizes a balanced oscillator baseline frequency ($F_{\text{osc}}$) configured at **8 MHz** to generate high-speed digital switching pulses.

### ⚡ PWM Frequency Calculation
The hardware timing path uses **Timer2** to benchmark the base output frequency. To unlock the absolute maximum **10-bit resolution** step density available on the silicon, the period register `PR2` is pushed to its largest constraint limit of **255 (`0xFF`)**.

$$\text{PWM Period } (T_{\text{pwm}}) = [(\text{PR2}) + 1] \times 4 \times T_{\text{osc}} \times \text{Timer2 Prescaler}$$

$$\text{Given: } \text{PR2} = 255, \ T_{\text{osc}} = \frac{1}{8,000,000\text{ Hz}}, \ \text{Prescaler} = 1$$

$$T_{\text{pwm}} = [255 + 1] \times 4 \times \left(\frac{1}{8,000,000\text{ Hz}}\right) \times 1 = \mathbf{128\ \mu\text{s}}$$

$$\text{PWM Base Frequency } (F_{\text{pwm}}) = \frac{1}{128\ \mu\text{s}} = \mathbf{7.8125\text{ kHz}}$$

---

## 🧠 Data Realignment Architecture (Register Splitting)
A major design challenge when working with low-cost 8-bit controllers is processing 10-bit numerical structures. Because individual hardware registers are only 8 bits wide, the data must be serialized across multiple memory addresses.

To simplify this mapping, the ADC is set to **Left-Justified** mode (`ADCON1 = B'01010000'`).

### 🔀 Left-Justified 10-Bit Register Interfacing Layout

```text
ADRESH Register:
+---+---+---+---+---+---+---+---+
|b9 |b8 |b7 |b6 |b5 |b4 |b3 |b2 |  <-- Captured 8 Most Significant Bits
+---+---+---+---+---+---+---+---+
  |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+----> Maps Directly into CCPR2L Register

ADRESL Register:
+---+---+-------+---+---+---+---+
|b1 |b0 | Unused|...|...|...|...|  <-- Remaining 2 Fractional Bits
+---+---+-------+---+---+---+---+
  |   |
  v   v   (Requires two logical right shifts via RRF)
+---+---+---+---+---+---+---+---+
| 0 | 0 |b1 |b0 | 0 | 0 | 0 | 0 |  <-- Injected cleanly into CCP2CON<5:4>
+---+---+---+---+---+---+---+---+
```

By maintaining this alignment, the system avoids math-heavy 16-bit variable transformations. It copies the high byte directly to `CCPR2L` and uses two high-speed right-shift operations (`RRF`) to tuck the lower bits safely into positions `<5:4>` of `CCP2CON` inside a single execution pipeline pass.

---

## 🛑 Software Clamping ("Hard Stop" Guard)
At extremely low potentiometer voltage inputs ($<0.05\text{ V}$), electrical ground noise can cause the duty cycle to rapidly fluctuate between 0% and 0.4%. This introduces high-frequency ripple that causes the motor drivers to emit an audible, high-pitched whine. 

To prevent this, a zero-point checking branch (`BTFSS STATUS, Z`) screens the data stream. If the 8 highest bits inside `ADRESH` evaluate to zero, the script enters a protective clamp that forces the duty registers to an absolute zero state and bypasses the alignment math, keeping the system silent and stable.

---

## 🔌 Hardware Mapping Layout
* **Processing Silicon Target:** PIC16F917 Microcontroller
* **Clock Matrix Speed:** 8 MHz Symmetrical Core Block RC Oscillator (`OSCCON = 0x71`)
* **Analog Feedback Interface:** Variable Resistor Potentiometer terminal (`POT1` ➔ `RA0 / AN0 Input`)
* **Synthesized Digital Output:** Capture/Compare/PWM Peripheral module 2 Line (`CCP2` ➔ `RD2 Output`)
* **Analog Drive Target:** Low-Pass Filter network mapped to an H-Bridge Brushed DC Motor Controller Driver