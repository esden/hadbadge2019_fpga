/* vim: set ts=4 sw=4 : */

/* Super inefficient "rainbow" fade generator */

/* We have 33 PDM generators multiplexed into 
 * the RGB led. Each LED has it's own color cycle 
 * generator offset by 1/11 of the cycle.
 *
 * There are WAY better ways of implementing this...
 */

`default_nettype none

module led_mux(
	input clk,
	input rst,
	input [10:0] ledir,
	input [10:0] ledig,
	input [10:0] ledib,
	output [10:0] ledc,
	output [2:0] leda
);
	/* LED Color Mapping
	   LED  0  1  2  3  4  5  6  7  8  9 10
	     R  0  2  0  2  0  2  2  1  1  0  0
	     G  1  1  1  1  1  1  1  0  0  1  1
	     B  2  0  2  0  2  0  0  2  2  2  2
	*/
	/*
	reg [1:0] col_lup [0:5] = {
		0, 1, 2, 0, // 0
		2, 1, 0, 0, // 1
		0, 1, 2, 0, // 2
		2, 1, 0, 0, // 3
		0, 1, 2, 0, // 4
		2, 1, 0, 0, // 5
		2, 1, 0, 0, // 6
		1, 0, 2, 0, // 7
		1, 0, 2, 0, // 8
		0, 1, 2, 0, // 9
		0, 1, 2, 0, // 10
		0, 0, 0, 0, // padding
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	};*/


	/* color exposure timer */
	reg prev_tim;
	reg [10:0] timer;
	reg [1:0] color;
	reg [10:0] led_out_latch;
	always @(posedge clk) begin
		if (rst) begin
			prev_tim = 0;
			timer = 0;
			color = 0;
			led_out_latch = 0;
		end else begin
			timer <= timer + 1;
			prev_tim <= timer[10];
			// Only increment color on hsb flip
			if (prev_tim != timer[10]) begin
				case (color)
					0: color <= 1;
					1: color <= 2;
					2: color <= 0;
				endcase
			end

			// Descramble led colors
			case (color)
				0: begin
					led_out_latch[0] <= ledir[0];
					led_out_latch[1] <= ledib[1];
					led_out_latch[2] <= ledir[2];
					led_out_latch[3] <= ledib[3];
					led_out_latch[4] <= ledir[4];
					led_out_latch[5] <= ledib[5];
					led_out_latch[6] <= ledib[6];
					led_out_latch[7] <= ledig[7];
					led_out_latch[8] <= ledig[8];
					led_out_latch[9] <= ledir[9];
					led_out_latch[10] <= ledir[10];
				end
				1: begin
					led_out_latch[0] <= ledig[0];
					led_out_latch[1] <= ledig[1];
					led_out_latch[2] <= ledig[2];
					led_out_latch[3] <= ledig[3];
					led_out_latch[4] <= ledig[4];
					led_out_latch[5] <= ledig[5];
					led_out_latch[6] <= ledig[6];
					led_out_latch[7] <= ledir[7];
					led_out_latch[8] <= ledir[8];
					led_out_latch[9] <= ledig[9];
					led_out_latch[10] <= ledig[10];
				end
				2: begin
					led_out_latch[0] <= ledib[0];
					led_out_latch[1] <= ledir[1];
					led_out_latch[2] <= ledib[2];
					led_out_latch[3] <= ledir[3];
					led_out_latch[4] <= ledib[4];
					led_out_latch[5] <= ledir[5];
					led_out_latch[6] <= ledir[6];
					led_out_latch[7] <= ledib[7];
					led_out_latch[8] <= ledib[8];
					led_out_latch[9] <= ledib[9];
					led_out_latch[10] <= ledib[10];
				end
			endcase
		end
	end

	assign ledc = led_out_latch;
	assign leda = 3'b001 << color;
endmodule

module led_pdm(
	input clk,
	input rst,
	input [16-1:0] pdm_level,
	output pdm_out
);

	reg [16+1:0] pdm_sigma;
	always @(posedge clk) begin
		if (rst)
			pdm_sigma <= 0;
		else
        	pdm_sigma <= pdm_sigma + {pdm_out, pdm_out, pdm_level};
	end

	assign pdm_out = ~pdm_sigma[16+1];

endmodule

module led_cycler(
	input clk,
	input rst,
	input tick,
	output [2:0] rgb,
);
parameter SOFFSET = 0;
parameter SSTART = 0;

	reg [15:0] red;
	reg [15:0] grn;
	reg [15:0] blu;
	reg [16:0] counter;
	reg [2:0] rgb_s;
	always @(posedge clk) begin
			if (rst) begin
				red <= 0;
				grn <= 0;
				blu <= 0;
				counter <= SOFFSET;
				rgb_s <= SSTART;
			end else if (tick) begin
				case (rgb_s)
					// r0, g-, b+
					0: begin
						if (counter[16] == 0) begin
							red <= 0;
							grn <= grn - 1;
							blu <= blu + 1;
							counter <= counter + 1;
						end else begin
							red <= 0;
							grn <= 0;
							blu <= 16'hFFFF;
							counter <= 0;
							rgb_s <= 1;
						end
					end
					// r+, g0, b-
					1: begin
						if (counter[16] == 0) begin
							red <= red + 1;
							grn <= 0;
							blu <= blu - 1;
							counter <= counter + 1;
						end else begin
							red <= 16'hFFFF;
							grn <= 0;
							blu <= 0;
							counter <= 0;
							rgb_s <= 2;
						end
					end
					// r-, g+, b0
					2: begin
						if (counter[16] == 0) begin
							red <= red - 1;
							grn <= grn + 1;
							blu <= 0;
							counter <= counter + 1;
						end else begin
							red <= 0;
							grn <= 16'hFFFF;
							blu <= 0;
							counter <= 0;
							rgb_s <= 0;
						end
					end
				endcase // state
			end
	end

	wire redo;
	led_pdm led_pdm_red_inst (
		clk,
		rst,
		red,
		redo
	);

	wire grno;
	led_pdm led_pdm_grn_inst (
		clk,
		rst,
		grn,
		grno
	);

	wire bluo;
	led_pdm led_pdm_blu_inst (
		clk,
		rst,
		blu,
		bluo
	);

	assign rgb = {bluo, grno, redo};

endmodule

module top(
	input  clk,
	output [10:0] ledc,
	output [2:0] leda,
);

	reg [24:0] led_vals [10:0]; // 11 LEDs so we need 4 bit

	reg [7:0] rst_cnt = 0;
	reg rst = 1;

	always @(posedge clk) begin
		if (rst_cnt[7] == 0)
			rst_cnt <= rst_cnt + 1;
		else
			rst <= 0;
	end

	reg tick;
	reg [15:0] delay = 16'h0000;
	always @(posedge clk) begin
		if (!delay[8]) begin
			delay <= delay + 1;
			tick <= 0;
		end else begin
			delay <= 16'h0000;
			tick <= 1;
		end
	end

	wire [10:0] lcred;
	wire [10:0] lcgrn;
	wire [10:0] lcblu;

	led_cycler #(
		.SOFFSET(0),
		.SSTART(0)
	) ledcyc0 (
		clk,
		rst,
		tick,
		{lcblu[0], lcred[0], lcgrn[0]}
	);

	led_cycler #(
		.SOFFSET(17873),
		.SSTART(0)
	) ledcyc1 (
		clk,
		rst,
		tick,
		{lcblu[1], lcred[1], lcgrn[1]}
	);

	led_cycler #(
		.SOFFSET(35746),
		.SSTART(0)
	) ledcyc2 (
		clk,
		rst,
		tick,
		{lcblu[2], lcred[2], lcgrn[2]}
	);

	led_cycler #(
		.SOFFSET(53619),
		.SSTART(0)
	) ledcyc3 (
		clk,
		rst,
		tick,
		{lcblu[3], lcred[3], lcgrn[0]}
	);

	led_cycler #(
		.SOFFSET(5957),
		.SSTART(1)
	) ledcyc4 (
		clk,
		rst,
		tick,
		{lcblu[4], lcred[4], lcgrn[4]}
	);

	led_cycler #(
		.SOFFSET(23830),
		.SSTART(1)
	) ledcyc5 (
		clk,
		rst,
		tick,
		{lcblu[5], lcred[5], lcgrn[5]}
	);

	led_cycler #(
		.SOFFSET(41704),
		.SSTART(1)
	) ledcyc6 (
		clk,
		rst,
		tick,
		{lcblu[6], lcred[6], lcgrn[6]}
	);

	led_cycler #(
		.SOFFSET(59577),
		.SSTART(1)
	) ledcyc7 (
		clk,
		rst,
		tick,
		{lcblu[7], lcred[7], lcgrn[7]}
	);

	led_cycler #(
		.SOFFSET(11915),
		.SSTART(2)
	) ledcyc8 (
		clk,
		rst,
		tick,
		{lcblu[8], lcred[8], lcgrn[8]}
	);

	led_cycler #(
		.SOFFSET(29788),
		.SSTART(2)
	) ledcyc9 (
		clk,
		rst,
		tick,
		{lcblu[9], lcred[9], lcgrn[9]}
	);

	led_cycler #(
		.SOFFSET(47661),
		.SSTART(2)
	) ledcyc10 (
		clk,
		rst,
		tick,
		{lcblu[10], lcred[10], lcgrn[10]}
	);

	led_mux led_mux_inst (
		clk,
		rst,
		lcred,
		lcgrn,
		lcblu,
		ledc,
		leda
	);

endmodule // top
