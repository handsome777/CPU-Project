module chuankou(sys_clk,UART_RX,reset,UART_TX,RX_STATUS,TX_STATUS,RX_DATA,TX_DATA,TX_EN);
	input sys_clk,UART_RX,reset;
	input TX_EN;
	input [7:0] TX_DATA;
	output UART_TX;
	output [7:0]RX_DATA;
	output RX_STATUS;
	output TX_STATUS;


	wire [7:0]RX_DATA;
	wire RX_STATUS;
	wire [7:0]TX_DATA;
	wire TX_EN;
	wire TX_STATUS;


	receiver r(.sys_clk(sys_clk),.UART_Rx(UART_RX),.RX_data(RX_DATA),.RX_status(RX_STATUS));
	sender s(.sys_clk(sys_clk),.reset(reset),.TX_data(TX_DATA),.TX_en(TX_EN),
	         .TX_status(TX_STATUS),.UART_tx(UART_TX));

endmodule // chuankou