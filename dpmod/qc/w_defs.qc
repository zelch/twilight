
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

/*
float weaponrange;
.void() weaponframecode;
float stopfiring; // used by W_GenericRapidFireCode system

float(float nextshotdelay) W_ShotsToFire;
float(float minrange, float preferredrange, float baserating) genericweaponrating;

float(string wname, float request) setweapon;
string(float dangerous) W_BestWeapon;
string(entity targ) W_BestWeaponForTarget;
//float(float w) RankForWeapon;
//void(float old, float new) Deathmatch_Weapon;
void() W_ChangeWeapon;
void() CheatCommand;
void() CycleWeaponCommand;
void() CycleWeaponReverseCommand;

string weaponstring; // used for returned weapon name from WR_NAME request

float WR_STATE = 1; // weapon state
float WR_SELECTABLE = 2; // true if it can be selected (has ammo)
float WR_RAISE = 3; // request state be changed to WS_RISE
float WR_INSTANT = 4; // instantly raise weapon
float WR_DROP = 5; // request state be changed to WS_DROP
float WR_SETUP = 6; // set the viewmodel, etc
float WR_PRECACHE = 7; // precache models/sounds
float WR_NAME = 8; // sets weaponstring to the name of the weapon
float WR_WEAPONRATING = 9; // returns rating given weaponrange, returns -1 if the weapon is not available
float WR_SWITCH = 10; // true if it can be selected (has ammo), and also sets self.switchweapon if so
// FIXME: kill/death/suicide stat requests of some kind

float WS_ACTIVE = 1; // weapon is selected
float WS_RAISE = 2; // weapon is rising (changes to ACTIVE when done)
float WS_DROP = 3; // weapon is falling (stays DROP until reselected)
*/

