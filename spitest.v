`define CMD_IDLE     16'hFFFF
`define CMD_BUZZON   16'hDEAD
`define CMD_BUZZOFF  16'hBABE
`define CMD_FIFO_WR  16'h0101
`define CMD_FIFO_RD  16'h0102

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

             output wire buzzer,

	     input wire  fe1_clk,
	     input wire  fe1_data,

	     output wire got_pkt,
	       
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

   /*
   wire 		 clk;
   SB_PLL40_CORE #(
		   .FEEDBACK_PATH("SIMPLE"),
		   .PLLOUT_SELECT("GENCLK"),
		   .DIVR(4'b0000), // 80 mhz into the PD
		   .DIVF(7'b0000111), // 80 * 8 = 640 MHz FVCO, between 533-1066 is valid
		   .DIVQ(3'b100), // x 16 (2^4)
		   .FILTER_RANGE(3'b101) // from icepll -i 80 -o 40
		   ) pllcore (
			      .RESETB(1'b1),
			      .BYPASS(1'b0),
			      .REFERENCECLK(inclk),
			      .PLLOUTCORE(clk)
			      );
   */
   
   assign rst = 1'b0;
//   assign dbg0 = spi_done;

   wire [15:0] 		 spmi_pkt;
   wire 		 pkt_rdy;
   wire 		 ssc_det;
   spmi myspmi(
		 .sysclk(clk),
		 .spmiclkin(fe1_clk),
		 .spmidatin(fe1_data),
		 .reset(rst),
		 .packet(spmi_pkt),
		 .valid(pkt_rdy),
		 .fetched(fifo_we),
//		 .overflow(dbg4),
	         .ssc_det(ssc_det)
		 );
   
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

   reg pkt_rdy_q;
   wire pkt_rising;
   reg 	fifo_full_q;
   wire fifo_full_falling;
   always @(posedge clk) begin
      pkt_rdy_q <= pkt_rdy;
      fifo_full_q <= fifo_full;
   end
   assign pkt_rising = !pkt_rdy_q && pkt_rdy;
   assign fifo_full_falling = fifo_full_q && !fifo_full;
   
   always @(posedge clk) begin
      fifo_re <= done_rising && !fifo_empty;
//      fifo_re <= (done_rising && (spi_addr_cmd == `CMD_FIFO_RD)) && !fifo_empty;
      fifo_we <= (pkt_rising && !fifo_full) || (pkt_rdy && fifo_full_falling);
//      fifo_we <= (done_rising && (spi_addr_cmd == `CMD_FIFO_WR)) && !fifo_full;
   end

   always @(posedge clk) begin
      dbg0 <= fifo_full;
      dbg1 <= got_pkt;
      dbg2 <= fifo_re;
      dbg3 <= fifo_we;
      dbg4 <= ssc_det;
      dbg5 <= pkt_rdy;
   end

   assign got_pkt = !fifo_empty && !ssc_det;

   reg buzz_on;
   always @(posedge clk) begin
      if( spi_addr_cmd == `CMD_BUZZON ) begin
	 buzz_on <= 1'b1;
      end else if( spi_addr_cmd == `CMD_BUZZOFF ) begin
	 buzz_on <= 1'b0;
      end else begin
	 buzz_on <= buzz_on;
      end
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
//	       .wdata(data_from_master),
	       .wdata(spmi_pkt),
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

   assign buzzer = (cnt[25] & cnt[13]) & buzz_on; // 3100 kHz
      
endmodule // blink



