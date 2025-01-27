#include "../share/defs.h"
#pragma target fte
#pragma autoproto

void (entity e, string ent_model) setmodel =
{
    // assume func_* are world models that need to be seen while flashed
    if (strstrofs(e.classname, "func_") == -1)
        e.dimension_seen = DIMENSION::NOFLASH;
    fte_setmodel(e, ent_model);
};

void(entity e, float chan, string samp, float vol, float atten, float speedpct = 0, float flags = 0, float timeofs = 0) sound =
{
    float olddimens = e.dimension_seen;
    // make the sound go to no flash, so it isn't heard by those that are flashed
    e.dimension_seen = DIMENSION::NOFLASH;
    fte_sound(e, chan, samp, vol, atten, speedpct, flags, timeofs);
    e.dimension_seen = olddimens;
};

typedef void () void_f;

enum CLASS
{
    NONE = 0,
    SCOUT = 1,
    SOLDIER = 3,
    DEMOMAN = 4,
    MEDIC = 5,
    SPY = 8,
};

// TF 
enum TEAM
{
    NONE = 0,
    BLUE = 1,
    RED = 2,
    YELLOW = 3,
    GREEN = 4
};

enum DIMENSION
{
    FLASH = 1, // when flash, dimension see is set to this
    // all bits between 1 and 255 are reserved for flash
    NOFLASH = 256, // can't been seen by those that are flashed
    BLUE = 512,
    RED = 1024,
    YELLOW = 2048,
    GREEN = 4096,
    INVISIBLE = 8192 // special dimension to hide stuff in
};

enum ILLEGALBIT
{
    SCOUT = 1,
    SNIPER = 2,
    SOLDIER = 4,
    DEMOMAN = 8,
    MEDIC = 16,
    HWGUY = 32,
    PYRO = 64,
    RANDOMPC = 128,
    SPY = 256,
    ENGINEER = 512,
};

enum SEASON
{
    FO = 0,
    ONE, // lordytf
    TF28
};

enumflags ATTRIBUTE
{
    SCAN,
    DASH,
    DISARM,
};

enumflags DAMAGE
{
    NONE = 0,
    IGNOREARMOR,
    NOTTEAM,
    NOTSELF,
};

enumflags DAMAGETYPE
{
    OTHER, // Ignore armorclass (as in ignore asbestos etc... essentially a "none"
    SHELL,
    NAIL,
    EXPLOSION,
    SHOCK,
    FIRE,
    NOSOUND, // Special damage. Makes no sound/painframe, etc
    NOMOMENTUM, // Special damage, don't change momentum
    CRUSH, // World stuff, not really used
};

enum SOUNDS : string
{
    DASH = "dash.wav",
    SCAN = "misc/basekey.wav",
    FLASH = "weapons/flashgrenburst.wav",
    SHOTGUN_SHOOT = "weapons/guncock.wav",
    SUPERSHOTGUN_SHOOT = "weapons/shotgn2.wav",
    ROCKETLAUNCHER_SHOOT = "weapons/sgun1.wav",
    GRENADELAUNCHER_SHOOT = "weapons/grenade.wav",
    AXE_SHOOT = "weapons/ax1.wav",
    AXE_HIT = "player/axhit2.wav",
    BOUNCE = "weapons/bounce.wav",
    SHOCK_HIT = "weapons/lhit.wav",
};

enum MODELS : string
{
    GRENADE_FLASH = "progs/flashgren.mdl",
    GRENADE_HAND = "progs/hgren2.mdl",
    BUBBLE = "progs/s_bubble.spr",
    VIEW_SHOTGUN = "progs/v_shot.mdl",
    VIEW_SUPERSHOTGUN = "progs/v_shot2.mdl",
    VIEW_AXE = "progs/v_axe.mdl",
    VIEW_ROCKETLAUNCHER = "progs/v_rock2.mdl",
    VIEW_GRENADELAUNCHER = "progs/v_rock.mdl",
    ROCKET = "progs/missile.mdl",
    GRENADE = "progs/grenade2.mdl",
    PIPEBOMB = MODELS::GRENADE,
    SPIKE = "progs/spike.mdl",
    GRENADE_SHOCK = "progs/biggren.mdl",
    GRENADE_MIRV = MODELS::GRENADE_SHOCK,
};

enum TFCLASSNAMES : string
{
    SCOUT = "scout",
    SOLDIER = "soldier",
    DEMOMAN = "demoman"
};

enum WEAPON
{
    NONE,
    AXE,
    SPANNER,
    SNIPERRIFLE,
    TRANQUILISER,
    SUPERSHOTGUN,
    NAILGUN,
    SUPERNAILGUN,
    GRENADELAUNCHER,
    PIPEBOMBLAUNCHER,
    FLAMETHROWER,
    INCENDIARYCANNON,
    ASSAULTCANNON,
    ROCKETLAUNCHER,
    RAILGUN,
    KNIFE,
    SHOTGUN,
    MEDIKIT
};

enum GRENADE
{
    FLASH,
    CONCUSSION,
    HANDGRENADE,
    SHOCK,
    MIRV,
};

enum IMPULSE
{
    PRIME_GREN1 = 14,
    PRIME_GREN2 = 15,
    THROW_GREN = 16,
    PRIMETHROW_GREN1 = 17, // Prime and throw grenade type 1 (two clicks)
    PRIMETHROW_GREN2 = 18, // Prime and throw grenade type 2 (two clicks)
    SWITCH_GREN_TYPE = 19, // Switch grenade mode 1/2
    SPECIAL = 30,
    DASH = 41,
    SCAN = 42,
    SCAN_ENEMY = 43,
    SCAN_FRIENDLY = 44,
    SCAN_SOUND = 45,
};

typedef struct 
{
    string command;
    IMPULSE impulse;
    IMPULSE impulse2;
} alias_t;

alias_t Aliases[11] =
{
    {"primeone", IMPULSE::PRIME_GREN1, 0},
    {"primetwo", IMPULSE::PRIME_GREN2, 0},
    {"gren1", IMPULSE::PRIMETHROW_GREN1, 0}, // FIXME - this also acts as a double tap
    {"gren2", IMPULSE::PRIMETHROW_GREN2, 0},
    {"throwgren", IMPULSE::THROW_GREN, 0},
    {"special", IMPULSE::SPECIAL, 0},
    {"autoscan", IMPULSE::SCAN, 0},
    {"scanf", IMPULSE::SCAN_FRIENDLY, 0},
    {"scane", IMPULSE::SCAN_ENEMY, 0},
    {"dash", IMPULSE::DASH, 0},
    {"scansound", IMPULSE::SCAN_SOUND, 0},
};

class player_c;
class gamemanager_c;
gamemanager_c GameManager;
class team_c;
team_c *Teams;

// old tf entity field support, unless we manually process ents raw with __fullspawndata
.float team_no;
.float goal_activation;
.float g_a;
.float g_e;
.float goal_effects;
.float h_i_g;
.float has_item_from_group;
.float hasnt_item_from_group;
.float hn_i_g;
.float r_i_g;
.float remove_item_group;
.float a_s;
.float a_n;
.float a_r;
.float a_c;
.float rv_s_h;
.float remove_spawngroup;
.float rs_s_h;
.float restore_spawngroup;
.float rv_gr;
.float remove_group_no;
.float rs_gr;
.float restore_group_no;
.float rv_g;
.float remove_goal_no;
.float rs_g;
.float restore_goal_no;
.string t_s_h;
.string team_str_home;
.string t_s_m;
.string team_str_moved;
.string t_s_c;
.string team_str_carried;
.string n_s_h;
.string non_team_str_home;
.string n_s_m;
.string non_team_str_moved;
.string n_s_c;
.string non_team_str_carried;
.string b_b;
.string broadcast;
.string b_t;
.string team_broadcast;
.string b_n;
.string non_team_broadcast;
.string b_o;
.string owners_team_broadcast;
.string n_b;
.string netname_broadcast;
.string n_t;
.string netname_team_broadcast;
.string n_n;
.string netname_non_team_broadcast;
.string n_o;
.string netname_owners_team_broadcast;
.string d_t;
.string team_drop;
.string d_n;
.string non_team_drop;
.string d_n_t;
.string netname_team_drop;
.string d_n_n;
.string netname_non_team_drop;

// random globals from qw code
entity  lastspawn;
float   modelindex_eyes, modelindex_player;
.float hit_z; // FIXME - is this used by engine?
.float  dmgtime;
float   H_ROTTEN = 1;
float   H_MEGA = 2;
.float  healamount, healtype;
float WEAPON_BIG2 = 1;
float START_OFF = 1;
float SPAWNFLAG_SUPERSPIKE      = 1;
float SPAWNFLAG_LASER = 2;

float DOOR_START_OPEN = 1;
float DOOR_DONT_LINK = 4;
float DOOR_GOLD_KEY = 8;
float DOOR_SILVER_KEY = 16;
float DOOR_TOGGLE = 32;
float PLAT_LOW_TRIGGER = 1;


float WEAPON_BIG = 8;

float SECRET_OPEN_ONCE = 1;             // stays open
float SECRET_1ST_LEFT = 2;              // 1st move is left of arrow
float SECRET_1ST_DOWN = 4;              // 1st move is down from arrow
float SECRET_NO_SHOOT = 8;              // only opened by trigger
float SECRET_YES_SHOOT = 16;    // shootable even if targeted