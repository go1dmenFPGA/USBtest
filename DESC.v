`timescale 1ns / 1ps

module DESC (input useClk,
             input answerDesc,
             input answerDescConfig,
             input answerDescInterface,
             input answerDescEndPoint,
             input answerDescChar,
             input answerNull,
             input [7:0] bRequestSetConfig,
             input [2:0] Driver,
             input checkData,
             input [4:0] setupPidReset,
             input [7:0] lengthDesc,
             output reg readyAnswerDesc,
             output reg OE_DESC = 0,
             output reg callEopDesc,
             output reg [2:0] counterUnitDesc,
             output Debug 
             );

    (* dont_touch = "true" *) reg [5:0] Addr = 1;
    wire [7:0] OutRegisters;
    (* dont_touch = "true" *) reg [7:0] dataRegisters;

    reg [2:0] State;

    reg [7:0] SyncPid;

    reg changePid = 1;

    reg callCrcReg;
    reg callCrc;

    reg [15:0] RegisterCrc;

    assign Debug = (Addr == 17) ? 1'b1 : 1'b0;

    localparam SYNC = 0, PID = 1, ROM = 2, CRC = 3, EMPTY = 4;

    romMemoryUsb myMemory (.useClk(useClk),
                           .Addr(Addr),
                           .checkData(checkData),
                           .OutRegisters(OutRegisters));

    reg [3:0] counterMain;
    reg [3:0] countAddr;
    reg [15:0] Delitel;
    reg [15:0] Register;

    wire xorValue = Register[0] ^ dataRegisters[0];
    reg [3:0] counterCrc;
    reg [2:0] counterReset;

    reg crutchReg = 1;

    always @(posedge useClk) begin
        if (checkData && (answerDesc || answerDescConfig || answerDescInterface || answerDescEndPoint || answerDescChar || answerNull)) begin
            readyAnswerDesc <= 0;
            OE_DESC <= 1;
            State <= SYNC;
            SyncPid <= 8'b0000_0100;
            callEopDesc <= 0;
            counterMain <= 0;
            changePid <= ~changePid;
            countAddr <= 0;
            Delitel <= 16'b1100_0000_0000_0101; //x^16 + x^15 + x^2 + 1
            Register <= 16'hFFFF;
            callCrcReg <= 0;
            callCrc <= 0;
            counterCrc <= 0;
            counterReset <= 0;
            counterUnitDesc <= 0;
            if (answerDesc) begin
                if ((0 < Addr) && (Addr < 19))
                    Addr <= Addr;
                else 
                    Addr <= 1;  
            end
            else if (answerDescConfig) begin
                if (Driver == 1) begin
                    if ((19 < Addr) && (Addr < 52))
                        Addr <= Addr;   
                    else 
                        Addr <= 19;
                end
                else if (Driver == 1) begin
                    if ((19 < Addr) && (Addr < 28))
                        Addr <= Addr;
                    else 
                        Addr <= 19;
                end
                else if (Driver == 2) begin
                    if (crutchReg) begin
                        Addr <= 19;
                        crutchReg <= 0;
                    end
                    else begin
                        if ((19 < Addr) && (Addr < 52))
                            Addr <= Addr;   
                        else 
                            Addr <= 19;
                    end
                end
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
                            if ((Addr != 51) && (bRequestSetConfig != 8'h09)) begin
                                if (counterMain == 7) begin
                                    State <= ROM;
                                    counterMain <= 1;
                                end
                                else 
                                    counterMain <= counterMain + 1;
                            end
                            else begin
                                if (counterMain == 8) begin
                                    State <= CRC;
                                    crutchReg <= 1;
                                end
                                else 
                                    counterMain <= counterMain + 1;
                            end
                end   
                ROM:    begin
                            if (counterUnitDesc == 5) begin
                                counterMain <= counterMain;
                                callCrcReg <= 0;
                            end
                            else begin
                                if (counterMain == 7) begin
                                    counterMain <= 0;
                                    if ((Driver == 0) || (Driver == 2)) begin
                                        if ((countAddr == 7) || (Addr == 19) || (Addr == 51) || (Addr == 52)) begin 
                                            Addr <= Addr;
                                            counterMain <= counterMain;
                                            callCrcReg <= 1;
                                        end
                                        else 
                                            countAddr <= countAddr + 1;
                                    end
                                    else if (Driver == 1) begin
                                        if ((countAddr == 7) || (Addr == 19) || (Addr == 28)) begin
                                            Addr <= Addr;
                                            counterMain <= counterMain;
                                            callCrcReg <= 1;
                                        end
                                        else 
                                            countAddr <= countAddr + 1;
                                    end
                                end
                                else if (counterMain == 6) begin
                                    Addr <= Addr + 1;
                                    counterMain <= counterMain + 1;
                                end
                                else 
                                    counterMain <= counterMain + 1;

                                if (callCrcReg) begin
                                    callCrc <= 1;
                                end
                                else 
                                    callCrc <= 0;
                                
                                if (callCrc) begin
                                    State <= CRC;
                                    RegisterCrc <= ~Register;
                                end
                                else 
                                    State <= State;
                            end
                end
                CRC:    begin   
                            if (counterUnitDesc == 5) begin
                                counterCrc <= counterCrc;                  
                            end
                            else begin
                                if (counterCrc == 15) begin
                                    State <= EMPTY;
                                    counterCrc <= 0;
                                    callEopDesc <= 1;
                                end
                                else 
                                    counterCrc <= counterCrc + 1;
                            end
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
                                    SyncPid <= 8'b0100_1011;
                                else 
                                    SyncPid <= 8'b1100_0011;
                            end
                end
                PID:    begin
                            SyncPid <= {1'b0, SyncPid[7:1]};
                            readyAnswerDesc <= SyncPid[0];
                end
                ROM:    begin
                            if (readyAnswerDesc) begin
                                if (counterUnitDesc == 5) begin
                                    counterUnitDesc <= 7;
                                    readyAnswerDesc <= 0;
                                    dataRegisters <= dataRegisters;
                                end
                                else begin
                                    counterUnitDesc <= counterUnitDesc + 1;
                                    if (counterMain == 0) begin
                                    dataRegisters <= OutRegisters;
                                    readyAnswerDesc <= dataRegisters[0];
                                    end
                                    else if (callCrc) begin
                                        readyAnswerDesc <= crcDebug[0];
                                    end   
                                    else begin
                                        dataRegisters <= {1'b0, dataRegisters[7:1]};
                                        readyAnswerDesc <= dataRegisters[0];
                                    end

                                    Register[15] <= xorValue;
                                    Register[14] <= Register[15];
                                    Register[13] <= Register[14] ^ xorValue;
                                    Register[12] <= Register[13];
                                    Register[11] <= Register[12];
                                    Register[10] <= Register[11];
                                    Register[9] <= Register[10];
                                    Register[8] <= Register[9];
                                    Register[7] <= Register[8];
                                    Register[6] <= Register[7];
                                    Register[5] <= Register[6];
                                    Register[4] <= Register[5];
                                    Register[3] <= Register[4];
                                    Register[2] <= Register[3];
                                    Register[1] <= Register[2];
                                    Register[0] <= Register[1] ^ xorValue;
                                end
                            end
                            else begin
                                counterUnitDesc <= 0;
                                if (counterMain == 0) begin
                                    dataRegisters <= OutRegisters;
                                    readyAnswerDesc <= dataRegisters[0];
                                end
                                else if (callCrc) begin
                                    readyAnswerDesc <= crcDebug[0];
                                end   
                                else begin
                                    dataRegisters <= {1'b0, dataRegisters[7:1]};
                                    readyAnswerDesc <= dataRegisters[0];
                                end

                                Register[15] <= xorValue;
                                Register[14] <= Register[15];
                                Register[13] <= Register[14] ^ xorValue;
                                Register[12] <= Register[13];
                                Register[11] <= Register[12];
                                Register[10] <= Register[11];
                                Register[9] <= Register[10];
                                Register[8] <= Register[9];
                                Register[7] <= Register[8];
                                Register[6] <= Register[7];
                                Register[5] <= Register[6];
                                Register[4] <= Register[5];
                                Register[3] <= Register[4];
                                Register[2] <= Register[3];
                                Register[1] <= Register[2];
                                Register[0] <= Register[1] ^ xorValue;       
                            end   
                end
                CRC:    begin   
                            if (readyAnswerDesc) begin
                                if (counterUnitDesc == 5) begin
                                    counterUnitDesc <= 7;
                                    readyAnswerDesc <= 0;
                                    RegisterCrc <= RegisterCrc;
                                end
                                else begin
                                    counterUnitDesc <= counterUnitDesc + 1;
                                    RegisterCrc <= {1'b0, RegisterCrc[15:1]};
                                    readyAnswerDesc <= RegisterCrc[1];
                                end
                            end
                            else begin
                                RegisterCrc <= {1'b0, RegisterCrc[15:1]};
                                readyAnswerDesc <= RegisterCrc[1];
                                counterUnitDesc <= 0;
                            end
                end
            endcase
        end
        else if (checkData && (setupPidReset == 3)) begin
            changePid <= 1;
            if (lengthDesc == 8'd64)
                Addr <= 1;
            else 
                Addr <= Addr;
        end
    end

    wire [15:0] crcDebug = ~Register[15:0];

endmodule














