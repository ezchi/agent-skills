module {{module_name}} (
    input  logic iClk,
    input  logic iRst,
    input  logic iStart,
    output logic oDone
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
        S_IDLE: if (iStart) state_next = S_BUSY;
        S_BUSY: state_next = S_DONE;
        S_DONE: state_next = S_IDLE;
    endcase
end

always_ff @(posedge iClk) begin
    if (iRst)
        state_curr <= S_IDLE;
    else
        state_curr <= state_next;
end

assign S_DONE = (state_curr == S_DONE);

endmodule
