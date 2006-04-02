
.float wfiretime, wburst; // weapon variables
.float dmg2;

float fightdone, nofire;

.float isadmin;
.float iscreature;

.entity aimtarg;

void() SuperDamageSound;

// called by worldspawn
void() W_Precache;

void(float wframe) havoc_shotanimupdate;
void(float wframe) havoc_nailanimupdate;
void(float wframe) havoc_rockanimupdate;
void(float wframe) havoc_lightanimupdate;

float(entity wclass) WeaponClassToNumber;
entity(float number) NumberToWeaponClass;

entity w_chain;
.string w_item;
.entity w_next;
.entity w_prev;
.float(float request) w_func;
.float wanim_id;
.float wanim_accumulator;
.float wanim_frameseconds;
.float wanim_finalframe;
.float wanim_increment;

.entity weaponclass; // current weapon
.entity switchweaponclass; // desired weapon (current weapon will switch to it when idle)

vector shotorg, shotdir;
void() W_Hostile;

float WR_REGISTER = 1;
float WR_HASAMMO = 2;
float WR_FRAME = 3;
float WR_SETUP = 4;
float WR_INSTANTSETUP = 5;
float WR_ANIMATIONFRAME = 6;
float WR_ANIMATIONFINISH = 7;
float WR_AIM = 8;

float WANIM_READY = 0;
float WANIM_RAISE = 1;
float WANIM_LOWER = 2;
float WANIM_FIRE1 = 3;
float WANIM_FIRE2 = 4;
float WANIM_FIRE3 = 5;
float WANIM_FIRE4 = 6;
float WANIM_FIRE5 = 7;
float WANIM_FIRE6 = 8;
float WANIM_FIRE7 = 9;
float WANIM_FIRE8 = 10;
float WANIM_FIRE9 = 11;
float WANIM_FIRE10 = 12;

entity(float dangerous) W_BestWeaponClass;
