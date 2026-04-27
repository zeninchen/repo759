`timescale 1ns/1ps

module tb_reduction;

    localparam int N_LANES   = 4;
    localparam int MEM_DEPTH = 256;
    localparam int B_OFFSET  = 128;

    localparam logic [2:0] REDUCE_ADD_OP = 3'b010;

    // ================= SIGNALS =================
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

    logic op_done;

    logic [31:0] mem [0:MEM_DEPTH-1];

    // ================= DUT =================
    simd #(.n_of_lanes(N_LANES)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .operation_type(operation_type),
        .n(n),
        .a_address(a_address),
        .b_address(b_address),
        .c_address(c_address),
        .read_addr1(read_addr1),
        .read_data1(read_data1),
        .read_addr2(read_addr2),
        .read_data2(read_data2),
        .write_en(write_en),
        .write_address(write_address),
        .write_data(write_data),
        .op_done(op_done)
    );

    // ================= CLOCK =================
    initial clk = 0;
    always #5 clk = ~clk;

    // ================= MEMORY MODEL WITH WRITEBACK BYPASS =================
    genvar g;
    generate
        for (g = 0; g < N_LANES; g++) begin : GEN_MEM_RD_BYPASS
            always @(*) begin
                // default: normal 0-delay memory read
                read_data1[g] = mem[read_addr1[g]];
                read_data2[g] = mem[read_addr2[g]];

                // bypass writeback data if same-cycle read/write address match
                for (int w = 0; w < N_LANES; w++) begin
                    if (write_en[w] && (write_address[w] == read_addr1[g])) begin
                        read_data1[g] = write_data[w];
                    end

                    if (write_en[w] && (write_address[w] == read_addr2[g])) begin
                        read_data2[g] = write_data[w];
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        for (int i = 0; i < N_LANES; i++) begin
            if (write_en[i]) begin
                mem[write_address[i]] <= write_data[i];
                $display("[%0t] WRITE lane=%0d addr=%0d data=%0d (0x%08h)",
                         $time, i, write_address[i],
                         $signed(write_data[i]), write_data[i]);
            end
        end
    end
    // ================= TASKS =================

    task automatic init_mem();
        for (int i = 0; i < MEM_DEPTH; i++) begin
            mem[i] = 0;
        end
    endtask

    task automatic load_vector(
        input int base,
        input int vec[]
    );
        for (int i = 0; i < vec.size(); i++) begin
            mem[base + i] = vec[i];
        end
    endtask

    task automatic print_region(
        input string name,
        input int base,
        input int len
    );
        $display("\n%s:", name);
        for (int i = 0; i < len; i++) begin
            $display("  [%0d] addr=%0d val=%0d",
                     i, base + i, $signed(mem[base + i]));
        end
    endtask

    // ⭐ PIPELINE DEBUG (MAIN FEATURE)
    task automatic print_pipeline_activity();
        $display("\n[%0t] ================ PIPELINE ================", $time);

        for (int lane = 0; lane < N_LANES; lane++) begin
            $display(
                "lane %0d | RD1: addr=%0d val=%0d | RD2: addr=%0d val=%0d || WB: en=%0b addr=%0d val=%0d",
                lane,
                read_addr1[lane], $signed(read_data1[lane]),
                read_addr2[lane], $signed(read_data2[lane]),
                write_en[lane], write_address[lane], $signed(write_data[lane])
            );
        end

        $display("============================================\n");
    endtask

    // ================= TEST =================
    task automatic run_reduction_test(
        input string name,
        input int base_a,
        input int vec[]
    );
        int expected;
        int cycles;
        int base_b;

    begin
        expected = 0;
        for (int i = 0; i < vec.size(); i++) begin
            expected += vec[i];
        end

        base_b = base_a + B_OFFSET;

        init_mem();
        load_vector(base_a, vec);

        operation_type = REDUCE_ADD_OP;
        n             = vec.size();
        a_address     = base_a;
        b_address     = base_b;
        c_address     = 0;

        $display("\n====================================");
        $display("TEST: %s", name);
        $display("Expected sum = %0d", expected);

        print_region("Initial A", base_a, vec.size());

        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        cycles = 0;

        while (op_done !== 1 && cycles < 300) begin
            @(posedge clk);
            #1;

            print_pipeline_activity();

            cycles++;
        end

        if (cycles >= 300) begin
            $fatal("Timeout");
        end

        @(posedge clk);
        #1;

        print_region("Final A", base_a, vec.size());
        print_region("Final B", base_b, vec.size());

        $display("\nResult (check A[0] or B[0]) = %0d", $signed(mem[base_a]));

        $display("====================================\n");
    end
    endtask

    // ================= TEST VECTORS =================
    int v1[] = '{1,2,3,4,5,6,7,8,9,10};
    int v2[] = '{10,20,30,40,50,60,70,80};
    int v3[] = '{7,8,9};

    // ================= MAIN =================
    initial begin
        rst_n = 0;
        start = 0;

        init_mem();

        repeat(3) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        run_reduction_test("REDUCE_N10", 0, v1);
        run_reduction_test("REDUCE_N8",  32, v2);
        run_reduction_test("REDUCE_N3",  64, v3);

        $display("ALL DONE");
        $finish;
    end

endmodule