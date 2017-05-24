/*
 * SPI interface for MIPSfpga
 */

module mfp_lcd_spi(
           input                                    clk,
           input                                    i_rst_n,
           input [7 : 0]                            value,
           input [2 : 0]                            ctrl,
           input                                    send,
           
           output    reg                            sdo,
           output                                   sck,
           output    reg                            ce,
           
           output    reg                            sdc,
           output    reg                            sbl,
           output    reg                            o_rst_n
           );

parameter DIV_WIDTH = 16;   // Width counter


reg [DIV_WIDTH - 1:0] counter;
reg [7:0]  data_r;
reg [3:0] bit_count_r;


// register for control signal
always @(posedge clk, negedge i_rst_n)
   if (!i_rst_n) begin

	   sdc     <= 1'b0;
       sbl     <= 1'b0;
	   o_rst_n <= 1'b0;

   end else begin

       sdc     <= ctrl[0];
       sbl     <= ctrl[1];
	   o_rst_n <= ctrl[2];

   end
//   
 

assign sck = (counter[DIV_WIDTH - 1]);


// counter for low frequency spi out
always @(posedge clk, negedge i_rst_n)
   if (!i_rst_n ) begin
	    counter <= {DIV_WIDTH{1'b0}};
   end else if (!ce)
	    counter <= counter + 1'b1;
   else 
	    counter <= {DIV_WIDTH{1'b0}};


// shift register for sending data
always @(posedge clk, negedge i_rst_n)
	if (!i_rst_n) begin

		data_r <= 8'b0;
		sdo <= 1'b0;
		bit_count_r <= 4'b1001;

	end else if (bit_count_r != 4'b1001 && counter == 0) begin
		
		sdo <= data_r[7];
		data_r <= data_r << 1;
		bit_count_r <= bit_count_r + 1'b1;


	end else if (send && ce) begin
	
		data_r <= value; 
		bit_count_r <= 4'b0000;
	
	end
//

//control register for allow data transfer
always @(posedge clk, negedge i_rst_n)
	if (!i_rst_n) begin
		ce <= 1'b1;
	end else if (!send && bit_count_r == 4'b1001)
		ce <= 1'b1;
	else 
		ce <= 1'b0;
//		
		
endmodule
