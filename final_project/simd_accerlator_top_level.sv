module simd(
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
    output logic [31:0] read_address[0:n_of_lanes],
    //should be immediate feedback to read_data
    input logic [31:0] read_data [0:n_of_lanes],

    //output logics, the accelator will slowly write the values into the memory
    output logic write_en[0:n_of_lanes],
    output logic [31:0] write_address[0:n_of_lanes],
    output logic [31:0] write_data[0:n_of_lanes],

    //indicates when the operation is finished
    output logic op_done

);
    parameter n_of_lanes =4;
    //three stages -> load, execute, writeback
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
        .read_address(read_address),
        .read_data(read_data),
        .write_en(write_en),
        .write_address(write_address),
        .write_data(write_data),
        .op_done(op_done)
    );

    


endmodule