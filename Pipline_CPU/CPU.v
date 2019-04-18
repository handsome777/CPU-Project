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
	wire load_use;
	wire is_branch;
	wire is_jump;

	//IF阶段的信号
	wire is_ILLOP;
	wire is_XADR;
	reg [31:0] IF_ID_instruction;
	reg [31:0] IF_ID_PC;
	reg [31:0] IF_ID_PC4;
	reg IF_ID_is_branch;

	//ID_EX之间的寄存器
	reg ID_EX_is_jump;	//保存经过control运算（PCSrc）传过来的jump
	reg [31:0] ID_EX_JUMP_Addr;//跳转地址
	reg [31:0] ID_EX_PC4;//保存PC4（注意中断和跳转的地址会保存在这里面去）
	reg [4:0] ID_EX_Rt;//保存Rt
	reg [4:0] ID_EX_Shamt;//保存Shamt
	reg ID_EX_MemRd;//保存control出来的MemRd
	reg ID_EX_MemWr;//保存control出来的MemWr
	reg [1:0] ID_EX_MemToReg;//保存control出来的MemToReg
	reg ID_EX_RegWr;//保存control出来的RegWr
	reg [2:0] ID_EX_PCSrc;//保存control出来的PCSrc
	reg ID_EX_Sign;//保存control出来的Sign
	reg [5:0] ID_EX_ALUFun;//保存control出来的ALUFun
	reg ID_EX_ALUSrc1;//保存control出来的MemWr
	reg ID_EX_ALUSrc2;//保存control出来的MemWr
	reg [4:0] ID_EX_Write_reg;//保存要写的寄存器号
	reg [31:0] ID_EX_data1;//转发后的输出1
	reg [31:0] ID_EX_data2;//转发后的输出2
	reg [31:0] ID_EX_Imm;//经过扩展和lu选择之后的输出
	reg [31:0] ID_EX_CONBA;//保存分支地址

	//EX_MEM之间的寄存器，一部分是保存上一级ID_EX的控制信号
	reg [31:0] EX_MEM_PC4;
	reg EX_MEM_MemRd;
	reg EX_MEM_MemWr;
	reg [1:0] EX_MEM_MemToReg;
	reg EX_MEM_RegWr;
	reg [4:0] EX_MEM_Write_reg;//从ID_EX传递过来的要保存的寄存器号
	reg [31:0] EX_MEM_ALU_out;//ALU的输出
	reg [31:0] EX_MEM_data2;//MEM保存的数据

	//MEM_WB之间的寄存器
	reg MEM_WB_RegWr;
	reg [4:0] MEM_WB_Write_reg;
	reg [31:0] MEM_WB_dataout;//写回寄存器的值

	wire [4:0] Rs; 
	wire [4:0] Rt; 
	wire [4:0] Shamt; 
	wire [4:0] Rd;
	wire [25:0] JT;
	wire [15:0] Imm16; 

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
	wire [1:0] MemToReg;
	wire ExtOp;
	wire LuOp;
	wire irqout;
	wire interrupt;

	//读取数据寄存器 or 外设
	wire [31:0] Read_datam;
	wire [31:0] Read_datap;
	wire [31:0] Read_data;
	wire [11:0] digi;
	wire [31:0] Databus3;

	//寄存器堆
	wire [31:0] Databus1, Databus2;
	wire [4:0] Write_register;

	//ALU模块
	wire [31:0] ALU_a;
	wire [31:0] ALU_b;
	wire [31:0] ALU_out;

	//跳转地址
	wire [31:0] Jump_target;
	assign Jump_target = {IF_ID_PC4[31:28],IF_ID_instruction[25:0],2'd0};
	//PC+4
	wire [31:0] PC_plus_4;
	assign PC_plus_4 = PC + 32'd4;

	//阻塞的控制信号，即lw保存的地址等于下一条指令要进入ALU的寄存器，就阻塞（PC不变）
	assign load_use =(ID_EX_MemRd && (ID_EX_Rt == Rs || ID_EX_Rt == Rt));
	assign is_jump=(PCSrc==3'd2);

	assign is_ILLOP=(PCSrc==3'd4);
	assign is_XADR=(PCSrc==3'd5);


	parameter ILLOP = 32'h80000004;
	parameter XADR = 32'h80000008;

	always @(negedge reset or posedge clk)
	begin
		if (~reset)
			PC <= 32'd0;
		else if (is_ILLOP && ~is_branch)//中断
			PC <= ILLOP;
		else if (is_XADR && ~is_branch)//异常
			PC <= XADR;
		else if (~load_use)//非阻塞运行，如果是阻塞，则PC不变
			begin
				if (is_branch)//分支
					PC <= ID_EX_CONBA;
				else if (PCSrc == 3'd2)//j
					PC <= Jump_target;
				else if (PCSrc == 3'd3)//jr
					PC <= Databus1;
				else//正常流程
					PC <= PC_plus_4;
			end
	end


	//取指令
	wire [31:0] Instruction;
	InstructionMemory instruction_memory1(.Address({1'b0,PC[30:0]}), .data(Instruction));
	


	//IF-ID，相当于是IF取完指，存入IF-ID中间的寄存器中保存
	always @(posedge clk or negedge reset)
	begin
		if(~reset)
		begin
			IF_ID_instruction <= 32'd0;
			IF_ID_PC4  <= 32'd0;
			IF_ID_PC <= 32'd0;
		end
		else if (PCSrc == 3'd4 || PCSrc == 3'd5)//如果是中断或者异常，下一条指令要清0，即不执行
		begin
			IF_ID_PC <=  32'h80000000;
			IF_ID_PC4 <= 32'h80000000;
			IF_ID_instruction <= 32'h00000000;
		end
		else if (is_branch || (PCSrc == 3'd2) || (PCSrc == 3'd3))//如果是分支、j型指令，下一条指令清0，不执行
		begin
			IF_ID_PC <= IF_ID_PC[31]? 32'h80000000:32'd0;
			IF_ID_PC4 <= IF_ID_PC4[31]?32'h80000000:32'd0;
			IF_ID_instruction <= 32'd0;
		end
		else if(~load_use)//非阻塞，正常运行，阻塞，下一条指令和PC和当前指令与PC一样
		begin
			IF_ID_PC <= PC;
			IF_ID_PC4 <= PC_plus_4;
			IF_ID_instruction <= Instruction;
		end
	end

	always@ (posedge clk or negedge reset)
	begin
		if(~reset)
			IF_ID_is_branch <= 0;
		else
			IF_ID_is_branch <= is_branch;//把分支跳转指令保存到下一级里面去
	end

	//取指
	assign Rs = IF_ID_instruction[25:21];
	assign Rt = IF_ID_instruction[20:16];
	assign Shamt = IF_ID_instruction[10:6];
	assign Rd = IF_ID_instruction[15:11];
	assign JT = IF_ID_instruction[25:0];
	assign Imm16 = IF_ID_instruction[15:0];

	//产生控制信号，注意，这里的输入的指令应该是IF阶段的指令，监督位也应该是IF阶段PC4的最高位
	control control1(.Instruct(IF_ID_instruction), .IRQ(irqout),
					 .PCSrc(PCSrc), .RegDst(RegDst), .RegWr(RegWr),
					 .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .ALUFun(ALUFun),
					 .MemWr(MemWrite), .MemRd(MemRead), .MemToReg(MemToReg),
					 .EXTOp(ExtOp), .LUOp(LuOp), 
					 .Sign(Sign), .interrupt(interrupt),.jiandu(IF_ID_PC4[31]));
	

	parameter Xp = 5'b11010;
	parameter Ra = 5'b11111;
	//判断是保存在哪个寄存器中，然后一级一级地传递下去，最后输入寄存器堆的是MEM_WB的write_reg
	assign Write_register = (RegDst == 2'b00)? Rd: (RegDst == 2'b01)? Rt: (RegDst == 2'b10)? Ra: Xp;
	//访问并写回寄存器堆
	RegisterFile register_file1(.clk(clk), .reset(reset), .RegWr(MEM_WB_RegWr), 
		.regA(Rs), .regB(Rt), .read_dataA(Databus1), .read_dataB(Databus2), .write_data(MEM_WB_dataout),
		.write_reg(MEM_WB_Write_reg));

	//扩展方式，ExtOp=1，符号扩展，=0，无符号扩展
	wire [31:0] Ext_out;
	assign Ext_out = ExtOp? {{16{Imm16[15]}},Imm16}: {16'h0000, Imm16};
	
	//Lui or Ext，LU_out=1，输出lui之后的值，=0，输出扩展的Ext_out
	wire [31:0] LU_out;
	assign LU_out = LuOp? {Imm16, 16'd0}: Ext_out;
	
	//计算分支地址
	wire [31:0] CONBA;
	assign CONBA =  IF_ID_PC4+ {Ext_out[29:0], 2'b00};

	//ID-EX阶段，更新寄存器的值
	always @(posedge clk or negedge reset)
	begin
		if(~reset)//清0
		begin
			ID_EX_is_jump<= 1'b0;
			ID_EX_JUMP_Addr <= 32'd0;
			ID_EX_PC4 <= 32'd0;
			ID_EX_Rt <= 5'd0;
			ID_EX_Shamt <= 5'd0;
			ID_EX_MemRd <= 1'b0;
			ID_EX_MemWr <= 1'b0;
			ID_EX_MemToReg <= 2'd0;
			ID_EX_RegWr <= 1'b0;
			ID_EX_PCSrc <= 3'd0;
			ID_EX_Sign <= 1'b0;
			ID_EX_ALUFun <= 6'd0;
			ID_EX_ALUSrc1 <= 1'b0;
			ID_EX_ALUSrc2 <= 1'b0;
			ID_EX_Write_reg <= 1'b0;
			ID_EX_data1 <= 32'd0;
			ID_EX_data2 <= 32'd0;
			ID_EX_Imm <= 32'd0;
			ID_EX_CONBA <= 32'd0;
			ID_EX_data1 <= 32'd0;
			ID_EX_data2 <= 32'd0;
		end
		else
		begin
			//判断写入寄存器的值，如果同一条指令跳转且中断，则会先跳转再中断；如果上一条指令跳转，当前指令中断，则把当前的PC写入寄存器
			ID_EX_PC4 <= ((IF_ID_is_branch ==1) && irqout)? PC:((ID_EX_is_jump == 1)?ID_EX_JUMP_Addr:
						 ((IF_ID_instruction[31:26] == 6'b000011)?IF_ID_PC4:IF_ID_PC));
			ID_EX_Rt <= Rt;//用于阻塞判断
			ID_EX_Shamt <= Shamt;//用于ALUA输入的一个选项
			ID_EX_PCSrc <= PCSrc;//保存PCSrc，用于ALU输出之后，计算is_branch
			ID_EX_Imm <= LU_out;//保存立即数输入
			ID_EX_CONBA <= CONBA;//用于保存分支指令，如果is_branch==1，则会写入PC

			//转发
			ID_EX_data1 <=
					(EX_MEM_RegWr&&(EX_MEM_Write_reg!=0)&&(EX_MEM_Write_reg==Rs)&&(ID_EX_Write_reg!=Rs||~ID_EX_RegWr))?Databus3:
			  		(ID_EX_RegWr&&(ID_EX_Write_reg!=0)&&(ID_EX_Write_reg==Rs))?ALU_out:
			  		(MEM_WB_RegWr&&(MEM_WB_Write_reg!=0)&&(MEM_WB_Write_reg==Rs))?MEM_WB_dataout:Databus1;
			ID_EX_data2 <=
					(EX_MEM_RegWr&&(EX_MEM_Write_reg!=0)&&(EX_MEM_Write_reg==Rt)&&(ID_EX_Write_reg!=Rt||~ID_EX_RegWr))?Databus3:
			  		(ID_EX_RegWr&&(ID_EX_Write_reg!=0)&&(ID_EX_Write_reg==Rt))?ALU_out:
			  		(MEM_WB_RegWr&&(MEM_WB_Write_reg!=0)&&(MEM_WB_Write_reg==Rt))?MEM_WB_dataout:Databus2;

			//如果是阻塞或者分支，则这些信号清0
			if ((load_use || is_branch)&&~is_XADR&&~is_ILLOP)
			begin
				ID_EX_Write_reg<=5'd0;
				ID_EX_MemToReg<=2'd0;
				ID_EX_ALUFun<=6'd0;
				ID_EX_RegWr<=1'd0;
				ID_EX_ALUSrc1<=1'd0;
				ID_EX_ALUSrc2<=1'd0;
				ID_EX_Sign<=1'd0;
				ID_EX_MemWr<=1'd0;
				ID_EX_MemRd<=1'd0;
				ID_EX_is_jump<=1'd0;
				ID_EX_JUMP_Addr<=32'b0;
			end
			else
			begin
				ID_EX_Write_reg <= Write_register;
				ID_EX_MemToReg <= MemToReg;
				ID_EX_ALUFun <= ALUFun;
				ID_EX_ALUSrc1 <= ALUSrc1;
				ID_EX_ALUSrc2 <= ALUSrc2;
				ID_EX_is_jump<= is_jump;
				ID_EX_MemRd <= MemRead;
				ID_EX_MemWr <= MemWrite;
				ID_EX_RegWr <= RegWr;
				ID_EX_Sign <= Sign;
				ID_EX_JUMP_Addr <= {IF_ID_PC4[31:28],IF_ID_instruction[25:0],2'd0};
			end
		end
	end
	
	//判断ALU的输入
	assign ALU_a = ID_EX_ALUSrc1? {27'd0,ID_EX_Shamt}:ID_EX_data1;
	assign ALU_b = ID_EX_ALUSrc2? ID_EX_Imm: ID_EX_data2;
	//ALU模块
	ALU alu1(.A(ALU_a), .B(ALU_b), .ALUFun(ID_EX_ALUFun), .Sign(ID_EX_Sign), .R(ALU_out));
	//根据ALU输出的最低位来判断is_branch的值
	assign is_branch = (ID_EX_PCSrc == 3'd1 && ALU_out[0]); 

	//EX_MEM
	always @ (posedge clk or negedge reset)
	begin
		if(~reset)
		begin
			EX_MEM_PC4 <= 32'd0;
			EX_MEM_MemRd <= 1'd0;
			EX_MEM_MemWr <= 1'd0;
			EX_MEM_MemToReg <= 2'd0;
			EX_MEM_RegWr <= 1'd0;
			EX_MEM_Write_reg <= 5'd0;
			EX_MEM_ALU_out <= 32'd0;
			EX_MEM_data2 <= 32'd0;
		end
		else
		begin
			EX_MEM_PC4 <= ID_EX_PC4;
			EX_MEM_MemRd <= ID_EX_MemRd;
			EX_MEM_MemWr <= ID_EX_MemWr;
			EX_MEM_MemToReg <= ID_EX_MemToReg;
			EX_MEM_RegWr <= ID_EX_RegWr;
			EX_MEM_Write_reg <= ID_EX_Write_reg;
			EX_MEM_ALU_out <= ALU_out;
			EX_MEM_data2 <= ID_EX_data2;
		end
	end


	//如果ALU_out[30]==0，这说明是访问的数据段
	DataMemory data_memory1(.reset(reset), .clk(clk), .Address(EX_MEM_ALU_out),
						    .Write_data(EX_MEM_data2), .Read_data(Read_datam),
						    .MemRead(EX_MEM_MemRd & (~EX_MEM_ALU_out[30])),
						    .MemWrite(EX_MEM_MemWr & (~EX_MEM_ALU_out[30])));
	//如果ALU_out[30]==1，这说明是访问的外设段
	Peripheral peripheral1(.reset(reset), .sys_clk(sys_clk), .clk(clk), .rd(EX_MEM_MemRd & (EX_MEM_ALU_out[30])), 
						   .wr(EX_MEM_MemWr & (EX_MEM_ALU_out[30])),.addr(EX_MEM_ALU_out),
						   .wdata(EX_MEM_data2), .rdata(Read_datap), .led(led),
						   .digi(digi), .irqout(irqout), .UART_TX(tx), .UART_RX(rx));
	//显示模块
	digitube_scan digi_scan(.digi_in(digi), .digi_out1(digi_o1), .digi_out2(digi_o2), .digi_out3(digi_o3), .digi_out4(digi_o4));
	//根据访问地址的第二高位来判断存储输出的是数据存储器得值还是外设存储器的值
	assign Read_data = EX_MEM_ALU_out[30]? Read_datap: Read_datam;
	assign Databus3 = (EX_MEM_MemToReg == 2'b00)? EX_MEM_ALU_out: (EX_MEM_MemToReg == 2'b01)? Read_data: (EX_MEM_MemToReg == 2'b10)?EX_MEM_PC4:EX_MEM_PC4 - 32'd12;
	
	//MEM-WB
	always @(posedge clk or negedge reset)
	begin
		if(~reset)
		begin
			MEM_WB_RegWr <= 1'b0;
			MEM_WB_Write_reg <= 5'd0;
			MEM_WB_dataout <= 32'd0;

		end
		else
		begin
			MEM_WB_RegWr <= EX_MEM_RegWr;
			MEM_WB_Write_reg <= EX_MEM_Write_reg;
			MEM_WB_dataout <= Databus3;
		end
	end

endmodule