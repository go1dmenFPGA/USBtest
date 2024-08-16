`timescale 1ns / 1ps

module AnswerSetAddr (input useClk,
                      input answerSetAddr,
                      input checkData,
                      output reg readyAnswerSetAddr = 0,
                      output reg OE_SET_ADDR = 0,
                      output reg callEopSetAddr = 0);

    (* dont_touch = "true" *) reg [5:0] counterAnswerSetAddr = 0;

    always @(posedge useClk) begin
        if (checkData && answerSetAddr) 
            OE_SET_ADDR <= 1;
        else if (checkData && (counterAnswerSetAddr == 34))
            OE_SET_ADDR <= 0;
    end

    always @(posedge useClk) begin
        if (OE_SET_ADDR && checkData) begin
            counterAnswerSetAddr <= counterAnswerSetAddr + 1;
            case(counterAnswerSetAddr)
                //----sync----
                0: readyAnswerSetAddr <= 0;
                1: readyAnswerSetAddr <= 0;                 
                2: readyAnswerSetAddr <= 0;
                3: readyAnswerSetAddr <= 0;
                4: readyAnswerSetAddr <= 0;
                5: readyAnswerSetAddr <= 1;
                //----Pid----
                6: readyAnswerSetAddr <= 1;
                7: readyAnswerSetAddr <= 1;
                8: readyAnswerSetAddr <= 0;
                9: readyAnswerSetAddr <= 1;
                10: readyAnswerSetAddr <= 0;
                11: readyAnswerSetAddr <= 0;
                12: readyAnswerSetAddr <= 1;
                13: readyAnswerSetAddr <= 0;
                //----DATA---
                14: readyAnswerSetAddr <= 0;
                15: readyAnswerSetAddr <= 0;
                16: readyAnswerSetAddr <= 0;
                17: readyAnswerSetAddr <= 0;
                18: readyAnswerSetAddr <= 0;
                19: readyAnswerSetAddr <= 0;
                20: readyAnswerSetAddr <= 0;
                21: readyAnswerSetAddr <= 0;
                22: readyAnswerSetAddr <= 0;
                23: readyAnswerSetAddr <= 0;
                24: readyAnswerSetAddr <= 0;
                25: readyAnswerSetAddr <= 0;
                26: readyAnswerSetAddr <= 0;
                27: readyAnswerSetAddr <= 0;
                28: readyAnswerSetAddr <= 0;
                29: readyAnswerSetAddr <= 0;
                30: callEopSetAddr <= 1;
                33: callEopSetAddr <= 0;
                34: counterAnswerSetAddr <= 0;
                default: begin
                    readyAnswerSetAddr <= 0;
                end
            endcase
        end
        else if (!OE_SET_ADDR && checkData) begin
            counterAnswerSetAddr <= 0;
            readyAnswerSetAddr <= 0;
            callEopSetAddr <= 0;
        end
    end

endmodule