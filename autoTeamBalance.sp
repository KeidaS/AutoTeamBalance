#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Auto Team Balance CSGO",
	author = "KeidaS",
	description = "Auto Team Balance",
	version = "1.0",
	url = "www.hermandadfenix.es"
};

Handle db = INVALID_HANDLE;

bool isTerroristValid[MAXPLAYERS + 1] = false;
int terroristCount = 0;
int playersOnTValids[MAXPLAYERS + 1] = 0;
int randomAux = 999;
int swapsNeeded = 0;
public void OnPluginStart() {
	ConnectDB();
	HookEvent("round_end", Event_OnRoundEnd);
}

public void ConnectDB() {
	char error[255];
	db = SQL_Connect("rankme", true, error, sizeof(error));
	if (db == INVALID_HANDLE) {
		LogError("ERROR CONNECTING TO THE DB");
	}
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	int Tcount = GetTeamClientCount(2);
	int CTcount = GetTeamClientCount(3);
	if ((CTcount * 2) < (Tcount + 1)) {
		while((CTcount * 2) < (Tcount-1)) {
			swapsNeeded++;
			CTcount++;
			Tcount--;
		}
		int playersOnT[MAXPLAYERS];
		for (int i = 1; i < MAXPLAYERS; i++) {
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) {
				playersOnT[terroristCount] = i;
				terroristCount++;
			}
		}
		for (int i = 0; i < terroristCount; i++) {
			char query[254];
			char steamID[32];
			GetClientAuthId(playersOnT[i], AuthId_Steam2, steamID, sizeof(steamID));
			Format(query, sizeof(query), "SELECT timeTotal FROM timerank WHERE steamid = '%s'", steamID);
			SQL_TQuery(db, OnRoundEndCallback, query, GetClientUserId(playersOnT[i]));
		}
		terroristCount = 0;
		for (int i = 0; i < MAXPLAYERS; i++) {
			if (isTerroristValid[i]) {
				playersOnTValids[terroristCount] = i;
				terroristCount++;
			}
		}
		if (terroristCount > 0) {
			for (int i = 0; i < swapsNeeded; i++) {
				int randomClient = GetRandomInt(0, terroristCount-1);
				if (randomAux == randomClient) {
					swapsNeeded++;
				} else{
					ChangeClientTeam(playersOnTValids[randomClient], 3);
				}
			}
		}
		terroristCount = 0;
		swapsNeeded = 0;
		randomAux = 999;
		for (int i = 0; i < MAXPLAYERS; i++) {
			isTerroristValid[i] = false;
			playersOnTValids[i] = 0;
		}
	}
}

public void OnRoundEndCallback(Handle owner, Handle hndl, char[] error, any data) {
	int client = GetClientOfUserId(data);
	if (hndl == INVALID_HANDLE) {
		LogError("ERROR GETING THE TIME");
		LogError("%i", error);
	} else if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) {
		LogError("NO TIME USER");
	} else {
		int time = SQL_FetchInt(hndl, 0);
		if (time >= 28800) {
			isTerroristValid[client] = true;
		}
	}
}