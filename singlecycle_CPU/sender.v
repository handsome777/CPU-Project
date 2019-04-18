module sender(sys_clk,reset,TX_data,TX_en,TX_status,UART_tx);
	input sys_clk,TX_en,reset;
	input [7:0]TX_data;
	output TX_status;
	output UART_tx;


	reg [3:0]digital;
	reg TX_status_b;
	reg [7:0]save_data;
	reg TX_send;
	reg UART_tx_b;
	reg [15:0]cnt1;

	assign UART_tx=UART_tx_b;
	assign TX_status=TX_status_b;

	initial
	begin
		digital<=0;
		UART_tx_b<=1;
		TX_status_b<=0;
		save_data<=0;
		TX_send<=0;
		cnt1<=0;
	end


	always@(posedge sys_clk or negedge reset)
	begin
		if(~reset)
			begin
				digital<=0;
				UART_tx_b<=1;
				save_data<=0;
				TX_send<=0;
			end
		else
			begin
				if(TX_en&&(~TX_send))
					begin
						TX_send<=1;
						save_data [7:0]<=TX_data[7:0];
					end
				else if (TX_send)
					begin
						TX_status_b<=1;
						if(cnt1==15'd5208)
						begin
							cnt1<=0;
							digital<=digital+1;
							case(digital)
							4'd0:begin
									UART_tx_b<=0;
									TX_status_b<=0;
								end
							4'd1:UART_tx_b<=save_data[0];
							4'd2:UART_tx_b<=save_data[1];
							4'd3:UART_tx_b<=save_data[2];
							4'd4:UART_tx_b<=save_data[3];
							4'd5:UART_tx_b<=save_data[4];
							4'd6:UART_tx_b<=save_data[5];
							4'd7:UART_tx_b<=save_data[6];
							4'd8:UART_tx_b<=save_data[7];
							4'd9:UART_tx_b<=1;
							4'd10:begin
									digital<=0;
									TX_status_b<=0;
									TX_send<=0;
								  end
							endcase // digital
						end
						else
							cnt1<=cnt1+1;
					end
			end
	end
endmodule // sender