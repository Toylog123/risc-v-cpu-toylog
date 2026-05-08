## CICC1003618 submission context:
## File role: fpga/vivado/constraints/pynq_z2_template.xdc is part of the FPGA prototype build, constraint or board adaptation source.
## Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
## Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
## Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
## Verification note: functional changes require matching simulation logs or FPGA reports.
## Maintenance note: update documents, metrics and hashes when this file changes.

## YH_rv_cpu PYNQ-Z2 constraint template
##
## Board: TUL/AMD PYNQ-Z2, Zynq-7000 XC7Z020-1CLG400C
## Source: TUL PYNQ-Z2 Master XDC, downloaded from:
## https://dpoauwgwqsy2x.cloudfront.net/Download/pynq-z2_v1.0.xdc.zip
##
## Notes:
## - PYNQ-Z2 exposes a 125 MHz PL clock on H16. The top-level port keeps the
##   historical name CLK100MHZ, but the PYNQ-Z2 build enables an MMCM. The
##   formal preliminary submission build runs the soft CPU domain at 50 MHz,
##   satisfying the required FPGA frequency floor with positive timing slack.
## - The on-board Micro-USB UART is wired to the Zynq PS MIO pins, not directly
##   to PL fabric pins in this simple RTL-only flow. This template routes the
##   soft CPU UART to Pmod B. Use an external 3.3 V USB-UART adapter for logs.
## - cpu_resetn is mapped to SW0 so OFF holds reset and ON releases reset.
##
## Frozen port list:
## - CLK100MHZ       -> PYNQ-Z2 sysclk, 125 MHz
## - cpu_resetn      -> SW0
## - uart_txd_in     -> Pmod B JB0, optional RX into FPGA, unused by current RTL
## - uart_rxd_out    -> Pmod B JB1, UART TX from FPGA to USB-UART adapter RX
## - led[3:0]        -> LD0..LD3

set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }]
set_property -dict { PACKAGE_PIN M20 IOSTANDARD LVCMOS33 } [get_ports { cpu_resetn }]

set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in }]
set_property -dict { PACKAGE_PIN Y14 IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }]

set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]
