

module fos_exact_v1(
    input [31:0] x_in,
    input [10:0] a1,
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

    wire signed [31:0] Data_feedforward;
    wire signed [31:0] Data_feedback;
    wire signed [31:0] sum0;
    reg signed  [31:0] Samples_in1; 
    reg signed  [31:0] Samples_in2; 
    reg signed  [31:0] Samples_out; 

    assign Data_feedforward = {Samples_in2}; 
                          
    //assign Data_feedback = a1*Samples_out; 
 
    assign y_out = Samples_in1 - Data_feedforward - Data_feedback; 
    
    rad4_odd_trunc mult(Samples_out,a1,Data_feedback);

 
   always @ (posedge clk) 
   if(reset == 1) begin
         Samples_in1 <= 0; 
         Samples_in2 <= 0; 
         Samples_out <= 0; 
      end 
   else begin 
      Samples_in1 <= x_in; 
      Samples_in2 <= Samples_in1; 
      Samples_out <= y_out; 
   end 
 
    

endmodule
