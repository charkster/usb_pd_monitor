
module synchronizer(
    input  logic clk,
    input  logic rst_n,
    input  logic data_in,
    output logic data_out
    );
    
    logic ff_1;
    
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n) ff_1 <= 1'b0;
    else        ff_1 <= data_in;
    
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n) data_out <= 1'b0;
    else        data_out <= ff_1;
    
    
endmodule
