.float isdecor;
.float radiusdamage_amount; // damage counter
.vector radiusdamage_force; // direction and power of blast kick
.float radiusdamage_hit; // 1 if it was hit, reset to 0 afterward
.vector radiusdamage_lasthit; // location
.float radiusdamage_ownerdamagescale; // if set on inflictor this will scale damage to owner (overriding default of 0.5)

/*
============
T_RadiusDamage
============
*/
void(entity inflictor, entity attacker, float damage, float force, float radius, entity ignore, string dethtype, float damgtype, void(entity t, entity a, string m, float dtyp) obitfunc) T_RadiusDamage =
{
	local   float   damagepoints, forcepoints, wt, d, ownerdamagescale;
	local   vector  v, l;
	local   entity  head;

	/*
	traceline(inflictor.origin, inflictor.origin, TRUE, world);
	if (trace_startsolid)
	{
		dprint("T_RadiusDamage: inflictor in a solid\n");
		return; // uh, it's in a wall, uh, lets be as sensible as we can in this strange situation...
	}
	*/
	wt = pointcontents(inflictor.origin);
	if ((wt != CONTENT_WATER) && (wt != CONTENT_SLIME))
		wt = 0;
	ownerdamagescale = inflictor.radiusdamage_ownerdamagescale;
	if (!ownerdamagescale)
		ownerdamagescale = 0.5;

	damgtype = damgtype | DTF_INDIRECT; // splash not direct damage

	// first count the damage
	head = findradius(inflictor.origin, radius + 4);
	while (head)
	{
		if (head.takedamage)
		if (!head.isdecor)
		if (head != ignore)
		{
			damagepoints = LinearRadDamage(head, ignore, inflictor.origin, damage, radius, 3);
			forcepoints = LinearRadDamage(head, ignore, inflictor.origin, force, radius, 3);
			if (damagepoints > damage)
				damagepoints = damage;
			if (head == attacker)
				damagepoints = damagepoints * ownerdamagescale;
			if (forcepoints > force)
				forcepoints = force;
			if (damagepoints > 0 || forcepoints > 0)
			{
				head.radiusdamage_amount = head.radiusdamage_amount + damagepoints;
				head.radiusdamage_force = head.radiusdamage_force + normalize((head.absmin + head.absmax) * 0.5 - inflictor.origin) * forcepoints;
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
		if (d > 0 || v != '0 0 0')
			T_Damage (head, inflictor, attacker, d, d, dethtype, damgtype, l, v, obitfunc);
		head = findfloat(head, radiusdamage_hit, 1);
	}

	// now push around gibs and such
	// (such as those made by a corpse which was just gibbed)
	head = findchainfloat(isdecor, TRUE);
	while (head)
	{
		damagepoints = LinearRadDamage(head, ignore, inflictor.origin, damage, radius, 1);
		forcepoints = LinearRadDamage(head, ignore, inflictor.origin, force, radius, 1);
		if (damagepoints > 0 || forcepoints > 0)
		{
			if (damagepoints > damage)
				damagepoints = damage;
			if (forcepoints > damage)
				forcepoints = damage;
			head.radiusdamage_amount = head.radiusdamage_amount + damagepoints;
			head.radiusdamage_force = head.radiusdamage_force + normalize((head.absmin + head.absmax) * 0.5 + '0 0 4'- inflictor.origin) * forcepoints;
			head.radiusdamage_hit = 1;
			head.radiusdamage_lasthit = raddamage_lasthit;
		}
		head = head.chain;
	}

	// now push around ragdolls
	// (may be a corpse or gibs of what was just killed)
	head = findchain(classname, "ragdoll_particle");
	while (head)
	{
		damagepoints = LinearRadDamage(head, ignore, inflictor.origin, damage, radius, 1);
		forcepoints = LinearRadDamage(head, ignore, inflictor.origin, force, radius, 1);
		if (damagepoints > 0 || forcepoints > 0)
		{
			if (damagepoints > damage)
				damagepoints = damage;
			if (forcepoints > damage)
				forcepoints = damage;
			head.radiusdamage_amount = head.radiusdamage_amount + damagepoints;
			head.radiusdamage_force = head.radiusdamage_force + normalize((head.absmin + head.absmax) * 0.5 + '0 0 4'- inflictor.origin) * forcepoints;
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
		if (d > 0 || v != '0 0 0')
			T_Damage (head, inflictor, attacker, d, d, dethtype, damgtype, l, v, obitfunc);
		head = findfloat(head, radiusdamage_hit, 1);
	}
};
