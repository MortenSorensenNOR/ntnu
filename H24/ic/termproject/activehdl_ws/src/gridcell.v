module gridCell(
    input  rw,                    // Read/Write signal
    input  [7:0] wordLine,        // Wordline signal	from adress decoder
    input  [7:0] i,               // 8-bit word input			 
    output [7:0] bitLinesOut      // 8-bit output bitlines
);						  
	
    
    
    // Intermediate connections for bitLinesOut of each word cell
    wire [7:0] bitLines [0:8];      // Define 7 intermediate wires, plus one for the final output

    assign bitLines[0] = 8'b0;      // Set the initial bitLinesIn to 8'b0 for the first word cell
    assign bitLinesOut = bitLines[8]; // Final output from the last word cell
	
	genvar idx;
    generate
        for (idx = 0; idx < 8; idx = idx + 1) begin : gen_wordcell
            wordCell wc (
                .rw(rw),
                .wordLine(wordLine[idx]),            // Enable signal for each word
                .word(i),                            // Input word (connected when wordLine is active)
                .bitLinesIn(bitLines[idx]),          // Connect bitLinesOut of previous word
                .bitLinesOut(bitLines[idx + 1])      // Output to next word's bitLinesIn
            );
        end
    endgenerate
	
	
endmodule				







module gridCellTestbench();

    // Inputs
    reg rw;
    reg [7:0] wordLine;
    reg [7:0] i;

    // Output
    wire [7:0] bitLinesOut;

    // Instantiate the Unit Under Test (UUT)
    gridCell uut (
        .rw(rw),
        .wordLine(wordLine),
        .i(i),
        .bitLinesOut(bitLinesOut)
    );

    // Procedure to simulate writing to a specific word
    task write_word(input [2:0] word_idx, input [7:0] data);
        begin
            rw = 1;                         // Enable write mode
            wordLine = 8'b1 << word_idx;    // Select the word by setting the corresponding bit high
            i = data;                       // Set input data
            #10;                            // Wait 10 time units for the write operation
        end
    endtask

    // Procedure to simulate reading from a specific word
    task read_word(input [2:0] word_idx);
        begin
            rw = 0;                         // Enable read mode
            wordLine = 8'b1 << word_idx;    // Select the word to read from
            #10;                            // Wait 10 time units for the read operation
        end
    endtask

    initial begin 	
		integer idx;
		
		
        // Initialize signals
        rw = 0;
        wordLine = 8'b0;
        i = 8'b0;
		
		
        $display(" ");
        // Write and Read to/from different words
        $display("Writing to 0,1,3 and 7");
			 
        write_word(3'd0, 8'd42);   // Write to word 0  
        write_word(3'd1, 8'd255);  // Write to word 0       
        write_word(3'd3, 8'd69);   // Write to word 3	        
        write_word(3'd7, 8'd127);  // Write to word 7	
		
		
		
        
        $display(" ");	
		$display("RAM contents:");			  
	    for (idx = 0; idx < 8; idx = idx + 1) begin
	        read_word(idx);                      // Read from word `idx`
	        #5;                                  // Wait a few time units to ensure the read completes
	        $display("		Word %0d: bitLinesOut = %d", idx, bitLinesOut);  // Display output
	    end		   
        $display(" ");

        // End simulation
        $stop;
    end

endmodule
