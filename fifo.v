module fifo(
	    input wire clk,
	    input wire we,
	    input wire re,
	    input wire [15:0] wdata,
	    output wire [15:0] rdata,
	    output wire fifo_empty,
	    output wire fifo_full,
	    input wire reset
	    );

   reg [7:0] 	       fifo_rptr;
   reg [7:0] 	       fifo_wptr;
   reg [8:0] 	       fifo_status;
   
   assign fifo_full = (fifo_status[8:0] == 9'b0_1111_1111);
   assign fifo_empty = (fifo_status == 9'b0);

   always @(posedge clk or posedge reset) begin
      if( reset ) begin
	 fifo_wptr <= 0;
      end else if ( we ) begin
	 fifo_wptr <= fifo_wptr + 8'b1;
      end
   end

   always @(posedge clk or posedge reset) begin
      if( reset ) begin
	 fifo_rptr <= 0;
      end else if( re ) begin
	 fifo_rptr <= fifo_rptr + 8'b1;
      end
   end

   always @(posedge clk or posedge reset) begin
      if( reset ) begin
	 fifo_status <= 0;
      end else if( re && !we && (fifo_status != 0) ) begin
	 fifo_status <= fifo_status - 1;
      end else if( we && !re && (fifo_status != 9'b0_1111_1111) ) begin
	 fifo_status <= fifo_status + 1;
      end
   end
   

   SB_RAM40_4K #(
		 .READ_MODE(0),
		 .WRITE_MODE(0),
		 ) fiforam40 (
			      .RDATA( rdata ),
			      .RADDR( fifo_rptr ),
			      .RCLK( clk ),
			      .RCLKE( 1'b1 ),
			      .RE( re ),

			      .WADDR( fifo_wptr ),
			      .WCLK( clk ),
			      .WCLKE( 1'b1 ),
			      .WDATA( wdata ),
			      .WE( we )
			      );
   
endmodule // fifo
