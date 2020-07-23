
/*
  rad4_odd_trunc -> Approximate odd rad-4 multiplier with  the truncation of multiplicand's (Y) bits
                 -> truncated last 5 bites (N=32)

            Y10  Y9  Y8   Y8  Y7  Y6    Y6  Y5  0
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

    BE -> Booth encode5r

*/
module rad4_odd_trunc(
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
    rad4_BE5 PP2_gen(
        .x1(y[10:8]),
        .y(x),
        .sign_factor(sign_factor[2]),
        .PP(PP_2)
        );
// Calculates PP_1
    rad4_BE5 PP1_gen(
        .x1(y[8:6]),
        .y(x),
        .sign_factor(sign_factor[1]),
        .PP(PP_1)
        );

// Calculates PP_1
    rad4_BE5 PP0_gen(
        .x1(tmp),
        .y(x),
        .sign_factor(sign_factor[0]),
        .PP(PP_0)
        );

// Partial product5 addition 

    PP_add5 Final(
        .sign_factor(sign_factor),
        .PP_2(PP_2),
        .PP_1(PP_1),
        .PP_0(PP_0),
        .p(p)
        );
        
endmodule



module rad4_BE5(
    input [2:0] x1,
    input [31:0] y,
    output sign_factor,
    output [32:0] PP
    );
    
    // encode5 
    wire one, two, sign;
    
    code5 encode5_block(
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
            product5 pp_pr(tmp1_pp[i],out1[i],one,two,sign,PP[i],out1[i+1]);
            end
    endgenerate
    
    //sign factor generate
    sgn_gen5 sign_gen(one,two,sign,sign_factor);


endmodule

module code5(one,two,sign,y2,y1,y0);  
	input y2,y1,y0;                     
	output one,two,sign;                
	wire [1:0]k;                        
	xor x1(one,y0,y1);                  
	xor x2(k[1],y2,y1);                 
	not n1(k[0],one);                   
	and a1(two,k[0],k[1]);              
	assign sign=y2;                     
endmodule   

module product5(x1,x0,one,two,sign,p,i);
	input x1,x0,sign,one,two;
	output p,i;
	wire [1:0] k;
	xor xo1(i,x1,sign);
	and a1(k[1],i,one);
	and a0(k[0],x0,two);
	or o1(p,k[1],k[0]);
endmodule

module sgn_gen5(one,two,sign,sign_factor);
    input sign,one,two;
    output sign_factor;
    wire k;
    or o1(k,one,two);
    and a1(sign_factor,sign,k);
endmodule

module PP_add5(
    input [2:0] sign_factor,
    input [32:0] PP_2,
    input [32:0] PP_1,
    input [32:0] PP_0,
    output [31:0] p
    );
    
    
    // First  reduction
    wire [34:0] sum00_FA;
    wire [34:0] carry00_FA;
  

    wire [34:0] tmp001_FA;
    wire [34:0] tmp002_FA;
    wire [34:0] tmp003_FA;

    assign tmp001_FA = {{5{PP_0[32]}},PP_0[32:4],PP_0[2]};
    assign tmp002_FA = {{3{PP_1[32]}},PP_1[32:2],PP_1[0]};
    assign tmp003_FA = {PP_2[32],PP_2,sign_factor[1]};

    genvar i001;
    generate
        for (i001 = 0; i001 < 35; i001 = i001 + 1)
            begin : pp_FAd500
            FAd5 pp_FAd5(tmp001_FA[i001],tmp002_FA[i001], tmp003_FA[i001], carry00_FA[i001],sum00_FA[i001]);
            end
    endgenerate

    wire sum00_HA;
    wire carry00_HA;

    HAd5 pp_HAd500(PP_0[3],PP_1[1],carry00_HA,sum00_HA);

    // Second generation
    wire sum10_FA;
    wire carry10_FA;


    FAd5 pp_FAd510(sum00_FA[1],carry00_HA,sign_factor[2],carry10_FA,sum10_FA);

    wire [32:0] sum10_HA;
    wire [32:0] carry10_HA;
    
    wire [32:0] tmp011_HA;
    wire [32:0] tmp012_HA;

    assign tmp011_HA = {sum00_FA[34:2]};
    assign tmp012_HA = {carry00_FA[33:1]};

    genvar i002;
    generate
        for (i002 = 0; i002 < 33; i002 = i002 + 1)
            begin : pp_HAd510
            HAd5 pp_FAd5(tmp011_HA[i002],tmp012_HA[i002], carry10_HA[i002],sum10_HA[i002]);
            end
    endgenerate


    wire [42:0] tmp_sum;
    wire [42:0] tmp_add1;
    wire [42:0] tmp_add2;

    assign tmp_add1 = {sum10_HA,sum10_FA,sum00_HA,sum00_FA[0],PP_0[1:0],5'b0};
    assign tmp_add2 = {carry10_HA[31:0],carry10_FA,1'b0,carry00_FA[0],2'b0,sign_factor[0],5'b0}; 

    assign tmp_sum = tmp_add1 + tmp_add2;
    assign p = {tmp_sum[41:10]};


endmodule


module FAd5(a,b,c,cy,sm);
	input a,b,c;
	output cy,sm;
	wire x,y,z;
	xor x1(x,a,b);
	xor x2(sm,x,c);
	and a1(y,a,b);
	and a2(z,x,c);
	or o1(cy,y,z);
endmodule 

module HAd5(a,b,cy,sm);
	input a,b;
	output cy,sm;
	xor x1(sm,a,b);
	and a1(cy,a,b);
endmodule 