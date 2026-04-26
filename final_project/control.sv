module control#(
    parameter int n_of_lanes = 4
)(
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

    output logic [31:0] read_addr1[0:n_of_lanes-1],
    output logic [31:0] read_addr2[0:n_of_lanes-1],
    output logic enable_alu[0:n_of_lanes-1], //to enable the alu for each lane
    output logic write_en[0:n_of_lanes-1],
    output logic [31:0] write_address[0:n_of_lanes-1],
    output logic op_done,
    output logic [1:0] alu_op //to indicate the operation type for the alu
);
    //we need to do n/n_of_lanes
    //the n_of_lanes will be 2^x, so we can just do n >> x to ge the number of repeated operation
    //we also need  a low bit mask, to identify if there is any additional cycles that does not use all the lanes
    // for example if lanes =4 =2^x; x = 2, n >> 2 to get the number of repeated operation,
    // and n && 32h'00000003 (last 2 bit 1)
    localparam shift_bits = $clog2(n_of_lanes); //2^shift_bits=4;
    localparam bit_masks = 32'hFFFF_FFFF >> (32-shift_bits); //if n_of_lanes =4, shift_bits =2, bit_masks = 0x0000_0003


    ////reduction basics///////
    //for reduction we will use interleaved addressing
    //we start with stride =1, and then double the stride evry iteration, until is more or equal to n/2
    ///////////////////////////
    logic [31:0] stride; //to calculate the stride for reduction
    logic step_complete; //signal to indicate we finish a step and it time to increse the stride
    typedef enum logic [1:0] { 
        IDLE,
        EX,
        STEP,
        DONE
     } state_t;
     state_t state, next_state;
     always_ff @( posedge clk or negedge rst_n) begin : state_transition
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end       
     end

    logic [31:0] op_count; //to count how many operations we have done
    /* we still need to determine if there are any additional cycles that does not use all the lanes,
     for example if n = 6, and n_of_lanes =4, we need to do 2 operations, but the second operation
      only uses 2 lanes, so we need to identify this case to determine when the operation is complete*/
    logic full_lane_complete; //to identify if the last operation has extra cycle
    logic additional_op; //to identify if we have an additional cycle that does not use all the lanes

    assign full_lane_complete = (op_count == 0); //if op_count is 0, and there are still some bits left in n, then we have a full lane complete
    assign additional_op = ((n & bit_masks) != 0); //if there are still some bits left in n, then we have an additional cycle
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op_count <= 32'd0;
        end else if (start && state == IDLE) begin
            op_count <= n >> shift_bits;
        end else if (state == EX && op_count != 0) begin
            op_count <= op_count - 1;
        end
    end

    logic [31:0] address_offset; //to calculate the address offset for each lane
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
        address_offset <= 0;
        end else if (state == IDLE && start) begin
            address_offset <= 0;
        end else if(state == EX) begin
            //address_offset <= address_offset + (n_of_lanes * 4); //each lane processes 4 bytes (32 bits) of data
            address_offset <= address_offset + (n_of_lanes); //the memory is in array form
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stride <= 1;
        end else if (state == IDLE && start) begin
            stride <= 1;
        end else if (step_complete == 1'b1) begin
            stride <= stride << 1; //shift left by 1 is the same as multiply by 2
        end
    end
    //combinational logic to determine the next state
    always_comb begin : state_comb
        next_state = state; //default to stay in the same state
        read_addr1 = '{default:32'b0}; //default to 0
        read_addr2 = '{default:32'b0}; //default to 0
        enable_alu = '{default:1'b0}; //default to disable
        op_done = 1'b0; //default to not done
        alu_op = 2'b00; //default to addition
        //default the write enable and write address to 0, we will set them in the execute stage, since they are related to the alu enable and address offset
        write_en = '{default:1'b0};
        write_address = '{default:32'b0};
        unique case(state)
            IDLE: begin
                if (start) begin
                    next_state = EX;                  
                end            
            end
            EX: begin
                if (operation_type[2:1] == 2'b00) begin
                    alu_op = {1'b0, operation_type[0]};
                    //these will unroll to the lanes we need
                    for (int i = 0; i < n_of_lanes; i++) begin
                        read_addr1[i] = a_address + address_offset + i;
                        read_addr2[i] = b_address + address_offset + i;
                        if (full_lane_complete)
                            enable_alu[i] = additional_op && (i < (n & bit_masks));
                        else
                            enable_alu[i] = 1'b1;
                        write_en[i] = enable_alu[i];
                        write_address[i] = c_address + address_offset + i;
                    end
                    if (full_lane_complete) next_state = DONE;
                end else if(operation_type[2:1] == 2'b01) begin
                    //reduction
                    alu_op = {1'b1, operation_type[0]};
                    for(int i = 0; i < n_of_lanes; i++) begin
                    end
                end else begin
                    next_state = DONE;
                end
            end
            STEP: begin
                //we can directly go to done, since we will write the data in the same cycle as we prepare the data
                next_state = DONE;
            end
            DONE: begin
                op_done = 1'b1; //indicate the operation is done
                next_state = IDLE; //go back to idle state, and wait for the next start signal
            end
        endcase
    end
endmodule