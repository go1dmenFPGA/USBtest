`timescale 1ns / 1ps

module USB(input Clk,
           inout serialData,       //Данные, закодированные NRZI
           inout NotserialData,
           output Debug,
           output OE_DESC);

    //----PLL----
    wire clk_120; //120 mhz

    wire locked;
    clk_wiz_0 instance_name
    (
    // Clock out ports
    .clk_out1(clk_120),   
    // Status and control signals
    .reset(1'b0), // input reset666
    .locked(locked),       // output locked
    // Clock in ports
    .clk_in1(Clk)); 

    wire checkData;
    wire [7:0] parallelData;
    wire detectEop;

    wire answerACK;
    wire answerDesc;
    wire answerDescConfig;
    wire answerDescInterface;
    wire answerDescEndPoint;
    wire answerDescChar;
    wire answerSetAddr;
    wire answerNull;
    wire answerNAK;

    wire lengthDesc;

    wire NRZI;
    wire NRZI_not;

    wire readyAnswerAck;
    wire readyAnswerDesc;
    wire readyAnswerSetAddr;
    wire readyAnswerNAK;
    wire readyAnswerData;

    wire OE_ACK;
    //wire OE_DESC;
    wire OE_SET_ADDR;
    wire OE_SET_CONFIG;
    wire OE_NAK;
    wire OE_DATA;
    wire callEopAck;
    wire callEopDesc;
    wire callEopSetAddr;
    wire callEopNAK;
    wire callEopData;
    wire [4:0] setupPidReset;

    wire [15:0] crcResult;    

    wire DataCypress;
   
    wire bitStaff;

    wire OE_TRANSMIT;

    wire Staff;

    DataReception uut (.useClk(clk_120),
                       .serialData(serialData),
                       .NotserialData(NotserialData),
                       .checkData(checkData),
                       .parallelData(parallelData),
                       .OE_TRANSMIT(OE_TRANSMIT),
                       .detectEop(detectEop),
                       .bitStaff(bitStaff));

    AnalizePid uut1 (.useClk(clk_120),
                     .detectEop(detectEop),
                     .checkData(checkData),
                     .parallelData(parallelData),
                     .answerACK(answerACK),
                     .answerDesc(answerDesc),
                     .answerDescConfig(answerDescConfig),
                     .answerDescInterface(answerDescInterface),
                     .answerDescEndPoint(answerDescEndPoint),
                     .answerDescChar(answerDescChar),
                     .answerSetAddr(answerSetAddr),
                     .answerDescSetConfig(answerDescSetConfig),
                     .answerNull(answerNull),
                     .answerNAK(answerNAK),
                     .readyAnswerAck(readyAnswerAck),
                     .readyAnswerDesc(readyAnswerDesc),
                     .readyAnswerSetAddr(readyAnswerSetAddr),
                     .readyAnswerNAK(readyAnswerNAK),
                     .readyAnswerData(readyAnswerData),
                     .lengthDesc(lengthDesc),
                     .callEopAck(callEopAck),
                     .callEopDesc(callEopDesc),
                     .callEopSetAddr(callEopSetAddr),
                     .callEopNAK(callEopNAK),
                     .callEopData(callEopData),
                     .OE_ACK(OE_ACK),
                     .OE_DESC(OE_DESC),
                     .OE_SET_ADDR(OE_SET_ADDR),
                     .OE_NAK(OE_NAK),
                     .OE_DATA(OE_DATA),
                     .setupPidReset(setupPidReset),
                     .Debug(Debug),
                     .bitStaff(bitStaff),
                     .OE_TRANSMIT(OE_TRANSMIT),
                     .Staff(Staff)
                     );

    NRZIBLOCK uut2 (.useClk(clk_120),
                    .checkData(checkData),
                    .readyAnswerAck(readyAnswerAck),
                    .readyAnswerDesc(readyAnswerDesc),
                    .readyAnswerSetAddr(readyAnswerSetAddr),
                    .readyAnswerNAK(readyAnswerNAK),
                    .readyAnswerData(readyAnswerData),
                    .counterUnitDesc(counterUnitDesc),
                    .OE_ACK(OE_ACK),
                    .OE_DESC(OE_DESC),
                    .OE_SET_ADDR(OE_SET_ADDR),
                    .OE_NAK(OE_NAK),
                    .OE_DATA(OE_DATA),
                    .callEopAck(callEopAck),
                    .callEopDesc(callEopDesc),
                    .callEopSetAddr(callEopSetAddr),
                    .callEopNAK(callEopNAK),
                    .callEopData(callEopData),
                    .NRZI(NRZI),
                    .NRZI_not(NRZI_not),
                    .Staff(Staff));

   assign serialData = ((OE_ACK) || (OE_DESC) || (OE_SET_ADDR) || (OE_NAK) || (OE_DATA)) ? NRZI : 1'bz;
   assign NotserialData = ((OE_ACK) || (OE_DESC) || (OE_SET_ADDR) || (OE_NAK) || (OE_DATA)) ? NRZI_not : 1'bz;

endmodule