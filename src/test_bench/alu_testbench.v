`timescale 1ns/1ps

module alu_testbench;

    parameter N=4;
    
    reg [N-1:0] OPA, OPB;
    reg CLK, RST, CE, MODE, CIN;
    reg [1:0]INP_VALID;
    reg [3:0] CMD;
    wire [2*N-1:0] RES_dut;
    wire COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut;

    wire [2*N-1:0] RES_ref;
    wire COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    ALU #(.WIDTH(N)) dut (
        .OPA(OPA), .OPB(OPB), .CIN(CIN),
        .CLK(CLK), .RST(RST), .CMD(CMD), .INP_VALID(INP_VALID),
        .CE(CE), .MODE(MODE),
        .COUT(COUT_dut), .OFLOW(OFLOW_dut),
        .RES(RES_dut),
        .G(G_dut), .E(E_dut), .L(L_dut),
        .ERR(ERR_dut)
    );

    alu_reference_model #(.N(N)) ref (
        .OPA(OPA), .OPB(OPB), .CIN(CIN),.CE(CE),
        .MODE(MODE), .CMD(CMD), .INP_VALID(INP_VALID),
        .RES(RES_ref),
        .COUT(COUT_ref), .OFLOW(OFLOW_ref),
        .G(G_ref), .E(E_ref), .L(L_ref),
        .ERR(ERR_ref)
    );

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        RST = 1; CE = 1; CIN = 0;
        OPA = 0; OPB = 0; MODE = 0; CMD = 0;

        check_reset("RESET");
        @(posedge CLK);
        RST = 0; 
        @(posedge CLK)

        apply_test(4'd5, 4'd1, 4'b0001, 2'b11,"PRE-CE", 2);

        CE = 0;

       @(posedge CLK);

       test_count = test_count + 1;

        if (RES_dut   === 8'h0E &&
    COUT_dut  === 1'b0 &&
    OFLOW_dut === 1'b0 &&
    G_dut     === 1'b0 &&
    E_dut     === 1'b0 &&
    L_dut     === 1'b0 &&
    ERR_dut   === 1'b0)
         begin
        $display("[PASS] CE test");
        pass_count = pass_count + 1;
       end
      else
    begin
    $display("[FAIL] CE test");
    fail_count = fail_count + 1;
    end

    CE = 1;
     @(posedge CLK);

        $display("\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        apply_test(4'd5, 4'd3, 4'b0000, 2'b11,
           "PRE-RESET ADD", 2);

         check_reset("Mid operation reset");
        test_arithmetic();



        $display("\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();


        $display("\n=== TEST SUMMARY ===");
        $display("Total Tests: %0d", test_count);
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        
        if (fail_count == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
        else
            $display("\n*** SOME TESTS FAILED ***\n");

        #100;
        $finish;
    end


    task test_arithmetic();
        begin
            apply_test(4'h1, 4'h1, 4'b0000, 2'b11, "ADD basic",2);
            apply_test(4'h0, 4'h0, 4'b0000, 2'b11, "ADD zero+zero",2);
            apply_test(4'hf, 4'hf, 4'b0000, 2'b11, "ADD f+f and cout",2);
            apply_test(4'h0, 4'h0, 4'b0000, 2'b01, "ADD wrong inp_valid",2);
            apply_test(4'hA, 4'h5, 4'b0000, 2'b11, "ADD alternating",2);
            
            
            apply_test(4'd5, 4'd1, 4'b0001, 2'b11, "SUB",2);
            apply_test(4'd2, 4'd3, 4'b0001, 2'b11, "SUB overflow",2);
            apply_test(4'd5, 4'd1, 4'b0001, 2'b11, "SUB SAME OP",2);
            apply_test(4'd5, 4'd1, 4'b0001, 2'b10, "SUB wrong inp_valid",2);
            apply_test(4'd0, 4'd1, 4'b0001, 2'b11, "SUB 0-1",2);
            
            
            CIN = 1;
            apply_test(4'd3,  4'd3,  4'b0010, 2'b00, "ADD_CIN wrong inp_valid",2);
            apply_test(4'd0,  4'd0,  4'b0010, 2'b11, "ADD_CIN 0+0+1",2);
            apply_test(4'd15, 4'd0,  4'b0010, 2'b11, "ADD_CIN 15+0+1",2);
            apply_test(4'd15, 4'd15, 4'b0010, 2'b11, "ADD_CIN 15+15+1",2);
            apply_test(4'd8,  4'd8,  4'b0010, 2'b11, "ADD_CIN 8+8+1",2);
            CIN = 0;
            apply_test(4'd2, 4'd2, 4'b0010, 2'b11, "ADD_CIN 0",2);
           
            CIN = 1;
            apply_test(4'd5,  4'd3,  4'b0011, 2'b11, "SUB_CIN general", 3);
            apply_test(4'd3,  4'd3,  4'b0011, 2'b00, "SUB_CIN wrong inp_valid", 3);
            apply_test(4'd3,  4'd3,  4'b0011, 2'b11, "SUB_CIN borrow by CIN", 3);
            apply_test(4'd4,  4'd3,  4'b0011, 2'b11, "SUB_CIN exact zero", 3);
            apply_test(4'd15, 4'd15, 4'b0011, 2'b11, "SUB_CIN max edge", 3);
            CIN = 0;
            apply_test(4'd0,  4'd1,  4'b0011, 2'b11, "SUB_CIN underflow", 3); 
           
            apply_test(4'd0,  4'd1, 4'b0100, 2'b01, "INC_A 0->1",2);
            apply_test(4'd14, 4'd0, 4'b0100, 2'b01, "INC_A 14->15",2);
            apply_test(4'd15, 4'd0, 4'b0100, 2'b01, "INC_A 15->0",2);
            apply_test(4'd5, 4'd1, 4'b0100, 2'b11, "INC_A  inp_valid 11",2);
            apply_test(4'd8, 4'd1, 4'b0100, 2'b10, "INC_A  inp_valid 10",2);
            

            apply_test(4'd1,  4'd0, 4'b0101, 2'b01, "DEC_A 1->0",2);
            apply_test(4'd0,  4'd0, 4'b0101, 2'b01, "DEC_A 0->15",2);
            apply_test(4'd15, 4'd0, 4'b0101, 2'b01, "DEC_A 15->14",2);
            apply_test(4'd5, 4'd1, 4'b0101, 2'b11, "DEC_A  inp_valid 11",2);
            apply_test(4'd8, 4'd1, 4'b0101, 2'b00, "DEC_A  inp_valid 10",2);

            apply_test(4'd0,  4'd0, 4'b0110, 2'b10, "INC_B 0->1",2);
            apply_test(4'd0,  4'd14,4'b0110, 2'b10, "INC_B 14->15",2);
            apply_test(4'd0,  4'd15,4'b0110, 2'b10, "INC_B 15->0",2);
            apply_test(4'd5, 4'd1, 4'b0110, 2'b11, "DEC_A inp_valid 11",2);
            apply_test(4'd7, 4'd1, 4'b0110, 2'b01, "DEC_A inp_valid 01",2);           
            
   
            apply_test(4'd0,  4'd1,  4'b0111, 2'b10, "DEC_B 1->0",2);
            apply_test(4'd0,  4'd0,  4'b0111, 2'b10, "DEC_B 0->15",2);
            apply_test(4'd0,  4'd15, 4'b0111, 2'b10, "DEC_B 15->14",2);
            apply_test(4'd1, 4'd5, 4'b0111, 2'b11, "DEC_B inp_valid 11",2);
            apply_test(4'd1, 4'd8, 4'b0111, 2'b00, "DEC_B inp_valid 00",2);
            

            apply_test(4'd5,  4'd5,  4'b1000, 2'b11, "CMP equal",2);
            apply_test(4'd10, 4'd5,  4'b1000, 2'b11, "CMP greater",2);
            apply_test(4'd3,  4'd9,  4'b1000, 2'b11, "CMP less",2);
            apply_test(4'd4,  4'd4,  4'b1000, 2'b01, "CMP invalid 01",2);
            

            apply_test(4'd7,  4'd8,  4'b1001, 2'b11, "MUL_INC 7,8",4);
            apply_test(4'd15, 4'd15, 4'b1001, 2'b11, "MUL_INC 15,15",4);
            apply_test(4'd15, 4'd0,  4'b1001, 2'b11, "MUL_INC 15,0",4);
            apply_test(4'd5,  4'd5,  4'b1001, 2'b00, "MUL_INC invalid 01",4);

            apply_test(4'd0,  4'd0,  4'b1010, 2'b11, "SHL_MUL 0,0",4);
            apply_test(4'd15, 4'd15, 4'b1010, 2'b11, "SHL_MUL 15,15",4);
            apply_test(4'd8,  4'd2,  4'b1010, 2'b11, "SHL_MUL 8,2",4);
            apply_test(4'd5,  4'd5,  4'b1010, 2'b01, "SHL_MUL invalid 01",4);

            apply_test(4'd3,  4'd2,  4'b1011, 2'b11, "SIGNED_ADD positive",2);
            apply_test(4'd7,  4'd1,  4'b1011, 2'b11, "SIGNED_ADD overflow",2);
            apply_test(4'd8,  4'd15, 4'b1011, 2'b11, "SIGNED_ADD negative",2);
            apply_test(4'd5,  4'd5,  4'b1011, 2'b11, "SIGNED_ADD equal",2);
            apply_test(4'd3, 4'd2, 4'b1011, 2'b01, "SIGNED_ADD invalid 01",2);
            apply_test(4'd3, 4'd2, 4'b1011, 2'b00, "SIGNED_ADD invalid 00",2);

            apply_test(4'd5,  4'd2,  4'b1100, 2'b11, "SIGNED_SUB positive",2);
            apply_test(4'd7,  4'd15, 4'b1100, 2'b11, "SIGNED_SUB overflow",2);
            apply_test(4'd8,  4'd1,  4'b1100, 2'b11, "SIGNED_SUB negative",2);
            apply_test(4'd4,  4'd4,  4'b1100, 2'b11, "SIGNED_SUB equal",2);
            
            apply_test(4'd4,  4'd4,  4'b1101, 2'b11, "DEFAULT",2);                   
        end
    endtask


     task test_logical();
        begin
            apply_test(4'd13, 4'd11, 4'b0000, 2'b11, "AND",2);
            apply_test(4'd0,  4'd0,  4'b0000, 2'b11, "AND 0&0",2);
            apply_test(4'd15, 4'd15, 4'b0000, 2'b11, "AND F&F",2);
            apply_test(4'd10, 4'd5,  4'b0000, 2'b11, "AND A&5",2);
            apply_test(4'd5, 4'd3, 4'b0000, 2'b00, "AND invalid 00",2);
            
            apply_test(4'd13, 4'd11, 4'b0001, 2'b11, "NAND",2);
            apply_test(4'd0,  4'd0,  4'b0001, 2'b11, "NAND 0&0",2);
            apply_test(4'd15, 4'd15, 4'b0001, 2'b11, "NAND F&F",2);
            apply_test(4'd10, 4'd5,  4'b0001, 2'b11, "NAND A&5",2);
            apply_test(4'd5,  4'd3,  4'b0001, 2'b00, "NAND invalid 00",2);
            apply_test(4'd5,  4'd3,  4'b0001, 2'b01, "NAND invalid 01",2);
            
            apply_test(4'd12, 4'd3,  4'b0010, 2'b11, "OR",2);
            apply_test(4'd0,  4'd0,  4'b0010, 2'b11, "OR 0|0",2);
            apply_test(4'd15, 4'd15, 4'b0010, 2'b11, "OR F|F",2);
            apply_test(4'd10, 4'd5,  4'b0010, 2'b11, "OR A|5",2);
            apply_test(4'd8,  4'd2,  4'b0010, 2'b11, "OR alternating",2);
            apply_test(4'd5,  4'd3,  4'b0010, 2'b00, "OR invalid 00",2);
            apply_test(4'd5,  4'd3,  4'b0010, 2'b01, "OR invalid 01",2);                       
            
            apply_test(4'd13, 4'd11, 4'b0011, 2'b11, "NOR",2);
            apply_test(4'd0,  4'd0,  4'b0011, 2'b11, "NOR 0|0",2);
            apply_test(4'd15, 4'd15, 4'b0011, 2'b11, "NOR F|F",2);
            apply_test(4'd10, 4'd5,  4'b0011, 2'b11, "NOR A|5",2);
            apply_test(4'd8,  4'd2,  4'b0011, 2'b11, "NOR mixed",2); 
            apply_test(4'd5,  4'd3,  4'b0011, 2'b00, "NOR invalid 00",2);
            apply_test(4'd5,  4'd3,  4'b0011, 2'b01, "NOR invalid 01",2);
            
            apply_test(4'd13, 4'd11, 4'b0100, 2'b11, "XOR",2);
            apply_test(4'd0,  4'd0,  4'b0100, 2'b11, "XOR 0^0",2);
            apply_test(4'd15, 4'd15, 4'b0100, 2'b11, "XOR F^F",2);
            apply_test(4'd10, 4'd5,  4'b0100, 2'b11, "XOR A^5",2);
            apply_test(4'd8,  4'd2,  4'b0100, 2'b11, "XOR mixed",2);
            apply_test(4'd5,  4'd3,  4'b0100, 2'b00, "XOR invalid 00",2);
            apply_test(4'd5,  4'd3,  4'b0100, 2'b10, "XOR invalid 10",2);
            
            apply_test(4'd13, 4'd11, 4'b0101, 2'b11, "XNOR",2);
            apply_test(4'd0,  4'd0,  4'b0101, 2'b11, "XNOR 0^0",2);
            apply_test(4'd15, 4'd15, 4'b0101, 2'b11, "XNOR F^F",2);
            apply_test(4'd10, 4'd5,  4'b0101, 2'b11, "XNOR A^5",2);
            apply_test(4'd8,  4'd2,  4'b0101, 2'b11, "XNOR mixed",2);
            apply_test(4'd5,  4'd3,  4'b0101, 2'b00, "XNOR invalid 00",2);
            apply_test(4'd5,  4'd3,  4'b0101, 2'b01, "XNOR invalid 01",2);

            apply_test(4'd0,  4'd0,  4'b0110, 2'b01, "NOT_A 0",2);
            apply_test(4'd15, 4'd0,  4'b0110, 2'b11, "NOT_A F",2);
            apply_test(4'd10, 4'd0,  4'b0110, 2'b11, "NOT_A A",2);
            apply_test(4'd5,  4'd0,  4'b0110, 2'b00, "NOT_A invalid 00",2);
            apply_test(4'd5,  4'd0,  4'b0110, 2'b10, "NOT_A invalid 10",2);
            
            apply_test(4'd0,  4'd0,  4'b0111, 2'b10, "NOT_B 0",2);
            apply_test(4'd0,  4'd15, 4'b0111, 2'b11, "NOT_B F",2);
            apply_test(4'd0,  4'd10, 4'b0111, 2'b11, "NOT_B A",2);
            apply_test(4'd0,  4'd5,  4'b0111, 2'b00, "NOT_B invalid 00",2);
            apply_test(4'd0,  4'd5,  4'b0111, 2'b01, "NOT_B invalid 01",2);
            
            apply_test(4'd9,  4'd0, 4'b1000, 2'b11, "SHR1_A",2);
            apply_test(4'd0,  4'd0, 4'b1000, 2'b01, "SHR1_A 0",2);
            apply_test(4'd15, 4'd0, 4'b1000, 2'b11, "SHR1_A F",2);
            apply_test(4'd10, 4'd0, 4'b1000, 2'b11, "SHR1_A A",2);
            apply_test(4'd5,  4'd0, 4'b1000, 2'b00, "SHR1_A invalid 00",2);
            apply_test(4'd5,  4'd0, 4'b1000, 2'b10, "SHR1_A invalid 10",2);
            
            apply_test(4'd9,  4'd0, 4'b1001, 2'b11, "SHL1_A",2);
            apply_test(4'd0,  4'd0, 4'b1001, 2'b01, "SHL1_A 0",2);
            apply_test(4'd15, 4'd0, 4'b1001, 2'b11, "SHL1_A F",2);
            apply_test(4'd5,  4'd0, 4'b1001, 2'b11, "SHL1_A 5",2);
            apply_test(4'd5,  4'd0, 4'b1001, 2'b00, "SHL1_A invalid 00",2);
            apply_test(4'd5,  4'd0, 4'b1001, 2'b10, "SHL1_A invalid 10",2);
            
            apply_test(4'd0,  4'd0, 4'b1010, 2'b11, "SHR1_B 0",2);
            apply_test(4'd0,  4'd15,4'b1010, 2'b11, "SHR1_B F",2);
            apply_test(4'd0,  4'd10,4'b1010, 2'b11, "SHR1_B A",2);
            apply_test(4'd0,  4'd10,4'b1010, 2'b10, "SHR1_B A 10",2);
            apply_test(4'd0,  4'd5, 4'b1010, 2'b00, "SHR1_B invalid 00",2);
            apply_test(4'd0,  4'd5, 4'b1010, 2'b01, "SHR1_B invalid 01",2);

            apply_test(4'd0,  4'd0, 4'b1011, 2'b10, "SHL1_B 0",2);
            apply_test(4'd0,  4'd15,4'b1011, 2'b11, "SHL1_B F",2);
            apply_test(4'd0,  4'd5, 4'b1011, 2'b11, "SHL1_B 5",2);
            apply_test(4'd0,  4'd5, 4'b1011, 2'b00, "SHL1_B invalid 00",2);
            apply_test(4'd0,  4'd5, 4'b1011, 2'b01, "SHL1_B invalid 01",2);
            
            apply_test(4'd9,  4'd12, 4'b1100, 2'b11, "ROL_A_B error shift",2);
            apply_test(4'd10, 4'd1,  4'b1100, 2'b11, "ROL_A_B A by1",2);
            apply_test(4'd9,  4'd2,  4'b1100, 2'b11, "ROL_A_B 9 by2",2);
            apply_test(4'd15, 4'd3,  4'b1100, 2'b11, "ROL_A_B F by3",2);
            apply_test(4'd5,  4'd1,  4'b1100, 2'b00, "ROL_A_B invalid",2);
            
            apply_test(4'd9,  4'd12, 4'b1101, 2'b11, "ROR_A_B error shift",2);
            apply_test(4'd10, 4'd1,  4'b1101, 2'b11, "ROR_A_B A by1",2);
            apply_test(4'd9,  4'd2,  4'b1101, 2'b11, "ROR_A_B 9 by2",2);
            apply_test(4'd15, 4'd3,  4'b1101, 2'b11, "ROR_A_B F by3",2);
            apply_test(4'd5,  4'd1,  4'b1101, 2'b00, "ROR_A_B invalid",2);
            
            apply_test(4'd5, 4'd3, 4'b1110, 2'b11, "DEFAULT case",2);
            
        end
    endtask

    task apply_test 
(
    input [N-1:0] a, b,
    input [3:0] cmd,
    input [1:0] inp_valid,
    input [80*8:1] test_name,
    input integer wait_cycles
);
integer i;

begin


    @(posedge CLK);

    OPA = a;
    OPB = b;
    CMD = cmd;
    INP_VALID = inp_valid;


    for(i=0; i<=wait_cycles; i=i+1)
        @(posedge CLK);


    test_count = test_count + 1;

    if(compare_outputs(1'b0)) begin
        $display("[PASS] %s", test_name);
        pass_count = pass_count + 1;
    end
    else begin
        $display("[FAIL] %s", test_name);
        display_mismatch();
        fail_count = fail_count + 1;
    end

end
endtask

task check_reset
(
    input [80*8:1] test_name
);
begin
    test_count = test_count + 1;

    RST = 1;
    #1;

    if (RES_dut   == 0 &&
        COUT_dut  == 0 &&
        OFLOW_dut == 0 &&
        G_dut     == 0 &&
        E_dut     == 0 &&
        L_dut     == 0 &&
        ERR_dut   == 0)
    begin
        $display("[PASS] %s", test_name);
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("[FAIL] %s", test_name);
        display_mismatch();
        fail_count = fail_count + 1;
    end

    @(posedge CLK);
    RST = 0;
    @(posedge CLK);
end
endtask
  
function [0:0] compare_outputs;
input dummy;
begin
    compare_outputs =
        (RES_dut    === RES_ref)   &&
        (COUT_dut  === COUT_ref)  &&
        (OFLOW_dut === OFLOW_ref) &&
        (G_dut     === G_ref)     &&
        (E_dut     === E_ref)     &&
        (L_dut     === L_ref)     &&
        (ERR_dut   === ERR_ref);
end
endfunction
task display_mismatch();
begin
    $display("  DUT: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
             RES_dut, COUT_dut, OFLOW_dut,
             G_dut, E_dut, L_dut, ERR_dut);

    $display("  REF: RES=0x%h COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
             RES_ref, COUT_ref, OFLOW_ref,
             G_ref, E_ref, L_ref, ERR_ref);
end
endtask


initial begin
    $dumpfile("alu_test.vcd");
    $dumpvars(0, alu_testbench);
end
endmodule

