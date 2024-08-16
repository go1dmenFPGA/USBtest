`timescale 1ns / 1ps

module NRZIBLOCK(input useClk,
                 input checkData,
                 input readyAnswerAck,
                 input readyAnswerDesc,
                 input readyAnswerSetAddr,
                 input readyAnswerNAK,
                 input readyAnswerData,
                 input OE_ACK,
                 input OE_DESC,
                 input OE_SET_ADDR,
                 input OE_NAK,
                 input OE_DATA,
                 input callEopAck,
                 input callEopDesc,
                 input callEopSetAddr,
                 input callEopNAK,
                 input callEopData,
                 input [2:0] counterUnitDesc,

                 input Staff,
                 
                 output reg NRZI = 0,
                 output reg NRZI_not = 1);

    reg [2:0] eopCount = 0;

    always @(posedge useClk) begin
        if (checkData && OE_ACK && !callEopAck) begin
            if (!readyAnswerAck)
                NRZI <= ~NRZI;
            else 
                NRZI <= NRZI;
            
            if (readyAnswerAck)
                NRZI_not <= NRZI_not;
            else 
                NRZI_not <= ~NRZI_not;
        end   
        else if ((checkData && OE_ACK && callEopAck) || (checkData && OE_DESC && callEopDesc) || (checkData && OE_SET_ADDR && callEopSetAddr) 
            || (checkData && OE_NAK && callEopNAK) || (checkData && OE_DATA && callEopData)) begin
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
        else if ((checkData && !OE_ACK) || (checkData && !OE_DESC) || (checkData && !OE_SET_ADDR) || (checkData && !OE_NAK) || (checkData && !OE_DATA)) begin
            NRZI <= 0; 
            NRZI_not <= 1;
            eopCount <= 0;
        end  

        if (checkData && OE_DESC && !callEopDesc) begin
                if (!readyAnswerDesc) begin
                    NRZI <= ~NRZI;
                    NRZI_not <= ~NRZI_not;
                end
                else begin
                    NRZI <= NRZI;
                    NRZI_not <= NRZI_not;
                end
            end

        if ((checkData && OE_SET_ADDR && !callEopSetAddr)) begin
            if (!readyAnswerSetAddr)
                NRZI <= ~NRZI;
            else 
                NRZI <= NRZI;

            if (readyAnswerSetAddr)
                NRZI_not <= NRZI_not;
            else 
                NRZI_not <= ~NRZI_not;
        end

        if ((checkData && OE_NAK && !callEopNAK)) begin
            if (!readyAnswerNAK)
                NRZI <= ~NRZI;
            else 
                NRZI <= NRZI;

            if (readyAnswerNAK)
                NRZI_not <= NRZI_not;
            else 
                NRZI_not <= ~NRZI_not;
        end

        if ((checkData && OE_DATA && !callEopData)) begin
            if (!Staff) begin
                if (!readyAnswerData)
                    NRZI <= ~NRZI;
                else 
                    NRZI <= NRZI;

                if (readyAnswerData)
                    NRZI_not <= NRZI_not;
                else 
                    NRZI_not <= ~NRZI_not;
            end
            else begin
                NRZI <= ~NRZI;
                NRZI_not <= ~NRZI_not;
            end
        end
    end
    
endmodule