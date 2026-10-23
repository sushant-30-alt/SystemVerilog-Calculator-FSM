
`timescale 1ns / 1ps

module calculator_gui_tb;

    logic clk = 0;
    logic reset = 1;
    logic start = 0;

    logic [3:0] A = 0;
    logic [3:0] B = 0;
    logic [1:0] op = 0;

    logic [7:0] result;
    logic [3:0] remainder;
    logic done;
    logic error;

    integer a_in, b_in, op_in;
    integer scan_status;
    integer request_file;
    integer response_file;
    integer transition_file;

    integer previous_state;
    integer current_state_value;

    // Preserve completion status before the FSM leaves DONE/ERROR.
    integer captured_done;
    integer captured_error;

    calculator_top dut (
        .clk       (clk),
        .reset     (reset),
        .start     (start),
        .A         (A),
        .B         (B),
        .op        (op),
        .result    (result),
        .remainder (remainder),
        .done      (done),
        .error     (error)
    );

    always #5 clk = ~clk;

    // State encoding:
    // 0 = IDLE
    // 1 = EXECUTE
    // 2 = DONE
    // 3 = ERROR
    // 4 = WAIT_RELEASE

    // Initialize status captures and transition log.
    initial begin
        captured_done = 0;
        captured_error = 0;

        previous_state = -1;
        transition_file = $fopen("fsm_transitions.txt", "w");

        if (transition_file == 0)
            $display("ERROR: Cannot create fsm_transitions.txt");
    end

    // Record actual state changes from calculator_top.
    always @(dut.current_state) begin
        current_state_value = dut.current_state;

        $display(
            "TB_STATE_DEBUG: state=%0d start=%0b done=%0b error=%0b time=%0t",
            current_state_value, start, done, error, $time
        );

        if (transition_file != 0 &&
            current_state_value !== previous_state) begin

            $fwrite(
                transition_file, "%0d\n",
                current_state_value
            );
            $fflush(transition_file);

            previous_state = current_state_value;
        end
    end

    initial begin
        // Reset the calculator.
        repeat (2) @(negedge clk);
        reset = 0;

        // Read the request written by Python.
        request_file = $fopen("request.txt", "r");

        if (request_file == 0) begin
            $display("ERROR: Cannot open request.txt");
            $finish;
        end

        scan_status = $fscanf(
            request_file, "%d %d %d",
            a_in, b_in, op_in
        );

        $fclose(request_file);

        if (scan_status != 3) begin
            $display("ERROR: Invalid request format");
            $finish;
        end

        if (a_in < 0 || a_in > 15 ||
            b_in < 0 || b_in > 15 ||
            op_in < 0 || op_in > 3) begin
            $display("ERROR: Input out of range");
            $finish;
        end

        // Apply the request.
        @(negedge clk);
        A = a_in;
        B = b_in;
        op = op_in;
        start = 1;

        // The FSM captures the request at the next rising edge.
        @(negedge clk);
        start = 0;

        // Wait for completion or an error.
        wait (done || error);

        // Capture status NOW, while DONE/ERROR is asserted.
        captured_done = done;
        captured_error = error;

        // Wait for WAIT_RELEASE (state code 4).
        wait (dut.current_state == 3'b100);

        // start is already low; wait for the FSM to return to IDLE.
        wait (dut.current_state == 3'b000);

        // Allow the transition monitor to flush its last update.
        #1;

        // Write the machine-readable response.
        response_file = $fopen("response.txt", "w");

        if (response_file == 0) begin
            $display("ERROR: Cannot create response.txt");

            if (transition_file != 0)
                $fclose(transition_file);

            $finish;
        end

        $fwrite(
            response_file, "%0d %0d %0d %0d\n",
            result, remainder, captured_done, captured_error
        );

        $fclose(response_file);

        $display(
            "GUI_SIM_PASS: A=%0d B=%0d OP=%0d RESULT=%0d REM=%0d DONE=%0d ERROR=%0d",
            a_in, b_in, op_in, result, remainder,
            captured_done, captured_error
        );

        if (transition_file != 0)
            $fclose(transition_file);

        $finish;
    end

    // Safety timeout.
    initial begin
        #1000;
        $display("ERROR: Simulation timeout");

        if (transition_file != 0)
            $fclose(transition_file);

        $finish;
    end

endmodule
