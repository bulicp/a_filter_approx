/*
  rad4_odd       -> Exact rad-4 multiplier 
                 -> Because the coefficients are close to -1
                 -> the  last two radix-4 groups change
                 -> plus the MS radix-4 group 

            Y10  Y10  Y9    Y3  Y2  Y1    Y1  Y0  0
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
                            P(31:0)

    BE -> Booth encode2r

*/
module rad4_exact(
    input [31:0] x,
    input [10:0] y,
    output [31:0] p
    );

    wire [2:0] sign_factor;
    wire [32:0] PP_2;
    wire [32:0] PP_1;
    wire [32:0] PP_0;
    wire [2:0] tmp1;
    wire [2:0] tmp0;

    assign tmp1 = {y[10],y[10:9]}; 
    assign tmp0 = {y[1:0],1'b0};

// Calculates PP_2 
    rad4_BE2 PP2_gen(
        .x1(tmp1),
        .y(x),
        .sign_factor(sign_factor[2]),
        .PP(PP_2)
        );
// Calculates PP_1
    rad4_BE2 PP1_gen(
        .x1(y[3:1]),
        .y(x),
        .sign_factor(sign_factor[1]),
        .PP(PP_1)
        );

// Calculates PP_1
    rad4_BE2 PP0_gen(
        .x1(tmp0),
        .y(x),
        .sign_factor(sign_factor[0]),
        .PP(PP_0)
        );

// Partial product2 addition 

    PP_add2 Final(
        .sign_factor(sign_factor),
        .PP_2(PP_2),
        .PP_1(PP_1),
        .PP_0(PP_0),
        .p(p)
        );
        
endmodule



module rad4_BE2(
    input [2:0] x1,
    input [31:0] y,
    output sign_factor,
    output [32:0] PP
    );
    
    // encode2 
    wire one, two, sign;
    
    code2 encode2_block(
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
            product2 pp_pr(tmp1_pp[i],out1[i],one,two,sign,PP[i],out1[i+1]);
            end
    endgenerate
    
    //sign factor generate
    assign sign_factor = sign;

endmodule

module code2(one,two,sign,y2,y1,y0);  
	input y2,y1,y0;                     
	output one,two,sign;                
	wire [1:0]k;                        
	xor x1(one,y0,y1);                  
	xor x2(k[1],y2,y1);                 
	not n1(k[0],one);                   
	and a1(two,k[0],k[1]);              
	assign sign=y2;                     
endmodule   

module product2(x1,x0,one,two,sign,p,i);
	input x1,x0,sign,one,two;
	output p,i;
	wire [1:0] k;
	xor xo1(i,x1,sign);
	and a1(k[1],i,one);
	and a0(k[0],x0,two);
	or o1(p,k[1],k[0]);
endmodule

module sgn_gen2(one,two,sign,sign_factor);
    input sign,one,two;
    output sign_factor;
    wire k;
    or o1(k,one,two);
    and a1(sign_factor,sign,k);
endmodule

module PP_add2(
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
    assign tmp003_FA = {PP_2[26:0],{7{sign_factor[2]}},sign_factor[2],{2{sign_factor[2]}}};

    genvar i001;
    generate
        for (i001 = 0; i001 < 37; i001 = i001 + 1)
            begin : pp_FAd200
            FAd2 pp_FAd2(tmp001_FA[i001],tmp002_FA[i001], tmp003_FA[i001], carry00_FA[i001],sum00_FA[i001]);
            end
    endgenerate


    wire [4:0] sum00_HA;
    wire [4:0] carry00_HA;

    wire [4:0] tmp001_HA;
    wire [4:0] tmp002_HA;

    assign tmp001_HA = {5{1'b1}};
    assign tmp002_HA = {PP_2[31:27]};


    genvar i002;
    generate
        for (i002 = 0; i002 < 5; i002 = i002 + 1)
            begin : pp_HAd200
            HAd2 pp_HAd2(tmp001_HA[i002],tmp002_HA[i002],carry00_HA[i002],sum00_HA[i002]);
            end
    endgenerate
   
    wire [41:0] tmp_sum;
    wire [41:0] tmp_add1;
    wire [41:0] tmp_add2;

    assign tmp_add1 = {sum00_HA[5:0],sum00_FA};
    assign tmp_add2 = {carry00_HA[4:0],carry00_FA,sign_factor[2]}; 

    assign tmp_sum = tmp_add1 + tmp_add2;

    assign p = tmp_sum[41:10];

endmodule


module FAd2(a,b,c,cy,sm);
	input a,b,c;
	output cy,sm;
	wire x,y,z;
	xor x1(x,a,b);
	xor x2(sm,x,c);
	and a1(y,a,b);
	and a2(z,x,c);
	or o1(cy,y,z);
endmodule 

module HAd2(a,b,cy,sm);
	input a,b;
	output cy,sm;
	xor x1(sm,a,b);
	and a1(cy,a,b);
endmodule 