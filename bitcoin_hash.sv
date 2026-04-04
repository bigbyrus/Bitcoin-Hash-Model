/*-------------------*/
/* Top Level Module  */
/* 
/* This module generates 16 256-bit hashes given input data of arbitrary size, */
/* accomplished by executing 16 SHA-256 cores in parallel. Incorporating 16 	 */
/* nonce values to mimic bitcoin mining.													 */
/*-----------------------------------------------------------------------------*/

module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;


/* local signals */
logic        cur_we;
logic        start0, start1, start2, done1[16:0];
logic [7:0]  i, j, n;
logic [15:0] cur_addr;
logic [15:0] offset;
logic [31:0] cur_write_data;
logic [31:0] base_block[16];
logic [31:0] w[15:0][15:0];
logic [31:0] h_ini[7:0];
logic [31:0] h[15:0][7:0], h_phase1[7:0];

/* state variables */
enum logic [3:0] {IDLE, WAIT, READ, WAIT1, PHASE1, SET2, PHASE2, WAIT2, SET3, PHASE3, WAIT3, SET4, WRITE} state;

/* output signals, connected to testbench */
assign mem_clk = clk;
assign mem_addr = cur_addr + offset;
assign mem_we = cur_we;
assign mem_write_data = cur_write_data;
			

/* Phase 1 */			
simplified_sha256 sha256_phase1(
  .clk(clk),
  .reset_n(reset_n),
  .start(start0),
  .message_addr,
  .output_addr,
  .mem_read_data(w[0]),
  .h_in(h_ini),
  .done(done1[0]),
  .mem_write_data(h_phase1)
);					
			
genvar q;

/* Phase 2, 16 parallel SHA-256 operations */
generate
	for(q = 0; q<num_nonces; q++) begin : generate_sha256_blocks
		simplified_sha256 block(
			.clk(clk),
			.reset_n(reset_n),
			.start(start1),
			.message_addr,
			.output_addr,
			.mem_read_data(w[q]), //store second digital block WITH NONCE in w[q]
			.h_in(h_ini),
			.done(done1[q + 1]),
			.mem_write_data(h[q]) //write output hash values into h[q]
			);
	end
endgenerate

			
always_ff @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		cur_we <= 1'b0;
		state <= IDLE;
	end 
  
	else 
   case (state)
	
	/* initial state, sets all variables to initial values */
	IDLE: begin
		if(start) begin
			cur_addr <= message_addr;
			cur_we <= 1'b0;
			start0 <= 0;
			start1 <= 0;
			offset <= 16'b0;
			i <= 0;
			j <= 0;
			n <= 0;
			
			/* initialize the hash constants for phase 1 */
			h_ini[0] <= 32'h6a09e667;
			h_ini[1] <= 32'hbb67ae85;
			h_ini[2] <= 32'h3c6ef372;
			h_ini[3] <= 32'ha54ff53a;
			h_ini[4] <= 32'h510e527f;
			h_ini[5] <= 32'h9b05688c;
			h_ini[6] <= 32'h1f83d9ab;
			h_ini[7] <= 32'h5be0cd19;
			
			state <= WAIT;
		end
	end
	
	WAIT: begin
		state <= READ;
	end
	
	/* obtain input data from memory */
	READ: begin
	
		/* place first 16 words in w[0][x] */
		if(offset < 16) begin
			w[0][offset] <= mem_read_data;
			offset <= offset + 1'b1;
			state <= WAIT;
		end
		
		/* store 2nd 512-bit block in "base_block" */
		else begin
			
			/* base_block[3] is the nonce value */
			if(offset < 19) begin
				base_block[offset-16] <= mem_read_data;
				offset <= offset + 1'b1;
				state <= WAIT;
			end
			
			/* add padding and input data size */
			else begin
				base_block[3] <= 32'h0;
				base_block[4]  <= 32'h80000000;
				base_block[15] <= 32'd640;
				
				for(int n=5; n<15; n++)
					base_block[n] <= 32'h0;
				
				offset <= 0;
				state <= PHASE1;
			end
		end
	end
	
	/* BEGIN PHASE1 */
	// generate 256-bit hash for the first 512-bit block
	PHASE1: begin
		start0 <= 1;
		state <= WAIT1; 
	end
	
	WAIT1: begin
		state <= SET2;
	end
	
	SET2: begin
	  start0 <= 0;
	  
	  /* wait until Phase 1 output hash is produced */
	  if(done1[0] == 1) begin
	  
	  /* store the 2nd 512-bit block 16 times */
		for(j = 0; j<16; j++) begin
			for(i = 0; i<16; i++) begin
				if(i != 3)
					w[j][i] <= base_block[i];
				
				/* each block has its own NONCE value */
				else
					w[j][i] <= j;
			end
		end
		
		// 256-bit hash generated from PHASE1 is used as
		// hash constants (H0-H7) in Phase 2
		for(n = 0; n<8; n++) begin
			h_ini[n] <= h_phase1[n];
		end
		
		i <= 0;
		j <= 0;
		state <= PHASE2;
	 end
	 
	 else
		state <= SET2;
	end
	
	/* BEGIN PHASE2 */
	// generate 16 different hashes for the 16 different
	// NONCE values added to the last block
	PHASE2: begin
		start1 <= 1;
		state <= WAIT2; 
	end
	
	WAIT2: begin
		state <= SET3;
	end
	
	
	SET3: begin
	 start1 <= 0;
	 
	 if(done1[16] == 1) begin	 
		for(j = 0; j<16; j++) begin
			for(i = 0; i<16; i++) begin
			
				/* store the 16 hashes generated in Phase 2 */
				if(i < 8) begin
					w[j][i] <= h[j][i];
				end
				
				/* add padding directly after 256-bit hash */
				else if(i == 8)begin
					w[j][i] <= 32'h80000000;
				end
				
				/* store the block size using the last 32 bits */
				else if(i == 15) begin
					w[j][i] <= 32'd256;
				end
				
				/* pad with zeros */
				else begin
					w[j][i] <= 32'h0;
				end
			end
		end
		
		/* reset the hash constants to the fixed hash constants */
		h_ini[0] <= 32'h6a09e667;
		h_ini[1] <= 32'hbb67ae85;
		h_ini[2] <= 32'h3c6ef372;
		h_ini[3] <= 32'ha54ff53a;
		h_ini[4] <= 32'h510e527f;
		h_ini[5] <= 32'h9b05688c;
		h_ini[6] <= 32'h1f83d9ab;
		h_ini[7] <= 32'h5be0cd19;
		i <= 0;
		j <= 0;
		n <= 0;
		
		state <= PHASE3;
	 end
	 
	 else
		state <= SET3;
	end
	
	/* begin the 16 generated instances of SHA-256 */
	/* this will hash all 16 output hashes from Phase2 */
	PHASE3: begin
		start1 <= 1;
		state <= WAIT3;
	end
	
	WAIT3: begin
		state <= SET4;
	end
	
	/* once all 16 hashes are produced, begin to write to memory */
	SET4: begin
	 start1 <= 0;
	 if(done1[15] == 1) begin
		cur_we <= 1;
		state <= WRITE;
	 end
	 else 
		state <= SET4;
	end
	
	/* write first word to memory */
	WRITE: begin
	cur_addr <= output_addr;
		if(i < 16) begin
			case(i)
				0: cur_write_data <= h[0][0];
				1: cur_write_data <= h[1][0];
				2: cur_write_data <= h[2][0];
				3: cur_write_data <= h[3][0];
				4: cur_write_data <= h[4][0];
				5: cur_write_data <= h[5][0];
		    	6: cur_write_data <= h[6][0];
			   7: cur_write_data <= h[7][0];
				8: cur_write_data <= h[8][0];
				9: cur_write_data <= h[9][0];
				10: cur_write_data <= h[10][0];
				11: cur_write_data <= h[11][0];
				12: cur_write_data <= h[12][0];
				13: cur_write_data <= h[13][0];
				14: cur_write_data <= h[14][0];
				15: cur_write_data <= h[15][0]; 
			endcase 
			i <= i + 1'b1;
			offset <= i;
			state <= WRITE;
		end
		else 
			state <= IDLE;
	end
   endcase
 end
 assign done = (state == IDLE);
endmodule