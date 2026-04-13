module iir_filter(
    input signed [3:0] x, b0, b1, a1,
    input clk, arst,
    output reg signed [7:0] y);

    reg signed [3:0] x_d1;
    reg signed [7:0] y_d1;

    wire signed [7:0] a1_ext;

    assign a1_ext = {{4{a1[3]}}, a1};

    wire signed [15:0] a1_mul;  
    wire signed [7:0] a1_trunc;

    assign a1_mul = a1_ext * y_d1;
    assign a1_trunc = a1_mul[11:4];

    always @(posedge clk or negedge arst) begin
        if (!arst) begin
            x_d1  <= '0;
            y_d1  <= '0;
            y <= '0;
        end else begin
            

            y <= (b0 * x) + (b1 * x_d1) + a1_trunc;
            
            // update delays
            x_d1 <= x;
            y_d1 <= y;
        end
    end

endmodule