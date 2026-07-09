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
|TX-06|Reset During Transmission| Verify reset during an active transmission. |✅ Pass|

### 3.3 UART Receiver (`UART_RX_tb`)
|Test ID | Test Name | Test Description | Status |
|:-------:|:--------:|:----------------:|:------:|
|RX-01|Reset Verification | Verify receiver reset behavior and return to the IDLE state. |✅ Pass|
|RX-02| False Start Detection | Verify that the receiver ignores an invalid start-bit glitch. |✅ Pass*|
|RX-03|Valid Frame Reception| Verify successful reception of a valid UART frame with correct even parity.|✅ Pass|
|RX-04|Parity Error Detection| Verify detection of an invalid parity bit during frame reception.|✅ Pass|

### 3.4 Integrated UART Transceiver (`UART_TOP_tb`)
|Test ID | Test Name | Test Description | Status |
|:-------:|:--------:|:----------------:|:------:|
|TOP-01| Basic Loopback | Verify successful end-to-end transmission and reception of a single UART frame.|✅ Pass*|
|TOP-02| All-Zeros Data Pattern| Verify correct transmission and reception of `8'b00000000`.|✅ Pass|
|TOP-03| All-Ones Data Pattern| Verify correct transmission and reception of `8'b11111111`.|✅ Pass|
|TOP-04| Consecutive Frame Transmission | Verify successful transmission and reception of three consecutive frames with distinct data patterns, confirming no inter-frame corruption.|✅ Pass*|

>[!NOTE]
> `*` Indicates a test case that exposed a design issue or implementation challenge during development.
> 
> The issue was resolved successfully and is discussed in Section 6 – Debugging Experience.

## 4. Waveform Analysis 

To be added


## 5. Verification Results

All planned verification scenarios were successfully completed for the UART communication system. Module-level and system-level simulations confirmed correct functionality under normal operating conditions as well as selected edge cases.

| Module | Test Cases | Result |
|:---------:|:-----------:|:------:|
| Baud Rate Generator | 3 | ✅ Pass |
| UART Transmitter | 6 | ✅ Pass |
| UART Receiver | 4 | ✅ Pass |
| UART Transceiver | 4 | ✅ Pass |
| TOTAL | 17 | 17/17 Passed| 

Overall verification confirms:
- Correct baud tick generation.
- Correct UART frame transmission.
- Reliable UART frame reception.
- Correct parity generation and verification.
- Detection of false start conditions.
- Reliable end-to-end communication through the integrated UART Transceiver.

## 6. Debugging Experience 
This section highlights the most significant issues, the root causes, and the solutions implemented to achieve the final verified design.

### 6.1. RX-02: False Start Detection

#### Issue

During the initial implementation of the UART receiver, the start bit was validated using a single baud tick immediately after detecting a LOW level on the RX line. This approach made the receiver susceptible to short glitches or noise, which could be incorrectly interpreted as the start of a valid UART frame.

#### Root Cause

A valid UART receiver must ensure that the detected LOW level persists long enough to represent a genuine start bit. Sampling the input immediately after the falling edge provided no mechanism to distinguish a valid start bit from a transient glitch, resulting in unreliable frame synchronization.

#### Solution

The receiver was redesigned to use **16× oversampling** for start bit validation. Upon detecting a potential start bit, the receiver waits until the middle of the bit period before sampling the RX line. If the line remains LOW, the frame reception proceeds; otherwise, the event is treated as a false start and the receiver returns to the `IDLE` state.

#### Outcome

The updated design reliably rejected false start conditions while correctly detecting valid UART frames. This improvement significantly increased the robustness of the receiver and aligned its behavior with standard UART receiver implementations.

### 6.2. TOP-01: Basic Loopback

#### Issue

Although the UART transmitter and receiver operated correctly during module-level verification, integrating them into a complete UART Transceiver introduced additional challenges. Correct end-to-end communication depended on both modules remaining synchronized throughout the entire frame.

#### Root Cause

The transmitter and receiver shared the same free-running `baud_tick`, but this alone did not guarantee synchronization. Since transmission could begin at any point within a baud tick period, the receiver's sampling instants gradually became misaligned with the actual bit boundaries. A shared clock source was therefore insufficient without establishing a common timing reference for the start of each frame.

#### Solution

Both the transmitter and receiver were redesigned around a common 16× timing scheme. The transmitter holds each transmitted bit for a fixed 16-tick interval, while the receiver synchronizes to the validated start bit and samples each subsequent bit at its midpoint. This establishes a common timing reference, ensuring reliable synchronization throughout the UART frame.

#### Outcome

The integrated UART Transceiver successfully achieved reliable end-to-end communication. The receiver consistently sampled each bit at the intended instant, correctly reconstructed the transmitted data, and eliminated synchronization-related reception errors observed during early integration.

### 6.3. TOP-04: Consecutive Frame Transmission 

#### Issue 
During the initial verification of consecutive UART frame transmissions, the second transmission request was occasionally ignored, resulting in only the first frame being transmitted successfully.

#### Root Cause
The testbench asserted `tx_start` for the next frame before the transmitter had fully completed the previous transmission and returned to the `IDLE` state. Since the transmitter only accepts a new transmission request while idle, the premature `tx_start` pulse was missed, causing the second frame to be dropped.

#### Solution
The testbench was modified to synchronize with the transmitter using its status signals instead of fixed simulation delays. Rather than assuming when a transmission had finished, the `send_byte` task waits for `tx_busy` to assert, indicating that transmission has started, and then waits for it to deassert before issuing the next `tx_start` pulse. This guarantees that each new transmission request is accepted only after the transmitter has completely returned to the `IDLE` state.

#### Outcome
The updated verification environment successfully transmitted multiple UART frames consecutively without dropped requests or data corruption. The synchronization-based approach also produced a more robust and reusable testbench suitable for future regression testing.

## 7. Verification Improvements

Throughout the development of the UART Transceiver, the verification environment evolved from simple module-level testing to a structured, reusable verification framework. Several improvements were introduced to increase reliability, automation, and maintainability: 

- Replaced manual verification with self-checking testbenches using automated pass/fail validation.
- Introduced reusable verification tasks (`reset_dut`, `send_byte`, `check_result`, and `print_summary`) to eliminate repetitive testbench code.
- Replaced fixed simulation delays with event-driven synchronization using `wait()` construct on DUT status signals (`tx_busy` and `rx_done`) for more robust verification.
- Expanded verification from individual module testing to end-to-end system-level loopback verification.
- Added automated verification statistics and a final pass/fail summary for improved regression testing.

## 8. Conclusion

The verification process successfully validated the functionality of the UART Transceiver through comprehensive module-level and system-level testing. The developed testbenches verified normal operation as well as key edge cases, providing confidence in the correctness of the Baud Rate Generator, UART Transmitter, UART Receiver, and the integrated UART Transceiver.

Throughout the verification process, the testbench environment evolved from simple manually driven simulations to a structured, reusable, and self-checking framework. This not only improved the efficiency and reliability of verification but also reinforced the importance of event-driven synchronization, systematic debugging, and scalable verification practices in RTL design.

Overall, this verification effort provides a strong foundation for verifying more complex communication protocols and digital systems in future projects.
