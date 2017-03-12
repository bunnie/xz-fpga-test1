`timescale 1ns / 1ps

module test_spmi;
   
   reg sysclk;
   reg spmiclk;
   reg spmidat;
   reg reset;
   reg fetched;

   parameter PERIOD_SYSCLK = 12.5;
   parameter PERIOD_SPMICLK = 45;

   always begin
      sysclk = 1'b0;
      #(PERIOD_SYSCLK/2) sysclk = 1'b1;
      #(PERIOD_SYSCLK/2);
   end

   spmi spmi_dut(
		 .sysclk(sysclk),
		 .spmiclk(spmiclk),
		 .spmidat(spmidat),
		 .reset(reset),
		 .packet(packet),
		 .valid(valid),
		 .fetched(fetched),
		 .overflow(overflow)
		 );

   integer i;
   integer dat;
   
   initial begin
      spmidat = 1'b0;
      spmiclk = 1'b0;
      reset = 1'b1;
      
      #(PERIOD_SYSCLK * 10);
      reset = 1'b0;
      #(PERIOD_SYSCLK * 50);
      

      // SSC
      spmidat = 1'b1;
      #(PERIOD_SPMICLK);
      spmidat = 1'b0;
      #(PERIOD_SPMICLK);

      // data
      dat = 13'h2F5;
      for( i = 0; i < 13; i = i + 1 ) begin
	 spmiclk = 1'b0;
	 spmidat = dat & 13'b1_0000_0000_0000 ? 1'b1 : 1'b0;
	 dat = dat << 1;
	 #(PERIOD_SPMICLK/2) spmiclk = 1'b1;
	 #(PERIOD_SPMICLK/2);
      end

      #(PERIOD_SYSCLK * 50);
      
      // SSC
      spmidat = 1'b1;
      #(PERIOD_SPMICLK);
      spmidat = 1'b0;
      #(PERIOD_SPMICLK);

      // data
      dat = 13'h1A05;
      for( i = 0; i < 13; i = i + 1 ) begin
	 spmiclk = 1'b0;
	 spmidat = dat & 13'b1_0000_0000_0000 ? 1'b1 : 1'b0;
	 dat = dat << 1;
	 #(PERIOD_SPMICLK/2) spmiclk = 1'b1;
	 #(PERIOD_SPMICLK/2);
      end

      #(PERIOD_SYSCLK * 50);
   end
   

endmodule // test_spmi
