
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
	local float f;
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
	local float c, f0, f1, f2, f, n, n2, r0, r1, r2, spew;
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

vector(float index) lhbitparms_codesize =
{
	if (index < 16)
		return '2 128 8388608';
	else
		return '2 64 8388608';
};

void(float index, vector v) lhbitparms_storeparm =
{
	local float code;
	if (index >= 16)
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
	if (index >= 16)
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
	local float current, total, remaining;
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
	local float c, c2, n0, n1, n2, l;
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
	local string t;
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

/*
float lhfp2_code01; // sign and exponent part, <508
float lhfp2_code2; // mantissa part, <8388608

float(float code01, float code2) lhfp2_encode =
{
	local float code, code0, code1;
	if (code1 != floor(code1) || code1 < 0 || code1 >= 508)
		error("lhfp2_encode: invalid code01, must be an integer in the range 0-507.\n");
	if (code2 != floor(code2) || code2 < 0 || code2 >= 8388608)
		error("lhfp2_encode: invalid code2, must be an integer in the range 0-8388607.\n");
	code0 = code01 & 1;
	code1 = (code01 - code0) * 0.5;
	code = (1 + (code2 / 8388608)) * lhfp_code1toscale(code1);
	if (code0)
		code = 0 - code;
	return code;
};

float(float code) lhfp2_decode =
{
	local float f, code0, code1;
	// code == 0 never occurs on a valid encoded value, we'll just assume it's garbage here.
	if (code == 0)
	{
		// invalid code
		lhfp2_code01 = 0;
		lhfp2_code2 = 0;
		return FALSE;
	}
	if (code < 0)
	{
		code = 0 - code;
		code0 = 1;
	}
	else
		code0 = 0;
	code1 = lhfp_scaletocode1(code);
	if (code1 < 0 || code1 >= 254)
	{
		// invalid exponent
		lhfp2_code01 = 0;
		lhfp2_code2 = 0;
		return FALSE;
	}
	lhfp2_code2 = ((code / lhfp_code1toscale(code1)) - 1) * 8388608;
	lhfp2_code01 = code0 + code1 * 2;
	return TRUE;
};

void() lhfp2_test =
{
	local float c, f01, f2, f, n, n2, r01, r2, spew;
	local string t;
	if (!cvar("developer"))
		bprint("lhfp2_test called without developer on, the dprints won't be seen.\n");
	c = 0;
	r01 = 0;
	r2 = 0;
	spew = 0;
	while (c < 100)
	{
		if (r01 == 0)
			f01 = 0;
		else if (r01 == 1)
			f01 = 507;
		else
		{
			f01 = random() * 508;
			f01 = floor(f01);
			// random() has a 1 in 32768 chance of returning 1.0, handle this case
			if (f01 > 507)
				f01 = 507;
		}
		f01 = bound(0, f01, 507);
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
		n = lhfp2_encode(f01, f2);
		lhfp2_decode(n);
		t = ftos(n);
		cvar_set("temp1", t);
		n2 = cvar("temp1");
		cvar_set("temp1", "0");
		if (spew || (n2 != n && f01 >= 278))
		{
			dprint("lhfp2_test: code combination ");dprint(ftos(f01));
			dprint(" ");dprint(ftos(f2));
			dprint(" encodes to ");dprint(ftos(n));
			if (n2 != n)
			{
				dprint(" which converts back INCORRECTLY to ");dprint(ftos(n2));
			}
			dprint("\n");
		}
		if (lhfp2_code01 != f01 || lhfp2_code2 != f2)
		{
			dprint("lhfp2_test: code combination ");dprint(ftos(f01));
			dprint(" ");dprint(ftos(f2));
			dprint(" failed! (came back as ");dprint(ftos(lhfp2_code01));
			dprint(" ");dprint(ftos(lhfp2_code2));
			dprint(")\n");
		}
		r01 = r01 + 1;
		if (r01 >= 3)
		{
			r01 = 0;
			r2 = r2 + 1;
			if (r2 >= 3)
			{
				r2 = 0;
				c = c + 1;
			}
		}
	}
};

float lhradix_code;
float lhradix_scale;

void(float startcode, float totalradix) lhradix_begin =
{
	lhradix_code = startcode;
	lhradix_scale = totalradix;
	//dprint("begin(");dprint(ftos(startcode));
	//dprint(", ");dprint(ftos(totalradix));
	//dprint("); s=");dprint(ftos(lhradix_scale));
	//dprint(" c=");dprint(ftos(lhradix_code));
	//dprint("\n");
};

float() lhradix_finish =
{
	return lhradix_code;
};

// returns TRUE if the number fit into the buffer, FALSE if it did not.
float(float n, float radix) lhradix_encode =
{
	//dprint("encode(");dprint(ftos(n));
	//dprint(", ");dprint(ftos(radix));
	//dprint(") == ");
	if (lhradix_scale < radix)
	{
		//dprint("FALSE;\n");
		return FALSE;
	}
	lhradix_scale = floor(lhradix_scale / radix);
	lhradix_code = lhradix_code + n * lhradix_scale;
	//dprint("TRUE; s=");dprint(ftos(lhradix_scale));
	//dprint(" c=");dprint(ftos(lhradix_code));
	//dprint("\n");
	return TRUE;
};

float(float radix) lhradix_decode =
{
	local float n;
	lhradix_scale = floor(lhradix_scale / radix);
	n = floor(lhradix_code / lhradix_scale);
	lhradix_code = lhradix_code - n * lhradix_scale;
	//dprint("decode(");dprint(ftos(radix));
	//dprint(") == ");dprint(ftos(n));
	//dprint("; s=");dprint(ftos(lhradix_scale));
	//dprint(" c=");dprint(ftos(lhradix_code));
	//dprint("\n");
	return n;
};

void() lhradix_test =
{
	local float c, c2, n, l;
	local float c0c, c0r, c0s;
	local float c1c, c1r, c1s;
	local float c2c, c2r, c2s;
	local float c3c, c3r, c3s;
	local string t;
	if (!cvar("developer"))
		bprint("lhradix_test called without developer on, the dprints won't be seen.\n");
	lhradix_begin(0, 8388608);
	c = 2;
	while (lhradix_encode(c - 1, c))
		c = c + 1;
	n = lhradix_finish();
	//dprint("c=");dprint(ftos(c));
	//dprint(" n=");dprint(ftos(n));
	//dprint("\n");
	lhradix_begin(n, 8388608);
	c2 = 2;
	while (c2 < c)
	{
		if (lhradix_decode(c2) != c2 - 1)
			//dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhradix_finish();
	l = 0;
	while (l < 1000)
	{
		l = l + 1;
		c0r = random() * 100 + 1;c0r = floor(c0r);c0c = random() * c0r;c0c = floor(c0c);if (c0c > c0r - 1) c0c = c0r - 1;
		c1r = random() * 100 + 1;c1r = floor(c1r);c1c = random() * c1r;c1c = floor(c1c);if (c1c > c1r - 1) c1c = c1r - 1;
		c2r = random() * 100 + 1;c2r = floor(c2r);c2c = random() * c2r;c2c = floor(c2c);if (c2c > c2r - 1) c2c = c2r - 1;
		c3r = random() * 100 + 1;c3r = floor(c3r);c3c = random() * c3r;c3c = floor(c3c);if (c3c > c3r - 1) c3c = c3r - 1;
		lhradix_begin(0, 8388608);
		c0s = lhradix_encode(c0c, c0r);
		c1s = lhradix_encode(c1c, c1r);
		c2s = lhradix_encode(c2c, c2r);
		c3s = lhradix_encode(c3c, c3r);
		n = lhradix_finish();
		lhradix_begin(n, 8388608);
		if (c0s) if (lhradix_decode(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhradix_decode(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhradix_decode(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhradix_decode(c3r) != c3c) dprint("decode error\n");
		lhradix_finish();
	}
};

float lhradix3_code0;
float lhradix3_scale0;
float lhradix3_code1;
float lhradix3_scale1;
float lhradix3_code2;
float lhradix3_scale2;

void(float startcode0, float startcode1, float startcode2, float totalradix0, float totalradix1, float totalradix2) lhradix3_begin =
{
	lhradix3_code0 = startcode0;
	lhradix3_code1 = startcode1;
	lhradix3_code2 = startcode2;
	lhradix3_scale0 = totalradix0;
	lhradix3_scale1 = totalradix1;
	lhradix3_scale2 = totalradix2;
	//dprint("begin(");dprint(ftos(startcode0));
	//dprint(", ");dprint(ftos(startcode1));
	//dprint(", ");dprint(ftos(startcode2));
	//dprint(", ");dprint(ftos(totalradix0));
	//dprint(", ");dprint(ftos(totalradix1));
	//dprint(", ");dprint(ftos(totalradix2));
	//dprint("); s0=");dprint(ftos(lhradix3_scale0));
	//dprint(" c0=");dprint(ftos(lhradix3_code0));
	//dprint(" s1=");dprint(ftos(lhradix3_scale1));
	//dprint(" c1=");dprint(ftos(lhradix3_code1));
	//dprint(" s2=");dprint(ftos(lhradix3_scale2));
	//dprint(" c2=");dprint(ftos(lhradix3_code2));
	//dprint("\n");
};

void() lhradix3_finish =
{
	//dprint("finish(); s0=");dprint(ftos(lhradix3_scale0));
	//dprint(" c0=");dprint(ftos(lhradix3_code0));
	//dprint(" s1=");dprint(ftos(lhradix3_scale1));
	//dprint(" c1=");dprint(ftos(lhradix3_code1));
	//dprint(" s2=");dprint(ftos(lhradix3_scale2));
	//dprint(" c2=");dprint(ftos(lhradix3_code2));
	//dprint("\n");
};

// returns TRUE if the number fit into the buffer, FALSE if it did not.
float(float n, float radix) lhradix3_encode =
{
	//dprint("encode(");
	//dprint(ftos(n));
	//dprint(", ");
	//dprint(ftos(radix));
	//dprint(") == ");
	if (lhradix3_scale0 >= radix)
	{
		lhradix3_scale0 = floor(lhradix3_scale0 / radix);
		lhradix3_code0 = lhradix3_code0 + n * lhradix3_scale0;
	}
	else if (lhradix3_scale1 >= radix)
	{
		lhradix3_scale1 = floor(lhradix3_scale1 / radix);
		lhradix3_code1 = lhradix3_code1 + n * lhradix3_scale1;
	}
	else if (lhradix3_scale2 >= radix)
	{
		lhradix3_scale2 = floor(lhradix3_scale2 / radix);
		lhradix3_code2 = lhradix3_code2 + n * lhradix3_scale2;
	}
	else
	{
		//dprint("FALSE;\n");
		return FALSE;
	}
	//dprint("TRUE; s0=");dprint(ftos(lhradix3_scale0));
	//dprint(" c0=");dprint(ftos(lhradix3_code0));
	//dprint(" s1=");dprint(ftos(lhradix3_scale1));
	//dprint(" c1=");dprint(ftos(lhradix3_code1));
	//dprint(" s2=");dprint(ftos(lhradix3_scale2));
	//dprint(" c2=");dprint(ftos(lhradix3_code2));
	//dprint("\n");
	return TRUE;
};

float(float radix) lhradix3_decode =
{
	local float n;
	//dprint("decode(");
	//dprint(ftos(radix));
	//dprint(") == ");
	if (lhradix3_scale0 >= radix)
	{
		lhradix3_scale0 = floor(lhradix3_scale0 / radix);
		n = floor(lhradix3_code0 / lhradix3_scale0);
		lhradix3_code0 = lhradix3_code0 - n * lhradix3_scale0;
	}
	else if (lhradix3_scale1 >= radix)
	{
		lhradix3_scale1 = floor(lhradix3_scale1 / radix);
		n = floor(lhradix3_code1 / lhradix3_scale1);
		lhradix3_code1 = lhradix3_code1 - n * lhradix3_scale1;
	}
	else if (lhradix3_scale2 >= radix)
	{
		lhradix3_scale2 = floor(lhradix3_scale2 / radix);
		n = floor(lhradix3_code2 / lhradix3_scale2);
		lhradix3_code2 = lhradix3_code2 - n * lhradix3_scale2;
	}
	else
		n = 0; // error
	//dprint(ftos(n));
	//dprint("; s0=");dprint(ftos(lhradix3_scale0));
	//dprint(" c0=");dprint(ftos(lhradix3_code0));
	//dprint(" s1=");dprint(ftos(lhradix3_scale1));
	//dprint(" c1=");dprint(ftos(lhradix3_code1));
	//dprint(" s2=");dprint(ftos(lhradix3_scale2));
	//dprint(" c2=");dprint(ftos(lhradix3_code2));
	//dprint("\n");
	return n;
};

void() lhradix3_test =
{
	local float c, c2, n0, n1, n2, l;
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
	local string t;
	if (!cvar("developer"))
		bprint("lhradix3_test called without developer on, the dprints won't be seen.\n");
	lhradix3_begin(0, 0, 0, 2, 254, 8388608);
	c = 2;
	while (lhradix3_encode(c - 1, c))
		c = c + 1;
	lhradix3_finish();
	n0 = lhradix3_code0;
	n1 = lhradix3_code1;
	n2 = lhradix3_code2;
	//dprint("c=");
	//dprint(ftos(c));
	//dprint(" n=");
	//dprint(ftos(n));
	//dprint("\n");
	lhradix3_begin(n0, n1, n2, 2, 254, 8388608);
	c2 = 2;
	while (c2 < c)
	{
		if (lhradix3_decode(c2) != c2 - 1)
			//dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhradix3_finish();
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
		lhradix3_begin(0, 0, 0, 2, 254, 8388608);
		c0s = lhradix3_encode(c0c, c0r);
		c1s = lhradix3_encode(c1c, c1r);
		c2s = lhradix3_encode(c2c, c2r);
		c3s = lhradix3_encode(c3c, c3r);
		c4s = lhradix3_encode(c4c, c4r);
		c5s = lhradix3_encode(c5c, c5r);
		c6s = lhradix3_encode(c6c, c6r);
		c7s = lhradix3_encode(c7c, c7r);
		c8s = lhradix3_encode(c8c, c8r);
		c9s = lhradix3_encode(c9c, c9r);
		cas = lhradix3_encode(cac, car);
		cbs = lhradix3_encode(cbc, cbr);
		ccs = lhradix3_encode(ccc, ccr);
		cds = lhradix3_encode(cdc, cdr);
		ces = lhradix3_encode(cec, cer);
		cfs = lhradix3_encode(cfc, cfr);
		lhradix3_finish();
		n0 = lhradix3_code0;
		n1 = lhradix3_code1;
		n2 = lhradix3_code2;
		lhradix3_begin(n0, n1, n2, 2, 254, 8388608);
		if (c0s) if (lhradix3_decode(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhradix3_decode(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhradix3_decode(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhradix3_decode(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhradix3_decode(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhradix3_decode(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhradix3_decode(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhradix3_decode(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhradix3_decode(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhradix3_decode(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhradix3_decode(car) != cac) dprint("decode error\n");
		if (cbs) if (lhradix3_decode(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhradix3_decode(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhradix3_decode(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhradix3_decode(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhradix3_decode(cfr) != cfc) dprint("decode error\n");
		lhradix3_finish();
	}
};


float lhradixarray_numcodes;
float lhradixarray_code, lhradixarray_scale;
float lhradixarray_code00, lhradixarray_scale00;
float lhradixarray_code01, lhradixarray_scale01;
float lhradixarray_code02, lhradixarray_scale02;
float lhradixarray_code03, lhradixarray_scale03;
float lhradixarray_code04, lhradixarray_scale04;
float lhradixarray_code05, lhradixarray_scale05;
float lhradixarray_code06, lhradixarray_scale06;
float lhradixarray_code07, lhradixarray_scale07;
float lhradixarray_code08, lhradixarray_scale08;
float lhradixarray_code09, lhradixarray_scale09;
float lhradixarray_code10, lhradixarray_scale10;
float lhradixarray_code11, lhradixarray_scale11;
float lhradixarray_code12, lhradixarray_scale12;
float lhradixarray_code13, lhradixarray_scale13;
float lhradixarray_code14, lhradixarray_scale14;
float lhradixarray_code15, lhradixarray_scale15;
float lhradixarray_code16, lhradixarray_scale16;
float lhradixarray_code17, lhradixarray_scale17;
float lhradixarray_code18, lhradixarray_scale18;
float lhradixarray_code19, lhradixarray_scale19;
float lhradixarray_code20, lhradixarray_scale20;
float lhradixarray_code21, lhradixarray_scale21;
float lhradixarray_code22, lhradixarray_scale22;
float lhradixarray_code23, lhradixarray_scale23;
float lhradixarray_code24, lhradixarray_scale24;
float lhradixarray_code25, lhradixarray_scale25;
float lhradixarray_code26, lhradixarray_scale26;
float lhradixarray_code27, lhradixarray_scale27;
float lhradixarray_code28, lhradixarray_scale28;
float lhradixarray_code29, lhradixarray_scale29;
float lhradixarray_code30, lhradixarray_scale30;
float lhradixarray_code31, lhradixarray_scale31;
float lhradixarray_code32, lhradixarray_scale32;
float lhradixarray_code33, lhradixarray_scale33;
float lhradixarray_code34, lhradixarray_scale34;
float lhradixarray_code35, lhradixarray_scale35;
float lhradixarray_code36, lhradixarray_scale36;
float lhradixarray_code37, lhradixarray_scale37;
float lhradixarray_code38, lhradixarray_scale38;
float lhradixarray_code39, lhradixarray_scale39;
float lhradixarray_code40, lhradixarray_scale40;
float lhradixarray_code41, lhradixarray_scale41;
float lhradixarray_code42, lhradixarray_scale42;
float lhradixarray_code43, lhradixarray_scale43;
float lhradixarray_code44, lhradixarray_scale44;
float lhradixarray_code45, lhradixarray_scale45;
float lhradixarray_code46, lhradixarray_scale46;
float lhradixarray_code47, lhradixarray_scale47;
float lhradixarray_code48, lhradixarray_scale48;
float lhradixarray_code49, lhradixarray_scale49;
float lhradixarray_code50, lhradixarray_scale50;
float lhradixarray_code51, lhradixarray_scale51;
float lhradixarray_code52, lhradixarray_scale52;
float lhradixarray_code53, lhradixarray_scale53;
float lhradixarray_code54, lhradixarray_scale54;
float lhradixarray_code55, lhradixarray_scale55;
float lhradixarray_code56, lhradixarray_scale56;
float lhradixarray_code57, lhradixarray_scale57;
float lhradixarray_code58, lhradixarray_scale58;
float lhradixarray_code59, lhradixarray_scale59;
float lhradixarray_code60, lhradixarray_scale60;
float lhradixarray_code61, lhradixarray_scale61;
float lhradixarray_code62, lhradixarray_scale62;
float lhradixarray_code63, lhradixarray_scale63;


void(float parmindex, float n) lhparms_storeparm =
{
	     if (parmindex <  1) parm1 = n;
	else if (parmindex <  2) parm2 = n;
	else if (parmindex <  3) parm3 = n;
	else if (parmindex <  4) parm4 = n;
	else if (parmindex <  5) parm5 = n;
	else if (parmindex <  6) parm6 = n;
	else if (parmindex <  7) parm7 = n;
	else if (parmindex <  8) parm8 = n;
	else if (parmindex <  9) parm9 = n;
	else if (parmindex < 10) parm10 = n;
	else if (parmindex < 11) parm11 = n;
	else if (parmindex < 12) parm12 = n;
	else if (parmindex < 13) parm13 = n;
	else if (parmindex < 14) parm14 = n;
	else if (parmindex < 15) parm15 = n;
	else                     parm16 = n;
};

float(float parmindex) lhparms_loadparm =
{
	     if (parmindex <  1) return parm1;
	else if (parmindex <  2) return parm2;
	else if (parmindex <  3) return parm3;
	else if (parmindex <  4) return parm4;
	else if (parmindex <  5) return parm5;
	else if (parmindex <  6) return parm6;
	else if (parmindex <  7) return parm7;
	else if (parmindex <  8) return parm8;
	else if (parmindex <  9) return parm9;
	else if (parmindex < 10) return parm10;
	else if (parmindex < 11) return parm11;
	else if (parmindex < 12) return parm12;
	else if (parmindex < 13) return parm13;
	else if (parmindex < 14) return parm14;
	else if (parmindex < 15) return parm15;
	else                     return parm16;
};

void(float index) lhradixarray_load =
{
	if (index < 16)
	{
		// 0-16
			 if (index <  1) {lhradixarray_code = lhradixarray_code00;lhradixarray_scale = lhradixarray_scale00;return;}
		else if (index <  2) {lhradixarray_code = lhradixarray_code01;lhradixarray_scale = lhradixarray_scale01;return;}
		else if (index <  3) {lhradixarray_code = lhradixarray_code02;lhradixarray_scale = lhradixarray_scale02;return;}
		else if (index <  4) {lhradixarray_code = lhradixarray_code03;lhradixarray_scale = lhradixarray_scale03;return;}
		else if (index <  5) {lhradixarray_code = lhradixarray_code04;lhradixarray_scale = lhradixarray_scale04;return;}
		else if (index <  6) {lhradixarray_code = lhradixarray_code05;lhradixarray_scale = lhradixarray_scale05;return;}
		else if (index <  7) {lhradixarray_code = lhradixarray_code06;lhradixarray_scale = lhradixarray_scale06;return;}
		else if (index <  8) {lhradixarray_code = lhradixarray_code07;lhradixarray_scale = lhradixarray_scale07;return;}
		else if (index <  9) {lhradixarray_code = lhradixarray_code08;lhradixarray_scale = lhradixarray_scale08;return;}
		else if (index < 10) {lhradixarray_code = lhradixarray_code09;lhradixarray_scale = lhradixarray_scale09;return;}
		else if (index < 11) {lhradixarray_code = lhradixarray_code10;lhradixarray_scale = lhradixarray_scale10;return;}
		else if (index < 12) {lhradixarray_code = lhradixarray_code11;lhradixarray_scale = lhradixarray_scale11;return;}
		else if (index < 13) {lhradixarray_code = lhradixarray_code12;lhradixarray_scale = lhradixarray_scale12;return;}
		else if (index < 14) {lhradixarray_code = lhradixarray_code13;lhradixarray_scale = lhradixarray_scale13;return;}
		else if (index < 15) {lhradixarray_code = lhradixarray_code14;lhradixarray_scale = lhradixarray_scale14;return;}
		else                 {lhradixarray_code = lhradixarray_code15;lhradixarray_scale = lhradixarray_scale15;return;}
	}
	else if (index < 32)
	{
		// 16-32
			 if (index < 17) {lhradixarray_code = lhradixarray_code16;lhradixarray_scale = lhradixarray_scale16;return;}
		else if (index < 18) {lhradixarray_code = lhradixarray_code17;lhradixarray_scale = lhradixarray_scale17;return;}
		else if (index < 19) {lhradixarray_code = lhradixarray_code18;lhradixarray_scale = lhradixarray_scale18;return;}
		else if (index < 20) {lhradixarray_code = lhradixarray_code19;lhradixarray_scale = lhradixarray_scale19;return;}
		else if (index < 21) {lhradixarray_code = lhradixarray_code20;lhradixarray_scale = lhradixarray_scale20;return;}
		else if (index < 22) {lhradixarray_code = lhradixarray_code21;lhradixarray_scale = lhradixarray_scale21;return;}
		else if (index < 23) {lhradixarray_code = lhradixarray_code22;lhradixarray_scale = lhradixarray_scale22;return;}
		else if (index < 24) {lhradixarray_code = lhradixarray_code23;lhradixarray_scale = lhradixarray_scale23;return;}
		else if (index < 25) {lhradixarray_code = lhradixarray_code24;lhradixarray_scale = lhradixarray_scale24;return;}
		else if (index < 26) {lhradixarray_code = lhradixarray_code25;lhradixarray_scale = lhradixarray_scale25;return;}
		else if (index < 27) {lhradixarray_code = lhradixarray_code26;lhradixarray_scale = lhradixarray_scale26;return;}
		else if (index < 28) {lhradixarray_code = lhradixarray_code27;lhradixarray_scale = lhradixarray_scale27;return;}
		else if (index < 29) {lhradixarray_code = lhradixarray_code28;lhradixarray_scale = lhradixarray_scale28;return;}
		else if (index < 30) {lhradixarray_code = lhradixarray_code29;lhradixarray_scale = lhradixarray_scale29;return;}
		else if (index < 31) {lhradixarray_code = lhradixarray_code30;lhradixarray_scale = lhradixarray_scale30;return;}
		else                 {lhradixarray_code = lhradixarray_code31;lhradixarray_scale = lhradixarray_scale31;return;}
	}
	else if (index < 48)
	{
		// 32-48
			 if (index < 33) {lhradixarray_code = lhradixarray_code32;lhradixarray_scale = lhradixarray_scale32;return;}
		else if (index < 34) {lhradixarray_code = lhradixarray_code33;lhradixarray_scale = lhradixarray_scale33;return;}
		else if (index < 35) {lhradixarray_code = lhradixarray_code34;lhradixarray_scale = lhradixarray_scale34;return;}
		else if (index < 36) {lhradixarray_code = lhradixarray_code35;lhradixarray_scale = lhradixarray_scale35;return;}
		else if (index < 37) {lhradixarray_code = lhradixarray_code36;lhradixarray_scale = lhradixarray_scale36;return;}
		else if (index < 38) {lhradixarray_code = lhradixarray_code37;lhradixarray_scale = lhradixarray_scale37;return;}
		else if (index < 39) {lhradixarray_code = lhradixarray_code38;lhradixarray_scale = lhradixarray_scale38;return;}
		else if (index < 40) {lhradixarray_code = lhradixarray_code39;lhradixarray_scale = lhradixarray_scale39;return;}
		else if (index < 41) {lhradixarray_code = lhradixarray_code40;lhradixarray_scale = lhradixarray_scale40;return;}
		else if (index < 42) {lhradixarray_code = lhradixarray_code41;lhradixarray_scale = lhradixarray_scale41;return;}
		else if (index < 43) {lhradixarray_code = lhradixarray_code42;lhradixarray_scale = lhradixarray_scale42;return;}
		else if (index < 44) {lhradixarray_code = lhradixarray_code43;lhradixarray_scale = lhradixarray_scale43;return;}
		else if (index < 45) {lhradixarray_code = lhradixarray_code44;lhradixarray_scale = lhradixarray_scale44;return;}
		else if (index < 46) {lhradixarray_code = lhradixarray_code45;lhradixarray_scale = lhradixarray_scale45;return;}
		else if (index < 47) {lhradixarray_code = lhradixarray_code46;lhradixarray_scale = lhradixarray_scale46;return;}
		else                 {lhradixarray_code = lhradixarray_code47;lhradixarray_scale = lhradixarray_scale47;return;}
	}
	else if (index < 64)
	{
		// 48-64
			 if (index < 49) {lhradixarray_code = lhradixarray_code48;lhradixarray_scale = lhradixarray_scale48;return;}
		else if (index < 50) {lhradixarray_code = lhradixarray_code49;lhradixarray_scale = lhradixarray_scale49;return;}
		else if (index < 51) {lhradixarray_code = lhradixarray_code50;lhradixarray_scale = lhradixarray_scale50;return;}
		else if (index < 52) {lhradixarray_code = lhradixarray_code51;lhradixarray_scale = lhradixarray_scale51;return;}
		else if (index < 53) {lhradixarray_code = lhradixarray_code52;lhradixarray_scale = lhradixarray_scale52;return;}
		else if (index < 54) {lhradixarray_code = lhradixarray_code53;lhradixarray_scale = lhradixarray_scale53;return;}
		else if (index < 55) {lhradixarray_code = lhradixarray_code54;lhradixarray_scale = lhradixarray_scale54;return;}
		else if (index < 56) {lhradixarray_code = lhradixarray_code55;lhradixarray_scale = lhradixarray_scale55;return;}
		else if (index < 57) {lhradixarray_code = lhradixarray_code56;lhradixarray_scale = lhradixarray_scale56;return;}
		else if (index < 58) {lhradixarray_code = lhradixarray_code57;lhradixarray_scale = lhradixarray_scale57;return;}
		else if (index < 59) {lhradixarray_code = lhradixarray_code58;lhradixarray_scale = lhradixarray_scale58;return;}
		else if (index < 60) {lhradixarray_code = lhradixarray_code59;lhradixarray_scale = lhradixarray_scale59;return;}
		else if (index < 61) {lhradixarray_code = lhradixarray_code60;lhradixarray_scale = lhradixarray_scale60;return;}
		else if (index < 62) {lhradixarray_code = lhradixarray_code61;lhradixarray_scale = lhradixarray_scale61;return;}
		else if (index < 63) {lhradixarray_code = lhradixarray_code62;lhradixarray_scale = lhradixarray_scale62;return;}
		else                 {lhradixarray_code = lhradixarray_code63;lhradixarray_scale = lhradixarray_scale63;return;}
	}
};

void(float index) lhradixarray_store =
{
	if (index < 16)
	{
		// 0-16
			 if (index <  1) {lhradixarray_code00 = lhradixarray_code;lhradixarray_scale00 = lhradixarray_scale;return;}
		else if (index <  2) {lhradixarray_code01 = lhradixarray_code;lhradixarray_scale01 = lhradixarray_scale;return;}
		else if (index <  3) {lhradixarray_code02 = lhradixarray_code;lhradixarray_scale02 = lhradixarray_scale;return;}
		else if (index <  4) {lhradixarray_code03 = lhradixarray_code;lhradixarray_scale03 = lhradixarray_scale;return;}
		else if (index <  5) {lhradixarray_code04 = lhradixarray_code;lhradixarray_scale04 = lhradixarray_scale;return;}
		else if (index <  6) {lhradixarray_code05 = lhradixarray_code;lhradixarray_scale05 = lhradixarray_scale;return;}
		else if (index <  7) {lhradixarray_code06 = lhradixarray_code;lhradixarray_scale06 = lhradixarray_scale;return;}
		else if (index <  8) {lhradixarray_code07 = lhradixarray_code;lhradixarray_scale07 = lhradixarray_scale;return;}
		else if (index <  9) {lhradixarray_code08 = lhradixarray_code;lhradixarray_scale08 = lhradixarray_scale;return;}
		else if (index < 10) {lhradixarray_code09 = lhradixarray_code;lhradixarray_scale09 = lhradixarray_scale;return;}
		else if (index < 11) {lhradixarray_code10 = lhradixarray_code;lhradixarray_scale10 = lhradixarray_scale;return;}
		else if (index < 12) {lhradixarray_code11 = lhradixarray_code;lhradixarray_scale11 = lhradixarray_scale;return;}
		else if (index < 13) {lhradixarray_code12 = lhradixarray_code;lhradixarray_scale12 = lhradixarray_scale;return;}
		else if (index < 14) {lhradixarray_code13 = lhradixarray_code;lhradixarray_scale13 = lhradixarray_scale;return;}
		else if (index < 15) {lhradixarray_code14 = lhradixarray_code;lhradixarray_scale14 = lhradixarray_scale;return;}
		else                 {lhradixarray_code15 = lhradixarray_code;lhradixarray_scale15 = lhradixarray_scale;return;}
	}
	else if (index < 32)
	{
		// 16-32
			 if (index < 17) {lhradixarray_code16 = lhradixarray_code;lhradixarray_scale16 = lhradixarray_scale;return;}
		else if (index < 18) {lhradixarray_code17 = lhradixarray_code;lhradixarray_scale17 = lhradixarray_scale;return;}
		else if (index < 19) {lhradixarray_code18 = lhradixarray_code;lhradixarray_scale18 = lhradixarray_scale;return;}
		else if (index < 20) {lhradixarray_code19 = lhradixarray_code;lhradixarray_scale19 = lhradixarray_scale;return;}
		else if (index < 21) {lhradixarray_code20 = lhradixarray_code;lhradixarray_scale20 = lhradixarray_scale;return;}
		else if (index < 22) {lhradixarray_code21 = lhradixarray_code;lhradixarray_scale21 = lhradixarray_scale;return;}
		else if (index < 23) {lhradixarray_code22 = lhradixarray_code;lhradixarray_scale22 = lhradixarray_scale;return;}
		else if (index < 24) {lhradixarray_code23 = lhradixarray_code;lhradixarray_scale23 = lhradixarray_scale;return;}
		else if (index < 25) {lhradixarray_code24 = lhradixarray_code;lhradixarray_scale24 = lhradixarray_scale;return;}
		else if (index < 26) {lhradixarray_code25 = lhradixarray_code;lhradixarray_scale25 = lhradixarray_scale;return;}
		else if (index < 27) {lhradixarray_code26 = lhradixarray_code;lhradixarray_scale26 = lhradixarray_scale;return;}
		else if (index < 28) {lhradixarray_code27 = lhradixarray_code;lhradixarray_scale27 = lhradixarray_scale;return;}
		else if (index < 29) {lhradixarray_code28 = lhradixarray_code;lhradixarray_scale28 = lhradixarray_scale;return;}
		else if (index < 30) {lhradixarray_code29 = lhradixarray_code;lhradixarray_scale29 = lhradixarray_scale;return;}
		else if (index < 31) {lhradixarray_code30 = lhradixarray_code;lhradixarray_scale30 = lhradixarray_scale;return;}
		else                 {lhradixarray_code31 = lhradixarray_code;lhradixarray_scale31 = lhradixarray_scale;return;}
	}
	else if (index < 48)
	{
		// 32-48
			 if (index < 33) {lhradixarray_code32 = lhradixarray_code;lhradixarray_scale32 = lhradixarray_scale;return;}
		else if (index < 34) {lhradixarray_code33 = lhradixarray_code;lhradixarray_scale33 = lhradixarray_scale;return;}
		else if (index < 35) {lhradixarray_code34 = lhradixarray_code;lhradixarray_scale34 = lhradixarray_scale;return;}
		else if (index < 36) {lhradixarray_code35 = lhradixarray_code;lhradixarray_scale35 = lhradixarray_scale;return;}
		else if (index < 37) {lhradixarray_code36 = lhradixarray_code;lhradixarray_scale36 = lhradixarray_scale;return;}
		else if (index < 38) {lhradixarray_code37 = lhradixarray_code;lhradixarray_scale37 = lhradixarray_scale;return;}
		else if (index < 39) {lhradixarray_code38 = lhradixarray_code;lhradixarray_scale38 = lhradixarray_scale;return;}
		else if (index < 40) {lhradixarray_code39 = lhradixarray_code;lhradixarray_scale39 = lhradixarray_scale;return;}
		else if (index < 41) {lhradixarray_code40 = lhradixarray_code;lhradixarray_scale40 = lhradixarray_scale;return;}
		else if (index < 42) {lhradixarray_code41 = lhradixarray_code;lhradixarray_scale41 = lhradixarray_scale;return;}
		else if (index < 43) {lhradixarray_code42 = lhradixarray_code;lhradixarray_scale42 = lhradixarray_scale;return;}
		else if (index < 44) {lhradixarray_code43 = lhradixarray_code;lhradixarray_scale43 = lhradixarray_scale;return;}
		else if (index < 45) {lhradixarray_code44 = lhradixarray_code;lhradixarray_scale44 = lhradixarray_scale;return;}
		else if (index < 46) {lhradixarray_code45 = lhradixarray_code;lhradixarray_scale45 = lhradixarray_scale;return;}
		else if (index < 47) {lhradixarray_code46 = lhradixarray_code;lhradixarray_scale46 = lhradixarray_scale;return;}
		else                 {lhradixarray_code47 = lhradixarray_code;lhradixarray_scale47 = lhradixarray_scale;return;}
	}
	else if (index < 64)
	{
		// 48-64
			 if (index < 49) {lhradixarray_code48 = lhradixarray_code;lhradixarray_scale48 = lhradixarray_scale;return;}
		else if (index < 50) {lhradixarray_code49 = lhradixarray_code;lhradixarray_scale49 = lhradixarray_scale;return;}
		else if (index < 51) {lhradixarray_code50 = lhradixarray_code;lhradixarray_scale50 = lhradixarray_scale;return;}
		else if (index < 52) {lhradixarray_code51 = lhradixarray_code;lhradixarray_scale51 = lhradixarray_scale;return;}
		else if (index < 53) {lhradixarray_code52 = lhradixarray_code;lhradixarray_scale52 = lhradixarray_scale;return;}
		else if (index < 54) {lhradixarray_code53 = lhradixarray_code;lhradixarray_scale53 = lhradixarray_scale;return;}
		else if (index < 55) {lhradixarray_code54 = lhradixarray_code;lhradixarray_scale54 = lhradixarray_scale;return;}
		else if (index < 56) {lhradixarray_code55 = lhradixarray_code;lhradixarray_scale55 = lhradixarray_scale;return;}
		else if (index < 57) {lhradixarray_code56 = lhradixarray_code;lhradixarray_scale56 = lhradixarray_scale;return;}
		else if (index < 58) {lhradixarray_code57 = lhradixarray_code;lhradixarray_scale57 = lhradixarray_scale;return;}
		else if (index < 59) {lhradixarray_code58 = lhradixarray_code;lhradixarray_scale58 = lhradixarray_scale;return;}
		else if (index < 60) {lhradixarray_code59 = lhradixarray_code;lhradixarray_scale59 = lhradixarray_scale;return;}
		else if (index < 61) {lhradixarray_code60 = lhradixarray_code;lhradixarray_scale60 = lhradixarray_scale;return;}
		else if (index < 62) {lhradixarray_code61 = lhradixarray_code;lhradixarray_scale61 = lhradixarray_scale;return;}
		else if (index < 63) {lhradixarray_code62 = lhradixarray_code;lhradixarray_scale62 = lhradixarray_scale;return;}
		else                 {lhradixarray_code63 = lhradixarray_code;lhradixarray_scale63 = lhradixarray_scale;return;}
	}
};

void() dprint_lhradixarray =
{
	local float index;
	index = 0;
	while (index < lhradixarray_numcodes)
	{
		lhradixarray_load(index);
		dprint(" n");
		dprint(ftos(index));
		dprint("=");
		dprint(ftos(lhradixarray_scale));
		dprint(":");
		dprint(ftos(lhradixarray_code));
		index = index + 1;
	}
	dprint("\n");
};

void() lhradixarray_begin =
{
	//dprint("begin();\n");
	//dprint_lhradixarray();
};

void() lhradixarray_finish =
{
	//dprint("finish();\n");
	//dprint_lhradixarray();
};

// returns TRUE if the number fit into the buffer, FALSE if it did not.
float(float n, float radix) lhradixarray_encode =
{
	local float index, bestindex, bestscale;
	//dprint("encode(");
	//dprint(ftos(n));
	//dprint(", ");
	//dprint(ftos(radix));
	//dprint(") == ");
	// search for the tightest fit
	// for example this tries to pack radix 2 into a code with scale 2
	// remaining space
	index = 0;
	bestindex = -1;
	while (index < lhradixarray_numcodes)
	{
		lhradixarray_load(index);
		if (lhradixarray_scale >= radix)
		if (bestindex < 0 || bestscale > lhradixarray_scale)
		{
			bestindex = index;
			bestscale = lhradixarray_scale;
			if (bestscale == radix)
				break;
		}
		index = index + 1;
	}
	if (bestindex >= 0)
	{
		lhradixarray_load(bestindex);
		lhradixarray_scale = floor(lhradixarray_scale / radix);
		lhradixarray_code = lhradixarray_code + n * lhradixarray_scale;
		lhradixarray_store(bestindex);
		//dprint("TRUE;\n");
		//dprint_lhradixarray();
		return TRUE;
	}
	else
	{
		//dprint("FALSE;\n");
		return FALSE;
	}
};

float(float radix) lhradixarray_decode =
{
	local float index, bestindex, bestscale;
	local float n;
	//dprint("decode(");
	//dprint(ftos(radix));
	//dprint(") == ");
	// search for the tightest fit
	// for example this tries to pack radix 2 into a code with scale 2
	// remaining space
	index = 0;
	bestindex = -1;
	n = 0;
	while (index < lhradixarray_numcodes)
	{
		lhradixarray_load(index);
		if (lhradixarray_scale >= radix)
		if (bestindex < 0 || bestscale > lhradixarray_scale)
		{
			bestindex = index;
			bestscale = lhradixarray_scale;
			if (bestscale == radix)
				break;
		}
		index = index + 1;
	}
	if (bestindex >= 0)
	{
		lhradixarray_load(bestindex);
		lhradixarray_scale = floor(lhradixarray_scale / radix);
		n = floor(lhradixarray_code / lhradixarray_scale);
		lhradixarray_code = lhradixarray_code - n * lhradixarray_scale;
		lhradixarray_store(bestindex);
	}
	//dprint(ftos(n));
	//dprint(";\n");
	//dprint_lhradixarray();
	return n;
};

// returns TRUE if the number fit into the buffer, FALSE if it did not.
float(float n, float radix) lhradixarray_encode_firstmatch =
{
	local float index;
	//dprint("encode(");
	//dprint(ftos(n));
	//dprint(", ");
	//dprint(ftos(radix));
	//dprint(") == ");
	// search for the tightest fit
	// for example this tries to pack radix 2 into a code with scale 2
	// remaining space
	index = 0;
	while (index < lhradixarray_numcodes)
	{
		lhradixarray_load(index);
		if (lhradixarray_scale >= radix)
		{
			lhradixarray_scale = floor(lhradixarray_scale / radix);
			lhradixarray_code = lhradixarray_code + n * lhradixarray_scale;
			lhradixarray_store(index);
			//dprint("TRUE;\n");
			//dprint_lhradixarray();
			return TRUE;
		}
		index = index + 1;
	}
	//dprint("FALSE;\n");
	return FALSE;
};

float(float radix) lhradixarray_decode_firstmatch =
{
	local float index, n;
	//dprint("decode(");
	//dprint(ftos(radix));
	//dprint(") == ");
	// search for the tightest fit
	// for example this tries to pack radix 2 into a code with scale 2
	// remaining space
	index = 0;
	n = 0;
	while (index < lhradixarray_numcodes)
	{
		lhradixarray_load(index);
		if (lhradixarray_scale >= radix)
		{
			lhradixarray_scale = floor(lhradixarray_scale / radix);
			n = floor(lhradixarray_code / lhradixarray_scale);
			lhradixarray_code = lhradixarray_code - n * lhradixarray_scale;
			lhradixarray_store(index);
			break;
		}
		index = index + 1;
	}
	//dprint(ftos(n));
	//dprint(";\n");
	//dprint_lhradixarray();
	return n;
};

// returns TRUE if the number fit into the buffer, FALSE if it did not.
float(float n, float radix) lhradixarray_encode2 =
{
	// write least significant bits until the radix becomes an odd number
	while (!(radix & 1))
	{
		if (!lhradixarray_encode_firstmatch(n & 1, 2))
			return FALSE;
		n = (n - (n & 1)) * 0.5;
		radix = radix * 0.5;
	}
	if (radix >= 2)
	{
		if (!lhradixarray_encode_firstmatch(n, radix))
			return FALSE;
	}
	return TRUE; // FIXME: failure not handled properly
};

float(float radix) lhradixarray_decode2 =
{
	local float n, s;
	n = 0;
	s = 1;
	// read least significant bits until the radix becomes an odd number
	while (!(radix & 1))
	{
		n = n * 2 + lhradixarray_decode_firstmatch(2);
		radix = radix * 0.5;
		s = s * 2;
	}
	if (radix >= 2)
		return n + lhradixarray_decode_firstmatch(radix) * s;
};

// returns TRUE if the number fit into the buffer, FALSE if it did not.
float(float n, float radix) lhradixarray_encodebits =
{
	local float index;
	index = 0;
	// write bits (in msb to lsb order)
	while (radix & (radix - 1))
		radix = radix + 1;
	radix = radix * 0.5;
	while (radix >= 1)
	{
		while (1)
		{
			if (index >= lhradixarray_numcodes)
				return FALSE;
			lhradixarray_load(index);
			if (lhradixarray_scale >= 2)
				break;
			index = index + 1;
		}
		// make sure the scale is a power of 2
		while (lhradixarray_scale & (lhradixarray_scale - 1))
			lhradixarray_scale = lhradixarray_scale - 1;
		lhradixarray_scale = lhradixarray_scale * 0.5;
		if (n & radix)
			lhradixarray_code = lhradixarray_code + lhradixarray_scale;
		lhradixarray_store(index);
		radix = radix * 0.5;
	}
	return TRUE; // FIXME: failure not handled properly
};

float(float radix) lhradixarray_decodebits =
{
	local float index, n;
	index = 0;
	n = 0;
	// read bits (in msb to lsb order)
	while (radix & (radix - 1))
		radix = radix + 1;
	radix = radix * 0.5;
	while (radix >= 1)
	{
		while (1)
		{
			if (index >= lhradixarray_numcodes)
				return 0;
			lhradixarray_load(index);
			if (lhradixarray_scale >= 2)
				break;
			index = index + 1;
		}
		// make the scale a power of 2
		while (lhradixarray_scale & (lhradixarray_scale - 1))
			lhradixarray_scale = lhradixarray_scale - 1;
		lhradixarray_scale = lhradixarray_scale * 0.5;
		if (lhradixarray_code >= lhradixarray_scale)
		{
			lhradixarray_code = lhradixarray_code - lhradixarray_scale;
			n = n + radix;
		}
		lhradixarray_store(index);
		radix = radix * 0.5;
	}
	return n;
};

void() lhradixarrayparms_store =
{
	local float c, f, f0, f1, f2;
	lhradixarray_finish();
	c = 0;
	while (c < 16)
	{
		lhradixarray_load(c * 3 + 0);
		f0 = lhradixarray_code;
		lhradixarray_load(c * 3 + 1);
		f1 = lhradixarray_code;
		lhradixarray_load(c * 3 + 2);
		f2 = lhradixarray_code;
		f = lhfp_encode(f0, f1, f2);
		lhparms_storeparm(c, f);
		c = c + 1;
	}
};

void() lhradixarrayparms_load =
{
	local float c, f, f0, f1, f2;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		f = lhparms_loadparm(c);
		lhfp_decode(f);
		lhradixarray_code = lhfp_code0;
		lhradixarray_scale = 2;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = lhfp_code1;
		lhradixarray_scale = 254;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = lhfp_code2;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms_clear =
{
	local float c;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		lhradixarray_code = 0;
		lhradixarray_scale = 2;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = 0;
		lhradixarray_scale = 254;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = 0;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms_test =
{
	local float c, c2, n0, n1, n2, l;
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
	local string t;
	if (!cvar("developer"))
		bprint("lhradixarray_test called without developer on, the dprints won't be seen.\n");
	lhradixarrayparms_clear();
	c = 2;
	while (lhradixarray_encode(c - 1, c))
		c = c + 1;
	lhradixarrayparms_store();
	dprint("successfully stored radix values from 2 to ");dprint(ftos(c));dprint("\n");
	lhradixarrayparms_load();
	c2 = 2;
	while (c2 < c)
	{
		if (lhradixarray_decode(c2) != c2 - 1) dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhradixarray_finish();
	l = 0;
	while (l < 1)
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
		lhradixarrayparms_clear();
		c0s = lhradixarray_encode(c0c, c0r);
		c1s = lhradixarray_encode(c1c, c1r);
		c2s = lhradixarray_encode(c2c, c2r);
		c3s = lhradixarray_encode(c3c, c3r);
		c4s = lhradixarray_encode(c4c, c4r);
		c5s = lhradixarray_encode(c5c, c5r);
		c6s = lhradixarray_encode(c6c, c6r);
		c7s = lhradixarray_encode(c7c, c7r);
		c8s = lhradixarray_encode(c8c, c8r);
		c9s = lhradixarray_encode(c9c, c9r);
		cas = lhradixarray_encode(cac, car);
		cbs = lhradixarray_encode(cbc, cbr);
		ccs = lhradixarray_encode(ccc, ccr);
		cds = lhradixarray_encode(cdc, cdr);
		ces = lhradixarray_encode(cec, cer);
		cfs = lhradixarray_encode(cfc, cfr);
		lhradixarrayparms_store();
		lhradixarrayparms_load();
		if (c0s) if (lhradixarray_decode(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhradixarray_decode(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhradixarray_decode(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhradixarray_decode(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhradixarray_decode(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhradixarray_decode(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhradixarray_decode(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhradixarray_decode(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhradixarray_decode(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhradixarray_decode(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhradixarray_decode(car) != cac) dprint("decode error\n");
		if (cbs) if (lhradixarray_decode(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhradixarray_decode(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhradixarray_decode(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhradixarray_decode(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhradixarray_decode(cfr) != cfc) dprint("decode error\n");
		lhradixarray_finish();
	}
};

void() lhradixarrayparms2_store =
{
	local float c, f, f01, f2;
	lhradixarray_finish();
	c = 0;
	while (c < 16)
	{
		lhradixarray_load(c * 2 + 0);
		f01 = lhradixarray_code;
		lhradixarray_load(c * 2 + 1);
		f2 = lhradixarray_code;
		f = lhfp2_encode(f01, f2);
		lhparms_storeparm(c, f);
		c = c + 1;
	}
};

void() lhradixarrayparms2_load =
{
	local float c, f, f0, f1, f2;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		f = lhparms_loadparm(c);
		lhfp2_decode(f);
		lhradixarray_code = lhfp2_code01;
		lhradixarray_scale = 508;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = lhfp2_code2;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms2_clear =
{
	local float c;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		lhradixarray_code = 0;
		lhradixarray_scale = 508;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = 0;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms2_test =
{
	local float c, c2, n0, n1, n2, l;
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
	local string t;
	if (!cvar("developer"))
		bprint("lhradixarray2_test called without developer on, the dprints won't be seen.\n");
	lhradixarrayparms2_clear();
	c = 2;
	while (lhradixarray_encode(c - 1, c))
		c = c + 1;
	lhradixarrayparms2_store();
	dprint("successfully stored radix values from 2 to ");dprint(ftos(c));dprint("\n");
	lhradixarrayparms2_load();
	c2 = 2;
	while (c2 < c)
	{
		if (lhradixarray_decode(c2) != c2 - 1) dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhradixarray_finish();
	l = 0;
	while (l < 1)
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
		lhradixarrayparms2_clear();
		c0s = lhradixarray_encode(c0c, c0r);
		c1s = lhradixarray_encode(c1c, c1r);
		c2s = lhradixarray_encode(c2c, c2r);
		c3s = lhradixarray_encode(c3c, c3r);
		c4s = lhradixarray_encode(c4c, c4r);
		c5s = lhradixarray_encode(c5c, c5r);
		c6s = lhradixarray_encode(c6c, c6r);
		c7s = lhradixarray_encode(c7c, c7r);
		c8s = lhradixarray_encode(c8c, c8r);
		c9s = lhradixarray_encode(c9c, c9r);
		cas = lhradixarray_encode(cac, car);
		cbs = lhradixarray_encode(cbc, cbr);
		ccs = lhradixarray_encode(ccc, ccr);
		cds = lhradixarray_encode(cdc, cdr);
		ces = lhradixarray_encode(cec, cer);
		cfs = lhradixarray_encode(cfc, cfr);
		lhradixarrayparms2_store();
		lhradixarrayparms2_load();
		if (c0s) if (lhradixarray_decode(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhradixarray_decode(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhradixarray_decode(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhradixarray_decode(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhradixarray_decode(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhradixarray_decode(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhradixarray_decode(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhradixarray_decode(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhradixarray_decode(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhradixarray_decode(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhradixarray_decode(car) != cac) dprint("decode error\n");
		if (cbs) if (lhradixarray_decode(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhradixarray_decode(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhradixarray_decode(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhradixarray_decode(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhradixarray_decode(cfr) != cfc) dprint("decode error\n");
		lhradixarray_finish();
	}
};

void() lhradixarrayparms3_store =
{
	local float c, f, f01, f2;
	lhradixarray_finish();
	c = 0;
	while (c < 16)
	{
		lhradixarray_load(c * 2 + 0);
		f01 = lhradixarray_code;
		lhradixarray_load(c * 2 + 1);
		f2 = lhradixarray_code;
		f = lhfp2_encode(f01, f2);
		lhparms_storeparm(c, f);
		c = c + 1;
	}
};

void() lhradixarrayparms3_load =
{
	local float c, f, f0, f1, f2;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		f = lhparms_loadparm(c);
		lhfp2_decode(f);
		lhradixarray_code = lhfp2_code01;
		lhradixarray_scale = 508;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = lhfp2_code2;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms3_clear =
{
	local float c;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		lhradixarray_code = 0;
		lhradixarray_scale = 508;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = 0;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms3_test =
{
	local float c, c2, n0, n1, n2, l;
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
	local string t;
	if (!cvar("developer"))
		bprint("lhradixarrayparms3_test called without developer on, the dprints won't be seen.\n");
	lhradixarrayparms3_clear();
	c = 2;
	while (lhradixarray_encode2(c - 1, c))
		c = c + 1;
	lhradixarrayparms3_store();
	dprint("successfully stored radix values from 2 to ");dprint(ftos(c));dprint("\n");
	lhradixarrayparms3_load();
	c2 = 2;
	while (c2 < c)
	{
		if (lhradixarray_decode2(c2) != c2 - 1) dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhradixarray_finish();
	l = 0;
	while (l < 1)
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
		lhradixarrayparms3_clear();
		c0s = lhradixarray_encode2(c0c, c0r);
		c1s = lhradixarray_encode2(c1c, c1r);
		c2s = lhradixarray_encode2(c2c, c2r);
		c3s = lhradixarray_encode2(c3c, c3r);
		c4s = lhradixarray_encode2(c4c, c4r);
		c5s = lhradixarray_encode2(c5c, c5r);
		c6s = lhradixarray_encode2(c6c, c6r);
		c7s = lhradixarray_encode2(c7c, c7r);
		c8s = lhradixarray_encode2(c8c, c8r);
		c9s = lhradixarray_encode2(c9c, c9r);
		cas = lhradixarray_encode2(cac, car);
		cbs = lhradixarray_encode2(cbc, cbr);
		ccs = lhradixarray_encode2(ccc, ccr);
		cds = lhradixarray_encode2(cdc, cdr);
		ces = lhradixarray_encode2(cec, cer);
		cfs = lhradixarray_encode2(cfc, cfr);
		lhradixarrayparms3_store();
		lhradixarrayparms3_load();
		if (c0s) if (lhradixarray_decode2(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhradixarray_decode2(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhradixarray_decode2(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhradixarray_decode2(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhradixarray_decode2(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhradixarray_decode2(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhradixarray_decode2(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhradixarray_decode2(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhradixarray_decode2(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhradixarray_decode2(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhradixarray_decode2(car) != cac) dprint("decode error\n");
		if (cbs) if (lhradixarray_decode2(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhradixarray_decode2(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhradixarray_decode2(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhradixarray_decode2(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhradixarray_decode2(cfr) != cfc) dprint("decode error\n");
		lhradixarray_finish();
	}
};

void() lhradixarrayparms4_store =
{
	local float c, f, f01, f2;
	lhradixarray_finish();
	c = 0;
	while (c < 16)
	{
		lhradixarray_load(c * 2 + 0);
		f01 = lhradixarray_code;
		lhradixarray_load(c * 2 + 1);
		f2 = lhradixarray_code;
		f = lhfp2_encode(f01, f2);
		lhparms_storeparm(c, f);
		c = c + 1;
	}
};

void() lhradixarrayparms4_load =
{
	local float c, f, f0, f1, f2;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		f = lhparms_loadparm(c);
		lhfp2_decode(f);
		lhradixarray_code = lhfp2_code01;
		lhradixarray_scale = 508;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = lhfp2_code2;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms4_clear =
{
	local float c;
	lhradixarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		lhradixarray_code = 0;
		lhradixarray_scale = 508;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		lhradixarray_code = 0;
		lhradixarray_scale = 8388608;
		lhradixarray_store(lhradixarray_numcodes);
		lhradixarray_numcodes = lhradixarray_numcodes + 1;
		c = c + 1;
	}
	lhradixarray_begin();
};

void() lhradixarrayparms4_test =
{
	local float c, c2, n0, n1, n2, l;
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
	local string t;
	if (!cvar("developer"))
		bprint("lhradixarrayparms4_test called without developer on, the dprints won't be seen.\n");
	lhradixarrayparms4_clear();
	c = 2;
	while (lhradixarray_encodebits(c - 1, c))
		c = c + 1;
	lhradixarrayparms4_store();
	dprint("successfully stored radix values from 2 to ");dprint(ftos(c));dprint("\n");
	lhradixarrayparms4_load();
	c2 = 2;
	while (c2 < c)
	{
		if (lhradixarray_decodebits(c2) != c2 - 1) dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhradixarray_finish();
	l = 0;
	while (l < 1)
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
		lhradixarrayparms4_clear();
		c0s = lhradixarray_encodebits(c0c, c0r);
		c1s = lhradixarray_encodebits(c1c, c1r);
		c2s = lhradixarray_encodebits(c2c, c2r);
		c3s = lhradixarray_encodebits(c3c, c3r);
		c4s = lhradixarray_encodebits(c4c, c4r);
		c5s = lhradixarray_encodebits(c5c, c5r);
		c6s = lhradixarray_encodebits(c6c, c6r);
		c7s = lhradixarray_encodebits(c7c, c7r);
		c8s = lhradixarray_encodebits(c8c, c8r);
		c9s = lhradixarray_encodebits(c9c, c9r);
		cas = lhradixarray_encodebits(cac, car);
		cbs = lhradixarray_encodebits(cbc, cbr);
		ccs = lhradixarray_encodebits(ccc, ccr);
		cds = lhradixarray_encodebits(cdc, cdr);
		ces = lhradixarray_encodebits(cec, cer);
		cfs = lhradixarray_encodebits(cfc, cfr);
		lhradixarrayparms4_store();
		lhradixarrayparms4_load();
		if (c0s) if (lhradixarray_decodebits(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhradixarray_decodebits(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhradixarray_decodebits(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhradixarray_decodebits(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhradixarray_decodebits(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhradixarray_decodebits(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhradixarray_decodebits(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhradixarray_decodebits(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhradixarray_decodebits(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhradixarray_decodebits(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhradixarray_decodebits(car) != cac) dprint("decode error\n");
		if (cbs) if (lhradixarray_decodebits(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhradixarray_decodebits(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhradixarray_decodebits(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhradixarray_decodebits(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhradixarray_decodebits(cfr) != cfc) dprint("decode error\n");
		lhradixarray_finish();
	}
};

float lhbitarray_numcodes;
float lhbitarray_index;
float lhbitarray_code, lhbitarray_scale;
float lhbitarray_code00, lhbitarray_scale00;
float lhbitarray_code01, lhbitarray_scale01;
float lhbitarray_code02, lhbitarray_scale02;
float lhbitarray_code03, lhbitarray_scale03;
float lhbitarray_code04, lhbitarray_scale04;
float lhbitarray_code05, lhbitarray_scale05;
float lhbitarray_code06, lhbitarray_scale06;
float lhbitarray_code07, lhbitarray_scale07;
float lhbitarray_code08, lhbitarray_scale08;
float lhbitarray_code09, lhbitarray_scale09;
float lhbitarray_code10, lhbitarray_scale10;
float lhbitarray_code11, lhbitarray_scale11;
float lhbitarray_code12, lhbitarray_scale12;
float lhbitarray_code13, lhbitarray_scale13;
float lhbitarray_code14, lhbitarray_scale14;
float lhbitarray_code15, lhbitarray_scale15;
float lhbitarray_code16, lhbitarray_scale16;
float lhbitarray_code17, lhbitarray_scale17;
float lhbitarray_code18, lhbitarray_scale18;
float lhbitarray_code19, lhbitarray_scale19;
float lhbitarray_code20, lhbitarray_scale20;
float lhbitarray_code21, lhbitarray_scale21;
float lhbitarray_code22, lhbitarray_scale22;
float lhbitarray_code23, lhbitarray_scale23;
float lhbitarray_code24, lhbitarray_scale24;
float lhbitarray_code25, lhbitarray_scale25;
float lhbitarray_code26, lhbitarray_scale26;
float lhbitarray_code27, lhbitarray_scale27;
float lhbitarray_code28, lhbitarray_scale28;
float lhbitarray_code29, lhbitarray_scale29;
float lhbitarray_code30, lhbitarray_scale30;
float lhbitarray_code31, lhbitarray_scale31;

void(float index) lhbitarray_load =
{
	if (index < 16)
	{
		// 0-16
			 if (index <  1) {lhbitarray_code = lhbitarray_code00;lhbitarray_scale = lhbitarray_scale00;return;}
		else if (index <  2) {lhbitarray_code = lhbitarray_code01;lhbitarray_scale = lhbitarray_scale01;return;}
		else if (index <  3) {lhbitarray_code = lhbitarray_code02;lhbitarray_scale = lhbitarray_scale02;return;}
		else if (index <  4) {lhbitarray_code = lhbitarray_code03;lhbitarray_scale = lhbitarray_scale03;return;}
		else if (index <  5) {lhbitarray_code = lhbitarray_code04;lhbitarray_scale = lhbitarray_scale04;return;}
		else if (index <  6) {lhbitarray_code = lhbitarray_code05;lhbitarray_scale = lhbitarray_scale05;return;}
		else if (index <  7) {lhbitarray_code = lhbitarray_code06;lhbitarray_scale = lhbitarray_scale06;return;}
		else if (index <  8) {lhbitarray_code = lhbitarray_code07;lhbitarray_scale = lhbitarray_scale07;return;}
		else if (index <  9) {lhbitarray_code = lhbitarray_code08;lhbitarray_scale = lhbitarray_scale08;return;}
		else if (index < 10) {lhbitarray_code = lhbitarray_code09;lhbitarray_scale = lhbitarray_scale09;return;}
		else if (index < 11) {lhbitarray_code = lhbitarray_code10;lhbitarray_scale = lhbitarray_scale10;return;}
		else if (index < 12) {lhbitarray_code = lhbitarray_code11;lhbitarray_scale = lhbitarray_scale11;return;}
		else if (index < 13) {lhbitarray_code = lhbitarray_code12;lhbitarray_scale = lhbitarray_scale12;return;}
		else if (index < 14) {lhbitarray_code = lhbitarray_code13;lhbitarray_scale = lhbitarray_scale13;return;}
		else if (index < 15) {lhbitarray_code = lhbitarray_code14;lhbitarray_scale = lhbitarray_scale14;return;}
		else                 {lhbitarray_code = lhbitarray_code15;lhbitarray_scale = lhbitarray_scale15;return;}
	}
	else if (index < 32)
	{
		// 16-32
			 if (index < 17) {lhbitarray_code = lhbitarray_code16;lhbitarray_scale = lhbitarray_scale16;return;}
		else if (index < 18) {lhbitarray_code = lhbitarray_code17;lhbitarray_scale = lhbitarray_scale17;return;}
		else if (index < 19) {lhbitarray_code = lhbitarray_code18;lhbitarray_scale = lhbitarray_scale18;return;}
		else if (index < 20) {lhbitarray_code = lhbitarray_code19;lhbitarray_scale = lhbitarray_scale19;return;}
		else if (index < 21) {lhbitarray_code = lhbitarray_code20;lhbitarray_scale = lhbitarray_scale20;return;}
		else if (index < 22) {lhbitarray_code = lhbitarray_code21;lhbitarray_scale = lhbitarray_scale21;return;}
		else if (index < 23) {lhbitarray_code = lhbitarray_code22;lhbitarray_scale = lhbitarray_scale22;return;}
		else if (index < 24) {lhbitarray_code = lhbitarray_code23;lhbitarray_scale = lhbitarray_scale23;return;}
		else if (index < 25) {lhbitarray_code = lhbitarray_code24;lhbitarray_scale = lhbitarray_scale24;return;}
		else if (index < 26) {lhbitarray_code = lhbitarray_code25;lhbitarray_scale = lhbitarray_scale25;return;}
		else if (index < 27) {lhbitarray_code = lhbitarray_code26;lhbitarray_scale = lhbitarray_scale26;return;}
		else if (index < 28) {lhbitarray_code = lhbitarray_code27;lhbitarray_scale = lhbitarray_scale27;return;}
		else if (index < 29) {lhbitarray_code = lhbitarray_code28;lhbitarray_scale = lhbitarray_scale28;return;}
		else if (index < 30) {lhbitarray_code = lhbitarray_code29;lhbitarray_scale = lhbitarray_scale29;return;}
		else if (index < 31) {lhbitarray_code = lhbitarray_code30;lhbitarray_scale = lhbitarray_scale30;return;}
		else                 {lhbitarray_code = lhbitarray_code31;lhbitarray_scale = lhbitarray_scale31;return;}
	}
};

void(float index) lhbitarray_store =
{
	if (index < 16)
	{
		// 0-16
			 if (index <  1) {lhbitarray_code00 = lhbitarray_code;lhbitarray_scale00 = lhbitarray_scale;return;}
		else if (index <  2) {lhbitarray_code01 = lhbitarray_code;lhbitarray_scale01 = lhbitarray_scale;return;}
		else if (index <  3) {lhbitarray_code02 = lhbitarray_code;lhbitarray_scale02 = lhbitarray_scale;return;}
		else if (index <  4) {lhbitarray_code03 = lhbitarray_code;lhbitarray_scale03 = lhbitarray_scale;return;}
		else if (index <  5) {lhbitarray_code04 = lhbitarray_code;lhbitarray_scale04 = lhbitarray_scale;return;}
		else if (index <  6) {lhbitarray_code05 = lhbitarray_code;lhbitarray_scale05 = lhbitarray_scale;return;}
		else if (index <  7) {lhbitarray_code06 = lhbitarray_code;lhbitarray_scale06 = lhbitarray_scale;return;}
		else if (index <  8) {lhbitarray_code07 = lhbitarray_code;lhbitarray_scale07 = lhbitarray_scale;return;}
		else if (index <  9) {lhbitarray_code08 = lhbitarray_code;lhbitarray_scale08 = lhbitarray_scale;return;}
		else if (index < 10) {lhbitarray_code09 = lhbitarray_code;lhbitarray_scale09 = lhbitarray_scale;return;}
		else if (index < 11) {lhbitarray_code10 = lhbitarray_code;lhbitarray_scale10 = lhbitarray_scale;return;}
		else if (index < 12) {lhbitarray_code11 = lhbitarray_code;lhbitarray_scale11 = lhbitarray_scale;return;}
		else if (index < 13) {lhbitarray_code12 = lhbitarray_code;lhbitarray_scale12 = lhbitarray_scale;return;}
		else if (index < 14) {lhbitarray_code13 = lhbitarray_code;lhbitarray_scale13 = lhbitarray_scale;return;}
		else if (index < 15) {lhbitarray_code14 = lhbitarray_code;lhbitarray_scale14 = lhbitarray_scale;return;}
		else                 {lhbitarray_code15 = lhbitarray_code;lhbitarray_scale15 = lhbitarray_scale;return;}
	}
	else if (index < 32)
	{
		// 16-32
			 if (index < 17) {lhbitarray_code16 = lhbitarray_code;lhbitarray_scale16 = lhbitarray_scale;return;}
		else if (index < 18) {lhbitarray_code17 = lhbitarray_code;lhbitarray_scale17 = lhbitarray_scale;return;}
		else if (index < 19) {lhbitarray_code18 = lhbitarray_code;lhbitarray_scale18 = lhbitarray_scale;return;}
		else if (index < 20) {lhbitarray_code19 = lhbitarray_code;lhbitarray_scale19 = lhbitarray_scale;return;}
		else if (index < 21) {lhbitarray_code20 = lhbitarray_code;lhbitarray_scale20 = lhbitarray_scale;return;}
		else if (index < 22) {lhbitarray_code21 = lhbitarray_code;lhbitarray_scale21 = lhbitarray_scale;return;}
		else if (index < 23) {lhbitarray_code22 = lhbitarray_code;lhbitarray_scale22 = lhbitarray_scale;return;}
		else if (index < 24) {lhbitarray_code23 = lhbitarray_code;lhbitarray_scale23 = lhbitarray_scale;return;}
		else if (index < 25) {lhbitarray_code24 = lhbitarray_code;lhbitarray_scale24 = lhbitarray_scale;return;}
		else if (index < 26) {lhbitarray_code25 = lhbitarray_code;lhbitarray_scale25 = lhbitarray_scale;return;}
		else if (index < 27) {lhbitarray_code26 = lhbitarray_code;lhbitarray_scale26 = lhbitarray_scale;return;}
		else if (index < 28) {lhbitarray_code27 = lhbitarray_code;lhbitarray_scale27 = lhbitarray_scale;return;}
		else if (index < 29) {lhbitarray_code28 = lhbitarray_code;lhbitarray_scale28 = lhbitarray_scale;return;}
		else if (index < 30) {lhbitarray_code29 = lhbitarray_code;lhbitarray_scale29 = lhbitarray_scale;return;}
		else if (index < 31) {lhbitarray_code30 = lhbitarray_code;lhbitarray_scale30 = lhbitarray_scale;return;}
		else                 {lhbitarray_code31 = lhbitarray_code;lhbitarray_scale31 = lhbitarray_scale;return;}
	}
};

void() dprint_lhbitarray =
{
	local float index;
	local float c, s;
	index = 0;
	c = lhbitarray_code;
	s = lhbitarray_scale;
	dprint("i");dprint(ftos(lhbitarray_index));
	dprint("/");dprint(ftos(lhbitarray_numcodes));
	while (index < lhbitarray_numcodes)
	{
		lhbitarray_load(index);
		dprint(" n");
		dprint(ftos(index));
		dprint("=");
		if (index == lhbitarray_index)
			dprint(ftos(s));
		else
			dprint(ftos(lhbitarray_scale));
		dprint(":");
		if (index == lhbitarray_index)
			dprint(ftos(c));
		else
			dprint(ftos(lhbitarray_code));
		index = index + 1;
	}
	dprint("\n");
	lhbitarray_code = c;
	lhbitarray_scale = s;
};

void() lhbitarray_dprintcurrent =
{
	dprint("i");dprint(ftos(lhbitarray_index));
	dprint("/");dprint(ftos(lhbitarray_numcodes));
	dprint("=");
	dprint(ftos(lhbitarray_scale));
	dprint(":");
	dprint(ftos(lhbitarray_code));
	dprint("\n");
};

void() lhbitarray_begin =
{
	//dprint("begin();\n");
	lhbitarray_index = 0;
	lhbitarray_load(lhbitarray_index);
	//dprint_lhbitarray();
};

void() lhbitarray_finish =
{
	//dprint("finish();\n");
	lhbitarray_store(lhbitarray_index);
	//dprint_lhbitarray();
};

// returns TRUE if the number fit into the buffer, FALSE if it did not
float(float n, float radix) lhbitarray_encodebits =
{
	//dprint("encodebits(");dprint(ftos(n));
	//dprint(", ");dprint(ftos(radix));
	//dprint(") == ");
	if (lhbitarray_index >= lhbitarray_numcodes)
	{
		//dprint("FALSE;\n");
		return FALSE;
	}
	// make sure radix is a power of 2
	while (radix & (radix - 1))
		radix = radix + 1;
	// write bits (in msb to lsb order)
	radix = radix * 0.5;
	while (radix >= 1)
	{
		while (lhbitarray_scale < 2)
		{
			lhbitarray_store(lhbitarray_index);
			lhbitarray_index = lhbitarray_index + 1;
			if (lhbitarray_index >= lhbitarray_numcodes)
			{
				//dprint("FALSE;\n");
				return FALSE;
			}
			lhbitarray_load(lhbitarray_index);
		}
		do
		{
			lhbitarray_scale = lhbitarray_scale * 0.5;
			if (n >= radix)
			{
				lhbitarray_code = lhbitarray_code + lhbitarray_scale;
				n = n - radix;
			}
			radix = radix * 0.5;
		}
		while (lhbitarray_scale >= 2 && radix >= 1);
	}
	//dprint("TRUE;\n");
	//dprint_lhbitarray();
	return TRUE;
};

// reads a number
float(float radix) lhbitarray_decodebits =
{
	local float n;
	//dprint("decodebits(");dprint(ftos(radix));
	//dprint(") == ");
	if (lhbitarray_index >= lhbitarray_numcodes)
	{
		//dprint("ERROR;\n");
		return 0;
	}
	n = 0;
	// make sure radix is a power of 2
	while (radix & (radix - 1))
		radix = radix + 1;
	// read bits (in msb to lsb order)
	radix = radix * 0.5;
	while (radix >= 1)
	{
		while (lhbitarray_scale < 2)
		{
			lhbitarray_store(lhbitarray_index);
			lhbitarray_index = lhbitarray_index + 1;
			if (lhbitarray_index >= lhbitarray_numcodes)
			{
				//dprint("ERROR;\n");
				return 0;
			}
			lhbitarray_load(lhbitarray_index);
		}
		do
		{
			lhbitarray_scale = lhbitarray_scale * 0.5;
			if (lhbitarray_code >= lhbitarray_scale)
			{
				lhbitarray_code = lhbitarray_code - lhbitarray_scale;
				n = n + radix;
			}
			radix = radix * 0.5;
		}
		while (lhbitarray_scale >= 2 && radix >= 1);
	}
	//dprint(ftos(n));dprint(";\n");
	//dprint_lhbitarray();
	return n;
};

void() lhbitarrayparms_store =
{
	local float c, f, f01, f2;
	lhbitarray_finish();
	c = 0;
	while (c < 16)
	{
		lhbitarray_load(c * 2 + 0);
		f01 = lhbitarray_code;
		lhbitarray_load(c * 2 + 1);
		f2 = lhbitarray_code;
		f = lhfp2_encode(f01, f2);
		lhparms_storeparm(c, f);
		c = c + 1;
	}
};

void() lhbitarrayparms_load =
{
	local float c, f, f0, f1, f2;
	lhbitarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		f = lhparms_loadparm(c);
		lhfp2_decode(f);
		lhbitarray_code = lhfp2_code01;
		lhbitarray_scale = 256;
		lhbitarray_store(lhbitarray_numcodes);
		lhbitarray_numcodes = lhbitarray_numcodes + 1;
		lhbitarray_code = lhfp2_code2;
		lhbitarray_scale = 8388608;
		lhbitarray_store(lhbitarray_numcodes);
		lhbitarray_numcodes = lhbitarray_numcodes + 1;
		c = c + 1;
	}
	lhbitarray_begin();
};

void() lhbitarrayparms_clear =
{
	local float c;
	lhbitarray_numcodes = 0;
	c = 0;
	while (c < 16)
	{
		lhbitarray_code = 0;
		lhbitarray_scale = 256;
		lhbitarray_store(lhbitarray_numcodes);
		lhbitarray_numcodes = lhbitarray_numcodes + 1;
		lhbitarray_code = 0;
		lhbitarray_scale = 8388608;
		lhbitarray_store(lhbitarray_numcodes);
		lhbitarray_numcodes = lhbitarray_numcodes + 1;
		c = c + 1;
	}
	lhbitarray_begin();
};

void() lhbitarrayparms_test =
{
	local float c, c2, n0, n1, n2, l;
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
	local string t;
	if (!cvar("developer"))
		bprint("lhbitarrayparms_test called without developer on, the dprints won't be seen.\n");
	lhbitarrayparms_clear();
	c = 2;
	while (lhbitarray_encodebits(c - 1, c))
		c = c + 1;
	lhbitarrayparms_store();
	dprint("successfully stored radix values from 2 to ");dprint(ftos(c));dprint("\n");
	lhbitarrayparms_load();
	c2 = 2;
	while (c2 < c)
	{
		if (lhbitarray_decodebits(c2) != c2 - 1) dprint("decode error\n");
		c2 = c2 + 1;
	}
	lhbitarray_finish();
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
		lhbitarrayparms_clear();
		c0s = lhbitarray_encodebits(c0c, c0r);
		c1s = lhbitarray_encodebits(c1c, c1r);
		c2s = lhbitarray_encodebits(c2c, c2r);
		c3s = lhbitarray_encodebits(c3c, c3r);
		c4s = lhbitarray_encodebits(c4c, c4r);
		c5s = lhbitarray_encodebits(c5c, c5r);
		c6s = lhbitarray_encodebits(c6c, c6r);
		c7s = lhbitarray_encodebits(c7c, c7r);
		c8s = lhbitarray_encodebits(c8c, c8r);
		c9s = lhbitarray_encodebits(c9c, c9r);
		cas = lhbitarray_encodebits(cac, car);
		cbs = lhbitarray_encodebits(cbc, cbr);
		ccs = lhbitarray_encodebits(ccc, ccr);
		cds = lhbitarray_encodebits(cdc, cdr);
		ces = lhbitarray_encodebits(cec, cer);
		cfs = lhbitarray_encodebits(cfc, cfr);
		lhbitarrayparms_store();
		lhbitarrayparms_load();
		if (c0s) if (lhbitarray_decodebits(c0r) != c0c) dprint("decode error\n");
		if (c1s) if (lhbitarray_decodebits(c1r) != c1c) dprint("decode error\n");
		if (c2s) if (lhbitarray_decodebits(c2r) != c2c) dprint("decode error\n");
		if (c3s) if (lhbitarray_decodebits(c3r) != c3c) dprint("decode error\n");
		if (c4s) if (lhbitarray_decodebits(c4r) != c4c) dprint("decode error\n");
		if (c5s) if (lhbitarray_decodebits(c5r) != c5c) dprint("decode error\n");
		if (c6s) if (lhbitarray_decodebits(c6r) != c6c) dprint("decode error\n");
		if (c7s) if (lhbitarray_decodebits(c7r) != c7c) dprint("decode error\n");
		if (c8s) if (lhbitarray_decodebits(c8r) != c8c) dprint("decode error\n");
		if (c9s) if (lhbitarray_decodebits(c9r) != c9c) dprint("decode error\n");
		if (cas) if (lhbitarray_decodebits(car) != cac) dprint("decode error\n");
		if (cbs) if (lhbitarray_decodebits(cbr) != cbc) dprint("decode error\n");
		if (ccs) if (lhbitarray_decodebits(ccr) != ccc) dprint("decode error\n");
		if (cds) if (lhbitarray_decodebits(cdr) != cdc) dprint("decode error\n");
		if (ces) if (lhbitarray_decodebits(cer) != cec) dprint("decode error\n");
		if (cfs) if (lhbitarray_decodebits(cfr) != cfc) dprint("decode error\n");
		lhbitarray_finish();
	}
};
*/








// traces a curved trajectory (grenades for instance)
// sets the trace info for the last segment (the one which hit something)
// and returns the flight time upto the impact
float(vector org, vector vel, float maxtime, float nomonsters, entity ignore) oldtracetoss =
{
	local   float   c, grav;
	local   vector  v, vel2;
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
vector  findtrajectory_velocity; // calculated direction
float(vector org, vector end, entity targ, float shotspeed, float maxtime, float nomonsters, entity ignore) oldfindtrajectory =
{
	local   float   c;
	local   vector  dir;
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
	local   float   c;
	local   vector  dir, end;
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
float(vector org, vector m1, vector m2, entity targ, float shotspeed, float maxtime, float shotdelay, entity ignore) findtrajectorywithleading =
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
		tracetossent.velocity = findtrajectory_velocity = normalize(dir) * shotspeed;
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

/*
==============================================================================

WIZARD

If the player moves behind cover before the missile is launched, launch it
at the last visible spot with no velocity leading, in hopes that the player
will duck back out and catch it.
==============================================================================
*/

/*
=============
WizardLaunchMissile

Sets the given entities velocity and angles so that it will hit self.enemy
if self.enemy maintains it's current velocity
0.1 is moderately accurate, 0.0 is totally accurate
=============
*/
void(entity missile, float mspeed, float accuracy) WizardLaunchMissile =
{
	local	vector	vec, move;
	local	float	fly;

	makevectors (self.angles);

// set missile speed
	vec = self.enemy.origin + self.enemy.mins + self.enemy.size * 0.7 - missile.origin;

// calc aproximate time for missile to reach vec
	fly = vlen (vec) / mspeed;

// get the entities xy velocity
	move = self.enemy.velocity;
	move_z = 0;

// project the target forward in time
	vec = vec + move * fly;

	vec = normalize(vec);
	vec = vec + accuracy*v_up*(random()- 0.5) + accuracy*v_right*(random()- 0.5);

	missile.velocity = vec * mspeed;

	missile.angles = '0 0 0';
	missile.angles_y = vectoyaw(missile.velocity);

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;
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
	local   float   s;
	s = attacker.solid;
	if (attacker.solid == SOLID_SLIDEBOX)
		attacker.solid = SOLID_BBOX;
	traceline(start, end, noents, attacker);
	if (s == SOLID_SLIDEBOX)
		attacker.solid = s;
};
