`timescale 1ns / 1ps

module romMemoryUsb(input useClk, checkData,
                    input [5:0] Addr,
                    output [7:0] OutRegisters);

    (*rom_style = "block" *) 

    reg [7:0] data;

    //(* dont_touch = "true" *) reg messageForWindowsReg;

    always @(posedge useClk) begin
        if (checkData) begin
            case(Addr)
                //Дескриптор уст-ва
                6'd1: data <= 8'h12; //Размер дескриптора    
                6'd2: data <= 8'h01; //Тип дескриптора
                6'd3: data <= 8'h10;//8'b0001_0000; //Номер версии USB 0110h (100010000)
                6'd4: data <= 8'h01;//8'b0000_0001;
                6'd5: data <= 8'h00;            //Код класса USB
                6'd6: data <= 8'h00;            //Код подкласса USB  
                6'd7: data <= 8'h00;            //Код протокола USB
                6'd8: data <= 8'h08;            //Максимальный размер пакета для нулевой точки
                6'd9: data <= 8'hB4;            //Идентификатор изготовителя для нулевой точки
                6'd10: data <= 8'h04;           
                6'd11: data <= 8'hF0;           //Идентификатор продукта
                6'd12: data <= 8'h00;
                6'd13: data <= 8'h01;           //Номер версии устройства
                6'd14: data <= 8'h01;
                6'd15: data <= 8'h00;           //Индекс дескриптора строки, описывающий изготовителя
                6'd16: data <= 8'h00;           //Индекс дескриптора строки, описывающий продукт
                6'd17: data <= 8'h00;           //Индекс дескриптора строки, содержащий серийный номер уст-ва
                6'd18: data <= 8'h01;           //Количество возможных конфигураций устройства
                //Дескриптор конфигурации
                6'd19: data <= 8'h09;
                6'd20: data <= 8'h02; //Тип дескриптора
                6'd21: data <= 8'd32; //wTotalLength
                6'd22: data <= 8'h00;
                6'd23: data <= 8'h01; //bNumInterfaces
                6'd24: data <= 8'h01; //bConfigurationValue
                6'd25: data <= 8'h00; //iConfiguration
                6'd26: data <= 8'b0100_0000; //bmAttributes
                6'd27: data <= 8'h05; //bMaxPower
                //Дескриптор интерфейса
                6'd28: data <= 8'h09;
                6'd29: data <= 8'h04; //Тип дескриптора
                6'd30: data <= 8'h00; //bInterfaceNumber
                6'd31: data <= 8'h00; //bAlternateSetting
                6'd32: data <= 8'h02; //bNumEndpoints
                6'd33: data <= 8'hFF; //bInterfaceClass
                6'd34: data <= 8'h00; //bInterfaceSubClass
                6'd35: data <= 8'h00; //bInterfaceProtocol
                6'd36: data <= 8'h00; //iInterface
                //Дескриптор конечной точки 
                6'd37: data <= 8'h07;
                6'd38: data <= 8'h05; //Тип дескриптора
                6'd39: data <= 8'h82; //bEndpointAddress
                6'd40: data <= 8'h02; //bmAttributes
                6'd41: data <= 8'h08; //wMaxPacketSize
                6'd42: data <= 8'h00;
                6'd43: data <= 8'h00; //bInterval
                //Дескриптор конечной точки 
                6'd44: data <= 8'h07;
                6'd45: data <= 8'h05; //Тип дескриптора
                6'd46: data <= 8'h06; //bEndpointAddress
                6'd47: data <= 8'h02; //bmAttributes
                6'd48: data <= 8'h08; //wMaxPacketSize
                6'd49: data <= 8'h00;
                6'd50: data <= 8'h00; //bInterval
                // //Дескриптор строки
                // 6'd51: data <= 8'h03;
                // 6'd52: data <= 8'h03; //Тип дескриптора
                // 6'd53: data <= 8'h50; //p                              
            endcase
        end
    end  

    assign OutRegisters = data;

endmodule