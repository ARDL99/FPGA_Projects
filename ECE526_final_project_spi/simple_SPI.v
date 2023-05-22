`timescale 1 ms /1 ms

/// SPI
module simple_spi
#(
	parameter reg_width = 8,
	parameter counter_width = $clog2(reg_width)
)
(
	// System side
	input rst,
	input sys_clk,
	input t_begin,
	input [reg_width-1:0] data_in,
	input [counter_width:0] t_size,
	output reg [reg_width-1:0] data_out,

	// SPI side
	input miso,
	output wire mosi,
	output wire spi_clk,
	output reg cs
);
	parameter reset = 0, idle = 1, load = 2, transact = 3, unload = 4;

	reg [reg_width-1:0] mosi_d;
	reg [reg_width-1:0] miso_d;
	reg [counter_width:0] count;
	reg [2:0] state;

	// begin state machine
	always @(state)
	begin
		case (state)
			reset:
			begin
				data_out <= 0;
				miso_d <= 0;
				mosi_d <= 0;
				count <= 0;
				cs <= 1;
			end

			idle:
			begin
				data_out <= data_out;
				miso_d <= 0;
				mosi_d <= 0;
				count <= 0;
				cs <= 1;
			end

			load:
			begin
				data_out <= data_out;
				miso_d <= 0;
				mosi_d <= data_in;
				count <= t_size;
				cs <= 0;
			end

			transact:
			begin
				cs <= 0;
			end

			unload:
			begin
				data_out <= miso_d;
				miso_d <= 0;
				mosi_d <= 0;
				count <= count;
				cs <= 0;
			end

			default:
				state = reset;
		endcase
	end
	
	always @(posedge sys_clk)
	begin
		if (!rst)
			state = reset;
		else
			case (state)
				reset:
					if (t_begin)
						state = load;
					else
						state = idle;
				idle:
					if (t_begin)
						state = load;
				load:
					if (count != 0)
						state = transact;
					else
						state = reset;
				transact:
					if (count != 0)
						state = transact;
					else
						state = unload;
				unload:
					if (t_begin)
						state = load;
					else
						state = idle;
			endcase
	end
	// end state machine

	// begin SPI logic

	assign mosi = ( ~cs ) ? mosi_d[reg_width-1] : 1'bz;
	assign spi_clk = ( state == transact ) ? sys_clk : 1'b0;
	
	// Shift Data
	always @(posedge spi_clk)
	begin
		if ( state == transact )
			miso_d <= {miso_d[reg_width-2:0], miso};
	end

	always @(negedge spi_clk)
	begin
		if ( state == transact )
		begin
			mosi_d <= {mosi_d[reg_width-2:0], 1'b0};
			count <= count-1;
		end
	end
	// end SPI logic

endmodule
