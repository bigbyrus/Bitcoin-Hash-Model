module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

logic        cur_we;
logic        start0, start1, start2, done1[16:0];
logic [15:0] cur_addr;
logic [31:0] cur_write_data;
logic [31:0] message[31:0];
logic [15:0] offset;
logic [31:0] w[15:0][15:0];
logic [31:0] h_ini[7:0];
logic [31:0] h[15:0][7:0], h_phase1[7:0];
logic [7:0] i, j, n;

parameter int k[64] = '{
    32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
    32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
    32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
    32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
    32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
    32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
    32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
    32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

enum logic [3:0] {IDLE, WAIT, READ, WAIT1, PHASE1, SET2, PHASE2, WAIT2, SET3, PHASE3, WAIT3, SET4, WRITE} state;

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

/* Phase 2 */
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
			
			
always_ff @(posedge clk, negedge reset_n)
begin
  if (!reset_n) begin
    cur_we <= 1'b0;
    state <= IDLE;
  end 
  
  else 
   case (state)
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
	
	/* Populate message array with two n-bit blocks (NO NONCE VALUES ADDED) */
	READ: begin
		/* Read first 20 words, store in message array */
		if(offset < 19) begin
				message[offset] <= mem_read_data;
				if(offset + 20 < 32)
					message[offset + 20] <= 32'h0;
				offset <= offset + 1'b1;
				state <= WAIT;
		end
		/* Add padding and size after Message bits */
		else begin
				message[20] <= 32'h80000000;
				message[31] <= 32'd640;
				offset <= 0;
				i <= 0;
				/* w[0][n] holds first 512-bit message block */
				for(int i = 0; i<16; i++) begin 
					w[0][i] <= message[i];
				end
				state <= PHASE1;
		end
	end
	
	
	PHASE1: begin
		start0 <= 1;
		state <= WAIT1; 
	end
	
	WAIT1: begin
		state <= SET2;
	end
	
	SET2: begin

	  start0 <= 0;
	  /* wait until Phase 1 output hash values are produced */
	  if(done1[0] == 1) begin
		for(j = 0; j<16; j++) begin
			for(i = 0; i<16; i++) begin
				if(i != 3)
					w[j][i] <= message[i + 16];
			end
		end
		
		w[0][3] <= 32'd0;
		w[1][3] <= 32'd1;
		w[2][3] <= 32'd2;
		w[3][3] <= 32'd3;
		w[4][3] <= 32'd4;
		w[5][3] <= 32'd5;
		w[6][3] <= 32'd6;
		w[7][3] <= 32'd7;
		w[8][3] <= 32'd8;
		w[9][3] <= 32'd9;
		w[10][3] <= 32'd10;
		w[11][3] <= 32'd11;
		w[12][3] <= 32'd12;
		w[13][3] <= 32'd13;
		w[14][3] <= 32'd14;
		w[15][3] <= 32'd15;
		
		
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
				if(i < 8) begin
					w[j][i] <= h[j][i];
				end
				else if(i == 8)begin
					w[j][i] <= 32'h80000000;
				end
				else if(i == 15) begin
					w[j][i] <= 32'd256;
				end
				else begin
					w[j][i] <= 32'h0;
				end
			end
		end
		
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
	
	
	PHASE3: begin
		start1 <= 1;
		state <= WAIT3;
	end
	
	WAIT3: begin
		state <= SET4;
	end
	
	SET4: begin
	 start1 <= 0;
	 if(done1[1] == 1) begin
		cur_we <= 1;
		state <= WRITE;
	 end
	 else 
		state <= SET4;
	end
	
	
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


