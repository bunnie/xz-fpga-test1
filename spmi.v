// command frame -- 13 bits
// data/address frame -- 9 bits
// no response frame -- 9/13 bits

module spmi(
	    input wire sysclk,
	    input wire spmiclkin,
	    input wire spmidatin,
	    input wire reset,
	    output wire [15:0] packet,
	    output reg valid,
	    input wire fetched,
	    output reg overflow,
	    output wire ssc_det
	    );

   // assume sysclk is >40MHz
   // spmiclk < 20MHz
   // this allows us to grab spmidat
   
   reg 			ssc;
   reg [3:0] 		ssc_timeout;
   reg 			was_fetched;
   reg 			seen_ssc;

   reg 			spmiclk;
   reg 			spmidat;

   always @(posedge sysclk) begin
      spmiclk <= spmiclkin;
      spmidat <= spmidatin;
   end
   
   always @(posedge sysclk) begin
      if(spmiclk == 1'b1) begin
	 ssc <= 1'b0;
	 ssc_timeout <= 4'b000;
      end else if( (spmidat == 1'b1) && (ssc_timeout >= 4'b0100) ) begin
	 ssc <= 1'b1;
      end else begin
	 if( ssc_timeout < 4'b1111 ) begin
	    ssc_timeout <= ssc_timeout + 4'b001;
	 end
	 ssc <= ssc;
      end

      if( reset ) begin
	 valid <= 1'b0;
	 was_fetched <= 1'b0;
	 overflow <= 1'b0;
	 seen_ssc = 1'b0;
      end else begin
	 if( !was_fetched && (ssc_timeout == 4'b0110) && seen_ssc ) begin
	    rcvd_pkt <= pkt_sr;
	    valid <= 1'b1;
	 end
	 if( fetched ) begin
	    valid <= 1'b0;
	    was_fetched <= 1'b1;
	    seen_ssc <= 1'b0;
	 end
	 if(ssc) begin
	    seen_ssc = 1'b1;
	    if( !was_fetched ) begin
	       overflow <= 1'b1;
	    end else begin
	       overflow <= overflow; // only clears on reset
	    end
	    was_fetched <= 1'b0;
	 end
      end // else: !if( reset )
   end // always @ (posedge sysclk)

   reg ssc_rising;
   reg ssc_d;
   always @(posedge sysclk) begin
      ssc_d <= ssc;
      ssc_rising <= !ssc_d & ssc;
   end
   
   reg [15:0] pkt_sr;
   reg [15:0] rcvd_pkt;
   // 9 = 1001, 13 = 1101
   reg [3:0]  pkt_len;
   always @(posedge spmiclk or posedge ssc_rising) begin
      if( ssc_rising == 1'b1 ) begin
	 pkt_sr <= 16'b0;
	 pkt_len <= 4'b0;
      end else begin
	 pkt_sr[15:0] <= {pkt_sr[14:0],spmidat};
	 pkt_len <= pkt_len + 4'b0001;
      end
   end // always @ (posedge spmiclk or posedge ssc)

   assign packet = {pkt_len[3:1],rcvd_pkt[12:0]};
   assign ssc_det = ssc;
   
endmodule // spmi
