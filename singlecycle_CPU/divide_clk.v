module divide_clk(reset, sys_clk, clk);
	input reset, sys_clk;
	output clk;

///	reg clk1;
	assign clk = sys_clk;

///	parameter CNT_NUM = 26'd0;

///	reg [25:0]  cnt;

///	always @(posedge sys_clk or negedge reset)
///	begin
///  	if(~reset) begin
///        	cnt <= 26'd0;
///        	clk1 <= 1'b0;
///    	end
///    	else begin
///        	if(cnt >= CNT_NUM)
///            	cnt <= 26'd0;
///        	else
///            	cnt <= cnt + 26'd2;
///        
///        	if(cnt == 26'd0)
///            	clk1 <= ~clk1;
///    	end
///	end

endmodule // divide