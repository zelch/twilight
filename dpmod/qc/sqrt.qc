
float(float y) sqrt =
{
	local float a, b, t, y, c;

	// initial guess
	a = 0.5 * (y + 1.0);
	// initial reciprocal of guess
	if (a < 1.0)
		b = 2.0;
	else
		b = 0.5;

	c = 0;
	while(c < 14)
	{
		c = c + 1;
		a = 0.5 * (a + y * b);
		t = b * (2.0 - a * b);
		if (t > 0)
			b = t;
		else
			b = b * 0.5;
	}

	return a;
};
