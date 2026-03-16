`include "toylog_cpu_defs.vh"

module toylog_cpu_mem_stage (
    input  wire        load,
    input  wire        store,
    input  wire [31:0] mem_addr,
    input  wire [31:0] store_data_in,
    input  wire [3:0]  store_wstrb_in,
    input  wire [1:0]  mem_size,
    input  wire        mem_unsigned,
    input  wire [31:0] dmem_rdata,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output reg  [31:0] load_data
);

assign dmem_addr = mem_addr;
assign dmem_wdata = store ? store_data_in : 32'h0000_0000;
assign dmem_wstrb = store ? store_wstrb_in : 4'b0000;

always @* begin
    case (mem_size)
        `TOYLOG_CPU_MEM_B: begin
            case (mem_addr[1:0])
                2'b00: load_data = mem_unsigned ? {24'b0, dmem_rdata[7:0]}   : {{24{dmem_rdata[7]}},   dmem_rdata[7:0]};
                2'b01: load_data = mem_unsigned ? {24'b0, dmem_rdata[15:8]}  : {{24{dmem_rdata[15]}},  dmem_rdata[15:8]};
                2'b10: load_data = mem_unsigned ? {24'b0, dmem_rdata[23:16]} : {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                default: load_data = mem_unsigned ? {24'b0, dmem_rdata[31:24]} : {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
            endcase
        end
        `TOYLOG_CPU_MEM_H: begin
            if (mem_addr[1]) begin
                load_data = mem_unsigned ? {16'b0, dmem_rdata[31:16]} : {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
            end else begin
                load_data = mem_unsigned ? {16'b0, dmem_rdata[15:0]} : {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
            end
        end
        default: begin
            load_data = dmem_rdata;
        end
    endcase
end

endmodule
