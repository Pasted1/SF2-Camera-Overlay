/**
 * ============================================================================
 * SF2 Sub-Plugin: Custom Boss Camera Overlay
 * ============================================================================
 *
 * 		HOW TO USE:
 *
 * 
 *      "camera_overlay"    "materials/overlays/example.vtf"
 *
 * Add this single line anywhere in a boss profile .cfg
 * (below keys like "name", "model", "health", etc.) and, for as long as
 * that boss is active for the round, RED players see this overlay material
 * instead of SF2's normal camera overlay material. No precache call is added here,
 * Remember that the material needs downloading, and you need to list it in the
 * profile's existing "mat_download"/"download" section. :)
 *
 * NOTE: Incase two bosses spawn with "camera_overlay" in their cfg file
 * then this plugin will choose the first boss only.
 *
 * ============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cbasenpc>
#include <cbasenpc/util>

#define SF2
#include <sf2>

#define SF2CAMERA_PLUGIN_VERSION "1.0.0"


ConVar g_cvEnabled;

ConVar g_cvSf2CameraOverlay;
ConVar g_cvSf2CameraOverlayNoGrain;


bool g_bBossHasOverlay[MAX_BOSSES] = { false, ... };
char g_sBossOverlay[MAX_BOSSES][PLATFORM_MAX_PATH];

int g_iActiveOverlayBoss = -1;
bool g_bOverlayOverridden = false;
char g_sSavedCameraOverlay[PLATFORM_MAX_PATH];
char g_sSavedCameraOverlayNoGrain[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "SF2 Sub-Plugin - Custom Boss Camera Overlay",
	author = "Paste",
	description = "Adds a camera overlay for RED Team for specific bosses.",
	version = SF2CAMERA_PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sf2_camera_overlay_attr_enabled", "1", "Enable/disable the custom boss camera_overlay attribute.", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sf2_camera_overlay_attr");

	HookEvent("teamplay_round_start", Event_RoundReset, EventHookMode_PostNoCopy);
}

public void OnAllPluginsLoaded()
{
	g_cvSf2CameraOverlay = FindConVar("sf2_camera_overlay");
	g_cvSf2CameraOverlayNoGrain = FindConVar("sf2_camera_overlay_nograin");

	if (g_cvSf2CameraOverlay == null || g_cvSf2CameraOverlayNoGrain == null)
	{
		SetFailState("Could not find sf2_camera_overlay / sf2_camera_overlay_nograin ConVars - is sf2.smx loaded?");
	}
}

public void OnPluginEnd()
{
	RestoreOverlay();
}

public void OnMapEnd()
{
	RestoreOverlay();
}

public void Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MAX_BOSSES; i++)
	{
		g_bBossHasOverlay[i] = false;
	}
	RestoreOverlay();
}


public void SF2_OnBossAdded(int bossIndex)
{
	if (!g_cvEnabled.BoolValue || bossIndex < 0 || bossIndex >= MAX_BOSSES || g_cvSf2CameraOverlay == null)
	{
		return;
	}

	char profile[SF2_MAX_PROFILE_NAME_LENGTH];
	SF2_GetBossName(bossIndex, profile, sizeof(profile));

	char overlay[PLATFORM_MAX_PATH];
	if (!ReadBossCameraOverlay(profile, overlay, sizeof(overlay)))
	{
		g_bBossHasOverlay[bossIndex] = false;
		return;
	}

	g_bBossHasOverlay[bossIndex] = true;
	strcopy(g_sBossOverlay[bossIndex], sizeof(g_sBossOverlay[]), overlay);

	if (!g_bOverlayOverridden)
	{
		ApplyOverlay(bossIndex);
	}
	else
	{
		LogMessage("[Camera Overlay] Boss %d (profile '%s') has a camera_overlay too, but boss %d is already providing one - keeping the first one active.", bossIndex, profile, g_iActiveOverlayBoss);
	}
}

public void SF2_OnBossRemoved(int bossIndex)
{
	if (bossIndex < 0 || bossIndex >= MAX_BOSSES)
	{
		return;
	}

	g_bBossHasOverlay[bossIndex] = false;

	if (bossIndex != g_iActiveOverlayBoss)
	{
		return;
	}

	RestoreOverlay();

	for (int i = 0; i < MAX_BOSSES; i++)
	{
		if (g_bBossHasOverlay[i])
		{
			ApplyOverlay(i);
			return;
		}
	}
}


void ApplyOverlay(int bossIndex)
{
	if (g_cvSf2CameraOverlay == null || g_cvSf2CameraOverlayNoGrain == null)
	{
		return;
	}

	g_cvSf2CameraOverlay.GetString(g_sSavedCameraOverlay, sizeof(g_sSavedCameraOverlay));
	g_cvSf2CameraOverlayNoGrain.GetString(g_sSavedCameraOverlayNoGrain, sizeof(g_sSavedCameraOverlayNoGrain));

	g_cvSf2CameraOverlay.SetString(g_sBossOverlay[bossIndex]);
	g_cvSf2CameraOverlayNoGrain.SetString(g_sBossOverlay[bossIndex]);

	g_iActiveOverlayBoss = bossIndex;
	g_bOverlayOverridden = true;
}

void RestoreOverlay()
{
	if (!g_bOverlayOverridden)
	{
		return;
	}

	if (g_cvSf2CameraOverlay != null && g_cvSf2CameraOverlayNoGrain != null)
	{
		g_cvSf2CameraOverlay.SetString(g_sSavedCameraOverlay);
		g_cvSf2CameraOverlayNoGrain.SetString(g_sSavedCameraOverlayNoGrain);
	}

	g_iActiveOverlayBoss = -1;
	g_bOverlayOverridden = false;
}

bool ReadBossCameraOverlay(const char[] profile, char[] buffer, int bufferLen)
{
	buffer[0] = '\0';

	if (!FindBossCameraOverlay(profile, buffer, bufferLen))
	{
		return false;
	}

	NormalizeOverlayPath(buffer, bufferLen);
	return buffer[0] != '\0';
}

void NormalizeOverlayPath(char[] path, int pathLen)
{
	ReplaceString(path, pathLen, "\\", "/");

	if (strncmp(path, "materials/", 10, false) == 0)
	{
		char temp[PLATFORM_MAX_PATH];
		strcopy(temp, sizeof(temp), path[10]);
		strcopy(path, pathLen, temp);
	}

	int len = strlen(path);
	if (len > 4 && (StrEqual(path[len - 4], ".vtf", false) || StrEqual(path[len - 4], ".vmt", false)))
	{
		path[len - 4] = '\0';
	}
}

bool FindBossCameraOverlay(const char[] profile, char[] overlay, int overlayLen)
{
	static const char rootDirs[][] = { "configs/sf2/profiles" };

	for (int i = 0; i < sizeof(rootDirs); i++)
	{
		if (ScanDirForProfile(rootDirs[i], profile, overlay, overlayLen))
		{
			return true;
		}
	}

	static const char packRoots[][] = { "configs/sf2/profiles/packs" };

	for (int i = 0; i < sizeof(packRoots); i++)
	{
		char packsDir[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, packsDir, sizeof(packsDir), packRoots[i]);

		if (!DirExists(packsDir))
		{
			continue;
		}

		DirectoryListing packDirList = OpenDirectory(packsDir);
		if (packDirList == null)
		{
			continue;
		}

		char entryName[PLATFORM_MAX_PATH];
		FileType type;
		bool matched = false;

		while (packDirList.GetNext(entryName, sizeof(entryName), type))
		{
			if (type != FileType_Directory || entryName[0] == '.')
			{
				continue;
			}

			char relSubDir[PLATFORM_MAX_PATH];
			Format(relSubDir, sizeof(relSubDir), "%s/%s", packRoots[i], entryName);

			if (ScanDirForProfile(relSubDir, profile, overlay, overlayLen))
			{
				matched = true;
				break;
			}
		}

		delete packDirList;

		if (matched)
		{
			return true;
		}
	}

	return false;
}


bool ScanDirForProfile(const char[] relDir, const char[] profile, char[] overlay, int overlayLen)
{
	char dirPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dirPath, sizeof(dirPath), relDir);

	if (!DirExists(dirPath))
	{
		return false;
	}

	DirectoryListing dir = OpenDirectory(dirPath);
	if (dir == null)
	{
		return false;
	}

	char entryName[PLATFORM_MAX_PATH];
	FileType type;
	bool found = false;

	while (dir.GetNext(entryName, sizeof(entryName), type))
	{
		if (type != FileType_File || entryName[0] == '.')
		{
			continue;
		}

		int nameLen = strlen(entryName);
		if (nameLen <= 4 || !StrEqual(entryName[nameLen - 4], ".cfg", false))
		{
			continue;
		}

		char filePath[PLATFORM_MAX_PATH];
		Format(filePath, sizeof(filePath), "%s/%s", dirPath, entryName);

		KeyValues kv = new KeyValues("root");
		bool ok = FileToKeyValues(kv, filePath);
		if (ok)
		{
			char sectionName[SF2_MAX_PROFILE_NAME_LENGTH];
			kv.GetSectionName(sectionName, sizeof(sectionName));

			if (StrEqual(sectionName, profile, false))
			{
				kv.GetString("camera_overlay", overlay, overlayLen, "");
				found = true;
			}
		}
		delete kv;

		if (found)
		{
			break;
		}
	}

	delete dir;

	return found;
}
