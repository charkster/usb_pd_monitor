module usb_pd_decode (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       cc_pin,
  output logic [7:0] char_out,
  output logic       char_ready
);

// clock of 24MHz used
parameter CNT_2P5_US = 67;  // 2.5us / ( 1 / 27MHz )
parameter CNT_3P0_US = 81;  // 3.0us / ( 1 / 27Mhz )
parameter CNT_5P0_US = 135; // 5.0us / ( 1 / 27Mhz )

logic [7:0] counter;
logic       cc_pin_hold;
logic       cc_pin_redge;
logic       cc_pin_fedge;
logic [2:0] bit_count;
logic       bit_0;
logic       bit_1;
logic [3:0] bit_buffer;
logic       timeout;
logic       timeout_hold;
logic       timeout_fedge;
logic       sync1_seen;
logic       sync1_seen_hold;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n) cc_pin_hold <= 1'b1;
  else        cc_pin_hold <= cc_pin;

assign cc_pin_redge =   cc_pin  && (!cc_pin_hold);
assign cc_pin_fedge = (!cc_pin) &&   cc_pin_hold;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)                                       counter <= 'd0;
  else if (cc_pin_redge || cc_pin_fedge || timeout) counter <= 'd0;
  else                                              counter <= counter + 1;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)                            timeout <= 1'b0;
  else if (cc_pin_redge || cc_pin_fedge) timeout <= 1'b0;
  else if (counter > CNT_5P0_US)         timeout <= 1'b1;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n) timeout_hold <= 1'b0;
  else        timeout_hold <= timeout;

// preamble detection
assign timeout_fedge = ~timeout && timeout_hold;

assign bit_0 = (cc_pin_redge && (counter > CNT_2P5_US) && (!timeout)) || 
               (cc_pin_fedge && (counter > CNT_2P5_US) && (!timeout));
//               (cc_pin_fedge && (counter > CNT_3P0_US) && (!timeout));

assign bit_1 = (cc_pin_redge && (counter < CNT_2P5_US) && (!timeout));

assign sync1_seen = bit_1 && (bit_buffer == 4'b1000); // we don't start the bit_count until we have seen SYNC-1

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)          sync1_seen_hold <= 1'b0;
  else if (timeout)    sync1_seen_hold <= 1'b0;
  else if (sync1_seen) sync1_seen_hold <= 1'b1;

assign char_ready = ((bit_0 || bit_1) && (bit_count == 'd4)) || (sync1_seen && !sync1_seen_hold) || timeout_fedge;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)                                bit_count <= 'd0;
  else if (char_ready || (!sync1_seen_hold)) bit_count <= 'd0;
  else if (bit_0 || bit_1)                   bit_count <= bit_count + 1;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)              bit_buffer <= 4'b0000;
  else if (timeout)        bit_buffer <= 4'b0000;
  else if (bit_0 || bit_1) bit_buffer <= {bit_1,bit_buffer[3:1]};

always_comb
  case({bit_1,bit_buffer})
    5'b11110 : char_out = 8'h30; // 0
    5'b01001 : char_out = 8'h31; // 1
    5'b10100 : char_out = 8'h32; // 2
    5'b10101 : char_out = 8'h33; // 3
    5'b01010 : char_out = 8'h34; // 4 
    5'b01011 : char_out = 8'h35; // 5
    5'b01110 : char_out = 8'h36; // 6
    5'b01111 : char_out = 8'h37; // 7
    5'b10010 : char_out = 8'h38; // 8
    5'b10011 : char_out = 8'h39; // 9
    5'b10110 : char_out = 8'h41; // A
    5'b10111 : char_out = 8'h42; // B
    5'b11010 : char_out = 8'h43; // C
    5'b11011 : char_out = 8'h44; // D
    5'b11100 : char_out = 8'h45; // E
    5'b11101 : char_out = 8'h46; // F
    5'b11000 : char_out = 8'h53; // S, SYNC-1
    5'b10001 : char_out = 8'h54; // T, SYNC-2
    5'b00110 : char_out = 8'h55; // U, SYNC-3
    5'b00111 : char_out = 8'h51; // Q, RST-1
    5'b11001 : char_out = 8'h52; // R, RST-2
    5'b01101 : char_out = 8'h0D; // CR, EOP
    5'b00000 : char_out = 8'h0A; // NL, preable begining detect
    default  : char_out = 8'h58; // X, invalid
  endcase

endmodule
