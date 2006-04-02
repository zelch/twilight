/*QUAKED --InfoStuff-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
*/
/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for deathmatch games
*/
/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 32)
potential spawning position for coop games
*/
/*QUAKED info_player_team1 (.7 0 0) (-16 -16 -24) (16 16 32)
potential spawning position for teamplay games
team #1 - red
*/
/*QUAKED info_player_team2 (0 0 .7) (-16 -16 -24) (16 16 32)
potential spawning position for teamplay games
team #2 - blue
*/
/*QUAKED info_player_team3 (.7 .7 .7) (-16 -16 -24) (16 16 32)
potential spawning position for teamplay games
team #3 - grey
*/
/*QUAKED --MiscItems-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
100 green armor, 30% absorb
*/
/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
150 yellow armor, 60% absorb
*/
/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
200 red armor, 80% absorb
*/
/*QUAKED item_armor_glow (0 .5 .8) (-16 -16 0) (16 16 32)
250 red armor, 80% absorb
*/
/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from
water or slime for 60 seconds
*/
/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
30 second Quad Damage, 'nuff said.
*/
/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is mostly invisible for 60 seconds.
*/
/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 15 points.
Megahealth heals 100.

If above your health limit
your health will drain
one point per second.
*/
/*QUAKED --Buttons-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/
/*QUAKED --Doors-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK GOLD_KEY SILVER_KEY TOGGLE
if two doors touch, they are assumed to be connected and operate as a unit.

TOGGLE causes the door to wait in both the start and end states for a trigger event.

START_OPEN causes the door to move to its destination when spawned, and operate in reverse.  It is used to temporarily or permanently close off an area when triggered (not usefull for touch or takedamage doors).

Key doors are allways wait -1.

"message"	is printed when the door is touched if it is a trigger door and it hasn't been fired yet
"angle"		determines the opening direction
"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
"health"	if set, door must be shot open
"speed"		movement speed (100 default)
"wait"		wait before returning (3 default, -1 = never return)
"lip"		lip remaining at end of move (8 default)
"dmg"		damage to inflict when blocked (2 default)
"sounds"
0)	no sound
1)	stone
2)	base
3)	stone chain
4)	screechy metal
*/
/*QUAKED func_door_secret (0 .5 .8) ? open_once 1st_left 1st_down no_shoot always_shoot
Basic secret door. Slides back, then to the side. Angle determines direction.
wait  = # of seconds before coming back
1st_left = 1st move is left of arrow
1st_down = 1st move is down from arrow
always_shoot = even if targeted, keep shootable
t_width = override WIDTH to move back (or height if going down)
t_length = override LENGTH to move sideways
"dmg"		damage to inflict when blocked (2 default)

If a secret door has a targetname, it will only be opened by it's botton or trigger, not by damage.
"sounds"
1) medieval
2) metal
3) base
*/
/*QUAKED --KeysAndRunes-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/
/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/
/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/
/*QUAKED --Monsters-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED monster_boss (1 0 0) (-128 -128 -24) (128 128 256)
*/
/*QUAKED monster_demon1 (1 0 0) (-32 -32 -24) (32 32 64) Ambush x x x x x x Stand
*/
/*QUAKED monster_dog (1 0 0) (-32 -32 -24) (32 32 40) Ambush x x x x x x Stand
*/
/*QUAKED monster_enforcer (1 0 0) (-16 -16 -24) (16 16 32) Ambush x x x x x x Stand
*/
/*QUAKED monster_fish (1 0 0) (-16 -16 -24) (16 16 24) Ambush x x x x x x Stand
*/
/*QUAKED monster_army (1 0 0) (-16 -16 -24) (16 16 32) Ambush
Grunt, normally 100 health.

Flags:
"ambush"
 the monster will only wake up on
 really seeing the player, not another
 monster getting angry

Keys:
"deathtype"
 death message.
 default: " lays down for a Grunt"
"health"
 default: 100
"armortype"
 armor quality:
 0.0) no armor
 0.3) green armor
 0.6) yellow armor
 0.8) red armor
 1.0) glow armor
"armorvalue"
 how much armor,
 can be anything you like,
 but these are normal:
 0) no armor
 100) green armor
 150) yellow armor
 200) red armor
 250) glow armor
*/
/*QUAKED monster_hell_knight (1 0 0) (-16 -16 -24) (16 16 32) Ambush x x x x x x Stand
*/
/*QUAKED monster_knight (1 0 0) (-16 -16 -24) (16 16 32) Ambush x x x x x x Stand
*/
/*QUAKED monster_ogre (1 0 0) (-32 -32 -24) (32 32 64) Ambush x x x x x x Stand
*/
/*QUAKED monster_oldone (1 0 0) (-16 -16 -24) (16 16 32)
*/
/*QUAKED monster_shalrath (1 0 0) (-32 -32 -24) (32 32 48) Ambush x x x x x x Stand
*/
/*QUAKED monster_shambler (1 0 0) (-32 -32 -24) (32 32 64) Ambush x x x x x x Stand
*/
/*QUAKED monster_tarbaby (1 0 0) (-16 -16 -24) (16 16 24) Ambush x x x x x x Stand
*/
/*QUAKED monster_wizard (1 0 0) (-16 -16 -24) (16 16 32) Ambush x x x x x x Stand
*/
/*QUAKED monster_zombie (1 0 0) (-16 -16 -24) (16 16 32) Crucified ambush x x x x x Stand
If crucified, stick the bounding box 12 pixels back into a wall to look right.
*/
/*QUAKED --PathsEtcetera-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
Note that monsters in Dark Places will normally wander on their own.
Also used with Trains.
*/
/*QUAKED info_target (0 0.5 0) (-4 -4 -4) (4 4 4)
Invisible entity. Used as an optional
target for trap_spikeshooter etc,
can follow path_corners as a moving
target for neat effects.

Keys:
"targetname"
 target name.
"target" (optional)
 if specified it will start at
 this path_corner,
 and follow the path.
"speed"
 movement speed (default 100)
*/
/*QUAKED havoc_waypoint (.7 .3 1) (-8 -8 -8) (8 8 8) EscapeWater HookWall UpOnly
Waypoint for havoc bots,
place these at bends in halls etc,
so the bots can find their way.

They will notice ammo etc along the way
and grab it, they are 'ok' at wandering,
but best to put these around.

They do not learn the map... :(

Also:
Place these where a button for a lift is,
and they will press the button
(trying to get to the waypoint),
so put one at the top of a lift and one at
the bottom and they will seem remotely
intelligent, but make sure the center of
the waypoint is visible.

If you want them to grapple up to a ledge
put the waypoint near the ceiling,
directly above the edge of the ledge,
also see the HookWall flag below.

Flags:
"EscapeWater"
 This waypoint will only be followed
 when near drowning, so put these out
 of the water to help the bots get out,
 like on the ceiling, as they will swim
 toward them, but stop when no longer
 drowning (meaning they got some air).
"HookWall"
 When waypoint is reached by grapple,
 the bot will then grapple the wall,
 useful in some places, stick a
 way point like this on the ceiling,
 and they will grapple up to it,
 then go to a wall, and go after
 ammo etc...
"UpOnly"
 Bots will only follow this way point when below it.
*/
/*QUAKED --WeaponsAndAmmo-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED ammobox_shells (0 .5 .8) (-4 -8 -4) (4 8 4)
rifle rounds.
*/
/*QUAKED ammobox_nails (0 .5 .8) (0 0 0) (32 32 32) big
chaingun rounds.
*/
/*QUAKED ammobox_rockets (0 .5 .8) (0 0 0) (32 32 32) big
bombs.
*/
/*QUAKED ammobox_cells (0 .5 .8) (0 0 0) (32 32 32) big
cells for plasma guns.
*/
/*QUAKED --Lights-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 300
Default style is 0
*/
/*QUAKED --AmbientAndStuff-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)
air bubbles as seen in e1m4,
does not appear in deathmatch.
*/
/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
/*QUAKED --TrainsAndPlats-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED func_train (0 .5 .8) ?
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed	default 100
dmg		default	2
sounds
1) ratchet metal

*/
/*QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed	default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determined by the model's height.
Set "sounds" to one of the following:
1) base fast
2) chain slow
*/
/*QUAKED --Teleporters-- (1 1 1) ?
DO NOT USE THIS
*/
/*QUAKED trigger_teleport (.5 .5 .5) ? PLAYER_ONLY SILENT
Any object touching this will be transported to the corresponding info_teleport_destination entity. You must set the "target" field, and create an object with a "targetname" field that matches.

If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
*/
/*QUAKED info_teleport_destination (.5 .5 .5) (-8 -8 -8) (8 8 32)
This is the destination
marker for a teleporter.

It should have a
"targetname" field with
the same value as a
teleporter's "target"
field.

Keys:
"dest"
 velocity on exiting
 teleport, nice for
 tricks.
 default: normal
 (throws player out
  a bit)
*/
/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
/*QUAKED misc_teleporttrain (0 .5 .8) (-8 -8 -8) (8 8 8)
This is used for the quake 'end' map.
*/
/*QUAKED --RotationStuff-- (1 1 1) ?
DO NOT USE THIS
*/
/*QUAKED rotate_object (.4 0 .7) ?
shape for rotating doors etc
this should target an info_rotate
to set center of rotation.
*/
/*QUAKED func_movewall (0 .5 .8) ? VISIBLE TOUCH
solid invisible wall,
moved as part of rotating
objects to simulate a solid
rotating object,
which the quake engine does
not directly support.
should be targeted by
func_rotatedoor along with
the rotate_object.

Flags:
"VISIBLE"
 makes the movewall visible,
 only useful for testing.

"TOUCH"
 set this to cause damage when
 touched, not just when blocked.

Keys:
"dmg"
 damage to do when touched or blocked,
 overrides owner damage.
*/
/*QUAKED func_rotatingdoor (.6 0 .9) (-8 -8 -8) (8 8 8) NOREVERSE TOGGLE
rotating door,
target a rotate_object to make
it visible.
and some func_movewall entities
to make it solid, normally
good to place them along the
door, every 16 or 32 units, but
depends on the door.

Flags:
"NOREVERSE"
 will crush things instead of
 reversing direction when
 blocked, useful when making a
 door to to block off an area.
"TOGGLE"
 opens/closes when triggered,
 rather than just opening.

Keys:
"dmg"
 damage to cause when blocked,
 default is 2, use -1 for no
 damage.
 func_movewall entities can
 have their own damage setting
 which overrides this.
"speed"
 how long it takes
 to completely open/close
"dest"
 end angles (pitch yaw roll).
"wait"
 how long to stay open.
 default: 3 seconds
"target"
 of course this must be set
"targetname"
 you should know this one...
"group"
 you can group rotating doors
 and some other things,
 when grouped all rotating
 doors will reverse direction
 at the same time etc.
"deathtype"
 as with basically all things
 in Dark Places, deathtype
 is message when something is
 killed by this.
 default: " got in the way"
"sounds"
1) medieval (default)
2) metal
3) base
*/
/*QUAKED func_rotatingobject (.6 0 .9) (-8 -8 -8) (8 8 8) STARTON
a rotating 'thing'
like a gear in a machine
or a spinning fan etc...

target a rotate_object to make
it visible, and some
func_movewalls to make it
solid, doesn't need to be
solid in all cases.
(if there is no way to find
 out if it is solid in game,
 then it doesn't need to be
 solid, note that shots would
 show it was not solid,
 *IF* they can reach it.
 if behind a window, be sure
 to make the window a
 func_invisiblewall and no
 shots can go through)

Flags:
"STARTON"
 easy to guess this one,
 meaningless if it can't be
 triggered.

Keys:
"dmg"
 damage to cause when blocked.
 default: 0
 func_movewall entities can
 have their own damage setting
 which overrides this.
"delay"
 how long it takes
 to completely spin up/down.
 default: 0 (instant)
"rotate"
 rotation per second (degrees)
 (pitch yaw roll).
"target"
 of course this must be set
"targetname"
 if set, it will only
 start/stop spinning when
 triggered, rather than
 simply spinning all the time.
"deathtype"
 as with basically all things
 in Dark Places, deathtype
 is message when something is
 killed by this.
 default: " got in the way"
*/
/*QUAKED info_rotate (0 .5 0) (-8 -8 -8) (8 8 8)
rotate_objects target this to
set center of rotation.
*/
/*QUAKED --Traps-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser fireball lightning fire ice plasma onlystrike
When triggered, fires a spike in
the direction determined by angle.

Flags:
"superspike"
 fires large spikes
"laser"
 fires laser
"fireball"
 fires fireballs (without gravity)
"lightning"
 fires lightning
 (only fires with a target,
  either an info_target or when
  striking something)
"fire"
 fires fireballs (with gravity)
"ice"
 fires ice
"plasma"
 fires plasma
"onlystrike"
 does not fire unless striking
 at something

Keys:
"deathtype"
 as with nearly all things in
 Dark Places, deathtype is
 the kill message.
 default: depends on shot type
"angle"
 angle to fire
 (can be pitch yaw roll,
  useful for throwing fireballs)
"target"
 much better than angle setting.
"speed"
 speed of shot - default 500
 (not applicable to lightning)
"dmg"
 how much damage the shot does
 default depends on shot:
 spike - 15
 superspike - 25
 laser - 15
 fireball - 15
 lightning - 30
 fire - 15
 plasma - 20 radius damage,
          5x in water
"count"
 how many shots are fired per
 burst.
"delay"
 time between shots in a burst.
"strikedist"
 max distance for striking.
 (meaning it acts as a turret)
*/
/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser fireball lightning fire ice plasma onlystrike
Continuously fires spikes.

Flags:
"superspike"
 fires large spikes
"laser"
 fires laser
"fireball"
 fires fireballs (without gravity)
"lightning"
 fires lightning
 (only fires with a target,
  either an info_target or when
  striking something)
"fire"
 fires fireballs (with gravity)
"ice"
 fires ice
"plasma"
 fires plasma
"onlystrike"
 does not fire unless striking
 at something

Keys:
"deathtype"
 as with nearly all things in
 Dark Places, deathtype is
 the kill message.
 default: depends on shot type
"angle"
 angle to fire
 (can be pitch yaw roll,
  useful for throwing fireballs)
"target"
 much better than angle setting.
"speed"
 speed of shot - default 500
 (not applicable to lightning)
"dmg"
 how much damage the shot does
 default depends on shot:
 spike - 15
 superspike - 25
 laser - 15
 fireball - 15
 lightning - 30
 fire - 15
 plasma - 20 radius damage,
          5x in water
"count"
 how many shots are fired per
 burst.
"delay"
 time between shots in a burst.
"strikedist"
 max distance for striking.
 (meaning it acts as a turret)
"wait"
 delay between start of bursts.
 (not the time between bursts,
  but the time between the
  start of each burst)
*/
/*QUAKED --TricksAndFX-- (1 1 1) ?
DO NOT USE THIS
*/
/*QUAKED event_lightning (0 1 1) (-16 -16 -16) (16 16 16)
Just for boss level.
*/
/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
*/
/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
*/
/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
*/
/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/
/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
Exploding box, as seen in e1m1, e2m1, e3m1, and e4m1.
*/
/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Small exploding box, seen in e2m1, e3m1, and e4m1.
*/
/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/
/*QUAKED trigger_forcefield (1 .5 0) ? PLAYERONLY SILENT STARTOFF TOGGLE WALL
anything touching this can be pushed away,
can be blocked, and can be hurt.

when targeted it will flash off/on
see STARTOFF, TOGGLE and delay

flags:
"PLAYERONLY"
 only affects players, still flashes
 on monsters, but no effect.
"SILENT"
 no hum or push sound.
"STARTOFF"
 works in reverse, normally off, on when targeted.
"TOGGLE"
 switches on/off when targeted.
"WALL"
 is totally solid when on.

keys:
"dmg"
 amount of damage to do when touched, default 0
"delay"
 how long it will stay switched when
 targeted, ignored with TOGGLE.
"speed"
 how much force, default 0
"targetname"
 guess (flashes when targeted)
"target"
 triggered on touch
*/
/*QUAKED trigger_shake (1 .5 0) ? PLAYERONLY SILENT STARTON TOGGLE
any player touching this feels an earthquake.

when targeted it will flash on/off
see STARTON, TOGGLE and delay

flags:
"PLAYERONLY"
 only affects players.
"SILENT"
 no sound.
"STARTON"
 works in reverse, normally on, off when targeted.
"TOGGLE"
 switches on/off when targeted.

keys:
"delay"
 how long it will stay switched when
 targeted, ignored with TOGGLE.
"targetname"
 guess (flashes/toggles when targeted)
*/
/*QUAKED effect_spinningspotlight (0 1 0) (-8 -8 -8) (8 8 8)
A spinning spot light,
nifty disco like effects or anything
else you think up.

Keys:
"startangles"
 starting direction in degrees (pitch yaw roll)
"rotate"
 rotation speed in degrees per second (pitch yaw roll)
*/
/*QUAKED func_invisiblewall (0 .5 .8) ? STARTOFF
invisible wall,
toggles on/off when triggered.

better than invisible walls
made with CLIP texture
as bullets etc can't go
through this.

Flags:
"STARTOFF"
 uh, guess...
*/
/*QUAKED func_xplowall (0 .5 .8) ? NoHeal SilverKey GoldKey

Normally you must do enough damage
in one blast to break the wall.

Flags:
"NoHeal"
 progressive damage will break
 this wall.
"SilverKey"
 will break if touched by player
 with silver key.
"GoldKey"
 will break if touched by player
 with gold key.

Keys:
"targetname"
 will break if targeted.
"target"
 will trigger when destroyed.
"health"
 if health is -1 then can only be
 broken by targeting and keys,
 default 100
 (close pipebomb will break).
"dmg"
 explosions do this much radius
 damage if set.
 (rockets do 120, plasma does 15)
"count"
 how many pieces of debris
 (releases this much debris
  total, some every explosion)
 (default is 5, -1 for no debris)
"count2"
 how many explosions
 (will release debris with none)
 (default is 3, use -1 for none)
"delay"
 time between explosions
 default: 0.1
"wait"
 time before respawning
 (default is no respawn)
 (this time is counted from the
  last explosion)
"style"
 type of debris,
 hard to describe these:
0) red
1) yellow
2) green
3) blue
4) brown
5) biege
6) rock
*/
/*QUAKED func_wallchunk (0 .5 .8) ?
wall chunk, destroyed by damage.

you must do enough damage
in one blast to break the wall.

simply a nice effect,
used in Dark Places maps.

make a hole in the wall,
cover it with a
func_wallchunk,
set the style for debris,
and you've got a wall that
gets damaged in a fight.

actually just a simplified
func_xplowall.

normally 3 pieces of debris.
set count to a dif # if you
like.
no explosions.

Keys:
"count"
 how many pieces of debris.
 default is 3.
"style"
 type of debris,
 hard to describe these:
0) red
1) yellow
2) green
3) blue
4) brown
5) biege
6) rock
*/
/*QUAKED trigger_hurt (.5 .5 .5) ?
Anything touching will be hurt.

Keys:
"dmg"
 damage amount
 default: 5
"cnt"
 how many times to trigger,
 default: unlimited
*/
/*QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters touching
this will jump in the
direction of the angle.

Keys:
"speed"
 horizontal speed
 default: 200
"height"
 upward speed
 default: 200
*/
/*QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE SILENT
Pushes anything that
touches it.

improved version of
normal trigger_push.

now pushes more than just
players and grenades,
pushes rockets, gibs,
monsters, shell casings,
etc, pushes anything
that can move...

Flags:
"PUSH_ONCE"
 removes itself after push
"SILENT"
 no 'windtunnel' noise

Keys:
"angles"
 direction to push.
 (usual Quake thing)
"speed"
 how fast.
 (usual Quake thing)
"movedir"
 direction and speed of push,
 better than angles.
*/
/*QUAKED --Triggers-- (1 1 1) ?
DO NOT USE THIS
*/
/*QUAKED misc_ticker (0 .6 .8) (-8 -8 -8) (8 8 8)
Triggers it's targets
every "delay" seconds.

if targetname is set,
it will only tick in bursts of
"count" times and only when
triggered.

Keys:
"delay"
 time between triggers,
 default 0.1, cannot go below 0.1.
"count"
 how many pulses to do when targeted
 not used unless targetname is set
 default 1
"targetname"
 as mentioned above
"target"
 must be set
*/
/*QUAKED trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/
/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
/*QUAKED trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by trigger_relay!
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
/*QUAKED trigger_once (.5 .5 .5) ? notouch
Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
"targetname".  If "health" is set, the trigger must be killed to activate.
If notouch is set, the trigger is only fired by other entities, not by touching.
if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
sounds
1)	secret
2)	beep beep
3)	large switch
4)
set "message" to text string
*/
/*QUAKED trigger_onlyregistered (.5 .5 .5) ?
Only fires if playing the registered version, otherwise prints the message
*/
/*QUAKED trigger_secret (.5 .5 .5) ?
secret counter trigger
sounds
1)	secret
2)	beep beep
3)
4)
set "message" to text string
*/
/*QUAKED trigger_setskill (.5 .5 .5) ?
sets skill level to the value of "message".
Only used on start map.
*/
/*QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Should be only one per MAP.

Keys:
"wad"
 which graphics wad to use
"message"
 sets the title of the map
"worldtype"
 normal quake maps:
 0 = medieval
 1 = metal
 2 = base
 Dark Places world types:
 3 = medieval
 4 = metal
 5 = base
 Dark Places maps have special
 properties such as 3x falling
 damage
 (falling 1024 units is like
  270 damage rather than 90)
 you should use one of the
 Dark Places world types if
 making a map for Dark Places

 MUST be set when using keys!
"sounds"
 CD track to play
"light"
 default light level
*/
/*QUAKED --WeirdStuff-- (1 1 1) ?
DO NOT USE
*/
/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
Lord Havoc's note:
Quake has been out for like two years and this thing is still here, because it's needed for a lot of the id maps, strange but true.
*/
/*QUAKED item_deathball (.3 .3 1) (0 0 0) (32 32 32)
*/
/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
/*QUAKED trigger_jctest (.5 .5 .5) ?
*/
/*QUAKED test_teleport (0 .5 .8) ?
Teleporter testing
*/
/*QUAKED test_fodder (0 .5 .8) ?
beating guy
*/
/*QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)
Just for the debugging level.  Don't use
*/
/*QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)
For optimzation testing, starts a lot of sounds.
*/
