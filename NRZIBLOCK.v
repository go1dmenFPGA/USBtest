`timescale 1ns / 1ps

module NRZIBLOCK(input useClk,
                 input checkData,
                 input readyAnswerAck,
                 input readyAnswerDesc,
                 input OE_ACK,
                 input OE_DESC,
                 input callEopAck,
                 input callEopDesc,
                 output reg NRZI = 0,
                 output reg NRZI_not = 1);

    reg readyAnswerAckReg;
    reg readyAnswerDescReg;
    reg [2:0] counterUnitNrzi = 0;
    reg [2:0] eopCount = 0;

    always @(posedge useClk) begin
        readyAnswerAckReg <= readyAnswerAck;
        readyAnswerDescReg <= readyAnswerDesc;
    end

    always @(posedge useClk) begin
        if (checkData && (OE_DESC || OE_ACK)) begin
            if ((readyAnswerDescReg && readyAnswerDesc) || (readyAnswerAckReg && readyAnswerAck)) begin
                if (counterUnitNrzi == 5)
                    counterUnitNrzi <= 0;
                else 
                    counterUnitNrzi <= counterUnitNrzi + 1;
            end
            else 
                counterUnitNrzi <= 0;
        end
    end

    always @(posedge useClk) begin
        if (checkData && OE_ACK && !callEopAck) begin
            if (!readyAnswerAck && (counterUnitNrzi != 5)) begin
                NRZI <= ~NRZI;
                NRZI_not <= ~NRZI_not;
            end
            else if (readyAnswerAck && (counterUnitNrzi != 5)) begin
                NRZI <= NRZI;
                NRZI_not <= NRZI_not;
            end
            else if (counterUnitNrzi == 5) begin
                NRZI <= 0;
                NRZI_not <= 1;
            end
        end
        else if (checkData && OE_DESC && !callEopDesc) begin
            if (!readyAnswerDesc && (counterUnitNrzi != 5)) begin
                NRZI <= ~NRZI;
                NRZI_not <= ~NRZI_not;
            end
            else if (readyAnswerDesc && (counterUnitNrzi != 5)) begin
                NRZI <= NRZI;
                NRZI_not <= NRZI_not;
            end
            else if (counterUnitNrzi == 5) begin
                NRZI <= 0;
                NRZI_not <= 1;
            end
        end
        else if ((checkData && OE_ACK && callEopAck) || (checkData && OE_DESC && callEopDesc)) begin
            if (eopCount == 2) begin
                eopCount <= eopCount;
                NRZI <= 1;
                NRZI_not <= 0;
            end
            else if ((eopCount == 0) || (eopCount == 1)) begin
                eopCount <= eopCount + 1;
                NRZI <= 0;
                NRZI_not <= 0;
            end
            else 
                eopCount <= eopCount + 1;
        end
        else if ((checkData && !OE_ACK) || (checkData && !OE_DESC)) begin
            NRZI <= 0; 
            NRZI_not <= 1;
            eopCount <= 0;
        end  

    end

endmodule