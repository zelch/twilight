.float isdecor;
.float radiusdamage_amount; // damage counter
.vector radiusdamage_force; // direction and power of blast kick
.float radiusdamage_hit; // 1 if it was hit, reset to 0 afterward
.vector radiusdamage_lasthit; // location

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, float radius, entity ignore, string dethtype, float damgtype, void(entity t, entity a, string m, float dtyp) obitfunc) T_RadiusDamage =
{
	local   float   points, points1, wt, d, scaler;
	local   vector  v, l;
	local   entity  head;

	if (pointcontents(inflictor.origin) == CONTENT_SOLID)
	{
		dprint("T_RadiusDamage: inflictor in a solid\n");
		return; // uh, it's in a wall, uh, lets be as sensible as we can in this strange situation...
	}
	wt = pointcontents(inflictor.origin);
	if ((wt != CONTENT_WATER) && (wt != CONTENT_SLIME))
		wt = 0;

	damgtype = damgtype | DTF_INDIRECT; // splash not direct damage

	// first count the damage
	head = findradius(inflictor.origin, radius/* + 64*/);
	while (head)
	{
		if (head.takedamage)
		if (!head.isdecor)
		if (head != ignore)
		{
			points = LinearRadDamage(head, ignore, inflictor.origin, damage, radius, 3);
			if (points > damage)
				points = damage;
			points1 = points;
			if (head == attacker)
				points = points * 0.5;
			if (points >= 1)
			{
				head.radiusdamage_amount = head.radiusdamage_amount + ceil(points);
				head.radiusdamage_force = head.radiusdamage_force + normalize((head.absmin + head.absmax) * 0.5 - inflictor.origin) * points1;
				head.radiusdamage_hit = 1;
				head.radiusdamage_lasthit = raddamage_lasthit;
			}
		}
		head = head.chain;
	}

	// then apply it
	head = findfloat(world, radiusdamage_hit, 1);
	while (head)
	{
		d = head.radiusdamage_amount;
		v = head.radiusdamage_force;
		l = head.radiusdamage_lasthit;
		head.radiusdamage_amount = 0;
		head.radiusdamage_hit = 0;
		head.radiusdamage_force = '0 0 0';
		head.radiusdamage_lasthit = '0 0 0';
		if (d > 0)
			T_Damage (head, inflictor, attacker, d, d, dethtype, damgtype, l, v, obitfunc);
		head = findfloat(head, radiusdamage_hit, 1);
	}

	// now push around gibs and such
	// (such as those made by a corpse which was just gibbed)
	head = findchainfloat(isdecor, TRUE);
	while (head)
	{
		points = LinearRadDamage(head, ignore, inflictor.origin, damage, radius, 1);
		if (points > damage)
			points = damage;
		if (points >= 1)
		{
			head.radiusdamage_amount = head.radiusdamage_amount + ceil(points);
			head.radiusdamage_force = head.radiusdamage_force + normalize((head.absmin + head.absmax) * 0.5 + '0 0 4'- inflictor.origin) * points;
			head.radiusdamage_hit = 1;
			head.radiusdamage_lasthit = raddamage_lasthit;
		}
		head = head.chain;
	}

	// then apply it
	head = findfloat(world, radiusdamage_hit, 1);
	while (head)
	{
		d = head.radiusdamage_amount;
		v = head.radiusdamage_force;
		l = head.radiusdamage_lasthit;
		head.radiusdamage_amount = 0;
		head.radiusdamage_hit = 0;
		head.radiusdamage_force = '0 0 0';
		head.radiusdamage_lasthit = '0 0 0';
		if (d > 0)
			T_Damage (head, inflictor, attacker, d, d, dethtype, damgtype, l, v, obitfunc);
		head = findfloat(head, radiusdamage_hit, 1);
	}
};
