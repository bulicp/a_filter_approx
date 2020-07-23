## Little help

Top module: a_filter_approx

a_filter_approx.v
	fos_exact_v4.v //Fos sekcija 
		rad4_odd // Aproksimativni množač
	fos_exact_v3.v
		rad4_odd_trunc1 // Aproksimativni množač 
	fos_exact_v2.v
		rad4_exact // Egzaktni rad4 množač sa 3 parcijalna produkta
	fos_exact_v2.v
		rad4_exact // Egzaktni rad4 množač sa 3 parcijalna produkta
	fos_exact_v1.v
		rad4_odd_trunc // Aproksimativni množač 
	fos_exact_v1.v
		rad4_odd_trunc // Aproksimativni množač
	

### Filter types: 
- Type 1: rad4_odd_trunc.v 
  - Zeros: -1 and Pole: -0.2031(-208)
- Type 2: rad4_exact.v 
  - Zeros: -1 and Pole: -0.9971(-1021)
- Type 3: rad4_odd_trunc.v 
  - Zeros: 0.2998 (307) Pole: -0.9082 (-930)
- Type 4: rad4_odd.v
  - Zeros: 0 Pole: -0.9863 (-1010)
  - 
