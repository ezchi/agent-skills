`default_nettype none

module {{module_name}} (
    output logic o_out1,
    output logic o_out2,
    input  logic i_in1,
    input  logic i_in2,
    input  logic i_clk,
input  logic i_rst
);

// Enumerated state_curr type
typedef enum logic [1:0] {
    S_IDLE,
    S_STATE_1,
    S_STATE_2,
    S_XXX = 'x
} state_t;

state_t state_curr;
state_t state_next;

// State_Curr Register
always_ff @(posedge i_clk) begin
    if (i_rst) state_curr <= S_IDLE;
    else       state_curr <= state_next;
end

// State_Next State_Curr and Output Logic
always_comb begin
    state_next   = S_XXX; // Pre-default 'x assignment for debug
    o_out1 = '0;    // Default output assignments
    o_out2 = '0;

    case (state_curr)
        S_IDLE: begin
            if (i_in1) state_next = S_STATE_1;
            else       state_next = S_IDLE; // Loopback
        end

        S_STATE_1: begin
            o_out1 = '1; // Combinatorial output assignment
            state_next   = S_STATE_2;
        end

        S_STATE_2: begin
            o_out1 = '1;
            if (!i_in2) begin
                o_out2 = '1;
                state_next   = S_IDLE;
            end
            else begin
                state_next = S_STATE_1;
            end
        end

        default: begin
            state_next   = S_XXX;
            o_out1 = 'x;
            o_out2 = 'x;
        end
    endcase
end

endmodule

`default_nettype wire
