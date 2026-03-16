`include "YH_rv_cpu_defs.vh"

module YH_rv_cpu_mem_stage #(
    parameter integer XLEN = 32
) (
    input  wire            load,
    input  wire            store,
    input  wire [XLEN-1:0] mem_addr,
    input  wire [XLEN-1:0] store_data_in,
    input  wire [XLEN/8-1:0] store_wstrb_in,
    input  wire [1:0]      mem_size,
    input  wire            mem_unsigned,
    input  wire [XLEN-1:0] dmem_rdata,
    output wire [XLEN-1:0] dmem_addr,
    output wire [XLEN-1:0] dmem_wdata,
    output wire [XLEN/8-1:0] dmem_wstrb,
    output reg  [XLEN-1:0] load_data
);

localparam integer STRB_W = XLEN / 8;
localparam integer BYTE_OFFSET_W = $clog2(STRB_W);

wire [BYTE_OFFSET_W-1:0] byte_offset;
wire [XLEN-1:0] shifted_rdata;

assign dmem_addr = mem_addr;
assign dmem_wdata = store ? store_data_in : {XLEN{1'b0}};
assign dmem_wstrb = store ? store_wstrb_in : {STRB_W{1'b0}};
assign byte_offset = mem_addr[BYTE_OFFSET_W-1:0];
assign shifted_rdata = dmem_rdata >> {byte_offset, 3'b000};

always @* begin
    case (mem_size)
        `YH_rv_cpu_MEM_B: begin
            load_data = mem_unsigned ? {{(XLEN-8){1'b0}}, shifted_rdata[7:0]} : {{(XLEN-8){shifted_rdata[7]}}, shifted_rdata[7:0]};
        end
        `YH_rv_cpu_MEM_H: begin
            load_data = mem_unsigned ? {{(XLEN-16){1'b0}}, shifted_rdata[15:0]} : {{(XLEN-16){shifted_rdata[15]}}, shifted_rdata[15:0]};
        end
        `YH_rv_cpu_MEM_W: begin
            load_data = mem_unsigned ? {{(XLEN-32){1'b0}}, shifted_rdata[31:0]} : {{(XLEN-32){shifted_rdata[31]}}, shifted_rdata[31:0]};
        end
        default: begin
            load_data = shifted_rdata;
        end
    endcase
end

endmodule
