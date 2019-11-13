/* vim: set ts=4 sw=4 : */

`default_nettype none

// Attach 7 segment display PMOD to had supercon2019 Badge Pmod port.

module top(
           input  clk,
           output [7:0] pmod
           );

	// Wiring external pins.
	reg [6:0]      seg_pins_n;
	reg            digit_sel;
	assign pmod[6:0] = seg_pins_n;
	assign pmod[7] = digit_sel;

	// counter increments at clk = 8 MHz.
	reg [29:0]     counter;
	wire [3:0]     ones = counter[20+:4];
	wire [3:0]     tens = counter[24+:4];
	wire [2:0]     display_state = counter[2+:3];

	reg [6:0]      ones_segments;
	reg [6:0]      tens_segments;

	digit_to_segments ones2segs(clk, ones, ones_segments);
	digit_to_segments tens2segs(clk, tens, tens_segments);

	always @(posedge clk) begin
		counter <= counter + 1;

		// Switch seg_pins_n off during digit_sel transitions
		// to prevent flicker.  Each digit has 25% duty cycle.
		case (display_state)
		  0, 1: seg_pins_n <= ~ones_segments;
		  2:    seg_pins_n <= ~0;
		  3:    digit_sel <= 0;
		  4, 5: seg_pins_n <= ~tens_segments;
		  6:    seg_pins_n <= ~0;
		  7:    digit_sel <= 1;
		endcase
	end

endmodule // top

// Get the segments to illuminate to display a single hex digit.
// N.B., This is positive logic.  Display needs negative.
module digit_to_segments(input clk,
						   input [3:0] digit,
						   output reg[6:0] segments
						   );
	always @(posedge clk)
	case (digit)
		0: segments <= 7'b0111111;
		1: segments <= 7'b0000110;
		2: segments <= 7'b1011011;
		3: segments <= 7'b1001111;
		4: segments <= 7'b1100110;
		5: segments <= 7'b1101101;
		6: segments <= 7'b1111101;
		7: segments <= 7'b0000111;
		8: segments <= 7'b1111111;
		9: segments <= 7'b1101111;
		4'hA: segments <= 7'b1110111;
		4'hB: segments <= 7'b1111100;
		4'hC: segments <= 7'b0111001;
		4'hD: segments <= 7'b1011110;
		4'hE: segments <= 7'b1111001;
		4'hF: segments <= 7'b1110001;
	endcase

endmodule
