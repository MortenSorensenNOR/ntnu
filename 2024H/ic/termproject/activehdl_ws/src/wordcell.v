module wordCell(
    input rw,              // Read/Write signal
    input wordLine,              // Wordline signal
    input [7:0] word,            // 8-bit word input
    input [7:0] bitLinesIn,      // 8-bit input bitlines
    output [7:0] bitLinesOut     // 8-bit output bitlines
);

	// Internal wiring for connecting each bitCell
    genvar i;
    
    // Generate 8 instances of bitCell, one for each bit of the word
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_bitcell
            bitCell bitCell_inst(
                .rw(rw),                            // Read/Write control shared across all cells
                .wordLine(wordLine),                // Wordline shared across all cells
                .i(word[i]),                        // Input word bit
                .bitCarry(bitLinesIn[i]),           // Corresponding bit from bitLinesIn
                .bitOut(bitLinesOut[i])             // Corresponding bit to bitLinesOut
            );
        end
    endgenerate
	
	
endmodule						






module wordCellTestbench();	// testing output on bitline.
	reg wordLine;
	reg [7:0] inWord;   // not nWord
	reg rw;
	reg [7:0] bitLinesIn;
	wire [7:0] bitLinesOut;	
	
	// Instantiate the wordCell module
    wordCell uut(  
	    .rw(rw),                   // Read/Write signal
	    .wordLine(wordLine),       // Wordline signal
	    .word(inWord),             // 8-bit word input
	    .bitLinesIn(bitLinesIn),   // 8-bit input bitlines
	    .bitLinesOut(bitLinesOut)  // 8-bit output bitlines
    );	 		 
	
	initial begin 
        $monitor("Time = %0d, rw = %b, wordLine = %b inputWord = %b, bitLinesOut = %b", $time, rw, wordLine, inWord, bitLinesOut);
		
		// try to write without wordline
		wordLine = 1'b0; inWord = 8'b01010101; rw = 1'b1; bitLinesIn = 8'b00000000; #10;  
		wordLine = 1'b1; inWord = 8'b00000000; rw = 1'b0; bitLinesIn = 8'b00000000; #10; 
		
		// try to write with wordline and read
		wordLine = 1'b1; inWord = 8'b01010101; rw = 1'b1; bitLinesIn = 8'b00000000; #10;  
		wordLine = 1'b0; inWord = 8'b00000000; rw = 1'b1; bitLinesIn = 8'b00000000; #10;
		wordLine = 1'b1; inWord = 8'b00000000; rw = 1'b0; bitLinesIn = 8'b00000000; #10; 
		
		// write a different word and read
		wordLine = 1'b1; inWord = 8'b00111000; rw = 1'b1; bitLinesIn = 8'b00000000; #10;  
		wordLine = 1'b1; inWord = 8'b00000000; rw = 1'b0; bitLinesIn = 8'b00000000; #10;  
		#10
		#10
		
        $finish;
	end
	
endmodule

