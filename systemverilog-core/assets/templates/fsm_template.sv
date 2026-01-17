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

// State_Next State_Curr Logic
always_comb begin
    state_next = S_XXX; // Pre-default 'x assignment

    case (state_curr)
        S_IDLE: begin
            if (i_in1) state_next = S_STATE_1;
            else       state_next = S_IDLE;
        end

        S_STATE_1: begin
            state_next = S_STATE_2;
        end

        S_STATE_2: begin
            if (!i_in2) state_next = S_IDLE;
            else        state_next = S_STATE_1;
        end

        default: state_next = S_XXX;
    endcase
end

// Registered Output Logic
// Calculated from 'state_next' state_curr to avoid 1-cycle latency relative to state_curr transition
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_out1 <= '0;
        o_out2 <= '0;
    end
    else begin
        // Default assignments
        o_out1 <= '0;
        o_out2 <= '0;

        // Re-implementing specific Example 16 logic for correctness with the paper's style:
        case (state_next)
            S_IDLE:    begin
                if (state_curr == S_STATE_2 && !i_in2) o_out2 <= '1;
            end
            S_STATE_1: o_out1 <= '1;
            S_STATE_2: o_out1 <= '1;
            default:   {o_out1, o_out2} <= 'x;
        endcase
    end
end

endmodule
