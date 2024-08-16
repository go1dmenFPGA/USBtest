`timescale 1ns / 1ps

module DataReception   (input useClk,
                        inout serialData,       //Данные, закодированные NRZI
                        inout NotserialData,
                        input OE_TRANSMIT,
                        output reg checkData = 0,
                        output reg [7:0] parallelData = 0,
                        output bitStaff,
                        output reg detectEop = 1);

    reg serialData_reg = 1;
    reg serialData_reg1 = 1;
    reg readyData = 0;
    reg [4:0] counter = 0;

    //----Расшифровка данных, поиск 6 единиц,
    //----последовательные данные распараллеливаю----
    always @(posedge useClk) begin
        serialData_reg <= serialData;
        serialData_reg1 <= serialData_reg;
    end

    always @(posedge useClk) begin
        if (counter == 9) begin
            checkData <= 1;
            counter <= 0;
            readyData <= serialData;
        end
        else begin
            counter <= counter + 1;
            checkData <= 0;
        end
    end

    (* dont_touch = "true" *) reg decoderData = 0;
    reg lastData = 0;
    (* dont_touch = "true" *) reg [3:0] counterUnitDebug = 0;

    reg debugStaff = 0;

    always @(posedge useClk) begin
        lastData <= readyData;
    end
    
    (* dont_touch = "true" *) reg staffReg = 1;

    assign bitStaff = staffReg;

    //(* dont_touch = "true" *) reg staffRegDouble = 1;

    // always @(posedge useClk) begin
    //     if (checkData) begin
    //         staffRegDouble <= staffReg;
    //     end
    // end

    (* dont_touch = "true" *) reg pozor = 0;

    always @(posedge useClk) begin
        if (checkData) begin  
                if (readyData != lastData) begin
                    decoderData <= 0;
                    counterUnitDebug <= 0;
                    if (counterUnitDebug == 7) begin
                        parallelData <= parallelData;
                    end
                    else begin
                        parallelData <= {decoderData, parallelData[7:1]}; 
                    end
                end
                else begin
                    decoderData <= 1;
                    counterUnitDebug <= counterUnitDebug + 1;
                    if (counterUnitDebug == 6) begin
                        decoderData <= 0;
                        parallelData <= {decoderData, parallelData[7:1]};
                    end
                    else if (counterUnitDebug == 7)begin
                        parallelData <= parallelData;
                        counterUnitDebug <= 1;
                    end
                    else begin
                        parallelData <= {decoderData, parallelData[7:1]};
                    end
                end

                if (OE_TRANSMIT) begin
                    if (counterUnitDebug == 6)
                        pozor <= 1;
                    else 
                        pozor <= 0;

                    if (pozor) begin
                        staffReg <= 0;
                        parallelData <= parallelData;
                    end
                    else 
                        staffReg <= 1;
                end
                else begin
                    staffReg <= 1;
                    pozor <= 0;
                end
            end
    end

    //----Поиск EOP----

    always @(posedge useClk) begin
        if (checkData) begin
            if ((serialData == 0) && (NotserialData == 0)) 
                detectEop <= 1;
            else 
                detectEop <= 0;
        end
    end

endmodule