# Design-and-implementation-of-a-secure-embedded-system-using-hardware-root-of-trust

##  Project Overview

This project focuses on the design and implementation of a Secure Embedded System using a **Hardware Root of Trust (HRoT)** combined with a **Ring Oscillator Physical Unclonable Function (RO-PUF)** on a **Xilinx Spartan-6 FPGA** platform.

The system aims to enhance embedded device security by authenticating hardware identity and verifying firmware integrity before system boot. The project demonstrates FPGA-based secure boot concepts using modular Verilog RTL design.

>  Current Status: The project is currently under development and testing. Basic RTL implementation, FPGA setup, and RO-PUF integration are in progress.


---

#  Objectives

- Implement Hardware Root of Trust (HRoT)
- Design FPGA-based RO-PUF architecture
- Verify firmware integrity before boot
- Prevent unauthorized firmware execution
- Demonstrate secure embedded system design
- Develop modular RTL implementation using Verilog HDL

---

#  Introduction

## Hardware Root of Trust (HRoT)

Hardware Root of Trust is a trusted hardware-based security mechanism that validates firmware authenticity during system startup.

It acts as:
- trusted boot controller
- authentication mechanism
- secure verification unit

---

## Ring Oscillator Physical Unclonable Function (RO-PUF)

RO-PUF generates unique responses using manufacturing variations inside FPGA hardware.

Features:
- unique device fingerprint
- anti-cloning capability
- hardware authentication
- secure identification

---

#  Secure Boot Flow

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
BOOT / BLOCK LED
```

---

#  System Architecture

```text
┌────────────────────────────────────────────┐
│              Spartan-6 FPGA                │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │             RO-PUF Module            │  │
│  │      Generates Unique Response       │  │
│  └──────────────────────────────────────┘  │
│                     │                      │
│                     ▼                      │
│  ┌──────────────────────────────────────┐  │
│  │            HRoT Module               │  │
│  │   Firmware Verification & Control    │  │
│  └──────────────────────────────────────┘  │
│                     │                      │
│                     ▼                      │
│          Boot Allow / Block Logic          │
│                     │                      │
│             LED Indication Output          │
└────────────────────────────────────────────┘
```

---

#  Repository Structure

```text
hrot_puf_project/
│
├── src/
│   ├── ro_puf.v
│   ├── firmware_module.v
│   ├── hash_module.v
│   ├── comparator.v
│   ├── decision_module.v
│   └── top_module.v
│
├── sim/
│   └── tb_top_module.v
│
├── constraints/
│   └── spartan6.ucf
│
├── docs/
│   ├── SETUP.md
│   ├── THEORY.md
│   └── TESTING.md
│
└── README.md
```

---

#  Tools and Technologies

| Tool | Purpose |
|------|----------|
| Verilog HDL | RTL Design |
| Xilinx ISE 14.7 | FPGA Synthesis |
| Spartan-6 FPGA | Hardware Platform |
| ISim | Simulation |
| iMPACT | FPGA Programming |
| GitHub | Version Control |

---

#  FPGA Platform Details

| Parameter | Value |
|-----------|-------|
| FPGA Family | Spartan-6 |
| Device | XC6SLX9 |
| Package | TQG144 |
| Speed Grade | -2 |

---

#  RTL Modules

| Module | Description |
|--------|-------------|
| ro_puf.v | Generates PUF response |
| firmware_module.v | Provides firmware data |
| hash_module.v | Generates hash-like output |
| comparator.v | Verifies authentication |
| decision_module.v | Controls boot/block LEDs |
| top_module.v | Top-level integration |

---

#  FPGA Implementation Flow

```text
RTL Design
    ↓
Simulation
    ↓
Synthesis
    ↓
Implementation
    ↓
Bitstream Generation
    ↓
FPGA Programming
    ↓
Hardware Testing
```

---

#  Hardware Testing

## Inputs
- FPGA switches used as challenge inputs

## Outputs
- boot_led → Secure boot success
- block_led → Authentication failure
- led[7:0] → Hash/debug outputs

---

#  Current Development Status

##  Completed
- Basic RTL architecture
- RO-PUF prototype logic
- Comparator module
- Decision module
- FPGA synthesis setup
- Initial simulation

##  Under Development
- SHA-256 integration
- UART communication
- Enhanced secure boot logic
- FPGA hardware validation

---

#  Future Enhancements

- Full SHA-256 hardware implementation
- ECC-based PUF stabilization
- 64-bit RO-PUF design
- Secure UART firmware update
- BRAM secure storage
- Advanced cryptographic support

---

#  Team

- Bhavana S
- Harshitha H N
- Nanditha L N

Department of Electronics & Communication Engineering

---

#  References

1. Xilinx Spartan-6 FPGA Documentation  
2. NIST SHA-256 Standard  
3. Research Papers on Physical Unclonable Functions  
4. Hardware Root of Trust Architecture  
5. FPGA Security Research Articles  

---

#  Notes

This repository is maintained for:
- FPGA development tracking
- mentor review
- academic documentation
- project presentation
- GitHub portfolio showcase

The project is currently under active development and testing.

---
