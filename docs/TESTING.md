# Hardware Testing Documentation
## Design and Implementation of Secure Embedded System Using HRoT with RO-PUF

---

# 1. Objective

The purpose of testing is to verify:
- RO-PUF functionality
- secure boot operation
- comparator logic
- LED output behavior
- FPGA implementation correctness

---

# 2. Testing Environment

| Component | Description |
|-----------|-------------|
| FPGA Board | Spartan-6 FPGA |
| Tool | Xilinx ISE 14.7 |
| Language | Verilog HDL |
| Programmer | iMPACT |
| Simulation Tool | ISim |

---

# 3. Input Method

FPGA switches are used as challenge inputs.

Example:

```text
SW = 00001111
```

---

# 4. Output Observation

LEDs indicate authentication status.

| LED | Function |
|-----|----------|
| boot_led | Boot allowed |
| block_led | Boot blocked |
| led[7:0] | Hash/debug output |

---

# 5. Testing Procedure

## Step 1
Power ON FPGA board.

---

## Step 2
Program FPGA using:
```text
top_module.bit
```

---

## Step 3
Apply switch input.

Example:
```text
10101010
```

---

## Step 4
Observe generated LED outputs.

---

# 6. Expected Working Flow

```text
Switch Input
      ↓
RO-PUF Response
      ↓
Firmware Module
      ↓
Hash Generation
      ↓
Comparator
      ↓
Decision Module
      ↓
LED Output
```

---

# 7. Test Cases

| Test Case | Input | Expected Result |
|-----------|------|----------------|
| Valid Input | Correct switch pattern | boot_led ON |
| Invalid Input | Wrong switch pattern | block_led ON |
| Reset Test | Reset pressed | Outputs cleared |
| LED Test | Any valid input | LED output changes |

---

# 8. Simulation Testing

Simulation is performed using ISim.

Testbench file:
```text
tb_top_module.v
```

Simulation verifies:
- module functionality
- signal flow
- LED behavior
- comparator output

---

# 9. FPGA Synthesis Verification

The design is checked for:
- syntax errors
- synthesis success
- implementation success
- bitstream generation

Expected:
```text
Green Tick in Xilinx ISE
```

---

# 10. Current Testing Status

## Completed
- Basic simulation
- RTL verification
- Synthesis testing
- Initial LED output testing

## Under Development
- Full hardware validation
- SHA-256 testing
- UART communication testing
- PUF stability testing

---

# 11. Future Testing

Future work includes:
- temperature variation testing
- long-term stability analysis
- advanced authentication testing
- secure firmware verification

---

# 12. Conclusion

Testing verifies the correct operation of the FPGA-based secure embedded system using HRoT and RO-PUF concepts.

The project is currently under development and undergoing continuous FPGA validation and testing.

---