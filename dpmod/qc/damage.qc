
.float  ammo_shells;
.float  ammo_nails;
.float  ammo_rockets;
.float  ammo_cells;
.float  ammo_xshells;

float   AMMOMAX_SHELLS          =  100;
float   AMMOMAX_NAILS           =  200;
float   AMMOMAX_ROCKETS         =  100;
float   AMMOMAX_CELLS           =  200;
float   AMMOMAX_XSHELLS         =  100;

float   STARTDM_AMMO_SHELLS      =    20;
float   STARTDM_AMMO_NAILS       =    0;
float   STARTDM_AMMO_ROCKETS     =    0;
float   STARTDM_AMMO_CELLS       =    0;
float   STARTDM_AMMO_XSHELLS     =    0;

float   STARTSP_AMMO_SHELLS      =    20;
float   STARTSP_AMMO_NAILS       =    0;
float   STARTSP_AMMO_ROCKETS     =    0;
float   STARTSP_AMMO_CELLS       =    0;
float   STARTSP_AMMO_XSHELLS     =    0;
float   STARTSP_WEAPON           = IT_WEAPON2;

// ammo given by collecting weapons when already at weapon's fill-up limit
float   AMMOWEAPONOVERFLOW              =    0; // false, thus it will give normal ammo
float   AMMOWEAPONOVERFLOW_SHELLS       =    3;
float   AMMOWEAPONOVERFLOW_NAILS        =    5;
float   AMMOWEAPONOVERFLOW_ROCKETS      =    1;
float   AMMOWEAPONOVERFLOW_CELLS        =    5;
float   AMMOWEAPONOVERFLOW_XSHELLS      =    3;

float   AMMO_SHELLS                     =   20; // double if big box
float   AMMO_NAILS                      =   25; // double if big box
float   AMMO_ROCKETS                    =    5; // double if big box
float   AMMO_CELLS                      =   14; // double if big box
float   AMMO_XSHELLS                    =   20; // double if big box

float   AMMO_GRUNT_PISTOL_ROUNDS        =    5;
float   AMMO_GRUNT_SHOTGUN_SHELLS       =    2;
float   AMMO_GRUNT_NAILGUN_ROUNDS       =    5;
float   AMMO_ENFORCER_ROCKETS           =    2;
float   AMMO_ENFORCER_PLASMACELLS       =    5;
float   AMMO_ENFORCER_LASERCELLS        =    5;
float   AMMO_OGRE_GRENADES              =    2;

// respawn times
float   RESPAWNTIME_AMMO = 20;
float   RESPAWNTIME_WEAPON = 5;
float   RESPAWNTIME_ARMOR = 15;
float   RESPAWNTIME_HEALTH = 20;
float   RESPAWNTIME_MEGAHEALTH = 30;
float   RESPAWNTIME_ARTIFACT = 60;

float   HEALTHSTART             = 125;
float   HEALTHMAX               = 100;
float   HEALTHBODY              = 200; // body health limit
float   HEALTHMEGAMAX           = 250; // max megahealth
float   HEALTHELIMINATION       = 400; // 400 + 200 armor

float   ARMORSTART              = 0;
float   ARMORMAX                = 100;

float   GREENARMOR_VALUE        = 100;
float   GREENARMOR_TYPE         = 0.3;

float   YELLOWARMOR_VALUE       = 150;
float   YELLOWARMOR_TYPE        = 0.6;

float   REDARMOR_VALUE          = 200;
float   REDARMOR_TYPE           = 0.8;

float   GLOWARMOR_VALUE         = 250;
float   GLOWARMOR_TYPE          = 0.8;

float   DMG_SOLDIER_PISTOL_DAMAGE       =   30;
float   DMG_SOLDIER_PISTOL_BDAMAGE      =   30;
float   DMG_SOLDIER_MACHINEGUN_DAMAGE   =   15;
float   DMG_SOLDIER_MACHINEGUN_BDAMAGE  =   15;
float   DMG_SOLDIER_SHOTGUN_PELLETS     =    3;
float   DMG_SOLDIER_SHOTGUN_DAMAGE      =   15;
float   DMG_SOLDIER_SHOTGUN_BDAMAGE     =   15;
float   DMG_OGRE_GRENADE                =   60;
float   DMG_OGRE_GRENADE_RADIUS         =  100;
float   DMG_SHALRATH_MISSILE            =   60;
float   DMG_SHALRATH_MISSILE_RADIUS     =  100;
float   DMG_SHAMBLER_LIGHTNING          =   20;
float   DMG_ENFORCER_LASER              =   25;
float   DMG_ENFORCER_PLASMA             =   20;
float   DMG_ENFORCER_ROCKET             =   60;
float   DMG_ENFORCER_ROCKET_RADIUS      =  100;
float   DMG_TARBABY                     =   90;
float   DMG_TARBABY_RADIUS              =  100;
float   DMG_CHTHON_LAVABALL             =   60;
float   DMG_CHTHON_LAVABALL_RADIUS      =  100;
float   DMG_ZOMBIE_CHUNK                =   20;

// MH = health, MB = extra body health (bodyhealth = MH_DOG + MB_DOG)
float MH_ENFORCER  =    80;float MB_ENFORCER  =   200;
float MH_DEMON     =   300;float MB_DEMON     =   300;
float MH_DOG       =    25;float MB_DOG       =    75;
float MH_GRUNT     =    30;float MB_GRUNT     =   100;
float MH_HELLKNIGHT=   250;float MB_HELLKNIGHT=   250;
float MH_KNIGHT    =    75;float MB_KNIGHT    =   150;
float MH_OGRE      =   200;float MB_OGRE      =   250;
float MH_ROTFISH   =    25;float MB_ROTFISH   =    50;
float MH_SHALRATH  =   400;float MB_SHALRATH  =   400;
float MH_SHAMBLER  =  1200;float MB_SHAMBLER  =  1200;
float MH_TARBABY   =    50;
float MH_WIZARD    =    80;float MB_WIZARD    =    70;
float MH_ZOMBIE    =   200; // explosives do more damage than normal

void(entity e) bound_ammo =
{
	if (e.ammo_shells  > AMMOMAX_SHELLS ) e.ammo_shells  = AMMOMAX_SHELLS;
	if (e.ammo_nails   > AMMOMAX_NAILS  ) e.ammo_nails   = AMMOMAX_NAILS;
	if (e.ammo_rockets > AMMOMAX_ROCKETS) e.ammo_rockets = AMMOMAX_ROCKETS;
	if (e.ammo_cells   > AMMOMAX_CELLS  ) e.ammo_cells   = AMMOMAX_CELLS;
	if (e.ammo_xshells > AMMOMAX_XSHELLS) e.ammo_xshells = AMMOMAX_XSHELLS;
};

float(entity e, float t, float a) full_ammo =
{
	if (t == 1 && (e.ammo_shells  + a) > AMMOMAX_SHELLS ) return (AMMOMAX_SHELLS  - e.ammo_shells );
	if (t == 2 && (e.ammo_nails   + a) > AMMOMAX_NAILS  ) return (AMMOMAX_NAILS   - e.ammo_nails  );
	if (t == 3 && (e.ammo_rockets + a) > AMMOMAX_ROCKETS) return (AMMOMAX_ROCKETS - e.ammo_rockets);
	if (t == 4 && (e.ammo_cells   + a) > AMMOMAX_CELLS  ) return (AMMOMAX_CELLS   - e.ammo_cells  );
	if (t == 5 && (e.ammo_xshells + a) > AMMOMAX_XSHELLS) return (AMMOMAX_XSHELLS - e.ammo_xshells);
	return a;
};

void(entity e) updateammodisplay =
{
/*
	e.ammo_shells = e.ammo_shells;
	e.ammo_nails = e.ammo_rounds;
	e.ammo_rockets = e.ammo_bombs;
	e.ammo_cells = e.ammo_plasma;
*/
};

void(entity targ, entity inflictor, entity attacker, float damage, float bdamage, string dt, float damgtype, vector damgpoint, vector force, void(entity t, entity a, string m, float dtyp) obitfunc) T_Damage;
void(entity inflictor, entity attacker, float damage, float radius, entity ignore, string dethtype, float damgtype, void(entity t, entity a, string m, float dtyp) obitfunc) T_RadiusDamage;
