`default_nettype none

module {{module_name}} (
    output logic o_out1,
    output logic o_out2,
    input  logic i_in1,
    input  logic i_in2,
    input  logic i_clk,
    input  logic i_rst
);

logic out1_c;
logic out2_c; // State_Next combinatorial outputs

// Enumerated state_curr type
typedef enum logic [1:0] {
    S_IDLE,
    S_STATE_1,
    S_STATE_2,
    S_XXX = 'x
} state_t;

state_t state_curr;
state_t state_next;

// State Register
always_ff @(posedge i_clk) begin
    if (i_rst) state_curr <= S_IDLE;
    else       state_curr <= state_next;
end

// Next-State Logic
always_comb begin
    state_next = S_XXX; // Pre-default 'x assignment

    unique case (state_curr)
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

// State_Next Output Logic (Combinatorial)
always_comb begin
    out1_c = '0;
    out2_c = '0;

    unique case (state_curr)
        S_IDLE: begin
            if (i_in1) out1_c = '1;
        end

        S_STATE_1: begin
            out1_c = '1;
        end

        S_STATE_2: begin
            if (!i_in2) begin
                out2_c = '1;
            end
            else begin
                out1_c = '1;
            end
        end

        default: {out1_c, out2_c} = 'x;
    endcase
end

// Output Register
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_out1 <= '0;
        o_out2 <= '0;
    end
    else begin
        o_out1 <= out1_c;
        o_out2 <= out2_c;
    end
end

endmodule

`default_nettype wire
