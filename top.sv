`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2019 04:03:19 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(clk, PS2Data, PS2Clk, an, c, sw, led, btnC);
    input clk, PS2Clk, PS2Data;//start bit(0), 8-bit scan code, odd parity, stop bit(1)
    input [3:0] sw;
    input btnC;
    output reg[15:0] led;
    output reg[0:6] c;
    output reg[3:0] an;
    reg[15:0] memory[0:15];//16-bit word memory with 4-bit addresses
    
    parameter zero = 7'b0000001;
    parameter one = 7'b1001111;
    parameter two = 7'b0010010;
    parameter three = 7'b0000110;
    parameter four = 7'b1001100;
    parameter five = 7'b0100100;
    parameter six = 7'b0100000;
    parameter seven = 7'b0001111;
    parameter eight = 7'b0000000;
    parameter nine = 7'b0000100;
    parameter A = 7'b0001000;
    parameter B = 7'b1100000;
    parameter C = 7'b0110001;
    parameter D = 7'b1000010;
    parameter E = 7'b0110000;
    parameter F = 7'b0111000;
    
    reg [7:0] cur;//the current data stream output from the keyboard
    reg [7:0] prev;
    reg [7:0] curA;
    reg [15:0] full;//current display of the 7 segment
    reg rflag;
    reg [31:0] count3;
    int index = 0;//index we are in currently
    //assign cur = PS2Data[9:2];this caused a bitstream error
    reg [63:0] clkCount = 64'd0;
    reg [1:0] anclk;
    assign anclk = clkCount[19:18];
    reg sflag;
    reg shiftflag;
    reg [3:0]switchprev;
    keyReceive kr(PS2Data, PS2Clk, cur, rflag);
    int i;
    reg waitflag;
    
    always @(posedge clk) begin// 100 MHz
        clkCount <= clkCount + 64'd1;
        setIndex;
        //the first thing we should do is check our context and correct it if needed
        if(switchprev != sw[3:0]) begin
            full = memory[index];
            switchprev = sw[3:0];
            for(i=0; i<16; i++) begin
                led[i] = 1'b0;
            end
        end
        if(clkCount % 32'd10_000_000 == 0) begin// 10Hz --> seems to be best for responsiveness and rollover control
            if(btnC == 1'b1) begin
                full >>= 8;
                for(i=0; i<16; i++) begin
                    led[i] = 1'b0;
                end
            end
        end
        //the waitflag here keeps it only writing once when a key is ready
        if(rflag == 1'b1) begin//so if we are ready to receive key signal
            if(waitflag == 1'b0) begin//dont have to wait, write the newly typed character
                //perform operations
                if(cur == 8'h5a) begin
                    memory[index] = full;//save
                    for(i=0; i<16; i++) begin
                        led[i] = 1'b1;
                    end    
                end else begin
                    codeToASCII(cur);//converts the keycodes to ASCII
                    //shift
                    //shiftflag = 1'b1;
                    prev = full[7:0];
                    full[7:0] = curA;
                    full[15:8] = prev;
                    for(i=0; i<16; i++) begin
                        led[i] = 1'b0;
                    end    
                end
                waitflag = 1'b1;//turn the wait flag on so we can wait for the next received keycode
            end
        end else begin//we dont have a ready key, so just turn the wait flag off
            waitflag = 1'b0;
        end    
        updateDisplay;          
    end
    
    task updateDisplay; begin
        case(anclk)
            2'b00: begin
                an = 4'b1110;
                updateNum(full[3:0]);
            end    
            2'b01: begin
                an = 4'b1101;
                updateNum(full[7:4]);
            end
            2'b10: begin
                an = 4'b1011;
                updateNum(full[11:8]);
            end    
            2'b11: begin
                an = 4'b0111;
                updateNum(full[15:12]);
            end        
         endcase
       end
     endtask     
    
    task updateNum( input reg[3:0] num ); begin
        case(num)
            4'd0: c <= zero;
            4'd1: c <= one;
            4'd2: c <= two;
            4'd3: c <= three;
            4'd4: c <= four;
            4'd5: c <= five;
            4'd6: c <= six;
            4'd7: c <= seven;
            4'd8: c <= eight;
            4'd9: c <= nine;
            4'd10: c <= A;
            4'd11: c <= B;
            4'd12: c <= C;
            4'd13: c <= D;
            4'd14: c <= E;
            4'd15: c <= F;
            default: c <= zero;
        endcase  
      end  
    endtask

//I am truly sorry for this case statement but it had to be done
task codeToASCII(input reg[7:0] i); begin
    case(i)
        8'h45: curA = 8'h30;//0
        8'h16: curA = 8'h31;//1
        8'h1e: curA = 8'h32;//2
        8'h26: curA = 8'h33;//3
        8'h25: curA = 8'h34;//4
        8'h2e: curA = 8'h35;//5
        8'h36: curA = 8'h36;//6
        8'h3d: curA = 8'h37;//7
        8'h3e: curA = 8'h38;//8
        8'h46: curA = 8'h39;//9
        8'h4c: curA = 8'h3b;//;
        8'h55: curA = 8'h3d;//=
        8'h1c: curA = 8'h61;//a
        8'h32: curA = 8'h62;//b
        8'h21: curA = 8'h63;//c
        8'h23: curA = 8'h64;//d
        8'h24: curA = 8'h65;//e
        8'h2b: curA = 8'h66;//f
        8'h34: curA = 8'h67;//g
        8'h33: curA = 8'h68;//h
        8'h43: curA = 8'h69;//i
        8'h3b: curA = 8'h6a;//j
        8'h42: curA = 8'h6b;//k
        8'h4b: curA = 8'h6c;//l
        8'h3a: curA = 8'h6d;//m
        8'h31: curA = 8'h6e;//n
        8'h44: curA = 8'h6f;//o
        8'h4d: curA = 8'h70;//p
        8'h15: curA = 8'h71;//q
        8'h2d: curA = 8'h72;//r
        8'h1b: curA = 8'h73;//s
        8'h2c: curA = 8'h74;//t
        8'h3c: curA = 8'h75;//u
        8'h2a: curA = 8'h76;//v
        8'h1d: curA = 8'h77;//w
        8'h22: curA = 8'h78;//x
        8'h35: curA = 8'h79;//y
        8'h1z: curA = 8'h7a;//z
        8'h0e: curA = 8'h60;//`
        8'h4e: curA = 8'h2d;//-
        8'h54: curA = 8'h5b;//[
        8'h5b: curA = 8'h5d;//]
        8'h5d: curA = 8'h5c;//\
        8'h52: curA = 8'h27;//'
        8'h41: curA = 8'h2c;//,
        8'h49: curA = 8'h2e;//.
        8'h4a: curA = 8'h2f;// /
        default: curA = 8'd0;//everything else
      endcase
    end
  endtask
  
  task setIndex; begin
      case(sw[3:0])
        4'd0: index = 0;
        4'd1: index = 1;
        4'd2: index = 2;
        4'd3: index = 3;
        4'd4: index = 4;
        4'd5: index = 5;
        4'd6: index = 6;
        4'd7: index = 7;
        4'd8: index = 8;
        4'd9: index = 9;
        4'd10: index = 10;
        4'd11: index = 11;
        4'd12: index = 12;
        4'd13: index = 13;
        4'd14: index = 14;
        4'd15: index = 15;
      endcase
    end
  endtask  
endmodule
