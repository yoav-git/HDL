/*
----------------------------------------
Binary GCD Algorithm
Authors:	Yoav 
File:	    gcd.sv
Date:       31/05/2022 	
----------------------------------------
*/

module gcd(
			input logic clk,
			input logic resetb,
			input logic [7:0]u,
			input logic [7:0]v,
			input logic ld,
			output logic [7:0]res,
			output logic done
			);
	
	// registers:
	logic [7:0]u_reg;		
	logic [7:0]v_reg;
	logic [2:0]shifts_counter_reg;
	// wires:
	logic [7:0]u_wire;
	logic [7:0]v_wire;
	
	
	always_ff @ (posedge clk or negedge resetb)
		if(~resetb)
			begin
				u_reg <= 8'b0;
				v_reg <= 8'b0;
			end
		else if (ld)
			begin
				u_reg <= u;
				v_reg <= v;
			end
		else
			begin
				u_reg <= u_wire;
				v_reg <= v_wire;
			end
			
	always_ff @ (posedge clk or negedge resetb)
		if(~resetb)
			shifts_counter_reg <= 3'b0;
		else if (ld)
			shifts_counter_reg <= 3'b0;
		else if (~(u_reg[0] | v_reg[0])) // both, u and v, are even
			shifts_counter_reg <= shifts_counter_reg + 3'b1;
		
	always_comb
		case({u_reg[0], v_reg[0]}) 
			2'b00 : begin   // both, u and v, are even
				        u_wire = u_reg / 2;
					    v_wire = v_reg / 2;
				    end
			2'b01 : begin   // only u is even
				        u_wire = u_reg / 2;
					    v_wire = v_reg;
				    end
			2'b10 : begin	// only v is even
				        u_wire = u_reg;
					    v_wire = v_reg / 2;
				    end
			2'b11 : begin	// both, u and v, are odd:
						if(u_reg > v_reg)
							begin
								u_wire = u_reg - v_reg;
								v_wire = v_reg;
							end
						else if (u_reg < v_reg)
							begin
								u_wire = u_reg;
								v_wire = v_reg - u_reg;
							end
						else
							begin
								u_wire = u_reg;
								v_wire = v_reg;
							end
				    end
			default : begin  
				         u_wire = 8'b0;
					     v_wire = 8'b0;
				      end
		endcase

	// output
	assign done = (u_reg == v_reg);
	assign res = (done)? u_reg << shifts_counter_reg : 8'b0;
	
endmodule // gcd