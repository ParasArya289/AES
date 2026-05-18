module aes_xkey (
	key_in,
	key_out
);
	localparam aes_const_Nk = 8;
	input wire [255:0] key_in;
	output wire [255:0] key_out;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 7; _gv_i_1 >= 0; _gv_i_1 = _gv_i_1 - 1) begin : genblk1
			localparam i = _gv_i_1;
			assign key_out[(31 - (4 * ((aes_const_Nk - i) - 1))) * 8+:8] = key_in[(32 * (i + 1)) - 1:(32 * i) + 24];
			assign key_out[(31 - ((4 * ((aes_const_Nk - i) - 1)) + 1)) * 8+:8] = key_in[(32 * (i + 1)) - 9:(32 * i) + 16];
			assign key_out[(31 - ((4 * ((aes_const_Nk - i) - 1)) + 2)) * 8+:8] = key_in[(32 * (i + 1)) - 17:(32 * i) + 8];
			assign key_out[(31 - ((4 * ((aes_const_Nk - i) - 1)) + 3)) * 8+:8] = key_in[(32 * (i + 1)) - 25:32 * i];
		end
	endgenerate
endmodule
module aes_xdata (
	data_in,
	data_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] data_in;
	output wire [127:0] data_out;
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 3; _gv_i_2 >= 0; _gv_i_2 = _gv_i_2 - 1) begin : genblk1
			localparam i = _gv_i_2;
			assign data_out[(15 - (4 * ((aes_const_Nb - i) - 1))) * 8+:8] = data_in[(32 * (i + 1)) - 1:(32 * i) + 24];
			assign data_out[(15 - ((4 * ((aes_const_Nb - i) - 1)) + 1)) * 8+:8] = data_in[(32 * (i + 1)) - 9:(32 * i) + 16];
			assign data_out[(15 - ((4 * ((aes_const_Nb - i) - 1)) + 2)) * 8+:8] = data_in[(32 * (i + 1)) - 17:(32 * i) + 8];
			assign data_out[(15 - ((4 * ((aes_const_Nb - i) - 1)) + 3)) * 8+:8] = data_in[(32 * (i + 1)) - 25:32 * i];
		end
	endgenerate
endmodule
module aes_cdata (
	data_in,
	data_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] data_in;
	output wire [127:0] data_out;
	genvar _gv_i_3;
	generate
		for (_gv_i_3 = 3; _gv_i_3 >= 0; _gv_i_3 = _gv_i_3 - 1) begin : genblk1
			localparam i = _gv_i_3;
			assign data_out[(32 * (i + 1)) - 1:(32 * i) + 24] = data_in[(15 - (4 * ((aes_const_Nb - i) - 1))) * 8+:8];
			assign data_out[(32 * (i + 1)) - 9:(32 * i) + 16] = data_in[(15 - ((4 * ((aes_const_Nb - i) - 1)) + 1)) * 8+:8];
			assign data_out[(32 * (i + 1)) - 17:(32 * i) + 8] = data_in[(15 - ((4 * ((aes_const_Nb - i) - 1)) + 2)) * 8+:8];
			assign data_out[(32 * (i + 1)) - 25:32 * i] = data_in[(15 - ((4 * ((aes_const_Nb - i) - 1)) + 3)) * 8+:8];
		end
	endgenerate
endmodule
module aes_array (
	SBox,
	IBox,
	RCon
);
	output wire [2047:0] SBox;
	output wire [2047:0] IBox;
	output wire [127:0] RCon;
	localparam [2047:0] sbox = 2048'h637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b27509832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cfd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdbe0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9ee1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16;
	localparam [2047:0] ibox = 2048'h52096ad53036a538bf40a39e81f3d7fb7ce339829b2fff87348e4344c4dee9cb547b9432a6c2233dee4c950b42fac34e082ea16628d924b2765ba2496d8bd12572f8f66486689816d4a45ccc5d65b6926c704850fdedb9da5e154657a78d9d8490d8ab008cbcd30af7e45805b8b34506d02c1e8fca3f0f02c1afbd0301138a6b3a9111414f67dcea97f2cfcef0b4e67396ac7422e7ad3585e2f937e81c75df6e47f11a711d29c5896fb7620eaa18be1bfc563e4bc6d279209adbc0fe78cd5af41fdda8338807c731b11210592780ec5f60517fa919b54a0d2de57a9f93c99cefa0e03b4dae2af5b0c8ebbb3c83539961172b047eba77d626e169146355210c7d;
	localparam [127:0] rcon = 128'h0001020408102040801b366cd8ab4d9a;
	assign SBox = sbox;
	assign IBox = ibox;
	assign RCon = rcon;
endmodule
module aes_gf4_mul (
	a,
	b,
	p
);
	input wire [3:0] a;
	input wire [3:0] b;
	output wire [3:0] p;
	wire [1:0] ah = a[3:2];
	wire [1:0] al = a[1:0];
	wire [1:0] bh = b[3:2];
	wire [1:0] bl = b[1:0];
	wire [1:0] a_sum = ah ^ al;
	wire [1:0] b_sum = bh ^ bl;
	wire Ah = ah[1] ^ ah[0];
	wire Al = al[1] ^ al[0];
	wire aa = a_sum[1] ^ a_sum[0];
	wire Bh = bh[1] ^ bh[0];
	wire Bl = bl[1] ^ bl[0];
	wire bb = b_sum[1] ^ b_sum[0];
	wire abcd_h = ~(Ah & Bh);
	wire [1:0] ph = {~(ah[1] & bh[1]) ^ abcd_h, ~(ah[0] & bh[0]) ^ abcd_h};
	wire abcd_l = ~(Al & Bl);
	wire [1:0] pl = {~(al[1] & bl[1]) ^ abcd_l, ~(al[0] & bl[0]) ^ abcd_l};
	wire t_m = ~(a_sum[0] & b_sum[0]);
	wire [1:0] pm = {~(aa & bb) ^ t_m, ~(a_sum[1] & b_sum[1]) ^ t_m};
	assign p = {ph ^ pm, pl ^ pm};
endmodule
module aes_gf4_inv (
	a,
	a_inv
);
	input wire [3:0] a;
	output wire [3:0] a_inv;
	wire [1:0] ah = a[3:2];
	wire [1:0] al = a[1:0];
	wire sa = ah[1] ^ ah[0];
	wire sb = al[1] ^ al[0];
	wire c1 = ~(ah[1] | al[1]) ^ ~(sa & sb);
	wire c0 = ~(sa | sb) ^ ~(ah[0] & al[0]);
	wire [1:0] d = {c0, c1};
	wire sd = d[1] ^ d[0];
	wire abcd_p = ~(sd & sb);
	wire [1:0] p_out = {~(d[1] & al[1]) ^ abcd_p, ~(d[0] & al[0]) ^ abcd_p};
	wire abcd_q = ~(sd & sa);
	wire [1:0] q_out = {~(d[1] & ah[1]) ^ abcd_q, ~(d[0] & ah[0]) ^ abcd_q};
	assign a_inv = {p_out, q_out};
endmodule
module aes_gf4_sq_scl (
	a,
	p
);
	input wire [3:0] a;
	output wire [3:0] p;
	assign p[3] = a[2] ^ a[0];
	assign p[2] = a[3] ^ a[1];
	assign p[1] = a[0] ^ a[1];
	assign p[0] = a[0];
endmodule
module aes_gf8_inv (
	a,
	a_inv
);
	input wire [7:0] a;
	output wire [7:0] a_inv;
	wire [3:0] ah = a[7:4];
	wire [3:0] al = a[3:0];
	wire [3:0] sq_scl_out;
	aes_gf4_sq_scl sq_scl_inst(
		.a(ah ^ al),
		.p(sq_scl_out)
	);
	wire [3:0] mul_out;
	aes_gf4_mul mul0(
		.a(ah),
		.b(al),
		.p(mul_out)
	);
	wire [3:0] norm = mul_out ^ sq_scl_out;
	wire [3:0] norm_inv;
	aes_gf4_inv inv0(
		.a(norm),
		.a_inv(norm_inv)
	);
	wire [3:0] p_out;
	wire [3:0] q_out;
	aes_gf4_mul mul1(
		.a(norm_inv),
		.b(al),
		.p(p_out)
	);
	aes_gf4_mul mul2(
		.a(norm_inv),
		.b(ah),
		.p(q_out)
	);
	assign a_inv = {p_out, q_out};
endmodule
module aes_cfa_sbox (
	a_in,
	s_out
);
	input wire [7:0] a_in;
	output wire [7:0] s_out;
	wire R1 = a_in[7] ^ a_in[5];
	wire R2 = ~(a_in[7] ^ a_in[4]);
	wire R3 = a_in[6] ^ a_in[0];
	wire R4 = ~(a_in[5] ^ R3);
	wire R5 = a_in[4] ^ R4;
	wire R6 = a_in[3] ^ a_in[0];
	wire R7 = a_in[2] ^ R1;
	wire R8 = a_in[1] ^ R3;
	wire R9 = a_in[3] ^ R8;
	wire [7:0] B;
	assign B[7] = ~(R7 ^ R8);
	assign B[6] = R5;
	assign B[5] = a_in[1] ^ R4;
	assign B[4] = ~(R1 ^ R3);
	assign B[3] = (a_in[1] ^ R2) ^ R6;
	assign B[2] = ~a_in[0];
	assign B[1] = R4;
	assign B[0] = ~(a_in[2] ^ R9);
	wire [7:0] Z = ~B;
	wire [7:0] C;
	aes_gf8_inv inv(
		.a(Z),
		.a_inv(C)
	);
	wire T1 = C[7] ^ C[3];
	wire T2 = C[6] ^ C[4];
	wire T3 = C[6] ^ C[0];
	wire T4 = ~(C[5] ^ C[3]);
	wire T5 = ~(C[5] ^ T1);
	wire T6 = ~(C[5] ^ C[1]);
	wire T7 = ~(C[4] ^ T6);
	wire T8 = C[2] ^ T4;
	wire T9 = C[1] ^ T2;
	wire [7:0] D;
	assign D[7] = T4;
	assign D[6] = T1;
	assign D[5] = T3;
	assign D[4] = T5;
	assign D[3] = T2 ^ T5;
	assign D[2] = T3 ^ T8;
	assign D[1] = T7;
	assign D[0] = T9;
	assign s_out = ~D;
endmodule
module aes_cfa_isbox (
	s_in,
	a_out
);
	input wire [7:0] s_in;
	output wire [7:0] a_out;
	wire R1 = s_in[7] ^ s_in[5];
	wire R2 = ~(s_in[7] ^ s_in[4]);
	wire R3 = s_in[6] ^ s_in[0];
	wire R4 = ~(s_in[5] ^ R3);
	wire R5 = s_in[4] ^ R4;
	wire R6 = s_in[3] ^ s_in[0];
	wire R7 = s_in[2] ^ R1;
	wire R8 = s_in[1] ^ R3;
	wire R9 = s_in[3] ^ R8;
	wire [7:0] Y;
	assign Y[7] = R2;
	assign Y[6] = s_in[4] ^ R8;
	assign Y[5] = s_in[6] ^ s_in[4];
	assign Y[4] = R9;
	assign Y[3] = ~(s_in[6] ^ R2);
	assign Y[2] = R7;
	assign Y[1] = s_in[4] ^ R6;
	assign Y[0] = s_in[1] ^ R5;
	wire [7:0] Z = ~Y;
	wire [7:0] C;
	aes_gf8_inv inv(
		.a(Z),
		.a_inv(C)
	);
	wire T1 = C[7] ^ C[3];
	wire T2 = C[6] ^ C[4];
	wire T3 = C[6] ^ C[0];
	wire T4 = ~(C[5] ^ C[3]);
	wire T5 = ~(C[5] ^ T1);
	wire T6 = ~(C[5] ^ C[1]);
	wire T7 = ~(C[4] ^ T6);
	wire T8 = C[2] ^ T4;
	wire T9 = C[1] ^ T2;
	wire T10 = T3 ^ T5;
	wire [7:0] X;
	assign X[7] = ~(C[4] ^ C[1]);
	assign X[6] = C[1] ^ T10;
	assign X[5] = C[2] ^ T10;
	assign X[4] = ~(C[6] ^ C[1]);
	assign X[3] = T8 ^ T9;
	assign X[2] = ~(C[7] ^ T7);
	assign X[1] = T6;
	assign X[0] = ~C[2];
	assign a_out = ~X;
endmodule
module aes_kexp (
	rst,
	clk,
	Key,
	RCon,
	SBox,
	Enable,
	KExp,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nk = 8;
	input wire [255:0] Key;
	input wire [127:0] RCon;
	input wire [2047:0] SBox;
	input wire [0:0] Enable;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 14;
	output reg [1919:0] KExp;
	output reg [0:0] Ready_out;
	localparam Nx = 8;
	reg [1919:0] KExp_R;
	reg [2047:0] KExp_P;
	reg [2047:0] KExp_N;
	reg [0:0] Ready_P [0:7];
	reg [0:0] Ready_N [0:7];
	function [31:0] RotWord;
		input [31:0] Word;
		RotWord = {Word[23:0], Word[31:24]};
	endfunction
	function [31:0] SubWord;
		input [31:0] Word;
		SubWord = {SBox[(255 - Word[31:24]) * 8+:8], SBox[(255 - Word[23:16]) * 8+:8], SBox[(255 - Word[15:8]) * 8+:8], SBox[(255 - Word[7:0]) * 8+:8]};
	endfunction
	function [31:0] Min;
		input [31:0] A;
		input [31:0] B;
		if (A > B)
			Min = B;
		else
			Min = A;
	endfunction
	function automatic [255:0] sv2v_cast_B6EF8;
		input reg [255:0] inp;
		sv2v_cast_B6EF8 = inp;
	endfunction
	initial begin
		KExp_P = {Nx {sv2v_cast_B6EF8({aes_const_Nk {32'b00000000000000000000000000000000}})}};
		KExp_N = {Nx {sv2v_cast_B6EF8({aes_const_Nk {32'b00000000000000000000000000000000}})}};
	end
	genvar _gv_i_4;
	genvar _gv_j_1;
	generate
		for (_gv_i_4 = 0; _gv_i_4 < aes_const_Nk; _gv_i_4 = _gv_i_4 + 1) begin : genblk1
			localparam i = _gv_i_4;
			always @(*) begin
				if (_sv2v_0)
					;
				if (Enable == 1)
					KExp_P[(56 + (7 - i)) * 32+:32] = {Key[(31 - (4 * i)) * 8+:8], Key[(31 - ((4 * i) + 1)) * 8+:8], Key[(31 - ((4 * i) + 2)) * 8+:8], Key[(31 - ((4 * i) + 3)) * 8+:8]};
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		KExp_R[1664+:256] = KExp_P[1792+:256];
		Ready_P[0] = Enable;
	end
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(posedge clk)
		if (rst == 0) begin
			KExp_N[1792+:256] <= {aes_const_Nk {sv2v_cast_32({32 {1'b0}})}};
			Ready_N[0] <= 1'sb0;
		end
		else if (Enable || Ready_N[0]) begin
			KExp_N[1792+:256] <= KExp_P[1792+:256];
			Ready_N[0] <= Ready_P[0];
		end
	generate
		for (_gv_i_4 = 1; _gv_i_4 < Nx; _gv_i_4 = _gv_i_4 + 1) begin : genblk2
			localparam i = _gv_i_4;
			for (_gv_j_1 = 0; _gv_j_1 < aes_const_Nk; _gv_j_1 = _gv_j_1 + 1) begin : genblk1
				localparam j = _gv_j_1;
				if ((j % aes_const_Nk) == 0) begin : genblk1
					wire [32:1] sv2v_tmp_E922F;
					assign sv2v_tmp_E922F = (KExp_N[(((8 - i) * 8) + (7 - j)) * 32+:32] ^ SubWord(RotWord(KExp_P[((8 - i) * 8) * 32+:32]))) ^ {RCon[(15 - i) * 8+:8], 24'h000000};
					always @(*) KExp_P[(((7 - i) * 8) + (7 - j)) * 32+:32] = sv2v_tmp_E922F;
				end
				else if ((j % aes_const_Nk) == 4) begin : genblk1
					wire [32:1] sv2v_tmp_485FA;
					assign sv2v_tmp_485FA = KExp_N[(((8 - i) * 8) + (7 - j)) * 32+:32] ^ SubWord(KExp_P[(((7 - i) * 8) + (8 - j)) * 32+:32]);
					always @(*) KExp_P[(((7 - i) * 8) + (7 - j)) * 32+:32] = sv2v_tmp_485FA;
				end
				else begin : genblk1
					wire [32:1] sv2v_tmp_431E9;
					assign sv2v_tmp_431E9 = KExp_N[(((8 - i) * 8) + (7 - j)) * 32+:32] ^ KExp_P[(((7 - i) * 8) + (8 - j)) * 32+:32];
					always @(*) KExp_P[(((7 - i) * 8) + (7 - j)) * 32+:32] = sv2v_tmp_431E9;
				end
			end
			always @(*) begin
				if (_sv2v_0)
					;
				KExp_R[32 * (59 - ((aes_const_Nk * i) >= (Min(aes_const_Nk * (i + 1), 60) - 1) ? aes_const_Nk * i : ((aes_const_Nk * i) + ((aes_const_Nk * i) >= (Min(aes_const_Nk * (i + 1), 60) - 1) ? ((aes_const_Nk * i) - (Min(aes_const_Nk * (i + 1), 60) - 1)) + 1 : ((Min(aes_const_Nk * (i + 1), 60) - 1) - (aes_const_Nk * i)) + 1)) - 1))+:32 * ((aes_const_Nk * i) >= (Min(aes_const_Nk * (i + 1), 60) - 1) ? ((aes_const_Nk * i) - (Min(aes_const_Nk * (i + 1), 60) - 1)) + 1 : ((Min(aes_const_Nk * (i + 1), 60) - 1) - (aes_const_Nk * i)) + 1)] = KExp_P[32 * ((((((7 - i) * 8) + (8 - (Min(aes_const_Nk * (i + 1), 60) - (aes_const_Nk * i)))) + (Min(aes_const_Nk * (i + 1), 60) - (aes_const_Nk * i))) - 1) - ((Min(aes_const_Nk * (i + 1), 60) - (aes_const_Nk * i)) - 1))+:32 * (Min(aes_const_Nk * (i + 1), 60) - (aes_const_Nk * i))];
				Ready_P[i] = Ready_N[i - 1];
			end
			always @(posedge clk)
				if (rst == 0) begin
					KExp_N[32 * ((7 - i) * 8)+:256] <= {aes_const_Nk {sv2v_cast_32({32 {1'b0}})}};
					Ready_N[i] <= 1'sb0;
				end
				else if (Ready_N[i - 1]) begin
					KExp_N[32 * ((7 - i) * 8)+:256] <= KExp_P[32 * ((7 - i) * 8)+:256];
					Ready_N[i] <= Ready_P[i];
				end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		KExp = KExp_R;
		Ready_out = Ready_N[7];
	end
	initial _sv2v_0 = 0;
endmodule
module aes_kexp_state (
	rst,
	clk,
	Key,
	RCon,
	SBox,
	Enable,
	KExp,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nk = 8;
	input wire [255:0] Key;
	input wire [127:0] RCon;
	input wire [2047:0] SBox;
	input wire [0:0] Enable;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 14;
	output reg [1919:0] KExp;
	output reg [0:0] Ready_out;
	reg [1919:0] KExp_R;
	reg [255:0] KExp_P;
	reg [255:0] KExp_N;
	localparam LENGTH = 60;
	localparam WIDTH = 6;
	function automatic [5:0] sv2v_cast_E6D93;
		input reg [5:0] inp;
		sv2v_cast_E6D93 = inp;
	endfunction
	reg [11:0] init_reg = {4'd0, sv2v_cast_E6D93(0), 2'h0};
	reg [11:0] r;
	reg [11:0] rin;
	reg [11:0] v;
	function [31:0] RotWord;
		input [31:0] Word;
		RotWord = {Word[23:0], Word[31:24]};
	endfunction
	function [31:0] SubWord;
		input [31:0] Word;
		SubWord = {SBox[(255 - Word[31:24]) * 8+:8], SBox[(255 - Word[23:16]) * 8+:8], SBox[(255 - Word[15:8]) * 8+:8], SBox[(255 - Word[7:0]) * 8+:8]};
	endfunction
	initial begin
		KExp_P = {aes_const_Nk {32'b00000000000000000000000000000000}};
		KExp_N = {aes_const_Nk {32'b00000000000000000000000000000000}};
	end
	always @(r[0] or KExp_R or v or v[7-:6] or KExp_P or v[7-:6] or v[1] or v[7-:6] or v[11-:4] or v[7-:6] or KExp_P or KExp_N or KExp_P or SBox or SBox or SBox or SBox or KExp_N or v[11-:4] or RCon or KExp_N[0+:32] or SBox or SBox or SBox or SBox or KExp_N or Key or Key or Key or Key or Enable or r[11-:4] or r or _sv2v_0) begin
		if (_sv2v_0)
			;
		v = r;
		case (r[11-:4])
			0: begin
				v[7-:6] = 0;
				v[1] = 0;
				v[0] = 0;
				if (Enable == 1) begin
					v[11-:4] = 1;
					v[1] = 1;
					begin : sv2v_autoblock_1
						reg signed [31:0] i;
						for (i = 0; i < aes_const_Nk; i = i + 1)
							KExp_P[(7 - i) * 32+:32] = {Key[(31 - (4 * i)) * 8+:8], Key[(31 - ((4 * i) + 1)) * 8+:8], Key[(31 - ((4 * i) + 2)) * 8+:8], Key[(31 - ((4 * i) + 3)) * 8+:8]};
					end
				end
			end
			default: begin
				begin : sv2v_autoblock_2
					reg signed [31:0] i;
					for (i = 0; i < aes_const_Nk; i = i + 1)
						if (i == 0)
							KExp_P[(7 - i) * 32+:32] = (KExp_N[(7 - i) * 32+:32] ^ SubWord(RotWord(KExp_N[0+:32]))) ^ {RCon[(15 - v[11-:4]) * 8+:8], 24'h000000};
						else if (i == 4)
							KExp_P[(7 - i) * 32+:32] = KExp_N[(7 - i) * 32+:32] ^ SubWord(KExp_P[(8 - i) * 32+:32]);
						else
							KExp_P[(7 - i) * 32+:32] = KExp_N[(7 - i) * 32+:32] ^ KExp_P[(8 - i) * 32+:32];
				end
				if (v[7-:6] > 52) begin
					v[11-:4] = 0;
					v[0] = 1;
				end
				else begin
					v[11-:4] = v[11-:4] + 1;
					v[0] = 0;
				end
			end
		endcase
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < aes_const_Nk; i = i + 1)
				if (((v[7-:6] + i[5:0]) < 60) && (v[1] == 1))
					KExp_R[(59 - (v[7-:6] + i[5:0])) * 32+:32] = KExp_P[(7 - i) * 32+:32];
		end
		v[7-:6] = v[7-:6] + aes_const_Nk;
		rin = v;
		KExp = KExp_R;
		Ready_out = r[0];
	end
	always @(posedge clk)
		if ((r[11-:4] != 0) || (Enable == 1))
			KExp_N <= KExp_P;
	always @(posedge clk)
		if (rst == 0)
			r <= init_reg;
		else if (((r[11-:4] != 0) || (r[0] == 1)) || (Enable == 1))
			r <= rin;
	initial _sv2v_0 = 0;
endmodule
module aes_arkey (
	State_in,
	KExp,
	Index,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	input wire [3:0] Index;
	output wire [127:0] State_out;
	genvar _gv_i_5;
	genvar _gv_j_2;
	generate
		for (_gv_j_2 = 0; _gv_j_2 < aes_const_Nb; _gv_j_2 = _gv_j_2 + 1) begin : genblk1
			localparam j = _gv_j_2;
			for (_gv_i_5 = 0; _gv_i_5 < 4; _gv_i_5 = _gv_i_5 + 1) begin : genblk1
				localparam i = _gv_i_5;
				assign State_out[(15 - ((4 * j) + i)) * 8+:8] = KExp[((59 - ((Index * aes_const_Nb) + j)) * 32) + ((((4 - i) * 8) - 1) >= ((3 - i) * 8) ? ((4 - i) * 8) - 1 : ((((4 - i) * 8) - 1) + ((((4 - i) * 8) - 1) >= ((3 - i) * 8) ? ((((4 - i) * 8) - 1) - ((3 - i) * 8)) + 1 : (((3 - i) * 8) - (((4 - i) * 8) - 1)) + 1)) - 1)-:((((4 - i) * 8) - 1) >= ((3 - i) * 8) ? ((((4 - i) * 8) - 1) - ((3 - i) * 8)) + 1 : (((3 - i) * 8) - (((4 - i) * 8) - 1)) + 1)] ^ State_in[(15 - ((4 * j) + i)) * 8+:8];
			end
		end
	endgenerate
endmodule
module aes_sbyte (
	State_in,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	output wire [127:0] State_out;
	genvar _gv_i_6;
	generate
		for (_gv_i_6 = 0; _gv_i_6 < 16; _gv_i_6 = _gv_i_6 + 1) begin : gen_cfa_sbox
			localparam i = _gv_i_6;
			aes_cfa_sbox cell_i(
				.a_in(State_in[(15 - i) * 8+:8]),
				.s_out(State_out[(15 - i) * 8+:8])
			);
		end
	endgenerate
endmodule
module aes_isbyte (
	State_in,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	output wire [127:0] State_out;
	genvar _gv_i_7;
	generate
		for (_gv_i_7 = 0; _gv_i_7 < 16; _gv_i_7 = _gv_i_7 + 1) begin : gen_cfa_isbox
			localparam i = _gv_i_7;
			aes_cfa_isbox cell_i(
				.s_in(State_in[(15 - i) * 8+:8]),
				.a_out(State_out[(15 - i) * 8+:8])
			);
		end
	endgenerate
endmodule
module aes_srow (
	State_in,
	State_out
);
	reg _sv2v_0;
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	output wire [127:0] State_out;
	genvar _gv_i_8;
	genvar _gv_j_3;
	reg [2:0] C [0:2];
	always @(*) begin
		if (_sv2v_0)
			;
		C[0] = 1;
		C[1] = 2;
		C[2] = 3;
	end
	generate
		for (_gv_j_3 = 0; _gv_j_3 < aes_const_Nb; _gv_j_3 = _gv_j_3 + 1) begin : genblk1
			localparam j = _gv_j_3;
			assign State_out[(15 - (4 * j)) * 8+:8] = State_in[(15 - (4 * j)) * 8+:8];
		end
		for (_gv_j_3 = 0; _gv_j_3 < aes_const_Nb; _gv_j_3 = _gv_j_3 + 1) begin : genblk2
			localparam j = _gv_j_3;
			for (_gv_i_8 = 1; _gv_i_8 < 4; _gv_i_8 = _gv_i_8 + 1) begin : genblk1
				localparam i = _gv_i_8;
				assign State_out[(15 - ((4 * j) + i)) * 8+:8] = State_in[(15 - ((4 * ((j + C[i - 1]) % aes_const_Nb)) + i)) * 8+:8];
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module aes_isrow (
	State_in,
	State_out
);
	reg _sv2v_0;
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	output wire [127:0] State_out;
	genvar _gv_i_9;
	genvar _gv_j_4;
	reg [2:0] C [0:2];
	always @(*) begin
		if (_sv2v_0)
			;
		C[0] = 1;
		C[1] = 2;
		C[2] = 3;
	end
	generate
		for (_gv_j_4 = 0; _gv_j_4 < aes_const_Nb; _gv_j_4 = _gv_j_4 + 1) begin : genblk1
			localparam j = _gv_j_4;
			assign State_out[(15 - (4 * j)) * 8+:8] = State_in[(15 - (4 * j)) * 8+:8];
		end
		for (_gv_j_4 = 0; _gv_j_4 < aes_const_Nb; _gv_j_4 = _gv_j_4 + 1) begin : genblk2
			localparam j = _gv_j_4;
			for (_gv_i_9 = 1; _gv_i_9 < 4; _gv_i_9 = _gv_i_9 + 1) begin : genblk1
				localparam i = _gv_i_9;
				assign State_out[(15 - ((4 * j) + i)) * 8+:8] = State_in[(15 - ((4 * (((j + aes_const_Nb) - C[i - 1]) % aes_const_Nb)) + i)) * 8+:8];
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module aes_mcol (
	State_in,
	State_out
);
	reg _sv2v_0;
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	output reg [127:0] State_out;
	wire [7:0] xt2 [0:15];
	assign xt2[0] = {State_in[126-:7], 1'b0} ^ (State_in[127] ? 8'h1b : 8'h00);
	assign xt2[1] = {State_in[118-:7], 1'b0} ^ (State_in[119] ? 8'h1b : 8'h00);
	assign xt2[2] = {State_in[110-:7], 1'b0} ^ (State_in[111] ? 8'h1b : 8'h00);
	assign xt2[3] = {State_in[102-:7], 1'b0} ^ (State_in[103] ? 8'h1b : 8'h00);
	assign xt2[4] = {State_in[94-:7], 1'b0} ^ (State_in[95] ? 8'h1b : 8'h00);
	assign xt2[5] = {State_in[86-:7], 1'b0} ^ (State_in[87] ? 8'h1b : 8'h00);
	assign xt2[6] = {State_in[78-:7], 1'b0} ^ (State_in[79] ? 8'h1b : 8'h00);
	assign xt2[7] = {State_in[70-:7], 1'b0} ^ (State_in[71] ? 8'h1b : 8'h00);
	assign xt2[8] = {State_in[62-:7], 1'b0} ^ (State_in[63] ? 8'h1b : 8'h00);
	assign xt2[9] = {State_in[54-:7], 1'b0} ^ (State_in[55] ? 8'h1b : 8'h00);
	assign xt2[10] = {State_in[46-:7], 1'b0} ^ (State_in[47] ? 8'h1b : 8'h00);
	assign xt2[11] = {State_in[38-:7], 1'b0} ^ (State_in[39] ? 8'h1b : 8'h00);
	assign xt2[12] = {State_in[30-:7], 1'b0} ^ (State_in[31] ? 8'h1b : 8'h00);
	assign xt2[13] = {State_in[22-:7], 1'b0} ^ (State_in[23] ? 8'h1b : 8'h00);
	assign xt2[14] = {State_in[14-:7], 1'b0} ^ (State_in[15] ? 8'h1b : 8'h00);
	assign xt2[15] = {State_in[6-:7], 1'b0} ^ (State_in[7] ? 8'h1b : 8'h00);
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < aes_const_Nb; i = i + 1)
				begin
					State_out[(15 - (4 * i)) * 8+:8] = ((xt2[4 * i] ^ (xt2[(4 * i) + 1] ^ State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ State_in[(15 - ((4 * i) + 2)) * 8+:8]) ^ State_in[(15 - ((4 * i) + 3)) * 8+:8];
					State_out[(15 - ((4 * i) + 1)) * 8+:8] = ((State_in[(15 - (4 * i)) * 8+:8] ^ xt2[(4 * i) + 1]) ^ (xt2[(4 * i) + 2] ^ State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ State_in[(15 - ((4 * i) + 3)) * 8+:8];
					State_out[(15 - ((4 * i) + 2)) * 8+:8] = ((State_in[(15 - (4 * i)) * 8+:8] ^ State_in[(15 - ((4 * i) + 1)) * 8+:8]) ^ xt2[(4 * i) + 2]) ^ (xt2[(4 * i) + 3] ^ State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 3)) * 8+:8] = (((xt2[4 * i] ^ State_in[(15 - (4 * i)) * 8+:8]) ^ State_in[(15 - ((4 * i) + 1)) * 8+:8]) ^ State_in[(15 - ((4 * i) + 2)) * 8+:8]) ^ xt2[(4 * i) + 3];
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module aes_imcol (
	State_in,
	State_out
);
	reg _sv2v_0;
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	output reg [127:0] State_out;
	wire [7:0] xt2 [0:15];
	wire [7:0] xt4 [0:15];
	wire [7:0] xt8 [0:15];
	assign xt2[0] = {State_in[126-:7], 1'b0} ^ (State_in[127] ? 8'h1b : 8'h00);
	assign xt2[1] = {State_in[118-:7], 1'b0} ^ (State_in[119] ? 8'h1b : 8'h00);
	assign xt2[2] = {State_in[110-:7], 1'b0} ^ (State_in[111] ? 8'h1b : 8'h00);
	assign xt2[3] = {State_in[102-:7], 1'b0} ^ (State_in[103] ? 8'h1b : 8'h00);
	assign xt2[4] = {State_in[94-:7], 1'b0} ^ (State_in[95] ? 8'h1b : 8'h00);
	assign xt2[5] = {State_in[86-:7], 1'b0} ^ (State_in[87] ? 8'h1b : 8'h00);
	assign xt2[6] = {State_in[78-:7], 1'b0} ^ (State_in[79] ? 8'h1b : 8'h00);
	assign xt2[7] = {State_in[70-:7], 1'b0} ^ (State_in[71] ? 8'h1b : 8'h00);
	assign xt2[8] = {State_in[62-:7], 1'b0} ^ (State_in[63] ? 8'h1b : 8'h00);
	assign xt2[9] = {State_in[54-:7], 1'b0} ^ (State_in[55] ? 8'h1b : 8'h00);
	assign xt2[10] = {State_in[46-:7], 1'b0} ^ (State_in[47] ? 8'h1b : 8'h00);
	assign xt2[11] = {State_in[38-:7], 1'b0} ^ (State_in[39] ? 8'h1b : 8'h00);
	assign xt2[12] = {State_in[30-:7], 1'b0} ^ (State_in[31] ? 8'h1b : 8'h00);
	assign xt2[13] = {State_in[22-:7], 1'b0} ^ (State_in[23] ? 8'h1b : 8'h00);
	assign xt2[14] = {State_in[14-:7], 1'b0} ^ (State_in[15] ? 8'h1b : 8'h00);
	assign xt2[15] = {State_in[6-:7], 1'b0} ^ (State_in[7] ? 8'h1b : 8'h00);
	assign xt4[0] = {xt2[0][6:0], 1'b0} ^ (xt2[0][7] ? 8'h1b : 8'h00);
	assign xt4[1] = {xt2[1][6:0], 1'b0} ^ (xt2[1][7] ? 8'h1b : 8'h00);
	assign xt4[2] = {xt2[2][6:0], 1'b0} ^ (xt2[2][7] ? 8'h1b : 8'h00);
	assign xt4[3] = {xt2[3][6:0], 1'b0} ^ (xt2[3][7] ? 8'h1b : 8'h00);
	assign xt4[4] = {xt2[4][6:0], 1'b0} ^ (xt2[4][7] ? 8'h1b : 8'h00);
	assign xt4[5] = {xt2[5][6:0], 1'b0} ^ (xt2[5][7] ? 8'h1b : 8'h00);
	assign xt4[6] = {xt2[6][6:0], 1'b0} ^ (xt2[6][7] ? 8'h1b : 8'h00);
	assign xt4[7] = {xt2[7][6:0], 1'b0} ^ (xt2[7][7] ? 8'h1b : 8'h00);
	assign xt4[8] = {xt2[8][6:0], 1'b0} ^ (xt2[8][7] ? 8'h1b : 8'h00);
	assign xt4[9] = {xt2[9][6:0], 1'b0} ^ (xt2[9][7] ? 8'h1b : 8'h00);
	assign xt4[10] = {xt2[10][6:0], 1'b0} ^ (xt2[10][7] ? 8'h1b : 8'h00);
	assign xt4[11] = {xt2[11][6:0], 1'b0} ^ (xt2[11][7] ? 8'h1b : 8'h00);
	assign xt4[12] = {xt2[12][6:0], 1'b0} ^ (xt2[12][7] ? 8'h1b : 8'h00);
	assign xt4[13] = {xt2[13][6:0], 1'b0} ^ (xt2[13][7] ? 8'h1b : 8'h00);
	assign xt4[14] = {xt2[14][6:0], 1'b0} ^ (xt2[14][7] ? 8'h1b : 8'h00);
	assign xt4[15] = {xt2[15][6:0], 1'b0} ^ (xt2[15][7] ? 8'h1b : 8'h00);
	assign xt8[0] = {xt4[0][6:0], 1'b0} ^ (xt4[0][7] ? 8'h1b : 8'h00);
	assign xt8[1] = {xt4[1][6:0], 1'b0} ^ (xt4[1][7] ? 8'h1b : 8'h00);
	assign xt8[2] = {xt4[2][6:0], 1'b0} ^ (xt4[2][7] ? 8'h1b : 8'h00);
	assign xt8[3] = {xt4[3][6:0], 1'b0} ^ (xt4[3][7] ? 8'h1b : 8'h00);
	assign xt8[4] = {xt4[4][6:0], 1'b0} ^ (xt4[4][7] ? 8'h1b : 8'h00);
	assign xt8[5] = {xt4[5][6:0], 1'b0} ^ (xt4[5][7] ? 8'h1b : 8'h00);
	assign xt8[6] = {xt4[6][6:0], 1'b0} ^ (xt4[6][7] ? 8'h1b : 8'h00);
	assign xt8[7] = {xt4[7][6:0], 1'b0} ^ (xt4[7][7] ? 8'h1b : 8'h00);
	assign xt8[8] = {xt4[8][6:0], 1'b0} ^ (xt4[8][7] ? 8'h1b : 8'h00);
	assign xt8[9] = {xt4[9][6:0], 1'b0} ^ (xt4[9][7] ? 8'h1b : 8'h00);
	assign xt8[10] = {xt4[10][6:0], 1'b0} ^ (xt4[10][7] ? 8'h1b : 8'h00);
	assign xt8[11] = {xt4[11][6:0], 1'b0} ^ (xt4[11][7] ? 8'h1b : 8'h00);
	assign xt8[12] = {xt4[12][6:0], 1'b0} ^ (xt4[12][7] ? 8'h1b : 8'h00);
	assign xt8[13] = {xt4[13][6:0], 1'b0} ^ (xt4[13][7] ? 8'h1b : 8'h00);
	assign xt8[14] = {xt4[14][6:0], 1'b0} ^ (xt4[14][7] ? 8'h1b : 8'h00);
	assign xt8[15] = {xt4[15][6:0], 1'b0} ^ (xt4[15][7] ? 8'h1b : 8'h00);
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < aes_const_Nb; i = i + 1)
				begin
					State_out[(15 - (4 * i)) * 8+:8] = ((((xt8[4 * i] ^ xt4[4 * i]) ^ xt2[4 * i]) ^ ((xt8[(4 * i) + 1] ^ xt2[(4 * i) + 1]) ^ State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ ((xt8[(4 * i) + 2] ^ xt4[(4 * i) + 2]) ^ State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ (xt8[(4 * i) + 3] ^ State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 1)) * 8+:8] = (((xt8[4 * i] ^ State_in[(15 - (4 * i)) * 8+:8]) ^ ((xt8[(4 * i) + 1] ^ xt4[(4 * i) + 1]) ^ xt2[(4 * i) + 1])) ^ ((xt8[(4 * i) + 2] ^ xt2[(4 * i) + 2]) ^ State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ ((xt8[(4 * i) + 3] ^ xt4[(4 * i) + 3]) ^ State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 2)) * 8+:8] = ((((xt8[4 * i] ^ xt4[4 * i]) ^ State_in[(15 - (4 * i)) * 8+:8]) ^ (xt8[(4 * i) + 1] ^ State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ ((xt8[(4 * i) + 2] ^ xt4[(4 * i) + 2]) ^ xt2[(4 * i) + 2])) ^ ((xt8[(4 * i) + 3] ^ xt2[(4 * i) + 3]) ^ State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 3)) * 8+:8] = ((((xt8[4 * i] ^ xt2[4 * i]) ^ State_in[(15 - (4 * i)) * 8+:8]) ^ ((xt8[(4 * i) + 1] ^ xt4[(4 * i) + 1]) ^ State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ (xt8[(4 * i) + 2] ^ State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ ((xt8[(4 * i) + 3] ^ xt4[(4 * i) + 3]) ^ xt2[(4 * i) + 3]);
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module aes_round (
	State_in,
	Index,
	KExp,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	output wire [127:0] State_out;
	wire [127:0] State_B;
	wire [127:0] State_R;
	wire [127:0] State_M;
	aes_sbyte aes_sbyte_comp(
		.State_in(State_in),
		.State_out(State_B)
	);
	aes_srow aes_srow_comp(
		.State_in(State_B),
		.State_out(State_R)
	);
	aes_mcol aes_mcol_comp(
		.State_in(State_R),
		.State_out(State_M)
	);
	aes_arkey aes_arkey_comp(
		.State_in(State_M),
		.KExp(KExp),
		.Index(Index),
		.State_out(State_out)
	);
endmodule
module aes_iround (
	State_in,
	Index,
	KExp,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	output wire [127:0] State_out;
	wire [127:0] State_R;
	wire [127:0] State_B;
	wire [127:0] State_A;
	aes_isrow aes_isrow_comp(
		.State_in(State_in),
		.State_out(State_R)
	);
	aes_isbyte aes_isbyte_comp(
		.State_in(State_R),
		.State_out(State_B)
	);
	aes_arkey aes_arkey_comp(
		.State_in(State_B),
		.KExp(KExp),
		.Index(Index),
		.State_out(State_A)
	);
	aes_imcol aes_imcol_comp(
		.State_in(State_A),
		.State_out(State_out)
	);
endmodule
module aes_fround (
	State_in,
	Index,
	KExp,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	output wire [127:0] State_out;
	wire [127:0] State_B;
	wire [127:0] State_R;
	aes_sbyte aes_sbyte_comp(
		.State_in(State_in),
		.State_out(State_B)
	);
	aes_srow aes_srow_comp(
		.State_in(State_B),
		.State_out(State_R)
	);
	aes_arkey aes_arkey_comp(
		.State_in(State_R),
		.KExp(KExp),
		.Index(Index),
		.State_out(State_out)
	);
endmodule
module aes_ifround (
	State_in,
	Index,
	KExp,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	output wire [127:0] State_out;
	wire [127:0] State_R;
	wire [127:0] State_B;
	aes_isrow aes_isrow_comp(
		.State_in(State_in),
		.State_out(State_R)
	);
	aes_isbyte aes_isbyte_comp(
		.State_in(State_R),
		.State_out(State_B)
	);
	aes_arkey aes_arkey_comp(
		.State_in(State_B),
		.KExp(KExp),
		.Index(Index),
		.State_out(State_out)
	);
endmodule
module aes_cipher (
	rst,
	clk,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	input wire [127:0] Data_in;
	input wire [0:0] Enable;
	output wire [127:0] Data_out;
	output reg [0:0] Ready_out;
	genvar _gv_i_10;
	wire [127:0] State [0:13];
	reg [127:0] State_Reg [0:13];
	reg [0:0] Ready [0:13];
	reg [0:0] Ready_Reg [0:13];
	wire [127:0] sbyte_in_muxed [0:13];
	aes_arkey aes_arkey_comp(
		.State_in(Data_in),
		.KExp(KExp),
		.Index(4'h0),
		.State_out(State[0])
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready[0] = Enable;
	end
	always @(posedge clk)
		if (rst == 0)
			Ready_Reg[0] <= 1'sb0;
		else if (Enable || Ready_Reg[0]) begin
			State_Reg[0] <= State[0];
			Ready_Reg[0] <= Ready[0];
		end
	generate
		for (_gv_i_10 = 2; _gv_i_10 < aes_const_Nr; _gv_i_10 = _gv_i_10 + 1) begin : genblk1
			localparam i = _gv_i_10;
			always @(posedge clk)
				if (rst == 0)
					Ready_Reg[i - 1] <= 1'sb0;
				else if (Ready_Reg[i - 2] || Ready_Reg[i - 1]) begin
					State_Reg[i - 1] <= State[i - 1];
					Ready_Reg[i - 1] <= Ready[i - 1];
				end
			assign sbyte_in_muxed[i - 1] = (Ready_Reg[i - 1] ? State_Reg[i - 1] : {16 {8'b00000000}});
			aes_round aes_round_comp(
				.State_in(sbyte_in_muxed[i - 1]),
				.Index(i[3:0]),
				.KExp(KExp),
				.State_out(State[i])
			);
			always @(*) begin
				if (_sv2v_0)
					;
				Ready[i] = Ready_Reg[i - 1];
			end
		end
	endgenerate
	assign sbyte_in_muxed[0] = (Ready_Reg[0] ? State_Reg[0] : {16 {8'b00000000}});
	aes_round aes_round1_comp(
		.State_in(sbyte_in_muxed[0]),
		.Index(4'h1),
		.KExp(KExp),
		.State_out(State[1])
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready[1] = Ready_Reg[0];
	end
	always @(posedge clk)
		if (rst == 0)
			Ready_Reg[13] <= 1'sb0;
		else if (Ready_Reg[12] || Ready_Reg[13]) begin
			State_Reg[13] <= State[13];
			Ready_Reg[13] <= Ready[13];
		end
	assign sbyte_in_muxed[13] = (Ready_Reg[13] ? State_Reg[13] : {16 {8'b00000000}});
	aes_fround aes_fround_comp(
		.State_in(sbyte_in_muxed[13]),
		.Index(aes_const_Nr[3:0]),
		.KExp(KExp),
		.State_out(Data_out)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready_out = Ready_Reg[13];
	end
	initial _sv2v_0 = 0;
endmodule
module aes_icipher (
	rst,
	clk,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	input wire [127:0] Data_in;
	input wire [0:0] Enable;
	output wire [127:0] Data_out;
	output reg [0:0] Ready_out;
	genvar _gv_i_11;
	wire [127:0] State [0:13];
	reg [127:0] State_Reg [0:13];
	reg [0:0] Ready [0:13];
	reg [0:0] Ready_Reg [0:13];
	wire [127:0] isbyte_in_muxed [0:13];
	aes_arkey aes_arkey_comp(
		.State_in(Data_in),
		.KExp(KExp),
		.Index(aes_const_Nr[3:0]),
		.State_out(State[13])
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready[13] = Enable;
	end
	always @(posedge clk)
		if (rst == 0)
			Ready_Reg[13] <= 1'sb0;
		else if (Enable || Ready_Reg[13]) begin
			State_Reg[13] <= State[13];
			Ready_Reg[13] <= Ready[13];
		end
	assign isbyte_in_muxed[13] = (Ready_Reg[13] ? State_Reg[13] : {16 {8'b00000000}});
	aes_iround aes_iround_top_comp(
		.State_in(isbyte_in_muxed[13]),
		.Index(4'sd13),
		.KExp(KExp),
		.State_out(State[12])
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready[12] = Ready_Reg[13];
	end
	generate
		for (_gv_i_11 = 12; _gv_i_11 > 0; _gv_i_11 = _gv_i_11 - 1) begin : genblk1
			localparam i = _gv_i_11;
			always @(posedge clk)
				if (rst == 0)
					Ready_Reg[i] <= 1'sb0;
				else if (Ready_Reg[i + 1] || Ready_Reg[i]) begin
					State_Reg[i] <= State[i];
					Ready_Reg[i] <= Ready[i];
				end
			assign isbyte_in_muxed[i] = (Ready_Reg[i] ? State_Reg[i] : {16 {8'b00000000}});
			aes_iround aes_iround_comp(
				.State_in(isbyte_in_muxed[i]),
				.Index(i[3:0]),
				.KExp(KExp),
				.State_out(State[i - 1])
			);
			always @(*) begin
				if (_sv2v_0)
					;
				Ready[i - 1] = Ready_Reg[i];
			end
		end
	endgenerate
	always @(posedge clk)
		if (rst == 0)
			Ready_Reg[0] <= 1'sb0;
		else if (Ready_Reg[1] || Ready_Reg[0]) begin
			State_Reg[0] <= State[0];
			Ready_Reg[0] <= Ready[0];
		end
	assign isbyte_in_muxed[0] = (Ready_Reg[0] ? State_Reg[0] : {16 {8'b00000000}});
	aes_ifround aes_ifround_comp(
		.State_in(isbyte_in_muxed[0]),
		.Index(4'h0),
		.KExp(KExp),
		.State_out(Data_out)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready_out = Ready_Reg[0];
	end
	initial _sv2v_0 = 0;
endmodule
module aes_cipher_state (
	rst,
	clk,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	input wire [127:0] Data_in;
	input wire [0:0] Enable;
	output reg [127:0] Data_out;
	output reg [0:0] Ready_out;
	reg [4:0] init_reg = 5'h00;
	reg [4:0] r;
	reg [4:0] rin;
	reg [4:0] v;
	reg [127:0] State_B_in;
	reg [127:0] State_R_in;
	reg [127:0] State_M_in;
	reg [127:0] State_A_in;
	wire [127:0] State_B_out;
	wire [127:0] State_R_out;
	wire [127:0] State_M_out;
	wire [127:0] State_A_out;
	reg [127:0] State_P;
	reg [127:0] State_N;
	reg [3:0] Index;
	initial begin
		State_P = {16 {8'b00000000}};
		State_N = {16 {8'b00000000}};
	end
	always @(*) begin
		if (_sv2v_0)
			;
		v = r;
		case (r[4-:4])
			0: begin
				if (Enable == 1)
					v[4-:4] = 1;
				v[0] = 0;
				State_B_in = {16 {8'b00000000}};
				State_R_in = {16 {8'b00000000}};
				State_M_in = {16 {8'b00000000}};
				State_A_in = Data_in;
				State_P = State_A_out;
				Index = 4'h0;
			end
			aes_const_Nr: begin
				v[4-:4] = 0;
				v[0] = 1;
				State_B_in = State_N;
				State_R_in = State_B_out;
				State_M_in = {16 {8'b00000000}};
				State_A_in = State_R_out;
				State_P = State_A_out;
				Index = aes_const_Nr[3:0];
			end
			default: begin
				v[4-:4] = v[4-:4] + 1;
				v[0] = 0;
				State_B_in = State_N;
				State_R_in = State_B_out;
				State_M_in = State_R_out;
				State_A_in = State_M_out;
				State_P = State_A_out;
				Index = r[4-:4];
			end
		endcase
		rin = v;
		Data_out = State_N;
		Ready_out = r[0];
	end
	always @(posedge clk)
		if (rst == 0)
			State_N <= {16 {8'b00000000}};
		else if (((r[4-:4] != 0) || (r[0] == 1)) || (Enable == 1))
			State_N <= State_P;
	aes_sbyte aes_sbyte_comp(
		.State_in(State_B_in),
		.State_out(State_B_out)
	);
	aes_srow aes_srow_comp(
		.State_in(State_R_in),
		.State_out(State_R_out)
	);
	aes_mcol aes_mcol_comp(
		.State_in(State_M_in),
		.State_out(State_M_out)
	);
	aes_arkey aes_arkey_comp(
		.State_in(State_A_in),
		.KExp(KExp),
		.Index(Index),
		.State_out(State_A_out)
	);
	always @(posedge clk)
		if (rst == 0)
			r <= init_reg;
		else if (((r[4-:4] != 0) || (r[0] == 1)) || (Enable == 1))
			r <= rin;
	initial _sv2v_0 = 0;
endmodule
module aes_icipher_state (
	rst,
	clk,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 14;
	input wire [1919:0] KExp;
	input wire [127:0] Data_in;
	input wire [0:0] Enable;
	output reg [127:0] Data_out;
	output reg [0:0] Ready_out;
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
	reg [4:0] init_reg = {sv2v_cast_4(aes_const_Nr), 1'd0};
	reg [4:0] r;
	reg [4:0] rin;
	reg [4:0] v;
	reg [127:0] State_B_in;
	reg [127:0] State_R_in;
	reg [127:0] State_M_in;
	reg [127:0] State_A_in;
	wire [127:0] State_B_out;
	wire [127:0] State_R_out;
	wire [127:0] State_M_out;
	wire [127:0] State_A_out;
	reg [127:0] State_P;
	reg [127:0] State_N;
	reg [3:0] Index;
	initial begin
		State_P = {16 {8'b00000000}};
		State_N = {16 {8'b00000000}};
	end
	always @(*) begin
		if (_sv2v_0)
			;
		v = r;
		case (r[4-:4])
			aes_const_Nr: begin
				if (Enable == 1)
					v[4-:4] = 13;
				v[0] = 0;
				State_R_in = {16 {8'b00000000}};
				State_B_in = {16 {8'b00000000}};
				State_A_in = Data_in;
				State_M_in = {16 {8'b00000000}};
				State_P = State_A_out;
				Index = aes_const_Nr[3:0];
			end
			0: begin
				v[4-:4] = aes_const_Nr;
				v[0] = 1;
				State_R_in = State_N;
				State_B_in = State_R_out;
				State_A_in = State_B_out;
				State_M_in = {16 {8'b00000000}};
				State_P = State_A_out;
				Index = 4'h0;
			end
			default: begin
				v[4-:4] = v[4-:4] - 1;
				v[0] = 0;
				State_R_in = State_N;
				State_B_in = State_R_out;
				State_A_in = State_B_out;
				State_M_in = State_A_out;
				State_P = State_M_out;
				Index = r[4-:4];
			end
		endcase
		rin = v;
		Data_out = State_N;
		Ready_out = r[0];
	end
	always @(posedge clk)
		if (rst == 0)
			State_N <= {16 {8'b00000000}};
		else if (((r[4-:4] != aes_const_Nr) || (r[0] == 1)) || (Enable == 1))
			State_N <= State_P;
	aes_isrow aes_isrow_comp(
		.State_in(State_R_in),
		.State_out(State_R_out)
	);
	aes_isbyte aes_isbyte_comp(
		.State_in(State_B_in),
		.State_out(State_B_out)
	);
	aes_arkey aes_arkey_comp(
		.State_in(State_A_in),
		.KExp(KExp),
		.Index(Index),
		.State_out(State_A_out)
	);
	aes_imcol aes_imcol_comp(
		.State_in(State_M_in),
		.State_out(State_M_out)
	);
	always @(posedge clk)
		if (rst == 0)
			r <= init_reg;
		else if (((r[4-:4] != aes_const_Nr) || (r[0] == 1)) || (Enable == 1))
			r <= rin;
	initial _sv2v_0 = 0;
endmodule
module aes_state (
	rst,
	clk,
	aes_in,
	aes_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nk = 8;
	input wire [386:0] aes_in;
	output reg [128:0] aes_out;
	localparam aes_const_Nr = 14;
	wire [1919:0] kexp;
	wire [2047:0] sbox;
	wire [2047:0] ibox;
	wire [127:0] rcon;
	wire [255:0] key_array;
	wire [127:0] data_array;
	wire [127:0] cipher_array;
	wire [127:0] icipher_array;
	wire [127:0] cipher_data;
	wire [127:0] icipher_data;
	reg [0:0] kexp_enable;
	reg [0:0] cipher_enable;
	reg [0:0] icipher_enable;
	wire [0:0] kexp_ready;
	wire [0:0] cipher_ready;
	wire [0:0] icipher_ready;
	aes_array aes_array_comp(
		.SBox(sbox),
		.IBox(ibox),
		.RCon(rcon)
	);
	aes_xkey aes_xkey_comp(
		.key_in(aes_in[386-:256]),
		.key_out(key_array)
	);
	aes_xdata aes_xdata_comp(
		.data_in(aes_in[130-:128]),
		.data_out(data_array)
	);
	aes_kexp_state aes_kexp_state_comp(
		.rst(rst),
		.clk(clk),
		.Key(key_array),
		.RCon(rcon),
		.SBox(sbox),
		.Enable(kexp_enable),
		.KExp(kexp),
		.Ready_out(kexp_ready)
	);
	aes_cipher_state aes_cipher_state_comp(
		.rst(rst),
		.clk(clk),
		.KExp(kexp),
		.Data_in(data_array),
		.Enable(cipher_enable),
		.Data_out(cipher_array),
		.Ready_out(cipher_ready)
	);
	aes_icipher_state aes_icipher_state_comp(
		.rst(rst),
		.clk(clk),
		.KExp(kexp),
		.Data_in(data_array),
		.Enable(icipher_enable),
		.Data_out(icipher_array),
		.Ready_out(icipher_ready)
	);
	aes_cdata aes_cdata_cipher_comp(
		.data_in(cipher_array),
		.data_out(cipher_data)
	);
	aes_cdata aes_cdata_icipher_comp(
		.data_in(icipher_array),
		.data_out(icipher_data)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		kexp_enable = 0;
		cipher_enable = 0;
		icipher_enable = 0;
		if (aes_in[0] == 1) begin
			if (aes_in[2-:2] == 1)
				kexp_enable = 1;
			else if (aes_in[2-:2] == 2)
				cipher_enable = 1;
			else if (aes_in[2-:2] == 3)
				icipher_enable = 1;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (kexp_ready == 1) begin
			aes_out[128-:128] = 0;
			aes_out[0] = kexp_ready;
		end
		else if (cipher_ready == 1) begin
			aes_out[128-:128] = cipher_data;
			aes_out[0] = cipher_ready;
		end
		else if (icipher_ready == 1) begin
			aes_out[128-:128] = icipher_data;
			aes_out[0] = icipher_ready;
		end
		else begin
			aes_out[128-:128] = 0;
			aes_out[0] = 0;
		end
	end
	initial _sv2v_0 = 0;
endmodule
