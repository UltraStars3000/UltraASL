//	Oddworld: Soulstorm PC autosplitter
//	Developped by UltraStars3000
//	Extended splits by GeekyLucii

// LEVELS ID:
// Front_End	= Main Menu
// ML_in		= The Raid On Monsaic
// GORGE		= The Ruins
// GORGE_BLIMP	= The Blimp
// SV_in		= The Funicular
// SV_out		= Sorrow Valley
// PHAT			= Phat Station
// Train		= The Hijack
// Trellis		= Reunion At The Old Trellis
// SB_post		= Slig Barracks
// NM_in		= Necrum
// NM_deep		= The Mines
// NM_trial		= The Sanctum
// NM_silo		= Escape
// CD_in		= FeeCo. Depot
// CD_Yards		= The Yards
// SS_in		= Brewery
// SS_out		= Eye Of The Storm
// TobysEscape_Path_XX
// VykkersLabsXX


state("soulstorm")
{
	int dummy : "GameAssembly.dll", 0x0;
}

startup
{
	settings.Add("info", true, "Oddworld: Soulstorm autosplitter v1.5.0 by UltraStars3000");
	settings.SetToolTip("info", "If you like to report bugs or contribute to this autosplitter, feel free to contact me on Discord: UltraStars3000#8412");
	
	settings.Add("isIL", false, "Individual Levels");
	settings.SetToolTip("isIL", "Allow the autosplitter to start whenever a level is started.");
	
	settings.Add("isExtnd", false, "Extended splits");
	settings.SetToolTip("isExtnd", "Allow the splitter to work with subsplits whithin a level. Select a category afterwards.");
	settings.Add("isAnyNMG", true, "Any% NMG (DEFAULT)", "isExtnd");

	settings.Add("customRate", false, "Custom Autosplitter refresh rate");
	settings.SetToolTip("customRate", "Changes the refresh rate of the autosplitter in order to get more accurate times, or help with performance");
	settings.Add("Hz30", false, "30 refreshes per second", "customRate");
	settings.Add("Hz45", false, "45 refreshes per second", "customRate");
	settings.Add("Hz60", true, "60 refreshes per second (DEFAULT)", "customRate");
	settings.Add("Hz75", false, "75 refreshes per second", "customRate");
	settings.Add("Hz90", false, "90 refreshes per second", "customRate");

	refreshRate = 60;

	vars.isBackup = false;
	vars.isEndMB = false;
	vars.global_Mil = 0;
	vars.backup_Mil = 0;
	vars.current_Mil = 0;
}

init
{
	vars.initialized = false;
	vars.debug = false;

	var patterns = new dynamic[,]
	{
		{ 14, "FF 90 E0 01 00 00 FF C3 89 5D 70" }, //DATA_00_MAIN
		{ 15, "0F 57 C0 0F 2F F8 0F 87 ?? ?? 00 00 48 8B 0D ?? ?? ?? ??" }, //DATA_01_APP
		{ 32, "8B 94 02 ?? BE 05 00 E8 ?? ?? ?? ?? 90 33 C9 FF 15 ?? ?? ?? ?? 90 C6 05 ?? ?? ?? ?? 01 48 8B ?? ?? ?? ?? ?? 48 8B ?? B8 00 00 00" }, //DATA_02_UNK
		{ 6,  "48 89 39 48 8B 15 ?? ?? ?? ?? 48 85 DB" }, //DATA_03_UNK
	};

	var offsetsptr = new dynamic[]
	{
		new dynamic[,] //DATA_00_MAIN
		{
			{ typeof(int  ), "milTimer", new int[] {0xB8, 0x8, 0x30, 0x28, 0x10, 0x20, 0xF8, 0x14} },
			{ typeof(int  ), "menuIdx", new int[] {0xB8, 0x8, 0x1990, 0x28, 0x10, 0x20, 0xB4} },
			{ typeof(bool ), "isEndingScreen", new int[] {0xB8, 0x8, 0xA00, 0x10} },
			{ typeof(long ), "currentDoor", new int[] {0xB8, 0x8, 0x5D0, 0x28, 0x10, 0x20, 0x40, 0x90, 0x68, 0x28, 0x20, 0x508} },
			{ typeof(uint ), "lastObjXSnap", new int[] {0xB8, 0x8, 0x5D0, 0x28, 0x10, 0x20, 0x38, 0x13D4} },
			{ typeof(uint ), "lastObjYSnap", new int[] {0xB8, 0x8, 0x5D0, 0x28, 0x10, 0x20, 0x38, 0x13D8} },
			{ typeof(long ), "actionType", new int[] {0xB8, 0x8, 0x5D0, 0x28, 0x10, 0x20, 0x38, 0xA30, 0x18} },
			{ typeof(long ), "firstDoor", new int[] {0xB8, 0x8, 0xD60, 0x28, 0x10, 0x20} },
			{ typeof(float), "abeXPos", new int[] {0xB8, 0x8, 0xE80, 0x28, 0x10, 0x70, 0x38, 0x10, 0x30, 0x30, 0x8, 0x38, 0x18, 0x0} },
			{ typeof(float), "abeYPos", new int[] {0xB8, 0x8, 0xE80, 0x28, 0x10, 0x70, 0x38, 0x10, 0x30, 0x30, 0x8, 0x38, 0x18, 0x4} },
			{ typeof(float), "abeZPos", new int[] {0xB8, 0x8, 0xE80, 0x28, 0x10, 0x70, 0x38, 0x10, 0x30, 0x30, 0x8, 0x38, 0x18, 0x8} },
			{ typeof(int  ), "tdMuds", new int[] {0xB8, 0x8, 0x968, 0x28, 0x10, 0x20, 0x88} },
		},
		new dynamic[,] //DATA_01_APP
		{
			{ typeof(string), "lvlID", new int[] {0xB8, 0x0, 0x120, 0x10, 0x14} }
		},
		new dynamic[,] //DATA_02_UNK
		{
			{ typeof(int ), "pauseIdx", new int[] {0xB8, 0x0, 0x60, 0x18, 0x48, 0x10, 0x20, 0xC0} },
			{ typeof(bool), "isLoadScreen", new int[] {0xB8, 0x0, 0x60, 0x18, 0x120, 0x10, 0x20, 0x78, 0x18} },
			{ typeof(float), "holdTimer", new int[] {0xB8, 0x0, 0x60, 0x18, 0x240, 0x10, 0x20, 0xEC} }
		},
		new dynamic[,] //DATA_03_UNK
		{
			{ typeof(long), "currentCP", new int[] {0xB8, 0x0} },
			{ typeof(long), "firstCP", new int[] {0xB8, 0x8, 0x10, 0x20} }
		}
	};

	// Finding pointers
	ProcessModuleWow64Safe gameModule = modules.First(x => x.ModuleName.Equals("GameAssembly.dll"));
	int moduleSize = gameModule.ModuleMemorySize;
	if(vars.debug) print("ModuleSize: " + moduleSize);
	IntPtr baseAddress = gameModule.BaseAddress;
	SigScanTarget target = new SigScanTarget();
	for(int i = 0; i < patterns.GetLength(0); ++i)
	{
		target.AddSignature(patterns[i,0], patterns[i,1]);
	}
	var addrs = new SignatureScanner(game, baseAddress, gameModule.ModuleMemorySize).ScanAll(target).ToArray();
	if(addrs.Length != target.Signatures.Count)
	{
		print("Signature Scan Failure");
		return;
	}

	// Main Memory Watchers creation
	long baseOffset = baseAddress.ToInt64() - 0x4;
	vars.watchList = new MemoryWatcherList();
	int offLen = offsetsptr.GetLength(0);
	vars.addrFinal = new int[offLen];
	for(int i = 0; i < offLen; ++i)
	{
		var result = addrs[i];
		vars.addrFinal[i] = (int)(memory.ReadPointer(result).ToInt64() + result.ToInt64() - baseOffset);
		
		for(int j = 0; j < offsetsptr[i].GetLength(0); ++j)
		{
			if(i==0 && j==0 && vars.debug)
			{
				string ver;
				switch(moduleSize)
				{
					case 0x385E000: 
						ver = "1.162";
						break;
					case 0x3865000:
						ver = "1.19.57673";
						break;
					case 0x3070000:
						ver = "1.20.57714";
						break;
					default:
						ver = "UNKNOWN";
						break;
				}
				print("GameVersion: " + ver);
			}

			var name = offsetsptr[i][j,1];
			var ptr = new DeepPointer("GameAssembly.dll", vars.addrFinal[i], offsetsptr[i][j,2]);
			var ptrType = offsetsptr[i][j,0]; 
			if(ptrType == typeof(string))
			{
				vars.watcher = new StringWatcher(ptr, 38);
			}
			else
			{
				var watcherType = typeof(MemoryWatcher<>).MakeGenericType(ptrType);
				vars.watcher = Activator.CreateInstance(watcherType, ptr);
			}
			vars.watchList.Add(vars.watcher);
			(vars as IDictionary<string, object>).Remove(name);
			(vars as IDictionary<string, object>).Add(name, vars.watcher);
		} 
	}

	vars.offType = new int[] {0};
	vars.splitList = new List<long>(new long[]{0x7FFFFFFFFFF});
	vars.sub_idx = 0;
	vars.save_menuidx = 0;

	vars.initialized = true;
}

exit
{
	vars.initialized = false;

	if(vars.lvlID.Current != "Front_End")
	{
		if(vars.save_menuidx <= 1)
		{
			vars.isBackup = true;
			vars.backup_Mil = vars.milTimer.Current;
		}
		else
		{
			vars.global_Mil = vars.global_Mil+vars.milTimer.Current;
		}
	}
}

update
{
	if (!vars.initialized) return false;
	vars.watchList.UpdateAll(game);

	if(vars.milTimer.Old > vars.milTimer.Current)
	{
		if(vars.isEndingScreen.Old)
		{
			vars.global_Mil = vars.global_Mil+vars.milTimer.Old;
			if(vars.debug) print("Summed up times by level ending (NL)");
			return false;
		}
		
		if(vars.isEndMB)
		{
			vars.isEndMB = false;
			vars.global_Mil = vars.global_Mil+vars.milTimer.Old;
			if(vars.debug) print("Summed up times by level ending (MB)");
		}
		if(vars.pauseIdx.Current == 2 || (vars.pauseIdx.Current == 6 && vars.save_menuidx > 1))
		{
			vars.global_Mil = vars.global_Mil+vars.milTimer.Old;
			if(vars.debug) print("Summed up times by level reset");
		}
	}

	if(vars.isEndingScreen.Old && !vars.isEndingScreen.Current && vars.lvlID.Current == "Front_End")
	{
		vars.isEndMB = true;
		if(vars.debug) print("Prepared level ending sum up (MB)");
	}

	if(vars.lvlID.Old != vars.lvlID.Current)
	{
		if(vars.lvlID.Old == "Front_End")
		{
			vars.save_menuidx = vars.menuIdx.Current;
			if(vars.debug) print("Stored last menu index: " + vars.save_menuidx);
		}
		
		if(vars.lvlID.Current == "Front_End" && vars.pauseIdx.Current == 6 && !vars.isEndingScreen.Current)
		{
			vars.isBackup = true;
			vars.backup_Mil = vars.milTimer.Current;
			if(vars.debug) print("Summed up times by main menu");
		}
	}

	if(vars.isBackup && vars.milTimer.Old == 0 && vars.milTimer.Current > 0)
	{
		vars.isBackup = false;
		if(vars.debug) print("Ended backup state");
	}
	
	//Extended Splits
	if((vars.firstDoor.Old == 0 && vars.firstDoor.Current != 0) || vars.firstCP.Old == 0 && vars.firstCP.Current != 0 && vars.lvlID.Current == "Train")
	{
		vars.extndAddr = new dynamic[,] //Lists
		{
			{vars.addrFinal[3], new int[] {0xB8, 0x8, 0x10, 0x00} },
			{vars.addrFinal[0], new int[] {0xB8, 0x8, 0xD60, 0x28, 0x10, 0x00} },
		};

		// 0: Checkpoint split
		// 1: Door split
		// 2: ObjectXSnap split
		// 3: Double ObjectXSnap split
		// 4: 3-Axis position split
		// 5: ObjectYSnap split (Hard coded for Escape)
		// 6: Dummy split

		switch((string) vars.lvlID.Current)
		{
			case "ML_in":
				print("The Raid On Monsaic LOADED");
				vars.offType = new int[] {0,0,0,0,6};
				vars.offList = new int[] {0x38,0x60,0x78,0x88};
				break;
			case "GORGE":
				print("The Ruins LOADED");
				vars.offType = new int[] {0,4,4,1,1,1,6};
				vars.offList = new int[] {0x40, 0x00, 0x00, 0x58, 0x50, 0x40};
				vars.extra = new dynamic[] {0, new float[] {-111.0F,-109.0F, 0.000F,2.000F, -38.00F,-36.00F}, new float[] {-18.00F,-16.00F, 28.00F,30.00F, 65.00F,67.00F},0,0,0};
				break;
			case "GORGE_BLIMP":
				print("The Blimp LOADED");
				vars.offType = new int[] {0,0,6};
				vars.offList = new int[] {0x40,0x60};
				break;
			case "SV_in":
				print("The Funicular LOADED");
				vars.offType = new int[] {1,1,1,6};
				vars.offList = new int[] {0x70,0x30,0x40};
				break;
			case "SV_out":
				print("Sorrow Valley LOADED");
				vars.offType = new int[] {1,0,1,0,6};
				vars.offList = new int[] {0x48,0x40,0x50,0x80};
				break;
			case "PHAT":
				print("Phat Station LOADED");
				vars.offType = new int[] {1,1,1,1,1,1,1,1,2,6};
				vars.offList = new int[] {0x40,0x38,0x50,0x28,0x70,0x68,0x98,0x88,0x00};
				vars.extra = new dynamic[] {0,0,0,0,0,0,0,0,0x424247AE};
				break;
			case "Train":
				print("The Hijack LOADED");
				vars.offType = new int[] {0,0,0,6};
				vars.offList = new int[] {0x40,0x60,0x68};
				break;
			case "Trellis":
				print("Reunion At The Old Trellis LOADED");
				vars.offType = new int[] {1,1,2,2,6};
				vars.offList = new int[] {0x30,0x28,0x00,0x00};
				vars.extra = new dynamic[] {0,0,0x4111999A,0x4131999A};
				break;
			case "SB_post":
				print("Slig Barracks LOADED");
				vars.offType = new int[] {1,0,1,0,0,6};
				vars.offList = new int[] {0x20,0x28,0x80,0x90,0xA8};
				break;
			case "NM_in":
				print("Necrum LOADED");
				vars.offType = new int[] {0,2,1,2,1,2,6};
				vars.offList = new int[] {0x38,0x00,0x38,0x00,0x58,0x00};
				vars.extra = new dynamic[] {0,0xC5488C52,0,0xC4594338,0,0x44FD56B6};
				break;
			case "NM_deep":
				print("The Mines LOADED");
				vars.offType = new int[] {1,1,1,1,1,1,1,2,6};
				vars.offList = new int[] {0x20,0x60,0x28,0x68,0x70,0x38,0x78,0x00};
				vars.extra = new dynamic[] {0,0,0,0,0,0,0,0xC37435C3};
				break;
			case "NM_trial":
				print("The Sanctum LOADED");
				vars.offType = new int[] {1,1,1,1,1,6};
				vars.offList = new int[] {0xA8,0x40,0x50,0x60,0x58};
				break;
			case "NM_silo":
				print("Escape LOADED");
				vars.offType = new int[] {5,5,5,5,5,5,5,5,5,6};
				vars.offList = new int[] {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
				vars.extra = new dynamic[] {0x40800000,0x42480000,0x428D0000,0x42B90000,0x42E60000,0x43098000,0x431F0000,0x43418000,0x43580000};
				break;
			case "CD_in":
				print("FeeCo. Depot LOADED");
				vars.offType = new int[] {0,0,2,6};
				vars.offList = new int[] {0x40,0x58,0x00};
				vars.extra = new dynamic[] {0,0,0x43C663D7};
				break;
			case "CD_Yards":
				print("The Yards LOADED");
				vars.offType = new int[] {3,0,2,2,6};
				vars.offList = new int[] {0x00,0x58,0x00,0x00};
				vars.extra = new dynamic[] {new uint[] {0xC4562CFD,0xC4566031},0,0xC434C21D,0xC423AF8B};
				break;
			case "SS_in":
				print("Brewery LOADED");
				vars.offType = new int[] {1,1,1,1,1,1,1,1,6};
				vars.offList = new int[] {0x48,0x60,0x68,0x88,0x98,0xA8,0xC8,0xD8};
				break;
			case "SS_out":
				print("Eye Of The Storm LOADED");
				vars.offType = new int[] {2,0,0,0,0,1,2,6};
				vars.offList = new int[] {0x00,0x48,0xC8,0x98,0xD0,0x30,0x00};
				vars.extra = new dynamic[] {0x42C9CCCD,0,0,0,0,0,0x42C63C25};
				break;	
			default:
				print("DLC LOADED");
				vars.offType = new int[] {6};
				vars.offList = new int[] {};
				break;
		}
		vars.splitList.Clear();
		for(int i = 0; i < vars.offList.GetLength(0); ++i)
		{
			if(vars.offType[i] < 2){
				vars.extndAddr[vars.offType[i],1][vars.extndAddr[vars.offType[i],1].GetLength(0)-1] = vars.offList[i];
				long cpAddr = new DeepPointer("GameAssembly.dll", vars.extndAddr[vars.offType[i],0], vars.extndAddr[vars.offType[i],1]).Deref<long>(game);
				vars.splitList.Add(cpAddr);
			}
			else
			{
				vars.splitList.Add(0x7FFFFFFFFFF);
			}
		}

		if(vars.debug)
		{
			var debugStrTab = new dynamic[] {"CheckID", "DoorsID"};
			for(int j = 0; j < 0; j++)
			{
				print("-----" + debugStrTab[j] + "-----");
				for(int i = 0x20; i <= 0xF8; i+=0x8)
				{
					vars.extndAddr[j,1][vars.extndAddr[j,1].GetLength(0)-1] = i;
					long drAddr = new DeepPointer("GameAssembly.dll", vars.extndAddr[j,0], vars.extndAddr[j,1]).Deref<long>(game);
					print("ID: " + Convert.ToString(i, 16).ToUpper() + " - " + Convert.ToString(drAddr, 16).ToUpper());
				} 
			}
		}
	}
}

gameTime
{
	if(vars.isBackup)
	{
		vars.finalIGT = vars.backup_Mil + vars.global_Mil;
	}
	else
	{
		vars.finalIGT = vars.global_Mil + vars.milTimer.Current;
	}
	vars.IGTtimer = new TimeSpan(0,0,0,0,vars.finalIGT);
	vars.timerStr = vars.IGTtimer.ToString();
	return vars.IGTtimer;
}

isLoading
{
	return true;
}

start
{
	if(vars.isLoadScreen.Old && !vars.isLoadScreen.Current && (settings["isIL"] && vars.lvlID.Current != "Front_End" || vars.lvlID.Current == "ML_in" && vars.save_menuidx <= 1))
	{
		if(settings["customRate"])
		{
			var rateList = new dynamic[,] {{"Hz90", 90}, {"Hz75", 75}, {"Hz60", 60}, {"Hz45", 45}, {"Hz30", 30}};
			for(int i = 0; i < rateList.GetLength(0); ++i)
			{
				if(settings[rateList[i,0]])
				{
					refreshRate = rateList[i,1];
				}
			}
		}

		vars.sub_idx = 0;
		vars.global_Mil = 0;
		vars.isBackup = false;
		vars.isEndMB = false;
		vars.backup_Mil = 0;
		return true;
	}
}

split
{
	if(!vars.isEndingScreen.Old && vars.isEndingScreen.Current)
	{
		vars.sub_idx = 0;
		return true;
	}

	if(settings["isExtnd"])
	{
		switch((int) vars.offType[vars.sub_idx])
		{
			case 0:
				if(vars.currentCP.Current == vars.splitList[vars.sub_idx])
				{
					vars.sub_idx++;
					return true;
				}
				break;
			case 1:
				if(vars.currentDoor.Current == vars.splitList[vars.sub_idx])
				{
					vars.sub_idx++;
					return true;
				}
				break;
			case 2:
				if(vars.lastObjXSnap.Current == vars.extra[vars.sub_idx] && vars.actionType.Current != 0)
				{
					vars.sub_idx++;
					return true;
				}
				break;
			case 3:
				if((vars.lastObjXSnap.Current == vars.extra[vars.sub_idx][0] || vars.lastObjXSnap.Current == vars.extra[vars.sub_idx][1]) && vars.actionType.Current != 0)
				{
					vars.sub_idx++;
					return true;
				}
				break;
			case 4:
				if(vars.abeXPos.Current >= vars.extra[vars.sub_idx][0] && vars.abeXPos.Current <= vars.extra[vars.sub_idx][1]
				&& vars.abeYPos.Current >= vars.extra[vars.sub_idx][2] && vars.abeYPos.Current <= vars.extra[vars.sub_idx][3]
				&& vars.abeZPos.Current >= vars.extra[vars.sub_idx][4] && vars.abeZPos.Current <= vars.extra[vars.sub_idx][5]
				&& vars.milTimer.Current == vars.milTimer.Old)
				{
					vars.sub_idx++;
					return true;
				}
				break;
			case 5:
				if(vars.tdMuds.Current == 0)
				{
					if(vars.lastObjXSnap.Current >= 0x40A665B0 && vars.lastObjXSnap.Current <= 0x40D9999F && vars.lastObjYSnap.Current == vars.extra[vars.sub_idx] && vars.actionType.Current != 0)
					{
						vars.sub_idx++;
						return true;
					}
				}
				break;
			default:
				break;
		}
	}
}

reset
{
	if(settings["isIL"] && vars.isLoadScreen.Current || vars.menuIdx.Current <= 1 && vars.holdTimer.Current >= 1.8 && vars.holdTimer.Current < 1.9)
	{
		return true;
	}
}
