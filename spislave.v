module spi_slave(
		     input clk,
		     input rst,
		     input ss,
		     input mosi,
		     output miso,
		     input sck,
		     output done,
		     input [15:0] din,
		     output [15:0] dout
		 );

   reg [15:0] 			  sr;
   reg [15:0] 			  sr_in;
   reg [15:0] 			  data_out;
   reg [3:0] 			  bit_cnt;
   reg 				  sck_d;
   reg 				  sck_d2;
   reg 				  ss_d;
   reg 				  ss_d2;
   reg 				  miso_q;
   reg 				  done;

   always @(posedge clk) begin
      sck_d <= sck;
      sck_d2 <= sck_d;
      ss_d <= ss;
      ss_d2 <= ss_d;
      if( ss_d ) begin
	 bit_cnt <= 4'b0;
	 done <= 1'b0;
	 sr <= din;
      end else if( !ss_d & ss_d2 ) begin // falling edge CS
	 sr <= din;
	 bit_cnt <= 4'b0;
	 done <= 1'b0;
	 miso_q <= din[15];
      end else begin
	 if( sck_d & !sck_d2 ) begin // rising edge SCK
	    sr_in[15:0] <= {sr_in[14:0], mosi};
	    sr <= {sr[14:0], mosi};
	    bit_cnt <= bit_cnt + 1;
	    if( bit_cnt == 4'b1111 ) begin
	       done <= 1'b1;
	       data_out[15:0] <= {sr_in[14:0], mosi};
	    end else begin
	       done <= 1'b0;
	    end
	 end else if( !sck_d & sck_d2 ) begin // falling edge SCK
	    done <= 1'b0;
	    if( bit_cnt == 4'b0000 ) begin
	       sr <= din;
	       miso_q <= din[15];
	    end else begin
	       sr <= sr;
	       miso_q <= sr[15];
	    end
	 end
      end
   end // always @ (posedge clk)
   assign miso = miso_q;
   assign dout[15:0] = data_out[15:0];

endmodule // spi_slave

