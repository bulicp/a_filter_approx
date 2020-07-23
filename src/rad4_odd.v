/*
  rad4_odd       -> Approximate odd rad-4 multiplier 
                 -> Because the coefficients are close to -1
                 -> the  last two radix-4 groups change
                 -> plus the MS radix-4 group 

            Y10  Y9  Y8    Y4  Y3  Y2   Y2  Y1  Y0
                 |             |            |
            -----------    ----------    ----------
         X->| rad-4 BE| X->| rad-4 BE|   | rad-4 BE| <- X(31:0)
            -----------    -----------   -----------
                 |             |             |
                PP2(32:0)     PP1(32:0)     PP0(32:0)
                 |             |             |
                ---------------------------------
                -          Wallace tree         -
                ---------------------------------
                               |
                              <<1
                               |
                            P(31:0)

    BE -> Booth encoder


*/
module rad4_odd(
    input [31:0] x,
    input [10:0] y,
    output [31:0] p
    );

    wire [2:0] sign_factor;
    wire [32:0] PP_2;
    wire [32:0] PP_1;
    wire [32:0] PP_0;
    wire [2:0] tmp;

    assign tmp = {y[6:5],1'b0};

// Calculates PP_2 
    rad4_BE PP2_gen(
        .x1(y[10:8]),
        .y(x),
        .sign_factor(sign_factor[2]),
        .PP(PP_2)
        );
// Calculates PP_1
    rad4_BE PP1_gen(
        .x1(y[4:2]),
        .y(x),
        .sign_factor(sign_factor[1]),
        .PP(PP_1)
        );

// Calculates PP_1
    rad4_BE PP0_gen(
        .x1(y[2:0]),
        .y(x),
        .sign_factor(sign_factor[0]),
        .PP(PP_0)
        );

// Partial product addition 

    PP_add Final(
        .sign_factor(sign_factor),
        .PP_2(PP_2),
        .PP_1(PP_1),
        .PP_0(PP_0),
        .p(p)
        );
        
endmodule



module rad4_BE(
    input [2:0] x1,
    input [31:0] y,
    output sign_factor,
    output [32:0] PP
    );
    
    // encode 
    wire one, two, sign;
    
    code encode_block(
        .one(one),
        .two(two),
        .sign(sign),
        .y2(x1[2]),
        .y1(x1[1]),
        .y0(x1[0])
        );
        
    // generation of PP
    wire [32:0] tmp1_pp; 
    assign tmp1_pp = {y[31],y}; // This variable is introduced because pp has 33 bits
    
    wire [33:0] out1;
    assign out1[0] = sign;
    
    genvar i;
    generate
        for ( i = 0; i < 33; i = i+1 )
            begin : pp_rad4_first 
            product pp_pr(tmp1_pp[i],out1[i],one,two,sign,PP[i],out1[i+1]);
            end
    endgenerate
    
    //sign factor generate
    sgn_gen sign_gen(one,two,sign,sign_factor);


endmodule

module code(one,two,sign,y2,y1,y0);  
	input y2,y1,y0;                     
	output one,two,sign;                
	wire [1:0]k;                        
	xor x1(one,y0,y1);                  
	xor x2(k[1],y2,y1);                 
	not n1(k[0],one);                   
	and a1(two,k[0],k[1]);              
	assign sign=y2;                     
endmodule   

module product(x1,x0,one,two,sign,p,i);
	input x1,x0,sign,one,two;
	output p,i;
	wire [1:0] k;
	xor xo1(i,x1,sign);
	and a1(k[1],i,one);
	and a0(k[0],x0,two);
	or o1(p,k[1],k[0]);
endmodule

module sgn_gen(one,two,sign,sign_factor);
    input sign,one,two;
    output sign_factor;
    wire k;
    or o1(k,one,two);
    and a1(sign_factor,sign,k);
endmodule


module PP_add(
    input [2:0] sign_factor,
    input [32:0] PP_2,
    input [32:0] PP_1,
    input [32:0] PP_0,
    output [31:0] p
    );
    
    
    // generate negative MSBs
    wire [2:0] E_MSB;
    assign E_MSB[0] = ~ PP_0[32];
    assign E_MSB[1] = ~ PP_1[32];
    assign E_MSB[2] = ~ PP_2[32];

        // First  reduction
    wire [36:0] sum00_FA;
    wire [36:0] carry00_FA;
  

    wire [36:0] tmp001_FA;
    wire [36:0] tmp002_FA;
    wire [36:0] tmp003_FA;

    assign tmp001_FA = {E_MSB[0],{3{PP_0[32]}},PP_0};
    assign tmp002_FA = {E_MSB[1],PP_1[32],PP_1,sign_factor[2],sign_factor[0]};
    assign tmp003_FA = {PP_2[28:0],{5{sign_factor[2]}},sign_factor[2],{2{sign_factor[2]}}};

    genvar i001;
    generate
        for (i001 = 0; i001 < 37; i001 = i001 + 1)
            begin : pp_fad00
            FAd pp_fad(tmp001_FA[i001],tmp002_FA[i001], tmp003_FA[i001], carry00_FA[i001],sum00_FA[i001]);
            end
    endgenerate

    wire [4:0] sum00_HA;
    wire [4:0] carry00_HA;

    wire [4:0] tmp001_HA;
    wire [4:0] tmp002_HA;

    assign tmp001_HA = {5{1'b1}};
    assign tmp002_HA = {PP_2[32],PP_2[32:29]};


    genvar i002;
    generate
        for (i002 = 0; i002 < 5; i002 = i002 + 1)
            begin : pp_had00
            HAd pp_had(tmp001_HA[i002],tmp002_HA[i002],carry00_HA[i002],sum00_HA[i002]);
            end
    endgenerate

    wire [41:0] tmp_sum;
    wire [41:0] tmp_add1;
    wire [41:0] tmp_add2;

    assign tmp_add1 = {sum00_HA[4:0],sum00_FA,1'b0}; // shift one place
    assign tmp_add2 = {carry00_HA[3:0],carry00_FA,1'b0,1'b0}; // shift one place

    assign tmp_sum = tmp_add1 + tmp_add2;

    assign p = tmp_sum[41:10];


endmodule


module FAd(a,b,c,cy,sm);
	input a,b,c;
	output cy,sm;
	wire x,y,z;
	xor x1(x,a,b);
	xor x2(sm,x,c);
	and a1(y,a,b);
	and a2(z,x,c);
	or o1(cy,y,z);
endmodule 

module HAd(a,b,cy,sm);
	input a,b;
	output cy,sm;
	xor x1(sm,a,b);
	and a1(cy,a,b);
endmodule 