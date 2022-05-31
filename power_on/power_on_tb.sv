/*
----------------------------------------
Power on Test Bench
Authors:	Yoav 
File:	    power_on_tb.sv
Date:       31/05/2022 	
----------------------------------------
*/

module power_on_tb();

	logic resetb;
	logic clk;
	logic power_good;
	logic enable;

	time start_time;


	// DUT
	power_on power_on_ins(.clk(clk), .resetb(resetb), .power_good(power_good), .enable(enable));
	
	// Clock generator - 100[MHz]
	initial 
	  begin
		clk = 0;
		forever #5ns clk = !clk;
	  end
	
	task power_on_inputs();
		#10ns;
		@ (posedge clk)
			power_good = 1;
		#50ns;
		@ (posedge clk)
			power_good = 0;
		#50ns;
		@ (posedge clk)
			power_good = 1;
	endtask
	
	// initials
	initial 
	  begin
		{resetb, power_good} = 0;
		#20ns;
		@(posedge clk);
			resetb = 1;
		
		power_on_inputs();
	end	
		
	initial
		forever
			begin
				@(posedge power_good);
				start_time = $time;
				fork : my_fork
					begin
						#300ns;
					end
					begin
						@(enable)
						$error("Enable rise less then 300ns");
					end
					begin
						@(negedge power_good);
					end
				join_any
				disable my_fork;
			end
	
	always @ (posedge enable)
		begin
			$display ("The delay between power_good and enable is %d [ps]", ($time - start_time));
		end
			
endmodule