module Adder(A,B,Sign,R,Z,V,N);
	input [31:0] A,B;
	input Sign;
	output reg [31:0] R;
	output reg Z,V,N;

	reg [32:0] temp;

	always @(*)
	begin
		temp <= A + B;
		R <= temp[31:0];
		if(Sign)              //有符号数
		begin
		    if(R==0)
			begin
			    Z<=1;
			end
			
			else
			begin
			    Z<=0;
			end	
			
			if(A[31]==0&&B[31]==0)
			begin
				N <= 0;
				if(temp[31]==1)        //溢出
				begin
					V <= 1;
				end
				
				else
				begin
				    V<=0;
				end
			end
			if(A[31]==1&&B[31]==1)
			begin
				N <= 1;
				if(temp[31]==0)        //溢出
				begin
					V <= 1;
				end
				
				else
				begin
				    V<=0;
				end
			end
			else begin                 //正负相加不可能溢出
			    V<=0;
				if(temp[31]==0)
				begin
					N <= 0;		
				end	
				
				else begin
					N <= 1;
				end
			end
		end
		else begin                    //无符号数
			if(temp[32]==1)           //溢出
			begin
				V <= 1; 				
			end
			
			else
			begin
			    V<=0;
			end
			if(temp==0)
			begin
			    Z<=1;
		    end
			
			else
			begin
			    Z<=0;
			end
			
		end
	end
endmodule