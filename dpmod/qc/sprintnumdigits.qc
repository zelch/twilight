float(float num, float digits) padoutnum =
{
	local   float   d;
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
	local   float   d;
	local   string  s;
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
        local   string s;
        s = ftos(n);
        sprint(e, s);
};

