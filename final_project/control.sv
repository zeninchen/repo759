module control(
    input logic clk,
    input logic rst_n,
    input logic start,
    // 000 is vector add,
    // 001 is vector subtract,
    // 010 is vector reduction(add)
    input logic [2:0] operation_type,
    input logic [31:0] n, 
    input logic [31:0] a_address, 
    input logic [31:0] b_address, 
    input logic [31:0] c_address,
    output logic [31:0] read_address[0:n_of_lanes],
    input logic [31:0] read_data [0:n_of_lanes],
    output logic write_en[0:n_of_lanes],
    output logic [31:0] write_address[0:n_of_lanes],
    output logic [31:0] write_data[0:n_of_lanes],
    output logic op_done
);
    parameter n_of_lanes =4;
    //we need to do n/n_of_lanes
    //the n_of_lanes will be 2^x, so we can just do n >> x to ge the number of repeated operation
    //we also need  a low bit mask, to identify if there is any additional cycles that does not use all the lanes
    // for example if lanes =4 =2^x; x = 2, n >> 2 to get the number of repeated operation,
    // and n && 32h'00000003 (last 2 bit 1)
    localparam shift_bits = $clog2(n_of_lanes); //2^shift_bits=4;
    localparam bit_masks = 32'hFFFF_FFFF >> (32-shift_bits); //if n_of_lanes =4, shift_bits =2, bit_masks = 0x0000_0003
    typedef enum logic [1:0] { 
        IDLE,
        EX,
        BUFF,
        DONE
     } state_t;
     state_t state, next_state;
     always_ff @( clk ) begin : state_transition
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end       
     end

    //combinational logic to determine the next state
    always_comb begin : state_comb
        
    end
endmodule