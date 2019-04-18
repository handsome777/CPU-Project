module receiver(sys_clk,UART_Rx,RX_data,RX_status);
	input sys_clk;
	input UART_Rx;
	output [7:0]RX_data;
	output RX_status;

	reg [7:0]count;
	reg receive_enable;
	reg [10:0]signal_count;
	reg [10:0]resignal_count;
	reg cai_signal;
	reg enable;
	reg [4:0]digital;
	reg [7:0]RX_data_b;
	reg RX_status_b;
	reg [15:0]cnt;

	initial
	begin
		count<=0;
		receive_enable<=0;
		signal_count<=0;
		resignal_count<=0-10'd14;
		cai_signal<=0;
		enable<=0;
		digital<=0;
		RX_data_b<=0;
		RX_status_b<=0;
		cnt<=0;
	end

	assign RX_status=RX_status_b;
	assign RX_data=RX_data_b;

	always@(posedge sys_clk)
	begin
		if(cnt==16'd324)
		begin
			cnt<=0;
			count<=count+1;
		

			if(~receive_enable)
				begin
					if(~UART_Rx)
						begin
							if(count==8'd15)
							begin
								receive_enable<=1'b1;
								count<=0;
								cnt<=0;
							end
						end
					else
						begin
							enable<=0;
							count<=0;
							cnt<=0;
						end

					if(count==8'd7)
						enable<=1;
				end
			else
				begin
					if(enable==1)
						begin
							if(signal_count==resignal_count+11'd15)
								begin
									cai_signal<=1'b1;
								end
							if(signal_count==resignal_count+11'd17)
								begin
									cai_signal<=1'b0;
									resignal_count<=signal_count-11'd1;
								end

							if(count<=8'd7)
								signal_count<=0;
							else
								signal_count<=count-11'd7;
						end
					if(count==8'd128)
						begin
							enable<=0;
							RX_status_b<=1;
						end
					else
						begin
							if(cai_signal==1)
								begin
								RX_data_b[digital]<=UART_Rx;
								digital<=signal_count/8'd16+1;
							end
						end
					if(count>=8'd128)
						begin
						//	if(cnt == 16'd2)
						//		RX_status_b<=0;
							if(count==8'd128+8'd16)
								begin
									count<=0;
									receive_enable<=0;
									signal_count<=0;
									resignal_count<=0-10'd14;
									cai_signal<=0;
									enable<=0;
									digital<=0;
									RX_data_b<=0;
								end
						end
				end
		end
		else
		begin
			cnt<=cnt+1;
			RX_status_b<=0;
		end
	end


endmodule
