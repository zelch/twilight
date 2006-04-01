
void() player_updatebounds;

/*
==============================================================================

PLAYER

==============================================================================
*/

$cd id1/models/player_4
$origin 0 -6 24
$base base
$skin skin

//
// running
//
$frame axrun1 axrun2 axrun3 axrun4 axrun5 axrun6

$frame rockrun1 rockrun2 rockrun3 rockrun4 rockrun5 rockrun6

//
// standing
//
$frame stand1 stand2 stand3 stand4 stand5

$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12


//
// pain
//
$frame axpain1 axpain2 axpain3 axpain4 axpain5 axpain6

$frame pain1 pain2 pain3 pain4 pain5 pain6


//
// death
//

$frame axdeth1 axdeth2 axdeth3 axdeth4 axdeth5 axdeth6
$frame axdeth7 axdeth8 axdeth9

$frame deatha1 deatha2 deatha3 deatha4 deatha5 deatha6 deatha7 deatha8
$frame deatha9 deatha10 deatha11

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11 deathc12 deathc13 deathc14 deathc15

$frame deathd1 deathd2 deathd3 deathd4 deathd5 deathd6 deathd7
$frame deathd8 deathd9

$frame deathe1 deathe2 deathe3 deathe4 deathe5 deathe6 deathe7
$frame deathe8 deathe9

//
// attacks
//
$frame nailatt1 nailatt2

$frame light1 light2

$frame rockatt1 rockatt2 rockatt3 rockatt4 rockatt5 rockatt6

$frame shotatt1 shotatt2 shotatt3 shotatt4 shotatt5 shotatt6

$frame axatt1 axatt2 axatt3 axatt4 axatt5 axatt6

$frame axattb1 axattb2 axattb3 axattb4 axattb5 axattb6

$frame axattc1 axattc2 axattc3 axattc4 axattc5 axattc6

$frame axattd1 axattd2 axattd3 axattd4 axattd5 axattd6


/*
==============================================================================
PLAYER
==============================================================================
*/

/*
void(vector bmins, vector bmaxs, vector hmins, vector hmaxs) player_setbounds =
{
	self.bodymins = bmins;
	self.bodymaxs = bmaxs;
	self.headmins = hmins;
	self.headmaxs = hmaxs;
};
*/

// updates the bounding box objects that make up the player
// presently just the head mainly
void() player_updatebounds =
{
	return;
	/*
	if (self.frame >= $axrun1 && self.frame < $rockrun1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axrun1 ) player_setbounds('-16 -16 -24', '16 16 19', '0 -3 19', '9 5 27');
		else if (self.frame == $axrun2 ) player_setbounds('-16 -16 -24', '16 16 19', '-3 -4 19', '7 5 29');
		else if (self.frame == $axrun3 ) player_setbounds('-16 -16 -24', '16 16 20', '-5 -5 20', '5 3 29');
		else if (self.frame == $axrun4 ) player_setbounds('-16 -16 -24', '16 16 19', '-2 -6 19', '7 2 28');
		else if (self.frame == $axrun5 ) player_setbounds('-16 -16 -24', '16 16 21', '-6 -6 21', '4 2 30');
		else if (self.frame == $axrun6 ) player_setbounds('-16 -16 -24', '16 16 20', '-5 -4 20', '4 4 30');
	}
	else if (self.frame >= $rockrun1 && self.frame < $stand1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $rockrun1 ) player_setbounds('-16 -16 -24', '16 16 23', '-7 -4 23', '3 4 32');
		else if (self.frame == $rockrun2 ) player_setbounds('-16 -16 -24', '16 16 21', '-4 -5 21', '5 3 30');
		else if (self.frame == $rockrun3 ) player_setbounds('-16 -16 -24', '16 16 21', '-7 -6 21', '2 2 30');
		else if (self.frame == $rockrun4 ) player_setbounds('-16 -16 -24', '16 16 23', '-6 -6 23', '4 2 32');
		else if (self.frame == $rockrun5 ) player_setbounds('-16 -16 -24', '16 16 21', '-5 -5 21', '4 3 30');
		else if (self.frame == $rockrun6 ) player_setbounds('-16 -16 -24', '16 16 21', '-5 -5 21', '4 4 30');
	}
	else if (self.frame >= $stand1 && self.frame < $axstnd1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $stand1 ) player_setbounds('-16 -16 -24', '16 16 19', '-9 -5 19', '1 3 28');
		else if (self.frame == $stand2 ) player_setbounds('-16 -16 -24', '16 16 19', '-9 -5 19', '1 3 27');
		else if (self.frame == $stand3 ) player_setbounds('-16 -16 -24', '16 16 18', '-9 -5 18', '1 3 27');
		else if (self.frame == $stand4 ) player_setbounds('-16 -16 -24', '16 16 19', '-9 -5 19', '1 3 27');
		else if (self.frame == $stand5 ) player_setbounds('-16 -16 -24', '16 16 19', '-9 -5 19', '1 3 28');
	}
	else if (self.frame >= $axstnd1 && self.frame < $axpain1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axstnd1 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd2 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd3 ) player_setbounds('-16 -16 -24', '16 16 18', '-6 -5 18', '4 4 28');
		else if (self.frame == $axstnd4 ) player_setbounds('-16 -16 -24', '16 16 18', '-5 -5 18', '4 4 28');
		else if (self.frame == $axstnd5 ) player_setbounds('-16 -16 -24', '16 16 18', '-6 -5 18', '4 4 28');
		else if (self.frame == $axstnd6 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd7 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd8 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd9 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd10 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd11 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
		else if (self.frame == $axstnd12 ) player_setbounds('-16 -16 -24', '16 16 19', '-6 -5 19', '3 4 28');
	}
	else if (self.frame >= $axpain1 && self.frame < $pain1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axpain1 ) player_setbounds('-16 -16 -24', '16 16 21', '-10 -5 21', '0 4 30');
		else if (self.frame == $axpain2 ) player_setbounds('-16 -16 -24', '16 16 19', '-16 -4 19', '-6 4 28');
		else if (self.frame == $axpain3 ) player_setbounds('-16 -16 -24', '16 16 16', '-22 -4 16', '-10 5 26');
		else if (self.frame == $axpain4 ) player_setbounds('-16 -16 -24', '16 16 16', '-21 -4 16', '-9 4 26');
		else if (self.frame == $axpain5 ) player_setbounds('-16 -16 -24', '16 16 18', '-19 -4 18', '-7 4 28');
		else if (self.frame == $axpain6 ) player_setbounds('-16 -16 -24', '16 16 21', '-16 -4 21', '-4 4 19');
	}
	else if (self.frame >= $pain1 && self.frame < $axdeth1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $pain1 ) player_setbounds('-16 -16 -24', '16 16 23', '-7 -5 23', '2 4 32');
		else if (self.frame == $pain2 ) player_setbounds('-16 -16 -24', '16 16 19', '-26 -7 19', '-15 2 29');
		else if (self.frame == $pain3 ) player_setbounds('-16 -16 -24', '16 16 19', '-27 -7 19', '-15 2 30');
		else if (self.frame == $pain4 ) player_setbounds('-16 -16 -24', '16 16 21', '-24 -6 21', '-12 3 31');
		else if (self.frame == $pain5 ) player_setbounds('-16 -16 -24', '16 16 23', '-16 -5 23', '-5 4 31');
		else if (self.frame == $pain6 ) player_setbounds('-16 -16 -24', '16 16 23', '-7 -5 23', '2 4 32');
	}
	else if (self.frame >= $axdeth1 && self.frame < $deatha1 )
	{
		if (self.frame >= $axdeth6 )
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_BBOX;
			 if (self.frame == $axdeth1 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $axdeth2 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $axdeth3 ) setsize(self, '-16 -16 -24', '16 16 21');
		else if (self.frame == $axdeth4 ) setsize(self, '-16 -16 -24', '16 16 15');
		else if (self.frame == $axdeth5 ) setsize(self, '-16 -16 -24', '16 16 3');
		else if (self.frame == $axdeth6 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $axdeth7 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $axdeth8 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $axdeth9 ) setsize(self, '-16 -16 -24', '16 16 0');
	}
	else if (self.frame >= $deatha1 && self.frame < $deathb1 )
	{
		if (self.frame >= $deatha8 )
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_BBOX;
			 if (self.frame == $deatha1 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deatha2 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deatha3 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deatha4 ) setsize(self, '-16 -16 -24', '16 16 26');
		else if (self.frame == $deatha5 ) setsize(self, '-16 -16 -24', '16 16 26');
		else if (self.frame == $deatha6 ) setsize(self, '-16 -16 -24', '16 16 21');
		else if (self.frame == $deatha7 ) setsize(self, '-16 -16 -24', '16 16 12');
		else if (self.frame == $deatha8 ) setsize(self, '-16 -16 -24', '16 16 1');
		else if (self.frame == $deatha9 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deatha10 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deatha11 ) setsize(self, '-16 -16 -24', '16 16 0');
	}
	else if (self.frame >= $deathb1 && self.frame < $deathc1 )
	{
		if (self.frame >= $deathb8 )
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_BBOX;
			 if (self.frame == $deathb1 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deathb2 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deathb3 ) setsize(self, '-16 -16 -24', '16 16 27');
		else if (self.frame == $deathb4 ) setsize(self, '-16 -16 -24', '16 16 21');
		else if (self.frame == $deathb5 ) setsize(self, '-16 -16 -24', '16 16 12');
		else if (self.frame == $deathb6 ) setsize(self, '-16 -16 -24', '16 16 7');
		else if (self.frame == $deathb7 ) setsize(self, '-16 -16 -24', '16 16 5');
		else if (self.frame == $deathb8 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathb9 ) setsize(self, '-16 -16 -24', '16 16 0');
	}
	else if (self.frame >= $deathc1 && self.frame < $deathd1 )
	{
		if (self.frame >= $deathc6 )
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_BBOX;
			 if (self.frame == $deathc1 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deathc2 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deathc3 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deathc4 ) setsize(self, '-16 -16 -24', '16 16 23');
		else if (self.frame == $deathc5 ) setsize(self, '-16 -16 -24', '16 16 12');
		else if (self.frame == $deathc6 ) setsize(self, '-16 -16 -24', '16 16 2');
		else if (self.frame == $deathc7 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc8 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc9 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc10 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc11 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc12 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc13 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc14 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathc15 ) setsize(self, '-16 -16 -24', '16 16 0');
	}
	else if (self.frame >= $deathd1 && self.frame < $deathe1 )
	{
		if (self.frame >= $deathd6 )
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_BBOX;
			 if (self.frame == $deathd1 ) setsize(self, '-16 -16 -24', '16 16 25');
		else if (self.frame == $deathd2 ) setsize(self, '-16 -16 -24', '16 16 24');
		else if (self.frame == $deathd3 ) setsize(self, '-16 -16 -24', '16 16 22');
		else if (self.frame == $deathd4 ) setsize(self, '-16 -16 -24', '16 16 18');
		else if (self.frame == $deathd5 ) setsize(self, '-16 -16 -24', '16 16 13');
		else if (self.frame == $deathd6 ) setsize(self, '-16 -16 -24', '16 16 3');
		else if (self.frame == $deathd7 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathd8 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathd9 ) setsize(self, '-16 -16 -24', '16 16 0');
	}
	else if (self.frame >= $deathe1 && self.frame < $nailatt1 )
	{
		if (self.frame >= $deathe5 )
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_BBOX;
			 if (self.frame == $deathe1 ) setsize(self, '-16 -16 -24', '16 16 28');
		else if (self.frame == $deathe2 ) setsize(self, '-16 -16 -24', '16 16 22');
		else if (self.frame == $deathe3 ) setsize(self, '-16 -16 -24', '16 16 13');
		else if (self.frame == $deathe4 ) setsize(self, '-16 -16 -24', '16 16 7');
		else if (self.frame == $deathe5 ) setsize(self, '-16 -16 -24', '16 16 3');
		else if (self.frame == $deathe6 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathe7 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathe8 ) setsize(self, '-16 -16 -24', '16 16 0');
		else if (self.frame == $deathe9 ) setsize(self, '-16 -16 -24', '16 16 0');
	}
	else if (self.frame >= $nailatt1 && self.frame < $light1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $nailatt1 ) player_setbounds('-16 -16 -24', '16 16 19', '-12 -7 19', '-3 4 24');
		else if (self.frame == $nailatt2 ) player_setbounds('-16 -16 -24', '16 16 19', '-14 -7 19', '-4 4 24');
	}
	else if (self.frame >= $light1 && self.frame < $rockatt1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $light1 ) player_setbounds('-16 -16 -24', '16 16 19', '-12 -7 19', '-3 4 24');
		else if (self.frame == $light2 ) player_setbounds('-16 -16 -24', '16 16 19', '-14 -7 19', '-4 4 24');
	}
	else if (self.frame >= $rockatt1 && self.frame < $shotatt1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $rockatt1 ) player_setbounds('-16 -16 -24', '16 16 15', '-7 -9 15', '2 0 24');
		else if (self.frame == $rockatt2 ) player_setbounds('-16 -16 -24', '16 16 15', '-21 -10 15', '12 0 24');
		else if (self.frame == $rockatt3 ) player_setbounds('-16 -16 -24', '16 16 18', '-17 -10 18', '-8 0 24');
		else if (self.frame == $rockatt4 ) player_setbounds('-16 -16 -24', '16 16 18', '-14 -10 18', '-4 0 24');
		else if (self.frame == $rockatt5 ) player_setbounds('-16 -16 -24', '16 16 17', '-10 -9 17', '-1 0 24');
		else if (self.frame == $rockatt6 ) player_setbounds('-16 -16 -24', '16 16 15', '-7 -9 15', '2 0 24');
	}
	else if (self.frame >= $shotatt1 && self.frame < $axatt1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $shotatt1 ) player_setbounds('-16 -16 -24', '16 16 19', '-12 -7 19', '-3 4 24');
		else if (self.frame == $shotatt2 ) player_setbounds('-16 -16 -24', '16 16 19', '-13 -6 19', '-3 5 24');
		else if (self.frame == $shotatt3 ) player_setbounds('-16 -16 -24', '16 16 18', '-18 -3 18', '-9 8 24');
		else if (self.frame == $shotatt4 ) player_setbounds('-16 -16 -24', '16 16 18', '-19 -3 18', '-9 7 24');
		else if (self.frame == $shotatt5 ) player_setbounds('-16 -16 -24', '16 16 19', '-17 -4 19', '-8 7 24');
		else if (self.frame == $shotatt6 ) player_setbounds('-16 -16 -24', '16 16 19', '-16 -5 19', '-6 6 24');
	}
	else if (self.frame >= $axatt1 && self.frame < $axattb1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axatt1 ) player_setbounds('-16 -16 -24', '16 16 20', '-10 -9 20', '1 -1 24');
		else if (self.frame == $axatt2 ) player_setbounds('-16 -16 -24', '16 16 20', '-4 -6 20', '6 3 24');
		else if (self.frame == $axatt3 ) player_setbounds('-16 -16 -24', '16 16 17', '3 -1 17', '13 7 24');
		else if (self.frame == $axatt4 ) player_setbounds('-16 -16 -24', '16 16 12', '3 -1 12', '12 7 23');
		else if (self.frame == $axatt5 ) player_setbounds('-16 -16 -24', '16 16 16', '-1 -7 16', '9 2 24');
		else if (self.frame == $axatt6 ) player_setbounds('-16 -16 -24', '16 16 20', '-5 -5 20', '4 3 24');
	}
	else if (self.frame >= $axattb1 && self.frame < $axattc1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axattb1 ) player_setbounds('-16 -16 -24', '16 16 18', '-10 2 18', '0 11 24');
		else if (self.frame == $axattb2 ) player_setbounds('-16 -16 -24', '16 16 19', '-7 1 19', '4 10 24');
		else if (self.frame == $axattb3 ) player_setbounds('-16 -16 -24', '16 16 18', '-1 -13 18', '9 -3 24');
		else if (self.frame == $axattb4 ) player_setbounds('-16 -16 -24', '16 16 15', '0 -8 15', '11 0 24');
		else if (self.frame == $axattb5 ) player_setbounds('-16 -16 -24', '16 16 16', '-1 -7 16', '9 2 24');
		else if (self.frame == $axattb6 ) player_setbounds('-16 -16 -24', '16 16 20', '-5 -5 20', '4 3 24');
	}
	else if (self.frame >= $axattc1 && self.frame < $axattd1 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axattc1 ) player_setbounds('-16 -16 -24', '16 16 19', '-9 -7 19', '2 2 24');
		else if (self.frame == $axattc2 ) player_setbounds('-16 -16 -24', '16 16 20', '-1 -6 20', '8 3 24');
		else if (self.frame == $axattc3 ) player_setbounds('-16 -16 -24', '16 16 18', '3 -4 18', '13 5 24');
		else if (self.frame == $axattc4 ) player_setbounds('-16 -16 -24', '16 16 10', '5 -4 10', '16 5 21');
		else if (self.frame == $axattc5 ) player_setbounds('-16 -16 -24', '16 16 16', '-1 -7 16', '9 2 24');
		else if (self.frame == $axattc6 ) player_setbounds('-16 -16 -24', '16 16 20', '-5 -5 20', '4 3 24');
	}
	else if (self.frame >= $axattd1 && self.frame <= $axattd6 )
	{
		setsize(self, '-16 -16 -24', '16 16 24');
			 if (self.frame == $axattd1 ) player_setbounds('-16 -16 -24', '16 16 16', '-10 -11 16', '1 -3 24');
		else if (self.frame == $axattd2 ) player_setbounds('-16 -16 -24', '16 16 18', '-4 -4 18', '6 5 24');
		else if (self.frame == $axattd3 ) player_setbounds('-16 -16 -24', '16 16 17', '0 2 17', '10 11 24');
		else if (self.frame == $axattd4 ) player_setbounds('-16 -16 -24', '16 16 15', '-14 3 15', '-2 11 24');
		else if (self.frame == $axattd5 ) player_setbounds('-16 -16 -24', '16 16 17', '-2 -3 17', '8 6 24');
		else if (self.frame == $axattd6 ) player_setbounds('-16 -16 -24', '16 16 20', '-5 -5 20', '4 3 24');
	}
	else
	{
		dprint("invalid player frame: ");
		dprint(ftos(self.frame));
		dprint("\n");
		setsize(self, '-16 -16 -24', '16 16 24');
		player_setbounds('-16 -16 -24', '16 16 24', '-0 -0 -0', '0 0 0');
	}
	*/
};

.float  playermovestate, playermovebegin;

void() player_move =
{
	local float m, n, t;
	if (self.health < 1) return;
	self.think = player_move;
	self.nextthink = time + 0.1;
	//if (time < self.pain_finished) return; // don't interrupt pain anim
	m = (self.velocity_x || self.velocity_y)/* + (self.weapon == IT_WEAPON1) * 2*/;
	if (m != self.playermovestate)
	{
		self.playermovebegin = time;
		self.playermovestate = m;
	}

	     if (m == 0) {n =  5;self.frame = $stand1;  } // gun stand
	else if (m == 1) {n =  6;self.frame = $rockrun1;} // gun run
//	else if (m == 2) {n = 12;self.frame = $axstnd1; } // axe stand
//	else             {n =  6;self.frame = $axrun1;  } // axe run

	t = (time - self.playermovebegin) * 10;
	t = t - (floor(t / n) * n);
	self.frame = floor(self.frame + t);
	dovisibleweapon();
};

void() player_movestart =
{
	self.playermovestate = -1;
	player_move();
};

void(float weapframe) havoc_shotanimupdate  = {if (self.health < 1) return;if (weapframe >= 1) {self.frame = $shotatt1 +   weapframe - 1      ;dovisibleweapon();}/* else player_move();*/};
void(float weapframe) havoc_nailanimupdate  = {if (self.health < 1) return;if (weapframe >= 1) {self.frame = $nailatt1 + ((weapframe - 1) & 1);dovisibleweapon();}/* else player_move();*/};
void(float weapframe) havoc_rockanimupdate  = {if (self.health < 1) return;if (weapframe >= 1) {self.frame = $rockatt1 +   weapframe - 1      ;dovisibleweapon();}/* else player_move();*/};
void(float weapframe) havoc_lightanimupdate = {if (self.health < 1) return;if (weapframe >= 1) {self.frame = $light1   + ((weapframe - 1) & 1);dovisibleweapon();}/* else player_move();*/};

/*
void()  player_axe1 =   [$axatt1, player_axe2   ] {if (self.health < 1) return;self.weaponframe=1;};
void()	player_axe2 =	[$axatt2, player_axe3	] {self.weaponframe=2;};
void()	player_axe3 =	[$axatt3, player_axe4	] {self.weaponframe=3;W_FireAxe();};
void()  player_axe4 =   [$axatt4, player_movestart] {self.weaponframe=4;};

void()  player_axeb1 =  [$axattb1, player_axeb2 ] {if (self.health < 1) return;self.weaponframe=5;};
void()	player_axeb2 =	[$axattb2, player_axeb3	] {self.weaponframe=6;};
void()	player_axeb3 =	[$axattb3, player_axeb4	] {self.weaponframe=7;W_FireAxe();};
void()  player_axeb4 =  [$axattb4, player_movestart] {self.weaponframe=8;};

void()  player_axec1 =  [$axattc1, player_axec2 ] {if (self.health < 1) return;self.weaponframe=1;};
void()	player_axec2 =	[$axattc2, player_axec3	] {self.weaponframe=2;};
void()	player_axec3 =	[$axattc3, player_axec4	] {self.weaponframe=3;W_FireAxe();};
void()  player_axec4 =  [$axattc4, player_movestart] {self.weaponframe=4;};

void()  player_axed1 =  [$axattd1, player_axed2 ] {if (self.health < 1) return;self.weaponframe=5;};
void()	player_axed2 =	[$axattd2, player_axed3	] {self.weaponframe=6;};
void()	player_axed3 =	[$axattd3, player_axed4	] {self.weaponframe=7;W_FireAxe();};
void()  player_axed4 =  [$axattd4, player_movestart] {self.weaponframe=8;};
*/

//============================================================================

void() PainSound =
{
	local float rs;
	local string s;

	if (self.health < 1)
		return;

	// water pain sounds
	if (self.watertype == CONTENT_WATER && self.waterlevel == 3)
	{
		self.bubble_count = self.bubble_count + 1;
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM);
		return;
	}

	// slime pain sounds
	if (self.watertype == CONTENT_SLIME)
	{
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.pain_finished > time)
	{
//		self.axhitme = 0;
		return;
	}
	self.pain_finished = time + 0.3;

	// don't make multiple pain sounds right after each other

	// ax pain sound
	/*
	if (self.axhitme)
	{
		self.axhitme = FALSE;
		sound (self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM);
		return;
	}
	*/


	rs = random() * 6;

	if (rs < 1)
		sound (self, CHAN_VOICE, "player/pain1.wav", 1, ATTN_NORM);
	else if (rs < 2)
		sound (self, CHAN_VOICE, "player/pain2.wav", 1, ATTN_NORM);
	else if (rs < 3)
		sound (self, CHAN_VOICE, "player/pain3.wav", 1, ATTN_NORM);
	else if (rs < 4)
		sound (self, CHAN_VOICE, "player/pain4.wav", 1, ATTN_NORM);
	else if (rs < 5)
		sound (self, CHAN_VOICE, "player/pain5.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "player/pain6.wav", 1, ATTN_NORM);

	return;
};

/*
void()  player_pain1   = [$pain1  , player_pain2    ] {PainSound();};
void()	player_pain2   = [$pain2  , player_pain3    ] {};
void()	player_pain3   = [$pain3  , player_pain4    ] {};
void()	player_pain4   = [$pain4  , player_pain5    ] {};
void()	player_pain5   = [$pain5  , player_pain6    ] {};
void()  player_pain6   = [$pain6  , player_movestart] {};

void()  player_axpain1 = [$axpain1, player_axpain2  ] {PainSound();};
void()  player_axpain2 = [$axpain2, player_axpain3  ] {};
void()  player_axpain3 = [$axpain3, player_axpain4  ] {};
void()  player_axpain4 = [$axpain4, player_axpain5  ] {};
void()  player_axpain5 = [$axpain5, player_axpain6  ] {};
void()  player_axpain6 = [$axpain6, player_movestart] {};
*/

void(entity attacker, float take) player_pain =
{
	if (self.health < 1)
		return; // dead

	if (take < 5) // ignore
		return;

	//if (self.weaponframe)
	//	return;

	if (self.invisible_finished > time)
		return;		// eyes don't have pain frames

	PainSound();

	/*
	if (self.weapon == IT_WEAPON1)
		player_axpain1 ();
	else
		player_pain1 ();
	//player_pain1 ();
	dovisibleweapon();
	*/
};

void() player_diea1;
void() player_dieb1;
void() player_diec1;
void() player_died1;
void() player_diee1;
void() player_die_ax1;

void() DeathSound =
{
	local float rs, p;

	// water death sounds
	p = pointcontents(self.origin + '0 0 22');
	if (p == CONTENT_SLIME || p == CONTENT_WATER)
	{
		self.bubble_count = self.bubble_count + 20;
		sound (self, CHAN_VOICE, "player/h2odeath.wav", 1, ATTN_NONE);
		return;
	}

	rs = random() * 5;
	if (rs < 1)
		sound (self, CHAN_VOICE, "player/death1.wav", 1, ATTN_NONE);
	else if (rs < 2)
		sound (self, CHAN_VOICE, "player/death2.wav", 1, ATTN_NONE);
	else if (rs < 3)
		sound (self, CHAN_VOICE, "player/death3.wav", 1, ATTN_NONE);
	else if (rs < 4)
		sound (self, CHAN_VOICE, "player/death4.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/death5.wav", 1, ATTN_NONE);
	return;
};


void() PlayerDead =
{
	self.nextthink = -1;
// allow respawn after a certain time
	self.deadflag = DEAD_DEAD;
};

void() GibPlayer =
{
	PlayerGibs("progs/h_player.mdl", 6, "", 0, "", 0);

	self.deadflag = DEAD_DEAD;

	if (self.deathtype == "TELEFRAG" || self.deathtype == "TRIEDTOTELEFRAG")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);
};

void() PlayerDie =
{
	local	float	i;

	if (self.deadflag)
	{
		bprint("warning: PlayerDie called twice\n");
		return;
	}

	if (deathmatch || coop)
		DropBackpack();

	self.items = self.items - (self.items & IT_INVISIBILITY);
	self.invisible_finished = 0;	// don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;

	self.weaponmodel="";
	self.view_ofs = '0 0 -8';
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_CORPSE;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	if (self.velocity_z < 10)
		self.velocity_z = self.velocity_z + random()*300;

	DeathSound();

	self.angles_x = 0;
	self.angles_z = 0;
	self.avelocity = '0 0 0';
	setmodel(self, "progs/player.mdl");

	/*
	if (self.weapon == IT_WEAPON1)
		BecomeCorpse(self, player_die_ax1);
	else
	{
	*/
		i = random() * 5;

			 if (i < 1) BecomeCorpse(self, player_diea1);
		else if (i < 2) BecomeCorpse(self, player_dieb1);
		else if (i < 3) BecomeCorpse(self, player_diec1);
		else if (i < 4) BecomeCorpse(self, player_died1);
		else            BecomeCorpse(self, player_diee1);
	//}

	//self.solid = SOLID_NOT;
	//self.currentammo = 0;
	//Inventory_SetQuantity(self, "shells", 0);
	//Inventory_SetQuantity(self, "nails", 0);
	//Inventory_SetQuantity(self, "rockets", 0);
	//Inventory_SetQuantity(self, "cells", 0);
	//self.items = 0;
	//self.effects = 0;
	//self.armorvalue = 0;
	//self.armortype = 0;
	//self.movetype = MOVETYPE_NONE;
	//self.velocity = '0 0 0';
	//self.model = "";
	//self.modelindex = 0;
};

void() player_suicideframe = [$deatha11, player_suicideframe] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

void() set_suicide_frame =
{
	// used by kill and disconnect commands
	if (self.deadflag >= DEAD_DEAD)
		return; // already dead
	self.items = self.items - (self.items & IT_INVISIBILITY);
	self.invisible_finished = 0;	// don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	setmodel(self, "progs/player.mdl");
	self.frame = $deatha11;
	self.deadflag = DEAD_DEAD;
	self.nextthink = -1;
	BecomeCorpse(self, player_suicideframe);
};

void()  player_diea1    =       [       $deatha1,       player_diea2    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diea2    =       [       $deatha2,       player_diea3    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diea3    =       [       $deatha3,       player_diea4    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diea4    =       [       $deatha4,       player_diea5    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diea5    =       [       $deatha5,       player_diea6    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diea6    =       [       $deatha6,       player_diea7    ] {body_solid('-16 -16 -24', '16 16 21');};
void()  player_diea7    =       [       $deatha7,       player_diea8    ] {body_solid('-16 -16 -24', '16 16 12');};
void()  player_diea8    =       [       $deatha8,       player_diea9    ] {body_nonsolid('-16 -16 -24', '16 16 1');};
void()  player_diea9    =       [       $deatha9,       player_diea10   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diea10   =       [       $deatha10,      player_diea11   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diea11   =       [       $deatha11,      player_diea11   ] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

void()  player_dieb1    =       [       $deathb1,       player_dieb2    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_dieb2    =       [       $deathb2,       player_dieb3    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_dieb3    =       [       $deathb3,       player_dieb4    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_dieb4    =       [       $deathb4,       player_dieb5    ] {body_solid('-16 -16 -24', '16 16 21');};
void()  player_dieb5    =       [       $deathb5,       player_dieb6    ] {body_solid('-16 -16 -24', '16 16 12');};
void()  player_dieb6    =       [       $deathb6,       player_dieb7    ] {body_solid('-16 -16 -24', '16 16 7');};
void()  player_dieb7    =       [       $deathb7,       player_dieb8    ] {body_solid('-16 -16 -24', '16 16 5');};
void()  player_dieb8    =       [       $deathb8,       player_dieb9    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_dieb9    =       [       $deathb9,       player_dieb9    ] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

void()  player_diec1    =       [       $deathc1,       player_diec2    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diec2    =       [       $deathc2,       player_diec3    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diec3    =       [       $deathc3,       player_diec4    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diec4    =       [       $deathc4,       player_diec5    ] {body_solid('-16 -16 -24', '16 16 23');};
void()  player_diec5    =       [       $deathc5,       player_diec6    ] {body_solid('-16 -16 -24', '16 16 12');};
void()  player_diec6    =       [       $deathc6,       player_diec7    ] {body_nonsolid('-16 -16 -24', '16 16 2');};
void()  player_diec7    =       [       $deathc7,       player_diec8    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec8    =       [       $deathc8,       player_diec9    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec9    =       [       $deathc9,       player_diec10   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec10   =       [       $deathc10,      player_diec11   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec11   =       [       $deathc11,      player_diec12   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec12   =       [       $deathc12,      player_diec13   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec13   =       [       $deathc13,      player_diec14   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec14   =       [       $deathc14,      player_diec15   ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diec15   =       [       $deathc15,      player_diec15   ] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

void()  player_died1    =       [       $deathd1,       player_died2    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_died2    =       [       $deathd2,       player_died3    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_died3    =       [       $deathd3,       player_died4    ] {body_solid('-16 -16 -24', '16 16 22');};
void()  player_died4    =       [       $deathd4,       player_died5    ] {body_solid('-16 -16 -24', '16 16 18');};
void()  player_died5    =       [       $deathd5,       player_died6    ] {body_solid('-16 -16 -24', '16 16 13');};
void()  player_died6    =       [       $deathd6,       player_died7    ] {body_nonsolid('-16 -16 -24', '16 16 3');};
void()  player_died7    =       [       $deathd7,       player_died8    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_died8    =       [       $deathd8,       player_died9    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_died9    =       [       $deathd9,       player_died9    ] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

void()  player_diee1    =       [       $deathe1,       player_diee2    ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_diee2    =       [       $deathe2,       player_diee3    ] {body_solid('-16 -16 -24', '16 16 22');};
void()  player_diee3    =       [       $deathe3,       player_diee4    ] {body_solid('-16 -16 -24', '16 16 13');};
void()  player_diee4    =       [       $deathe4,       player_diee5    ] {body_solid('-16 -16 -24', '16 16 7');};
void()  player_diee5    =       [       $deathe5,       player_diee6    ] {body_nonsolid('-16 -16 -24', '16 16 3');};
void()  player_diee6    =       [       $deathe6,       player_diee7    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diee7    =       [       $deathe7,       player_diee8    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diee8    =       [       $deathe8,       player_diee9    ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_diee9    =       [       $deathe9,       player_diee9    ] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

void()  player_die_ax1  =       [       $axdeth1,       player_die_ax2  ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_die_ax2  =       [       $axdeth2,       player_die_ax3  ] {body_solid('-16 -16 -24', '16 16 24');};
void()  player_die_ax3  =       [       $axdeth3,       player_die_ax4  ] {body_solid('-16 -16 -24', '16 16 21');};
void()  player_die_ax4  =       [       $axdeth4,       player_die_ax5  ] {body_solid('-16 -16 -24', '16 16 15');};
void()  player_die_ax5  =       [       $axdeth5,       player_die_ax6  ] {body_solid('-16 -16 -24', '16 16 3');};
void()  player_die_ax6  =       [       $axdeth6,       player_die_ax7  ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_die_ax7  =       [       $axdeth7,       player_die_ax8  ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_die_ax8  =       [       $axdeth8,       player_die_ax9  ] {body_nonsolid('-16 -16 -24', '16 16 0');};
void()  player_die_ax9  =       [       $axdeth9,       player_die_ax9  ] {body_nonsolid('-16 -16 -24', '16 16 0');PlayerDead();};

/*QUAKED dead_player (1 0 0) (-16 -16 -24) (16 16 0)
*/
void() dead_player =
{
	local float r;
	r = random() * 5;
	     if (r < 1) deadmonstersetup("progs/player.mdl", "progs/h_player.mdl", player_diea11, 6, 5, HEALTHBODY);
	else if (r < 2) deadmonstersetup("progs/player.mdl", "progs/h_player.mdl", player_dieb9 , 6, 5, HEALTHBODY);
	else if (r < 3) deadmonstersetup("progs/player.mdl", "progs/h_player.mdl", player_diec15, 6, 5, HEALTHBODY);
	else if (r < 4) deadmonstersetup("progs/player.mdl", "progs/h_player.mdl", player_died9 , 6, 5, HEALTHBODY);
	else            deadmonstersetup("progs/player.mdl", "progs/h_player.mdl", player_diee9 , 6, 5, HEALTHBODY);
};

/*QUAKED dead_player_axe (1 0 0) (-16 -16 -24) (16 16 0)
*/
void() dead_player_axe =
{
	deadmonstersetup("progs/player.mdl", "progs/h_player.mdl", player_die_ax9, 6, 5, HEALTHBODY);
};

