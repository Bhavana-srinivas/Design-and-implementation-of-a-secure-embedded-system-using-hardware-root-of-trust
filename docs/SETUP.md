# FPGA Setup and Implementation Guide
## Design and Implementation of Secure Embedded System Using HRoT with RO-PUF

---

# 1. Introduction

This project implements a basic Hardware Root of Trust (HRoT) system integrated with a Ring Oscillator Physical Unclonable Function (RO-PUF) on a Spartan-6 FPGA platform.

The objective of the system is to:
- Generate a unique hardware fingerprint
- Verify firmware authenticity
- Allow or block secure boot
- Indicate authentication result using LEDs

The implementation is developed using:
- Verilog HDL
- Xilinx ISE 14.7
- Spartan-6 FPGA Board

---

# 2. Required Software

| Software | Purpose |
|----------|----------|
| Xilinx ISE 14.7 | FPGA Design & Synthesis |
| ISim | Simulation |
| iMPACT | FPGA Programming |
| Git | Version Control |
| VS Code | Code Editing |

---

# 3. FPGA Board Details

| Parameter | Value |
|-----------|-------|
| FPGA Family | Spartan-6 |
| Device | XC6SLX9 |
| Package | TQG144 |
| Speed Grade | -2 |

---

# 4. Project Folder Structure

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

# 5. Creating Project Folder

## Step 1
Create a folder:

```text
hrot_puf_project
```

---

## Step 2
Inside the folder create:

```text
src
sim
constraints
docs
```

---

# 6. Creating Verilog Files

Inside `src/` create these files:

```text
ro_puf.v
firmware_module.v
hash_module.v
comparator.v
decision_module.v
top_module.v
```

---

# 7. Creating Simulation File

Inside `sim/` create:

```text
tb_top_module.v
```

---

# 8. Creating Documentation Files

Inside `docs/` create:

```text
SETUP.md
THEORY.md
TESTING.md
```

---

# 9. Opening Project in VS Code

## Step 1
Open VS Code.

---

## Step 2
Click:

```text
File → Open Folder
```

Select:

```text
hrot_puf_project
```

---

# 10. Creating GitHub Repository

## Step 1
Open:

```text
https://github.com
```

---

## Step 2
Click:

```text
New Repository
```

---

## Step 3
Repository Name:

```text
hrot_puf_project
```

---

## Step 4
Click:

```text
Create Repository
```

---

# 11. Uploading Project to GitHub

## Step 1
Open terminal inside VS Code.

---

## Step 2
Initialize Git:

```bash
git init
```

---

## Step 3
Add files:

```bash
git add .
```

---

## Step 4
Commit files:

```bash
git commit -m "Initial RTL implementation"
```

---

## Step 5
Connect GitHub repository:

```bash
git remote add origin YOUR_REPOSITORY_LINK
```

Example:

```bash
git remote add origin https://github.com/username/hrot_puf_project.git
```

---

## Step 6
Push files:

```bash
git branch -M main
git push -u origin main
```

---

# 12. Opening Xilinx ISE 14.7

## Step 1
Open:

```text
Xilinx ISE Design Suite 14.7
```

---

# 13. Creating New FPGA Project

## Step 1
Click:

```text
File → New Project
```

---

## Step 2
Project Name:

```text
hrot_puf_project
```

---

## Step 3
Select Device Properties:

```text
Family  : Spartan6
Device  : XC6SLX9
Package : TQG144
Speed   : -2
```

---

## Step 4
Click:

```text
Next → Finish
```

---

# 14. Adding Verilog Files in ISE

## Step 1
Right click:

```text
Hierarchy Panel
```

---

## Step 2
Click:

```text
Add Source
```

---

## Step 3
Add all files from:

```text
src/
```

---

# 15. Setting Top Module

Right click:

```text
top_module.v
```

Click:

```text
Set as Top Module
```

---

# 16. Running Synthesis

Double click:

```text
Synthesize - XST
```

Expected Result:

```text
Green Tick
```

---

# 17. Implement Design

Double click:

```text
Implement Design
```

Expected Result:

```text
Green Tick
```

---

# 18. Generate Bitstream File

Double click:

```text
Generate Programming File
```

Generated Output:

```text
top_module.bit
```

---

# 19. Connecting FPGA Board

Connect:
- Spartan-6 FPGA Board
- USB/JTAG cable
- Power Supply

Turn ON the board.

---

# 20. Programming FPGA

## Step 1
Open:

```text
Tools → iMPACT
```

---

## Step 2
Select:

```text
Boundary Scan
```

---

## Step 3
Right click white area:

```text
Initialize Chain
```

FPGA will be detected.

---

## Step 4
Select:

```text
top_module.bit
```

---

## Step 5
Right click FPGA icon:

```text
Program
```

Expected Result:

```text
Program Succeeded
```

---

# 21. Hardware Testing

## Input

Switches on FPGA board act as:
- Challenge input to RO-PUF

Example:

```text
00001111
```

---

# 22. Output Observation

| LED Status | Meaning |
|------------|----------|
| boot_led ON | Secure boot successful |
| block_led ON | Authentication failed |

---

# 23. System Working Flow

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

# 24. Current Development Status

## Completed
- Basic RTL structure
- RO-PUF module
- Comparator logic
- Decision module
- FPGA synthesis flow
- Initial testing

## Under Development
- SHA-256 Integration
- UART firmware loading
- BRAM storage
- Enhanced authentication flow

---

# 25. Future Enhancements

- SHA-256 hardware accelerator
- ECC-based PUF stabilization
- 64-bit PUF implementation
- Secure UART firmware update
- Machine learning attack resistance

---

# 26. Notes

This project is currently under development and testing for academic and research purposes.

The repository is maintained for:
- Mentor review
- FPGA implementation tracking
- Academic documentation
- GitHub portfolio showcase

---