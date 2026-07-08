# UART Transceiver Verification

## 1. Verification Objective
The primary objective of this verification document is to demonstrate that the UART Transceiver functions as intended by testing the required functional scenarios, standard operating conditions, and relevant edge cases. This includes verifying the functionality of the Baud Rate Generator, UART Transmitter, UART Receiver, and the integrated UART Transceiver.

A secondary objective was to strengthen RTL verification practices by developing structured testbenches and improving debugging skills throughout the design and verification process.

## 2. Testbench Architecture
Dedicated testbenches were developed for the following modules:
- `Baud_Rate_Generator_tb`
- `UART_TX_tb`
- `UART_RX_tb`
- `UART_TOP_tb`

Each testbench shares several common verification components, including:
- Clock and Reset generation
- DUT instantiation
- Input stimulus generation
- Output monitoring (`$monitor`)
- Waveform dumping (`$dumpfile`,`$dumpvars`)
- Simulation control (`$finish`)

>[!NOTE]
> 1. First 3 modules uses manual frame generation to visualise UART timing and protocol behaviour during module-level verification.
>
> 2. The integrated `UART_TOP_tb` utilises advanced verification techniques, including reusable tasks (`reset_dut`, `send_byte`, `check_result`) and automated self-checking with a pass/fail summary (`print_summary`), enabling a more scalable and maintainable verification environment.

## 3. Test cases
This section tabulates the verification tests performed for each module. 

### 3.1 Baud Rate Generator (`Baud_Rate_Generator_tb`)
|Test ID | Test Name | Test Description | Status |
|:-------:|:--------:|:----------------:|:------:|
| BRG-01| Reset Verification | Verify that asserting `rst` resets the internal counter and deasserts `baud_tick`. | ✅ Pass|
| BRG-02| Baud Tick Generation | Verify that `baud_tick` is asserted after the overridden baud divisor (`CLK_FREQ` = 100, `BAUD_RATE` = 10) is reached.| ✅ Pass|
| BRG-03| Continous Tick Generation | Verify that `baud_tick` is generated periodically during continuous operation after reset is released. | ✅ Pass|

### 3.2 UART Transmitter (`UART_TX_tb`)
|Test ID | Test Name | Test Description | Status |
|:-------:|:--------:|:----------------:|:------:|
|TX-01| Reset Verification | Verify that the transmitter enters the IDLE state after reset. | ✅ Pass|
|TX-02| Single Byte Transmission (Even Parity) | Verify correct parity bit (0) generation for input data containing an even number of logic 1s.|  ✅ Pass|
|TX-03| Single Byte Transmission (Odd Parity) | Verify correct parity bit (1) generation for input data containing an odd number of logic 1s.|✅ Pass|
|TX-04|Back-to-Back Transmission| Verify consecutive UART frame transmissions without data loss.| ✅ Pass|
|TX-05| Extended `tx_start` Assertion | Verify that holding `tx_start` HIGH for multiple clock cycles does not trigger unintended re-transmissions.|  ✅ Pass|
|TX-06|Reset During Transmission| Verify reset during an active transmission. | ✅ Pass|

