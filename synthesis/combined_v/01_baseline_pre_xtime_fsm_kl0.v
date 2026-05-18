module aes_xkey (
	key_in,
	key_out
);
	localparam aes_const_Nk = 4;
	input wire [127:0] key_in;
	output wire [127:0] key_out;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 3; _gv_i_1 >= 0; _gv_i_1 = _gv_i_1 - 1) begin : genblk1
			localparam i = _gv_i_1;
			assign key_out[(15 - (4 * ((aes_const_Nk - i) - 1))) * 8+:8] = key_in[(32 * (i + 1)) - 1:(32 * i) + 24];
			assign key_out[(15 - ((4 * ((aes_const_Nk - i) - 1)) + 1)) * 8+:8] = key_in[(32 * (i + 1)) - 9:(32 * i) + 16];
			assign key_out[(15 - ((4 * ((aes_const_Nk - i) - 1)) + 2)) * 8+:8] = key_in[(32 * (i + 1)) - 17:(32 * i) + 8];
			assign key_out[(15 - ((4 * ((aes_const_Nk - i) - 1)) + 3)) * 8+:8] = key_in[(32 * (i + 1)) - 25:32 * i];
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
	EXP3,
	LN3,
	RCon
);
	output wire [2047:0] SBox;
	output wire [2047:0] IBox;
	output wire [2047:0] EXP3;
	output wire [2047:0] LN3;
	output wire [127:0] RCon;
	localparam [2047:0] sbox = 2048'h637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b27509832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cfd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdbe0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9ee1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16;
	localparam [2047:0] ibox = 2048'h52096ad53036a538bf40a39e81f3d7fb7ce339829b2fff87348e4344c4dee9cb547b9432a6c2233dee4c950b42fac34e082ea16628d924b2765ba2496d8bd12572f8f66486689816d4a45ccc5d65b6926c704850fdedb9da5e154657a78d9d8490d8ab008cbcd30af7e45805b8b34506d02c1e8fca3f0f02c1afbd0301138a6b3a9111414f67dcea97f2cfcef0b4e67396ac7422e7ad3585e2f937e81c75df6e47f11a711d29c5896fb7620eaa18be1bfc563e4bc6d279209adbc0fe78cd5af41fdda8338807c731b11210592780ec5f60517fa919b54a0d2de57a9f93c99cefa0e03b4dae2af5b0c8ebbb3c83539961172b047eba77d626e169146355210c7d;
	localparam [2047:0] exp3 = 2048'h103050f113355ff1a2e7296a1f813355fe13848d87395a4f702060a1e2266aae5345ce43759eb266abed97090abe63153f5040c143c44cc4fd168b8d36eb2cd4cd467a9e03b4dd762a6f10818287888839eb9d06bbddc7f8198b3ce49db769ab5c457f9103050f00b1d2769bbd661a3fe192b7d8792adec2f7193aee92060a0fb163a4ed26db7c25de73256fa153f41c35ee23d47c940c05bed2c749cbfda759fbad564acef2a7e829dbcdf7a8e89809bb6c158e82365afea256fb1c843c554fc1f2163a5f407091b2d7799b0cb46ca45cf4ade798b8691a8e33e42c651f30e12365aee297b8d8c8f8a8594a7f20d17394bdd7c8497a2fd1c246cb4c752f601;
	localparam [2047:0] ln3 = 2048'h190132021ac64bc71b6833eedf036404e00e348d81ef4c7108c8f8691cc17dc21db5f9b9276a4de4a6729ac90978652f8a05210fe12412f082453593da8e968fdbbd36d0ce94135cd2f14046833866ddfd30bf068b62b325e298228891107e6e48c3a3b61e423a6b2854fa853dba2b790a159b9f5eca4ed4ace5f373a757af58a850f4ead6744faee9d5e7e6ade82cd7757aeb160bf559cb5fb09ca951a07f0cf66f17c449ecd8431f2da4767bb7ccbb3e5afb60b1863b52a16caa55299d97b2879061bedcfcbc95cfcd373f5bd15339843c41a26d47142a9e5d56f2d3ab441192d923202e89b47cb8267799e3a5674aeddec531fe180d638c80c0f77007;
	localparam [127:0] rcon = 128'h0001020408102040801b366cd8ab4d9a;
	assign SBox = sbox;
	assign IBox = ibox;
	assign EXP3 = exp3;
	assign LN3 = ln3;
	assign RCon = rcon;
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
	localparam aes_const_Nk = 4;
	input wire [127:0] Key;
	input wire [127:0] RCon;
	input wire [2047:0] SBox;
	input wire [0:0] Enable;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 10;
	output reg [1407:0] KExp;
	output reg [0:0] Ready_out;
	localparam Nx = 11;
	reg [1407:0] KExp_R;
	reg [1407:0] KExp_P;
	reg [1407:0] KExp_N;
	reg [0:0] Ready_P [0:10];
	reg [0:0] Ready_N [0:10];
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
	function automatic [127:0] sv2v_cast_B6EF8;
		input reg [127:0] inp;
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
					KExp_P[(40 + (3 - i)) * 32+:32] = {Key[(15 - (4 * i)) * 8+:8], Key[(15 - ((4 * i) + 1)) * 8+:8], Key[(15 - ((4 * i) + 2)) * 8+:8], Key[(15 - ((4 * i) + 3)) * 8+:8]};
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		KExp_R[1280+:128] = KExp_P[1280+:128];
		Ready_P[0] = Enable;
	end
	always @(posedge clk) begin
		KExp_N[1280+:128] <= KExp_P[1280+:128];
		Ready_N[0] <= Ready_P[0];
	end
	generate
		for (_gv_i_4 = 1; _gv_i_4 < Nx; _gv_i_4 = _gv_i_4 + 1) begin : genblk2
			localparam i = _gv_i_4;
			for (_gv_j_1 = 0; _gv_j_1 < aes_const_Nk; _gv_j_1 = _gv_j_1 + 1) begin : genblk1
				localparam j = _gv_j_1;
				if ((j % aes_const_Nk) == 0) begin : genblk1
					wire [32:1] sv2v_tmp_E3922;
					assign sv2v_tmp_E3922 = (KExp_N[(((11 - i) * 4) + (3 - j)) * 32+:32] ^ SubWord(RotWord(KExp_P[((11 - i) * 4) * 32+:32]))) ^ {RCon[(15 - i) * 8+:8], 24'h000000};
					always @(*) KExp_P[(((10 - i) * 4) + (3 - j)) * 32+:32] = sv2v_tmp_E3922;
				end
				else begin : genblk1
					wire [32:1] sv2v_tmp_8D87C;
					assign sv2v_tmp_8D87C = KExp_N[(((11 - i) * 4) + (3 - j)) * 32+:32] ^ KExp_P[(((10 - i) * 4) + (4 - j)) * 32+:32];
					always @(*) KExp_P[(((10 - i) * 4) + (3 - j)) * 32+:32] = sv2v_tmp_8D87C;
				end
			end
			always @(*) begin
				if (_sv2v_0)
					;
				KExp_R[32 * (43 - ((aes_const_Nk * i) >= (Min(aes_const_Nk * (i + 1), 44) - 1) ? aes_const_Nk * i : ((aes_const_Nk * i) + ((aes_const_Nk * i) >= (Min(aes_const_Nk * (i + 1), 44) - 1) ? ((aes_const_Nk * i) - (Min(aes_const_Nk * (i + 1), 44) - 1)) + 1 : ((Min(aes_const_Nk * (i + 1), 44) - 1) - (aes_const_Nk * i)) + 1)) - 1))+:32 * ((aes_const_Nk * i) >= (Min(aes_const_Nk * (i + 1), 44) - 1) ? ((aes_const_Nk * i) - (Min(aes_const_Nk * (i + 1), 44) - 1)) + 1 : ((Min(aes_const_Nk * (i + 1), 44) - 1) - (aes_const_Nk * i)) + 1)] = KExp_P[32 * ((((((10 - i) * 4) + (4 - (Min(aes_const_Nk * (i + 1), 44) - (aes_const_Nk * i)))) + (Min(aes_const_Nk * (i + 1), 44) - (aes_const_Nk * i))) - 1) - ((Min(aes_const_Nk * (i + 1), 44) - (aes_const_Nk * i)) - 1))+:32 * (Min(aes_const_Nk * (i + 1), 44) - (aes_const_Nk * i))];
				Ready_P[i] = Ready_N[i - 1];
			end
			always @(posedge clk) begin
				KExp_N[32 * ((10 - i) * 4)+:128] <= KExp_P[32 * ((10 - i) * 4)+:128];
				Ready_N[i] <= Ready_P[i];
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		KExp = KExp_R;
		Ready_out = Ready_N[10];
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
	localparam aes_const_Nk = 4;
	input wire [127:0] Key;
	input wire [127:0] RCon;
	input wire [2047:0] SBox;
	input wire [0:0] Enable;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 10;
	output reg [1407:0] KExp;
	output reg [0:0] Ready_out;
	reg [1407:0] KExp_R;
	reg [127:0] KExp_P;
	reg [127:0] KExp_N;
	localparam LENGTH = 44;
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
							KExp_P[(3 - i) * 32+:32] = {Key[(15 - (4 * i)) * 8+:8], Key[(15 - ((4 * i) + 1)) * 8+:8], Key[(15 - ((4 * i) + 2)) * 8+:8], Key[(15 - ((4 * i) + 3)) * 8+:8]};
					end
				end
			end
			default: begin
				begin : sv2v_autoblock_2
					reg signed [31:0] i;
					for (i = 0; i < aes_const_Nk; i = i + 1)
						if (i == 0)
							KExp_P[(3 - i) * 32+:32] = (KExp_N[(3 - i) * 32+:32] ^ SubWord(RotWord(KExp_N[0+:32]))) ^ {RCon[(15 - v[11-:4]) * 8+:8], 24'h000000};
						else
							KExp_P[(3 - i) * 32+:32] = KExp_N[(3 - i) * 32+:32] ^ KExp_P[(4 - i) * 32+:32];
				end
				if (v[7-:6] > 40) begin
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
				if (((v[7-:6] + i[5:0]) < 44) && (v[1] == 1))
					KExp_R[(43 - (v[7-:6] + i[5:0])) * 32+:32] = KExp_P[(3 - i) * 32+:32];
		end
		v[7-:6] = v[7-:6] + aes_const_Nk;
		rin = v;
		KExp = KExp_R;
		Ready_out = r[0];
	end
	always @(posedge clk) KExp_N <= KExp_P;
	always @(posedge clk)
		if (rst == 0)
			r <= init_reg;
		else
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
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [3:0] Index;
	output wire [127:0] State_out;
	genvar _gv_i_5;
	genvar _gv_j_2;
	generate
		for (_gv_j_2 = 0; _gv_j_2 < aes_const_Nb; _gv_j_2 = _gv_j_2 + 1) begin : genblk1
			localparam j = _gv_j_2;
			for (_gv_i_5 = 0; _gv_i_5 < 4; _gv_i_5 = _gv_i_5 + 1) begin : genblk1
				localparam i = _gv_i_5;
				assign State_out[(15 - ((4 * j) + i)) * 8+:8] = KExp[((43 - ((Index * aes_const_Nb) + j)) * 32) + ((((4 - i) * 8) - 1) >= ((3 - i) * 8) ? ((4 - i) * 8) - 1 : ((((4 - i) * 8) - 1) + ((((4 - i) * 8) - 1) >= ((3 - i) * 8) ? ((((4 - i) * 8) - 1) - ((3 - i) * 8)) + 1 : (((3 - i) * 8) - (((4 - i) * 8) - 1)) + 1)) - 1)-:((((4 - i) * 8) - 1) >= ((3 - i) * 8) ? ((((4 - i) * 8) - 1) - ((3 - i) * 8)) + 1 : (((3 - i) * 8) - (((4 - i) * 8) - 1)) + 1)] ^ State_in[(15 - ((4 * j) + i)) * 8+:8];
			end
		end
	endgenerate
endmodule
module aes_sbyte (
	State_in,
	SBox,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [2047:0] SBox;
	output wire [127:0] State_out;
	genvar _gv_i_6;
	genvar _gv_j_3;
	generate
		for (_gv_i_6 = 0; _gv_i_6 < 4; _gv_i_6 = _gv_i_6 + 1) begin : genblk1
			localparam i = _gv_i_6;
			for (_gv_j_3 = 0; _gv_j_3 < aes_const_Nb; _gv_j_3 = _gv_j_3 + 1) begin : genblk1
				localparam j = _gv_j_3;
				assign State_out[(15 - ((i * aes_const_Nb) + j)) * 8+:8] = SBox[(255 - State_in[(15 - ((i * aes_const_Nb) + j)) * 8+:8]) * 8+:8];
			end
		end
	endgenerate
endmodule
module aes_isbyte (
	State_in,
	IBox,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [2047:0] IBox;
	output wire [127:0] State_out;
	genvar _gv_i_7;
	genvar _gv_j_4;
	generate
		for (_gv_i_7 = 0; _gv_i_7 < 4; _gv_i_7 = _gv_i_7 + 1) begin : genblk1
			localparam i = _gv_i_7;
			for (_gv_j_4 = 0; _gv_j_4 < aes_const_Nb; _gv_j_4 = _gv_j_4 + 1) begin : genblk1
				localparam j = _gv_j_4;
				assign State_out[(15 - ((i * aes_const_Nb) + j)) * 8+:8] = IBox[(255 - State_in[(15 - ((i * aes_const_Nb) + j)) * 8+:8]) * 8+:8];
			end
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
	genvar _gv_j_5;
	reg [2:0] C [0:2];
	always @(*) begin
		if (_sv2v_0)
			;
		C[0] = 1;
		C[1] = 2;
		C[2] = 3;
	end
	generate
		for (_gv_j_5 = 0; _gv_j_5 < aes_const_Nb; _gv_j_5 = _gv_j_5 + 1) begin : genblk1
			localparam j = _gv_j_5;
			assign State_out[(15 - (4 * j)) * 8+:8] = State_in[(15 - (4 * j)) * 8+:8];
		end
		for (_gv_j_5 = 0; _gv_j_5 < aes_const_Nb; _gv_j_5 = _gv_j_5 + 1) begin : genblk2
			localparam j = _gv_j_5;
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
	genvar _gv_j_6;
	reg [2:0] C [0:2];
	always @(*) begin
		if (_sv2v_0)
			;
		C[0] = 1;
		C[1] = 2;
		C[2] = 3;
	end
	generate
		for (_gv_j_6 = 0; _gv_j_6 < aes_const_Nb; _gv_j_6 = _gv_j_6 + 1) begin : genblk1
			localparam j = _gv_j_6;
			assign State_out[(15 - (4 * j)) * 8+:8] = State_in[(15 - (4 * j)) * 8+:8];
		end
		for (_gv_j_6 = 0; _gv_j_6 < aes_const_Nb; _gv_j_6 = _gv_j_6 + 1) begin : genblk2
			localparam j = _gv_j_6;
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
	EXP3,
	LN3,
	State_out
);
	reg _sv2v_0;
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	output reg [127:0] State_out;
	function [7:0] gmul;
		input [7:0] data_a;
		input [7:0] data_b;
		reg [8:0] swap;
		if ((data_a == 0) || (data_b == 0))
			gmul = 0;
		else begin
			swap = LN3[(255 - data_a) * 8+:8] + LN3[(255 - data_b) * 8+:8];
			swap = swap % 9'h0ff;
			gmul = EXP3[(255 - swap[7:0]) * 8+:8];
		end
	endfunction
	always @(State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or _sv2v_0) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < aes_const_Nb; i = i + 1)
				begin
					State_out[(15 - (4 * i)) * 8+:8] = ((gmul(8'h02, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h03, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h01, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h01, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 1)) * 8+:8] = ((gmul(8'h01, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h02, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h03, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h01, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 2)) * 8+:8] = ((gmul(8'h01, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h01, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h02, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h03, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 3)) * 8+:8] = ((gmul(8'h03, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h01, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h01, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h02, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module aes_imcol (
	State_in,
	EXP3,
	LN3,
	State_out
);
	reg _sv2v_0;
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	output reg [127:0] State_out;
	function [7:0] gmul;
		input [7:0] data_a;
		input [7:0] data_b;
		reg [8:0] swap;
		if ((data_a == 0) || (data_b == 0))
			gmul = 0;
		else begin
			swap = LN3[(255 - data_a) * 8+:8] + LN3[(255 - data_b) * 8+:8];
			swap = swap % 9'h0ff;
			gmul = EXP3[(255 - swap[7:0]) * 8+:8];
		end
	endfunction
	always @(State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or State_in or EXP3 or LN3 or LN3 or _sv2v_0) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < aes_const_Nb; i = i + 1)
				begin
					State_out[(15 - (4 * i)) * 8+:8] = ((gmul(8'h0e, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h0b, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h0d, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h09, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 1)) * 8+:8] = ((gmul(8'h09, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h0e, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h0b, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h0d, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 2)) * 8+:8] = ((gmul(8'h0d, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h09, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h0e, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h0b, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
					State_out[(15 - ((4 * i) + 3)) * 8+:8] = ((gmul(8'h0b, State_in[(15 - (4 * i)) * 8+:8]) ^ gmul(8'h0d, State_in[(15 - ((4 * i) + 1)) * 8+:8])) ^ gmul(8'h09, State_in[(15 - ((4 * i) + 2)) * 8+:8])) ^ gmul(8'h0e, State_in[(15 - ((4 * i) + 3)) * 8+:8]);
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module aes_round (
	State_in,
	Index,
	KExp,
	SBox,
	EXP3,
	LN3,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [2047:0] SBox;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	output wire [127:0] State_out;
	wire [127:0] State_B;
	wire [127:0] State_R;
	wire [127:0] State_M;
	aes_sbyte aes_sbyte_comp(
		.State_in(State_in),
		.SBox(SBox),
		.State_out(State_B)
	);
	aes_srow aes_srow_comp(
		.State_in(State_B),
		.State_out(State_R)
	);
	aes_mcol aes_mcol_comp(
		.State_in(State_R),
		.EXP3(EXP3),
		.LN3(LN3),
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
	IBox,
	EXP3,
	LN3,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [2047:0] IBox;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
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
		.IBox(IBox),
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
		.EXP3(EXP3),
		.LN3(LN3),
		.State_out(State_out)
	);
endmodule
module aes_fround (
	State_in,
	Index,
	KExp,
	SBox,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [2047:0] SBox;
	output wire [127:0] State_out;
	wire [127:0] State_B;
	wire [127:0] State_R;
	aes_sbyte aes_sbyte_comp(
		.State_in(State_in),
		.SBox(SBox),
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
	IBox,
	State_out
);
	localparam aes_const_Nb = 4;
	input wire [127:0] State_in;
	input wire [3:0] Index;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [2047:0] IBox;
	output wire [127:0] State_out;
	wire [127:0] State_R;
	wire [127:0] State_B;
	aes_isrow aes_isrow_comp(
		.State_in(State_in),
		.State_out(State_R)
	);
	aes_isbyte aes_isbyte_comp(
		.State_in(State_R),
		.IBox(IBox),
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
	SBox,
	EXP3,
	LN3,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	input wire [2047:0] SBox;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [127:0] Data_in;
	input wire [0:0] Enable;
	output wire [127:0] Data_out;
	output reg [0:0] Ready_out;
	genvar _gv_i_10;
	wire [127:0] State [0:9];
	reg [127:0] State_Reg [0:9];
	reg [0:0] Ready [0:9];
	reg [0:0] Ready_Reg [0:9];
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
	generate
		for (_gv_i_10 = 1; _gv_i_10 < aes_const_Nr; _gv_i_10 = _gv_i_10 + 1) begin : genblk1
			localparam i = _gv_i_10;
			always @(posedge clk) begin
				State_Reg[i - 1] <= State[i - 1];
				Ready_Reg[i - 1] <= Ready[i - 1];
			end
			aes_round aes_round_comp(
				.State_in(State_Reg[i - 1]),
				.Index(i[3:0]),
				.KExp(KExp),
				.SBox(SBox),
				.EXP3(EXP3),
				.LN3(LN3),
				.State_out(State[i])
			);
			always @(*) begin
				if (_sv2v_0)
					;
				Ready[i] = Ready_Reg[i - 1];
			end
		end
	endgenerate
	always @(posedge clk) begin
		State_Reg[9] <= State[9];
		Ready_Reg[9] <= Ready[9];
	end
	aes_fround aes_fround_comp(
		.State_in(State_Reg[9]),
		.Index(aes_const_Nr[3:0]),
		.KExp(KExp),
		.SBox(SBox),
		.State_out(Data_out)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready_out = Ready_Reg[9];
	end
	initial _sv2v_0 = 0;
endmodule
module aes_icipher (
	rst,
	clk,
	IBox,
	EXP3,
	LN3,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	input wire [2047:0] IBox;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
	input wire [127:0] Data_in;
	input wire [0:0] Enable;
	output wire [127:0] Data_out;
	output reg [0:0] Ready_out;
	genvar _gv_i_11;
	wire [127:0] State [0:9];
	reg [127:0] State_Reg [0:9];
	reg [0:0] Ready [0:9];
	reg [0:0] Ready_Reg [0:9];
	aes_arkey aes_arkey_comp(
		.State_in(Data_in),
		.KExp(KExp),
		.Index(aes_const_Nr[3:0]),
		.State_out(State[9])
	);
	always @(*) begin
		if (_sv2v_0)
			;
		Ready[9] = Enable;
	end
	generate
		for (_gv_i_11 = 9; _gv_i_11 > 0; _gv_i_11 = _gv_i_11 - 1) begin : genblk1
			localparam i = _gv_i_11;
			always @(posedge clk) begin
				State_Reg[i] <= State[i];
				Ready_Reg[i] <= Ready[i];
			end
			aes_iround aes_iround_comp(
				.State_in(State_Reg[i]),
				.Index(i[3:0]),
				.KExp(KExp),
				.IBox(IBox),
				.EXP3(EXP3),
				.LN3(LN3),
				.State_out(State[i - 1])
			);
			always @(*) begin
				if (_sv2v_0)
					;
				Ready[i - 1] = Ready_Reg[i];
			end
		end
	endgenerate
	always @(posedge clk) begin
		State_Reg[0] <= State[0];
		Ready_Reg[0] <= Ready[0];
	end
	aes_ifround aes_ifround_comp(
		.State_in(State_Reg[0]),
		.Index(4'h0),
		.KExp(KExp),
		.IBox(IBox),
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
	SBox,
	EXP3,
	LN3,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	input wire [2047:0] SBox;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
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
	always @(posedge clk) State_N <= State_P;
	aes_sbyte aes_sbyte_comp(
		.State_in(State_B_in),
		.SBox(SBox),
		.State_out(State_B_out)
	);
	aes_srow aes_srow_comp(
		.State_in(State_R_in),
		.State_out(State_R_out)
	);
	aes_mcol aes_mcol_comp(
		.State_in(State_M_in),
		.EXP3(EXP3),
		.LN3(LN3),
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
		else
			r <= rin;
	initial _sv2v_0 = 0;
endmodule
module aes_icipher_state (
	rst,
	clk,
	IBox,
	EXP3,
	LN3,
	KExp,
	Data_in,
	Enable,
	Data_out,
	Ready_out
);
	reg _sv2v_0;
	input wire rst;
	input wire clk;
	input wire [2047:0] IBox;
	input wire [2047:0] EXP3;
	input wire [2047:0] LN3;
	localparam aes_const_Nb = 4;
	localparam aes_const_Nr = 10;
	input wire [1407:0] KExp;
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
					v[4-:4] = 9;
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
	always @(posedge clk) State_N <= State_P;
	aes_isrow aes_isrow_comp(
		.State_in(State_R_in),
		.State_out(State_R_out)
	);
	aes_isbyte aes_isbyte_comp(
		.State_in(State_B_in),
		.IBox(IBox),
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
		.EXP3(EXP3),
		.LN3(LN3),
		.State_out(State_M_out)
	);
	always @(posedge clk)
		if (rst == 0)
			r <= init_reg;
		else
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
	localparam aes_const_Nk = 4;
	input wire [258:0] aes_in;
	output reg [128:0] aes_out;
	localparam aes_const_Nr = 10;
	wire [1407:0] kexp;
	wire [2047:0] sbox;
	wire [2047:0] ibox;
	wire [2047:0] exp3;
	wire [2047:0] ln3;
	wire [127:0] rcon;
	wire [127:0] key_array;
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
		.EXP3(exp3),
		.LN3(ln3),
		.RCon(rcon)
	);
	aes_xkey aes_xkey_comp(
		.key_in(aes_in[258-:128]),
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
		.SBox(sbox),
		.EXP3(exp3),
		.LN3(ln3),
		.KExp(kexp),
		.Data_in(data_array),
		.Enable(cipher_enable),
		.Data_out(cipher_array),
		.Ready_out(cipher_ready)
	);
	aes_icipher_state aes_icipher_state_comp(
		.rst(rst),
		.clk(clk),
		.IBox(ibox),
		.EXP3(exp3),
		.LN3(ln3),
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
