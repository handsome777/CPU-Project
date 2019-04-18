module ALU(A,B,ALUFun,Sign,R);
	input [31:0] A,B;
	input [5:0] ALUFun;
	input Sign;
	output [31:0] R;
	wire [31:0] ZA;                 //ADD/SUB
	wire [31:0] ZC;                 //CMP
	wire [31:0] ZL;                 //Logic
	wire [31:0] ZS;                 //Shift
	wire Z;
	wire V;
	wire N;

	assign R = (ALUFun[5:4]==2'b00)?ZA:
			   (ALUFun[5:4]==2'b11)?ZC:
			   (ALUFun[5:4]==2'b01)?ZL:ZS;

    //ADD/SUB
    Adder A1(A,ALUFun[0]?(~B+1):B,Sign,ZA,Z,V,N);

    //CMP
    wire z;
    assign z = (ALUFun[3:1]==3'b000)?~Z:
    		   (ALUFun[3:1]==3'b001)?Z:
    		   (ALUFun[3:1]==3'b010)?N:
    		   (ALUFun[3:1]==3'b101)?A[31]:
    		   (ALUFun[3:1]==3'b110)?A[31]:
    		   (ALUFun[3:1]==3'b111)?~A[31]:0;
    assign ZC = {31'd0,z};
    //shift
    wire [31:0] one;                     //shift one
    wire [31:0] two;					 //shift two
    wire [31:0] four;                    //shift four
    wire [31:0] eight;                   //shift eight
    assign one = ALUFun[0]?(ALUFun[1]?(A[0]?{B[31],B[31:1]}:B):(A[0]?B>>1:B)):(A[0]?B<<1:B);
    assign two = ALUFun[0]?(ALUFun[1]?(A[1]?{{2{one[31]}},one[31:2]}:one):(A[1]?one>>2:one)):(A[1]?one<<2:one);
    assign four = ALUFun[0]?(ALUFun[1]?(A[2]?{{4{two[31]}},two[31:4]}:two):(A[2]?two>>4:two)):(A[2]?two<<4:two);
    assign eight = ALUFun[0]?(ALUFun[1]?(A[3]?{{8{four[31]}},four[31:4]}:four):(A[3]?four>>8:four)):(A[3]?four<<4:four);
    assign ZS = ALUFun[0]?(ALUFun[1]?(A[4]?{{16{eight[31]}},eight[31:4]}:eight):(A[4]?eight>>2:eight)):(A[4]?eight<<4:eight);
    //logic
    assign ZL = (ALUFun[3:0]==4'b0001)?~(A|B):
    			(ALUFun[3:0]==4'b0110)?A^B:
    			(ALUFun[3:0]==4'b1000)?A&B:
    			(ALUFun[3:0]==4'b1110)?A|B:A;
endmodule