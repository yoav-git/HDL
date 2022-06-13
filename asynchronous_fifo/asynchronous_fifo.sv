/*
----------------------------------------
Asynchronous FIFO
Authors:	Yoav 
File:	    asynchronous_fifo.sv
Date:       13/06/2022 	
----------------------------------------
*/

// clka 80[MHz], Ta = 12.5 [ns]
// clkb 50[MHz], Tb = 20 [ns]

// clka burst of 20 random words

// total write time: 20 * 12.5[ns] = 250[ns]
// fifo synchronizition delay is cycles: 3 * 20[ns] = 60[ns]
// total reads words during writing: (250[ns] - 60[ns]) / 20[ns] = 9 words
// fifo depth* = 20 - 9 = 11
// + 2 unused cells empty & full
// total depth** = 11 + 2 + 6 = 13 cells
// total depth: 16 cells (gray code)

// ------------------------------------------------------
// Double FF Synchronizer
// ------------------------------------------------------
module dff_sync #(WIDTH = 1)(
							 input  logic               clk,
							 input  logic               resetb,
							 input  logic [WIDTH-1:0]   d,
							 output logic [WIDTH-1:0]   q
							 );

	logic [WIDTH-1:0] q1;
	logic [WIDTH-1:0] q2;
	
	always_ff @ (posedge clk or negedge resetb)
		if (~resetb)
		  begin
			q1 <= '0;
			q2 <= '0;
		  end
		else
		  begin
			q1 <= d;
			q2 <= q1;
		  end
	// Output
	assign q = q2;
  
endmodule


// ------------------------------------------------------
// parameter bin to gray
// ------------------------------------------------------
module bin2gray #(parameter WIDTH = 4)
				(
				input logic			[WIDTH - 1:0]bin,
				output logic		[WIDTH - 1:0]gray
				);
	
	assign gray[WIDTH - 1] = bin[WIDTH - 1];
	
	genvar i;
	generate
		for(i = 0; i < WIDTH - 1; i++)
			assign gray[i] = bin[i + 1] ^ bin[i];
	endgenerate
	
endmodule //bin2gray


// ------------------------------------------------------
// parameter gray to bin
// ------------------------------------------------------
module gray2bin #(parameter WIDTH = 4)
				(
				input logic			[WIDTH - 1:0]gray,
				output logic		[WIDTH - 1:0]bin
				);
		
	assign bin[WIDTH - 1] = gray[WIDTH - 1];
	
	genvar i;
	generate
		for(i = WIDTH - 2; i >= 0; i--)
			assign bin[i] = bin[i + 1] ^ gray[i];
	endgenerate

endmodule // gray2bin


// ------------------------------------------------------
// Counter
// ------------------------------------------------------
module counter #(parameter WIDTH = 4, parameter RST = 4'b0)
					(
					input logic			clk,
					input logic			resetb,
					input logic			en,
					output logic		[WIDTH - 1:0]count_bin,
					output logic		[WIDTH - 1:0]count_gray
					);
		
	logic [WIDTH - 1:0]gray_counter;
	logic [WIDTH - 1:0]bin_wire;
	logic [WIDTH - 1:0]bin_inc_wire;
	logic [WIDTH - 1:0]gray_wire;
	
	gray2bin #(.WIDTH(WIDTH)) gray2bin_ins (.gray(gray_counter), .bin(bin_wire));
	bin2gray #(.WIDTH(WIDTH)) bin2gray_ins (.bin(bin_inc_wire), .gray(gray_wire));
	
	assign bin_inc_wire = bin_wire + {{(WIDTH - 1){1'b0}}, 1'b1};
	
	always_ff @ (posedge clk or negedge resetb)
		if(~resetb)
			gray_counter <= RST;
		else if (en)
			gray_counter <= gray_wire;
			
	// Outputs
	// -----------------------------------------------------------
	assign count_gray = gray_counter;
	assign count_bin = bin_wire;
	
endmodule // gray_counter


// ------------------------------------------------------
// asynchronous_fifo
// ------------------------------------------------------
module asynchronous_fifo(
						input logic			clka,
						input logic			clkb,
						input logic			resetb_clka,
						input logic			[7:0]din_clka,
						input logic			wr_en_clka,
						input logic			rd_en_clkb,
						output logic		full_clka,
						output logic		[7:0]dout_clkb,
						output logic		empty_clkb
						);
	
	logic [7:0]memory_reg_clka[15:0];
	
	logic wr_en_wire_clka;
	logic rd_en_wire_clkb;
	
	logic [3:0]wr_ptr_bin_wire_clka;
	logic [3:0]wr_ptr_gray_wire_clka;
	
	logic [3:0]wr_ptr_bin_wire_clkb;
	logic [3:0]wr_ptr_gray_wire_clkb;
	
	logic [3:0]rd_ptr_bin_wire_clkb;
	logic [3:0]rd_ptr_gray_wire_clkb;
	
	logic [3:0]rd_ptr_bin_wire_clka;
	logic [3:0]rd_ptr_gray_wire_clka;
	
	logic resetb_clkb;
	
	// Instantiations
	// -----------------------------------------
	// write ptr gray counter
	counter #(.WIDTH(4), .RST(4'b0)) wr_ptr_counter_clka_ins(.clk(clka), .resetb(resetb_clka),
			.en(wr_en_wire_clka), .count_bin(wr_ptr_bin_wire_clka), .count_gray(wr_ptr_gray_wire_clka));
	// read ptr gray counter
	counter #(.WIDTH(4), .RST(4'b1000)) rd_ptr_counter_clkb_ins(.clk(clkb), .resetb(resetb_clkb),   // 4'b1000 [gray] = 4'b1111 [bin]
			.en(rd_en_wire_clkb), .count_bin(rd_ptr_bin_wire_clkb), .count_gray(rd_ptr_gray_wire_clkb));	
	
	// Synchronizers
	// -----------------------------------------------------------
	// clka to clkb
	dff_sync #(.WIDTH(4)) dff_sync_clka2clkb_ins(.clk(clkb), .resetb(resetb_clkb), .d(wr_ptr_gray_wire_clka), .q(wr_ptr_gray_wire_clkb));
	// clkb to clka
	dff_sync #(.WIDTH(4)) dff_sync_clkb2clka_ins(.clk(clka), .resetb(resetb_clka), .d(rd_ptr_gray_wire_clkb), .q(rd_ptr_gray_wire_clka));
	// reset synchronizer
	dff_sync #(.WIDTH(1)) reset_sync_clka2clkb_ins(.clk(clkb), .resetb(resetb_clka), .d(1'b1), .q(resetb_clkb));
	
	
	// Converters - Gray to Bin
	// -----------------------------------------------------------
	gray2bin #(.WIDTH(4)) gray2bin_read_ptr_clka_ins(.gray(rd_ptr_gray_wire_clka), .bin(rd_ptr_bin_wire_clka));
	gray2bin #(.WIDTH(4)) gray2bin_write_ptr_clkb_ins(.gray(wr_ptr_gray_wire_clkb), .bin(wr_ptr_bin_wire_clkb));
	
	// Memory
	// -----------------------------------------------------------
	always_ff @ (posedge clka)
		if(wr_en_wire_clka)
			memory_reg_clka[wr_ptr_bin_wire_clka] <= din_clka; 
	
	
	// Enables
	// -----------------------------------------------------------
	assign wr_en_wire_clka = wr_en_clka & ~full_clka;
	assign rd_en_wire_clkb = rd_en_clkb & ~empty_clkb;
	
	// Ouputs
	// -----------------------------------------------------------
	assign full_clka = wr_ptr_bin_wire_clka + 4'b1 == rd_ptr_bin_wire_clka;
	assign empty_clkb = rd_ptr_bin_wire_clkb + 4'b1 == wr_ptr_bin_wire_clkb;
	assign dout_clkb = memory_reg_clka[rd_ptr_bin_wire_clkb];
	
endmodule // asynchronous_fifo








