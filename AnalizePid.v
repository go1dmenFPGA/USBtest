`timescale 1ns / 1ps

module AnalizePid(input useClk,
                  input detectEop,
                  input checkData,
                  input [7:0] parallelData,

                  output reg answerACK = 0,
                  output OE_ACK,                  
                  output readyAnswerAck,
                  output callEopAck,
                  output reg [4:0] prevPid,

                  output reg answerDesc = 0,
                  output reg [7:0] lengthDesc = 0,
                  output reg [7:0] bmRequestType = 0,

                  output readyAnswerDesc,
                  output OE_DESC,
                  output [15:0] crcResult,
                  output callEopDesc,

                  output reg answerDescConfig = 0,
                  output reg answerDescInterface = 0,
                  output reg answerDescEndPoint
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
                       .lengthDesc(lengthDesc),
                       .readyAnswerDesc(readyAnswerDesc),
                       .OE_DESC(OE_DESC),
                       .crcResult(crcResult),
                       .callEopDesc(callEopDesc),
                       .prevPid(prevPid));

    reg detectEopReg = 0;
    reg detectPid = 0;
    reg [3:0] countPid = 0;
    reg [4:0] setupPid;

    //----Поиск и анализ PID----
    always @(posedge useClk) begin
        if (checkData && (!OE_ACK && !OE_DESC)) begin
            if (detectEop) begin
                detectEopReg <= 1;
            end
            else if (detectEopReg && (parallelData == 8'b0000_0001)) begin
                detectPid <= 1;
                detectEopReg <= 0;
                //setupPid <= 0;
            end
            else if (detectPid) begin
                if (countPid == 8) begin
                    detectPid <= 0;
                    countPid <= 0;
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
                end
                else 
                    countPid <= countPid + 1;
            end
        end
    end

    //----Запоминаю предыдущий PID

    reg [4:0] copyPid;

    always @(posedge useClk) begin
        if (checkData && setupPid == 3) begin
            prevPid <= 3;
        end
    end

    //----Анализ данных после PIDа----

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

    reg [7:0] bRequest = 0;
    reg [7:0] wValue = 0;

    //Анализ данных

    always @(posedge useClk) begin
        if (checkData && (setupPid == 4)) begin
            if (counterData == 7) //bmRequestType
                bmRequestType <= parallelData;
            else if (counterData == 15) //bRequest
                bRequest <= parallelData;
            else if (counterData == 23) //wValue
                wValue <= parallelData;
            else if (counterData == 55) //lengthDesc
                lengthDesc <= parallelData;
        end
    end

    //После EOP необходимо проанализировать данные

    reg [1:0] counterEop = 0;

    always @(posedge useClk) begin
        if (checkData) begin
            if (detectEopReg) begin
                if (counterEop == 2)
                    counterEop <= counterEop;
                else 
                    counterEop <= counterEop + 1;
            end
            else 
                counterEop <= 0;
        end
    end

    //Отправка ACK

    always @(posedge useClk) begin
        if (checkData) begin
            if ((counterEop == 1) && (setupPid == 4) && ((bmRequestType == 0) || (bmRequestType == 8'h80))) 
                answerACK <= 1; 
            else
                answerACK <= 0;
        end
    end

    //Отправка Desc

    always @(posedge useClk) begin
        if (checkData) begin
            if ((counterEop == 1) && (setupPid == 2) && (lengthDesc != 0) && (bmRequestType == 8'h80) &&
                (bRequest == 8'h06) && (wValue == 8'h01))
                answerDesc <= 1;
            else if ((counterEop == 1) && (setupPid == 2) && (lengthDesc != 0) && (bmRequestType == 8'h80) && 
                (bRequest == 8'h06) && (wValue == 8'h02))
                answerDescConfig <= 1;
            else if ((counterEop == 1) && (setupPid == 2) && (lengthDesc != 0) && (bmRequestType == 8'h80) && 
                (bRequest == 8'h06) && (wValue == 8'h04))
                answerDescInterface <= 1;
            else if ((counterEop == 1) && (setupPid == 2) && (lengthDesc != 0) && (bmRequestType == 8'h80) && 
                (bRequest == 8'h06) && (wValue == 8'h05))
                answerDescEndPoint <= 1;
            else begin
                answerDesc <= 0;
                answerDescConfig <= 0;
                answerDescInterface <= 0;
                answerDescEndPoint <= 0;
            end
        end
    end

endmodule
