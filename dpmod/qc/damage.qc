
float AMMOMAXSP_SHELLS          =  4000;
float AMMOMAXSP_NAILS           =  4000;
float AMMOMAXSP_ROCKETS         =  4000;
float AMMOMAXSP_CELLS           =  4000;

float AMMOMAXDM_SHELLS          =  100;
float AMMOMAXDM_NAILS           =  500;
float AMMOMAXDM_ROCKETS         =  100;
float AMMOMAXDM_CELLS           =  200;

// LordHavoc: since constants can't have math in them, the ITEMS are inlined in client.qc :(
float STARTPARMSDM_AMMO_SHELLS     =   50; // 20
float STARTPARMSDM_AMMO_NAILS      =    0;
float STARTPARMSDM_AMMO_ROCKETS    =    0;
float STARTPARMSDM_AMMO_CELLS      =    0;
//float STARTPARMSDM_ITEMS           = IT_WEAPON1 | IT_WEAPON2;
float STARTPARMSDM_HEALTH          =  125;
float STARTPARMSDM_MAXHEALTH       =  100;
float STARTPARMSDM_ARMORVALUE      =    0;
float STARTPARMSDM_ARMORTYPE       =    0;

float STARTPARMSSP_AMMO_SHELLS     =   50; // 20
float STARTPARMSSP_AMMO_NAILS      =    0;
float STARTPARMSSP_AMMO_ROCKETS    =    0;
float STARTPARMSSP_AMMO_CELLS      =    0;
//float STARTPARMSSP_ITEMS           = IT_WEAPON1 | IT_WEAPON2;
float STARTPARMSSP_HEALTH          =  100;
float STARTPARMSSP_MAXHEALTH       =  100;
float STARTPARMSSP_ARMORVALUE      =    0;
float STARTPARMSSP_ARMORTYPE       =    0;

float STARTPARMSELIM_AMMO_SHELLS   =  100;
float STARTPARMSELIM_AMMO_NAILS    =  200;
float STARTPARMSELIM_AMMO_ROCKETS  =  100;
float STARTPARMSELIM_AMMO_CELLS    =  200;
//float STARTPARMSELIM_ITEMS         = IT_WEAPON1 | IT_WEAPON2 | IT_WEAPON3 | IT_WEAPON4 | IT_WEAPON5 | IT_WEAPON6 | IT_WEAPON7 | IT_WEAPON8 | IT_WEAPON9 | IT_WEAPON10;
float STARTPARMSELIM_HEALTH        =  400;
float STARTPARMSELIM_MAXHEALTH     =  400;
float STARTPARMSELIM_ARMORVALUE    =    0;
float STARTPARMSELIM_ARMORTYPE     =    0;

// ammo given by collecting weapons when already at weapon's fill-up limit
float AMMOWEAPONOVERFLOW              =    0; // false, thus it will give normal ammo
float AMMOWEAPONOVERFLOW_SHELLS       =    3;
float AMMOWEAPONOVERFLOW_NAILS        =    5;
float AMMOWEAPONOVERFLOW_ROCKETS      =    1;
float AMMOWEAPONOVERFLOW_CELLS        =    5;

/*
// quake values (roughly)
float AMMO_AXE_DAMAGE                   =   20;
float AMMO_AXE_BODYDAMAGE               =   20;
float AMMO_SHELL_DAMAGE                 =   28;
float AMMO_SHELL_BODYDAMAGE             =   28;
float AMMO_NAIL_DAMAGE                  =    9;
float AMMO_NAIL_BODYDAMAGE              =    9;
float AMMO_ROCKET_DAMAGE                =  110;
float AMMO_ROCKET_FORCE                 =  110;
float AMMO_ROCKET_RADIUS                =  240;
float AMMO_CELL_DAMAGE                  =   30;
float AMMO_CELL_BODYDAMAGE              =   30;
// ammo boxes (double if big box)
float AMMO_SHELLS                       =   20;
float AMMO_NAILS                        =   25;
float AMMO_ROCKETS                      =    5;
float AMMO_CELLS                        =   12;
// ammo dropped by monsters
float AMMO_GRUNT_PISTOL                 =    5;
float AMMO_GRUNT_SHOTGUN                =    5;
float AMMO_GRUNT_NAILGUN                =   10;
float AMMO_ENFORCER_DBSHOTGUN           =   10;
float AMMO_ENFORCER_SUPERNAILGUN        =   20;
float AMMO_ENFORCER_ROCKETLAUNCHER      =    2;
float AMMO_ENFORCER_PLASMARIFLE         =    5;
float AMMO_ENFORCER_LASERRIFLE          =    5;
float AMMO_OGRE_GRENADELAUNCHER         =    2;
*/
// darkplaces mod values
float AMMO_AXE_DAMAGE                   =   60;
float AMMO_AXE_BODYDAMAGE               =   60;
float AMMO_SHELL_DAMAGE                 =   42;
float AMMO_SHELL_BODYDAMAGE             =   42;
float AMMO_NAIL_DAMAGE                  =   15;
float AMMO_NAIL_BODYDAMAGE              =   15;
float AMMO_ROCKET_DAMAGE                =  110;
float AMMO_ROCKET_FORCE                 =  880;
float AMMO_ROCKET_RADIUS                =  200;
float AMMO_CELL_DAMAGE                  =   30;
float AMMO_CELL_BODYDAMAGE              =   30;
// ammo boxes (double if big box)
float AMMO_SHELLS                       =   20;
float AMMO_NAILS                        =   25;
float AMMO_ROCKETS                      =    5;
float AMMO_CELLS                        =   12;
// ammo dropped by monsters
float AMMO_GRUNT_PISTOL                 =    5;
float AMMO_GRUNT_SHOTGUN                =    5;
float AMMO_GRUNT_NAILGUN                =   10;
float AMMO_ENFORCER_DBSHOTGUN           =   10;
float AMMO_ENFORCER_SUPERNAILGUN        =   20;
float AMMO_ENFORCER_ROCKETLAUNCHER      =    4;
float AMMO_ENFORCER_PLASMARIFLE         =    5;
float AMMO_ENFORCER_LASERRIFLE          =    5;
float AMMO_OGRE_GRENADELAUNCHER         =    4;

// respawn times
float RESPAWNTIME_AMMO        =  20;
float RESPAWNTIME_WEAPON      =   5;
float RESPAWNTIME_ARMOR       =  15;
float RESPAWNTIME_HEALTH      =  20;
float RESPAWNTIME_MEGAHEALTH  =  30;
float RESPAWNTIME_ARTIFACT    =  60;

float ARTIFACT_SUIT_TIME            =  30;
float ARTIFACT_SUPER_DAMAGE_TIME    =  30;
float ARTIFACT_INVULNERABILITY_TIME =  30;
float ARTIFACT_INVISIBILITY_TIME    =  30;

float HEALTHSTART             = 125;
float HEALTHMAX               = 100;
float HEALTHBODY              = 200; // body health limit
float HEALTHMEGAMAX           = 250; // max megahealth
float HEALTHELIMINATION       = 400; // 400 + 200 armor

float ARMORSTART              = 0;
float ARMORMAX                = 100;

float GREENARMOR_VALUE        = 100;
float GREENARMOR_TYPE         = 0.3;

float YELLOWARMOR_VALUE       = 150;
float YELLOWARMOR_TYPE        = 0.6;

float REDARMOR_VALUE          = 200;
float REDARMOR_TYPE           = 0.8;

float SKILL4_MINALPHA         = 0.4;

float DMG_CHTHON_LAVABALL_DAMAGE      =  110;
float DMG_CHTHON_LAVABALL_FORCE       =  110;
float DMG_CHTHON_LAVABALL_RADIUS      =  102;
float DMG_DOG_BITE_BASE               =    0;
float DMG_DOG_BITE_RANDOM1            =    8;
float DMG_DOG_BITE_RANDOM2            =    8;
float DMG_DOG_BITE_RANDOM3            =    8;
float DMG_DOG_JUMP_BASE               =   10;
float DMG_DOG_JUMP_RANDOM             =   10;
float DMG_ENFORCER_DBSHOTGUN_DAMAGE   =   28;
float DMG_ENFORCER_DBSHOTGUN_RANGE    =  500;
float DMG_ENFORCER_LASER              =   15;
float DMG_ENFORCER_PLASMA_DAMAGE      =   15;
float DMG_ENFORCER_PLASMA_FORCE       =    0;
float DMG_ENFORCER_PLASMA_RADIUS      =   20;
float DMG_ENFORCER_ROCKET_DAMAGE      =   60;
float DMG_ENFORCER_ROCKET_FORCE       =   60;
float DMG_ENFORCER_ROCKET_RADIUS      =  102;
float DMG_ENFORCER_SUPERNAIL_DAMAGE   =    9; // fires 20 per second
float DMG_FIEND_JUMP_BASE             =   40;
float DMG_FIEND_JUMP_RANDOM           =   10;
float DMG_FIEND_MELEE_BASE            =   10;
float DMG_FIEND_MELEE_RANDOM          =    5;
float DMG_FISH_BITE_BASE              =    0;
float DMG_FISH_BITE_RANDOM1           =    3;
float DMG_FISH_BITE_RANDOM2           =    3;
float DMG_FISH_BITE_RANDOM3           =    0;
float DMG_HELLFISH_BITE_BASE          =    0;
float DMG_HELLFISH_BITE_RANDOM1       =    9;
float DMG_HELLFISH_BITE_RANDOM2       =    9;
float DMG_HELLFISH_BITE_RANDOM3       =    0;
float DMG_HELLKNIGHT_SPIKE            =    9;
float DMG_KNIGHT_MELEE_BASE           =    0;
float DMG_KNIGHT_MELEE_RANDOM1        =    3;
float DMG_KNIGHT_MELEE_RANDOM2        =    3;
float DMG_KNIGHT_MELEE_RANDOM3        =    3;
float DMG_OGRE_GRENADE_DAMAGE         =   40;
float DMG_OGRE_GRENADE_FORCE          =   40;
float DMG_OGRE_GRENADE_RADIUS         =  102;
float DMG_OGRE_GRENADE_TIME           =    2.5;
float DMG_OGRE_MELEE_BASE             =    0;
float DMG_OGRE_MELEE_RANDOM1          =    4;
float DMG_OGRE_MELEE_RANDOM2          =    4;
float DMG_OGRE_MELEE_RANDOM3          =    4;
float DMG_SHALRATH_MISSILE_DAMAGE     =   40;
float DMG_SHALRATH_MISSILE_FORCE      =   40;
float DMG_SHALRATH_MISSILE_RADIUS     =  102;
float DMG_SHAMBLER_CLAW_BASE          =    0;
float DMG_SHAMBLER_CLAW_RANDOM1       =   20;
float DMG_SHAMBLER_CLAW_RANDOM2       =   20;
float DMG_SHAMBLER_CLAW_RANDOM3       =   20;
float DMG_SHAMBLER_LIGHTNING          =   10;
float DMG_SHAMBLER_SMASH_BASE         =    0;
float DMG_SHAMBLER_SMASH_RANDOM1      =   40;
float DMG_SHAMBLER_SMASH_RANDOM2      =   40;
float DMG_SHAMBLER_SMASH_RANDOM3      =   40;
float DMG_SOLDIER_MACHINEGUN_BDAMAGE  =    6;
float DMG_SOLDIER_MACHINEGUN_DAMAGE   =    6;
float DMG_SOLDIER_PISTOL_BDAMAGE      =   10;
float DMG_SOLDIER_PISTOL_DAMAGE       =   10;
float DMG_SOLDIER_SHOTGUN_BDAMAGE     =    4;
float DMG_SOLDIER_SHOTGUN_DAMAGE      =    4;
float DMG_SOLDIER_SHOTGUN_PELLETS     =    4;
float DMG_TARBABY_DIE_DAMAGE          =  102;
float DMG_TARBABY_DIE_FORCE           =  102;
float DMG_TARBABY_DIE_RADIUS          =  102;
float DMG_TARBABY_JUMP_BASE           =   10;
float DMG_TARBABY_JUMP_RANDOM         =   10;
float DMG_WIZARD_SPIT                 =    9;
float DMG_ZOMBIE_CHUNK                =   10;

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
float MH_SHAMBLER  =   600;float MB_SHAMBLER  =   600;
float MH_TARBABY   =    80;
float MH_WIZARD    =    80;float MB_WIZARD    =    70;
float MH_ZOMBIE    =   200; // explosives do more damage than normal

// new monsters
float MH_HELLFISH  =    90;float MB_HELLFISH  =   150;



// damage types

float DTF_NOTHING          =       0;
float DTF_ARMOR            =       1;
float DTF_RESIST_BULLET    =       2; // bullet like projectile
float DTF_RESIST_EXPLOSIVE =       4; // explosive damage
float DTF_RESIST_ENERGY    =       8; // energy damage
float DTF_RESIST_FIRE      =      16; // fire damage
float DTF_RESIST_ICE       =    2048; // ice damage
float DTF_BLOOD            =      32; // this kind of damage causes blood splatters
float DTF_INDIRECT         =      64; // not a direct hit
// no recursive shield damage
// (though I've considered gibbing both entities involved for correctness >:)
float DTF_SHIELD          =      128;
float DTF_TELEFRAG        = 33554432; // ignores god mode, team, and always gibs (can not be combined with other flags)
float DTF_SHOCK           =      512; // change radius damage behavior in water/slime
float DTF_NOPROTECT       =     1024; // god mode etc have no effect
float DTF_FREEZE          =     4096;
float DTF_AXHIT           =     8192; // humiliating scream when hit by an ax

// unfortunately I had to use decimal bitmasks here instead of |'ing or +'ing
// the flags together.  QCC needs more number formats, like binary and hex...
float DT_IMPACT           =        1; // DTF_ARMOR
float DT_EXPLOSION        =        5; // often also DTF_INDIRECT (from T_RadiusDamage)
float DT_FIRE             =       17;
float DT_BURN             =       17;
float DT_PLASMA           =        9;
float DT_PARTICLEBEAM     =        9;
float DT_LIGHTNING        =        9; // DTF_ARMOR | DTF_RESIST_ENERGY
float DT_LASER            =       41;
float DT_SHOTGUN          =       35;
float DT_NAIL             =       35;
float DT_CUT              =       33;
float DT_HURT             =        1;
float DT_TELEFRAG         = 33554432; // can not be combined with other flags
float DT_AX               =     8225;

float DT_FALL             =        0; // no armor damage

// liquids
float DT_WATER            =        0; // not used
float DT_SLIME            =        1;
float DT_LAVA             =        1;
float DT_WATERDROWN       =        0; // ignore armor
float DT_SLIMEDROWN       =        0; // ignore armor
float DT_LAVADROWN        =        0; // ignore armor

float DT_KICKBACK         =        0;

float DT_ICE              =     6144;
