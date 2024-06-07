`timescale 1ns / 1ps

module DataReception   (input useClk,
                        inout serialData,       //Данные, закодированные NRZI
                        inout NotserialData,
                        output reg checkData = 0,
                        output reg [7:0] parallelData = 0,
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

    reg decoderData = 0;
    reg lastData = 0;
    reg [3:0] counterUnit = 0;

    always @(posedge useClk) begin
        lastData <= readyData;
    end

    always @(posedge useClk) begin
        if (checkData) begin   
            if (readyData != lastData) begin
                decoderData <= 0;
                counterUnit <= 0;
                if (counterUnit == 7) 
                    parallelData <= parallelData;
                else 
                    parallelData <= {decoderData, parallelData[7:1]}; 
            end
            else begin
                decoderData <= 1;
                counterUnit <= counterUnit + 1;
                if (counterUnit == 6) begin
                    decoderData <= 0;
                    parallelData <= {decoderData, parallelData[7:1]};
                end
                else if (counterUnit == 7) begin
                    parallelData <= parallelData;
                    counterUnit <= 0;
                end
                else 
                    parallelData <= {decoderData, parallelData[7:1]};
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