#include <sourcemod>
#include <sdktools>

// Original reference: "https://forums.alliedmods.net/showthread.php?p=2709375"
public Plugin myinfo =
{
    name        = "Left 4 World Wide Rank",
    author      = "BoboDev",
    description = "Changes server rank and number of players served.",
    version     = "1.1",
    url         = "https://github.com/LeandroTheDev/left_4_wwr"

};

char     gv_DatabaseConfig[PLATFORM_MAX_PATH];
char     gv_TableName[PLATFORM_MAX_PATH];
bool     gv_ShouldDebug = false;
Database gv_Database    = null;

int  gv_ServerRank    = 1;
int  gv_ServedPlayers = 0;

ConVar gc_DatabaseConfig;
ConVar gc_TableName;
ConVar gc_ShouldDebug;

void ReadVariables()
{
    gc_DatabaseConfig.GetString(gv_DatabaseConfig, sizeof(gv_DatabaseConfig));
    PrintToServer("[Left 4 World Wide Rank] Database config: %s", gv_DatabaseConfig);

    gc_TableName.GetString(gv_TableName, sizeof(gv_TableName));
    PrintToServer("[Left 4 World Wide Rank] Table name: %s", gv_TableName);

    gv_ShouldDebug = gc_ShouldDebug.BoolValue;
    PrintToServer("[Left 4 World Wide Rank] Should debug: %b", gv_ShouldDebug);
}

public void OnPluginStart()
{
    gc_DatabaseConfig = CreateConVar(
        "worldRankDatabase",
        "default",
        "Database configuration name from databases.cfg",
        FCVAR_NONE);

    gc_TableName = CreateConVar(
        "worldRankTable",
        "left4dead2",
        "Table name to count players from",
        FCVAR_NONE);

    gc_ShouldDebug = CreateConVar(
        "worldRankDebug",
        "0",
        "Enable debug logging",
        FCVAR_NONE,
        true,
        0.0,
        true,
        1.0);

    RegConsoleCmd("worldrankreload", CommandReload, "Reload Cvars");

    ReadVariables();
    ConnectDatabase();
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

public Action CommandReload(int client, int args)
{
    if (client != 0 && !IsValidClient(client))
        return Plugin_Stop;
    if (client != 0 && !CheckCommandAccess(client, "sm_worldrankreload", ADMFLAG_BAN))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    ReadVariables();
    return Plugin_Handled;
}

public OnClientConnected()
{
    GameRules_SetProp("m_iServerRank", gv_ServerRank);
    GameRules_SetProp("m_iServerPlayerCount", gv_ServedPlayers);
    if (gv_ShouldDebug)
        PrintToServer("[Left 4 World Wide Rank] m_iServerRank = %d m_iServerPlayerCount = %d", gv_ServerRank, gv_ServedPlayers);

    RefreshServedPlayers();
}

stock void ConnectDatabase()
{
    Database.Connect(ConnectDatabase_Callback, gv_DatabaseConfig);
}

public void ConnectDatabase_Callback(Database database, const char[] error, any data)
{
    if (database == null)
    {
        PrintToServer("[Left 4 World Wide Rank] ERROR: Cannot connect to the database: %s", error);
        return;
    }

    gv_Database = database;
    PrintToServer("[Left 4 World Wide Rank] Database connected.");
}

stock void RefreshServedPlayers()
{
    if (gv_Database == null)
    {
        PrintToServer("[Left 4 World Wide Rank] Database not connected, skipping refresh.");
        return;
    }

    char query[256];
    Format(query, sizeof(query), "SELECT COUNT(*) FROM `%s`", gv_TableName);

    if (gv_ShouldDebug)
        PrintToServer("[Left 4 World Wide Rank] Query: SELECT COUNT(*) FROM `%s`", gv_TableName);

    SQL_TQuery(gv_Database, RefreshServedPlayers_Callback, query);
}

public void RefreshServedPlayers_Callback(Database database, DBResultSet results, const char[] error, any data)
{
    if (results == null || error[0] != '\0')
    {
        PrintToServer("[Left 4 World Wide Rank] Database error on refresh: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        gv_ServedPlayers = results.FetchInt(0);
        GameRules_SetProp("m_iServerPlayerCount", gv_ServedPlayers);

        if (gv_ShouldDebug)
            PrintToServer("[Left 4 World Wide Rank] Served Players refreshed: %d", gv_ServedPlayers);
    }
}
