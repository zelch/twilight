
.float  ammo_shells;
.float  ammo_nails;
.float  ammo_rockets;
.float  ammo_cells;

float   AMMOMAX_SHELLS          =  100;
float   AMMOMAX_NAILS           =  500;
float   AMMOMAX_ROCKETS         =  100;
float   AMMOMAX_CELLS           =  300;

// LordHavoc: since constants can't have math in them, the ITEMS are inlined in client.qc :(
float   STARTPARMSDM_AMMO_SHELLS     =   50; // 20
float   STARTPARMSDM_AMMO_NAILS      =    0;
float   STARTPARMSDM_AMMO_ROCKETS    =    0;
float   STARTPARMSDM_AMMO_CELLS      =    0;
//float   STARTPARMSDM_ITEMS           = IT_WEAPON1 | IT_WEAPON2;
float   STARTPARMSDM_HEALTH          =  125;
float   STARTPARMSDM_MAXHEALTH       =  100;
float   STARTPARMSDM_ARMORVALUE      =    0;
float   STARTPARMSDM_ARMORTYPE       =    0;

float   STARTPARMSMCTF_AMMO_SHELLS     =    0;
float   STARTPARMSMCTF_AMMO_NAILS      =    0;
float   STARTPARMSMCTF_AMMO_ROCKETS    =    0;
float   STARTPARMSMCTF_AMMO_CELLS      =    0;
//float   STARTPARMSMCTF_ITEMS           = IT_WEAPON1 | IT_WEAPON2;
float   STARTPARMSMCTF_HEALTH          =  100;
float   STARTPARMSMCTF_MAXHEALTH       =  100;
float   STARTPARMSMCTF_ARMORVALUE      =    0;
float   STARTPARMSMCTF_ARMORTYPE       =    0;

float   STARTPARMSSP_AMMO_SHELLS     =   50; // 20
float   STARTPARMSSP_AMMO_NAILS      =    0;
float   STARTPARMSSP_AMMO_ROCKETS    =    0;
float   STARTPARMSSP_AMMO_CELLS      =    0;
//float   STARTPARMSSP_ITEMS           = IT_WEAPON1 | IT_WEAPON2;
float   STARTPARMSSP_HEALTH          =  100;
float   STARTPARMSSP_MAXHEALTH       =  100;
float   STARTPARMSSP_ARMORVALUE      =    0;
float   STARTPARMSSP_ARMORTYPE       =    0;

float   STARTPARMSELIM_AMMO_SHELLS   =  100;
float   STARTPARMSELIM_AMMO_NAILS    =  200;
float   STARTPARMSELIM_AMMO_ROCKETS  =  100;
float   STARTPARMSELIM_AMMO_CELLS    =  200;
//float   STARTPARMSELIM_ITEMS         = IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10;
float   STARTPARMSELIM_HEALTH        =  400;
float   STARTPARMSELIM_MAXHEALTH     =  400;
float   STARTPARMSELIM_ARMORVALUE    =    0;
float   STARTPARMSELIM_ARMORTYPE     =    0;

// ammo given by collecting weapons when already at weapon's fill-up limit
float   AMMOWEAPONOVERFLOW              =    0; // false, thus it will give normal ammo
float   AMMOWEAPONOVERFLOW_SHELLS       =    3;
float   AMMOWEAPONOVERFLOW_NAILS        =    5;
float   AMMOWEAPONOVERFLOW_ROCKETS      =    1;
float   AMMOWEAPONOVERFLOW_CELLS        =    5;

float   AMMO_SHELLS                     =   50; // double if big box (was 20)
float   AMMO_NAILS                      =   50; // double if big box (was 25)
float   AMMO_ROCKETS                    =   10; // double if big box (was 5)
float   AMMO_CELLS                      =   30; // double if big box (was 14)

float   AMMO_GRUNT_PISTOL_ROUNDS        =   10;
float   AMMO_GRUNT_SHOTGUN_SHELLS       =   10; // 5
float   AMMO_GRUNT_NAILGUN_ROUNDS       =   20;
float   AMMO_ENFORCER_ROCKETS           =    5;
float   AMMO_ENFORCER_PLASMACELLS       =   20;
float   AMMO_ENFORCER_LASERCELLS        =   10;
float   AMMO_ENFORCER_FLAMERCELLS       =   10;
float   AMMO_OGRE_GRENADES              =    5;

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

float	SKILL4_MINALPHA			= 0.2;

float   DMG_SOLDIER_PISTOL_DAMAGE       =   30;
float   DMG_SOLDIER_PISTOL_BDAMAGE      =   30;
float   DMG_SOLDIER_MACHINEGUN_DAMAGE   =   15;
float   DMG_SOLDIER_MACHINEGUN_BDAMAGE  =   15;
float   DMG_SOLDIER_SHOTGUN_PELLETS     =    3;
float   DMG_SOLDIER_SHOTGUN_DAMAGE      =   15;
float   DMG_SOLDIER_SHOTGUN_BDAMAGE     =   15;
float   DMG_OGRE_GRENADE_DAMAGE         =   60;
float   DMG_OGRE_GRENADE_FORCE          =   60;
float   DMG_OGRE_GRENADE_RADIUS         =  100;
float   DMG_SHALRATH_MISSILE_DAMAGE     =   60;
float   DMG_SHALRATH_MISSILE_FORCE      =   60;
float   DMG_SHALRATH_MISSILE_RADIUS     =  100;
float   DMG_SHAMBLER_LIGHTNING          =   20;
float   DMG_ENFORCER_LASER              =   25;
float   DMG_ENFORCER_PLASMA_DAMAGE      =   20;
float   DMG_ENFORCER_PLASMA_FORCE       =   20;
float   DMG_ENFORCER_PLASMA_RADIUS      =   20;
float   DMG_ENFORCER_ROCKET_DAMAGE      =   60;
float   DMG_ENFORCER_ROCKET_FORCE       =   60;
float   DMG_ENFORCER_ROCKET_RADIUS      =  100;
float   DMG_ENFORCER_FLAMER_DAMAGE      =   20;
float   DMG_ENFORCER_FLAMER_FORCE       =   20;
float   DMG_ENFORCER_FLAMER_BURNDAMAGE  =   70;
float   DMG_ENFORCER_FLAMER_BURNLIMIT   =   90;
float   DMG_ENFORCER_FLAMER_RADIUS      =  100;
float   DMG_TARBABY_DAMAGE              =   90;
float   DMG_TARBABY_FORCE               =   90;
float   DMG_TARBABY_RADIUS              =  200;
float   DMG_CHTHON_LAVABALL_DAMAGE      =   60;
float   DMG_CHTHON_LAVABALL_FORCE       =   60;
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
float MH_TARBABY   =    20;
float MH_WIZARD    =    80;float MB_WIZARD    =    70;
float MH_ZOMBIE    =   200; // explosives do more damage than normal

void(entity targ, entity inflictor, entity attacker, float damage, float bdamage, string dt, float damgtype, vector damgpoint, vector force, void(entity t, entity a, string m, float dtyp) obitfunc) T_Damage;
void(entity inflictor, entity attacker, float damage, float force, float radius, entity ignore, string dethtype, float damgtype, void(entity t, entity a, string m, float dtyp) obitfunc) T_RadiusDamage;
