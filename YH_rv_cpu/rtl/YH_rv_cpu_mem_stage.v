`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_mem_stage #(
    parameter integer XLEN = 32
) (
    input  wire            load,
    input  wire            store,
    input  wire [XLEN-1:0] mem_addr,
    input  wire [XLEN-1:0] store_data_in,
    input  wire [3:0]      store_wstrb_in,
    input  wire [1:0]      mem_size,
    input  wire            mem_unsigned,
    input  wire [XLEN-1:0] dmem_rdata,
    output wire [XLEN-1:0] dmem_addr,
    output wire [XLEN-1:0] dmem_wdata,
    output wire [3:0]      dmem_wstrb,
    output reg  [XLEN-1:0] load_data
);

assign dmem_addr = mem_addr;
assign dmem_wdata = store ? store_data_in : {XLEN{1'b0}};
assign dmem_wstrb = store ? store_wstrb_in : 4'b0000;

always @* begin
    case (mem_size)
        `YH_rv_cpu_MEM_B: begin
            case (mem_addr[1:0])
                2'b00: load_data = mem_unsigned ? {{(XLEN-8){1'b0}}, dmem_rdata[7:0]}   : {{(XLEN-8){dmem_rdata[7]}},   dmem_rdata[7:0]};
                2'b01: load_data = mem_unsigned ? {{(XLEN-8){1'b0}}, dmem_rdata[15:8]}  : {{(XLEN-8){dmem_rdata[15]}},  dmem_rdata[15:8]};
                2'b10: load_data = mem_unsigned ? {{(XLEN-8){1'b0}}, dmem_rdata[23:16]} : {{(XLEN-8){dmem_rdata[23]}}, dmem_rdata[23:16]};
                default: load_data = mem_unsigned ? {{(XLEN-8){1'b0}}, dmem_rdata[31:24]} : {{(XLEN-8){dmem_rdata[31]}}, dmem_rdata[31:24]};
            endcase
        end
        `YH_rv_cpu_MEM_H: begin
            if (mem_addr[1]) begin
                load_data = mem_unsigned ? {{(XLEN-16){1'b0}}, dmem_rdata[31:16]} : {{(XLEN-16){dmem_rdata[31]}}, dmem_rdata[31:16]};
            end else begin
                load_data = mem_unsigned ? {{(XLEN-16){1'b0}}, dmem_rdata[15:0]} : {{(XLEN-16){dmem_rdata[15]}}, dmem_rdata[15:0]};
            end
        end
        default: begin
            load_data = mem_unsigned ? {{(XLEN-32){1'b0}}, dmem_rdata[31:0]} : {{(XLEN-32){dmem_rdata[31]}}, dmem_rdata[31:0]};
        end
    endcase
end

endmodule
