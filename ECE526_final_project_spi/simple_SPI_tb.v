`timescale 1 ms /1 ms

module simple_spi_tb();

	parameter bits = 16;

	reg sys_clk;
	reg t_begin;
	reg [bits-1:0] data_in;
	wire [bits-1:0] data_out;
	reg [bits:0] t_size;
	wire cs;
	reg rst;
	wire spi_clk;
	wire miso;
	wire mosi;

	simple_spi
	#(
		.reg_width(bits)
	) spi
	(
		.sys_clk(sys_clk),
		.t_begin(t_begin),
		.data_in(data_in),
		.data_out(data_out),
		.t_size(t_size),
		.cs(cs),
		.rst(rst),
		.spi_clk(spi_clk),
		.miso(miso),
		.mosi(mosi)
	);

	assign miso = mosi;
	always
		#2 sys_clk = ~sys_clk;
	
	initial
	begin
		$vcdpluson;
		sys_clk = 0;
		t_begin = 0;
		data_in = 0;
		rst = 0;
		t_size = bits;
		#4;
		rst = 1;
	end

	
	integer i;
	task transact_test;
		input [bits-1:0] d;
		begin
			$vcdpluson;
			data_in = d[bits-1:0];
			#3 t_begin = 1;
			#4 t_begin = 0;
			for( i=0; i < bits; i=i+1)
			begin
				#4;
			end
			#16;
		end
	endtask	

	initial
	begin
		$vcdpluson;
		#10;
		transact_test( {1'b0, 4'h00EE} );
		$finish;
	end
	
endmodule
