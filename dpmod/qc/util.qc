
/*
LordHavoc's float coder notes
SEEE EEEE EMMM MMMM MMMM MMMM MMMM MMMM
bits[8], bits[23]
float code1; // to be encoded as exponent, 0-250 (stored at +1)
float code2; // to be encoded as mantissa, 0-8388607 (stored at +8388608)
*/

float lhfp_code0; // sign part, TRUE/FALSE allowed
float lhfp_code1; // exponent part, 0-252 range allowed
float lhfp_code2; // mantissa part, 0-8388607 range allowed

float(float n) lhfp_code1toscale =
{
	local float f;
	local float r;
	r = (1 / 65536);
	f = 1;
	n = n - 126;
	// most of these cases are just optimizations to process faster
	while (n <= -16)
	{
		n = n + 16;
		f = f * r;
	}
	while (n < 0)
	{
		n = n + 1;
		f = f * 0.5;
	}
	while (n >= 16)
	{
		n = n - 16;
		f = f * 65536;
	}
	while (n > 0)
	{
		n = n - 1;
		f = f * 2;
	}
	return f;
};

float(float f) lhfp_scaletocode1 =
{
	local float n;
	local float r;
	r = (1 / 65536);
	n = 126;
	// most of these cases are just optimizations to process faster
	// the < n and > checks are to prevent runaway loops
	while (f >= 65536 && n <= 254)
	{
		n = n + 16;
		f = f * r;
	}
	while (f >= 2 && n <= 254)
	{
		n = n + 1;
		f = f * 0.5;
	}
	while (f < r && n >= 0)
	{
		n = n - 16;
		f = f * 65536;
	}
	while (f < 1 && n >= 0)
	{
		n = n - 1;
		f = f * 2;
	}
	return n;
};

float(float code0, float code1, float code2) lhfp_encode =
{
	local float code;
	if (code1 != floor(code1) || code1 < 0 || code1 >= 254)
		error("lhfp_encode: invalid code1, must be an integer in the range 0-253.\n");
	if (code2 != floor(code2) || code2 < 0 || code2 >= 8388608)
		error("lhfp_encode: invalid code2, must be an integer in the range 0-8388607.\n");
	code = (1 + (code2 / 8388608)) * lhfp_code1toscale(code1);
	if (code0)
		code = 0 - code;
	return code;
};

float(float code) lhfp_decode =
{
	// code == 0 never occurs on a valid encoded value, we'll just assume it's garbage here.
	if (code == 0)
	{
		// invalid code
		lhfp_code0 = FALSE;
		lhfp_code1 = 0;
		lhfp_code2 = 0;
		return FALSE;
	}
	if (code < 0)
	{
		code = 0 - code;
		lhfp_code0 = TRUE;
	}
	else
		lhfp_code0 = FALSE;
	lhfp_code1 = lhfp_scaletocode1(code);
	if (lhfp_code1 < 0 || lhfp_code1 >= 254)
	{
		// invalid exponent
		lhfp_code0 = FALSE;
		lhfp_code1 = 0;
		lhfp_code2 = 0;
		return FALSE;
	}
	lhfp_code2 = ((code / lhfp_code1toscale(lhfp_code1)) - 1) * 8388608;
	return TRUE;
};

void() lhfp_test =
{
	local float c, f0, f1, f2, n, n2, r0, r1, r2, spew;
	local string t;
	if (!cvar("developer"))
		bprint("lhfp_test called without developer on, the dprints won't be seen.\n");
	c = 0;
	r0 = 0;
	r1 = 0;
	r2 = 0;
	spew = 0;
	while (c < 100)
	{
		if (r0 == 0)
			f0 = FALSE;
		else if (r0 == 1)
			f0 = TRUE;
		else
		{
			f0 = FALSE;
			if (random() > 0.5)
				f0 = TRUE;
		}
		if (r1 == 0)
			f1 = 0;
		else if (r1 == 1)
			f1 = 253;
		else
		{
			f1 = random() * 254;
			f1 = floor(f1);
			// random() has a 1 in 32768 chance of returning 1.0, handle this case
			if (f1 > 253)
				f1 = 253;
		}
		f1 = bound(0, f1, 253);
		if (r2 == 0)
			f2 = 0;
		else if (r2 == 1)
			f2 = 8388607;
		else
		{
			f2 = random() * 32767;
			f2 = f2 + random() * 8388607;
			f2 = f2 & 8388607;
		}
		n = lhfp_encode(f0, f1, f2);
		lhfp_decode(n);
		t = ftos(n);
		cvar_set("temp1", t);
		n2 = cvar("temp1");
		cvar_set("temp1", "0");
		if (spew || (n2 != n && f1 >= 139))
		{
			dprint("lhfp_test: code combination ");dprint(ftos(f0));
			dprint(" ");dprint(ftos(f1));
			dprint(" ");dprint(ftos(f2));
			dprint(" encodes to ");dprint(ftos(n));
			if (n2 != n)
			{
				dprint(" which converts back INCORRECTLY to ");dprint(ftos(n2));
			}
			dprint("\n");
		}
		if (lhfp_code0 != f0 || lhfp_code1 != f1 || lhfp_code2 != f2)
		{
			dprint("lhfp_test: code combination ");dprint(ftos(f0));
			dprint(" ");dprint(ftos(f1));
			dprint(" ");dprint(ftos(f2));
			dprint(" failed! (came back as ");dprint(ftos(lhfp_code0));
			dprint(" ");dprint(ftos(lhfp_code1));
			dprint(" ");dprint(ftos(lhfp_code2));
			dprint(")\n");
		}
		r0 = r0 + 1;
		if (r0 >= 3)
		{
			r0 = 0;
			r1 = r1 + 1;
			if (r1 >= 3)
			{
				r1 = 0;
				r2 = r2 + 1;
				if (r2 >= 3)
				{
					r2 = 0;
					c = c + 1;
				}
			}
		}
	}
};

float lhbitparms_index;
float lhbitparms_endindex;
vector lhbitparms_code, lhbitparms_scale;

// this allows storage of up to 480 bits in 16 parms,
// 720 bits with 16 parms + 8 cvars, more if you have more cvars
vector(float index) lhbitparms_codesize =
{
	return '2 64 8388608';
};

void(float index, vector v) lhbitparms_storeparm =
{
	local float code;
	v = v + '0 140 0';
	code = lhfp_encode(v_x, v_y, v_z);
	if (index <  1) parm1 = code;
	else if (index <  2) parm2 = code;
	else if (index <  3) parm3 = code;
	else if (index <  4) parm4 = code;
	else if (index <  5) parm5 = code;
	else if (index <  6) parm6 = code;
	else if (index <  7) parm7 = code;
	else if (index <  8) parm8 = code;
	else if (index <  9) parm9 = code;
	else if (index < 10) parm10 = code;
	else if (index < 11) parm11 = code;
	else if (index < 12) parm12 = code;
	else if (index < 13) parm13 = code;
	else if (index < 14) parm14 = code;
	else if (index < 15) parm15 = code;
	else if (index < 16) parm16 = code;
	else if (index < 17) cvar_set("scratch1", ftos(code));
	else if (index < 18) cvar_set("scratch2", ftos(code));
	else if (index < 19) cvar_set("scratch3", ftos(code));
	else if (index < 20) cvar_set("scratch4", ftos(code));
	else if (index < 21) cvar_set("saved1", ftos(code));
	else if (index < 22) cvar_set("saved2", ftos(code));
	else if (index < 23) cvar_set("saved3", ftos(code));
	else if (index < 24) cvar_set("saved4", ftos(code));
};

vector(float index) lhbitparms_loadparm =
{
	local float code;
	local vector v;
	if (index <  1) code = parm1;
	else if (index <  2) code = parm2;
	else if (index <  3) code = parm3;
	else if (index <  4) code = parm4;
	else if (index <  5) code = parm5;
	else if (index <  6) code = parm6;
	else if (index <  7) code = parm7;
	else if (index <  8) code = parm8;
	else if (index <  9) code = parm9;
	else if (index < 10) code = parm10;
	else if (index < 11) code = parm11;
	else if (index < 12) code = parm12;
	else if (index < 13) code = parm13;
	else if (index < 14) code = parm14;
	else if (index < 15) code = parm15;
	else if (index < 16) code = parm16;
	else if (index < 17) code = cvar("scratch1");
	else if (index < 18) code = cvar("scratch2");
	else if (index < 19) code = cvar("scratch3");
	else if (index < 20) code = cvar("scratch4");
	else if (index < 21) code = cvar("saved1");
	else if (index < 22) code = cvar("saved2");
	else if (index < 23) code = cvar("saved3");
	else if (index < 24) code = cvar("saved4");
	lhfp_decode(code);
	v_x = lhfp_code0;
	v_y = lhfp_code1;
	v_z = lhfp_code2;
	v_y = v_y - 140;
	return v;
};

void(float startindex, float endindex) lhbitparms_encode_begin =
{
	lhbitparms_index = startindex;
	lhbitparms_endindex = endindex;
	lhbitparms_code = '0 0 0';
	lhbitparms_scale = lhbitparms_codesize(lhbitparms_index);
};

void() lhbitparms_encode_finish =
{
	lhbitparms_storeparm(lhbitparms_index, lhbitparms_code);
};

void(float startindex, float endindex) lhbitparms_decode_begin =
{
	lhbitparms_index = startindex;
	lhbitparms_endindex = endindex;
	lhbitparms_code = lhbitparms_loadparm(lhbitparms_index);
	lhbitparms_scale = lhbitparms_codesize(lhbitparms_index);
};

// returns how many bits of space are left, when encoding
float(float index, float endindex) lhbitparms_totalspace =
{
	local float total;
	local vector s;
	total = 0;
	while (index < endindex)
	{
		s = lhbitparms_codesize(index);
		while (s_x >= 2)
		{
			total = total + 1;
			s_x = s_x * 0.5;
		}
		while (s_y >= 2)
		{
			total = total + 1;
			s_y = s_y * 0.5;
		}
		while (s_z >= 2)
		{
			total = total + 1;
			s_z = s_z * 0.5;
		}
		index = index + 1;
	}
	return total;
};

float(float index, float endindex) lhbitparms_usedspace =
{
	local float current;
	local vector s;
	current = 0;
	while (index < endindex)
	{
		s = lhbitparms_codesize(index);
		if (index < lhbitparms_index)
		{
			while (s_x >= 2)
			{
				current = current + 1;
				s_x = s_x * 0.5;
			}
			while (s_y >= 2)
			{
				current = current + 1;
				s_y = s_y * 0.5;
			}
			while (s_z >= 2)
			{
				current = current + 1;
				s_z = s_z * 0.5;
			}
		}
		else if (index == lhbitparms_index)
		{
			while (s_x > lhbitparms_scale_x)
			{
				current = current + 1;
				s_x = s_x * 0.5;
			}
			while (s_y > lhbitparms_scale_y)
			{
				current = current + 1;
				s_y = s_y * 0.5;
			}
			while (s_z > lhbitparms_scale_z)
			{
				current = current + 1;
				s_z = s_z * 0.5;
			}
		}
		else
			break;
		index = index + 1;
	}
	return current;
}

float(float startindex, float endindex) lhbitparms_remainingspace =
{
	local float remaining, current, total;
	total = lhbitparms_totalspace(startindex, endindex);
	current = lhbitparms_usedspace(startindex, endindex);
	remaining = total - current;
	return remaining;
}

void(float startindex, float endindex) dprint_lhbitparms_space =
{
	local float remaining, current, total;
	total = lhbitparms_totalspace(startindex, endindex);
	current = lhbitparms_usedspace(startindex, endindex);
	remaining = total - current;
	dprint(ftos(current));
	dprint(" of ");dprint(ftos(total));
	dprint(" bits used, ");dprint(ftos(remaining));
	dprint(" remaining\n");
};

// returns TRUE if the number fit into the buffer, FALSE if it did not
float(float n, float radix) lhbitparms_encodebits =
{
	if (lhbitparms_index >= lhbitparms_endindex)
		return FALSE;
	// make sure radix is a power of 2
	while (radix & (radix - 1))
		radix = radix + 1;
	// write bits (in msb to lsb order)
	radix = radix * 0.5;
	while (radix >= 1)
	{
		if (lhbitparms_scale_x >= 2)
		{
			lhbitparms_scale_x = lhbitparms_scale_x * 0.5;
			if (n >= radix)
			{
				lhbitparms_code_x = lhbitparms_code_x + lhbitparms_scale_x;
				n = n - radix;
			}
			radix = radix * 0.5;
		}
		else if (lhbitparms_scale_y >= 2)
		{
			lhbitparms_scale_y = lhbitparms_scale_y * 0.5;
			if (n >= radix)
			{
				lhbitparms_code_y = lhbitparms_code_y + lhbitparms_scale_y;
				n = n - radix;
			}
			radix = radix * 0.5;
		}
		else if (lhbitparms_scale_z >= 2)
		{
			lhbitparms_scale_z = lhbitparms_scale_z * 0.5;
			if (n >= radix)
			{
				lhbitparms_code_z = lhbitparms_code_z + lhbitparms_scale_z;
				n = n - radix;
			}
			radix = radix * 0.5;
		}
		else
		{
			lhbitparms_storeparm(lhbitparms_index, lhbitparms_code);
			lhbitparms_index = lhbitparms_index + 1;
			if (lhbitparms_index >= lhbitparms_endindex)
				return FALSE;
			lhbitparms_code = '0 0 0';
			lhbitparms_scale = lhbitparms_codesize(lhbitparms_index);
		}
	}
	return TRUE;
};

// reads a number
float(float radix) lhbitparms_decodebits =
{
	local float n;
	if (lhbitparms_index >= lhbitparms_endindex)
		return 0;
	// make sure radix is a power of 2
	while (radix & (radix - 1))
		radix = radix + 1;
	// read bits (in msb to lsb order)
	radix = radix * 0.5;
	n = 0;
	while (radix >= 1)
	{
		if (lhbitparms_scale_x >= 2)
		{
			lhbitparms_scale_x = lhbitparms_scale_x * 0.5;
			if (lhbitparms_code_x >= lhbitparms_scale_x)
			{
				lhbitparms_code_x = lhbitparms_code_x - lhbitparms_scale_x;
				n = n + radix;
			}
			radix = radix * 0.5;
		}
		else if (lhbitparms_scale_y >= 2)
		{
			lhbitparms_scale_y = lhbitparms_scale_y * 0.5;
			if (lhbitparms_code_y >= lhbitparms_scale_y)
			{
				lhbitparms_code_y = lhbitparms_code_y - lhbitparms_scale_y;
				n = n + radix;
			}
			radix = radix * 0.5;
		}
		else if (lhbitparms_scale_z >= 2)
		{
			lhbitparms_scale_z = lhbitparms_scale_z * 0.5;
			if (lhbitparms_code_z >= lhbitparms_scale_z)
			{
				lhbitparms_code_z = lhbitparms_code_z - lhbitparms_scale_z;
				n = n + radix;
			}
			radix = radix * 0.5;
		}
		else
		{
			lhbitparms_index = lhbitparms_index + 1;
			if (lhbitparms_index >= lhbitparms_endindex)
				return 0;
			lhbitparms_code = lhbitparms_loadparm(lhbitparms_index);
			lhbitparms_scale = lhbitparms_codesize(lhbitparms_index);
		}
	}
	return n;
};

void() lhbitparms_test =
{
	local float c, c2, l;
	local float c0c, c0r, c0s;
	local float c1c, c1r, c1s;
	local float c2c, c2r, c2s;
	local float c3c, c3r, c3s;
	local float c4c, c4r, c4s;
	local float c5c, c5r, c5s;
	local float c6c, c6r, c6s;
	local float c7c, c7r, c7s;
	local float c8c, c8r, c8s;
	local float c9c, c9r, c9s;
	local float cac, car, cas;
	local float cbc, cbr, cbs;
	local float ccc, ccr, ccs;
	local float cdc, cdr, cds;
	local float cec, cer, ces;
	local float cfc, cfr, cfs;
	if (!cvar("developer"))
		bprint("lhbitparms_test called without developer on, the dprints won't be seen.\n");
	lhbitparms_encode_begin(0, 16);
	dprint_lhbitparms_space(0, 16);
	c = 2;
	while (lhbitparms_encodebits(c - 1, c))
	{
		c = c + 1;
		dprint_lhbitparms_space(0, 16);
	}
	lhbitparms_encode_finish();
	dprint("successfully stored radix values from 2 to ");dprint(ftos(c));dprint("\n");
	lhbitparms_decode_begin(0, 16);
	c2 = 2;
	while (c2 < c)
	{
		if (lhbitparms_decodebits(c2) != c2 - 1) dprint("decode error\n");
		c2 = c2 + 1;
	}
	l = 0;
	while (l < 100)
	{
		l = l + 1;
		c0r = random() * 100 + 1;c0r = floor(c0r);c0c = random() * c0r;c0c = floor(c0c);if (c0c > c0r - 1) c0c = c0r - 1;
		c1r = random() * 100 + 1;c1r = floor(c1r);c1c = random() * c1r;c1c = floor(c1c);if (c1c > c1r - 1) c1c = c1r - 1;
		c2r = random() * 100 + 1;c2r = floor(c2r);c2c = random() * c2r;c2c = floor(c2c);if (c2c > c2r - 1) c2c = c2r - 1;
		c3r = random() * 100 + 1;c3r = floor(c3r);c3c = random() * c3r;c3c = floor(c3c);if (c3c > c3r - 1) c3c = c3r - 1;
		c4r = random() * 100 + 1;c4r = floor(c4r);c4c = random() * c4r;c4c = floor(c4c);if (c4c > c4r - 1) c4c = c4r - 1;
		c5r = random() * 100 + 1;c5r = floor(c5r);c5c = random() * c5r;c5c = floor(c5c);if (c5c > c5r - 1) c5c = c5r - 1;
		c6r = random() * 100 + 1;c6r = floor(c6r);c6c = random() * c6r;c6c = floor(c6c);if (c6c > c6r - 1) c6c = c6r - 1;
		c7r = random() * 100 + 1;c7r = floor(c7r);c7c = random() * c7r;c7c = floor(c7c);if (c7c > c7r - 1) c7c = c7r - 1;
		c8r = random() * 100 + 1;c8r = floor(c8r);c8c = random() * c8r;c8c = floor(c8c);if (c8c > c8r - 1) c8c = c8r - 1;
		c9r = random() * 100 + 1;c9r = floor(c9r);c9c = random() * c9r;c9c = floor(c9c);if (c9c > c9r - 1) c9c = c9r - 1;
		car = random() * 100 + 1;car = floor(car);cac = random() * car;cac = floor(cac);if (cac > car - 1) cac = car - 1;
		cbr = random() * 100 + 1;cbr = floor(cbr);cbc = random() * cbr;cbc = floor(cbc);if (cbc > cbr - 1) cbc = cbr - 1;
		ccr = random() * 100 + 1;ccr = floor(ccr);ccc = random() * ccr;ccc = floor(ccc);if (ccc > ccr - 1) ccc = ccr - 1;
		cdr = random() * 100 + 1;cdr = floor(cdr);cdc = random() * cdr;cdc = floor(cdc);if (cdc > cdr - 1) cdc = cdr - 1;
		cer = random() * 100 + 1;cer = floor(cer);cec = random() * cer;cec = floor(cec);if (cec > cer - 1) cec = cer - 1;
		cfr = random() * 100 + 1;cfr = floor(cfr);cfc = random() * cfr;cfc = floor(cfc);if (cfc > cfr - 1) cfc = cfr - 1;
		lhbitparms_encode_begin(0, 16);
		if (l == 1) dprint_lhbitparms_space(0, 16);
		c0s = lhbitparms_encodebits(c0c, c0r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c1s = lhbitparms_encodebits(c1c, c1r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c2s = lhbitparms_encodebits(c2c, c2r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c3s = lhbitparms_encodebits(c3c, c3r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c4s = lhbitparms_encodebits(c4c, c4r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c5s = lhbitparms_encodebits(c5c, c5r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c6s = lhbitparms_encodebits(c6c, c6r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c7s = lhbitparms_encodebits(c7c, c7r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c8s = lhbitparms_encodebits(c8c, c8r);if (l == 1) dprint_lhbitparms_space(0, 16);
		c9s = lhbitparms_encodebits(c9c, c9r);if (l == 1) dprint_lhbitparms_space(0, 16);
		cas = lhbitparms_encodebits(cac, car);if (l == 1) dprint_lhbitparms_space(0, 16);
		cbs = lhbitparms_encodebits(cbc, cbr);if (l == 1) dprint_lhbitparms_space(0, 16);
		ccs = lhbitparms_encodebits(ccc, ccr);if (l == 1) dprint_lhbitparms_space(0, 16);
		cds = lhbitparms_encodebits(cdc, cdr);if (l == 1) dprint_lhbitparms_space(0, 16);
		ces = lhbitparms_encodebits(cec, cer);if (l == 1) dprint_lhbitparms_space(0, 16);
		cfs = lhbitparms_encodebits(cfc, cfr);if (l == 1) dprint_lhbitparms_space(0, 16);
		lhbitparms_encode_finish();
		lhbitparms_decode_begin(0, 16);
		if (c0s) if (lhbitparms_decodebits(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhbitparms_decodebits(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhbitparms_decodebits(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhbitparms_decodebits(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhbitparms_decodebits(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhbitparms_decodebits(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhbitparms_decodebits(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhbitparms_decodebits(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhbitparms_decodebits(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhbitparms_decodebits(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhbitparms_decodebits(car) != cac) dprint("decode error\n");
		if (cbs) if (lhbitparms_decodebits(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhbitparms_decodebits(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhbitparms_decodebits(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhbitparms_decodebits(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhbitparms_decodebits(cfr) != cfc) dprint("decode error\n");
	}
};








// traces a curved trajectory (grenades for instance)
// sets the trace info for the last segment (the one which hit something)
// and returns the flight time upto the impact
float(vector org, vector vel, float maxtime, float nomonsters, entity ignore) oldtracetoss =
{
	local float c, grav;
	local vector v, vel2;
	grav = cvar("sv_gravity") * 0.1; // only reads the cvar once
	c = 0;v = org;vel2 = vel;
	while (c < maxtime)
	{
		//dprint("vel2=");
		//dprintvector(vel2);
		//dprint("\n");
		//particle(v, '0 0 0', 104, 4);
		traceline(v, v + vel2 * 0.05, nomonsters, ignore);
		if (trace_fraction < 1)
		{
			c = c + trace_fraction * 0.05;
			//dprint("tracetoss: ");
			//dprint(ftos(c * 1000));
			//dprint(" impact:");
			//dprint(trace_ent.classname);
			//dprint("\n");
			return c; // how long it took to impact
		}
		if (trace_startsolid)
		{
			//dprint("tracetoss: started in a solid\n");
			return 0; // started in a solid?
		}
		vel2_z = vel2_z - grav;
		v = v + vel2 * 0.1;
		c = c + 0.1;
	}
	//dprint("tracetoss: ran out of time\n");
	return maxtime; // didn't impact
};

entity tracetossent;
entity tracetossfaketarget;

void(vector org, vector m1, vector m2, vector vel, entity ignore) tracetossnoent =
{
	if (!tracetossent)
		tracetossent = spawn();
	setorigin(tracetossent, org);
	setsize(tracetossent, m1, m2);
	tracetossent.velocity = vel;
	tracetoss(tracetossent, ignore);
};

// traces multiple trajectories to find one that will impact the target
// 'end' vector is the place it aims for,
// returns TRUE only if it hit targ (don't target non-solid entities)
vector findtrajectory_velocity; // calculated direction
float(vector org, vector end, entity targ, float shotspeed, float maxtime, float nomonsters, entity ignore) oldfindtrajectory =
{
	local float c;
	local vector dir;
	if (shotspeed < 1)
		return FALSE; // could cause division by zero if calculated
	if (nomonsters)
	if (targ.solid != SOLID_BSP) // nomonsters ignores BBOX and SLIDEBOX
		return FALSE; // could never hit it
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return FALSE; // could never hit it
	c = 0;
	if (maxtime == 0) // calculate maxtime
		maxtime = vlen(end - org) / shotspeed + 0.2;
	dir = normalize(end - org);
	while (c < 10) // 10 traces
	{
		findtrajectory_velocity = normalize(dir) * shotspeed;
		//dprint("findtrajectory: testing vel=");
		//dprintvector(findtrajectory_velocity);
		//dprint("\n");
		oldtracetoss(org, findtrajectory_velocity, maxtime, nomonsters, ignore);
		if (trace_ent == targ) // done
		{
			//dprint("findtrajectory: found target\n");
			return TRUE;
		}
		dir_z = dir_z + 0.1; // aim up a little more
		c = c + 1;
	}
	//dprint("findtrajectory: didn't reach target\n");
	// leave a valid one even if it won't reach
	findtrajectory_velocity = normalize(end - org) * shotspeed;
	return FALSE;
};

// returns TRUE if it was able to calculate a trajectory which would hit,
// FALSE if not
float(vector org, vector m1, vector m2, entity targ, float shotspeed, float maxtime, entity ignore) findtrajectory =
{
	local float c;
	local vector dir, end;
	if (shotspeed < 1)
		return FALSE; // could cause division by zero if calculated
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return FALSE; // could never hit it
	end = (targ.absmin + targ.absmax) * 0.5;
	if ((vlen(end - org) / shotspeed + 0.2) > maxtime)
		return FALSE; // out of range
	if (!tracetossent)
		tracetossent = spawn();
	setsize(tracetossent, m1, m2);
	c = 0;
	dir = normalize(end - org);
	while (c < 10) // 10 traces
	{
		setorigin(tracetossent, org); // reset
		tracetossent.velocity = findtrajectory_velocity = normalize(dir) * shotspeed;
		tracetoss(tracetossent, ignore); // love builtin functions...
		if (trace_ent == targ) // done
			return TRUE;
/*
		if (cvar("developer"))
		{
			oldtracetoss(org, findtrajectory_velocity, maxtime, MOVE_NORMAL, ignore);
			if (trace_ent == targ)
			{
				dprint("engine tracetoss broken?  (oldtracetoss succeeded)\n");
				dprint("findtrajectory ");dprintvector(org);dprint(" to ");dprintvector(end);dprint("\n");
				return TRUE;
			}
		}
*/
		dir_z = dir_z + 0.1; // aim up a little more
		c = c + 1;
	}
	// leave a valid one even if it won't reach
	findtrajectory_velocity = normalize(end - org) * shotspeed;
	return FALSE;
};

// returns TRUE if it was able to calculate a trajectory which would hit,
// FALSE if not
float(vector org, vector m1, vector m2, entity targ, float shotspeed, float shotupspeed, float maxtime, float shotdelay, entity ignore) findtrajectorywithleading =
{
	local float c, savesolid, shottime;
	local vector dir, end, v;
	if (vlen(targ.velocity) < 10) // immobile targets can be hit with the normal method
		return findtrajectory(org, m1, m2, targ, shotspeed, maxtime, ignore);
	if (shotspeed < 1)
		return FALSE; // could cause division by zero if calculated
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return FALSE; // could never hit it
	if (!tracetossent)
		tracetossent = spawn();
	tracetossent.owner = ignore;
	setsize(tracetossent, m1, m2);
	savesolid = targ.solid;
	targ.solid = SOLID_NOT;
	shottime = ((vlen(targ.origin - org) / shotspeed) + shotdelay);
	v = targ.velocity * shottime + targ.origin;
	tracebox(targ.origin, targ.mins, targ.maxs, v, FALSE, targ);
	v = trace_endpos;
	end = v + (targ.mins + targ.maxs) * 0.5;
	if ((vlen(end - org) / shotspeed + 0.2) > maxtime)
	{
		// out of range
		targ.solid = savesolid;
		return FALSE;
	}

	if (!tracetossfaketarget)
		tracetossfaketarget = spawn();
	tracetossfaketarget.solid = savesolid;
	tracetossfaketarget.movetype = targ.movetype;
	setmodel(tracetossfaketarget, targ.model);
	tracetossfaketarget.model = targ.model;
	tracetossfaketarget.modelindex = targ.modelindex;
	setsize(tracetossfaketarget, targ.mins, targ.maxs);
	setorigin(tracetossfaketarget, v);

	c = 0;
	dir = normalize(end - org);
	while (c < 10) // 10 traces
	{
		setorigin(tracetossent, org); // reset
		tracetossent.velocity = findtrajectory_velocity = normalize(dir) * shotspeed + '0 0 1' * shotupspeed;
		tracetoss(tracetossent, ignore); // love builtin functions...
		if (trace_ent == tracetossfaketarget) // done
		{
			targ.solid = savesolid;

			// make it disappear
			tracetossfaketarget.solid = SOLID_NOT;
			tracetossfaketarget.movetype = MOVETYPE_NONE;
			tracetossfaketarget.model = "";
			tracetossfaketarget.modelindex = 0;
			// relink to remove it from physics considerations
			setorigin(tracetossfaketarget, v);

			return TRUE;
		}
/*
		if (cvar("developer"))
		{
			oldtracetoss(org, findtrajectory_velocity, maxtime, MOVE_NORMAL, ignore);
			if (trace_ent == targ)
			{
				dprint("engine tracetoss broken?  (oldtracetoss succeeded)\n");
				dprint("findtrajectorywithleading ");dprintvector(org);dprint(" to ");dprintvector(end);dprint(" (");dprintvector(targ.origin);dprint(" + ");dprintfloat(shottime);dprint(" * ");dprintvector(targ.velocity);dprint(")\n");

				targ.solid = savesolid;

				// make it disappear
				tracetossfaketarget.solid = SOLID_NOT;
				tracetossfaketarget.movetype = MOVETYPE_NONE;
				tracetossfaketarget.model = "";
				tracetossfaketarget.modelindex = 0;
				// relink to remove it from physics considerations
				setorigin(tracetossfaketarget, v);

				return TRUE;
			}
		}
*/
		dir_z = dir_z + 0.1; // aim up a little more
		c = c + 1;
	}
	targ.solid = savesolid;

	// make it disappear
	tracetossfaketarget.solid = SOLID_NOT;
	tracetossfaketarget.movetype = MOVETYPE_NONE;
	tracetossfaketarget.model = "";
	tracetossfaketarget.modelindex = 0;
	// relink to remove it from physics considerations
	setorigin(tracetossfaketarget, v);

	// leave a valid one even if it won't reach
	findtrajectory_velocity = normalize(end - org) * shotspeed;
	return FALSE;
};

vector(float shotdelay) monster_shotleadbullet =
{
	// project latency movement
	tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.velocity * shotdelay, FALSE, self.enemy);
	traceline(self.origin + '0 0 16', trace_endpos, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// can't hit that, return current position and hope for the best
		return self.enemy.origin;
	}
	return trace_endpos;
};

vector(float shotdelay, float shotspeed) monster_shotlead =
{
	local float f;
	// project latency and shot leading movement
	f = shotdelay + vlen(self.enemy.origin - self.origin) / shotspeed;
	tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.velocity * f, FALSE, self.enemy);
	// check if self can shoot that spot
	traceline(self.origin + '0 0 16', trace_endpos, FALSE, self);
	if (trace_fraction < 1 && trace_ent != self.enemy)
	{
		// try with latency but not shot leading
		tracebox(self.enemy.origin, self.enemy.mins, self.enemy.maxs, self.enemy.origin + self.enemy.velocity * shotdelay, FALSE, self.enemy);
		traceline(self.origin + '0 0 16', trace_endpos, FALSE, self);
		if (trace_fraction < 1 && trace_ent != self.enemy)
		{
			// can't hit that either, return current position and hope for the best
			return self.enemy.origin;
		}
	}
	return trace_endpos;
};

// hack to make it hit dead bodies
// (traceline using a SLIDEBOX will normally skip CORPSE,
//  desirable for visibility checking but not for weapons fire)
void(vector start, vector end, float noents, entity attacker) weapontraceline =
{
	local float s;
	s = attacker.solid;
	if (attacker.solid == SOLID_SLIDEBOX)
		attacker.solid = SOLID_BBOX;
	traceline(start, end, noents, attacker);
	if (s == SOLID_SLIDEBOX)
		attacker.solid = s;
};

float(float num, float digits) padoutnum =
{
	local float d;
	d = digits - 1;
	if (num < 0)
	{
		d = d - 1;
		num = 0 - num;
	}
	if (num >= 10) d = d - 1;
	if (num >= 100) d = d - 1;
	if (num >= 1000) d = d - 1;
	if (num >= 10000) d = d - 1;
	if (num >= 100000) d = d - 1;
	if (num >= 1000000) d = d - 1;
	return (d);
};

void(entity ent, float num, float digits) sprintnumdigits =
{
	local float d;
	local string s;
	num = floor(num); // remove fraction
	d = padoutnum(num, digits);
	while (d > 0)
	{
		d = d - 1;
		sprint(ent, " ");
	}
	s = ftos(num);
	sprint(ent, s);
};

void(entity e, float n) sprintnum =
{
	local string s;
	s = ftos(n);
	sprint(e, s);
};



// lag simulation

.void(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) lag_func;

// upto 5 queued messages
.float lag1_time;
.float lag1_float1;
.float lag1_float2;
.entity lag1_entity1;
.vector lag1_vec1;
.vector lag1_vec2;
.vector lag1_vec3;
.vector lag1_vec4;

.float lag2_time;
.float lag2_float1;
.float lag2_float2;
.entity lag2_entity1;
.vector lag2_vec1;
.vector lag2_vec2;
.vector lag2_vec3;
.vector lag2_vec4;

.float lag3_time;
.float lag3_float1;
.float lag3_float2;
.entity lag3_entity1;
.vector lag3_vec1;
.vector lag3_vec2;
.vector lag3_vec3;
.vector lag3_vec4;

.float lag4_time;
.float lag4_float1;
.float lag4_float2;
.entity lag4_entity1;
.vector lag4_vec1;
.vector lag4_vec2;
.vector lag4_vec3;
.vector lag4_vec4;

.float lag5_time;
.float lag5_float1;
.float lag5_float2;
.entity lag5_entity1;
.vector lag5_vec1;
.vector lag5_vec2;
.vector lag5_vec3;
.vector lag5_vec4;

void() lag_update =
{
	if (self.lag1_time) if (time > self.lag1_time) {self.lag_func(self.lag1_time, self.lag1_float1, self.lag1_float2, self.lag1_entity1, self.lag1_vec1, self.lag1_vec2, self.lag1_vec3, self.lag1_vec4);self.lag1_time = 0;}
	if (self.lag2_time) if (time > self.lag2_time) {self.lag_func(self.lag2_time, self.lag2_float1, self.lag2_float2, self.lag2_entity1, self.lag2_vec1, self.lag2_vec2, self.lag2_vec3, self.lag2_vec4);self.lag2_time = 0;}
	if (self.lag3_time) if (time > self.lag3_time) {self.lag_func(self.lag3_time, self.lag3_float1, self.lag3_float2, self.lag3_entity1, self.lag3_vec1, self.lag3_vec2, self.lag3_vec3, self.lag3_vec4);self.lag3_time = 0;}
	if (self.lag4_time) if (time > self.lag4_time) {self.lag_func(self.lag4_time, self.lag4_float1, self.lag4_float2, self.lag4_entity1, self.lag4_vec1, self.lag4_vec2, self.lag4_vec3, self.lag4_vec4);self.lag4_time = 0;}
	if (self.lag5_time) if (time > self.lag5_time) {self.lag_func(self.lag5_time, self.lag5_float1, self.lag5_float2, self.lag5_entity1, self.lag5_vec1, self.lag5_vec2, self.lag5_vec3, self.lag5_vec4);self.lag5_time = 0;}
};

float(float t, float f1, float f2, entity e1, vector v1, vector v2, vector v3, vector v4) lag_additem =
{
	if (self.lag1_time == 0) {self.lag1_time = t;self.lag1_float1 = f1;self.lag1_float2 = f2;self.lag1_entity1 = e1;self.lag1_vec1 = v1;self.lag1_vec2 = v2;self.lag1_vec3 = v3;self.lag1_vec4 = v4;return TRUE;}
	if (self.lag2_time == 0) {self.lag2_time = t;self.lag2_float1 = f1;self.lag2_float2 = f2;self.lag2_entity1 = e1;self.lag2_vec1 = v1;self.lag2_vec2 = v2;self.lag2_vec3 = v3;self.lag2_vec4 = v4;return TRUE;}
	if (self.lag3_time == 0) {self.lag3_time = t;self.lag3_float1 = f1;self.lag3_float2 = f2;self.lag3_entity1 = e1;self.lag3_vec1 = v1;self.lag3_vec2 = v2;self.lag3_vec3 = v3;self.lag3_vec4 = v4;return TRUE;}
	if (self.lag4_time == 0) {self.lag4_time = t;self.lag4_float1 = f1;self.lag4_float2 = f2;self.lag4_entity1 = e1;self.lag4_vec1 = v1;self.lag4_vec2 = v2;self.lag4_vec3 = v3;self.lag4_vec4 = v4;return TRUE;}
	if (self.lag5_time == 0) {self.lag5_time = t;self.lag5_float1 = f1;self.lag5_float2 = f2;self.lag5_entity1 = e1;self.lag5_vec1 = v1;self.lag5_vec2 = v2;self.lag5_vec3 = v3;self.lag5_vec4 = v4;return TRUE;}
	// no room for it (what is the best thing to do here??)
	return FALSE;
};

