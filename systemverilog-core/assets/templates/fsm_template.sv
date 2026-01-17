module {{module_name}} (
    input  logic i_clk,
    input  logic i_rst,
    input  logic i_start,
    output logic o_done
);

typedef enum logic [1:0] {
    S_IDLE,
    S_BUSY,
    S_DONE
} state_t;

state_t state_curr;
state_t state_next;


always_comb begin
    state_next = state_curr;
    case (state_curr)
        S_IDLE: if (i_start) state_next = S_BUSY;
        S_BUSY: state_next = S_DONE;
        S_DONE: state_next = S_IDLE;
    endcase
end

always_ff @(posedge i_clk) begin
    if (i_rst)
        state_curr <= S_IDLE;
    else
        state_curr <= state_next;
end

assign o_done = (state_curr == S_DONE);

endmodule
