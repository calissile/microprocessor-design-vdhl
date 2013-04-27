module RegisterFile (ABUS, BBUS, activateLSB, activateMSB, ABUSread, BBUSread, CBUSwriteMSB, CBUSwriteLSB, CBUS, clk, reset);

output [0:31] ABUS;
reg [0:31] ABUS;
output [0:31] BBUS;
reg [0:31] BBUS;
input [0:63] CBUS;
input activateLSB, activateMSB;
input [0:4] ABUSread;
input [0:4] BBUSread;
input [0:4] CBUSwriteMSB;
input [0:4] CBUSwriteLSB;
input clk, reset;

reg [0:31] registers [0:31];

always @ (posedge (clk), posedge (reset))
	begin
		if (reset == 1)
			begin
				registers [0] = 0;
				registers [1] = 1;
				registers [2] = 2;
				registers [3] = 3;
				registers [4] = 4;
				registers [5] = 5;
				registers [6] = 6;
				registers [7] = 7;
				registers [8] = 8;
				registers [9] = 9;
				registers [10] = 10;
				registers [11] = 11;
				registers [12] = 12;
				registers [13] = 13;
				registers [14] = 14;
				registers [15] = 15;
			end
		else
			begin
				ABUS = registers [ABUSread];
				BBUS = registers [BBUSread];
				if (activateLSB == 1) registers [CBUSwriteLSB] = CBUS [32:63];
				if (activateLSB == 0) registers [CBUSwriteMSB] = CBUS [0:31];
			end
		end
endmodule

module ALU (ABUS, BBUS, sub, rrs, mult, nandc, orc, zero, carry, negative, CBUS, pos);
input [0:31] ABUS;
input [0:31] BBUS;
output [0:63] CBUS;
reg [0:63] CBUS;
input sub, rrs, mult, nandc, orc;
output zero, carry, negative;
output reg [0:5] pos;
reg zero, carry, negative;
reg [0:31] temp;
reg [0:31] stuff;
reg [0:31] count;

always @ (*)
	begin
		if (sub == 1)
			begin
				CBUS [32:63] = ABUS - BBUS;
				pos = 32;
				carry = CBUS [32];
			end
		else if (rrs == 1)
			begin
				temp = ABUS [0:31] >> BBUS [0:31];
				count = 32 - BBUS [0:31];
				stuff = (ABUS << count);
				CBUS [32:63] = temp | stuff;
				pos = 32;
				carry = CBUS [32];
			end
		else if (mult == 1)
			begin
				CBUS = ABUS * BBUS;
				pos = 0;
				carry = CBUS [0];
			end
		else if (nandc == 1)
			begin
				CBUS [32:63] = ~ (ABBUS & BBUS);
				pos = 32;
				carry = 0;
			end
		else if (orc == 1)
			begin	
				CBUS [32:63] = ABUS | BBUS;
				pos = 32;
				carry = 0;
			end
		if (CBUS [pos] == 1)
			negative = 1;
		else
			negative = 0;
		if (pos == 32)
			begin
				if (CBUS [32:63] == 0)
					zero = 1;
				else
					zero = 0;
			end
	end
endmodule

module PC (newPCvalue, PCinc, PCload, PCvalue, clk, reset);
input [0:31] newPCvalue;
output [0:31] PCvalue;
reg [0:31] PCvalue;
input PCinc, PCload, clk, reset;

always @ (posedge (clk) or posedge (reset))
	begin
		if (reset == 1)
			PCvalue = 0;
		else
			begin	
				if (PCinc == 1)
					PCvalue = PCvalue + 1;
				else if (PCload == 1)
					PCvalue = newPCvalue;
			end
	end
endmodule

module control (IR, PCinc, PCload, sub, rrs, mult, nandc, orc, activateLSB, activateMSB, clk, reset, PCvalue, newPCvalue, next_state, pres_state, ABUSread, BBUSread, CBUSwriteMSB, CBUSwriteLSB);
input [0:31] IR;
input clk, reset;
output [0:4] ABUSread, BBUSread, CBUSwriteLSB, CBUSwriteMSB;
reg [0:4] ABUSread, BBUSread, CBUSwriteLSB, CBUSwriteMSB;
output PCinc, PCload, sub, rrs, mult, nandc, orc, activateLSB, activateMSB;
reg PCinc, PCload, sub, rrs, mult, nandc, orc, activateLSB, activateMSB;
input [0:31] PCvalue;
output [0:31] newPCvalue;
reg [0:31] newPCvalue;
output [0:1] pres_State, next_state;
reg [0:1] pres_state, next_state;

parameter SUB = 8'h0A, MULT = 8'h1A, RRS = 8'h21, NANDOP = 8'h22, OROP = 8'h23, BRANCHIFZERO = 8'h14;

wire [0:7] OPCODE;
wire [0:4] R1;
wire [0:4] R2;
wire [0:4] R3;
wire [0:4] Immediate;

reg activate;

parameter RESET = 0, EXECUTE = 1, FINISH = 2;

assign OPCODE = IR [0:7];
	R1 = IR [8:12];
	R2 = IR [13:17];
	R3 = IR [18:22];
	Immediate = IR [23:31];

always @ (clk, pres_state, OPCODE)
	begin
		case (pres_state)
			RESET:
				begin
					next_state = EXECUTE;
					PCinc = 0;
					PCload = 0;
					activate = 0;
					sub = 0;
					mult = 0;
					rrs = 0;
					nandc = 0;
					orc = 0;
					ABUSread = R1;
					BBUSread = R2;
				end
			EXECUTE: 
				begin
					PCinc = 0;
				end
			SUB:
				begin
					PCload = 0;
					activate = 0;
					sub = 1;
					CBUSwriteLSB = R3;
					next_state = FINISH;
				end
			MULT:
				begin
					PCload = 0;
					activate = 1;
					mult = 1;
					CBUSwriteMSB = R3;
					CBUSwriteLSB = R3 + 1;
					next_state = FINISH;
				end
			RRS:
				begin
					PCload = 0;
					activate = 0;
					nandc = 1;
					CBUSwriteLSB = R3;
					next_state = FINISH;
				end
			NANDOP:
				begin
					PCload = 0;	
					activate = 0;
					nandc = 1;
					CBUSwriteLSB = R3;
					next_state = FINISH;
				end
			OROP:
				begin
					PCload = 0;
					activate = 0;
					orc = 1;
					CBUSwriteLSB = R3;
					next_state = FINISH;
				end
			BRANCHIFZERO:
				begin
					PCload = 1;
					PCinc = 0;
					newPCvalue = PCvalue + {23'b0, Immediate};
					next_state = RESET;
				end
			FINISH:
				begin
					PCload = 0;
					PCinc = 1;
					activateLSB = 1;
					activateMSB = activate;
					next_state = RESET;
				emd
		endcase
	end

always @ (posedge (clk), posedge (reset))
	begin
		if (reset == 1)
			pres_state = RESET:
		else
			pres_state = next_state;
	end
endmodule

module testbench (IR, clk, reset, ABUS, BBUS, CBUS, PCvalue, nst, cst, zero,
                  carry, negative, pos);
output [0:31] IR;
reg [0:31] IR;
output clk, reset;
reg clk, reset;
input [0:31] ABUS;
input [0:31] BBUS;
input [0:63] CBUS;
input [0:31] PCvalue;
inout [0:1] nst, cst;
input zero, carry, negative;
input [0:5] pos; // Used by Bushnell's solution for debugging -- you can
                 // ignore this

// Opcode definitions
parameter SUB = 8'h0A, MULT = 8'h1A, RRS = 8'h21, NANDOP = 8'h22,
          OROP = 8'h23, BRANCHIFZERO = 8'h14;

// In your Register File module, please add initialization code to
// set the contents of each Register to its register number, so
// R0 will be set to 0, R1 to 1, ..., and R15 to 15.
// This test bench assumes that the registers have been set that way.
   
initial
  begin
    $dumpvars;
    $dumpfile ("hw5.dump");
    clk = 0;
    reset = 1;
    IR = 0;
#5 reset = 0;
    // SUB instruction
    IR = {SUB, 5'd1, 5'd2, 5'd3, 9'b0};
#10
#10
#10 // MULT instruction
    IR = {MULT, 5'd1, 5'd2, 5'd3, 9'b0};
#10
#10
#10 // RRS instruction
    IR = {RRS, 5'd3, 5'd4, 5'd5, 9'b0};
#10
#10
#10 // NAND instruction
    IR = {NANDOP, 5'd5, 5'd6, 5'd7, 9'b0};
#10
#10
#10 // OR instruction
    IR = {OROP, 5'd7, 5'd8, 5'd9, 9'b0};
#10
#10
#10 // Add R0 <= R0 + R0 to set the Z bit to 1
    IR = {ADD, 5'd0, 5'd0, 5'd0, 9'b0}
#10 // BRANCHIFZERO instruction
    IR = {BRANCHIFZERO, 5'd0, 5'd0, 5'd0, 9'd7};
#10
#10 $finish;
  end

always
#5  clk = ~ clk;

endmodule

module dothis;

RegisterFile (ABUS, BBUS, activateLSB, activateMSB, ABUSread, BBUSread, CBUSwriteMSB, CBUSwriteLSB, CBUS, clk, reset);
ALU (ABUS, BBUS, sub, rrs, mult, nandc, orc, zero, carry, negative, CBUS, pos);
PC (newPCvalue, PCinc, PCload, PCvalue, clk, reset);
control (IR, PCinc, PCload, sub, rrs, mult, nandc, orc, activateLSB, activateMSB, clk, reset, PCvalue, newPCvalue, next_state, pres_state, ABUSread, BBUSread, CBUSwriteMSB, CBUSwriteLSB);
testbench (IR, clk, reset, ABUS, BBUS, CBUS, PCvalue, nst, cst, zero, carry, negative, pos);

endmodule
