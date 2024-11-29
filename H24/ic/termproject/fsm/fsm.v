// States are:
// 00: Idle
// 10: Read
// 11: Write
// 01: Stable

module fsm (
    input op,
    input select,
    output reg valid,
    output reg rw
);

    // State encoding
    parameter IDLE = 2'b00, WRITE = 2'b01, READ = 2'b10, STABLE = 2'b11;
   
    reg [1:0] state, next_state;

    // State transitions (combinational logic)
    always @(*) begin
        case (state)
            IDLE: begin
                valid = 0;
                rw = 0;
                if (select == 1) begin
                    if (op == 1) 
                        next_state = WRITE;
                    else 
                        next_state = READ;
                end else 
                    next_state = IDLE;
            end

            WRITE: begin
                valid = 1;
                rw = 1;
                next_state = STABLE; // Automatically transition to STABLE after WRITE
            end

            READ: begin
                valid = 1;
                rw = 0;
                next_state = IDLE; // Automatically transition to IDLE after READ
            end

            STABLE: begin
                valid = 0;
                rw = 1;
                next_state = IDLE; // Automatically transition to IDLE after STABLE
            end

            default: next_state = IDLE;
        endcase
    end

    // Continuous state update
    always @(*) begin
        state = next_state;
    end

endmodule
