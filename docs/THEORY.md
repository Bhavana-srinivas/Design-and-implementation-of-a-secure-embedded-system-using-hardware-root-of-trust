# Theory Documentation
## Design and Implementation of Secure Embedded System Using HRoT with RO-PUF

---

# 1. Introduction

Embedded systems are increasingly vulnerable to:
- firmware tampering
- hardware cloning
- unauthorized access
- malicious modifications

To improve security, this project implements a Hardware Root of Trust (HRoT) integrated with a Ring Oscillator Physical Unclonable Function (RO-PUF) on a Spartan-6 FPGA.

The system verifies device authenticity before booting the firmware.

---

# 2. Hardware Root of Trust (HRoT)

Hardware Root of Trust is a secure hardware-based mechanism responsible for validating system integrity during startup.

It acts as:
- the first trusted component
- secure boot controller
- firmware authentication system

---

# 3. Functions of HRoT

The HRoT module:
- verifies firmware authenticity
- prevents unauthorized boot
- validates device identity
- controls secure startup process

---

# 4. Physical Unclonable Function (PUF)

A Physical Unclonable Function (PUF) generates a unique response based on manufacturing variations in hardware.

Even identical FPGA chips produce different responses.

---

# 5. Ring Oscillator PUF (RO-PUF)

RO-PUF uses multiple ring oscillators.

Due to manufacturing differences:
- oscillators run at slightly different frequencies
- frequency comparison generates unique bits

This creates a hardware fingerprint unique to every FPGA device.

---

# 6. Working Principle

## Step 1
Switches provide challenge input.

## Step 2
RO-PUF generates unique response.

## Step 3
Firmware data is processed.

## Step 4
Hash/comparison logic verifies integrity.

## Step 5
Decision module:
- allows boot
- or blocks boot

---

# 7. Secure Boot Flow

```text
Switch Input
      ↓
RO-PUF Response
      ↓
Firmware Verification
      ↓
Comparator
      ↓
Decision Logic
      ↓
BOOT / BLOCK LED
```

---

# 8. FPGA Implementation

The project is implemented using:
- Verilog HDL
- Xilinx ISE 14.7
- Spartan-6 FPGA

RTL modules are synthesized and programmed into FPGA hardware.

---

# 9. Advantages

- Hardware-level security
- Device authentication
- Anti-cloning protection
- Secure boot verification
- Low-cost FPGA implementation

---

# 10. Applications

- Secure IoT devices
- Embedded security systems
- FPGA authentication
- Defense electronics
- Trusted computing systems

---

# 11. Current Development Status

## Completed
- Basic RTL module development
- RO-PUF prototype
- Comparator logic
- Decision module
- FPGA synthesis flow

## Under Development
- SHA-256 integration
- UART communication
- Enhanced authentication logic
- BRAM secure storage

---

# 12. Future Enhancements

- ECC-based stabilization
- Full SHA-256 hardware engine
- 64-bit PUF
- Secure firmware updates
- Advanced cryptographic support

---

# 13. Conclusion

This project demonstrates a basic FPGA-based secure embedded system using Hardware Root of Trust and Ring Oscillator PUF concepts.

The implementation focuses on secure boot verification and hardware authentication using Verilog HDL on Spartan-6 FPGA.

---