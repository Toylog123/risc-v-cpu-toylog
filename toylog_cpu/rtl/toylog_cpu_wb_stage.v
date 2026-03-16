`include "toylog_cpu_defs.vh"

module toylog_cpu_wb_stage (
    input  wire [1:0]  wb_sel,
    input  wire [31:0] exec_result,
    input  wire [31:0] load_data,
    input  wire [31:0] pc4,
    output wire [31:0] wb_data
);

assign wb_data =
    (wb_sel == `TOYLOG_CPU_WB_MEM) ? load_data :
    (wb_sel == `TOYLOG_CPU_WB_PC4) ? pc4 :
    exec_result;

endmodule
