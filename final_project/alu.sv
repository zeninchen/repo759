module alu(
    input logic [31:0] a, b,
    input logic [1:0] op,
    output logic [31:0] result
)
    //for now, we will only implement addition and subtraction
    always_comb begin
        case (op)
            2'b00: result = a + b; // addition
            2'b01: result = a - b; // subtraction
            default: result = 32'b0; // default case
        endcase
    end
endmodule