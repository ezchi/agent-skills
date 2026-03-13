initial begin
    $display("Starting self-checking test...");

    {{stimulus_sequence}}

    if ({{pass_condition}}) begin
        $display("TEST PASS");
    end else begin
        $display("TEST FAIL");
    end

    delay_cc(2);
    $finish;
end
