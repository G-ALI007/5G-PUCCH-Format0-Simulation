# 5G NR PUCCH Format 0 - ACK Missed Detection Simulation

This repository contains a MATLAB implementation for simulating the **Physical Uplink Control Channel (PUCCH) Format 0** in 5G New Radio (NR). The simulation specifically focuses on analyzing the **ACK Missed Detection Probability**.

## Project Structure
* `ACK_missed_F0.m`: The main execution script that sets up simulation parameters and runs the SNR loop.
* `mynrPUCCH0.m`: Custom function for PUCCH Format 0 waveform generation.
* `mynrPUCCHDecode.m`: Custom decoder that implements detection logic based on a specific threshold.

## Simulation Parameters
- **Carrier Configuration:** 15 kHz Subcarrier Spacing, 25 PRBs.
- **Channel Model:** TDL-C with 100 Hz maximum Doppler shift.
- **Antenna Configuration:** 1x2 (SISO-SIMO).
- **Detection Threshold:** 0.55 (Adjustable in the main script).

## How to Use
1. Clone the repository or download all `.m` files.
2. Ensure you have the **MATLAB 5G Toolbox** installed.
3. Run the script `ACK_missed_F0.m`.
4. The simulation will output a semi-logarithmic plot showing the probability of missed detection vs. SNR.
