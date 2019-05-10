`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2019 02:49:17 PM
// Design Name: 
// Module Name: keyReceive
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

//needs to skip keyReleased Data
module keyReceive(kdata, kclk, kout, oflag);
    input kdata, kclk;
    output reg [7:0]kout;
    output reg oflag;//set to HIGH if the data has been fully transmitted, LOW if in progress
    reg [63:0] count2;
    
    reg [31:0] count = 32'd0;
    
    always @(negedge kclk) begin
        case(count)
        0:;
        1: kout[0] = kdata;
        2: kout[1] = kdata;
        3: kout[2] = kdata;
        4: kout[3] = kdata;
        5: kout[4] = kdata;
        6: kout[5] = kdata;
        7: kout[6] = kdata;
        8: kout[7] = kdata;
        9:;
        10: begin
                count = 32'b0;
                count2 = count2 + 64'b1;
            end
        endcase
        if(kdata == 1'b0 && count == 32'b0) begin
            count = count + 32'b1;
        end
        else if (count > 32'd0)begin
            count = count + 32'b1;
        end 
        if(count2%32'd3 == 32'd0) begin
            oflag = 1'b1;
        end else begin
            oflag = 1'b0;
        end         
    end        
endmodule