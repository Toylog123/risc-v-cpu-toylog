## CICC1003618 submission context:
## File role: fpga/vivado/constraints/nexys_a7_100_template.xdc is part of the FPGA prototype build, constraint or board adaptation source.
## Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
## Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
## Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
## Verification note: functional changes require matching simulation logs or FPGA reports.
## Maintenance note: update documents, metrics and hashes when this file changes.

## YH_rv_cpu Nexys A7-100T constraint template
##
## This file freezes only the ports used by YH_rv_cpu on the Nexys A7-100T.
## The PACKAGE_PIN and IOSTANDARD values below were copied from the official
## Digilent Nexys-A7-100T Master XDC so the pre-board flow can generate a real
## bitstream. Final board closure still requires on-hardware UART/LED/reset
## verification.
##
## Reference sources:
## - https://github.com/Digilent/digilent-xdc
## - Nexys A7 Reference Manual
##
## Frozen port list for the bring-up flow:
## - CLK100MHZ
## - cpu_resetn
## - uart_txd_in
## - uart_rxd_out
## - led[3:0]
##
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }]
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { cpu_resetn }]
set_property -dict { PACKAGE_PIN C4  IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in }]
set_property -dict { PACKAGE_PIN D4  IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]
