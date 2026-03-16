## YH_rv_cpu 的 Nexys A7-100T 约束模板。
##
## 当前项目还没有实物板卡，这个文件的目的不是直接生成最终 bitstream，
## 而是先统一接口命名、统一时钟约束，并给后续拿到板卡后的引脚绑定留出入口。
##
## 权威约束来源：
## 1. Digilent 官方 Master XDC 仓库
##    https://github.com/Digilent/digilent-xdc
## 2. Nexys A7 Reference Manual
##    https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7_rm.pdf
##
## 建议做法：
## - 拿到实物板卡后，以 Digilent 的 Nexys-A7-100T-Master.xdc 为准。
## - 只保留本工程实际使用到的端口，并把对应 LOC 从官方 XDC 复制到这里。
## - 在最终生成 bitstream 前，不要依赖这个模板中的占位注释。

create_clock -name sys_clk -period 10.000 [get_ports CLK100MHZ]

## TODO: 从 Digilent 官方 Master XDC 复制并启用这些端口的 LOC / IOSTANDARD。
##
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { cpu_resetn }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { uart_txd_in }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_out }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
## set_property -dict { PACKAGE_PIN <pin> IOSTANDARD LVCMOS33 } [get_ports { led[3] }]
