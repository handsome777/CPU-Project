module control(Instruct,IRQ,PCSrc,RegDst,RegWr,ALUSrc1,ALUSrc2,ALUFun,MemWr,MemRd,MemToReg,EXTOp,LUOp,Sign,interrupt,jiandu);
  	input [31:0] Instruct;
 	input IRQ;
 	input jiandu;
 	output [2:0] PCSrc;
  	output [1:0] RegDst;
  	output RegWr,ALUSrc1,ALUSrc2,Sign,MemWr,MemRd;
 	output [5:0] ALUFun;
 	output [1:0] MemToReg;
 	output EXTOp;
  	output LUOp;
  	output interrupt;

  	wire [2:0] PCSrc;
  	wire [1:0] RegDst;
  	wire RegWr,ALUSrc1,ALUSrc2,Sign,MemWr,MemRd;
  	wire [5:0] ALUFun;
  	wire [1:0] MemToReg;
  	wire EXTOp;
  	wire LUOp;
  	wire interrupt;
  	wire [5:0] OpCode;
  	wire [5:0] Funct;
  	wire error;

  
  	assign OpCode=Instruct[31:26];
  	assign Funct=Instruct[5:0];
  	assign interrupt=(~jiandu)&&IRQ;
  	assign error=~(((OpCode>=6'h01&&OpCode<=6'h0c)||(OpCode==6'h0f)||(OpCode==6'h23)||(OpCode==6'h2b))||
				  ((OpCode==6'h0)&&((Funct>=6'h20&&Funct<=6'h27)||(Funct==6'h00)||(Funct==6'h02)||(Funct==6'h03)||
				  (Funct==6'h2a)||(Funct==6'h08)||(Funct==6'h09))));

  	//PCSrc
	assign PCSrc=interrupt?3'd4:
			((OpCode>=6'h04&&OpCode<=6'h07)||(OpCode==6'h01))?3'd1:
			(OpCode==6'h02||OpCode==6'h03)?3'd2:
			(OpCode==6'h00&&(Funct==6'h08||Funct==6'h09))?3'd3:
			error?3'd5:3'd0;
         
   	//RegDst
   	assign RegDst=(interrupt|error)?2'b11:(OpCode==6'h03)?2'b10:(OpCode == 6'h0)?2'b00:2'd1;
         
    //RegWr
    assign RegWr=interrupt|(~((OpCode>=6'h04&&OpCode<=6'h07)||(OpCode==6'h01)||(OpCode==6'h02)||(OpCode==6'h2b)||(OpCode==6'h00&&Funct==6'h08)));
         
    //ALUSrc1
    assign ALUSrc1=(OpCode==0&&(Funct==0||Funct==6'h02||Funct==6'h03))?1:0;
         
    //ALUSrc2
    assign ALUSrc2=(OpCode==6'h23||OpCode==6'h2b||OpCode==6'h0f||OpCode==6'h08||OpCode==6'h09
    				||OpCode==6'h0c||OpCode==6'h0d||OpCode==6'h0a||OpCode==6'h0b)?1:0;
         
    //ALUFun
    assign ALUFun=
    			(OpCode==6'h23||OpCode==6'h2b||OpCode==6'h08||OpCode==6'h09||(OpCode==0&&(Funct==6'h20||Funct==6'h21)))?6'b000000:
    			(OpCode==0&&(Funct==6'h22||Funct==6'h23))?6'b000001:
    			(OpCode==6'h0c||(OpCode==0&&Funct==6'h24))?6'b011000:
    			(OpCode==6'h0f||OpCode==6'h0d||(OpCode==0&&Funct==6'h25))?6'b011110:
    			(OpCode==0&&Funct==6'h26)?6'b010110:
    			(OpCode==0&&Funct==6'h27)?6'b010001:
    			(OpCode==0&&(Funct==6'h08||Funct==6'h09))?6'b011010:
    			(OpCode==0&&Funct==0)?6'b100000:
    			(OpCode==0&&Funct==6'h02)?6'b100001:
    			(OpCode==0&&Funct==6'h03)?6'b100011:
    			(OpCode==6'h04)?6'b110011:
    			(OpCode==6'h05)?6'b110001:
    			(OpCode==6'h0a||OpCode==6'h0b||(OpCode==0&&(Funct==6'h2a||Funct==6'h2b)))?6'b110101:
    			(OpCode==6'h06)?6'b111101:
    			(OpCode==6'h01)?6'b111011:0;
         
    //Sign
    assign Sign=(OpCode==6'h09||OpCode==6'h0b||(OpCode==0&&(Funct==6'h21||Funct==6'h23||Funct==6'h2B)))?0:1;
         
    //MemWr
    assign MemWr=((OpCode==6'h2b) && (interrupt == 0))?1:0;
         
    //MemRd
    assign MemRd=((interrupt == 0) && OpCode==6'h23)?1:0;
         
    //MemToReg
    assign MemToReg=((interrupt|error)||OpCode==6'h03||(OpCode==0&&Funct==6'h09))?2'b10:(OpCode==6'h23)?2'b01:0;
         
    //EXTOp
    assign EXTOp=(OpCode==6'h0c||OpCode==6'h0d)?0:1;
         
    //LUOp
    assign LUOp=(OpCode==6'h0f)?1:0;
endmodule
         
      