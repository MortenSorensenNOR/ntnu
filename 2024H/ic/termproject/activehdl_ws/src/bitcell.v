module bitCell(
	input rw,   // readWrite operation variables
	input wordLine,   // wordLine, indicating that the word this bit is part of should be written to
	input i, 		  // the bit of the input-word that should be written to this cell
	input bitCarry,   // the output from the same bit in the words above this one
	output bitOut,	  // output from this bit to the bitlines
	);		

	wire read;
	wire write;
	and U1 (read, ~rw, wordLine);	//read
	and U2 (write,  rw, wordLine);   //write
	
	// defining some wires
	wire [1:0] s;  // wires between and and crosslinked nands
	
	//UNCOMMENT NEXT LINE WHEN NOT TESTING
	wire [1:0] Q;     // Q and Q inverse
	
	// assigning the wires				   
	and U3 (s[0], write,  i);  
	and U4 (s[1], write, ~i);  
									
																  
	nor U5 (Q[0], s[0], Q[1]);
	nor U6 (Q[1], s[1], Q[0]);
	
	// defining and assigning wires for the bitLine
	wire bit_gated;								 
	and U7 (bit_gated, Q[1], read);
													
	or U8 (bitOut, bitCarry, bit_gated);
	
endmodule 		 