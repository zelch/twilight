
// resistances to 4 kinds of damage:
.float resist_bullet, resist_explosive, resist_energy, resist_fire, resist_ice;
// every monster can have resistances
// note: -1 means immune, as 0.0 can't be used

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

// unfortunately I had to use decimal bitmasks here instead of |'ing or +'ing
// the flags together.  QCC needs more number formats, like binary and hex...
float DT_IMPACT           =        1; // DTF_ARMOR
float DT_EXPLOSION        =        5; // often also DTF_INDIRECT (from T_RadiusDamage)
float DT_FIRE             =       17;
float DT_BURN             =       17;
float DT_PLASMA           =        9;
float DT_PARTICLEBEAM     =        9;
float DT_LIGHTNING        =        8;
float DT_LASER            =       41;
float DT_SHOTGUN          =       35;
float DT_NAIL             =       35;
float DT_CUT              =       33;
float DT_HURT             =        1;
float DT_TELEFRAG         = 33554432; // can not be combined with other flags

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


// kill message
.string deathtype;
// copied from .deathtype for the attacker
// a map entity can gain alot of meaning by
// adding a kill message in the deathtype key
// such as ' was chopped to bits'
// or ' fell into the abyss'
// if you set a deathtype for a monster
// in a map key it will override the normal
// kill message for that monster
// so you could have some hell knights that
// say ' was slain by one of the palace guards'
// and many other ways to add meaning to a map
.string deathmsg;

.float frozen;

