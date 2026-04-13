`timescale 1ns/1ps
module iir_filter_tb();
    reg signed [3:0] x, b0, b1, a1;
    reg clk, arst;
    wire signed [7:0] y;

    iir_filter dut(.x(x), .b0(b0), .b1(b1), .a1(a1), .clk(clk), .arst(arst), .y(y));

initial clk = 1;
always #50 clk = ~clk;
 
initial 
begin
   arst = 0;
   #10;
   arst = 1;
  /*//test1 (LPF)
   b0 = 'd3;
   b1 = 'd0;
   a1 = 'd4;
   x = 'd0;
   #20;
   x = 'd5;
   #1000;
   //test2 (HPF)
  b0 = 4'd2;
  b1 = -4'sd2;
  a1 = -4'sd4;
  x  = 4'd0;
  #20;
  x  = 4'd5;
 #1000;
   //test3 (Impulse Response)
   b0 = 'd3;
   b1 = 'd3;
   a1 = 'd7;
   x = 'd0;
   #70
   x = 'd5;
   #70;
   x = 'd0;
   #1000;
   //test4 (Smoothing rapid changes)
   b0 = 'd1;
   b1 = 'd1;
   a1 = 'd4;
   #70
   while (1) begin
       x = 'd2;
     #100;
       x = 'd6;
     #100;
    end
   #2000;*/
   //test5 (overflow failure)
   b0 = 'd7;
   b1 = 'd7;
   a1 = 'd6;
   x = 'd0;
   #20;
   x = 'd7;
   #5000;
  /*//EXTRA TESTS
   //test6 (overflow(min))
   b0 = 'd7;
   b1 = 'd7;
   a1 = 'd6;
   x = 'd0;
   #20;
   x = -'sd7;
   #5000;

   //test7 (zero output)
   b0 = 'd1;
   b1 = 'd1;
   a1 = 'd1;
   x = 'd0;
   #1000;
   
   //test8 (dc input)
   b0 = 'd1;
   b1 = 'd0;
   a1 = -'sd1;
   x = 'd2;
   #1000;
*/
   $stop;
end

endmodule