# Quake MegaMod
Quake MegaMod is a collection of mods  for multiplayer deathmatch, and is compatible with the 2021 release of Quake

## Mod Details
This changes the weapons and gameplay features of Quake (id1) maps.
Current Modifications Include:
* Grapple Hook: impulse 24 & 25 both extend and break the chain
* Super Laser Gun (Select Super Shot Gun twice): Fire two lasers. A classic mod that was either featured on the regular shotgun, or the super shotgun at the cost of 5 shells
* Trip Wire Gun (Select Super Nail Gun twice): Attach a tripwire on the wall that can be destroyed with rockets at the costs if 50 nails
* Cluster Grenade Gun (Select Grenade Launcher twice): Classic cluster grenade launcher, turns into a cluster of grenades that do 50% regular damage (The one I originally remember wouldn't explode on impact, but this will do until I can figure out how to get it to bounce, then cluster explode)
* Flare Gun (Select Grenade Launcher three times): A grenade that functions as a light source for a minute, which is useful for when someone turns the lights off (see Light Controller weapon)
* Homing Rocket Launcher (Select Rocket Launcher twice): A homing rocket that will fly around and avoid walls until it starts tracking someone
* BFG (Select Lightning Gun twice): Classic BFG, a slow moving lava ball that kills everyone in a small radius on impact. Costs 25 cells. (I might make this cost 50 cells, and double the radius)
* Light Controller (Select Lightning Gun three times): A classic mod I remember would allow players to vote to turn the lights on and off. Since the vote used impulse commands, to keep things it accessible to console players I created this weapon instead
* Biosuit has been replaced with Haste (I gave it a Blue Key model): It makes everything you do faster (I also removed the damage from Slime)
* Reduced item respawn time in half for most items, and the rest has a 1/3 time reduction
* Extra Gibs! The requires for players to gib is -10 health, instead of -40 health. There's 3x as many gibs, and they can be kicked around until they disappear. Also all hanging zombies are now killable and gib after 40 damage
* Map Start has the func_bossgate removed which opens the arena for more deathmatch
* Custom Death messages for the weapons I've added to the mod (EG: Tenetri was deleted by Tenetri's Homing Missile)
* All maps show up with (MegaMod) inside the map name (Thanks to JPiolho)

## Installation
1. Goto your 'Saved Games', NOT THE STEAM FOLDER. Access this by using Run (Windows Key + R) and typing: %userprofile%\Saved Games\Nightdive Studios\Quake\
2. If it doesn't already exist, create a folder called "id1"
3. Also, if it doesn't already exist, create another folder called "mod"
4. Extract the contents of the ZIP into the folder called "id1" created in step 2. Please back up or delete and existing files in this folder before extracting

## How to play
1. Once in game, open the console and type > bind f10 "game mod"
2. Whenever you launch Quake and want to start a server with this mod, press f10 before starting the server. 
Note: If you forget to press F10 and your game has already started, press Esc, then select "End Game" and once your back at the lobby screen press F10

## Notes
This is my first ever Quake server mod. I used to make maps for this game back in 1999-2002, and though server mods were neat. I just didn't have the resources to learn how to do it. Now almost 20 years later, I finally took the time and made this. It's more or less a tribute to all the old mods I remember from back then. I started this project not even knowing how to compile a Quake server mod, so it was a lot of fun for me. If you read though the source code, I apologize for how horribly its written lol.

## Credits
Tenetri: Author

Special thanks to JPiolho, Dan the Man, the Quake Mapping Discord Community
