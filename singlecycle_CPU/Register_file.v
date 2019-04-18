module RegisterFile(clk,reset,RegWr,regA,regB,read_dataA,read_dataB,write_data,write_reg);
	input clk,reset;
	input RegWr;
	input [4:0] regA , regB, write_reg;
	input [31:0] write_data;
	output [31:0]read_dataA , read_dataB;
	reg [31:0] RF_DATA[31:1];

	//确定输出，注意$zero
	assign read_dataA = (regA == 5'b00000) ? 32'b0 : RF_DATA[regA];
	assign read_dataB = (regB == 5'b00000) ? 32'b0 : RF_DATA[regB];

	integer i; 

	always @ (posedge clk or negedge reset)
		begin 
			if(~reset)
				for (i = 1; i < 32; i = i + 1)
					RF_DATA[i] <= 32'h00000000;
			else
				if(RegWr == 1 && write_reg != 5'b00000)
					RF_DATA[write_reg] <= write_data;//写入寄存器
		end
endmodule // RegisterFile
