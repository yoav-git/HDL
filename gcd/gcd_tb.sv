/*
----------------------------------------
Binary GCD Algorithm - Test Bench
Authors:	Yoav  
File:	    gcd_tb.sv
Date:       31/05/2022 	
----------------------------------------
*/

module gcd_tb();

	logic resetb;
	logic clk;
	logic [7:0] u;
	logic [7:0] v;

	logic [7:0] res;
	logic ld;
	logic done;

	// DUT (Device Under Test)
	gcd gcd_ins (.resetb(resetb), .clk(clk), .u(u), .v(v), .ld(ld), .res(res), .done(done)); 

	// Generates 100MHz clock	
	initial 
	  begin
		clk = 0;
		forever #5ns clk = ~clk;
	  end

	// Generator
		function void random_values();
			u = $random();
			v = $random();
		endfunction

	// Driver
	initial 
		begin
			{resetb, u, v, ld} = 0;
			#20ns;
			@ (posedge clk);
				resetb = 1;
			#10ns
			$display("============== Test begin ==============\n");
			repeat(100)
				begin
					@ (posedge clk);
						random_values();
						ld = 1;
						@ (posedge clk);
						ld = 0;
					@ (posedge done);
				end
			$display("============== Test End ==============\n");
			$stop();
		end 


	// Golden model
	function logic [7:0] golden_model(logic [7:0] u, logic [7:0] v);
		begin
		
		logic [7:0]temp_gcd;  
		
			while(v) 
				begin
					temp_gcd = v;
					v = u % v;
					u = temp_gcd;
				
				end
			golden_model = temp_gcd;
		end
	endfunction 
	
	// Checker
	function void check_gcd(logic [7:0] u, logic [7:0] v, logic [7:0] res);
		if(u != 8'b0)
			begin
				logic [7:0] exp_result;
				 
				exp_result = golden_model(u, v);
				
				$display("GCD(%d, %d) = %d ", u, v, res);

				if (exp_result != res)
					$error("checker failed: exp_GCD= (%d)", exp_result);
			end
	endfunction
		
	// Monitor
	initial
		forever
			begin
				@(posedge done);
				#0ns;
				check_gcd(u, v, res);
			end

endmodule // gcd_tb