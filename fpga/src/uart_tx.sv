module uart_tx
# ( parameter SYSCLOCK = 27.0, // MHz
    parameter BAUDRATE = 1.0 ) // Mbits
( input  logic       clk,
  input  logic       rst_n,  
  input  logic       send_trig,
  input  logic [7:0] send_data,
  output logic       tx,
  output logic       tx_bsy
);

    localparam CLKPERFRM = int'(SYSCLOCK/BAUDRATE)*10;
    // bit order is lsb-msb
    localparam TBITAT    = 1; // START bit
    localparam BIT0AT    = int'(SYSCLOCK/BAUDRATE*1)+1;
    localparam BIT1AT    = int'(SYSCLOCK/BAUDRATE*2)+1;
    localparam BIT2AT    = int'(SYSCLOCK/BAUDRATE*3)+1;
    localparam BIT3AT    = int'(SYSCLOCK/BAUDRATE*4)+1;
    localparam BIT4AT    = int'(SYSCLOCK/BAUDRATE*5)+1;
    localparam BIT5AT    = int'(SYSCLOCK/BAUDRATE*6)+1;
    localparam BIT6AT    = int'(SYSCLOCK/BAUDRATE*7)+1;
    localparam BIT7AT    = int'(SYSCLOCK/BAUDRATE*8)+1;
    localparam PBITAT    = int'(SYSCLOCK/BAUDRATE*9)+1; // STOP bit

    logic [$clog2(CLKPERFRM+1)-1:0] tx_cnt;    // tx flow control
    logic [7:0] data2send; // buffer
    logic       frame_begin;
    logic       frame_end;

    assign frame_begin = send_trig & (~tx_bsy);
    assign frame_end    = tx_bsy && (tx_cnt == CLKPERFRM);
    
    always@(posedge clk, negedge rst_n)
      if      (~rst_n)      tx_bsy <= 1'b0;
      else if (frame_begin) tx_bsy <= 1'b1;
      else if (frame_end)   tx_bsy <= 1'b0;
 
    always@(posedge clk, negedge rst_n)
      if      (~rst_n)    tx_cnt <= 'd0;
      else if (frame_end) tx_cnt <= 'd0;
      else if (tx_bsy)    tx_cnt <= tx_cnt + 1'b1;
    
    always@(posedge clk, negedge rst_n)
      if      (~rst_n)      data2send <= 8'd0;
      else if (frame_begin) data2send <= send_data;
    
    always@(posedge clk or negedge rst_n)
        if      (~rst_n)              tx <= 1'b1; // init val should be 1
        else if (tx_bsy) case(tx_cnt)
                              TBITAT: tx <= 1'b0;
                              BIT0AT: tx <= data2send[0];
                              BIT1AT: tx <= data2send[1];
                              BIT2AT: tx <= data2send[2];
                              BIT3AT: tx <= data2send[3];
                              BIT4AT: tx <= data2send[4];
                              BIT5AT: tx <= data2send[5];
                              BIT6AT: tx <= data2send[6];
                              BIT7AT: tx <= data2send[7];
                              PBITAT: tx <= 1'b1;
                         endcase
        else                          tx <= 1'b1;

endmodule
