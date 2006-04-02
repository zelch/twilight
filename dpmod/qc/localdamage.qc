// localdamage stuff (headshots etc)

.float localdamage;
.float localdamage_hit;
.float localdamage_head_z1;
.float localdamage_head_z2;
.float localdamage_head_mul;
.float localdamage_body_z1;
.float localdamage_body_z2;
.float localdamage_body_mul;
// codes for this
.float localdamage_hit;

.vector bodymins, bodymaxs, headmins, headmaxs;

float LD_NORMAL       = 0;
float LD_BODY         = 1;
float LD_HEAD         = 2;

float(vector hitpos, vector direction, entity victim, float damage) localdamage_getdamage =
{
	local float z, tf;
	victim.localdamage_hit = LD_NORMAL;
	// detect local damage?
	if (victim.localdamage)
	{
		if (victim.model == "progs/player.mdl" || victim.model == "progs/eyes.mdl")
		{
			lh_traceagainstbox(hitpos - victim.origin, hitpos + direction * 1000 - victim.origin, victim.bodymins, victim.bodymaxs);
			tf = trace_fraction;
			lh_traceagainstbox(hitpos - victim.origin, hitpos + direction * 1000 - victim.origin, victim.headmins, victim.headmaxs);
			if (trace_fraction < tf) // head
			{
				//dprint("localdamage: head\n");
				victim.localdamage_hit = LD_HEAD;
				//return (damage * victim.localdamage_head_mul);
				return damage;
			}
			else // body or missed
			{
				if (tf < 1) // body
				{
					//dprint("localdamage: body\n");
					victim.localdamage_hit = LD_BODY;
					//return (damage * victim.localdamage_body_mul);
					return damage;
				}
				else // missed
					return 0;
			}
		}
		else
		{
			z = hitpos_z - victim.origin_z;
			if (z >= victim.localdamage_head_z1 && z < victim.localdamage_head_z2)
			{
				victim.localdamage_hit = LD_HEAD;
				//return (damage * victim.localdamage_head_mul);
				return damage;
			}
			if (z >= victim.localdamage_body_z1 && z < victim.localdamage_body_z2)
			{
				victim.localdamage_hit = LD_BODY;
				//return (damage * victim.localdamage_body_mul);
				return damage;
			}
		}
	}
	return damage;
};

float(vector hitpos, vector direction, entity victim, float damgtype) localdamage_getdamagetype =
{
	/*
	// armor is only below head
	if (victim.localdamage)
	if (hitpos_z >= (victim.localdamage_head_z1 + victim.origin_z) && hitpos_z < (victim.localdamage_head_z2 + victim.origin_z))
		return (damgtype - (damgtype & DTF_ARMOR));
	*/
	return damgtype;
};

