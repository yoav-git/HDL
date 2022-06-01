/*
----------------------------------------
Sinus Generator Test Bench
Author:	Yoav	   
File:	sin_gen_tb.sv
Date:	01/06/2022 	
----------------------------------------
*/

module sin_gen_tb();

	logic resetb;
	logic clk;
	logic en;
	logic [7:0]period_sel;
	logic [8:0]sin_out;
	shortreal temp;

	// DUT (Device Under Test)
	sin_gen sin_gen_ins (.resetb(resetb), .clk(clk), .en(en), .period_sel(period_sel), .sin_out(sin_out)); 

	// Generates ~512MHz clock	
	always
		begin
			#1.95ns;  
			clk = ~clk;
		end 

	initial
		begin
			{clk, resetb, en, period_sel} = 0; 
			#10ns;
			@(posedge clk)
				resetb = 1;
			#20ns;
			
			drive_inputs();	

			$stop();
		end
		
	function shortreal sin_delay(logic [7:0]period_sel);
		sin_delay = (1024) * 3.9 * (period_sel + 1)*1000;
	endfunction

	// Driver
	task automatic drive_inputs();
	
		// Test 1 - period_sel = 0;
		@(posedge clk)
			period_sel = 0;
			en = 1;
		@(posedge clk)
			en = 0;
		temp = sin_delay(period_sel);
		#temp;
		
		// Test 2 - period_sel = random;
		@(posedge clk)
			period_sel = $random;
			en = 1;
		@(posedge clk)
			en = 0;
		
		temp = sin_delay(period_sel);
		#temp;	
		
		#10000ns;
		
		// Test 3 - period_sel = 2, en = 1 during sin, and change frequency
		@(posedge clk)
			period_sel = 2;
			en = 1;
		@(posedge clk)
			en = 0;
			
		temp = 0.5 * sin_delay(period_sel);
		#temp;	
		
		@(posedge clk)
			period_sel = $random;
			en = 1;
		@(posedge clk)
			en = 0;
		#temp;
		
	endtask
endmodule // sin_gen_tb