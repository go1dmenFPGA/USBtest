`timescale 1ns / 1ps

module USB(input Clk,
           inout serialData,       //Данные, закодированные NRZI
           inout NotserialData);

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

    wire NRZI;
    wire NRZI_not;

    wire readyAnswerAck;
    wire readyAnswerDesc;

    wire OE_ACK;
    wire OE_DESC;
    wire callEopAck;
    wire callEopDesc;

    wire [15:0] crcResult;    

    wire [2:0] counterUnitDesc;

    DataReception uut (.useClk(clk_120),
                       .serialData(serialData),
                       .NotserialData(NotserialData),
                       .checkData(checkData),
                       .parallelData(parallelData),
                       .detectEop(detectEop));

    AnalizePid uut1 (.useClk(clk_120),
                     .detectEop(detectEop),
                     .checkData(checkData),
                     .parallelData(parallelData),
                     .answerACK(answerACK),
                     .answerDesc(answerDesc),
                     .answerDescConfig(answerDescConfig),
                     .answerDescInterface(answerDescInterface),
                     .answerDescEndPoint(answerDescEndPoint),
                     .readyAnswerAck(readyAnswerAck),
                     .readyAnswerDesc(readyAnswerDesc),
                     .counterUnitDesc(counterUnitDesc),
                     .callEopAck(callEopAck),
                     .callEopDesc(callEopDesc),
                     .OE_ACK(OE_ACK),
                     .OE_DESC(OE_DESC),
                     .crcResult(crcResult)
                     );

    NRZIBLOCK uut2 (.useClk(clk_120),
                    .checkData(checkData),
                    .readyAnswerAck(readyAnswerAck),
                    .readyAnswerDesc(readyAnswerDesc),
                    .counterUnitDesc(counterUnitDesc),
                    .OE_ACK(OE_ACK),
                    .OE_DESC(OE_DESC),
                    .callEopAck(callEopAck),
                    .callEopDesc(callEopDesc),
                    .NRZI(NRZI),
                    .NRZI_not(NRZI_not));

   assign serialData = ((OE_ACK) || (OE_DESC)) ? NRZI : 1'bz;
   assign NotserialData = ((OE_ACK) || (OE_DESC)) ? NRZI_not : 1'bz;

endmodule