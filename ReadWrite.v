`timescale 1ns / 1ps

module ReadWrite(
        input useClk,
        input checkData,
        input [3:0] AddrData,
        input [7:0] inputData,
        output [7:0] outputdata,

        input oe
        );

    reg [7:0] mem [7:0];

    always @ (posedge useClk) begin
        if (oe && checkData)
            mem[AddrData] <= inputData;
    end

    assign outputdata = mem[AddrData];
    
endmodule
