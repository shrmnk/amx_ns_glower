/*
Glower
 by KrX a.k.a. Whosat?!
 version 3.3

-Credits-
OneEyed's roll the dice plugin.
semaja2, for his mines for levels' helper support part & for helping with coding.
gr1mre4p3r, for some ideas.
unnamed -sg for his RGB colour chart and for testing on his server and compiling for me.
Morpheus, for helping me with the engine module, but unfortunately will not be implemented.
White Knight, for helping with testing version 3.2, 3.3

-Test Machine-
Win32 HLDS
NS v3.2
AMXx v1.8.1.3722
Metamod-P v1.19p32

-ChangeLog-
v1.0
Red Glow for all players

v1.1
Added random colour glowing
Increased amount of glow

v1.2 
Added stealth
Removed useless code

v1.3 
Added command to make self stealth

v1.4
Added StealthGlow effect. say/2gt.

v1.5
Changed command for making StealthGlow effect to make it shorter.

v1.6
Removed /stealth as it was too cheat.

v1.7
Fixed StealthGlow not stealthing

v1.8
Changed Stealthing method, less code needed this way.
Removed making all players StealthGlow after joining server.

v1.9
Added a command to make the player revert back to normal.

v2.0
Tested stealth
Changed /2gt to /sglow

v2.1
Completely removed stealth as it crashes the server. (No idea why 0.o)
Added Helper support

v2.2
Added cvar to disable/enable glower

v2.3
Fixed Glower not disabling when amx_glow is 0

v2.4
Fixed showing that glower is disabled when it is not
Fixed message not showing that glower is disabled when any command is called.

v2.5
Fixed glow showing StealthGlow. (Mixed up the codes, XD)

v2.6
Fixed not StealthGlowing when in RR.

v2.7
Added defines for glowing/StealthGlowing in rr. See RRglow and RRsglow

v2.8
Added cvar to enable/disable StealthGlow on-the-fly. (Thanks, gr1mre4p3r for idea. =D)

v2.9
Shows message to clients when StealthGlow is disabled.
Players will now glow when StealthGlow is disabled (Message will be displayed).
Shows in helper when RR glow and RR StealthGlow is disabled.
Added define to make players glow when they connect.
Removed showing glower version when any message from glower is displayed. (Shows v50 XD)
Added message to client when command is called and cvar is enabled that he/she(?) is glowing/StealthGlowing.

v3.0
Cleaned up code
Shows a message to clients when they connect that the server is running Glower.
Released on ModNS

v3.1
Now disables fades and jetpackers from StealthGlowing (makes them 'invisible') (adjustable on next release)
Now disables people from glowing/StealthGlowing when they're dead. (displays message)
Some code rewritten by semaja2, thanks loads man.

v3.2
Added persistent glowing/stealthglowing, even after death, until /stopglow
Added Spawn Invulnerability support
Added cvar 'amx_sgflyers' to control whether flying-types are allowed to StealthGlow
Loads of code optimizations
v3.2r2
Fixed bug where an alien gestating to fade will not follow amx_sgflyers rule (thanks That's Enough)
 
v3.3
**! Changed format of cvar, to amx_g_<cvarname>
Changed Ready Room glowing to cvar (amx_g_rrglow, amx_g_rrsglow)
Changed format of client chat output to use square brackets
Added changeteam check
Removed connectglow "feature"
Fixed exploit where clients can still hold their glow when cvar is changed during a game
Fixed bug where a player changing to flying-type will spam a message
Loads of code optimizations
Proper commenting & changelog

-----END CHANGELOG-----

-Planned for coming releases-
Cvar to control whether to allow aliens to use "flashlight"
Fakemeta

*/

// Defines
#define HELPER 1		// Use Helper plugin?

/*** -- DO NOT TOUCH BELOW HERE IF YOU DO NOT KNOW WHAT YOU'RE DOING! -- ***/

#define PLUGIN_AUTHOR "KrX"
#define PLUGIN_VERSION "3.3"

#include <amxmodx>
#include <fun>
#include <ns>
#if HELPER == 1
#include <helper>
#endif

new sglowing[33], glowing[33];		// Array to store if client is glowing/stealthglowing
static Float:cvar_spawninvul, spawninvul;

public plugin_init() {
	register_plugin("Glower", PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar("KrX_glower", PLUGIN_VERSION, FCVAR_SERVER);
	register_clcmd("say /glow", "makeglow");
	register_clcmd("say_team /glow", "makeglow");
	register_clcmd("say /sglow", "sglowsplit");
	register_clcmd("say_team /sglow", "sglowsplit");
	register_clcmd("say /stopglow", "revert");
	register_clcmd("say_team /stopglow", "revert");
	register_cvar("amx_g_glow", "1");
	register_cvar("amx_g_sglow", "1");
	register_cvar("amx_g_sgflyers", "0");
	register_cvar("amx_g_rrglow", "1");
	register_cvar("amx_g_rrsglow", "1");
	spawninvul = cvar_exists("mp_spawninvulnerabletime");
	if(spawninvul)
		cvar_spawninvul = get_cvar_float("mp_spawninvulnerabletime");
	server_print("Glower v%s by KrX loaded!", PLUGIN_VERSION);
}

// Spawn Invulnerability support
// Persistent stealth/glowing
// Check cvar on spawn
public client_spawn(id)
{
	if(!get_cvar_num("amx_g_glow"))
		glowing[id] = 0;
	if(!get_cvar_num("amx_g_sglow"))
		sglowing[id] = 0;
	
	if(glowing[id])
	{
		if(spawninvul)
			set_task(cvar_spawninvul, "makeglow", id);
		else
			makeglow(id);
	}
	if(sglowing[id])
	{
		if(spawninvul)
			set_task(cvar_spawninvul, "sglowsplit", id);
		else
			sglowsplit(id);
	}
}

// To ensure players don't exploit by sglowing before gestating/upgrading
public client_changeclass(id, newclass, oldclass)
{
	if(newclass == CLASS_FADE || newclass == CLASS_JETPACK && !get_cvar_num("amx_g_sgflyers") && sglowing[id])
		revert(id);
}

// Stops glowing client once changeteam
public client_changeteam(id, newteam, oldteam)
{
	if(glowing[id] || sglowing[id])
		revert(id);
}

// Resets clients' glowing status
public client_putinserver(id) {
	glowing[id] = 0;
	sglowing[id] = 0;
	return PLUGIN_CONTINUE;
}

// Splits sglow.
public sglowsplit(id) {
	new class = ns_get_class(id);
	if(class == CLASS_FADE || class == CLASS_JETPACK && !get_cvar_num("amx_g_sgflyers"))   // JP or fade
	{
		client_print(id, print_chat, "[Glower v%s] You cannot StealthGlow when you're a FADE or JETPACK", PLUGIN_VERSION);
		return PLUGIN_HANDLED;
	}
	if ( !get_cvar_num("amx_g_sglow")) 
	{
		makeglow(id);
		client_print(id, print_chat, "[Glower v%s] StealthGlow disabled, now glowing instead.", PLUGIN_VERSION);
	}
	else
	{
		stealthglow(id);
	}
	return PLUGIN_CONTINUE;
}

// Glowing operation
public makeglow(id) {
	if (!get_cvar_num("amx_g_glow"))
	{
		client_print(id, print_chat, "[Glower v%s] Glow disabled by Admin.", PLUGIN_VERSION);
		return PLUGIN_HANDLED;
	}
	
	if (!is_user_alive(id)) 
	{
		client_print(id, print_chat, "[Glower v%s] The dead can't be seen.", PLUGIN_VERSION);
		return PLUGIN_HANDLED;
	}
	new team[32];
	new Red = random(256);
	new Green = random(256);
	new Blue = random(256);
	
	get_user_team(id,team,32);
	if(equal(team, "marine2team") || equal(team, "alien2team") || equal(team, "marine1team") || equal(team, "alien1team"))
	{
		set_user_rendering(id, kRenderFxGlowShell, Red, Green, Blue, kRenderNormal, 16);
	}
	else if(equal(team, "undefinedteam") || strlen(team) == 0 && get_cvar_num("amx_g_rrglow"))
	{
		set_user_rendering(id, kRenderFxGlowShell, Red, Green, Blue, kRenderNormal, 16);
	}
	client_print(id, print_chat, "[Glower v%s] Now glowing", PLUGIN_VERSION);
	glowing[id] = 1;
	return PLUGIN_HANDLED;
}

// StealthGlowing operation
public stealthglow(id) {
	if (!is_user_alive(id)) {
		client_print(id, print_chat, "[Glower v%s] The dead can't be seen.", PLUGIN_VERSION);
		return PLUGIN_HANDLED;
	}
	
	new team[33];
	new Red = random(256);
	new Green = random(256);
	new Blue = random(256);
	get_user_team(id,team,32);
	if(equal(team, "marine2team") || equal(team, "alien2team") || equal(team, "marine1team") || equal(team, "alien1team"))
	{
		set_user_rendering(id, kRenderFxGlowShell, Red, Green, Blue, kRenderTransAlpha, 22);
	}
	else if(equal(team, "undefinedteam") || strlen(team) == 0 && get_cvar_num("amx_g_rrsglow"))
	{
		set_user_rendering(id, kRenderFxGlowShell, Red, Green, Blue, kRenderTransAlpha, 22);
	}
	client_print(id, print_chat, "[Glower v%s] Now StealthGlowing.", PLUGIN_VERSION);
	sglowing[id] = 1;
	return PLUGIN_HANDLED;
}

// Revert player back to normal
public revert(id) {
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 16);
	client_print(id, print_chat, "[Glower v%s] No longer stealth/glowing", PLUGIN_VERSION);
	glowing[id] = 0;
	sglowing[id] = 0;
	return PLUGIN_HANDLED;
}

// Helper Info
#if HELPER == 1					// if helper is running, see define HELPER
/************************************************
client_help( id )
Public Help System
************************************************/

public client_help(id){
	help_add("Information","This plugin allows users to stealth/glow a random colour");
	help_add("Commands","/glow^n/sglow^n/stopglow");
	help_add("About","/glow: Makes player glow^n/sglow: Makes player StealthGlow^n /stopglow: Makes player revert back to normal");
	if(!get_cvar_num( "amx_g_rrglow" ))
		help_add("Glowing","Glowing in RR is not allowed.");
	if(!get_cvar_num( "amx_g_rrsglow" ))
  		help_add("StealthGlowing","StealthGlowing in RR is not allowed.");
	if(!get_cvar_num( "amx_g_sgflyers" ))
		help_add("Notes", "Jetpackers and Fades are not allowed to StealthGlow");
	help_add("Tips","Keep saying the same command to change to another colour. =D");
}

public client_advertise(id)	return PLUGIN_CONTINUE;
#endif