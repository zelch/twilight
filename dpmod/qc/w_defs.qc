
.float  wfiretime, wframe, wburst; // weapon variables
.float  dmg2;

float   fightdone, nofire;

.float  isadmin;
.float iscreature;

entity modechecker;

void() SuperDamageSound;

// called by worldspawn
void() W_Precache;

void(float wframe) havoc_shotanimupdate;
void(float wframe) havoc_nailanimupdate;
void(float wframe) havoc_rockanimupdate;
void(float wframe) havoc_lightanimupdate;
.void() weaponframecode;

.float  switchweapon; // desired weapon (current weapon will switch to it when idle)

float   stopfiring; // used by W_GenericRapidFireCode system

vector  shotorg, shotdir;
void(string firingsound, float nextshotdelay, void() uniquefunc) W_GenericRapidFireCode;
void(string firingsound, float nextshotdelay, void() uniquefunc) W_GenericSlowFireCode;
float(float minrange, float preferredrange, float baserating) genericweaponrating;

float(float w, float request) setweapon;
float(float dangerous) W_BestWeapon;
float(entity targ) W_BestWeaponForTarget;
//float(float w) RankForWeapon;
//void(float old, float new) Deathmatch_Weapon;
void() W_ChangeWeapon;
void() CheatCommand;
void() CycleWeaponCommand;
void() CycleWeaponReverseCommand;

string weaponstring; // used for returned weapon name from WR_NAME request
float weaponrange;

float WR_STATE = 1; // weapon state
float WR_SELECTABLE = 2; // true if it can be selected (has ammo)
float WR_RAISE = 3; // request state be changed to WS_RISE
float WR_INSTANT = 4; // instantly raise weapon
float WR_DROP = 5; // request state be changed to WS_DROP
float WR_SETUP = 6; // set the viewmodel, etc
float WR_AIM = 7; // returns direction to aim the weapon (for bots)
float WR_NAME = 8; // sets weaponstring to the name of the weapon
float WR_WEAPONRATING = 9; // returns rating given weaponrange, returns -1 if the weapon is not available
// FIXME: kill/death/suicide stat requests of some kind

float WS_ACTIVE = 1; // weapon is selected
float WS_RAISE = 2; // weapon is rising (changes to ACTIVE when done)
float WS_DROP = 3; // weapon is falling (stays DROP until reselected)
