module usb_pd_monitor_top (
  input  logic clk_27mhz,
  input  logic button_s1,
  input  logic cc1_pin,
  input  logic cc2_pin,
  output logic uart_tx,
  output logic uart_tx_buf,
  output logic cc1_pin_buf,
  output logic cc2_pin_buf
);

logic       rst_n;
logic       rst_n_sync;
logic [7:0] char_out;
logic       char_ready;
logic       cc1_pin_sync;
logic       cc2_pin_sync;
logic       cc1_pin_sync_hold;
logic       cc2_pin_sync_hold;

assign rst_n = button_s1;

assign uart_tx_buf = uart_tx;

synchronizer u_synchronizer_rst_n_sync
  ( .clk      (clk_27mhz), // input
    .rst_n    (rst_n),     // input
    .data_in  (1'b1),      // input
    .data_out (rst_n_sync) // output
   );

synchronizer u_synchronizer_cc1_pin_sync
  ( .clk      (clk_27mhz),   // input
    .rst_n    (rst_n),       // input
    .data_in  (cc1_pin),     // input
    .data_out (cc1_pin_sync) // output
   );

always_ff @(posedge clk_27mhz, negedge rst_n_sync)
  if (~rst_n_sync) cc1_pin_sync_hold <= 1'b0;
  else             cc1_pin_sync_hold <= cc1_pin_sync;

always_ff @(posedge clk_27mhz, negedge rst_n_sync)
  if (~rst_n_sync)                            cc1_pin_buf <= 1'b0;
  else if (cc1_pin_sync == cc1_pin_sync_hold) cc1_pin_buf <= cc1_pin_sync;

synchronizer u_synchronizer_cc2_pin_sync
  ( .clk      (clk_27mhz),   // input
    .rst_n    (rst_n),       // input
    .data_in  (cc2_pin),     // input
    .data_out (cc2_pin_sync) // output
   );

always_ff @(posedge clk_27mhz, negedge rst_n_sync)
  if (~rst_n_sync) cc2_pin_sync_hold <= 1'b0;
  else             cc2_pin_sync_hold <= cc2_pin_sync;

always_ff @(posedge clk_27mhz, negedge rst_n_sync)
  if (~rst_n_sync)                            cc2_pin_buf <= 1'b0;
  else if (cc2_pin_sync == cc2_pin_sync_hold) cc2_pin_buf <= cc2_pin_sync;

usb_pd_decode u_usb_decode
  ( .clk    (clk_27mhz),                 // input
    .rst_n  (rst_n_sync),                // input
    .cc_pin (cc1_pin_buf | cc2_pin_buf), // input
    .char_out,                           // output [7:0]
    .char_ready                          // output
   );

uart_tx u_uart_tx
    ( .clk       (clk_27mhz),  // input
      .rst_n     (rst_n_sync), // input
      .send_trig (char_ready), // input
      .send_data (char_out),   // input [7:0]
      .tx        (uart_tx),    // output
      .tx_bsy    ()            // output
     );

endmodule