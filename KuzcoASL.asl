//	The Emperor's New Groove PC autosplitter. English, French, Italian and Finish versions
//	Developped by UltraStars3000 || Tested by the entire TENG crew

//  TODO LIST:
//  Spanish & German support and more if any

state("groove")
{
	byte ENGLISH : 0x179D00;
	byte FRENCH : 0x179E9C;
	byte ITALIAN : 0x179E94;
	byte FINISH : 0x179EA4;
}

state("groove", "EN")
{
	byte World_ID : 0x184548;
	byte Chapter_ID : 0x18454C;
	byte State : 0x1807E9;
	byte Ingame : 0x2D991C;
	byte ChSw : 0x2D8B40;
	byte IsFade : 0x182DC0;
	
	byte Secrets : 0x1844F4;
	byte Coins : 0x1FC604;
	byte Wampys : 0x1FC614;	
}
state("groove", "FR")
{
	byte World_ID : 0x184DE8;
	byte Chapter_ID : 0x184DEC;
	byte State : 0x181089;
	byte Ingame : 0x2DA1C4;
	byte ChSw : 0x2D93E0;
	byte IsFade : 0x183664;
	
	byte Secrets : 0x1844F4;
	byte Coins : 0x1FCEA4;
	byte Wampys : 0x1FCEB4;
}
state("groove", "IT")
{
	byte World_ID : 0x184EB8;
	byte Chapter_ID : 0x184EBC;
	byte State : 0x181159;
	byte Ingame : 0x2DA294;
	byte ChSw : 0x2D94B0;
	byte IsFade : 0x183734;
	
	byte Secrets : 0x184E64;
	byte Coins : 0x1FCF74;
	byte Wampys : 0x1FCF84;	
}
state("groove", "FI")
{
	byte World_ID : 0x184F08;
	byte Chapter_ID : 0x184F0C;
	byte State : 0x1811A9;
	byte Ingame : 0x2DA2E4;
	byte ChSw : 0x2D9500;
	byte IsFade : 0x183784;
	
	byte Secrets : 0x184EB4;
	byte Coins : 0x1FCFC4;
	byte Wampys : 0x1FCFD4;
}

startup
{
	settings.Add("info", true, "The Emperor's New Groove autospliiter v0.9.5a by UltraStars3000");
	settings.SetToolTip("info", "If you like to report bugs or to contribute on this autosplitter, feel free to contact me on Discord: UltraStars3000#8412");
	settings.Add("contact", true, "Contact me if you possess any version that isn't supported");
	
	settings.Add("isHundo", false, "100%");
	settings.SetToolTip("isHundo", "Adds an additionnal verification at the end of each level so it only splits when the level is fully completed");
	
	settings.Add("isIL", false, "Individual Levels");
	settings.SetToolTip("isIL", "This option will allow the autosplitter to start whenever a level is started");
}

init
{	
	vars.lang = "NULL";
	if(current.ENGLISH == 81)
	{
		version = "EN";
		vars.lang = "English";
	}
	else if(current.FRENCH == 81)
	{
		version = "FR";
		vars.lang = "French";
	}
	else if(current.ITALIAN == 69)
	{
		version = "IT";
		vars.lang = "Italian";
	}
	else if(current.FINISH == 76)
	{
		version = "FI";
		vars.lang = "Finish";
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
	
	vars.indexArray = new byte[,] {	{0,1,2,3,0},
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
	
}

update
{
	if(current.Wampys == old.Wampys+1)
	{
		vars.hasWampy = true;
	}
	if(old.State != 0 && current.State == 0)
	{
		vars.hasWampy = false;
	}
}

start
{
	if(settings["isIL"])
	{
		if(old.Ingame == 1 && current.Ingame == 0)
		{
			vars.index = vars.indexArray[current.World_ID-1, current.Chapter_ID-1];
			vars.hasWampy = false;
			return true;
		}
	}
	else
	{
		if(old.Ingame == 1 && current.Ingame == 0 && current.World_ID == 1 && current.Chapter_ID == 1)
		{
			vars.index = 0;
			vars.hasWampy = false;
			return true;
		}
	}
}

split
{
	if(vars.asCase == 0)
	{
		if((old.World_ID == vars.levelArray[vars.index, 0] && old.Chapter_ID == vars.levelArray[vars.index, 1] && current.World_ID == vars.levelArray[vars.index+1, 0] && current.Chapter_ID == vars.levelArray[vars.index+1, 1]) || (old.ChSw == 0 && current.ChSw == 1))
		{
			if(current.State != 0 && (!settings["isHundo"] || current.Secrets == vars.secretArray[vars.index] && vars.hasWampy && current.Coins == vars.coinsArray[vars.index]))
			{
				vars.hasWampy = false;
				if(vars.levelArray[vars.index+1, 1] != 6)
				{
					vars.index += 1;
					vars.asCase = 1;
				}
				else
				{
					return true;
				}
			}
		}
	}
	else if(vars.asCase == 1)
	{
		if(old.State != current.State)
		{
			if(!settings["isIL"])
			{
				vars.asCase = 0;
				return true;
			}
			vars.asCase = 2;
		}
	}
	else
	{
		if(old.IsFade == 0 && current.IsFade == 1)
		{
			vars.asCase = 0;
			return true;
		}
	}
}

reset
{
	if(((current.World_ID == 1 && current.Chapter_ID == 1) || settings["isIL"]) && old.Ingame == 0 && current.Ingame == 1)
	{
		return true;
	}
}
