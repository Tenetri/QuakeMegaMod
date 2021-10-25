/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;


// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun
	precache_sound ("enforcer/enfstop.wav"); // laser shot gun
    precache_sound ("enforcer/enfire.wav"); // laser sizzle
    precache_model ("progs/laser.mdl"); // laser model laser shot gun
	
	precache_model ("progs/s_light.spr"); // grapple hook
	
	precache_sound ("misc/basekey.wav");    // Laser Trip Bomb activate sound
	precache_sound ("weapons/deploy.wav");  // Laser Trip Bomb weapon sound
	precache_model ("progs/lavaball.mdl");  // Laser Trip Bomb modelasdf
};

float() crandom =
{
	return 2*(random() - 0.5);
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org;

	makevectors (self.v_angle);
	source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1.0)
		return;

	org = trace_endpos - v_forward*4;

	if (trace_ent.takedamage)
	{
		trace_ent.axhitme = 1;
		SpawnBlood (org, '0 0 0', 20);
		T_Damage (trace_ent, self, self, 20);
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};


//============================================================================


vector() wall_velocity =
{
	local vector	vel;

	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local	entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';

// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity	multi_ent;
float	multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;

	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local	vector	vel, org;

	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
	{
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local	vector direction;
	local	vector	src;

	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};
/*
http://www.insideqc.com/qctut/qctut-4.shtml
Laser Super Shot Gun (modified to fit into my code)
Credits: Mr. Pink

*/
void() LaserHit =
{
        local vector org;
        
        if (other == self.owner)
                return;         // don't explode on owner

        if (pointcontents(self.origin) == CONTENT_SKY)
        {
                remove(self);  
                return;
        }
        //Sizzle noise that you hear when the enforcer's laser contacts
        sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
        org = self.origin - 8*normalize(self.velocity);

        if (other.health)
        {
                SpawnBlood (org, self.velocity*0.2, 40);
                T_Damage (other, self, self.owner, 60); 
        // You can change the amount of damage it does
        }
        else 
        {
                WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
                WriteByte (MSG_BROADCAST, TE_GUNSHOT);
                WriteCoord (MSG_BROADCAST, org_x);
                WriteCoord (MSG_BROADCAST, org_y);
                WriteCoord (MSG_BROADCAST, org_z);
        }       
        remove(self);   
};

void() W_FireLaserSuperShotgun =
{
    local vector dir; 
    local vector dir2;
    local entity newmis2;

    self.currentammo = self.ammo_shells = self.ammo_shells - 5;
    sound (self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM); 

    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;

    dir = aim (self, 1000);
    newmis.angles = vectoangles(dir);

    newmis.touch = LaserHit;
    newmis.classname = "laser";
    newmis.nextthink = time + 6; // Time before laser disappears
    newmis.think = SUB_Remove;
    newmis.effects = self.effects | EF_DIMLIGHT; // Make it glow a little
    setmodel (newmis, "progs/laser.mdl");
    setsize (newmis, '0 0 0', '0 0 0'); 

    setorigin (newmis, self.origin + v_forward*8 + v_right*-3 + '0 0 16'); // make it go a little to the left. 
    newmis.velocity = dir * 1000;
// What are you gonna see next is just a copy of whats above but with all the newmis renamed to newmis2 and all the dir renamed to dir2.
    newmis2 = spawn ();
    newmis2.owner = self;
    newmis2.movetype = MOVETYPE_FLYMISSILE;
    newmis2.solid = SOLID_BBOX;

    dir2 = aim (self, 1000);
    newmis2.angles = vectoangles(dir2);

    newmis2.touch = LaserHit;
    newmis2.classname = "laser";
    newmis2.nextthink = time + 6; 
    newmis2.think = SUB_Remove;
    newmis2.effects = self.effects | EF_DIMLIGHT; 
    setmodel (newmis2, "progs/laser.mdl");
    setsize (newmis2, '0 0 0', '0 0 0'); 
    setorigin (newmis2, self.origin + v_forward*8 + v_right*3  + '0 0 16');  //make it go a little to the right
    newmis2.velocity = dir * 1000;
};

/*
================
W_FireSuperShotgun
================
*/


void() W_FireSuperShotgun =
{
	local vector dir;

	if (self.currentammo == 1)
	{
		W_FireShotgun ();
		return;
	}

	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

	self.punchangle_x = -4;

	self.currentammo = self.ammo_shells = self.ammo_shells - 2;
	dir = aim (self, 100000);
	FireBullets (14, dir, '0.14 0.08 0');
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() T_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 100 + random()*20;

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other);

	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};



/*
=================
Hunter Killer
By: Sestze (enjoy!)
(Tenetri: I got found it from here, thank you Sestze (added to my code in 2021)- http://www.insideqc.com/qctut/qctut-83.shtml )
=================
*/

//Function Prototypes
void() W_HunterFire;
void() T_HunterTouch;
void() S_HunterThink;
entity(entity startz, float cr_range, float wall) Checkrad;

//Fire Function
void() W_HunterFire =
{
	sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM); 	//Classic rocket fire
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 5; 	//Subtract a rocket
	
	local entity hunter; 						//Make an entity
	
	hunter = spawn(); 						//Spawn it
	hunter.classname = "Hunter killer"; 				//Give it a classname
	hunter.owner = self; 						//You own this baby.
	hunter.oldenemy = self;						//You will need this
	hunter.movetype = MOVETYPE_FLY; 				//Flies around
	hunter.solid = SOLID_BBOX; 				//Solid - Touch on edge, block (Pickable items and missiles)
	
	makevectors(self.v_angle);					//Make vectors from your current viewing angle
	hunter.velocity = v_forward * 240;			//Fly forward at 240 units (trust me, you will want this)
	hunter.angles = vectoangles(hunter.velocity);			//Set the angles for the object
	
	hunter.nextthink = time + 0.25;					//Quarter second out, activate
	hunter.think = S_HunterThink;					//Activation and thinking function
	
	hunter.touch = T_HunterTouch;					//Touch Function
	
	setmodel(hunter, "progs/missile.mdl");				//Set the model
	setsize(hunter, '0 0 0', '0 0 0');				//Set the size
	setorigin(hunter, self.origin + '0 0 16');			//Set the origin
};

//Touch function
void() T_HunterTouch =
{
	if(other == self.owner)						//Don't want it blowin up on ya, do ya?
		return;

	T_RadiusDamage (self, self.oldenemy, 100, world);		//Damage!
			
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);			//Temp entity - Explosion
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion();
};

//Think code
void() S_HunterThink =
{
	//Hunter finds an enemy
	if((self.enemy == world) || (self.enemy.health < 0))		//Checks if enemy is dead or doesnt have enemy
		self.enemy = Checkrad(self, 1000, TRUE);
			
	//Declarations
	local vector vele, vels;					//velocity enemy, velocity self
	local vector ph;						//Place holder
	
	//The tack to opponent
	vele = (self.enemy.origin + '0 0 16') - self.origin;		//Finds the unit vector towards the enemy
	vele = normalize(vele);
	
	//Current tack
	vels = normalize(self.velocity);				//defines current vector
	
	//Check tack to enemy
	traceline(self.origin, self.origin + vele * 10000, FALSE, self);	//Traceline to enemy
	
	if((trace_fraction != 0) && (self.enemy != world))
	{
		//Placeholder
		ph = vele + vels + vels + vels + vels;			//Enemy velocity plus 4 times self velocity
		
		//Placeholder over three
		ph = ph * (1/5);					//Averaging
		
		//Setvelocity and here we go!	
		self.velocity = normalize(vels + ph);			//Set the velocity
		self.velocity = self.velocity * 240;			//And you are on your way
	}
		
	//Check current tack 320 units ahead
	traceline(self.origin, self.origin + vels * 320, FALSE, self);	//Traceline in front (check for walls)
	
	if((trace_fraction < 0.2))
	{
		ph = trace_plane_normal;				//Find direction that is perpindicular to the wall
		ph = ph + vels + vels;					//Add that direction plus two times your own
		ph = ph * (1/3);					//Averaging
		
		self.velocity = normalize(vels + ph);			//Set the velocity
		self.velocity = self.velocity * 240;			//And you are on your way
	}
	
	//Set the angles	
	self.angles = vectoangles(self.velocity);			//Set angle
	self.aflag = self.aflag + 1;					//Add to "idle hands" counter
	
	if(self.aflag >= 2000)						//origionally set to 500, changed to 2000 (about a minute)
	{
		//self.owner = world;					//this was the origional code, i changed it to remove(self); because they sometimes get trapped in corners and stay there forever.
		remove(self);							// Added by Tenetri 2021
	}
	
	//Hunter thinks
	self.nextthink = time + 0.01;					//Nextthink will be quick to avoid running into walls
};

//Check radius function
entity(entity startz, float cr_range, float wall) Checkrad =
{
	local entity finder;						//The .chain entity
	local float cr_ran;						//The range holder
	local entity blodger;						//Entity placeholder
	cr_ran = 1200;							//Set to above the detection radius
	
	finder = findradius(startz.origin, cr_range);			//Finds anything within cr_range units of self
	
	while(finder)
	{
		if((CanDamage(finder, self)) || (!wall))	//If I can see him, or if I just ignore walls alltogether
		{
			if(finder.health > 0)				//If he lives
			{
				if(finder != self.owner)		//If he aint my daddy
				{
					if(vlen(finder.origin - self.origin) < cr_ran)	//If the range of that guy is less than the previous
					{
						blodger = finder;	//Blodger holds who that is
						cr_ran = vlen(finder.origin - self.origin);	//resets cr_ran for next time
					}
				}
			}
		}
		finder = finder.chain;	//Loop chain
	}
	if(blodger != world)	//If Blodger isn't the world
		return blodger;	//blodger is returned
	else			//If blodger = world
		return world;	//return the world
};



/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
	local	entity missile;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";

// set missile speed

	makevectors (self.v_angle);
	missile.velocity = aim(self, 1000);
	missile.velocity = missile.velocity * 1000;
	missile.angles = vectoangles(missile.velocity);

	missile.touch = T_MissileTouch;

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity		e1, e2;
	local vector		f;

	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
	if (trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
};

void() LightningHit =
{        
	local	vector org; // creates org vector
	//local	float damage=0; // floats damage starting at 0
	local	entity head; //creates head entity

	org = self.origin + '0 0 16'; // vector org origin
	head = findradius(self.origin, 250); //send lightning line to anything in 250 radius
	while (head) // while looking for head
	{
		if (head.takedamage)  // if head has health, attack it
		{
			if(head != self.owner) // don't attack thunderbolt owner!!
            {
				WriteByte (MSG_BROADCAST, SVC_TEMPENTITY); // temp entity
				WriteByte (MSG_BROADCAST, TE_LIGHTNING2); // makes lightning line i think
				WriteEntity (MSG_BROADCAST, head); // write head entity
				WriteCoord (MSG_BROADCAST, org_x); // write orgs x coord
				WriteCoord (MSG_BROADCAST, org_y); // write orgs y coord
				WriteCoord (MSG_BROADCAST, org_z); // write orgs z coord
				WriteCoord (MSG_BROADCAST, head.origin_x); // write heads x coord
				WriteCoord (MSG_BROADCAST, head.origin_y); // write heads y coord
				WriteCoord (MSG_BROADCAST, head.origin_z); // write heads z coord
				sound (head, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM); // its sound
				//damage = 40 + random()*20; // 40 plus some random damage
				//T_Damage (head, self, self.owner, damage); // its damage
				T_RadiusDamage (self, self.owner, 500, self);
			}
		}
        head = head.chain; // go to next enemy
	}
        remove(self);
};

/*
http://www.insideqc.com/qctut/lesson-51.shtml
W_FireLightning (Modified to W_FireLightning) Credits: Cheezer
This came preloaded with a custom model, which i replaced with progs/lavaball.mdl. 
I modified this pretty heavily to work with my code. I don't remember how much it resembles the origional code.
I added an area of effect explosion, slowed the weapon down considerably, and made it cost 25 cells instead of 1.
Anyways, if this looks nothing like the origional code, then know the code atleast gave me a starting point to learn how to make the classic BFG
*/

void() W_FireBFGLightning =
{
	local	entity thunderbolt; // create thunderbolt entity

    if (self.ammo_cells < 25) // if u have more than 1 cell, this is the best weapon
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
			return;
	}
	self.currentammo = self.ammo_cells = self.ammo_cells - 25; // ammo it uses
	self.punchangle_x = -2; // kickback angle
	thunderbolt = spawn (); // spawning it
	thunderbolt.owner = self; // self (you) is owner of thunderbolt
	thunderbolt.movetype = MOVETYPE_FLYMISSILE; // flies straight on
	thunderbolt.solid = SOLID_BBOX; // its solid
	thunderbolt.classname = "thunderbolt"; // name it thunderbolt
	makevectors (self.v_angle); // i dont know
	thunderbolt.velocity = aim(self, 1000); // dont know this either
	thunderbolt.velocity = thunderbolt.velocity * 700; //speed of 1000
	thunderbolt.angles = vectoangles(thunderbolt.velocity); // dont know
	thunderbolt.touch = LightningHit; // calls LightningHit when touched
	thunderbolt.nextthink = time + 5; // disappears after flying for 5 seconds
	thunderbolt.think = SUB_Remove; // does nothing after 5 seconds
	setmodel (thunderbolt, "progs/lavaball.mdl"); // sets the thunderbolt model
	setsize (thunderbolt, '0 0 0', '0 0 0'); // thunderbolt model size
	setorigin (thunderbolt, self.origin + v_forward*8 + '0 0 16'); // thunderbolt spawn origin
};

void() W_FireLightning =
{
	local	vector		org;
	local	float		cells;

	if (self.ammo_cells < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
	if (self.waterlevel > 1)
	{
		cells = self.ammo_cells;
		self.ammo_cells = 0;
		W_SetCurrentAmmo ();
		T_RadiusDamage (self, self, 35*cells, world);
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

	self.currentammo = self.ammo_cells = self.ammo_cells - 1;

	org = self.origin + '0 0 16';

	traceline (org, org + v_forward*600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (self.origin, trace_endpos + v_forward*4, self, 30);
};


//=============================================================================

/*
http://www.insideqc.com/qctut/lesson-19.shtml

ClusterExplode Credits: Smoke2Much
Modified this sleightly to fit into my code

*/

void() ClusterExplode =
{
    T_RadiusDamage (self, self.owner, 60, world);    //Damage Variables, notice the third..
                                                     //...which only does 60 damage
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);    //Create temporary entity
    WriteByte (MSG_BROADCAST, TE_EXPLOSION);    //Tell engine the temp entity is an explosion
    WriteCoord (MSG_BROADCAST, self.origin_x);    //x coordinate of explosion
    WriteCoord (MSG_BROADCAST, self.origin_y);    //y coordinate of explosion
    WriteCoord (MSG_BROADCAST, self.origin_z);    //z coordinate of explosion
    BecomeExplosion ();    //Create explosion
};

void() GrenadeExplodeAlt =
{
    local float cluster=0;    //create a variable called cluster that equals zero
    local entity missile;    //create an entity called missile

    while (cluster < 5)    //while cluster is less than 5
    {
        cluster=cluster+1;    //add one to cluster
        missile = spawn ();    //spawn a missile
        missile.owner = self;    //missiles owner is player
        missile.movetype = MOVETYPE_BOUNCE;    //the missile will bounce
        missile.solid = SOLID_BBOX;     //the missile IS solid
        missile.classname = "grenade";

        // set missile speed

        missile.velocity_z = 500;    //missiles upward speed=500
        missile.velocity_x = -100 + (random() * 200);    //missiles x and y velocitys..
        missile.velocity_y = -100 + (random() * 200);    //are randomish
        missile.avelocity = '300 300 300';    //missiles rotating velocity
        missile.angles = vectoangles(missile.velocity);

        // set missile duration

        missile.nextthink = time + 1.5;    //Time before clusters go off
        missile.think = ClusterExplode;    //Where to go after time's up
        missile.touch = ClusterExplode;    //If touched then explode
        setmodel (missile, "progs/grenade.mdl");    //Missile model
        setsize (missile, '0 0 0', '0 0 0');    //Missile model size
        setorigin (missile, self.origin);    //Where the missile will appear
    }   //End of while loop

    T_RadiusDamage (self, self.owner, 20, world);    //This code and below destroys
                                   //The original grenade in a small explosion
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte (MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord (MSG_BROADCAST, self.origin_x);
    WriteCoord (MSG_BROADCAST, self.origin_y);
    WriteCoord (MSG_BROADCAST, self.origin_z);

    BecomeExplosion ();
};

void() FlareExplode =
{
	T_RadiusDamage (self, self.owner, 0, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/
void() W_FireAltGrenade =
{
	local	entity missile;

	self.currentammo = self.ammo_rockets = self.ammo_rockets - 3;  //Cluster Bomb Edit - From 1 to 3

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";

// set missile speed

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = GrenadeExplodeAlt;				//Cluster Bomb Edit - GrenadeTouch to GrenadeExplode 

// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplodeAlt;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

/*
Flare Credit: A. George Corrigan
http://www.insideqc.com/qctut/lesson-26.shtml
*/

void() W_FireFlare =
{
	local	entity missile;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";
	
	if(random() < 0.1) 
	{
		missile.effects = missile.effects | EF_DIMLIGHT;
	}else{
		missile.effects = missile.effects | EF_BRIGHTLIGHT;
	}

// set missile speed

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = GrenadeTouch;

// set missile duration
	if(lightstats)
	{
		missile.nextthink = time + 180;
	}else{
		missile.nextthink = time + 10;
	}
	
	missile.think = FlareExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

void() W_FireGrenade =
{
	local	entity missile;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";

// set missile speed

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = GrenadeTouch;

// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
================
W_FireLTB Laser Trip Bomb --(C) 1997 Frika C
================
*/

void() LTB_Detonate =

{
        self.th_pain = self.th_pain;
        self.th_die = SUB_Null;         // switched to null to avoid chain reaction when exploding (repeatedly kills itself!)
        self.owner = self.enemy;        // Return Property rights so the player gets credit

        T_RadiusDamage (self, self.owner, 250, world); // Do some damage

        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_EXPLOSION);
        WriteCoord (MSG_BROADCAST, self.origin_x); // Standard Textbook explosion code
        WriteCoord (MSG_BROADCAST, self.origin_y);
        WriteCoord (MSG_BROADCAST, self.origin_z);

        BecomeExplosion ();
};
void() LTB_Explode =

{
        sound (self, CHAN_AUTO, "misc/basekey.wav", 1, ATTN_NORM);
        self.nextthink = time + 0.2;
        self.think = LTB_Detonate;      // A quick little function to play the trigger wav before detonation
};



void() LTB_Pain =

{
                self.health = 40;       //didn't kill it.....probably a distant explosion
};

void() LTB_Arm =

{
        local vector org;                               // Origin of the LTB
        local vector targ;                      // Target "       "
        
        makevectors(self.angles);               // Load the current looking position into v_forward
        org = self.origin + self.view_ofs;      // Set the origin;
        targ = org + v_forward * 2000;  // 2000 is the maximum distance of the bomb
        traceline(org, targ, FALSE, self);      // Traceline outward
        if (trace_fraction == 1.0)              // If hit nothing in 2000 units
        {
                LTB_Explode(); // Explode if wall is too far away
                return;
        }
        if ((trace_ent == self.enemy) && (self.weapon == FALSE)) //Weapon indicates if the LTB is armed yet
        {                                                                          //And enemy is the owner
                self.nextthink = time + 1; // Don't Arm until player is out of the way
                self.think = LTB_Arm;           // Wait yet another second (move it buster!)
                return;                 
        }
        if (self.weapon == FALSE)               // If not armed...
                self.weapon = TRUE; // arm....watch out!
        if ((trace_ent.velocity != '0 0 0') || (trace_ent.flags & FL_MONSTER)) // If object is moving or monster
        {// The above FL monster check was put in because some monsters could walk through
        // The beam without being detected (they don't have a velocity, they're using movetogoal())                     
                LTB_Explode();  // Kaboom!
                return;
        }
        if (self.attack_finished < time)        // Attack_finished keeps track of when the beam should be refeshed
        {
        WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte (MSG_BROADCAST, TE_LIGHTNING2);               // Fire lightning two.
        WriteEntity (MSG_BROADCAST, self);
        WriteCoord (MSG_BROADCAST, org_x);                      //This is a lighting brodcast.
        WriteCoord (MSG_BROADCAST, org_y);
        WriteCoord (MSG_BROADCAST, org_z);
        WriteCoord (MSG_BROADCAST, trace_endpos_x);     // it happens every .2 secs
        WriteCoord (MSG_BROADCAST, trace_endpos_y);
        WriteCoord (MSG_BROADCAST, trace_endpos_z);     // but the think function occurs evey .07
        self.attack_finished = time + 0.2;                      // this allows fast reaction on the beam
        }                                                               // without crowding the network with broadcasts

        self.think = LTB_Arm;
        self.nextthink = time + 0.07;                   // 0.07 secs before checking again
};

void() W_FireLTB =

{
        local   vector  source;         // Where the player is
        local entity    lasertrip;      // New entity for spawning

        
        makevectors (self.v_angle);     // Make a vector of the players facing angle
        source = self.origin + '0 0 16';        // Up a little
        traceline (source, source + v_forward*64, FALSE, self); // Trace a line straight out
        if (trace_fraction == 1.0)      // hit nothing
                return;
        if (trace_plane_normal_z != 0)  // Wall is not perfectly vertical
                return;                         // can't stick to floor or slope....
        if (trace_ent != world)         // hit a door, monster etc.
                return;
        self.currentammo = self.ammo_nails = self.ammo_nails - 50;      // Take away 50 nails  (origionally 10, modified to 50 by Tenetri 2021
        lasertrip = spawn();            // Spawn a new dynamic entity
        lasertrip.owner = world;        // If the player is the owner he can't trigger it!
        lasertrip.enemy = self;         // Keep track of the owner to give him credit though
        lasertrip.movetype = MOVETYPE_NONE;     // doesn't move
        lasertrip.solid = SOLID_BBOX;
        lasertrip.classname = "laser_trip_bomb";        // Name for it
        lasertrip.angles = vectoangles(trace_plane_normal);     // This aligns it perpendicular to the wall it struck
        lasertrip.weapon = FALSE;               // weapon is used to flag if the bomb has been armed or not

        lasertrip.takedamage = DAMAGE_YES;      // Can be destroyed
        lasertrip.health = 40;
        lasertrip.th_pain = self.th_pain;           // This allows other explosions trigger it's explosion
        lasertrip.th_die = LTB_Detonate;

        lasertrip.think = LTB_Arm;              // Arm in one second
        lasertrip.nextthink = time + 1;
        lasertrip.attack_finished = time + 1;//Attack_finished keeps track of how long until it should re-draw the beam
        setmodel (lasertrip, "progs/lavaball.mdl");  // set the model
        setsize (lasertrip, '0 0 0', '0 0 0');  // See below            

        setorigin (lasertrip, trace_endpos);
        sound (self, CHAN_WEAPON, "weapons/deploy.wav", 1, ATTN_NORM); // Play the deployment sound
};

/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);

	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void() W_FireSuperSpikes =
{
	local vector	dir;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 2;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector	dir;

	makevectors (self.v_angle);

	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireSuperSpikes ();
		return;
	}

	if (self.ammo_nails < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right*ox, dir);

	self.punchangle_x = -2;
};


void() spike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};

void() superspike_touch =
{
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_SetCurrentAmmo =
{
	player_run ();		// get out of any weapon firing states

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );

	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
		sprint (self, "Axe Selected!\n");
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
		sprint (self, "Shotgun Selected!\n");
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
		sprint (self, "Super Shotgun Selected!\n");
	}
	else if (self.weapon == IT_LASER_SSG)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
		sprint (self, "Laser Super Shotgun Selected!\n");
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
		sprint (self, "Nail Gun Selected!\n");
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
		sprint (self, "Super Nail Gun Selected!\n");
	}
	else if (self.weapon == IT_PROX_MINE)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
		sprint (self, "Tripwire Gun Selected!\n");
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
		sprint (self, "Grenade Launcher Selected!\n");
	}
	else if (self.weapon == IT_CLUSTER_GL)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
		sprint (self, "Cluster Grenade Launcher Selected!\n");
	}
	else if (self.weapon == IT_FLARE_GUN)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
		sprint (self, "Flare Gun Selected!\n");
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
		sprint (self, "Rocket Launcher Selected!\n");
	}
	else if (self.weapon == IT_HOMING_RL)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
		sprint (self, "Homing Rocket Launcher Selected!\n");
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
		sprint (self, "Lightning Gun Selected!\n");
	}
	else if (self.weapon == IT_BFG)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
		sprint (self, "BFG Selected!\n");
	}
	else if (self.weapon == IT_LIGHT_CONTROL)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
		sprint (self, "Light Controller Selected!\n");
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = string_null;
		self.weaponframe = 0;
	}
};

float() W_BestWeapon =
{
	local	float	it;

	it = self.items;

	if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
		return IT_LIGHTNING;
	else if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
	else if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
		return IT_SUPER_SHOTGUN;
	else if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
		return IT_NAILGUN;
	else if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
		return IT_SHOTGUN;

	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;

	self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();

// drop the weapon down
	return FALSE;
};

/*
================
toggleLights

Credit: Tenetri 2021

Had fun learning how lightstyles work. There used to be a gamemode in Quake where players could vote to turn the lights on or off every 5 minutes.
I wanted to bring that back, but with some limitations of the new engine, voting in chat isn't possible. And the console isn't accessible to console players. 
I origionally had this linked to Impulse 98 and 99. Then I turned it into just Impulse 99, and now console players can use it too now that its attached to the lightning gun.
================
*/
void() toggleLights =
{
	if (self.ammo_cells >= 50)
	{
		if(lightstats == 0)
		{

			self.ammo_cells = self.ammo_cells - 50;
			lightstyle (0, "a");
			bprint (self.netname);
			bprint (" shut the lights OFF!\n");
			lightstats = 1;
		}else{
			self.ammo_cells = self.ammo_cells - 50;
			lightstyle (0, "m");
			bprint (self.netname);
			bprint (" turned the lights ON!\n");
			lightstats = 0;
			
		}
		sound (self, CHAN_AUTO, "ambience/thunder1.wav", 1, ATTN_NORM);
	}
}

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_nail1;
void()	player_light1;
void()	player_rocket1;
void()	player_light3;

void() W_Attack =
{
	local	float	r;

	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up

	if (self.weapon == IT_AXE)
	{
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		r = random();
		if (r < 0.25)
			player_axe1 ();
		else if (r<0.5)
			player_axeb1 ();
		else if (r<0.75)
			player_axec1 ();
		else
			player_axed1 ();

		if (self.haste_finished > time) self.attack_finished = time + 0.25;
		else self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		if (self.haste_finished > time) self.attack_finished = time + 0.25;
		else self.attack_finished = time + 0.5;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		if (self.haste_finished > time) self.attack_finished = time + 0.35;
		else self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		if (self.haste_finished > time) self.attack_finished = time + 0.35;
		else self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_LASER_SSG)
	{
		player_shot1 ();
		W_FireLaserSuperShotgun ();
		if (self.haste_finished > time) self.attack_finished = time + 0.35;
		else self.attack_finished = time + 0.7;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_PROX_MINE)
	{
		player_rocket1(); // Rocket animation
		W_FireLTB();    // Our deploy function
		self.attack_finished = time + 1.0; // Wait a little
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1();
		W_FireGrenade();
		if (self.haste_finished > time) self.attack_finished = time + 0.3;
		else self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_CLUSTER_GL)
	{
		player_rocket1();
		W_FireAltGrenade();
		if (self.haste_finished > time) self.attack_finished = time + 0.3;
		else self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_FLARE_GUN)
	{
		player_rocket1();
		W_FireFlare();
		if (self.haste_finished > time) self.attack_finished = time + 0.3;
		else self.attack_finished = time + 0.3;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1();
		W_FireRocket();
		if (self.haste_finished > time) self.attack_finished = time + 0.4;
		else self.attack_finished = time + 0.8;
	}
	else if (self.weapon == IT_HOMING_RL)
	{
		player_rocket1();
		W_HunterFire();
		if (self.haste_finished > time) self.attack_finished = time + 0.4;
		else self.attack_finished = time + 1.2;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1();
		if (self.haste_finished > time) self.attack_finished = time + 0.07;
		else self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
	else if (self.weapon == IT_BFG)
	{
		player_light3();
		if (self.haste_finished > time) self.attack_finished = time + 0.07;
		else self.attack_finished = time + 1.0;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
	else if (self.weapon == IT_LIGHT_CONTROL)
	{
		toggleLights();
		if (self.haste_finished > time) self.attack_finished = time + 0.4;
		else self.attack_finished = time + 2.0;
	}
};



/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local	float	it, am, fl;

	it = self.items;
	am = 0;
	fl = 0;

	if (self.impulse == 1)
	{
		fl = IT_AXE;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		if(self.weapon == IT_SUPER_SHOTGUN)
		{
			fl = IT_LASER_SSG;
			if (self.ammo_shells < 5)
				am = 1;
		}else{
			fl = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
	}
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		if(self.weapon == IT_SUPER_NAILGUN)
		{
			fl = IT_PROX_MINE;
			if (self.ammo_nails < 50)
				am = 1;
		}else{
			fl = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
	}
	else if (self.impulse == 6)
	{
		if(self.weapon == IT_CLUSTER_GL)
		{
			fl = IT_FLARE_GUN;
			if (self.ammo_rockets < 1)
			am = 1;
		}else if(self.weapon == IT_GRENADE_LAUNCHER)
		{
			fl = IT_CLUSTER_GL;
			if (self.ammo_rockets < 3)
			am = 1;
		}else{
			fl = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
	}
	else if (self.impulse == 7)
	{
		if(self.weapon == IT_ROCKET_LAUNCHER)
		{
			fl = IT_HOMING_RL;
			if (self.ammo_rockets < 5)
				am = 1;
		}else{
			fl = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
	}
	else if (self.impulse == 8)
	{
		if(self.weapon == IT_BFG)
		{
			fl = IT_LIGHT_CONTROL;
			if (self.ammo_cells < 50)
			{
				am = 1;
			}
		}else if(self.weapon == IT_LIGHTNING)
		{
			fl = IT_BFG;
			if (self.ammo_cells < 25)
			{
				am = 1;
			}
		}else{
			fl = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
	}

	self.impulse = 0;

	if (!(self.items & fl))
	{	// don't have the weapon or the ammo
		sprint (self, "no weapon.\n");
		return;
	}

	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	self.weapon = fl;
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	if (deathmatch || coop)
		return;

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.items = self.items |
		IT_AXE |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER |
		IT_KEY1 | IT_KEY2;

	self.ammo_cells = 200;
	self.items = self.items | IT_LIGHTNING;

	self.weapon = IT_ROCKET_LAUNCHER;
	self.impulse = 0;
	W_SetCurrentAmmo ();
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it, am;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHT_CONTROL)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_LASER_SSG;
			if (self.ammo_shells < 5)
				am = 1;
		}
		else if (self.weapon == IT_LASER_SSG)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_PROX_MINE;
			if (self.ammo_nails < 50)
				am = 1;
		}
		else if (self.weapon == IT_PROX_MINE)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_CLUSTER_GL;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_CLUSTER_GL)
		{
			self.weapon = IT_FLARE_GUN;
			if (self.ammo_rockets < 3)
				am = 1;
		}
		else if (self.weapon == IT_FLARE_GUN)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_HOMING_RL;
			if (self.ammo_rockets < 5)
				am = 1;
		}
		else if (self.weapon == IT_HOMING_RL)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
		else if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_BFG;
			if (self.ammo_cells < 25)
				am = 1;
		}
		else if (self.weapon == IT_BFG)
		{
			self.weapon = IT_LIGHT_CONTROL;
			if (self.ammo_cells < 50)
				am = 1;
		}


		if ( (self.items & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local   float   it, am;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHT_CONTROL)
		{
			self.weapon = IT_BFG;
			if (self.ammo_cells < 25)
				am = 1;
		}
		else if (self.weapon == IT_BFG)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
		else if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_HOMING_RL;
			if (self.ammo_rockets < 5)
				am = 1;
		}
		else if (self.weapon == IT_HOMING_RL)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_FLARE_GUN;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_FLARE_GUN)
		{
			self.weapon = IT_CLUSTER_GL;
			if (self.ammo_rockets < 3)
				am = 1;
		}
		else if (self.weapon == IT_CLUSTER_GL)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_PROX_MINE;
			if (self.ammo_nails < 50)
				am = 1;
		}
		else if (self.weapon == IT_PROX_MINE)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_LASER_SSG;
			if (self.ammo_shells < 5)
				am = 1;
		}
		else if (self.weapon == IT_LASER_SSG)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_LIGHT_CONTROL;
			if (self.ammo_cells < 50)
				am = 1;
		}

		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch || coop)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
	dprint ("quad cheat\n");
};

/*
============
ImpulseCommands

============
*/


/*
void() restoreLights =
{
	if (self.ammo_cells >= 50)
	{
		self.ammo_cells = self.ammo_cells - 50;
		lightstyle (0, "m");
		bprint (self.netname);
		bprint (" turned the Lights On for 50 Cells (impulse 98 to turn back off)\n");
	}
}
*/

void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();

	if (self.impulse == 9)
		CheatCommand ();
	if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();
	if (self.impulse == 12)
		CycleWeaponReverseCommand ();
	if (self.impulse == 255)
		QuadCheat ();
		
	if (self.impulse == 24)
		FireHook ();
	if (self.impulse == 25)
		BreakHook ();
	
	self.impulse = 0;
};

/*
============
Set Speed
Sets speed of Player for Haste
============
*/
void() Set_Speed =
{
      local string daspeed;
      local float deespeed, basicspd;

	if (self.haste_finished > time) basicspd = 500;
	else basicspd = 340;

      deespeed = basicspd/2;
      daspeed = ftos(deespeed);
      stuffcmd(self, "cl_forwardspeed ");
      stuffcmd(self, daspeed);
      stuffcmd(self, "\n");
      stuffcmd(self, "cl_sidespeed ");
      stuffcmd(self, daspeed);
      stuffcmd(self, "\n");
      stuffcmd(self, "cl_backspeed ");
      stuffcmd(self, daspeed);
      stuffcmd(self, "\n");
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	ImpulseCommands ();

// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};


