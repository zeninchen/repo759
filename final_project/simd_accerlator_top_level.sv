module simd(
    input logic clk,
    input logic rst_n,

    //start should be high for one cycle, and will be ignored until the op_done goes high again
    input logic start,
    input logic [1:0] operation_type,
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
    //we need to do n/n_of_lanes
    //the n_of_lanes will be 2^x, so we can just do n >> x to ge the number of repeated operation
    //we also need  a low bit mask, to identify if there is any additional cycles that does not use all the lanes
    // for example if lanes =4 =2^x; x = 2, n >> 2 to get the number of repeated operation,
    // and n && 32h'00000003 (last 2 bit 1)
    localparam shift_bits = 2; 2^shift_bits=4;
    localparam bit_masks = 32'h00000003

    


endmodule