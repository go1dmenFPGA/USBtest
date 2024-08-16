`timescale 1ns / 1ps

module ACK(input useClk,
           input answerACK,
           input checkData,
           output reg readyAnswerAck = 0,
           output reg OE_ACK = 0,
           output reg callEopAck = 0);

    (* dont_touch = "true" *) reg [5:0] counterAnswerAck = 0;

    always @(posedge useClk) begin
        if (checkData && answerACK) 
            OE_ACK <= 1;
        else if (checkData && (counterAnswerAck == 18))
            OE_ACK <= 0;
    end

    always @(posedge useClk) begin
        if (OE_ACK && checkData) begin
            counterAnswerAck <= counterAnswerAck + 1;
            case(counterAnswerAck)
                //----sync----
                0: readyAnswerAck <= 0;
                1: readyAnswerAck <= 0;                 
                2: readyAnswerAck <= 0;
                3: readyAnswerAck <= 0;
                4: readyAnswerAck <= 0;
                5: readyAnswerAck <= 1;
                //----Pid----
                6: readyAnswerAck <= 0;
                7: readyAnswerAck <= 1;
                8: readyAnswerAck <= 0;
                9: readyAnswerAck <= 0;
                10: readyAnswerAck <= 1;
                11: readyAnswerAck <= 0;
                12: readyAnswerAck <= 1;
                13: readyAnswerAck <= 1;
                14: callEopAck <= 1;
                17: callEopAck <= 0;
                18: counterAnswerAck <= 0;
                default: begin
                    readyAnswerAck <= 0;
                end
            endcase
        end
        else if (!OE_ACK && checkData) begin
            counterAnswerAck <= 0;
            readyAnswerAck <= 0;
            callEopAck <= 0;
        end
    end

endmodule