/*
----------------------------------------
Power on
Authors:	Yoav 
File:	    power_on.sv
Date:       31/05/2022 	
----------------------------------------
*/
module power_on(
				input logic resetb,
				input logic clk,
				input power_good,
				output logic enable
				);
	// clock frequancy: 100 [MHz]
	
	parameter logic[4:0] END_COUNT = 5'b11110; // (30 DEC) 
	logic [4:0]counter_reg;
	

	always_ff @ (posedge clk or negedge resetb)
		if(~resetb)
			counter_reg <= 5'b0;
		else if (power_good)
			counter_reg <= counter_reg + {4'b0, ~enable};
		else
			counter_reg <= 5'b0;
		
	assign enable = (counter_reg == END_COUNT); // 300 [ns]
			
endmodule