`timescale 1ns / 1ps

module romMemoryUsb(input useClk, checkData,
                    input [7:0] lengthDesc,
                    input [5:0] Addr,
                    output [7:0] OutRegisters);

    (*rom_style = "block" *) 

    reg [7:0] data;

    localparam N = 3; //Параметр для дескриптора строки

    always @(posedge useClk) begin
        if (checkData) begin
            case(Addr)
                //Дескриптор уст-ва
                6'd1: data <= lengthDesc; //Размер дескриптора    
                6'd2: data <= 8'b0000_0001; //Тип дескриптора
                6'd3: data <= 8'b0001_0000; //Номер версии USB 0110h (100010000)
                6'd4: data <= 8'b0000_0001;
                6'd5: data <= 0;            //Код класса USB
                6'd6: data <= 0;            //Код подкласса USB  
                6'd7: data <= 0;            //Код протокола USB
                6'd8: data <= 8'b1011_0111; //Максимальный размер пакета для нулевой точки
                6'd9: data <= 0;            //Идентификатор изготовителя для нулевой точки
                6'd10: data <= 0;           
                6'd11: data <= 0;           //Идентификатор продукта
                6'd12: data <= 0;
                6'd13: data <= 0;           //Номер версии устройства
                6'd14: data <= 0;
                6'd15: data <= 0;           //Индекс дескриптора строки, описывающий изготовителя
                6'd16: data <= 8'b10101010;           //Индекс дескриптора строки, описывающий продукт
                6'd17: data <= 8'b0;           //Индекс дескриптора строки, содержащий серийный номер уст-ва
                6'd18: data <= 8'b1000_0010;           //Количество возможных конфигураций устройства
                //Дескриптор конфигурации
                6'd19: data <= lengthDesc;
                6'd20: data <= 8'b0000_0010; //Тип дескриптора
                6'd21: data <= 8'b0010_1000; //wTotalLength
                6'd22: data <= 8'b0000_0000;
                6'd23: data <= 8'b0000_0011; //bNumInterfaces
                6'd24: data <= 8'b0000_0001; //bConfigurationValue
                6'd25: data <= 8'b0000_0000; //iConfiguration
                6'd26: data <= 8'b1010_0000; //bmAttributes
                6'd27: data <= 8'b0010_0000; //bMaxPower
                //Дескриптор интерфейса
                6'd28: data <= lengthDesc;
                6'd29: data <= 8'b0000_0100; //Тип дескриптора
                6'd30: data <= 8'b1111_1111; //bInterfaceNumber
                6'd31: data <= 8'b1111_1111; //bAlternateSetting
                6'd32: data <= 8'b0000_0001; //bNumEndpoints
                6'd33: data <= 8'b0000_0011; //bInterfaceClass
                6'd34: data <= 8'b0000_0001; //bInterfaceSubClass
                6'd35: data <= 8'b0000_0010; //bInterfaceProtocol
                6'd36: data <= 8'b1001_0011; //iInterface
                //Дескриптор конечной точки 
                6'd37: data <= lengthDesc;
                6'd38: data <= 8'b0000_0101; //Тип дескриптора
                6'd39: data <= 8'b0101_0001; //bEndpointAddress
                6'd40: data <= 8'b0000_0011; //bmAttributes
                6'd41: data <= 8'b0001_1000; //wMaxPacketSize
                6'd42: data <= 8'b1010_1100;
                6'd43: data <= 8'b0000_0001; //bInterval
                //Дескриптор строки
                6'd44: data <= lengthDesc;
                6'd45: data <= 8'b0000_0011; //Тип дескриптора
                6'd46: data <= N;
            endcase
        end
    end 

    assign OutRegisters = data;

endmodule
