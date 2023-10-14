#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_trace>
#undef REQUIRE_PLUGIN
#tryinclude <updater>

// ====[ CONSTANTS ]===============================================
#define PLUGIN_NAME	   "[TF2] Projectiles Fix"
#define PLUGIN_VERSION "1.1.0"

#define UPDATE_URL	   "https://raw.github.com/Dragonisser/TF2_ProjectilesFix/master/updater.txt"

enum {
	arrow,	  // 24
	// ball_ornament, // 13 // Other than 24 are not yet supported
	// cleaver,       // 20
	energy_ball,	// 24
	energy_ring,	// 24
	flare,			// 24
	// healing_bolt,  // 24  // Pointless and not working anyways
	// jar,           // 20
	// jar_milk,      // 20
	// pipe,          // 20
	// pipe_remote,   // 20
	rocket,			// 24
	sentryrocket	// 24
					// stun_ball,     // 13
					// syringe,       // 13
					// throwable      // 20?
}

static const char tf_projectiles[][] = {
	"arrow",
	//"ball_ornament",
	//"cleaver",
	"energy_ball",
	"energy_ring",
	"flare",
	//"healing_bolt",
	//"jar",
	//"jar_milk",
	//"pipe",
	//"pipe_remote",
	"rocket",
	"sentryrocket"
	//"stun_ball",
	//"syringe",
	//"throwable"
};

static const char boss_events[][] = {
	"pumpkin_lord_summoned",
	"pumpkin_lord_killed",
	"merasmus_summoned",
	"merasmus_killed",
	"merasmus_escaped",
	"eyeball_boss_summoned",
	"eyeball_boss_killed",
	"eyeball_boss_escaped",
	"teamplay_round_start",
	"arena_round_start"
};

// ====[ VARIABLES ]===============================================
Handle ProjectilesTrie;
bool   HookProjectiles;
int	   m_vecOrigin;		  // origin of a projectile
int	   m_vecAbsOrigin;	  // abs origin of a projectile
int	   m_CollisionGroup;

// ====[ PLUGIN ]==================================================
public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Root",
	description = "Simply fixes projectiles not flying through team mates",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/Dragonisser/TF2_ProjectilesFix"
}

/* OnPluginStart()
 *
 * When the plugin starts up.
 * ---------------------------------------------------------------- */
public void OnPluginStart() {
	// Create Version ConVar
	CreateConVar("tf_projectiles_fix_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

	// Register ConVars without using global handles
	Handle Registar;
	char   cvarname[32];

	// Create trie with projectile names
	ProjectilesTrie = CreateTrie();

	// Set a name of the ConVar
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[arrow]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow arrow to fly through team mates?", 0, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[arrow], arrow);

	/* Not yet supported
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[ball_ornament]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow ball ornament to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[ball_ornament], ball_ornament);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[cleaver]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow cleaver to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[cleaver], cleaver);
	*/

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[energy_ball]);

	// Hook changes immediately
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow energy ball to fly through team mates?", 0, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[energy_ball], energy_ball);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[energy_ring]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow energy ring to fly through team mates?", 0, true, 0.0, true, 1.0)), OnConVarChange);

	// Also set appropriate value in trie
	SetTrieValue(ProjectilesTrie, tf_projectiles[energy_ring], energy_ring);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[flare]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow flare to fly through team mates?", 0, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[flare], flare);

	/*
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[healing_bolt]);
	HookConVarChange((Registar = CreateConVar(cvarname, "0", "Allow crossbow bolt to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[healing_bolt], healing_bolt);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[jar]);
	HookConVarChange((Registar = CreateConVar(cvarname, "0", "Allow jarate to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[jar], jar);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[jar_milk]);
	HookConVarChange((Registar = CreateConVar(cvarname, "0", "Allow mad milk to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[jar_milk], jar_milk);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[pipe]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow pipebomb projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[pipe], pipe);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[pipe_remote]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow sticky projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[pipe_remote], pipe_remote);
	*/

	// I call this 'KyleS' style, and that's good because you dont need to always retrieve ConVar handle
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[rocket]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow rocket projectile to fly through team mates?", 0, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[rocket], rocket);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[sentryrocket]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow sentry rocket projectile to fly through team mates?", 0, true, 0.0, true, 1.0)), OnConVarChange);

	// It saves memory much when many CVars are created, and its very important in our case when OnEntityCreated() forward is used
	SetTrieValue(ProjectilesTrie, tf_projectiles[sentryrocket], sentryrocket);

	/*
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[stun_ball]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow stun ball to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[stun_ball], stun_ball);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[syringe]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow syringe to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[syringe], syringe);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[throwable]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow throwable projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[throwable], throwable);
	*/

	// I HATE Handles (c) KyleS
	CloseHandle(Registar);

	// Find a networkable send property offset for projectiles collision
	if ((m_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup")) == -1) {
		SetFailState("Fatal Error: Unable to find offset \"CBaseEntity::m_CollisionGroup\" !");
	}

	// Hook some boss events, because for some reasons projectiles goes through them
	for (int i = 0; i < sizeof(boss_events); i++) {
		HookEvent(boss_events[i], OnBossEvents, EventHookMode_PostNoCopy);
	}

	// Create and execute plugin config at every map change
	AutoExecConfig(true, "tf_projectiles_fix");

#if defined _updater_included
	if (LibraryExists("updater")) Updater_AddPlugin(UPDATE_URL);
#endif
}
/* OnConVarChange()
 *
 * Called when ConVar value has changed.
 * ---------------------------------------------------------------- */
public void OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue) {
	// Declare some dummies
	int	 oldNum;
	char cvarName[32];

	// This callback will not automatically hook changes for every single CVar, so we have to check for what CVar value has changed
	GetConVarName(convar, cvarName, sizeof(cvarName));

	// Skip the first 7 characters in name string to avoid comparing with the "sm_fix_"
	if (GetTrieValue(ProjectilesTrie, cvarName[7], oldNum)) {
		// Loop through all projectiles
		for (int i = 0; i < sizeof(tf_projectiles); i++) {
			// If cvar name is equal to any which is in projectiles trie
			if (StrEqual(cvarName[7], tf_projectiles[i])) {
				// Convert changed value to integer
				switch (StringToInt(newValue)) {
					case false: RemoveFromTrie(ProjectilesTrie, tf_projectiles[oldNum]);	// Remove a key from projectiles trie
					case true: SetTrieValue(ProjectilesTrie, cvarName[7], i, false);		// Register a new key in trie
				}
			}
		}
	}
}

/* OnBossEvents()
 *
 * Called when game bosses are spawning, escaping or dying.
 * ---------------------------------------------------------------- */
public void OnBossEvents(Handle event, const char[] name, bool dontBroadcast) {
	// Bosses dont have collision group nor contentsmask, we have to unhook projectiles
	if (StrContains(name, "summoned", false) != -1) HookProjectiles = false;
	else if (StrContains(name, "killed", false) != -1		 // Enable hook if boss has escaped/killed
			 || StrContains(name, "escaped", false) != -1	 // Or new round is started
			 || StrContains(name, "start", false) != -1) HookProjectiles = true;
}

/* OnEntityCreated()
 *
 * When an entity is created.
 * ---------------------------------------------------------------- */
public void OnEntityCreated(int entity, const char[] classname) {
	int projectile;

	// Skip the first 14 characters in classname string to avoid comparing with the "tf_projectile_" prefix (optimizations)
	if (HookProjectiles && strlen(classname) > 14 && GetTrieValue(ProjectilesTrie, classname[14], projectile)) {
		// If I'd use not Post hook (with new collision group) - plugin would never detect when projectile collides with a players
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

/* OnProjectileSpawned()
 *
 * When a projectile successfully spawned.
 * ---------------------------------------------------------------- */
public void OnProjectileSpawned(int projectile) {
	// Find datamap property offset for m_vecOrigin to define starting position for trace
	if (!m_vecOrigin && (m_vecOrigin = FindDataMapInfo(projectile, "m_vecOrigin")) == -1) {
		LogError("Unable to find datamap offset: \"m_vecOrigin\" !");
		return;
	}

	// Find datamap property offset for m_vecAbsOrigin to define direction angle for trace
	if (!m_vecAbsOrigin && (m_vecAbsOrigin = FindDataMapInfo(projectile, "m_vecAbsOrigin")) == -1) {
		// If not found - just dont do anything and error out
		LogError("Unable to find datamap offset: \"m_vecAbsOrigin\" !");
		return;
	}

	// Set the collision group for created projectile depends on own group
	switch (GetEntData(projectile, m_CollisionGroup)) {
		// case 20: // CG for cleaver, jars, pipe bombs and probably throwable ?
		case 24: {
			SetEntData(projectile, m_CollisionGroup, 3, 4, true);	 // CG for or arrows, flares, rockets and unused crossbow bolt
		}
			// default: // Real projectiles (such as syringes and scout ballz)
	}

	// Hook 'ShouldCollide' for this projectile
	SDKHook(projectile, SDKHook_ShouldCollide, OnProjectileCollide);
}

/* OnProjectileCollide()
 *
 * A ShouldCollide hook for given projectile.
 * ---------------------------------------------------------------- */
public bool OnProjectileCollide(int entity, int collisiongroup, int contentsmask, bool result) {
	// ShouldCollide called 66 times per second, but only once when it hits player
	float vecPos[3];
	float vecAng[3];
	int	  owner;

	// Get vecOrigin and vecAbsOrigin
	GetEntDataVector(entity, m_vecOrigin, vecPos);
	GetEntDataVector(entity, m_vecAbsOrigin, vecAng);

	// Get the rocket owner (it automatically detects deflector as well)
	owner = GetProjectileOwner(entity);

	// Create TraceRay to check whether or not projectiles goes through a valid player
	// TR(StartPos, DirectPos, player's contentsmask, infinite and with filter (which includes owner index))
	TR_TraceRayFilter(vecPos, vecAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, owner);

	// Are we hit something?
	if (TR_DidHit()) {
		// Yep, get its index
		int entidx = TR_GetEntityIndex();

		// Make sure player is valid and teams are different
		if (IsValidClient(entidx) && GetEntityTeam(entidx) != GetEntityTeam(entity)) {
			// Retrieve the changed collision group for hit projectile
			switch (GetEntData(entity, m_CollisionGroup)) {
				// case num: // Cleaver, jars & pipe bombs
				case 3: {
					SetEntData(entity, m_CollisionGroup, 24, 4, true);	  // Use 3 for projectiles to prevent flying through buildings
				}
					// default: // Syringes & scout ballz
			}
		}
	}
	return result;
}

/* TraceFilter()
 *
 * Whether or not we should trace through 'this'.
 * ---------------------------------------------------------------- */
public bool TraceFilter(int entity, int contentsMask, any client) {
	// Both projectile and player should be valid

	if (IsValidEdict(entity) && IsValidClient(client) && entity != client && GetEntityTeam(entity) == GetEntityTeam(client)) {
		return false;
	}

	return true;
}

/* GetProjectileOwner()
 *
 * Retrieves an 'owner' of projectile.
 * ---------------------------------------------------------------- */
int GetProjectileOwner(int entity) {
	static int offsetOwner;

	// Find the owner offset
	if (!offsetOwner && (offsetOwner = FindDataMapInfo(entity, "m_hOwnerEntity")) == -1) {
		LogError("Unable to find datamap offset: \"m_hOwnerEntity\" !");
		return 0;
	}

	// m_hOwnerEntity always returns a player index
	return GetEntDataEnt2(entity, offsetOwner);
}

/* IsValidClient()
 *
 * Default 'valid client' check.
 * ---------------------------------------------------------------- */
bool IsValidClient(int client) {
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) ? true : false;
}

int GetEntityTeam(int entity) {
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}