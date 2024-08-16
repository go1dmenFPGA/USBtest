`timescale 1ns / 1ps

module NAK(input useClk,
           input answerNAK,
           input checkData,
           output reg readyAnswerNAK = 0,
           output reg OE_NAK = 0,
           output reg callEopNAK = 0);

    (* dont_touch = "true" *) reg [5:0] counterAnswerNAK = 0;

    always @(posedge useClk) begin
        if (checkData && answerNAK) 
            OE_NAK <= 1;
        else if (checkData && (counterAnswerNAK == 18))
            OE_NAK <= 0;
    end

    always @(posedge useClk) begin
        if (OE_NAK && checkData) begin
            counterAnswerNAK <= counterAnswerNAK + 1;
            case(counterAnswerNAK)
                //----sync----
                0: readyAnswerNAK <= 0;
                1: readyAnswerNAK <= 0;                 
                2: readyAnswerNAK <= 0;
                3: readyAnswerNAK <= 0;
                4: readyAnswerNAK <= 0;
                5: readyAnswerNAK <= 1;
                //----Pid----
                6: readyAnswerNAK <= 0;
                7: readyAnswerNAK <= 1;
                8: readyAnswerNAK <= 0;
                9: readyAnswerNAK <= 1;
                10: readyAnswerNAK <= 1;
                11: readyAnswerNAK <= 0;
                12: readyAnswerNAK <= 1;
                13: readyAnswerNAK <= 0;
                14: callEopNAK <= 1;
                17: callEopNAK <= 0;
                18: counterAnswerNAK <= 0;
                default: begin
                    readyAnswerNAK <= 0;
                end
            endcase
        end
        else if (!OE_NAK && checkData) begin
            counterAnswerNAK <= 0;
            readyAnswerNAK <= 0;
            callEopNAK <= 0;
        end
    end

endmodule