module usb_pd_monitor_top (
  input  logic clk_27mhz,
  input  logic button_s1,
  input  logic cc1_pin,
  input  logic cc2_pin,
  output logic uart_tx,
  output logic uart_tx_buf,
  output logic cc_pin_buf
);

logic       rst_n;
logic       rst_n_sync;
logic [7:0] char_out;
logic       char_ready;
logic       cc_pin;
logic       cc_pin_sync;
logic       cc_pin_sync_hold;

assign rst_n = button_s1;

assign uart_tx_buf = uart_tx; // FPGA TX and RX signals do not normally connect to board pins

synchronizer u_synchronizer_rst_n_sync
  ( .clk      (clk_27mhz), // input
    .rst_n    (rst_n),     // input
    .data_in  (1'b1),      // input
    .data_out (rst_n_sync) // output
   );

assign cc_pin = cc1_pin | cc2_pin;

synchronizer u_synchronizer_cc1_pin_sync
  ( .clk      (clk_27mhz),   // input
    .rst_n    (rst_n),       // input
    .data_in  (cc_pin),     // input
    .data_out (cc_pin_sync) // output
   );

always_ff @(posedge clk_27mhz, negedge rst_n_sync)
  if (~rst_n_sync) cc_pin_sync_hold <= 1'b0;
  else             cc_pin_sync_hold <= cc_pin_sync;

// one clock cycle buffer, ignore changes until the sync and hold are equal
always_ff @(posedge clk_27mhz, negedge rst_n_sync)
  if (~rst_n_sync)                          cc_pin_buf <= 1'b0;
  else if (cc_pin_sync == cc_pin_sync_hold) cc_pin_buf <= cc_pin_sync;

usb_pd_decode u_usb_decode
  ( .clk    (clk_27mhz),  // input
    .rst_n  (rst_n_sync), // input
    .cc_pin (cc_pin_buf), // input
    .char_out,            // output [7:0]
    .char_ready           // output
   );

uart_tx 
# ( .SYSCLOCK( 27.0 ), .BAUDRATE( 1.0 ) ) // MHz and Mbits
u_uart_tx
    ( .clk       (clk_27mhz),  // input
      .rst_n     (rst_n_sync), // input
      .send_trig (char_ready), // input
      .send_data (char_out),   // input [7:0]
      .tx        (uart_tx),    // output
      .tx_bsy    ()            // output
     );

endmodule
