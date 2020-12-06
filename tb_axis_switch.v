`timescale 1 ns / 1 ps

`include "rom.v"
`include "hdl/axis_switch.v"
`include "hdl/axis_lut_fifo.v"
`include "hdl/lutram_w.v"

module tb ();
  localparam AXIS_DATA_WIDTH = 512;
  localparam AXIS_TUSER_WIDTH = 256;

  localparam ADDR_WIDTH = 17;
  localparam SHIFT_WIDTH = 128;

  reg                            axis_aclk;
  reg                            axis_resetn;

  // Slave Stream Ports
  wire [AXIS_DATA_WIDTH*2 - 1:0]   s_axis_tdata;
  wire [AXIS_DATA_WIDTH/8*2 - 1:0] s_axis_tkeep;
  wire [AXIS_TUSER_WIDTH*2 - 1:0]  s_axis_tuser;
  wire [1:0]                       s_axis_tvalid;
  wire [1:0]                       s_axis_tready;
  wire [1:0]                       s_axis_tlast;

  // Master Stream Ports
  wire [AXIS_DATA_WIDTH - 1:0]   m_axis_tdata;
  wire [AXIS_DATA_WIDTH/8 - 1:0] m_axis_tkeep;
  wire [AXIS_TUSER_WIDTH - 1:0]  m_axis_tuser;
  wire                           m_axis_tvalid;
  reg                            m_axis_tready;
  wire                           m_axis_tlast;

  reg  [ADDR_WIDTH - 1:0]        addr[1:0], next_addr[1:0];

  reg  [SHIFT_WIDTH - 1:0]       valid_shift_reg = {SHIFT_WIDTH{1'b1}};


  initial begin
    addr[1] = 0;
    addr[0] = 0;
  end

  // Test Module
  axis_switch #(
    .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
    .AXIS_TUSER_WIDTH (AXIS_TUSER_WIDTH),
    .ADDR_WIDTH       (6),
    .S_INTF_NUM       (2)
  )
  axis_switch_inst (
    .aclk     (axis_aclk),
    .aresetn  (axis_resetn),

    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tkeep  (s_axis_tkeep),
    .s_axis_tuser  (s_axis_tuser),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .s_axis_tlast  (s_axis_tlast),

    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tkeep  (m_axis_tkeep),
    .m_axis_tuser  (m_axis_tuser),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tlast  (m_axis_tlast)
  );

  // Dumped Packet Memory
  genvar i;
  generate
  for (i = 0; i < 2; i = i + 1) begin: GenRom

    rom #(
      .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
      .AXIS_TUSER_WIDTH (AXIS_TUSER_WIDTH),
      .ADDR_WIDTH       (ADDR_WIDTH)
    )
    rom_inst (
      .clk         (axis_aclk),
      .addr        (next_addr[i]),
      .axis_tdata  (s_axis_tdata [i*AXIS_DATA_WIDTH +: AXIS_DATA_WIDTH]),
      .axis_tkeep  (s_axis_tkeep [i*AXIS_DATA_WIDTH/8 +: AXIS_DATA_WIDTH/8]),
      .axis_tuser  (s_axis_tuser [i*AXIS_TUSER_WIDTH +: AXIS_TUSER_WIDTH]),
      .axis_tvalid (s_axis_tvalid[i]),
      .axis_tlast  (s_axis_tlast [i])
    );

  end
  endgenerate


  // 200MHz
  always #2.5 axis_aclk = ~axis_aclk;

  // ROM Address
  initial begin
    addr[0] = 0;
    addr[1] = 0;
  end

  generate
  for (i = 0; i < 2; i = i + 1) begin: GenAddr

    always @(posedge axis_aclk) begin
      if (!axis_resetn) begin
        addr[i] <= 0;
      end else begin
        addr[i] <= next_addr[i];
      end
    end

    always @(*) begin
      if (addr[i] != {ADDR_WIDTH{1'b1}}) begin
        if (s_axis_tready[i] && s_axis_tvalid[i])
          next_addr[i] = addr[i] + 1;
        else
          next_addr[i] = addr[i];
      end
    end

  end
  endgenerate

  // TVALID Shift Register
  always @(posedge axis_aclk) begin
    if (!axis_resetn) begin
      valid_shift_reg <= {SHIFT_WIDTH{1'b1}};
    end else begin
      valid_shift_reg[SHIFT_WIDTH - 1:1] <= valid_shift_reg[SHIFT_WIDTH - 2:0];
      valid_shift_reg[0] <= s_axis_tvalid[0];
    end
  end

  // Main
  integer fd;
  initial begin
    fd = $fopen("tb_axis_switch.mem");
    $dumpfile("tb_axis_switch.vcd");
    $dumpvars(0, tb);
    $dumplimit(1000000000);
    axis_aclk <= 1'b0;
    m_axis_tready <= 1'b1;
    $display("[%t] : System Reset Asserted...", $realtime);
    axis_resetn <= 1'b0;
    repeat(2) @(posedge axis_aclk);
    $display("[%t] : System Reset De-asserted...", $realtime);
    axis_resetn <= 1'b1;
    forever begin
      @(posedge axis_aclk);
      if (m_axis_tready & m_axis_tvalid) $fdisplay(fd, "%h", m_axis_tdata);
      if (!(|valid_shift_reg)) $finish;
    end
    $fclose(fd);
    $finish;
  end

endmodule
