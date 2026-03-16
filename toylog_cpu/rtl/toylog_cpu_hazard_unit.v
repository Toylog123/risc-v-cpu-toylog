module toylog_cpu_hazard_unit (
    input  wire        if_id_rs1_en,
    input  wire        if_id_rs2_en,
    input  wire [4:0]  if_id_rs1_addr,
    input  wire [4:0]  if_id_rs2_addr,
    input  wire        id_ex_valid,
    input  wire        id_ex_load,
    input  wire        id_ex_rd_en,
    input  wire [4:0]  id_ex_rd_addr,
    input  wire        id_ex_rs1_en,
    input  wire        id_ex_rs2_en,
    input  wire [4:0]  id_ex_rs1_addr,
    input  wire [4:0]  id_ex_rs2_addr,
    input  wire        ex_mem_valid,
    input  wire        ex_mem_load,
    input  wire        ex_mem_rd_en,
    input  wire [4:0]  ex_mem_rd_addr,
    input  wire        mem_wb_valid,
    input  wire        mem_wb_rd_en,
    input  wire [4:0]  mem_wb_rd_addr,
    output wire        stall_fetch,
    output wire        stall_decode,
    output wire        bubble_execute,
    output reg  [1:0]  forward_a_sel,
    output reg  [1:0]  forward_b_sel
);

wire load_use_hazard;

assign load_use_hazard =
    id_ex_valid && id_ex_load && id_ex_rd_en && (id_ex_rd_addr != 5'd0) &&
    (
        (if_id_rs1_en && (if_id_rs1_addr == id_ex_rd_addr)) ||
        (if_id_rs2_en && (if_id_rs2_addr == id_ex_rd_addr))
    );

assign stall_fetch = load_use_hazard;
assign stall_decode = load_use_hazard;
assign bubble_execute = load_use_hazard;

always @* begin
    forward_a_sel = 2'b00;
    forward_b_sel = 2'b00;

    if (id_ex_rs1_en && ex_mem_valid && ex_mem_rd_en && !ex_mem_load &&
        (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs1_addr)) begin
        forward_a_sel = 2'b01;
    end else if (id_ex_rs1_en && mem_wb_valid && mem_wb_rd_en &&
                 (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs1_addr)) begin
        forward_a_sel = 2'b10;
    end

    if (id_ex_rs2_en && ex_mem_valid && ex_mem_rd_en && !ex_mem_load &&
        (ex_mem_rd_addr != 5'd0) && (ex_mem_rd_addr == id_ex_rs2_addr)) begin
        forward_b_sel = 2'b01;
    end else if (id_ex_rs2_en && mem_wb_valid && mem_wb_rd_en &&
                 (mem_wb_rd_addr != 5'd0) && (mem_wb_rd_addr == id_ex_rs2_addr)) begin
        forward_b_sel = 2'b10;
    end
end

endmodule
