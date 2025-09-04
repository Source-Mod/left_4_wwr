#include <sourcemod>
#include <sdktools>

// Original reference: "https://forums.alliedmods.net/showthread.php?p=2709375"
public Plugin myinfo =
{
    name        = "Left 4 World Wide Rank",
    author      = "BoboDev",
    description = "Changes server rank and number of players served.",
    version     = "1.0",
    url         = "https://github.com/LeandroTheDev/left_4_wwr"

};

char databaseConfig[PLATFORM_MAX_PATH] = "default";
char tableName[PLATFORM_MAX_PATH]      = "left4dead2";
bool shouldDebug                       = false;

int  serverRank                        = 1;
int  servedPlayers                     = 0;

public void OnPluginStart()
{
    char commandLine[512];
    if (GetCommandLine(commandLine, sizeof(commandLine)))
    {
        if (StrContains(commandLine, "-debug") != -1)
        {
            PrintToServer("[Left 4 World Wide Rank] Debug is enabled");
            shouldDebug = true;
        }
    }

    if (!GetCommandLineParam("-worldRankDatabase", databaseConfig, sizeof(databaseConfig)))
    {
        PrintToServer("[Left 4 World Wide Rank] Missing -worldRankDatabase parameter, using default");
        databaseConfig = "default";
    }
    else {
        if (databaseConfig[0] == EOS)
        {
            PrintToServer("[Left 4 World Wide Rank] -worldRankDatabase is empty, using default");
            databaseConfig = "default";
        }
        else {
            PrintToServer("[Left 4 World Wide Rank] -worldRankDatabase selected: %s", databaseConfig);
        }
    }

    if (!GetCommandLineParam("-worldRankTable", tableName, sizeof(tableName)))
    {
        PrintToServer("[Left 4 World Wide Rank] Missing -worldRankTable parameter, using default");
        tableName = "left4dead2";
    }
    else {
        if (tableName[0] == EOS)
        {
            PrintToServer("[Left 4 World Wide Rank] -worldRankTable is empty, using default");
            tableName = "left4dead2";
        }
        else {
            PrintToServer("[Left 4 World Wide Rank] -worldRankTable selected: %s", tableName);
        }
    }
}

public OnClientConnected()
{
    GameRules_SetProp("m_iServerRank", serverRank);
    GameRules_SetProp("m_iServerPlayerCount", servedPlayers);
    if (shouldDebug)
        PrintToServer("[Left 4 World Wide Rank] m_iServerRank = %d m_iServerPlayerCount = %d", serverRank, servedPlayers);

    RefreshServedPlayers();
}

stock void RefreshServedPlayers()
{
    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char query[256];
    Format(query, sizeof(query), "SELECT COUNT(*) FROM `%s`", tableName);

    char        statementError[456];
    DBStatement statement = SQL_PrepareQuery(database, query, statementError, sizeof(statementError));

    if (shouldDebug)
        PrintToServer("[Left 4 World Wide Rank] Query: SELECT COUNT(*) FROM `%s`", tableName);

    if (!SQL_Execute(statement))
    {
        char databaseError[456];
        SQL_GetError(database, databaseError, sizeof(databaseError));
        PrintToServer("[Left 4 World Wide Rank] Database error: %s", databaseError);
        PrintToServer("[Left 4 World Wide Rank] Statement error: %s", statementError);
    }

    if (SQL_HasResultSet(statement))
    {
        while (SQL_FetchRow(statement))
        {
            servedPlayers = SQL_FetchInt(statement, 0);
            if (shouldDebug)
                PrintToServer("[Left 4 World Wide Rank] Served Players refreshed: %d", servedPlayers);
        }
    }

    statement.Close();
    database.Close();
}

stock Database CreateDatabaseConnection()
{
    char     error[256];
    Database database = SQL_Connect(databaseConfig, true, error, sizeof(error));

    if (database == null)
    {
        PrintToServer("[Left 4 World Wide Rank] ERROR: Cannot connect to the database: %s", error);
        return null;
    }
    else {
        return database;
    }
}