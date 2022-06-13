/*
----------------------------------------
Asynchronous FIFO Test Bench
Authors:	Yoav 
File:	    asynchronous_fifo_tb.sv
Date:       13/06/2022 	
----------------------------------------
*/

module asynchronous_fifo_tb();

	logic		clka;
	logic		resetb_clka;
	logic		clkb;
	logic		[7:0]din_clka;
	logic		wr_en_clka;
	logic		full_clka;
	logic		rd_en_clkb;
	logic		[7:0]dout_clkb;
	logic		empty_clkb;
	
	integer queue[$];	// Queue declaration
	

	// ---------------------------------------------
	// clock's
	// ---------------------------------------------
	// clka 80 [MHz]
	always
		begin
			#6.25ns;
			clka = ~clka;
		end
		
	// clkb 50 [MHz]	
	always
		begin
			#10ns;
			clkb = ~clkb;
		end
		
		
	// ---------------------------------------------			 
	// DUT Asynchronous FIFO 
	// ---------------------------------------------
	asynchronous_fifo async_fifo_ins(.clka(clka), .resetb_clka(resetb_clka), .din_clka(din_clka),
	.wr_en_clka(wr_en_clka), .full_clka(full_clka), .clkb(clkb), .rd_en_clkb(~empty_clkb),
	.dout_clkb(dout_clkb), .empty_clkb(empty_clkb));
	
	
	// -----------------------------------------------------------	
	// Driver
	// -----------------------------------------------------------
	task stream_words(int burst_size);
		for(int i = 0; i < burst_size; i++)
			begin
				if(full_clka)
					begin
						$error("FIFO depth no fit to the burst");	
						$stop();
					end
				@ (posedge clka)
				wr_en_clka = 1;
				din_clka = $random();
			end
			
		@ (posedge clka)
		wr_en_clka = 0;
	endtask
	
	initial
		begin
			{clka, resetb_clka, clkb} = 0;
			{din_clka, wr_en_clka, full_clka, rd_en_clkb, dout_clkb, empty_clkb} = 0;
			#20ns;
			@(posedge clka);
			resetb_clka = 1;
			
			#100ns;
			$display("----------------------------");
			$display("Asynchronous FIFO Test Bench");
			$display("----------------------------");
			$display("----------- Begin ----------");
			stream_words(20);
		end
			
			
	// -----------------------------------------------------------	
	// Monitor
	// -----------------------------------------------------------
	initial
		forever
			begin
				@(din_clka);
				queue.push_back(din_clka);
			end

	initial
		forever
			begin
				@(dout_clkb);
				#0;
				check_sync(dout_clkb, queue.pop_front());
			end


	// -----------------------------------------------------------	
	// Checker
	// -----------------------------------------------------------
	function void check_sync(logic [7:0] dout_clkb, logic [7:0] data);
		$display("doute=%d, expected value=%d", dout_clkb, data);

		if (dout_clkb != data)
			$error("checker failed\n");	
	endfunction
	
endmodule // asynchronous_fifo_tb