# FPGA-Based Hardware Root of Trust (HRoT) — Secure Boot System

8-pair RO-PUF + Hamming-distance device authentication, UART-delivered
SHA-256 firmware attestation, and a secure boot FSM gating ESP32 reset.
Target: Xilinx Spartan-6.

## Design decisions locked in during this build
- **Hash transfer:** UART (8N1), not SPI.
- **Hamming distance threshold:** runtime-configurable register
  (`authentication_controller.v`), reset to a synthesis-time
  `DEFAULT_THRESHOLD` parameter, overwritable via UART command `0x04`.
  Not a hard-coded constant, per spec.
- **Reference storage (enrolled PUF response + reference hash):**
  register-based, provisioned via UART each session (`enrollment_storage.v`,
  `sha256_interface.v` commands `0x01`/`0x03`). No external non-volatile
  memory in this design — see "Known simplifications" below.

## UART command protocol (sha256_interface.v)
| Byte | Command | Payload |
|---|---|---|
| 0x01 | Load reference hash | 32 bytes, MSB-first |
| 0x02 | Send current firmware hash (this boot) | 32 bytes, MSB-first |
| 0x03 | Load reference PUF response | 1 byte |
| 0x04 | Set HD threshold | 1 byte |

## Files
**RTL (13 modules):** ring_oscillator, frequency_counter, ro_pair,
ro_puf_controller, enrollment_storage, hamming_distance,
authentication_controller, uart_receiver, sha256_interface,
hash_comparator, secure_boot_fsm, esp32_reset_controller, top_module.

**Testbenches (9):** tb_hamming_distance, tb_ro_pair, tb_ro_puf_controller,
tb_uart_receiver, tb_sha256_interface, tb_hash_and_auth (hash_comparator +
authentication_controller), tb_secure_boot_fsm (4 required scenarios),
tb_top_integration (full pass path via real UART timing), and
tb_top_integration_fail (full fail path, modified firmware).

## Verified by actually simulating (Icarus Verilog 12.0), not just written blind
Every testbench above was compiled and run; all pass. In the process three
real RTL bugs were found and fixed — worth knowing about since they're the
kind of thing that would otherwise only surface on the bench:

1. **`frequency_counter.v`** — the first version sampled the RO's edges
   into the system clock domain via an edge detector. That only works if
   the system clock is comfortably above the RO's Nyquist rate; since RO
   frequency on Spartan-6 can be comparable to or faster than the system
   clock, this aliased and undercounted. Rewrote as an async ripple
   counter clocked directly by the oscillator, with a proper 2-flop CDC
   synchronizer to read the final count into the system clock domain.

2. **`ro_pair.v` (bug 1)** — the two frequency counters' "count ready"
   pulses are single-cycle and, since RO_A and RO_B run at different
   frequencies by design, don't reliably land on the same clock cycle.
   `bit_valid = valid_a & valid_b` almost never caught both. Fixed with
   sticky "seen" latches, cleared only when a new measurement window opens.

3. **`ro_pair.v` (bug 2)** — a same-cycle race: `bit_valid` (originally
   combinational) could go high one cycle before `response_bit`
   (registered) reflected the correct comparison, so a consumer polling
   `bit_valid` could read a stale/default `response_bit`. Fixed by
   registering both together off the same condition.

Test results (abbreviated):
```
tb_hamming_distance      -> 4/4 vectors PASS (incl. spec's own HD=1 example)
tb_ro_pair                -> PASS (faster RO correctly resolves to response_bit=1)
tb_ro_puf_controller      -> 8-bit response defined and repeatable across two runs
tb_uart_receiver          -> both test bytes correctly decoded at 115200 baud
tb_sha256_interface       -> all 4 command types (ref hash / cur hash / ref PUF / threshold) PASS
tb_hash_and_auth          -> hash match/mismatch PASS; runtime threshold reprogram PASS
tb_secure_boot_fsm        -> all 4 required scenarios PASS (TC1..TC4)
tb_top_integration        -> full enroll -> authenticate -> PASS -> reset released
tb_top_integration_fail   -> full enroll -> authenticate -> modified FW -> reset held
```

## Known simplifications (deliberate, called out in-code)
- **No non-volatile storage.** Reference PUF response and reference hash
  live in FPGA registers, re-provisioned via UART each power cycle. A
  production HRoT would move this to protected NVM (eFuse/OTP or an
  authenticated external flash region) so enrollment happens once at
  manufacture time.
- **Provisioning commands are not authenticated.** The UART protocol has
  no signing/authentication on the `0x01`/`0x03`/`0x04` commands — an
  attacker on the UART line could in principle reprogram the reference
  values to match malicious firmware. Flagged in `sha256_interface.v`
  as a known gap appropriate for an academic prototype, not a hardened
  field design.
- **SHA-256 itself is computed off-FPGA**, by the ESP32, by design (per
  your spec) — the FPGA only compares hashes, which keeps gate count and
  attack surface down. This is a deliberate architectural choice, not a
  simplification.

## What's not yet done
- **UCF pin constraints** for the actual Spartan-6 board (RO placement in
  particular needs LOC/RLOC constraints so place-and-route doesn't
  optimize away or rebalance the RO pairs — noted in `ring_oscillator.v`).
- **Synthesis run** against Xilinx ISE/XST — everything here has been
  verified in simulation only.
- **LCD status display integration**, referenced in your prior HRoT
  project but not requested in this spec.
