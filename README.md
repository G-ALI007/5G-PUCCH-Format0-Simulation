# 5G NR PUCCH Format 0 Performance Simulation

This repository provides a comprehensive MATLAB simulation for **5G NR PUCCH Format 0** performance metrics, including ACK detection and DTX behavior.

## Simulations Included
1. **ACK Missed Detection (`ACK_missed_F0.m`):**
   - Measures the probability that a transmitted ACK is not detected or incorrectly decoded.
2. **DTX to ACK Probability (`DTX_to_ACK_F0.m`):**
   - Measures the false alarm rate where noise is incorrectly detected as an ACK signal when nothing was transmitted (Discontinuous Transmission).

## Technical Specifications
* **Waveform:** 5G NR PUCCH Format 0.
* **Channel:** TDL-C fading model (300ns delay spread, 100Hz Doppler).
* **Antennas:** 1 TX antenna and 2 RX antennas.
* **Threshold-based Detection:** Uses a configurable threshold (default: 0.55).

## Helper Functions
The simulations rely on the following custom functions:
* `mynrPUCCH0.m`: For signal generation.
* `mynrPUCCHDecode.m`: For signal detection and UCI decoding.

## How to Run
1. Clone the repository.
2. Open MATLAB (ensure 5G Toolbox is installed).
3. Run either `ACK_missed_F0.m` or `DTX_to_ACK_F0.m` to see the performance plots.
