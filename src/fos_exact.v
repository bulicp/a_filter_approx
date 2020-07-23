
module fos_exact(
    input [31:0] x_in,
    input [10:0] a1,
    input [10:0] b1,
    input clk,
    input reset,
    output [31:0] y_out);
    /*
    Direct I form
     x_in ---------------->(+)------------------- >y_out
            |               ^              |
            |               |              |
         (z^-1)              |            (z^-1) 
            |               |              |
            |               |              |
            ----->(X)----->(+)<-----(X)<----
                   ^                 ^
                   |                 |
                  b1                a1
    */

    wire [31:0] Data_feedforward;
    wire [31:0] Data_feedback;
    wire [31:0] sum0;
    reg [31 : 0] Samples_in; 
    reg [31 : 0] Samples_out; 

    assign Data_feedforward = b1*Samples_in; 
                          
    assign Data_feedback = a1*Samples_out; 
 
    assign y_out = x_in + Data_feedforward + Data_feedback; 



   always @ (posedge clk) 
   if(reset == 1) begin
         Samples_in <= 0; 
         Samples_out <= 0; 
      end 
   else begin 
      Samples_in <= x_in; 
      Samples_out <= y_out; 
   end 
 
    

endmodule
