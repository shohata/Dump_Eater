`timescale 1 ns / 1 ps

`include "rom.v"
`include "hdl/stream_manager.v"
`include "hdl/header_parser.v"
`include "hdl/packet_switch.v"
`include "hdl/crc.v"
`include "hdl/ram_w.v"
`include "hdl/timer.v"
`include "hdl/axis_ff.v"
`include "hdl/axis_fifo.v"

module tb ();
  localparam AXIS_DATA_WIDTH = 512;
  localparam AXIS_TUSER_WIDTH = 256;

  localparam ADDR_WIDTH = 17;
  localparam SHIFT_WIDTH = 128;

  localparam [1:0]                BUF_NONE = 0, BUF_ALL = 1, BUF_STREAM = 3;

  reg                            axis_aclk;
  reg                            axis_resetn;

  // Slave Stream Ports
  wire [AXIS_DATA_WIDTH - 1:0]   s_axis_tdata;
  wire [AXIS_DATA_WIDTH/8 - 1:0] s_axis_tkeep;
  wire [AXIS_TUSER_WIDTH - 1:0]  s_axis_tuser;
  wire                           s_axis_tvalid;
  wire                           s_axis_tready;
  wire                           s_axis_tlast;

  // Master Stream Ports
  wire [AXIS_DATA_WIDTH - 1:0]   m_axis_tdata;
  wire [AXIS_DATA_WIDTH/8 - 1:0] m_axis_tkeep;
  wire [AXIS_TUSER_WIDTH - 1:0]  m_axis_tuser;
  wire                           m_axis_tvalid;
  reg                            m_axis_tready;
  wire                           m_axis_tlast;

  reg  [ADDR_WIDTH - 1:0]        addr = 0, next_addr;

  reg  [SHIFT_WIDTH - 1:0]       valid_shift_reg = {SHIFT_WIDTH{1'b1}};

  wire [AXIS_DATA_WIDTH - 1:0]                    s_axis_buf_tdata;
  wire [AXIS_DATA_WIDTH/8 - 1:0]                  s_axis_buf_tkeep;
  wire [AXIS_TUSER_WIDTH - 1:0]                   s_axis_buf_tuser;
  wire                                            s_axis_buf_tvalid;
  wire                                            s_axis_buf_tready;
  wire                                            s_axis_buf_tlast;

  wire [AXIS_DATA_WIDTH - 1:0]                    m_axis_buf_tdata;
  wire [AXIS_DATA_WIDTH/8 - 1:0]                  m_axis_buf_tkeep;
  wire [AXIS_TUSER_WIDTH - 1:0]                   m_axis_buf_tuser;
  wire                                            m_axis_buf_tvalid;
  wire                                            m_axis_buf_tready;
  wire                                            m_axis_buf_tlast;

  reg                                             migration_progress;
  wire                                            migration_ready;
  reg  [1:0]                                      buffering_type;
  reg  [7:0]                                      buffering_port;


  // Test Module
  // Stream Maneger
  stream_manager #(
    .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
    .AXIS_TUSER_WIDTH (AXIS_TUSER_WIDTH)
  )
  stream_manager_inst (
    .axis_aclk          (axis_aclk  ),
    .axis_resetn        (axis_resetn),
    .s_axis_tdata       (s_axis_tdata ),
    .s_axis_tkeep       (s_axis_tkeep ),
    .s_axis_tuser       (s_axis_tuser ),
    .s_axis_tvalid      (s_axis_tvalid),
    .s_axis_tready      (s_axis_tready),
    .s_axis_tlast       (s_axis_tlast ),
    .m_axis_tdata       (m_axis_tdata ),
    .m_axis_tkeep       (m_axis_tkeep ),
    .m_axis_tuser       (m_axis_tuser ),
    .m_axis_tvalid      (m_axis_tvalid),
    .m_axis_tready      (m_axis_tready),
    .m_axis_tlast       (m_axis_tlast ),
    .s_axis_buf_tdata   (s_axis_buf_tdata ),
    .s_axis_buf_tkeep   (s_axis_buf_tkeep ),
    .s_axis_buf_tuser   (s_axis_buf_tuser ),
    .s_axis_buf_tvalid  (s_axis_buf_tvalid),
    .s_axis_buf_tready  (s_axis_buf_tready),
    .s_axis_buf_tlast   (s_axis_buf_tlast ),
    .m_axis_buf_tdata   (m_axis_buf_tdata ),
    .m_axis_buf_tkeep   (m_axis_buf_tkeep ),
    .m_axis_buf_tuser   (m_axis_buf_tuser ),
    .m_axis_buf_tvalid  (m_axis_buf_tvalid),
    .m_axis_buf_tready  (m_axis_buf_tready),
    .m_axis_buf_tlast   (m_axis_buf_tlast ),
    .migration_progress (migration_progress),
    .migration_ready    (migration_ready   ),
    .buffering_type     (buffering_type    ),
    .buffering_port     (buffering_port    )
  );

  // Buffer
  axis_fifo #(
    .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
    .AXIS_TUSER_WIDTH (AXIS_TUSER_WIDTH),
    .ADDR_WIDTH       (16)
  )
  buffer_inst (
    .aclk         (axis_aclk),
    .resetn       (axis_resetn),
    .write_tdata  (s_axis_buf_tdata ),
    .write_tkeep  (s_axis_buf_tkeep ),
    .write_tuser  (s_axis_buf_tuser ),
    .write_tvalid (s_axis_buf_tvalid),
    .write_tlast  (s_axis_buf_tready),
    .write_tready (s_axis_buf_tlast ),
    .read_tdata   (m_axis_buf_tdata ),
    .read_tkeep   (m_axis_buf_tkeep ),
    .read_tuser   (m_axis_buf_tuser ),
    .read_tvalid  (m_axis_buf_tvalid),
    .read_tlast   (m_axis_buf_tready),
    .read_tready  (m_axis_buf_tlast )
  );


  // Dumped Packet Memory
  rom #(
    .AXIS_DATA_WIDTH  (AXIS_DATA_WIDTH),
    .AXIS_TUSER_WIDTH (AXIS_TUSER_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  )
  rom_inst (
    .clk         (axis_aclk),
    .addr        (next_addr),
    .axis_tdata  (s_axis_tdata),
    .axis_tkeep  (s_axis_tkeep),
    .axis_tuser  (s_axis_tuser),
    .axis_tvalid (s_axis_tvalid),
    .axis_tlast  (s_axis_tlast)
  );


  // 200MHz
  always #2.5 axis_aclk = ~axis_aclk;

  // ROM Address
  always @(posedge axis_aclk) begin
    if (!axis_resetn) begin
      addr <= 0;
    end else begin
      addr <= next_addr;
    end
  end

  always @(*) begin
    if (addr != {ADDR_WIDTH{1'b1}}) begin
      if (s_axis_tready && s_axis_tvalid)
        next_addr = addr + 1;
      else
        next_addr = addr;
    end
  end

  // TVALID Shift Register
  always @(posedge axis_aclk) begin
    if (!axis_resetn) begin
      valid_shift_reg <= {SHIFT_WIDTH{1'b1}};
    end else begin
      valid_shift_reg[SHIFT_WIDTH - 1:1] <= valid_shift_reg[SHIFT_WIDTH - 2:0];
      valid_shift_reg[0] <= s_axis_tvalid;
    end
  end

  // Main
  integer fd;
  initial begin
    fd = $fopen("tb_stream_manager.mem");
    $dumpfile("tb_stream_manager.vcd");
    $dumpvars(0, tb);
    $dumplimit(1000000000);
    axis_aclk <= 1'b0;
    m_axis_tready <= 1'b1;
    $display("[%t] : System Reset Asserted...", $realtime);
    axis_resetn <= 1'b0;
    repeat(2) @(posedge axis_aclk);
    $display("[%t] : System Reset De-asserted...", $realtime);
    axis_resetn <= 1'b1;
    migration_progress <= 1'b1;
    buffering_type <= BUF_STREAM;
    buffering_port <= 8'b00000001;
    forever begin
      @(posedge axis_aclk);
      if (m_axis_tready & m_axis_tvalid) $fdisplay(fd, "%h", m_axis_tdata);
      if (!(|valid_shift_reg)) $finish;
    end
    $fclose(fd);
    $finish;
  end

endmodule
