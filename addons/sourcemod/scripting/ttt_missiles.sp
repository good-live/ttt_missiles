#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.00"

#define SHORT_NAME_T "mi_t"
#define SHORT_NAME_D "mi_d"
#define SHORT_NAME_I "mi_i"
#define SHORT_NAMEF_T "mif_t"
#define SHORT_NAMEF_D "mif_d"
#define SHORT_NAMEF_I "mif_i"

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ttt>
#include <ttt_shop>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "TTT - Missiles",
	author = PLUGIN_AUTHOR,
	description = "Allows you to buy a Missile",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

ConVar g_cDamage;
ConVar g_cRadius;
ConVar g_cSpeed;
ConVar g_cArc;
ConVar g_cModel;

ConVar g_cPriceT_F = null;
ConVar g_cPriceD_F = null;
ConVar g_cPriceI_F = null;
ConVar g_cPriorityT_F = null;
ConVar g_cPriorityD_F = null;
ConVar g_cPriorityI_F = null;
ConVar g_cAmountT_F = null;
ConVar g_cAmountD_F = null;
ConVar g_cAmountI_F = null;
ConVar g_cName_F = null;

int g_iPAmount_F[MAXPLAYERS + 1] =  { 0, ... };

int g_iMissile_F[MAXPLAYERS + 1] =  { 0, ... };

ConVar g_cPriceT = null;
ConVar g_cPriceD = null;
ConVar g_cPriceI = null;
ConVar g_cPriorityT = null;
ConVar g_cPriorityD = null;
ConVar g_cPriorityI = null;
ConVar g_cAmountT = null;
ConVar g_cAmountD = null;
ConVar g_cAmountI = null;
ConVar g_cName = null;

int g_iPAmount[MAXPLAYERS + 1] =  { 0, ... };

int g_iMissile[MAXPLAYERS + 1] =  { 0, ... };

float g_fMinNadeHull[3] = {-2.5, -2.5, -2.5};
float g_fMaxNadeHull[3] = {2.5, 2.5, 2.5};
float g_fMaxWorldLength;
float g_fSpinVel[3] = {0.0, 0.0, 200.0};
float g_fSmokeOrigin[3] = {-30.0,0.0,0.0};
float g_fSmokeAngle[3] = {0.0,-180.0,0.0};

int g_iType[MAXPLAYERS + 1] =  { -1, ... };

public void OnPluginStart()
{
	g_cDamage = CreateConVar("ttt_missile_damage", "100", "Sets the maximum amount of damage the missiles can do", _, true, 1.0);
	g_cRadius = CreateConVar("ttt_missile_radius", "350", "Sets the explosive radius of the missiles", _, true, 1.0);
	g_cSpeed = CreateConVar("ttt_missile_speed", "500.0", "Sets the speed of the missiles", _, true, 300.0 ,true, 3000.0);
	g_cArc = CreateConVar("ttt_missile_arc", "1", "1 enables the turning arc of missiles, 0 makes turning instant for missiles", _, true, 0.0, true, 1.0);
	g_cModel = CreateConVar("ttt_missile_model", "models/weapons/w_missile_closed.mdl", "The model of the missile (You need to add it to the donwloadtable yourself)");
	
	g_cPriceT = CreateConVar("ttt_missile_price_t", "10000", "Price for the missile for Traitors", _, true, 0.0);
	g_cPriceD = CreateConVar("ttt_missile_price_d", "0", "Price for the missile for Detectives", _, true, 0.0);
	g_cPriceI = CreateConVar("ttt_missile_price_i", "0", "Price for the missile for Innos", _, true, 0.0);
	g_cPriorityT = CreateConVar("ttt_missile_priority_t", "0", "Priority in shop list for Traitors", _, true, 0.0);
	g_cPriorityD = CreateConVar("ttt_missile_priority_d", "0", "Priority in shop list for Detectives", _, true, 0.0);
	g_cPriorityI = CreateConVar("ttt_missile_priority_i", "0", "Priority in shop list for Innos", _, true, 0.0);
	g_cAmountT = CreateConVar("ttt_missile_amount_t", "2", "How much missiles can a traitor buy?");
	g_cAmountD = CreateConVar("ttt_missile_amount_d", "0", "How much missiles can a detective buy?");
	g_cAmountI = CreateConVar("ttt_missile_amount_i", "0", "How much missiles can a innocent buy?");
	g_cName = CreateConVar("ttt_missile_name", "Missile", "The name of the missile in the shop");
	
	g_cPriceT_F = CreateConVar("ttt_missile_following_price_t", "10000", "Price for the following missile for Traitors", _, true, 0.0);
	g_cPriceD_F = CreateConVar("ttt_missile_following_price_d", "0", "Price for the following missile for Detectives", _, true, 0.0);
	g_cPriceI_F = CreateConVar("ttt_missile_following_price_i", "0", "Price for the following missile for Innos", _, true, 0.0);
	g_cPriorityT_F = CreateConVar("ttt_missile_following_priority_t", "0", "Priority in shop list for Traitors", _, true, 0.0);
	g_cPriorityD_F = CreateConVar("ttt_missile_following_priority_d", "0", "Priority in shop list for Detectives", _, true, 0.0);
	g_cPriorityI_F = CreateConVar("ttt_missile_following_priority_i", "0", "Priority in shop list for Innos", _, true, 0.0);
	g_cAmountT_F = CreateConVar("ttt_missile_following_amount_t", "2", "How much following missiles can a traitor buy?");
	g_cAmountD_F = CreateConVar("ttt_missile_following_amount_d", "0", "How much following missiles can a detective buy?");
	g_cAmountI_F = CreateConVar("ttt_missile_following_amount_i", "0", "How much following missiles can a innocent buy?");
	g_cName_F = CreateConVar("ttt_missile_following_name", "Following Missile", "The name of the following missile in the shop");
	
	HookEvent("player_spawn", Event_Reset);
	HookEvent("player_death", Event_Reset);
	
	AutoExecConfig(true);
}

public void OnAllPluginsLoaded()
{
	char longName[32];
	g_cName.GetString(longName, sizeof(longName));
	
	TTT_RegisterCustomItem(SHORT_NAME_T, longName, g_cPriceT.IntValue, TTT_TEAM_TRAITOR, g_cPriorityT.IntValue);
	TTT_RegisterCustomItem(SHORT_NAME_I, longName, g_cPriceD.IntValue, TTT_TEAM_DETECTIVE, g_cPriorityD.IntValue);
	TTT_RegisterCustomItem(SHORT_NAME_D, longName, g_cPriceI.IntValue, TTT_TEAM_INNOCENT, g_cPriorityI.IntValue);
	
	g_cName_F.GetString(longName, sizeof(longName));
	TTT_RegisterCustomItem(SHORT_NAMEF_T, longName, g_cPriceT_F.IntValue, TTT_TEAM_TRAITOR, g_cPriorityT_F.IntValue);
	TTT_RegisterCustomItem(SHORT_NAMEF_I, longName, g_cPriceD_F.IntValue, TTT_TEAM_DETECTIVE, g_cPriorityD_F.IntValue);
	TTT_RegisterCustomItem(SHORT_NAMEF_D, longName, g_cPriceI_F.IntValue, TTT_TEAM_INNOCENT, g_cPriorityI_F.IntValue);
}

public void OnMapStart()
{
	float WorldMinHull[3]; 
	float WorldMaxHull[3];
	GetEntPropVector(0, Prop_Send, "m_WorldMins", WorldMinHull);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", WorldMaxHull);
	g_fMaxWorldLength = GetVectorDistance(WorldMinHull, WorldMaxHull);
	
	AddFileToDownloadsTable("sound/weapons/rpg/rocket1.wav");
	
	AddFileToDownloadsTable("materials/models/weapons/w_missile/missile_side.vmt");
	
	PrecacheModel("models/weapons/w_missile_closed.mdl");
	
	PrecacheSound("weapons/rpg/rocket1.wav");
	PrecacheSound("weapons/hegrenade/explode5.wav");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "hegrenade_projectile", false))
	{
		HookSingleEntityOutput(entity, "OnUser2", InitMissile, true);
		
		char OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
		SetVariantString(OutputString);
		AcceptEntityInput(entity, "AddOutput");
		
		AcceptEntityInput(entity, "FireUser1");
	}
}

public int InitMissile(const char[] output, int caller, int activator, float delay)
{
	int NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
	
	// assume other plugins don't set this on any projectiles they create, this avoids conflicts.
	if (!IsClientValid(NadeOwner))
		return;
	
	if ((!g_iMissile[NadeOwner] && !g_iMissile_F[NadeOwner]) || g_iType[NadeOwner] != -1)
		return;
		
	if(g_iMissile_F[NadeOwner])
	{
		g_iMissile_F[NadeOwner]--;
		g_iType[NadeOwner] = 1;
	}else{
		g_iMissile[NadeOwner]--;
		g_iType[NadeOwner] = 0;
	}
	char sModel[PLATFORM_MAX_PATH];
	g_cModel.GetString(sModel, sizeof(sModel));
	// stop the projectile thinking so it doesn't detonate.
	SetEntProp(caller, Prop_Data, "m_nNextThinkTick", -1);
	SetEntityMoveType(caller, MOVETYPE_FLY);
	SetEntityModel(caller, sModel);
	// make it spin correctly.
	SetEntPropVector(caller, Prop_Data, "m_vecAngVelocity", g_fSpinVel);
	// stop it bouncing when it hits something
	SetEntPropFloat(caller, Prop_Send, "m_flElasticity", 0.0);
	SetEntPropVector(caller, Prop_Send, "m_vecMins", g_fMinNadeHull);
	SetEntPropVector(caller, Prop_Send, "m_vecMaxs", g_fMaxNadeHull);
	
	int SmokeIndex = CreateEntityByName("env_rockettrail");
	if (SmokeIndex != -1)
	{
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_Opacity", 0.5);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRate", 100.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_ParticleLifetime", 0.5);
		float smokeRed[3] =  { 0.5, 0.25, 0.25 };
		SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", smokeRed);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_StartSize", 5.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_EndSize", 30.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRadius", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MinSpeed", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MaxSpeed", 10.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_flFlareScale", 1.0);
		DispatchSpawn(SmokeIndex);
		ActivateEntity(SmokeIndex);
		char NadeName[20];
		Format(NadeName, sizeof(NadeName), "Nade_%i", caller);
		DispatchKeyValue(caller, "targetname", NadeName);
		SetVariantString(NadeName);
		AcceptEntityInput(SmokeIndex, "SetParent");
		TeleportEntity(SmokeIndex, g_fSmokeOrigin, g_fSmokeAngle, NULL_VECTOR);
	}
	
	float NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	float OwnerAng[3];
	GetClientEyeAngles(NadeOwner, OwnerAng);
	float OwnerPos[3];
	GetClientEyePosition(NadeOwner, OwnerPos);
	TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
	float InitialPos[3];
	TR_GetEndPosition(InitialPos);
	float InitialVec[3];
	MakeVectorFromPoints(NadePos, InitialPos, InitialVec);
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, g_cSpeed.FloatValue);
	float InitialAng[3];
	GetVectorAngles(InitialVec, InitialAng);
	TeleportEntity(caller, NULL_VECTOR, InitialAng, InitialVec);
	
	EmitSoundToAll("weapons/rpg/rocket1.wav", caller, 1, 90);
	
	HookSingleEntityOutput(caller, "OnUser2", MissileThink);
	
	char OutputString[] = "OnUser1 !self:FireUser2::0.1:-1";
	SetVariantString(OutputString);
	AcceptEntityInput(caller, "AddOutput");
	
	AcceptEntityInput(caller, "FireUser1");
	
	SDKHook(caller, SDKHook_StartTouch, OnStartTouch);
}

public void MissileThink(const char[] output, int caller, int activator, float delay)
{
	int NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
	
	// detonate any missiles that stopped for any reason but didn't detonate.
	float CheckVec[3];
	GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CheckVec);
	if ((CheckVec[0] == 0.0) && (CheckVec[1] == 0.0) && (CheckVec[2] == 0.0))
	{
		StopSound(caller, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(caller);
		return;
	}
	
	float NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	
	if (g_iType[NadeOwner] > 0)
	{
		float ClosestDistance = g_fMaxWorldLength;
		float TargetVec[3];
		
		int ClosestEnemy;
		float EnemyDistance;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
					continue;
				float EnemyPos[3];
				GetClientEyePosition(i, EnemyPos);
				TR_TraceHullFilter(NadePos, EnemyPos, g_fMinNadeHull, g_fMaxNadeHull, MASK_SOLID, DontHitOwnerOrNade, caller);
				if (TR_GetEntityIndex() == i)
				{
					EnemyDistance = GetVectorDistance(NadePos, EnemyPos);
					if (EnemyDistance < ClosestDistance)
					{
						ClosestEnemy = i;
						ClosestDistance = EnemyDistance;
					}
				}
			}
		}
		// no target found, continue along current trajectory.
		if (!IsClientValid(ClosestEnemy))
		{
			AcceptEntityInput(caller, "FireUser1");
			return;
		}else{
			float EnemyPos[3];
			GetClientEyePosition(ClosestEnemy, EnemyPos);
			MakeVectorFromPoints(NadePos, EnemyPos, TargetVec);
		}
		
		float CurrentVec[3];
		GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CurrentVec);
		float FinalVec[3];
		if (g_cArc.BoolValue && (ClosestDistance > 100.0))
		{
			NormalizeVector(TargetVec, TargetVec);
			NormalizeVector(CurrentVec, CurrentVec);
			ScaleVector(TargetVec, g_cSpeed.FloatValue / 1000.0);
			AddVectors(TargetVec, CurrentVec, FinalVec);
		}else{
			FinalVec = TargetVec;
		}
		
		NormalizeVector(FinalVec, FinalVec);
		ScaleVector(FinalVec, g_cSpeed.FloatValue);
		float FinalAng[3];
		GetVectorAngles(FinalVec, FinalAng);
		TeleportEntity(caller, NULL_VECTOR, FinalAng, FinalVec);
	}
	
	AcceptEntityInput(caller, "FireUser1");
}

public bool DontHitOwnerOrNade(int entity, int contentsMask, any data)
{
	int NadeOwner = GetEntPropEnt(data, Prop_Send, "m_hThrower");
	return ((entity != data) && (entity != NadeOwner));
}

public Action OnStartTouch(int entity, int other) 
{
	if (other == 0)
	{
		StopSound(entity, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(entity);
	} else if((GetEntProp(other, Prop_Data, "m_nSolidType") != SOLID_NONE) && (!(GetEntProp(other, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID))) {
		StopSound(entity, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(entity);
	}
	return Plugin_Continue;
}

void CreateExplosion(int entity)
{
	UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
	
	float MissilePos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", MissilePos);
	int MissileOwner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	int MissileOwnerTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	g_iType[MissileOwner] = -1;
	
	int ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
		DispatchKeyValue(ExplosionIndex,"classname", "hegrenade_projectile");
		
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", g_cDamage.IntValue);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", g_cRadius.IntValue);
		
		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		TeleportEntity(ExplosionIndex, MissilePos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", MissileOwner);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", MissileOwnerTeam);
		
		EmitSoundToAll("weapons/hegrenade/explode5.wav", ExplosionIndex, 1, 90);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		
		DispatchKeyValue(ExplosionIndex,"classname","env_explosion");
		
		AcceptEntityInput(ExplosionIndex, "Kill");
	}
	
	AcceptEntityInput(entity, "Kill");
}

public void Event_Reset(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TTT_IsClientValid(client))
		ResetClient(client);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort)
{
	if(TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME_T, false))
		{
			if(!(g_iPAmount[client] < g_cAmountT.IntValue))
				return Plugin_Stop;
			
			GiveMissile(client);
			GiveGrenade(client);
		}
		else if(StrEqual(itemshort, SHORT_NAME_D, false))
		{
			if(!(g_iPAmount[client] < g_cAmountD.IntValue))
				return Plugin_Stop;
			
			GiveMissile(client);
			GiveGrenade(client);
		}
		else if(StrEqual(itemshort, SHORT_NAME_I, false))
		{
			if(!(g_iPAmount[client] < g_cAmountI.IntValue))
				return Plugin_Stop;
			
			GiveMissile(client);
			GiveGrenade(client);
		}
		else if(StrEqual(itemshort, SHORT_NAMEF_T, false))
		{
			if(!(g_iPAmount_F[client] < g_cAmountT_F.IntValue))
				return Plugin_Stop;
			
			GiveFollowingMissile(client);
			GiveGrenade(client);
		}
		else if(StrEqual(itemshort, SHORT_NAMEF_D, false))
		{
			if(!(g_iPAmount_F[client] < g_cAmountD_F.IntValue))
				return Plugin_Stop;
			
			GiveFollowingMissile(client);
			GiveGrenade(client);
		}
		else if(StrEqual(itemshort, SHORT_NAMEF_I, false))
		{
			if(!(g_iPAmount_F[client] < g_cAmountI_F.IntValue))
				return Plugin_Stop;
			
			GiveFollowingMissile(client);
			GiveGrenade(client);
		}
	}
	return Plugin_Continue;
}

void GiveMissile(int client)
{
	g_iMissile[client]++;
	g_iPAmount[client]++;
}

void GiveFollowingMissile(int client)
{
	g_iMissile_F[client]++;
	g_iPAmount_F[client]++;
}

void GiveGrenade(int client)
{
	int AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 11);
	
	if (!AmmoReserve)
	{
		GivePlayerItem(client, "weapon_hegrenade");
	}
	
	if (AmmoReserve)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", g_iMissile[client] + g_iMissile_F[client], 4, 11);
	}
}

void ResetClient(int client)
{
	g_iPAmount[client] = 0;
	g_iMissile[client] = 0;
	g_iPAmount_F[client] = 0;
	g_iMissile_F[client] = 0;
	g_iType[client] = -1;
}

stock bool IsClientValid(int client)
{
	if(0 < client <= MaxClients && IsClientConnected(client))
		return true;
	
	return false;
}
