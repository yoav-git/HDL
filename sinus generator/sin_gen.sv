/*
----------------------------------------
Sinus Generator
Author:	Yoav   
File:	sin_gen.sv
Date:	01/06/2022 	
----------------------------------------
*/
module sin_gen(input logic clk,
			   input logic resetb,
			   input logic en,
			   input logic [7:0]period_sel,
			   output logic [8:0]sin_out		
			   );
		
	logic [7:0]freq_counter;
	logic freq_flag;
	logic count_up;
	
	logic [7:0]address;
	logic end_count;

	logic [7:0]dout;
	logic [7:0]frequency;

	// ---- states machine setup ----
	typedef enum logic[2:0]{
							INIT = 3'b000, 	// default
							S0   = 3'b001, 	// 
							S1   = 3'b010, 	// 
							S2   = 3'b011, 	// 
							S3   = 3'b100 	// 
							} sin_states;			
	sin_states cs, ns;

	always_ff @(posedge clk or negedge resetb)
		if(~resetb)
			cs <= INIT;
		else
			cs <= ns;
	/*         
           ..    
	   S0 .  . S1         +
   INIT__.____.____._______
	        S2 .  . S3    
		        ..        -	   
	*/
	
	always_comb
		case(cs)
			INIT : ns = en?        S0   : INIT;
			S0   : ns = end_count? S1   : S0;
			S1   : ns = end_count? S2   : S1;
			S2   : ns = end_count? S3   : S2;
			S3   : ns = end_count? (en? S0 : INIT) : S3;
			default : ns = INIT;
		endcase
	// ---- end of states machine setup ----
	
	// instance of sin LUT 
	sin_lut sin_lut_ins (.address(address), .dout(dout));

	
	// ---- frequency control ----
	assign freq_flag = freq_counter == frequency;
	
	always_ff @(posedge clk or negedge resetb)
		if(~resetb)
			freq_counter <= 8'b0;
		else if (cs == INIT | (cs != S0 & ns == S0))
			freq_counter <= 8'b0;
		else if(freq_flag)
			freq_counter <= 8'b0;
		else // enable count	
			freq_counter <= freq_counter + 8'b1;

	always_ff@(posedge clk or negedge resetb)
		if(~resetb)
			frequency <= 8'b0;
		else if (cs != S0 & ns == S0) // sin end
			frequency <= period_sel;
	// ---- end of frequency control ----
	
	// ---- sin LUT address ----
	assign count_up  = (cs == S0 | cs == S2);
	assign end_count = count_up? (address == 8'b1111_1111) : (address == 8'b0); 
	
	always_ff @(posedge clk or negedge resetb)
		if(~resetb)
			address <= 8'b0;
		else if(freq_flag & ~end_count)
			if(count_up)
				address <= address + 8'b1;
			else
				address <= address - 8'b1;	
	// ---- end of sin LUT address ----	
	
	// output                                  Posetive   :    Negative
	assign sin_out = (cs == S0 | cs == S1)?  {1'b0, dout} : (~dout + 9'b1);
			
endmodule // sin_gin