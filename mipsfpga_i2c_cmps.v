`timescale 1ns / 1 ps


module i2c_cmps (
					input  wire	       clk,
					input  wire	       i_reset_n,
					input  wire        start,
					input  wire  [7:0] i_data,
					
					
					output reg   [7:0] o_data,
					output wire        o_data_ready,
					output wire        ready,  
					inout  wire	       io_sda,
					inout  wire	       io_scl
                );

parameter DELAY = 1000;

localparam  STATE_IDLE  =   0,
            STATE_START =   1,
            STATE_WRITE =   2,
            STATE_WACK  =   3,
	        STATE_READ  =   4,
            STATE_WACK2 =   5,
            STATE_STOP  =   6;
            

reg [7:0] state;
reg [7:0] count;
reg       i2c_scl_enable;
reg       rw_r;
reg       error_r;

reg [7:0] saved_i_data;

reg sda_ctrl;
wire scl_ctrl;

wire i2c_clk;
wire sda_in;

i2c_clk_divider #(.DELAY(DELAY)) i2c_clk_divider_inst  (
    
                                            .i_reset_n(i_reset_n),
                                            .ref_clk(clk),
                                            .i2c_clk(i2c_clk)
                                            
                                        );

assign io_sda = sda_ctrl ? 1'bz : 1'b0;
assign sda_in = io_sda;

assign io_scl = scl_ctrl ? 1'bz : 1'b0;

assign scl_ctrl = (i2c_scl_enable == 0) ? 1 : ~i2c_clk;
assign ready = ((i_reset_n == 1) && (state == STATE_IDLE || state == STATE_WACK || state == STATE_WACK2)) ? 1 : 0;
assign o_data_ready = (state == STATE_WACK2 && count ==0) ? 1 : 0;


always @(posedge i2c_clk, negedge i_reset_n) begin    
    if (i_reset_n == 0) begin
        i2c_scl_enable <= 0;
end else begin
    if (state == STATE_IDLE || state == STATE_START) begin 
       i2c_scl_enable <= 0;
    end
    else begin
            i2c_scl_enable <= 1;
        end
    end
end



always @(posedge i2c_clk, negedge i_reset_n) begin
    if (i_reset_n == 0) begin
        
        state <= STATE_IDLE;
        sda_ctrl <= 1;
        count <= 8'd0;
	    saved_i_data <= 8'b0;
        o_data       <= 8'b0;
	    rw_r         <= 0;
	    error_r      <= 0;

    end
    else begin
        case (state)
            
STATE_IDLE: //0
            
                begin // idle state
                
                    sda_ctrl <= 1;
                        
                        if (start) begin
                            
                            state <= STATE_START;
                            saved_i_data <= i_data;
                            rw_r <= i_data[0];
                            count <= 7;

                        end else 
       
                        state   <= STATE_IDLE;
                end // end idle state
        


STATE_START: //1
                begin // rw state
                    
                    sda_ctrl <= 0;
                    count <= 7;
                    state <= STATE_WRITE;
                
                end
                

                
STATE_WRITE: //2
                
                begin // data state
    
                          sda_ctrl <= saved_i_data[count];
                          if (count == 0) begin
                          state <= STATE_WACK;
                          end else count <= count - 1;               
      
                end // end data state
                
        
STATE_WACK: //3
                begin // wack states
                
                    sda_ctrl <= 1;
                    
                    if (sda_in) begin
                                                
                        error_r <= 1'b1;
                        state <= STATE_WRITE;
                        count <= 7;
                               
                    end else
                                              
                        error_r <= 1'b0;
                        
                        if(rw_r) begin
                            
                            state <= STATE_READ;
                            count <= 8;
                                                        
                        end else 
                        
                        if (start) begin
                            
                            saved_i_data <= i_data;                            
                            state <= STATE_WRITE;
                            count <= 7;
                                                                                    
                        end else 
                                                                                        
                            state <= STATE_STOP;                        
                    
                end




STATE_READ: //4
            if (count == 8) begin
            
                sda_ctrl <= 1;
                count <= count - 1;
                state <= STATE_READ;
                
            end else begin // read_data state
                
                sda_ctrl <= 1;
                o_data[count] <= io_sda;
               
                if (count == 0) begin
                    
                    sda_ctrl <= 1'b0;
                
                if (start)
                    state <= STATE_WACK2;
                else begin
                    sda_ctrl <= 1'b1;
                    state <= STATE_STOP;
                end end else begin
                
                    count <= count - 1;               
                                                              // write STATE_READ
                end
            end // end read_data state



STATE_WACK2: begin// 5
                 
                 if (start) begin
                 
                    sda_ctrl <= 1'b1;
                    state <= STATE_READ;
                    count <= 7;
                              
                 end else begin 
                       
                    sda_ctrl <= 1'b1;
                    state <= STATE_STOP;
                 
                 end // end wack2 state
              
              end
STATE_STOP: begin //6

                  sda_ctrl <= 0;
                  state <= STATE_IDLE;

             end // end stop state
                   
       endcase     
   end
   
end


endmodule
