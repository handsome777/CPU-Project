module CPU(reset, sys_clk, digi_o1, digi_o2, digi_o3, digi_o4, led, rx, tx);
	input reset, sys_clk;
	input rx;
//	input [7:0] switch;
	output [6:0] digi_o1;
	output [6:0] digi_o2;
	output [6:0] digi_o3;
	output [6:0] digi_o4;
	output [7:0] led;
	output tx;

	//分频
	divide_clk div_clk(.reset(reset), .sys_clk(sys_clk), .clk(clk));

	//PC+4
	reg [31:0] PC;
	wire [31:0] PC_next;
	always @(negedge reset or posedge clk)
		if (~reset)
			PC <= 32'h0000000;
		else
			PC <= PC_next;
	
	wire [31:0] PC_plus_4;
	assign PC_plus_4 = PC + 32'd4;
	
	//取指令
	wire [31:0] Instruction;
	InstructionMemory instruction_memory1(.Address({1'b0,PC[30:0]}), .data(Instruction));
	
	//控制信号
	wire [2:0] PCSrc;
	wire [1:0] RegDst;
	wire RegWr;
	wire ALUSrc1;
	wire ALUSrc2;
	wire [5:0] ALUFun;
	wire Sign;
	wire MemWrite;
	wire MemRead;
	wire [1:0] MemtoReg;
	wire ExtOp;
	wire LuOp;
	wire irqout;
	wire interrupt;

	control control1(.Instruct(Instruction), .IRQ(irqout),
					 .PCSrc(PCSrc), .RegDst(RegDst), .RegWr(RegWr),
					 .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .ALUFun(ALUFun),
					 .MemWr(MemWrite), .MemRd(MemRead), .MemToReg(MemtoReg),
					 .EXTOp(ExtOp), .LUOp(LuOp), 
					 .Sign(Sign), .interrupt(interrupt),.jiandu(PC[31]));
	
	//寄存器堆
	wire [31:0] Databus1, Databus2, Databus3;
	wire [4:0] Write_register;
	parameter Xp = 5'b11010;
	parameter Ra = 5'b11111;
	assign Write_register = (RegDst == 2'b00)? Instruction[15:11]: (RegDst == 2'b01)? Instruction[20:16]: (RegDst == 2'b10)? Ra: Xp;
	RegisterFile register_file1(.clk(clk), .reset(reset), .RegWr(RegWr), 
		.regA(Instruction[25:21]), .regB(Instruction[20:16]), .read_dataA(Databus1), .read_dataB(Databus2), .write_data(Databus3),
		.write_reg(Write_register));
	
	//扩展方式
	wire [31:0] Ext_out;
	assign Ext_out = {ExtOp? {16{Instruction[15]}}: 16'h0000, Instruction[15:0]};
	
	//Lui or Ext
	wire [31:0] LU_out;
	assign LU_out = LuOp? {Instruction[15:0], 16'h0000}: Ext_out;
	
	//ALU模块
	wire [31:0] ALU_a;
	wire [31:0] ALU_b;
	wire [31:0] ALU_out;
	
	assign ALU_a = ALUSrc1? {27'd0, Instruction[10:6]}: Databus1;
	assign ALU_b = ALUSrc2? LU_out: Databus2;
	ALU alu1(.A(ALU_a), .B(ALU_b), .ALUFun(ALUFun), .Sign(Sign), .R(ALU_out));
	
	//读取数据寄存器 or 外设
	wire [31:0] Read_datam;
	wire [31:0] Read_datap;
	wire [31:0] Read_data;
	wire [11:0] digi;
	//如果ALU_out[30]==0，这说明是访问的数据段
	DataMemory data_memory1(.reset(reset), .clk(clk), .Address(ALU_out), .Write_data(Databus2), 
							.Read_data(Read_datam), .MemRead(MemRead & (~ALU_out[30])), .MemWrite(MemWrite & (~ALU_out[30])));
	//如果ALU_out[30]==1，这说明是访问的外设段
	Peripheral peripheral1(.reset(reset), .sys_clk(sys_clk), .clk(clk), .rd(MemRead & (ALU_out[30])), .wr(MemWrite & (ALU_out[30])),.addr(ALU_out),
							.wdata(Databus2), .rdata(Read_datap), .led(led),
							 .digi(digi), .irqout(irqout), .UART_TX(tx), .UART_RX(rx));
	//显示模块
	digitube_scan digi_scan(.digi_in(digi), .digi_out1(digi_o1), .digi_out2(digi_o2), .digi_out3(digi_o3), .digi_out4(digi_o4));
	assign Read_data = ALU_out[30]? Read_datap: Read_datam;

	assign Databus3 = (MemtoReg == 2'b00)? ALU_out: (MemtoReg == 2'b01)? Read_data: ((MemtoReg == 2'b10) && (interrupt))?PC:PC_plus_4;
	
	wire [31:0] Jump_target;
	assign Jump_target = {PC_plus_4[31:28], Instruction[25:0], 2'b00};
	
	wire [31:0] Branch_target;
	assign Branch_target = ALU_out[0]? PC_plus_4 + {LU_out[29:0], 2'b00}: PC_plus_4;
	

	parameter ILLOP = 32'h80000004;
	parameter XADR = 32'h80000008;
	assign PC_next = (PCSrc == 3'b000)? PC_plus_4: (PCSrc == 3'b001)? Branch_target: (PCSrc == 3'b010)? Jump_target:
					 (PCSrc == 3'b011)? Databus1: (PCSrc == 3'b100)? ILLOP: XADR;

endmodule
	