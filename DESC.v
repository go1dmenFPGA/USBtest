`timescale 1ns / 1ps

module DESC (input useClk,
             input answerDesc,
             input answerDescConfig,
             input answerDescInterface,
             input answerDescEndPoint,
             input checkData,
             input [7:0] lengthDesc,
             input [4:0] prevPid,
             output reg readyAnswerDesc,
             output reg OE_DESC = 0,
             output reg [15:0] crcResult,
             output reg callEopDesc,
             output reg [2:0] counterUnitDesc);

    reg [5:0] Addr = 1;
    wire [7:0] OutRegisters;
    reg [7:0] dataRegisters;

    reg [2:0] State;

    reg [7:0] SyncPid;

    reg changePid = 1;

    reg callCrcReg;
    reg callCrc;

    localparam SYNC = 0, PID = 1, ROM = 2, CRC = 3, EMPTY = 4;

    romMemoryUsb myMemory (.useClk(useClk),
                           .Addr(Addr),
                           .checkData(checkData),
                           .lengthDesc(lengthDesc),
                           .OutRegisters(OutRegisters));

    reg [3:0] counterMain;
    reg [3:0] countAddr;
    reg [15:0] Delitel;
    reg [15:0] Register;

    wire xorValue = Register[15] ^ readyAnswerDesc;
    reg [3:0] counterCrc;
    reg [2:0] counterReset;

    always @(posedge useClk) begin
        if (checkData && (answerDesc || answerDescConfig || answerDescInterface || answerDescEndPoint)) begin
            readyAnswerDesc <= 0;
            OE_DESC <= 1;
            State <= SYNC;
            SyncPid <= 8'b0000_0100;
            callEopDesc <= 0;
            counterMain <= 0;
            changePid <= ~changePid;
            countAddr <= 0;
            Delitel <= 16'b1000_0000_0000_0101; //x^16 + x^15 + x^2 + 1
            Register <= 16'hFFFF;
            callCrcReg <= 0;
            callCrc <= 0;
            counterCrc <= 0;
            counterReset <= 0;
            counterUnitDesc <= 0;
            if (answerDesc) begin
                if ((prevPid == 3) && (Addr != 19))
                    Addr <= Addr;
                else 
                    Addr <= 1;  
            end
            else if (answerDescConfig) begin
                if ((prevPid == 3) && (19 < Addr) && (Addr < 28))
                    Addr <= Addr;
                else 
                    Addr <= 19;
            end
            else if (answerDescInterface) begin
                if ((prevPid == 3) && (28 < Addr) && (Addr < 37))
                    Addr <= Addr;
                else 
                    Addr <= 28;
            end
            else if (answerDescEndPoint) begin
                if ((prevPid == 3) && (37 < Addr) && (Addr < 44))
                    Addr <= Addr;
                else 
                    Addr <= 37;
            end
        end  
        else if (OE_DESC && checkData) begin    
            case(State)  
                SYNC:   begin
                            if (counterMain == 5) begin
                                counterMain <= 0;
                                State <= PID;
                            end
                            else 
                                counterMain <= counterMain + 1;                    
                end 
                PID:    begin
                            if (counterMain == 6) begin
                                State <= ROM;
                                counterMain <= 0;
                            end
                            else 
                                counterMain <= counterMain + 1;
                end   
                ROM:    begin
                            if (counterUnitDesc == 5)
                                Addr <= Addr;
                            else if (counterMain == 7) begin
                                counterMain <= 0;
                                if ((countAddr == 7) || (Addr == 19) || (Addr == 28) || (Addr == 37) || (Addr == 44)) begin
                                    Addr <= Addr;
                                    counterMain <= counterMain;
                                    callCrcReg <= 1;
                                end
                                else 
                                    countAddr <= countAddr + 1;
                            end
                            else if (counterMain == 6) begin
                                Addr <= Addr + 1;
                                counterMain <= counterMain + 1;
                            end
                            else 
                                counterMain <= counterMain + 1;

                            if (callCrcReg) 
                                callCrc <= 1;
                            else 
                                callCrc <= 0;
                            
                            if (callCrc)
                                State <= CRC;
                            else 
                                State <= State;
                end
                CRC:    begin   
                            if (counterCrc == 15) begin
                                State <= EMPTY;
                                counterCrc <= 0;
                                callEopDesc <= 1;
                            end
                            else 
                                counterCrc <= counterCrc + 1;
                end
                EMPTY:  begin
                            if (counterReset == 3)
                                OE_DESC <= 0;
                            else 
                                counterReset <= counterReset + 1;
                end
            endcase

            case(State)
                SYNC:   begin
                            SyncPid <= {SyncPid[6:0], 1'b0};
                            readyAnswerDesc <= SyncPid[7];
                            dataRegisters <= OutRegisters;
                            if (counterMain == 5) begin
                                if (!changePid)
                                    SyncPid <= 8'b1100_0011;
                                else 
                                    SyncPid <= 8'b1101_0010;
                            end
                end
                PID:    begin
                            SyncPid <= {1'b0, SyncPid[7:1]};
                            readyAnswerDesc <= SyncPid[0];
                end
                ROM:    begin
                            if (counterMain == 0) begin
                                dataRegisters <= OutRegisters;
                            end
                            else if (counterUnitDesc == 5) begin
                                dataRegisters <= dataRegisters;
                                readyAnswerDesc <= dataRegisters[0];
                            end
                            else begin
                                dataRegisters <= {1'b0, dataRegisters[7:1]};
                                readyAnswerDesc <= dataRegisters[0];
                            end

        /*crc part*/        Register[0] <= xorValue ^ Delitel[0];
                            Register[1] <= xorValue ^ Register[0];
                            Register[14:2] <= Register[13:1];
                            Register[15] <= xorValue ^ Register[14];  
                end
                CRC:    begin   
                            readyAnswerDesc <= Register[0];
                            Register <= {1'b0, Register[15:1]};
                end
            endcase
        end
    end

    //Считаю 6 единиц
    always @(posedge useClk) begin
        if (checkData && OE_DESC) begin
            if (readyAnswerDesc) begin
                if (counterUnitDesc == 5) begin
                    counterUnitDesc <= 0;
                end
                else 
                    counterUnitDesc <= counterUnitDesc + 1;
            end
            else 
                counterUnitDesc <= 0;
        end
    end

endmodule





