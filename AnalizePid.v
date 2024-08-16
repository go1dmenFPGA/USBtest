`timescale 1ns / 1ps

module AnalizePid(input useClk,
                  input detectEop,
                  input checkData,
                  input [7:0] parallelData,

                  output reg answerACK = 0,
                  output OE_ACK,                  
                  output readyAnswerAck,
                  output callEopAck,
                  output [4:0] prevPid,

                  output reg answerDesc = 0,
                  output [7:0] lengthDesc,
                  output [7:0] bmRequestType,
                  output readyAnswerDesc,   

                  output OE_DESC,
                  output [15:0] crcResult,
                  output callEopDesc,

                  output reg answerDescConfig,
                  output reg answerDescInterface,
                  output reg answerDescEndPoint,
                  output reg answerDescChar,
                  output reg answerDescSetConfig,

                  output [2:0] Driver,      

                  output reg answerNull,
                  output [7:0] bRequestSetConfig,           

                  output reg answerSetAddr,
                  output OE_SET_ADDR,
                  output readyAnswerSetAddr,
                  output callEopSetAddr,

                  output reg answerNAK,
                  output OE_NAK,
                  output readyAnswerNAK,
                  output callEopNAK,

                  output [3:0] AddrData,
                  output [7:0] inputData,
                  output [7:0] outputdata,

                  output reg readyAnswerData,
                  output reg OE_DATA = 0,
                  output reg callEopData,

                  output [4:0] setupPidReset,
                  output [2:0] counterUnitData,
                  output Debug,

                  output OE_TRANSMIT,
                  input bitStaff,

                  output Staff
                 );

    ACK firstAnswer (.useClk(useClk),
                     .checkData(checkData),
                     .answerACK(answerACK),
                     .OE_ACK(OE_ACK),
                     .readyAnswerAck(readyAnswerAck),
                     .callEopAck(callEopAck));

    DESC secondAnswer (.useClk(useClk),
                       .checkData(checkData),
                       .answerDesc(answerDesc),
                       .answerDescConfig(answerDescConfig),
                       .answerDescInterface(answerDescInterface),
                       .answerDescEndPoint(answerDescEndPoint),
                       .answerDescChar(answerDescChar),
                       .answerNull(answerNull),
                       .readyAnswerDesc(readyAnswerDesc),
                       .Driver(Driver),
                       .lengthDesc(lengthDesc),
                       .OE_DESC(OE_DESC),
                       .callEopDesc(callEopDesc),
                       .setupPidReset(setupPidReset),
                       .Debug(Debug));

    AnswerSetAddr thirdAnswer (.useClk(useClk),
                               .checkData(checkData),
                               .answerSetAddr(answerSetAddr),
                               .OE_SET_ADDR(OE_SET_ADDR),
                               .readyAnswerSetAddr(readyAnswerSetAddr),
                               .callEopSetAddr(callEopSetAddr));

    NAK fiveAnswer  (.useClk(useClk),
                     .checkData(checkData),
                     .answerNAK(answerNAK),
                     .OE_NAK(OE_NAK),
                     .readyAnswerNAK(readyAnswerNAK),
                     .callEopNAK(callEopNAK));

    DataReception sixAnswer (.OE_TRANSMIT(OE_TRANSMIT));

    reg detectEopReg = 0;
    reg detectPid = 0;
    (* dont_touch = "true" *) reg [3:0] countPid = 0;
    (* dont_touch = "true" *) reg [4:0] setupPid;
    (* dont_touch = "true" *) reg [7:0] bmRequestType = 0;
    (* dont_touch = "true" *) reg [7:0] lengthDescReg = 0;
    (* dont_touch = "true" *) reg [7:0] lengthDescRegSecond = 0;   
    (* dont_touch = "true" *) reg [7:0] dataByte = 0;
    (* dont_touch = "true" *) reg [4:0] prevPid;

    assign lengthDesc = lengthDescReg;
    assign setupPidReset = setupPid;

    //----Поиск и анализ PID----
    always @(posedge useClk) begin
        if (checkData && (!OE_ACK && !OE_DESC && !OE_SET_ADDR && !OE_DATA && !OE_NAK)) begin
            if (detectPid) begin
                if (countPid == 8) begin
                    detectPid <= 0;
                    countPid <= 0;
                    prevPid <= setupPid;
                    if (parallelData == 8'b1110_0001) //OUT:передача данных от хоста к конечной точке
                        setupPid <= 1;
                    else if (parallelData == 8'b0110_1001) //IN:передача данных от конечной точки к хосту
                        setupPid <= 2;
                    else if (parallelData == 8'b0010_1101) //SETUP:передача от хоста к конечной точке по каналу управления
                        setupPid <= 3;
                    else if (parallelData == 8'b1100_0011) //DATA0:пакет данных с четным PID
                        setupPid <= 4;
                    else if (parallelData == 8'b0100_1011) //DATA1:пакет данных с нечетным PID
                        setupPid <= 5;
                    else if (parallelData == 8'b1101_0010) //ACK
                        setupPid <= 6;
                    else if (parallelData == 8'b0101_1010) //NAK
                        setupPid <= 7;
                    else if (parallelData == 8'b0001_1110) //STALL
                        setupPid <= 8;
                    else if (parallelData == 8'b1010_0101) //SOF
                        setupPid <= 9;
                end
                else 
                    countPid <= countPid + 1;
            end
            else if (detectEop) begin
                detectEopReg <= 1;
                //setupPid <= 0;
            end
            else if (detectEopReg && (parallelData == 8'b0000_0001)) begin
                detectPid <= 1;
                detectEopReg <= 0;
            end
        end
    end

    reg [6:0] counterData = 0;

    always @(posedge useClk) begin
        if (checkData) begin
            if (!detectPid && !detectEopReg) begin
                counterData <= counterData + 1;
            end
            else 
                counterData <= 0;
        end
    end

    (* dont_touch = "true" *)  reg [7:0] bRequest = 0;
    (* dont_touch = "true" *)  reg [7:0] wValue = 0;
    (* dont_touch = "true" *)  reg [7:0] wValueSecond = 0;
    (* dont_touch = "true" *)  reg [7:0] wIndex = 0;
    (* dont_touch = "true" *)  reg [7:0] wIndexSecond = 0;

    assign bRequestSetConfig = bRequest;

    //Анализ данных    
    (* dont_touch = "true" *) reg [2:0] counterUnitTransmiter;               

    always @ (posedge useClk)
        if (checkData && (setupPid == 4) || (setupPid == 5) || (setupPid == 1)) begin
            if (counterData[2:0] == 3'b111) 
                dataByte <= parallelData;
        end

    always @(posedge useClk) begin
        if (checkData && (prevPid == 3) && ((setupPid == 4) || (setupPid == 5) || (setupPid == 1))) begin
            if (counterData == 7)        //bmRequestType
                bmRequestType <= parallelData;
            else if (counterData == 15) //bRequest
                bRequest <= parallelData;
            else if (counterData == 23) //wValueSecond
                wValueSecond <= parallelData;    
            else if (counterData == 31) //wValue
                wValue <= parallelData;
            else if (counterData == 39) //wIndexSecond
                wIndexSecond <= parallelData;
            else if (counterData == 47) //wIndex
                wIndex <= parallelData;
            else if (counterData == 55) begin//lengthDesc
                // if (parallelData == )
                //     lengthDescReg <= 8'd32;
                // else 
                    lengthDescReg <= parallelData;
            end
            else if (counterData == 63) //lengthDescRegSecond
                lengthDescRegSecond <= parallelData;
        end
    end

    (* dont_touch = "true" *) reg [8:0] countToken = 0;

    always @(posedge useClk) begin
        if (checkData && (counterData == 7) && ((setupPid == 1) || (setupPid == 2) || (setupPid == 5)))
            countToken <= countToken + 1;
    end

    //Записываю адрес

    (* dont_touch = "true" *) reg [7:0] writeAddr;

    always @(posedge useClk) begin
        if (checkData && (bRequest == 8'h05) && (counterEop == 1)) begin
            writeAddr <= wValueSecond;
        end
    end

    //После EOP необходимо проанализировать данные

    reg [1:0] counterEop = 0;   

    always @(posedge useClk) begin
        if (checkData) begin
            if (detectEopReg) begin
                if (counterEop == 2) begin
                    counterEop <= counterEop;
                end
                else 
                    counterEop <= counterEop + 1;
            end
            else 
                counterEop <= 0;
        end
    end

    //регистры, детектирующий пришедшие данные

    reg datain = 0;

    always @(posedge useClk) begin
        if (checkData) begin
            if (answerData)
                datain <= 1;
        end
    end

    //Отправка ACK

    always @(posedge useClk) begin
        if (checkData) begin
            if ((counterEop == 1) && ((setupPid == 4) || (setupPid == 5)) && ((bmRequestType == 8'h80) || (bmRequestType == 0))) 
                answerACK <= 1; 
            else
                answerACK <= 0;
        end
    end

    //Отправка Desc

    always @(posedge useClk) begin
        if (checkData) begin
            if (!datain) begin
                if ((counterEop == 1) && (setupPid == 2) && (bmRequestType == 8'h80) &&
                    (bRequest == 8'h06) && (wValue == 8'h01))
                    answerDesc <= 1;
                else if ((counterEop == 1) && (setupPid == 2) && (bmRequestType == 8'h80) && 
                    (bRequest == 8'h06) && (wValue == 8'h02))
                    answerDescConfig <= 1;
                // else if ((counterEop == 1) && (setupPid == 2) && (bmRequestType == 8'h80) && 
                //     (bRequest == 8'h06) && (wValue == 8'h04))
                //     answerDescInterface <= 1;
                // else if ((counterEop == 1) && (setupPid == 2) && (bmRequestType == 8'h80) && 
                //     (bRequest == 8'h06) && (wValue == 8'h05)) 
                //     answerDescEndPoint <= 1;
                else if ((counterEop == 1) && (setupPid == 2) && (bmRequestType == 8'h80) && 
                    (bRequest == 8'h06) && (wValue == 8'h03) && (wIndex != 8'h04) && (wIndexSecond != 8'h09))
                    answerDescChar <= 1;
                else if ((counterEop == 1) && (setupPid == 2) && (bmRequestType == 8'h00) &&
                    (bRequest == 8'h09))
                    answerNull <= 1;
                else begin
                    answerDesc <= 0;
                    answerDescConfig <= 0;
                    answerDescInterface <= 0;
                    answerDescEndPoint <= 0;
                    answerDescChar <= 0;
                    answerDescSetConfig <= 0;
                    answerNull <= 0;
                end
            end
        end
    end

    //Конфигарция для драйвера

    reg [2:0] driverReg;
    
    always @(posedge useClk) begin
        if (checkData) begin
            if (lengthDescReg == 8'd9)
                driverReg <= 1;
            else if (lengthDescReg == 8'd32)
                driverReg <= 2;
            else begin
                driverReg <= 0;
            end
        end
     end

    //Отправка DATA1

    always @(posedge useClk) begin
        if (checkData) begin
            if ((counterEop == 1) && (setupPid == 2) && (bRequest == 8'h05))
                answerSetAddr <= 1;
            else 
                answerSetAddr <= 0;
        end
    end

    assign Driver = driverReg;

    //Попытка №2

    (* dont_touch = "true" *) reg debugEndPoint = 0;
    (* dont_touch = "true" *) reg [6:0] waitCounter = 0;
    (* dont_touch = "true" *) reg [6:0] rememberCounter = 0;

    (* dont_touch = "true" *) reg [3:0] addrReg = 0;    
    (* dont_touch = "true" *) reg [7:0] inputReg = 0;   

    assign AddrData = addrReg;
    assign inputData = inputReg;

    (* dont_touch = "true" *) reg oe = 0;

    assign OE_TRANSMIT = oe;

    (* dont_touch = "true" *) reg [2:0] counterUnit;
    assign counterUnitData = counterUnit;

    (* dont_touch = "true" *) reg transmitReg = 0;

    ReadWrite memoryData (.useClk(useClk),
                          .checkData(checkData),
                          .AddrData(AddrData),
                          .inputData(inputData),
                          .oe(oe),
                          .outputdata(outputdata));     

    (* dont_touch = "true" *) reg [3:0] counterEndpoint = 0;

    (* dont_touch = "true" *) reg bitStaffTransmit = 0;

    assign Staff = bitStaffTransmit;
 
    always @(posedge useClk) begin
        if (checkData) begin
            if (setupPid == 1) begin
                if (counterEndpoint == 12)
                    counterEndpoint <= counterEndpoint;
                else 
                    counterEndpoint <= counterEndpoint + 1;
            end
            else 
                counterEndpoint <= 0;
        end
    end

    always @(posedge useClk) begin
        if (checkData) begin
            if (!bitStaffTransmit) begin
                if ((counterEndpoint == 10) && (parallelData[7:4] == 4'b0110)) begin
                    debugEndPoint <= 1;
                    waitCounter <= 0;
                    transmitReg <= 1;
                end
                else if (!bitStaff) 
                    rememberCounter <= rememberCounter;
                else if (debugEndPoint && ((setupPid == 4) || (setupPid == 5))) begin
                    oe <= 1;
                    if (waitCounter == 7) begin
                        waitCounter <= waitCounter;
                        if (rememberCounter == 7) begin
                            addrReg <= addrReg + 1;
                            rememberCounter <= 0;
                            if (addrReg == 7) begin
                                addrReg <= 0;
                                debugEndPoint <= 0;
                                oe <= 0;
                            end
                        end
                        else begin
                            rememberCounter <= rememberCounter + 1;
                            if (rememberCounter == 0)
                                inputReg <= parallelData;
                        end
                    end
                    else 
                        waitCounter <= waitCounter + 1;
                end
                else if (OE_DATA && (counterMain == 5) && (State == ROM)) begin
                    if (addrReg == 7)
                        addrReg <= addrReg;
                    else 
                        addrReg <= addrReg + 1;
                end
                else if (State == CRC) begin
                    addrReg <= 0;
                    transmitReg <= 0;
                end
            end
        end
    end

    (* dont_touch = "true" *) reg answerData;

    (* dont_touch = "true" *) reg [3:0] counterNak = 0;
    (* dont_touch = "true" *) reg detectNak = 0;

    //(* dont_touch = "true" *) reg arrivedReg = 0;

    always @(posedge useClk) begin
        if (checkData) begin
            if (transmitReg && (setupPid == 2) && (counterEop == 1)) begin
                answerData <= 1;
            end
            else 
                answerData <= 0;
        end
    end

    //NAK

    always @(posedge useClk) begin
        if (checkData) begin
            if (setupPid == 2) begin
                if (counterNak == 9) begin
                    counterNak <= 0;
                    if (parallelData[7:4] == 4'b0100)
                        detectNak <= 1;
                end
                else 
                    counterNak <= counterNak + 1;
            end
            else begin
                detectNak <= 0;
                counterNak <= 0;
            end
        end
    end

    always @(posedge useClk) begin
        if (checkData) begin
            if ((counterEop == 1) && detectNak)
                answerNAK <= 1;
            else 
                answerNAK <= 0;
        end
    end

    /////////////////////////

    wire [7:0] outputdata;
    (* dont_touch = "true" *) reg [7:0] dataRegistersData;

    (* dont_touch = "true" *) reg [2:0] State;

    reg [7:0] SyncPid;

    reg changePid = 1;

    reg callCrcReg;
    reg callCrc;

    reg [15:0] RegisterCrc;

    localparam SYNC = 0, PID = 1, ROM = 2, CRC = 3, EMPTY = 4;

    (* dont_touch = "true" *) reg [3:0] counterMain;
    reg [3:0] countAddr;
    reg [15:0] Delitel;
    (* dont_touch = "true" *) reg [15:0] Register;

    wire xorValue = Register[0] ^ dataRegistersData[0];
    reg [3:0] counterCrc;
    reg [2:0] counterReset;

    reg crutchReg = 1;

    (* dont_touch = "true" *) reg [3:0] counterCrcWait;

    (* dont_touch = "true" *) reg finalReg;

    (* dont_touch = "true" *) reg [3:0] dataReg;

    (* dont_touch = "true" *) reg abc;

    (* dont_touch = "true" *) reg [2:0] countAbc;

    always @(posedge useClk) begin
        if (checkData) begin
            if (readyAnswerData) begin
                if (counterUnit == 5) begin
                    bitStaffTransmit <= 1;
                    counterUnit <= counterUnit + 1;
                end
                else if (bitStaffTransmit) begin
                    bitStaffTransmit <= 0;
                    counterUnit <= 0;
                end
                else begin
                    bitStaffTransmit <= 0;
                    counterUnit <= counterUnit + 1;
                end
            end
            else begin
                counterUnit <= 0;
                bitStaffTransmit <= 0;
            end
        end
    end

    always @(posedge useClk) begin
        if (checkData && answerData) begin
            readyAnswerData <= 0;
            OE_DATA <= 1;
            State <= SYNC;
            SyncPid <= 8'b0000_0100;
            callEopData <= 0;
            counterMain <= 0;
            changePid <= ~changePid;
            countAddr <= 0;
            Delitel <= 16'b1100_0000_0000_0101; //x^16 + x^15 + x^2 + 1
            Register <= 16'hFFFF;
            callCrcReg <= 0;
            callCrc <= 0;
            counterCrc <= 0;
            counterReset <= 0;
            //counterUnit <= 0;
            counterCrcWait <= 0;
            finalReg <= 0;
            dataReg <= 0;
            abc <= 0;
            countAbc <= 0;
            //bitStaffTransmit <= 0;
        end 
        else if (OE_DATA && checkData) begin
            if (!bitStaffTransmit) begin
                if (abc) begin
                    if (countAbc == 7) begin
                        countAbc <= 0;
                        dataReg <= dataReg + 1;
                    end
                    else 
                        countAbc <= countAbc + 1;
                end
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
                                abc <= 1;
                                if (counterMain == 7) begin
                                    State <= ROM;
                                    counterMain <= 0;
                                    dataRegistersData <= outputdata;
                                end
                                else 
                                    counterMain <= counterMain + 1;
                    end
                    ROM:    begin
                                if (counterMain == 7) begin
                                    counterMain <= 0;
                                end
                                else 
                                    counterMain <= counterMain + 1;

                                if ((dataReg == 8) && (countAbc == 6))
                                    callCrc <= 1;
                                else 
                                    callCrc <= 0;

                                if (callCrc) begin
                                    State <= CRC;
                                    RegisterCrc <= ~Register;
                                end
                                else 
                                    State <= State;
                    end
                    CRC:    begin
                                if (counterCrc == 15) begin
                                    State <= EMPTY;
                                    counterCrc <= 0;
                                    callEopData <= 1;
                                end
                                else begin
                                    counterCrc <= counterCrc + 1;
                                end
                    end
                    EMPTY:  begin
                                if (counterReset == 3)
                                    OE_DATA <= 0;
                                else 
                                    counterReset <= counterReset + 1;
                    end
                endcase

                case(State) 
                    SYNC:   begin
                                SyncPid <= {SyncPid[6:0], 1'b0};
                                readyAnswerData <= SyncPid[7];
                                dataRegistersData <= outputdata;
                                if (counterMain == 5) begin
                                    if (!changePid)
                                        SyncPid <= 8'b1100_0011;
                                    else 
                                        SyncPid <= 8'b0100_1011;
                                end
                    end
                    PID:    begin
                                SyncPid <= {1'b0, SyncPid[7:1]};
                                readyAnswerData <= SyncPid[0];
                    end
                    ROM:    begin
                                if (counterMain == 7) begin
                                    dataRegistersData <= outputdata;
                                    readyAnswerData <= dataRegistersData[0];
                                end
                                else if (callCrc)
                                    readyAnswerData <= crcDebug[0];
                                else begin
                                    dataRegistersData <= {1'b0, dataRegistersData[7:1]};
                                    readyAnswerData <= dataRegistersData[0];
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
                    CRC:    begin
                                RegisterCrc <= {1'b0, RegisterCrc[15:1]};
                                readyAnswerData <= RegisterCrc[1];
                    end
                endcase
            end
        end
    end

    wire [15:0] crcDebug = ~Register[15:0];

endmodule