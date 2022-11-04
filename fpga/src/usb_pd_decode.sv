// 1 bit is a "UI" (Unit Interval), 3.02us < UI < 3.7us
// Effectively this means...
// A high bit has no transitions for over 2.5us, a low bit sees a transition in less than 2.5us
// I define a timeout as not seeing an edge in at least 5us (Spec says 3.7us, but fpga pins are not accurate)
// the only time you expect a timeout is at the end of the entire message... so ignore all my "timeout" terms
// the preamble ends when the first SYNC-1 is detected... three lows then two highs (11000 shifting in from left-to-right)
// 5 bits decode to one 4bit nibble, every time 5 bits is counted a nibble is born
// I probably have some extra terms that are not needed... no harm, no foul

module usb_pd_decode (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       cc_pin,
  output logic [7:0] char_out,
  output logic       char_ready
);

// clock of 27MHz used
parameter CNT_2P5_US = 67;  // 2.5us / ( 1 / 27MHz )
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

// this counter counts at the 27MHz rate, the count is the time interval between CC edges
always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)                                       counter <= 'd0;
  else if (cc_pin_redge || cc_pin_fedge || timeout) counter <= 'd0;
  else                                              counter <= counter + 1;

// timeout occurs if we don't see an edge for 5us
always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)                            timeout <= 1'b0;
  else if (cc_pin_redge || cc_pin_fedge) timeout <= 1'b0;
  else if (counter > CNT_5P0_US)         timeout <= 1'b1;

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n) timeout_hold <= 1'b0;
  else        timeout_hold <= timeout;

// preamble detection, a falling edge of CC pin when timeout has previously been active
assign timeout_fedge = ~timeout && timeout_hold;

assign bit_0 = (cc_pin_redge && (counter > CNT_2P5_US) && (!timeout)) || 
               (cc_pin_fedge && (counter > CNT_2P5_US) && (!timeout));

assign bit_1 = (cc_pin_redge && (counter < CNT_2P5_US) && (!timeout));

assign sync1_seen = bit_1 && (bit_buffer == 4'b1000); // we don't start the bit_count until we have seen SYNC-1

always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)          sync1_seen_hold <= 1'b0;
  else if (timeout)    sync1_seen_hold <= 1'b0;
  else if (sync1_seen) sync1_seen_hold <= 1'b1;

// sync1_seen term is needed for first detected sync1 as bit_count is not running, timeout_fedge for preamble detection
assign char_ready = ((bit_0 || bit_1) && (bit_count == 'd4)) || (sync1_seen && !sync1_seen_hold) || timeout_fedge;

// bit_count is not expected to be over 5, sync1_seen_hold will go low with a timeout and bit_count follows 1 clock cycle later
always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)                                bit_count <= 'd0;
  else if (char_ready || (!sync1_seen_hold)) bit_count <= 'd0;
  else if (bit_0 || bit_1)                   bit_count <= bit_count + 1;

// bit buffer is used in both preamble and packet data
always_ff @(posedge clk, negedge rst_n)
  if (~rst_n)              bit_buffer <= 4'b0000;
  else if (timeout)        bit_buffer <= 4'b0000;
  else if (bit_0 || bit_1) bit_buffer <= {bit_1,bit_buffer[3:1]};

// the char_out is the ASCII hex character of the CC data
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
