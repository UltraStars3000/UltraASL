//	The Emperor's New Groove PC autosplitter.
//	Developped by UltraStars3000 & hdc0 || Tested by the entire TENG crew

state("groove") {}

startup
{
	settings.Add("info", true, "The Emperor's New Groove autospliiter v1.5.0 by UltraStars3000 & hdc0");
	settings.SetToolTip("info", "If you like to report bugs or to contribute on this autosplitter, feel free to contact me on Discord: UltraStars3000#8412");
	
	settings.Add("isHundo", false, "100%");
	settings.SetToolTip("isHundo", "Adds an additionnal verification at the end of each level so it only splits when the level is fully completed");
	
	settings.Add("isIL", false, "Individual Levels");
	settings.SetToolTip("isIL", "This option will allow the autosplitter to start whenever a level is started");
}

init
{
	vars.initialized = false;

	var patterns = new dynamic[,]
	{
		{ typeof(int ), "World_ID"  , 5, "8D 48 01 89 0D ?? ?? ?? ?? 74 2A" },
		{ typeof(int ), "Chapter_ID", 4, "8D 78 01 A1 ?? ?? ?? ?? 8D 0C 52" },
		{ typeof(int ), "State"     , 3, "85 C0 A3 ?? ?? ?? ?? 7E 26" },
		{ typeof(byte), "Ingame"    , 3, "74 4B A0 ?? ?? ?? ?? 84 C0" },
		{ typeof(byte), "ChSw"      , 3, "C3 C6 05 ?? ?? ?? ?? 00 52" },
		{ typeof(int ), "ILCheck"   , 4, "33 C0 89 15 ?? ?? ?? ?? 5E" },
		{ typeof(bool), "VialFade"  , 4, "75 18 39 1D ?? ?? ?? ?? 75 10"},
		{ typeof(int ), "ViewZone"  , 4, "D3 E6 85 35 ?? ?? ?? ?? 74 0E" },

		{ typeof(int ), "Secrets"   , 3, "74 1B A1 ?? ?? ?? ?? 8B" },
		{ typeof(int ), "Coins"     , 2, "8B 0D ?? ?? ?? ?? C1 E8 0C 3B C8" },
		{ typeof(int ), "Wampys"    , 6, "6A 20 C1 E8 0C A3 ?? ?? ?? ??" }
	};

	// Create memory watchers
	vars.memoryWatcherList = new MemoryWatcherList();
	var mainModule = modules.First();
	var scanner = new SignatureScanner(game, mainModule.BaseAddress, mainModule.ModuleMemorySize);
	for (int i = 0; i < patterns.GetLength(0); ++i)
	{
		var varType = patterns[i, 0];
		var name    = patterns[i, 1];
		var offset  = patterns[i, 2];
		var pattern = patterns[i, 3];

		var addr = scanner.Scan(new SigScanTarget(offset, pattern));
		if (addr == IntPtr.Zero)
		{
			print("Cannot determine address of \"" + name + "\"");
			return;
		}

		var varAddr = memory.ReadPointer(addr);
		print(string.Format("Variable \"{0}\" is at 0x{1:08X}", name, varAddr));
		var watcherType = typeof(MemoryWatcher<>).MakeGenericType(varType);
		var watcher = Activator.CreateInstance(watcherType, varAddr);
		vars.memoryWatcherList.Add(watcher);
		(vars as IDictionary<string, object>).Remove(name);
		(vars as IDictionary<string, object>).Add(name, watcher);
	}

	vars.index = 0;
	vars.levelArray = new byte[,] { {1,1},{1,2},{1,3},{1,4},
									{2,1},{2,2},{2,3},
									{3,1},{3,2},{3,3},{3,4},
									{4,1},{4,2},{4,3},
									{5,1},{5,2},{5,3},
									{6,1},{6,2},{6,3},
									{7,1},{7,2},{7,3},{7,4},{7,5},
									{8,1},{8,2},{8,3},{8,4},{8,5},{8,6}};
	
	vars.indexArray = new byte[,] { {0,1,2,3,0},
									{4,5,6,0,0},
									{7,8,9,10,0},
									{11,12,13,0,0},
									{14,15,16,0,0},
									{17,18,19,0,0},
									{20,21,22,23,24},
									{25,26,27,28,29}};
									
	vars.secretArray = new byte[] {2,1,2,2,1,1,0,1,1,1,1,1,2,2,2,4,1,3,3,7,0,5,0,3,0,2,1,1,3,1};
	vars.coinsArray = new byte[] {55,55,55,55,35,70,40,45,55,25,40,65,95,70,90,75,70,100,100,100,35,100,40,100,50,100,80,35,90,70};
	vars.hasWampy = false;
	vars.asCase = 0;

	vars.initialized = true;
}

update
{
	if (!vars.initialized) return false;
	vars.memoryWatcherList.UpdateAll(game);

	if(vars.Wampys.Current == vars.Wampys.Old+1)
	{
		vars.hasWampy = true;
	}
	if(vars.State.Old != 0 && vars.State.Current == 0)
	{
		vars.hasWampy = false;
	}
}

start
{
	if(settings["isIL"])
	{
		if(vars.Ingame.Old == 1 && vars.Ingame.Current == 0)
		{
			vars.index = vars.indexArray[vars.World_ID.Current-1, vars.Chapter_ID.Current-1];
			vars.asCase = 0;
			if(vars.World_ID.Current == 8 && vars.Chapter_ID.Current == 5)
			{
				vars.asCase = 2;
			}
			vars.hasWampy = false;
			return true;
		}
	}
	else
	{
		if(vars.Ingame.Old == 1 && vars.Ingame.Current == 0 && vars.World_ID.Current == 1 && vars.Chapter_ID.Current == 1)
		{
			vars.index = 0;
			vars.asCase = 0;
			vars.hasWampy = false;
			return true;
		}
	}
}

split
{
	if(vars.asCase == 0)
	{
		if((vars.World_ID.Old == vars.levelArray[vars.index, 0] && vars.Chapter_ID.Old == vars.levelArray[vars.index, 1] && vars.World_ID.Current == vars.levelArray[vars.index+1, 0] && vars.Chapter_ID.Current == vars.levelArray[vars.index+1, 1]) || (vars.ChSw.Old == 0 && vars.ChSw.Current == 1))
		{
			if(vars.State.Current != 174 && (!settings["isHundo"] || vars.Secrets.Current == vars.secretArray[vars.index] && vars.hasWampy && vars.Coins.Current == vars.coinsArray[vars.index]))
			{
				vars.hasWampy = false;
				vars.index += 1;
				vars.asCase = 1;
			}
		}
	}
	else if(vars.asCase == 1)
	{
		if((settings["isIL"] && vars.ILCheck.Old != vars.ILCheck.Current) || vars.State.Old != vars.State.Current)
		{
			vars.asCase = 0;
			if(vars.levelArray[vars.index+1, 1] == 6)
			{
				vars.asCase = 2;
			}
			return true;
		}
	}
	else
	{
		if(!vars.VialFade.Old && vars.VialFade.Current && vars.ViewZone.Current == 0x02000000)
		{
			return true;
		}
	}
}

reset
{
	if(((vars.World_ID.Current == 1 && vars.Chapter_ID.Current == 1) || settings["isIL"]) && vars.Ingame.Old == 0 && vars.Ingame.Current == 1)
	{
		return true;
	}
}
