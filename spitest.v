`define CMD_IDLE  16'hFFFF
`define CMD_FIFO_WR  16'h101
`define CMD_FIFO_RD  16'h102

module spitest(
	     input wire  clk,
	     output wire clk_oe,

	     input wire  sclk,
	     input wire  ss,
	     input wire  mosi,
	     output wire miso,

	     output wire dbg0,
	     output wire dbg1,
	     output wire dbg2,
	     output wire dbg3,
	     output wire dbg4,
	     output wire dbg5,
	       
	     output wire blink
	     );
   
   wire 		 spi_done;
   wire 		 done_rising;
   reg 			 spi_done_q;
   reg [15:0] 		 spi_addr_cmd;
   reg 			 spi_state;
   wire [15:0] 		 data_to_master;
   wire [15:0] 		 data_from_master;
   wire [15:0] 		 fifo_rdata;

   wire 		 rst;
   reg 			 fifo_re;
   reg 			 fifo_we;
   wire 		 fifo_empty;
   wire 		 fifo_full;

   reg 			 dbg0;
   reg 			 dbg1;
   reg 			 dbg2;
   reg 			 dbg3;
   reg 			 dbg4;
   reg 			 dbg5;

   assign rst = 1'b0;
   assign dbg0 = spi_done;
   
   always @(posedge clk) begin
      if( ss == 1'b1 ) begin // put spi in reset state
	 spi_state <= 1'b0;
	 spi_addr_cmd <= `CMD_IDLE; 
      end else begin
	 if( (spi_state == 1'b0) && spi_done && (ss == 1'b0) ) begin
	    spi_state <= 1'b1;
	    spi_addr_cmd <= data_from_master;
	 end
      end
   end
   
   spi_slave spislave(
		      .clk(clk),  // 80 MHz
		      
		      .sck(sclk), // oversampling 2MHz or so?
		      .rst(rst),
		      .ss(ss),
		      .mosi(mosi),
		      .miso(miso),

		      .done(spi_done),

		      .din(data_to_master),
		      .dout(data_from_master));

   always @(posedge clk) begin
      spi_done_q <= spi_done;
   end
   assign done_rising = !spi_done_q && spi_done;

   always @(posedge clk) begin
      fifo_re <= (done_rising && (spi_addr_cmd == `CMD_FIFO_RD)) && !fifo_empty;
      fifo_we <= (done_rising && (spi_addr_cmd == `CMD_FIFO_WR)) && !fifo_full;
   end

   always @(posedge clk) begin
      dbg1 <= (spi_addr_cmd == `CMD_FIFO_WR);
      dbg2 <= (spi_addr_cmd == `CMD_FIFO_RD);
      dbg3 <= data_from_master[0];
      dbg4 <= data_from_master[1];
      dbg5 <= data_from_master[2];
   end

   /*
   always @(*) begin
      case( spi_addr_cmd ) 
	 `CMD_FIFO_RD: data_to_master = fifo_rdata;
	 default: data_to_master = 16'hdead;
      endcase // case ( spi_addr_cmd )
   end
    */
 
   fifo myfifo(
	       .clk(clk),
	       .we(fifo_we),
	       .re(fifo_re),
	       .wdata(data_from_master),
//	       .rdata(fifo_rdata),
	       .rdata(data_to_master),
	       .reset(rst),
	       .fifo_empty(fifo_empty),
	       .fifo_full(fifo_full)
	       );
   
   
   reg [25:0] 		 cnt;
   
   always @(posedge clk) begin
      cnt <= cnt + 1;
   end

   assign blink = cnt[25];

   assign clk_oe = 1'b1;
   
endmodule // blink



