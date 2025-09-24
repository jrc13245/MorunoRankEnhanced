--CORE LOGIC/CALCULATIONS WRITTEN BY MARTOCK(thread: https://forum.nostalrius.org/viewtopic.php?f=63&t=22558)
--EXPANDED WITH UI BY STRETPAKET @ NOSTALRIUS PVP(thread: https://forum.nostalrius.org/viewtopic.php?f=63&t=28269)
local isRunning = false;
local function isNAN(value) --standard func.
  return value ~= value
end
local initDone = false;
--CREATE FRAME 
local Frame = CreateFrame("Frame", "mreFrame", UIParent)
--AND SET EVENTS
	Frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")--on honorgain
	Frame:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")--"backup" event, fires when HK's update.
	Frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE") -- RUN WHEN GETTING REP WITH FACTION(AB/AV/WSG)
	Frame:RegisterEvent("ADDON_LOADED") --init evnt
	Frame:RegisterEvent("PLAYER_ENTERING_WORLD") --backup init evnt.
--EVENTS SET.

--UI STUFF BELOW(XML gth)
	local backdrop = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  
		edgeFile="";
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = {
			left = 0,
			right = 0,
			top = 0,
			bottom = 0
		}
	}
	Frame:SetWidth(110)
	Frame:SetHeight(72)
	Frame:SetPoint('CENTER', UIParent, 'CENTER', 0,0)
	Frame:SetFrameStrata('MEDIUM')
	Frame:SetBackdrop(backdrop)
	Frame:SetBackdropBorderColor(1,1,1,1)
	Frame:SetBackdropColor(1,1,1,0.4);
	Frame:SetScript("OnMouseDown",function()
	  Frame:StartMoving()
	end)
	Frame:SetScript("OnMouseUp",function()
		Frame:StopMovingOrSizing()
		if IsAddOnLoaded("MorunoRankEnhanced") then
			MorunoRank_SV["point"], _, MorunoRank_SV["relativePoint"], MorunoRank_SV["x"], MorunoRank_SV["y"] = Frame:GetPoint(); --SAVE POS IN SVs
		end
	end)
	local thisWeekLabel = Frame:CreateFontString("fntString2","ARTWORK",Frame)
		thisWeekLabel:SetFontObject("GameFontNormalSmall")
		thisWeekLabel:SetPoint("TOP", Frame, "TOP", 0, -10)
		thisWeekLabel:SetTextColor(1,1,1);

	local rankLabel = Frame:CreateFontString("fntString","ARTWORK",statusBar1)
		rankLabel:SetFontObject("GameFontNormalSmall")
		rankLabel:SetPoint("TOP", thisWeekLabel, "BOTTOM",0,-2)
		rankLabel:SetTextColor(1,1,1);

	local totalRPCalcLabel = Frame:CreateFontString("fntString2","ARTWORK",Frame)
		totalRPCalcLabel:SetFontObject("GameFontNormalSmall")
		totalRPCalcLabel:SetPoint("TOP", rankLabel, "BOTTOM", 0, -5)
		totalRPCalcLabel:SetTextColor(1,1,1);
		totalRPCalcLabel:SetText("Total RP Calc:");

	local statusBar2 = CreateFrame("StatusBar", nil, Frame)
		statusBar2:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		statusBar2:SetMinMaxValues(0, 100)
		statusBar2:SetValue(100)
		statusBar2:SetWidth(100)
		statusBar2:SetHeight(12)
		statusBar2:SetPoint("TOP",totalRPCalcLabel,"BOTTOM",0,-2)
		statusBar2:SetBackdrop(backdrop)
		statusBar2:SetBackdropColor(0,0,0,0.5);
		statusBar2:SetStatusBarColor(0,0,1)

	local statusBar2_Text = statusBar2:CreateFontString("fntString","ARTWORK",statusBar2)
		statusBar2_Text:SetFontObject("GameFontNormalSmall")
		statusBar2_Text:SetPoint("CENTER", statusBar2, "CENTER",0,0)
		statusBar2_Text:SetTextColor(1,1,1);

	local text2 = Frame:CreateFontString("fntString3","ARTWORK",Frame)
		text2:SetFontObject("GameFontNormalSmall")
		text2:SetPoint("CENTER", Frame, "TOP", 0, 0)
		text2:SetTextColor(1,0.4,0.7); --PALADIN COLOUR OFC
		text2:SetText("MorunoRankEnhanced");

	local text3 = Frame:CreateFontString("fntString3","ARTWORK",Frame)
		text3:SetFontObject("GameFontDarkGraySmall")
		text3:SetPoint("BOTTOM", Frame, "BOTTOM", 0, 1)
		text3:SetAlpha(0.3)
		text3:SetText("STRETPAKET");

		-- Turtle helpers (labels)
	local cityLabel = Frame:CreateFontString(nil, "ARTWORK", Frame)
		cityLabel:SetFontObject("GameFontNormalSmall")
		cityLabel:SetPoint("TOP", text3, "TOP", 0, 12)
		cityLabel:SetTextColor(0.9, 0.9, 0.3)

	local raceLabel = Frame:CreateFontString(nil, "ARTWORK", Frame)
		raceLabel:SetFontObject("GameFontNormalSmall")
		raceLabel:SetPoint("TOP", cityLabel, "BOTTOM", 0, -12)
		raceLabel:SetTextColor(0.9, 0.9, 0.3)

--UI STUFF DONE




--CORE LOGIC BELOW WRITTEN BY MARTOCK(thread: https://forum.nostalrius.org/viewtopic.php?f=63&t=22558)
local function getCurrentRank(CurrentRP) -- 
 
	local CRank = 0;
	 
		if(CurrentRP < 65000) then CRank = 14; end;
		if(CurrentRP < 60000) then CRank = 13; end;
		if(CurrentRP < 55000) then CRank = 12; end;
		if(CurrentRP < 50000) then CRank = 11; end;
		if(CurrentRP < 45000) then CRank = 10; end;
		if(CurrentRP < 40000) then CRank = 9; end;
		if(CurrentRP < 35000) then CRank = 8; end;
		if(CurrentRP < 30000) then CRank = 7; end;
		if(CurrentRP < 25000) then CRank = 6; end;
		if(CurrentRP < 20000) then CRank = 5; end;
		if(CurrentRP < 15000) then CRank = 4; end;
		if(CurrentRP < 10000) then CRank = 3; end;
		if(CurrentRP < 5000) then CRank = 2; end;
		if(CurrentRP < 2000) then CRank = 1; end;
		if(CurrentRP < 500) then CRank = 0; end;
	 
		return CRank;
 
end;
 
local function getCurrentHP(CurrentRP)
 
	local CRank = 0;
    if(CurrentRP == 14) then CRank = 60000; end;
    if(CurrentRP == 13) then CRank = 55000; end;
    if(CurrentRP == 12) then CRank = 50000; end;
    if(CurrentRP == 11) then CRank = 45000; end;
    if(CurrentRP == 10) then CRank = 40000; end;
    if(CurrentRP == 9) then CRank = 35000; end;
    if(CurrentRP == 8) then CRank = 30000; end;
    if(CurrentRP == 7) then CRank = 25000; end;
    if(CurrentRP == 6) then CRank = 20000; end;
    if(CurrentRP == 5) then CRank = 15000; end;
    if(CurrentRP == 4) then CRank = 10000; end;
    if(CurrentRP == 3) then CRank = 5000; end;
    if(CurrentRP == 2) then CRank = 2000; end;
    if(CurrentRP == 1) then CRank = 500; end;
 
    return CRank;
 
end;
 
 
local function MorunoRank()

    local PercentPVPRank = math.floor(GetPVPRankProgress("player") * 100);
    local UPVPRank = UnitPVPRank("player");
    local hk, CPLast = GetPVPThisWeekStats();

    -- Current RP by original logic
    local CurrentRP = (UPVPRank - 6) * 5000 + 5000 * PercentPVPRank / 100;
    local NeededRPToNextRank = (UPVPRank - 5) * 5000 - CurrentRP * 0.8;

    local CurrentRank = getCurrentRank(CurrentRP);
    local RA = CurrentRP;

    -- Original CP -> RP bracket mapping (unchanged)
    if (CPLast < 910) then CPup=0;CPlo=0;RPup=0;RPlo=0; end;
    if (CPLast < 2539 and CPLast > 910) then CPup=2539;CPlo=910;RPup=1000;RPlo=400; end;
    if (CPLast < 5231 and CPLast > 2539) then CPup=5231;CPlo=2539;RPup=2000;RPlo=1000; end;
    if (CPLast < 9221 and CPLast > 5231) then CPup=9221;CPlo=5231;RPup=3000;RPlo=2000; end;
    if (CPLast < 15491 and CPLast > 9221) then CPup=15491;CPlo=9221;RPup=4000;RPlo=3000; end;
    if (CPLast < 23369 and CPLast > 15491) then CPup=23369;CPlo=15491;RPup=5000;RPlo=4000; end;
    if (CPLast < 36958 and CPLast > 23369) then CPup=36958;CPlo=23369;RPup=6000;RPlo=5000; end;
    if (CPLast < 54408 and CPLast > 36958) then CPup=54408;CPlo=36958;RPup=7000;RPlo=6000; end;
    if (CPLast < 76316 and CPLast > 54408) then CPup=76316;CPlo=54408;RPup=8000;RPlo=7000; end;
    if (CPLast < 120420 and CPLast > 76316) then CPup=120420;CPlo=76316;RPup=9000;RPlo=8000; end;
    if (CPLast < 164960 and CPLast > 120420) then CPup=164960;CPlo=120420;RPup=10000;RPlo=9000; end;
    if (CPLast < 226508 and CPLast > 164960) then CPup=226508;CPlo=164960;RPup=11000;RPlo=10000; end;
    if (CPLast < 315119 and CPLast > 226508) then CPup=315119;CPlo=226508;RPup=12000;RPlo=11000; end;
    if (CPLast < 431492 and CPLast > 315119) then CPup=431492;CPlo=315119;RPup=13000;RPlo=12000; end;

    local RB = 0;
    if (CPup and CPlo and RPup and RPlo and CPup ~= CPlo) then
        RB = (CPLast - CPlo) / (CPup - CPlo) * (RPup - RPlo) + RPlo;
    end

    local RC = 0.2 * RA; -- weekly decay is still computed

    -- Turtle change: floor RP at your current rank minimum
    local rawEEarns = math.floor(RA + RB - RC);
    local floorRP = getCurrentHP(getCurrentRank(RA)); -- min RP for current rank
    local useFloor = (MorunoRank_SV and MorunoRank_SV["turtleMode"]) and true or false;
    local EEarns = useFloor and math.max(rawEEarns, floorRP) or rawEEarns;
    local floorApplied = useFloor and (EEarns > rawEEarns);

    local EarnedRank = getCurrentRank(EEarns);
	local nextRankMin = getCurrentHP(EarnedRank + 1);
	local thisRankMin = getCurrentHP(EarnedRank);
	local denom = (nextRankMin - thisRankMin);
	local PercentNextPVPRank = 0;
	if denom and denom > 0 then
		PercentNextPVPRank = math.floor(((EEarns - thisRankMin) * 100) / denom);
	end
	-- clamp 0..100 (defensive)
	if PercentNextPVPRank < 0 then PercentNextPVPRank = 0 end
	if PercentNextPVPRank > 100 then PercentNextPVPRank = 100 end


    -- Update UI (original text + Turtle hints)
    if isNAN(PercentNextPVPRank) or not denom or denom == 0 then
        thisWeekLabel:SetText("Rank incomputable.");
        rankLabel:SetText("Do some PVP!")
        totalRPCalcLabel:SetText("(^_^)");
        statusBar2:SetValue(0);
        if chatReport then
            DEFAULT_CHAT_FRAME:AddMessage("Current RP: "..CurrentRP.." at "..PercentPVPRank.."% (Rank "..CurrentRank..") RP To Next Rank: "..NeededRPToNextRank.." This Week RP gained:"..math.floor(RB).." @ Total RP Calc: "..EEarns.." at "..PercentNextPVPRank.."%(Rank "..EarnedRank..")","emote");
            chatReport = false;
        end
    else
        if chatReport then
            local floorNote = floorApplied and " [Turtle Floor Applied]" or ""
            DEFAULT_CHAT_FRAME:AddMessage("Current RP: "..CurrentRP.." at "..PercentPVPRank.."% (Rank "..CurrentRank..") RP To Next Rank: "..NeededRPToNextRank.." This Week RP gained:"..math.floor(RB).." @ Total RP Calc: "..EEarns.." at "..PercentNextPVPRank.."%(Rank "..EarnedRank..")"..floorNote,"emote");
            chatReport = false;
        end
        local floorTag = floorApplied and " (floor)" or ""
        -- total weekly RP needed to reach NEXT rank, starting from RA and including decay:
		-- Need RB_required such that: RA + RB_required - RC >= nextMin  =>  RB_required >= nextMin - 0.8*RA
		local nextMin_forNextRank = getCurrentHP(CurrentRank + 1)
		local weeklyNeededTotal = 0
		if nextMin_forNextRank then
			weeklyNeededTotal = math.max(0, nextMin_forNextRank - (RA - RC))  -- = max(0, nextMin - 0.8*RA)
		end

		-- Show "Weekly RP: <earned>/<needed total>"
		thisWeekLabel:SetText("Weekly RP: " .. math.floor(RB) .. "/" .. weeklyNeededTotal)
        local weeklyPercent = 0
		if weeklyNeededTotal > 0 then
			weeklyPercent = math.floor((math.max(0, RB) / weeklyNeededTotal) * 100)
			if weeklyPercent > 100 then weeklyPercent = 100 end
		else
			weeklyPercent = 100 -- already at/above next rank requirement for this week
		end
				rankLabel:SetText("Current rank: Rank "..CurrentRank..(floorApplied and " — Decay floored" or ""))
        totalRPCalcLabel:SetText("Total RP Calc(Rank "..EarnedRank..")"..floorTag..":")
		statusBar2:SetValue(weeklyPercent)
		statusBar2_Text:SetText(math.floor(RB) .. "/" .. weeklyNeededTotal .. " " .. weeklyPercent .. "%")
    end

    -- Turtle-only helper banners (toggleable)
	if MorunoRank_SV and MorunoRank_SV["showBanners"] then
		cityLabel:Show(); raceLabel:Show()

		local cutoff = (MorunoRank_SV and MorunoRank_SV["cityCutoffHK"]) or 0
		local raceCut = (MorunoRank_SV and MorunoRank_SV["raceCutoffHK"]) or 0
		local myRace  = (MorunoRank_SV and MorunoRank_SV["race"]) or "race?"

		if cutoff > 0 then
			if hk and hk >= cutoff then
				cityLabel:SetText("City Protector: Eligible (est.)")
			else
				local need = cutoff - (hk or 0)
				cityLabel:SetText("City Protector: Needs +".. math.max(need,0) .." HK")
			end
		else
			cityLabel:SetText("City Protector: set /mre citycutoff <HK>")
		end

		if raceCut > 0 then
			if hk and hk >= raceCut then
				raceLabel:SetText("Top "..myRace..": Eligible (est.)")
			else
				local need = raceCut - (hk or 0)
				raceLabel:SetText("Top "..myRace..": Needs +".. math.max(need,0) .." HK")
			end
		else
			raceLabel:SetText("Top-of-race title: /mre race <name>, /mre racecutoff <HK>")
		end
	else
		cityLabel:SetText(""); cityLabel:Hide()
		raceLabel:SetText(""); raceLabel:Hide()
	end
end
--LOGIC DONE

--INIT BELOW(LOAD SETTINGS LIKE POS, HIDDEN, LOCKED)
local function mrInit()	
	Frame:UnregisterEvent("ADDON_LOADED");--wont be needing this no more	
	--SEE IF SV's are loaded/set
	if MorunoRank_SV == nil or MorunoRank_SV["point"] == nil or MorunoRank_SV ["relativePoint"] == nil or MorunoRank_SV["x"] == nil or MorunoRank_SV["y"] == nil or MorunoRank_SV["hidden"] == nil or MorunoRank_SV["locked"] == nil then 
		--IF NOT, SET IT TO DEFAULT VALUES
		Frame:SetPoint("CENTER", UIParent, "CENTER", 0,0);		
		MorunoRank_SV = {}
		MorunoRank_SV["point"], _, MorunoRank_SV ["relativePoint"], MorunoRank_SV["x"], MorunoRank_SV["y"] = Frame:GetPoint();
		MorunoRank_SV["hidden"] = false;
		MorunoRank_SV["locked"] = false;
		-- Turtle WoW additions (defaults)
		MorunoRank_SV["showBanners"] = false
		MorunoRank_SV["turtleMode"]   = true
		MorunoRank_SV["cityCutoffHK"] = 0
		MorunoRank_SV["raceCutoffHK"] = 0
		MorunoRank_SV["race"]         = ""
		Frame:EnableMouse(true)
		Frame:SetMovable(true)
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced loaded with UI by Stretpaket",1,0.4,0.7);
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is shown \"/mre hide\" or \"/mre h\" to hide.",1,0.4,0.7);
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is unlocked \"/mre lock\" or \"/mre l\" to lock.",1,0.4,0.7);
	else
		--ELSE LOAD FROM SVs
		Frame:SetPoint(MorunoRank_SV["point"], nil, MorunoRank_SV ["relativePoint"], MorunoRank_SV["x"], MorunoRank_SV["y"]);
		-- Back-compat defaults for Turtle keys
		if MorunoRank_SV["showBanners"] == nil then MorunoRank_SV["showBanners"] = false end
		if MorunoRank_SV["turtleMode"]   == nil then MorunoRank_SV["turtleMode"]   = true end
		if MorunoRank_SV["cityCutoffHK"] == nil then MorunoRank_SV["cityCutoffHK"] = 0    end
		if MorunoRank_SV["raceCutoffHK"] == nil then MorunoRank_SV["raceCutoffHK"] = 0    end
		if MorunoRank_SV["race"]         == nil then MorunoRank_SV["race"]         = ""   end
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced loaded with UI by Stretpaket",1,0.4,0.7);		
		if MorunoRank_SV["hidden"] == true then
			Frame:Hide();
			DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is hidden. \"/mre show\" or \"/mre s\" to show.",1,0.4,0.7);
		else
			Frame:Show();
			DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is shown \"/mre hide\" or \"/mre h\" to hide.",1,0.4,0.7);
		end		
		if MorunoRank_SV["locked"] == true then
			Frame:EnableMouse(false)
			Frame:SetMovable(false)
			DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is locked. \"/mre unlock\" or \"/mre u\" to unlock.",1,0.4,0.7);
		else
			Frame:EnableMouse(true)
			Frame:SetMovable(true)
			DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is unlocked \"/mre lock\" or \"/mre l\" to lock.",1,0.4,0.7);
		end		
	end					
	initDone = true;	
end
--INIT DONE.

--SLASH MSGs
function SlashCmd(msg, self) 	
	if msg == "hide" or msg == "h" then
		Frame:Hide();
		MorunoRank_SV["hidden"] = true;
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is hidden. \"/mre show\" or \"/mre s\" to show.",1,0,0);
	elseif msg == "show" or msg=="s" then
		Frame:Show();
		MorunoRank_SV["hidden"] = false;
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is shown \"/mre hide\" or \"/mre h\" to hide.",0,1,0);		
	elseif msg == "lock" or msg == "l" then
		MorunoRank_SV["locked"] = true;
		Frame:EnableMouse(false)
		Frame:SetMovable(false)
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is locked. \"/mre unlock\" or \"/mre u\" to unlock.",1,0,0);
	elseif msg == "unlock" or msg == "u" then
		MorunoRank_SV["locked"] = false;
		Frame:EnableMouse(true)
		Frame:SetMovable(true)
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is unlocked \"/mre lock\" or \"/mre l\" to lock.",0,1,0);
	elseif msg == "help" then
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced(UI by Stretpaket)",1,0.4,0.7);
		DEFAULT_CHAT_FRAME:AddMessage("Help:");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre show\" or \"/mre s\" to show.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre hide\" or \"/mre h\" to hide.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre lock\" or \"/mre l\" to lock.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre unlock\" or \"/mre u\" to unlock.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre report\" or \"/mre r\" to to see full MorunoRank report.");
	elseif msg == "report" or msg == "r" then
		chatReport = true;
		MorunoRank();
	elseif msg == "reset" then
		Frame:ClearAllPoints()
		MorunoRank_SV = {
			y = 0,
			x = 0,
			point = "CENTER",
			relativePoint = "CENTER",
			locked = false,
			hidden = false,
			turtleMode   = true,
			cityCutoffHK = 0,
			raceCutoffHK = 0,
			race         = ""
		}
		Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		Frame:Show()
		Frame:EnableMouse(true)
		Frame:SetMovable(true)
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced was reset to original settings(placed in the middle of the screen)")
	-- Turtle mode on/off
	elseif string.find(msg, "^turtle%s") == 1 then
		local _, _, arg = string.find(msg, "^turtle%s+(%S+)")
		if arg == "on" then
			MorunoRank_SV["turtleMode"] = true
			DEFAULT_CHAT_FRAME:AddMessage("Turtle Mode: ON (RP never drops below your current rank floor).")
		elseif arg == "off" then
			MorunoRank_SV["turtleMode"] = false
			DEFAULT_CHAT_FRAME:AddMessage("Turtle Mode: OFF (classic behavior, RP can decay below floor).")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre turtle on|off")
		end

	-- City Protector cutoff (weekly HK estimate)
	elseif string.find(msg, "^citycutoff%s") == 1 then
		local _, _, nstr = string.find(msg, "^citycutoff%s+(%d+)$")
		local n = tonumber(nstr or "")
		if n then
			MorunoRank_SV["cityCutoffHK"] = n
			DEFAULT_CHAT_FRAME:AddMessage("City Protector cutoff set to "..n.." HK.")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre citycutoff <HK>")
		end

	-- Per-race top HK cutoff (weekly HK estimate)
	elseif string.find(msg, "^racecutoff%s") == 1 then
		local _, _, nstr = string.find(msg, "^racecutoff%s+(%d+)$")
		local n = tonumber(nstr or "")
		if n then
			MorunoRank_SV["raceCutoffHK"] = n
			DEFAULT_CHAT_FRAME:AddMessage("Race Leader cutoff set to "..n.." HK.")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre racecutoff <HK>")
		end

	-- Set your race name for the per-race title helper
	elseif string.find(msg, "^race%s+") == 1 then
		local _, _, r = string.find(msg, "^race%s+(.+)$")
		if r then
			-- trim leading/trailing spaces (Lua 5.0-safe)
			r = string.gsub(r, "^%s*(.-)%s*$", "%1")
			MorunoRank_SV["race"] = r  -- keep as string, no tonumber!
			DEFAULT_CHAT_FRAME:AddMessage("Your race set to: " .. r .. ".")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre race <yourRaceName>")
		end
	elseif string.find(msg, "^banners%s") == 1 then
		local _, _, arg = string.find(msg, "^banners%s+(%S+)")
		if arg == "on" then
			MorunoRank_SV["showBanners"] = true
			cityLabel:Show(); raceLabel:Show()
			DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced: banners ON.")
		elseif arg == "off" then
			MorunoRank_SV["showBanners"] = false
			cityLabel:SetText(""); cityLabel:Hide()
			raceLabel:SetText(""); raceLabel:Hide()
			DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced: banners OFF.")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre banners on|off")
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced(UI by Stretpaket)",1,0.4,0.7);
		DEFAULT_CHAT_FRAME:AddMessage("Help:");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre show\" or \"/mre s\" to show.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre hide\" or \"/mre h\" to hide.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre lock\" or \"/mre l\" to lock.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre unlock\" or \"/mre u\" to unlock.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre report\" or \"/mre r\" to see full MorunoRank report.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre reset\" to reset the window placement(to the middle of the screen).");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre turtle on|off\"  — apply Turtle RP floor.");
		DEFAULT_CHAT_FRAME:AddMessage("\"/mre banners on|off\" — show/hide City Protector & top-race banners.");
        DEFAULT_CHAT_FRAME:AddMessage("\"/mre citycutoff <HK>\" — your estimated top-8 HK cutoff.");
        DEFAULT_CHAT_FRAME:AddMessage("\"/mre race <name>\" and \"/mre racecutoff <HK>\" — per-race title estimate.");

	end	
end

SLASH_MRE1 = '/mre';
SLASH_MRE2 = '/MorunoRankEnhanced';
SlashCmdList["MRE"] = SlashCmd;
--SLASH MSGs DONE

--EVENTLISTENER
Frame:SetScript("OnEvent", function()		
	if IsAddOnLoaded("MorunoRankEnhanced") and not isRunning then
		isRunning = true; --DONT WANNA CLOG THE SYSTEM 
		if not initDone then
			mrInit();	
		end
		MorunoRank();
		isRunning = false;
	end	
end)
--EVENT LISTENER DONE
