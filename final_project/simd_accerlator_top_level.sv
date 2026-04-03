module simd #(
    parameter int n_of_lanes = 4
)(
    input logic clk,
    input logic rst_n,

    //start should be high for one cycle, and will be ignored until the op_done goes high again
    input logic start,
    input logic [2:0] operation_type,
    //length of the vectors
    input logic [31:0] n, 

    //the start address of input a
    input logic [31:0] a_address, 
    //the start address of input b(if reduction, operation that only uses one vector, this can be ignored)
    input logic [31:0] b_address, 

    //the start address of the output address
    input logic [31:0] c_address,

    //for this accerlator we will use 32 bit memory address, with memory address 0 delay in this case
    //and memory handled outside
    output logic [31:0] read_addr1[0:n_of_lanes-1],
    //should be immediate feedback to read_data
    input logic [31:0] read_data1 [0:n_of_lanes-1],

    //for this accerlator we will use 32 bit memory address, with memory address 0 delay in this case
    //and memory handled outside
    output logic [31:0] read_addr2[0:n_of_lanes-1],
    //should be immediate feedback to read_data
    input logic [31:0] read_data2 [0:n_of_lanes-1],

    //output logics, the accelator will slowly write the values into the memory
    output logic write_en[0:n_of_lanes-1],
    output logic [31:0] write_address[0:n_of_lanes-1],
    output logic [31:0] write_data[0:n_of_lanes-1],

    //indicates when the operation is finished
    output logic op_done

);
    //three stages -> load(control), execute, writeback

    //////////////////////
    //load(control) stage
    //////////////////////

    //combinational net
    logic cr_enable_alu[0:n_of_lanes-1];
    logic [1:0] cr_alu_op; //to indicate the operation type for the alu
    logic [31:0] cr_read_addr1 [0:n_of_lanes-1];
    logic [31:0] cr_read_addr2 [0:n_of_lanes-1];
    logic cr_write_en[0:n_of_lanes-1];
    logic [31:0] cr_write_address[0:n_of_lanes-1];
    logic cr_op_done;

    //instaniate control
    control #(.n_of_lanes(n_of_lanes)) control_unit(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .operation_type(operation_type),
        .n(n),
        .a_address(a_address),
        .b_address(b_address),
        .c_address(c_address),
        .read_addr1(cr_read_addr1),
        .read_addr2(cr_read_addr2),
        .enable_alu(cr_enable_alu),
        .write_en(cr_write_en),
        .write_address(cr_write_address),
        .op_done(cr_op_done),
        .alu_op(cr_alu_op)
    );

    //pipline reg
    logic cr_ex_enable_alu[0:n_of_lanes-1];
    logic [1:0] cr_ex_alu_op; //to indicate the operation type for the alu
    logic [31:0] cr_ex_read_addr1 [0:n_of_lanes-1];
    logic [31:0] cr_ex_read_addr2 [0:n_of_lanes-1];
    logic cr_ex_write_en[0:n_of_lanes-1];
    logic [31:0] cr_ex_write_address[0:n_of_lanes-1];
    logic cr_ex_op_done;

    always_ff @(posedge clk or negedge rst_n ) begin : cr_ex_pipline
        if(!rst_n) begin
            //default all the reg to 0
            cr_ex_enable_alu <= '{default:1'b0};
            cr_ex_alu_op <= 2'b00;
            cr_ex_read_addr1 <= '{default:32'b0};
            cr_ex_read_addr2 <= '{default:32'b0};
            cr_ex_write_en <= '{default:1'b0};
            cr_ex_write_address <= '{default:32'b0};
            cr_ex_op_done <= 1'b0;
        end
        else begin
            //propagate the next value
            cr_ex_enable_alu <= cr_enable_alu;
            cr_ex_alu_op <= cr_alu_op;
            cr_ex_read_addr1 <= cr_read_addr1;
            cr_ex_read_addr2 <= cr_read_addr2;
            cr_ex_write_en <= cr_write_en;
            cr_ex_write_address <= cr_write_address;
            cr_ex_op_done <= cr_op_done;
        end
    end

    //////////////////
    ///execute stage
    //////////////////

    logic [31:0] ex_write_data[0:n_of_lanes-1];
    //access the external memory
    assign read_addr1 = cr_ex_read_addr1;
    assign read_addr2 = cr_ex_read_addr2;

    //instaniate alu
    genvar i;
    generate
        for (i = 0; i < n_of_lanes; i++) begin : g_alu
            alu alu_unit (
                .a(read_data1[i]),
                .b(read_data2[i]),
                .op(cr_ex_alu_op),
                .enable(cr_ex_enable_alu[i]),
                .result(ex_write_data[i])
            );
        end
    endgenerate

    //pipline reg
    logic [31:0] ex_wb_write_data[0:n_of_lanes-1];
    //these three below are propagated
    logic ex_wb_write_en[0:n_of_lanes-1];
    logic [31:0] ex_wb_write_address[0:n_of_lanes-1];
    logic ex_wb_op_done;

    always_ff @( posedge clk or negedge rst_n) begin : ex_wb_pipline
        if(!rst_n) begin
            //default all the reg to 0
            ex_wb_write_data <= '{default:32'b0};
            ex_wb_write_en <= '{default:1'b0};
            ex_wb_write_address <= '{default:32'b0};
            ex_wb_op_done <= 1'b0;

        end
        else begin
            //propagate the next value
            ex_wb_write_data <= ex_write_data;
            ex_wb_write_en <= cr_ex_write_en;
            ex_wb_write_address <= cr_ex_write_address;
            ex_wb_op_done <= cr_ex_op_done;
        end
    end

    //////////////////
    //writeback stage
    //////////////////

    //simply connect the output ports
    assign op_done = ex_wb_op_done;
    //writes to the external memory
    assign write_en = ex_wb_write_en;
    assign write_data = ex_wb_write_data;
    assign write_address = ex_wb_write_address;


endmodule