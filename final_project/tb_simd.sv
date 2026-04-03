`timescale 1ns/1ps

module tb_simd;
    localparam int N_LANES = 4;
    localparam int MEM_DEPTH = 256;

    logic clk;
    logic rst_n;
    logic start;
    logic [2:0] operation_type;
    logic [31:0] n;
    logic [31:0] a_address;
    logic [31:0] b_address;
    logic [31:0] c_address;

    logic [31:0] read_addr1 [0:N_LANES-1];
    logic [31:0] read_data1 [0:N_LANES-1];
    logic [31:0] read_addr2 [0:N_LANES-1];
    logic [31:0] read_data2 [0:N_LANES-1];
    logic        write_en [0:N_LANES-1];
    logic [31:0] write_address [0:N_LANES-1];
    logic [31:0] write_data [0:N_LANES-1];
    logic        op_done;

    logic [31:0] mem [0:MEM_DEPTH-1];

    simd #(.n_of_lanes(N_LANES)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .operation_type(operation_type), .n(n),
        .a_address(a_address), .b_address(b_address), .c_address(c_address),
        .read_addr1(read_addr1), .read_data1(read_data1),
        .read_addr2(read_addr2), .read_data2(read_data2),
        .write_en(write_en), .write_address(write_address), .write_data(write_data),
        .op_done(op_done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // zero-delay external memory model
    genvar g;
    generate
        for (g = 0; g < N_LANES; g++) begin : GEN_MEM_RD
            assign read_data1[g] = mem[read_addr1[g]];
            assign read_data2[g] = mem[read_addr2[g]];
        end
    endgenerate

    always_ff @(posedge clk) begin
        for (int i = 0; i < N_LANES; i++) begin
            if (write_en[i]) begin
                mem[write_address[i]] <= write_data[i];
                $display("[%0t] WRITE lane=%0d addr=%0d data=%0d (0x%08x)", $time, i, write_address[i], $signed(write_data[i]), write_data[i]);
            end
        end
    end

    task automatic init_mem();
        for (int i = 0; i < MEM_DEPTH; i++) mem[i] = 32'd0;
    endtask

    task automatic pulse_start();
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
    endtask

    task automatic wait_done();
        int cycles;
        cycles = 0;
        while (op_done !== 1'b1 && cycles < 100) begin
            @(posedge clk);
            cycles++;
        end
        if (cycles >= 100) begin
            $fatal(1, "Timeout waiting for op_done");
        end
        @(posedge clk);
    endtask

    task automatic load_vector(
        input int base_addr,
        input int values[]
    );
        for (int i = 0; i < values.size(); i++) begin
            mem[base_addr + i] = values[i];
        end
    endtask

    task automatic check_vector(
        input string test_name,
        input int base_addr,
        input int expected[]
    );
        for (int i = 0; i < expected.size(); i++) begin
            if ($signed(mem[base_addr + i]) !== expected[i]) begin
                $error("%s mismatch at index %0d: got=%0d expected=%0d", test_name, i, $signed(mem[base_addr + i]), expected[i]);
                $fatal(1, "%s FAILED", test_name);
            end
        end
        $display("%s PASSED", test_name);
    endtask

    task automatic run_add_test();
        int a_vals[] = '{10, 20, 30, 40, 50, 60};
        int b_vals[] = '{1, 2, 3, 4, 5, 6};
        int exp[]    = '{11, 22, 33, 44, 55, 66};

        init_mem();
        load_vector(0, a_vals);
        load_vector(32, b_vals);

        operation_type = 3'b000;
        n             = 6;
        a_address     = 0;
        b_address     = 32;
        c_address     = 64;

        pulse_start();
        wait_done();
        check_vector("vector_add_n6", 64, exp);
    endtask

    task automatic run_sub_test();
        int a_vals[] = '{100, 90, 80, 70};
        int b_vals[] = '{1, 2, 3, 4};
        int exp[]    = '{99, 88, 77, 66};

        init_mem();
        load_vector(8, a_vals);
        load_vector(40, b_vals);

        operation_type = 3'b001;
        n             = 4;
        a_address     = 8;
        b_address     = 40;
        c_address     = 80;

        pulse_start();
        wait_done();
        check_vector("vector_sub_n4", 80, exp);
    endtask

    task automatic run_small_partial_test();
        int a_vals[] = '{7, 8};
        int b_vals[] = '{2, 3};
        int exp[]    = '{9, 11};

        init_mem();
        load_vector(12, a_vals);
        load_vector(20, b_vals);

        operation_type = 3'b000;
        n             = 2;
        a_address     = 12;
        b_address     = 20;
        c_address     = 28;

        pulse_start();
        wait_done();
        check_vector("vector_add_n2_partial_lane", 28, exp);
        if (mem[30] !== 0 || mem[31] !== 0) begin
            $fatal(1, "Unexpected write from disabled lanes in partial test");
        end
    endtask

    task automatic run_vector_test(
        input string test_name,
        input logic [2:0] op_sel,                  // 3'b000 = add, 3'b001 = sub
        input int vec_len,
        input int base_a,
        input int base_b,
        input int base_out,
        input int vec_a[],
        input int vec_b[]
    );
        int i;
    begin
        $display("==============================================");
        $display("TEST: %s", test_name);
        if (op_sel == 3'b000)
            $display("OPERATION: VECTOR ADD");
        else if (op_sel == 3'b001)
            $display("OPERATION: VECTOR SUB");
        else
            $display("OPERATION: UNKNOWN");

        $display("\nLoading input vectors into external memory...");

        //initialize memory and load vectors
        init_mem();
        load_vector(base_a, vec_a);
        load_vector(base_b, vec_b);

        // Print A vector first
        $display("\nA vector:");
        for (i = 0; i < vec_len; i++) begin
            $display("  A[%0d] @ addr %0d = %0d (0x%08h)", 
                    i, 
                    base_a + i, 
                    $signed(vec_a[i]), 
                    vec_a[i]);
        end

        // Print B vector second
        $display("\nB vector:");
        for (i = 0; i < vec_len; i++) begin
            $display("  B[%0d] @ addr %0d = %0d (0x%08h)", 
                    i, 
                    base_b + i, 
                    $signed(vec_b[i]), 
                    vec_b[i]);
        end

        // Apply control inputs
        @(negedge clk);
        start      = 1'b1;
        operation_type = op_sel;
        n          = vec_len;
        a_address  = base_a;
        b_address  = base_b;
        c_address  = base_out;

        @(negedge clk);
        start = 1'b0;

        // Wait for done
        wait(op_done == 1'b1);
        @(negedge clk);

        // Print output
        $display("\nResult vector:");
        for (i = 0; i < vec_len; i++) begin
            $display("  C[%0d] @ addr %0d = %0d (0x%08h)", 
                    i, 
                    base_out + i, 
                    $signed(mem[base_out + i]), 
                    mem[base_out + i]);
        end

        $display("END TEST: %s", test_name);
        $display("==============================================\n");
    end
    endtask

    int a_add[] = '{1,2,3,4,5,6,7,8,9,10};
    int b_add[] = '{10,20,30,40,50,60,70,80,90,100};

    initial begin
        rst_n = 0;
        start = 0;
        operation_type = 3'b000;
        n = 0;
        a_address = 0;
        b_address = 0;
        c_address = 0;
        init_mem();

        repeat (3) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        run_add_test();
        run_sub_test();
        run_small_partial_test();
        run_vector_test(
            "ADD_TEST_N10",
            3'b000,
            a_add.size(),
            0, 32, 64,
            a_add,
            b_add
        );
        $display("All tests passed.");
        $finish;
    end
endmodule
