--[[
MorunoRankEnhanced - Original UI + CP math, with optional in-house Vanilla Ladder Math
Core logic by Martock; UI by Stretpaket. Ladder math additions (no dependencies).
IMPROVED: Automatic pool prediction + enhanced accuracy
]]

local isRunning = false;
local function isNAN(value) return value ~= value end
local initDone = false;
local chatReport = false
local lastBGZone = nil

--========================
-- Saved Vars & Defaults
--========================
MorunoRank_SV = MorunoRank_SV or {}

if MorunoRank_SV["hidden"]      == nil then MorunoRank_SV["hidden"]      = false end
if MorunoRank_SV["locked"]      == nil then MorunoRank_SV["locked"]      = false end
if MorunoRank_SV["point"]       == nil then MorunoRank_SV["point"]       = "CENTER" end
if MorunoRank_SV["relativePoint"]==nil then MorunoRank_SV["relativePoint"]= "CENTER" end
if MorunoRank_SV["x"]           == nil then MorunoRank_SV["x"]           = 0 end
if MorunoRank_SV["y"]           == nil then MorunoRank_SV["y"]           = 0 end
if MorunoRank_SV["turtleMode"]  == nil then MorunoRank_SV["turtleMode"]  = true end
if MorunoRank_SV["showBanners"] == nil then MorunoRank_SV["showBanners"] = false end
if MorunoRank_SV["cityCutoffHK"]== nil then MorunoRank_SV["cityCutoffHK"]= 0 end
if MorunoRank_SV["raceCutoffHK"]== nil then MorunoRank_SV["raceCutoffHK"]= 0 end
if MorunoRank_SV["race"]        == nil then MorunoRank_SV["race"]        = "" end
if MorunoRank_SV["ladderEnabled"] == nil then MorunoRank_SV["ladderEnabled"] = false end
if MorunoRank_SV["pool"]          == nil then MorunoRank_SV["pool"]          = 800 end
if MorunoRank_SV["standing"]      == nil then MorunoRank_SV["standing"]      = nil end
if MorunoRank_SV["autoPredict"]   == nil then MorunoRank_SV["autoPredict"]   = true end
if MorunoRank_SV["showScenarios"] == nil then MorunoRank_SV["showScenarios"] = false end
if MorunoRank_SV["estimateStanding"] == nil then MorunoRank_SV["estimateStanding"] = true end

--========================
-- Pool Prediction
--========================
local function MRE_EnsurePoolPredict()
  if not MorunoRank_SV then MorunoRank_SV = {} end
  if not MorunoRank_SV.poolPredict then
    MorunoRank_SV.poolPredict = {}
  end
  local pp = MorunoRank_SV.poolPredict
  if pp.alpha == nil then pp.alpha = 0.5 end
  if pp.coverage == nil then pp.coverage = 12 end
  if type(pp.hist) ~= "table" then pp.hist = {} end
  if type(pp.seen) ~= "table" then pp.seen = {} end
  if type(pp.bgSamples) ~= "table" then pp.bgSamples = {} end
  if pp.lastHK == nil then pp.lastHK = 0 end
  if pp.totalBGs == nil then pp.totalBGs = 0 end
  if pp.confidenceScore == nil then pp.confidenceScore = 0 end
  return pp
end

MorunoRank_SV.poolPredict = MorunoRank_SV.poolPredict or {
  alpha   = 0.5,
  coverage= 12,
  hist    = {},
  seen    = {},
  bgSamples = {},
  lastHK  = 0,
  totalBGs = 0,
  confidenceScore = 0,
}

local function MRE_CalculateConfidence()
  local pp = MRE_EnsurePoolPredict()
  local uniq = 0
  for _ in pairs(pp.seen) do uniq = uniq + 1 end

  local conf = 0

  if uniq >= 50 then conf = conf + 60
  elseif uniq >= 30 then conf = conf + 45
  elseif uniq >= 15 then conf = conf + 30
  elseif uniq >= 5 then conf = conf + 15
  end

  local numBGs = pp.totalBGs or 0
  if numBGs >= 10 then conf = conf + 20
  elseif numBGs >= 5 then conf = conf + 12
  elseif numBGs >= 2 then conf = conf + 6
  end

  local histSize = table.getn(pp.hist or {})
  if histSize >= 4 then conf = conf + 20
  elseif histSize >= 2 then conf = conf + 12
  elseif histSize >= 1 then conf = conf + 6
  end

  if conf > 100 then conf = 100 end
  pp.confidenceScore = conf
  return conf
end

local function MRE_PoolFromCut(bracket, cutoffStanding)
  bracket = tonumber(bracket or 0) or 0
  cutoffStanding = tonumber(cutoffStanding or 0) or 0
  if bracket < 1 or bracket > 14 or cutoffStanding <= 0 then return nil end
  local MRE_BR_PCTS = { 1.00, 0.85, 0.70, 0.55, 0.40, 0.30, 0.20, 0.15, 0.10, 0.06, 0.035, 0.02, 0.008, 0.003 }
  local p = MRE_BR_PCTS[bracket]
  if not p or p <= 0 then return nil end
  local est = math.floor((cutoffStanding / p) + 0.5)
  if est < 800 then est = 800 end
  return est
end

local function MRE_PoolEMA()
  local pp = MRE_EnsurePoolPredict()
  local uniq = 0
  for _ in pairs(pp.seen) do uniq = uniq + 1 end

  local sampleEst = uniq * (pp.coverage or 12)
  if sampleEst < 800 then sampleEst = 800 end

  local baseline = MorunoRank_SV.pool or 0
  if baseline <= 0 or baseline < 800 then
    local histSize = table.getn(pp.hist or {})
    if histSize > 0 then
      local sum, weight = 0, 0
      local i
      for i = 1, histSize do
        local w = i / histSize
        sum = sum + (pp.hist[i] * w)
        weight = weight + w
      end
      if weight > 0 then
        baseline = math.floor((sum / weight) + 0.5)
      end
    end
  end
  if baseline <= 0 then baseline = 800 end

  local a = pp.alpha or 0.5
  if a < 0 then a = 0 elseif a > 1 then a = 1 end

  local conf = MRE_CalculateConfidence()
  if conf < 30 then
    a = a * 0.6
  elseif conf > 70 then
    a = a * 1.2
    if a > 1 then a = 1 end
  end

  local est = math.floor(a * sampleEst + (1 - a) * baseline + 0.5)
  if est < 800 then est = 800 end

  if conf < 50 and baseline > 800 then
    local maxDeviation = baseline * 0.3
    if est > baseline + maxDeviation then
      est = math.floor(baseline + maxDeviation + 0.5)
    elseif est < baseline - maxDeviation then
      est = math.floor(baseline - maxDeviation + 0.5)
    end
  end

  return est, sampleEst, baseline, uniq, conf
end

local function MRE_PoolMaybeResetWeek()
  if type(GetPVPThisWeekStats) ~= "function" then return end
  local hk1 = GetPVPThisWeekStats()
  local hk = hk1 or 0
  local pp = MRE_EnsurePoolPredict()
  if hk < (pp.lastHK or 0) then
    local prevPool = MorunoRank_SV.pool or 0
    if prevPool > 0 then
      local n = table.getn(pp.hist)
      if n >= 6 then table.remove(pp.hist, 1) end
      table.insert(pp.hist, prevPool)
    end
    pp.seen = {}
    pp.bgSamples = {}
    pp.totalBGs = 0
    pp.confidenceScore = 0
  end
  pp.lastHK = hk
end

local function MRE_SampleBGScoreboard()
  if type(GetNumBattlefieldScores) ~= "function" or type(GetBattlefieldScore) ~= "function" then return end
  local myFaction = UnitFactionGroup and UnitFactionGroup("player") or nil
  if not myFaction then return end

  local pp = MRE_EnsurePoolPredict()
  local n = GetNumBattlefieldScores()
  if not n or n <= 0 then return end

  local facNumSelf = nil
  if myFaction == "Alliance" then facNumSelf = 0 else facNumSelf = 1 end

  local newSeen = 0
  local i
  for i = 1, n do
    local name, killingBlows, honorableKills, deaths, honorGained, faction = GetBattlefieldScore(i)
    local sameFaction = false
    if type(faction) == "number" then
      sameFaction = (faction == facNumSelf)
    elseif type(faction) == "string" then
      sameFaction = (faction == myFaction)
    end
    if sameFaction and name and name ~= "" then
      if not pp.seen[name] then
        newSeen = newSeen + 1
      end
      pp.seen[name] = true
    end
  end

  if newSeen > 0 then
    table.insert(pp.bgSamples, newSeen)
  end
end

local function MRE_AutoPredictPool(silent)
  if not MorunoRank_SV["autoPredict"] then return end

  MRE_EnsurePoolPredict()
  local est, sampleEst, baseline, uniq, conf = MRE_PoolEMA()

  if uniq >= 3 then
    local oldPool = MorunoRank_SV.pool or 800
    MorunoRank_SV.pool = est

    if not silent then
      local confText = ""
      if conf >= 70 then confText = "|cff00ff00High|r"
      elseif conf >= 40 then confText = "|cffffff00Medium|r"
      else confText = "|cffff5555Low|r" end

      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cff00ffffMRE|r Pool auto-predicted: %d (was %d) | Confidence: %s (%d%%) | %d unique names, %d BGs",
        est, oldPool, confText, conf, uniq, MorunoRank_SV.poolPredict.totalBGs or 0
      ))
    end
  end
end

local function MRE_CheckBGZone()
  local inInstance, instanceType = IsInInstance()
  local currentZone = nil

  if inInstance and instanceType == "pvp" then
    currentZone = "BG"
  end

  if lastBGZone == "BG" and currentZone ~= "BG" then
    local pp = MRE_EnsurePoolPredict()
    pp.totalBGs = (pp.totalBGs or 0) + 1
    MRE_AutoPredictPool(false)
  end

  lastBGZone = currentZone
end

--========================
-- RP Helper Functions
--========================
local function getCurrentRank(CurrentRP)
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
end

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
end

--========================
-- Ladder Math
--========================
local MRE_BR_PCTS = { 1.00, 0.85, 0.70, 0.55, 0.40, 0.30, 0.20, 0.15, 0.10, 0.06, 0.035, 0.02, 0.008, 0.003 }

local function MRE_BuildTopThresholds(pool)
  local t = {}
  local b
  for b = 1, 14 do
    local v = math.floor((MRE_BR_PCTS[b] * pool) + 0.5)
    if v < 1 then v = 1 end
    t[b] = v
  end
  return t
end

local function MRE_StandingToBracket(standing, pool)
  if not standing or not pool or standing < 1 or pool < 1 then return nil end

  local thr = MRE_BuildTopThresholds(pool)
  local b
  for b = 14, 2, -1 do
    if standing <= thr[b] then
      local best = (b == 14) and 1 or (thr[b + 1] + 1)
      local worst = thr[b]
      if worst < best then worst = best end
      local span = worst - best
      local inside = 1
      if span > 0 then
        inside = 1 - ((standing - best) / span)
      end
      if inside < 0 then inside = 0 elseif inside > 1 then inside = 1 end
      return b, inside, best, worst
    end
  end

  return 1, 0, (thr[2] + 1), pool
end

local function MRE_BaseRPForBracket(b)
  if b <= 1 then return 0 end
  if b == 2 then return 400 end
  return (b - 2) * 1000
end

local function MRE_AwardFromStanding(standing, pool)
  local b, inside = MRE_StandingToBracket(standing, pool)
  if not b then return nil end
  local base = MRE_BaseRPForBracket(b)
  local award = base + 1000 * (inside or 0)
  if award < 0 then award = 0 end
  if award > 13000 then award = 13000 end
  return award, b, inside
end

local function MRE_CurrentRP()
  local rank = UnitPVPRank("player") or 0
  local prog = 0
  if type(GetPVPRankProgress) == "function" then
    local p = GetPVPRankProgress("player"); if p then prog = p end
  end
  local rp = (rank - 6) * 5000 + math.floor(5000 * prog + 0.5)
  if rp < 0 then rp = 0 end
  return rp
end

local function MRE_RankFloorRP(currentRP)
  local r = math.floor(currentRP / 5000) * 5000
  if r < 0 then r = 0 end
  return r
end

local function MRE_MinHKRequired()
  return MorunoRank_SV["turtleMode"] and 1 or 15
end

local function MRE_EstimateNextRP(opts)
  opts = opts or {}
  local pool = opts.pool or MorunoRank_SV["pool"] or 800
  local standing = opts.standing or MorunoRank_SV["standing"]
  local currentRP = (opts.currentRP ~= nil) and opts.currentRP or MRE_CurrentRP()

  if not standing then
    return { ok=false, reason="NO_STANDING", currentRP=currentRP, pool=pool }
  end

  local hk = 0
  if type(GetPVPThisWeekStats) == "function" then
    local hk1 = GetPVPThisWeekStats()
    if hk1 then hk = hk1 end
  end

  local needHK = MRE_MinHKRequired()
  local award, bracket, inside = 0, nil, nil
  local hkGate = false

  if hk < needHK then
    hkGate = true
  else
    award, bracket, inside = MRE_AwardFromStanding(standing, pool)
    if not award then return { ok=false, reason="BAD_INPUT", currentRP=currentRP, pool=pool, standing=standing } end
  end

  local nextRP = math.floor(0.8 * currentRP + award + 0.5)

  local floorRP = MRE_RankFloorRP(currentRP)
  if nextRP < floorRP then nextRP = floorRP end

  return {
    ok=true, currentRP=currentRP, pool=pool, standing=standing,
    award=math.floor(award + 0.5), nextRP=nextRP, bracket=bracket, inside=inside,
    hkGate=hkGate, hk=hk
  }
end

local function MRE_EstimateStanding()
  if not MorunoRank_SV["standing"] or not MorunoRank_SV["pool"] then
    return nil
  end

  local lastStanding = MorunoRank_SV["standing"]
  local pool = MorunoRank_SV["pool"]

  local hk, cp = 0, 0
  if type(GetPVPThisWeekStats) == "function" then
    hk, cp = GetPVPThisWeekStats()
  end

  if cp < 1000 then
    return lastStanding, "last_week"
  end

  local avgCP = pool * 8000
  local poolAvg = avgCP / pool

  local myRelative = cp / poolAvg

  local estimatedStanding = lastStanding

  if myRelative > 1.5 then
    estimatedStanding = math.floor(lastStanding * 0.7)
  elseif myRelative > 1.2 then
    estimatedStanding = math.floor(lastStanding * 0.85)
  elseif myRelative < 0.5 then
    estimatedStanding = math.floor(lastStanding * 1.4)
  elseif myRelative < 0.8 then
    estimatedStanding = math.floor(lastStanding * 1.15)
  end

  if estimatedStanding < 1 then estimatedStanding = 1 end
  if estimatedStanding > pool then estimatedStanding = pool end

  return estimatedStanding, "estimated"
end

local function MRE_CalculateScenarios(currentRP)
  local pool = MorunoRank_SV["pool"] or 800
  local baseStanding = MorunoRank_SV["standing"]

  if not baseStanding then return nil end

  local scenarios = {}

  local r1 = MRE_EstimateNextRP({ currentRP = currentRP, standing = baseStanding, pool = pool })
  if r1.ok then
    scenarios.maintain = {
      standing = baseStanding,
      award = r1.award,
      nextRP = r1.nextRP,
      bracket = r1.bracket,
      inside = r1.inside,
      label = "Maintain"
    }
  end

  local betterStanding = math.floor(baseStanding * 0.85)
  if betterStanding < 1 then betterStanding = 1 end
  local r2 = MRE_EstimateNextRP({ currentRP = currentRP, standing = betterStanding, pool = pool })
  if r2.ok then
    scenarios.improve = {
      standing = betterStanding,
      award = r2.award,
      nextRP = r2.nextRP,
      bracket = r2.bracket,
      inside = r2.inside,
      label = "Improve 15%"
    }
  end

  local worseStanding = math.floor(baseStanding * 1.15)
  if worseStanding > pool then worseStanding = pool end
  local r3 = MRE_EstimateNextRP({ currentRP = currentRP, standing = worseStanding, pool = pool })
  if r3.ok then
    scenarios.worsen = {
      standing = worseStanding,
      award = r3.award,
      nextRP = r3.nextRP,
      bracket = r3.bracket,
      inside = r3.inside,
      label = "Worsen 15%"
    }
  end

  return scenarios
end

--========================
-- Frame & UI
--========================
local Frame = CreateFrame("Frame", "mreFrame", UIParent)
Frame:SetMovable(true)
Frame:EnableMouse(true)
Frame:RegisterForDrag("LeftButton")
if type(Frame.SetClampedToScreen) == "function" then
  Frame:SetClampedToScreen(true)
end
if type(Frame.SetUserPlaced) == "function" then
  Frame:SetUserPlaced(true)
end

local function MRE_CanDrag() return not (MorunoRank_SV and MorunoRank_SV["locked"]) end

Frame:SetScript("OnDragStart", function()
  if MRE_CanDrag() and (IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown()) then
    this:StartMoving()
  end
end)

Frame:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  if MorunoRank_SV then
    local point, _, relativePoint, x, y = this:GetPoint()
    MorunoRank_SV["point"] = point
    MorunoRank_SV["relativePoint"] = relativePoint
    MorunoRank_SV["x"] = x
    MorunoRank_SV["y"] = y
  end
end)

Frame:SetScript("OnHide", function() this:StopMovingOrSizing() end)

Frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
Frame:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
Frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
Frame:RegisterEvent("ADDON_LOADED")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
Frame:RegisterEvent("PLAYER_PVP_RANK_CHANGED")
Frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local backdrop = {
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = nil, tile = true, tileSize = 32, edgeSize = 0,
  insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

Frame:SetWidth(110)
Frame:SetHeight(110)
Frame:SetPoint('CENTER', UIParent, 'CENTER', 0,0)
Frame:SetFrameStrata('MEDIUM')
Frame:SetBackdrop(backdrop)
Frame:SetBackdropBorderColor(0, 0, 0, 0)
Frame:SetBackdropColor(1, 1, 1, 0.4)

local nextRankLabel = Frame:CreateFontString(nil, "ARTWORK", nil)
nextRankLabel:SetFontObject("GameFontNormalSmall")
nextRankLabel:SetPoint("TOP", Frame, "TOP", 0, -10)
nextRankLabel:SetTextColor(1,1,1);

local totalRPCalcLabel = Frame:CreateFontString(nil, "ARTWORK", nil)
totalRPCalcLabel:SetFontObject("GameFontNormalSmall")
totalRPCalcLabel:SetPoint("TOP", nextRankLabel, "BOTTOM", 0, -5)
totalRPCalcLabel:SetTextColor(1,1,1);
totalRPCalcLabel:SetText("Progress to Next Rank:");

-- NEW: CP display label
local cpLabel = Frame:CreateFontString(nil, "ARTWORK", nil)
cpLabel:SetFontObject("GameFontNormalSmall")
cpLabel:SetPoint("TOP", totalRPCalcLabel, "BOTTOM", 0, -2)
cpLabel:SetTextColor(0.8, 0.8, 1)
cpLabel:SetText("")

local statusBar2 = CreateFrame("StatusBar", nil, Frame)
statusBar2:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
statusBar2:SetMinMaxValues(0, 100)
statusBar2:SetValue(100)
statusBar2:SetWidth(100)
statusBar2:SetHeight(12)
statusBar2:SetPoint("TOP",cpLabel,"BOTTOM",0,-2)
statusBar2:SetBackdrop(backdrop)
statusBar2:SetBackdropColor(0,0,0,0.5);
statusBar2:SetStatusBarColor(0,0,1)

local statusBar2_Text = statusBar2:CreateFontString(nil, "ARTWORK", nil)
statusBar2_Text:SetFontObject("GameFontNormalSmall")
statusBar2_Text:SetPoint("CENTER", statusBar2, "CENTER",0,0)
statusBar2_Text:SetTextColor(1,1,1);

local text2 = Frame:CreateFontString(nil, "ARTWORK", nil)
text2:SetFontObject("GameFontNormalSmall")
text2:SetPoint("CENTER", Frame, "TOP", 0, 2)
text2:SetTextColor(1,0.4,0.7);
text2:SetText("MorunoRankEnhanced");

local methodTag = Frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
methodTag:SetPoint("TOP", statusBar2, "BOTTOM", 0, -3)
methodTag:SetTextColor(0.7, 0.7, 0.7)
methodTag:SetText("")

local cityLabel = Frame:CreateFontString(nil, "ARTWORK", nil)
cityLabel:SetFontObject("GameFontNormalSmall")
cityLabel:SetPoint("BOTTOM", Frame, "BOTTOM", 0, 2)
cityLabel:SetTextColor(0.9, 0.9, 0.3)

local raceLabel = Frame:CreateFontString(nil, "ARTWORK", nil)
raceLabel:SetFontObject("GameFontNormalSmall")
raceLabel:SetPoint("BOTTOM", cityLabel, "TOP", 0, 2)
raceLabel:SetTextColor(0.9, 0.9, 0.3)

local function MRE_SetBannerVisibility()
  if MorunoRank_SV and MorunoRank_SV["showBanners"] then
    if methodTag and methodTag.Show then methodTag:Show() end
    if cityLabel and cityLabel.Show then cityLabel:Show() end
    if raceLabel and raceLabel.Show then raceLabel:Show() end
  else
    if methodTag and methodTag.Hide then methodTag:Hide() end
    if cityLabel and cityLabel.Hide then cityLabel:Hide() end
    if raceLabel and raceLabel.Hide then raceLabel:Hide() end
  end
end

--========================
-- Main Calculation
--========================
local function MorunoRank()
  local PercentPVPRank = math.floor((GetPVPRankProgress("player") or 0) * 100);
  local UPVPRank = UnitPVPRank("player") or 0;
  local hk, CPLast = 0, 0
  if type(GetPVPThisWeekStats) == "function" then hk, CPLast = GetPVPThisWeekStats() end

  local RA = (UPVPRank - 6) * 5000 + 5000 * PercentPVPRank / 100;
  local NeededRPToNextRank = (UPVPRank - 5) * 5000 - RA * 0.8;
  local CurrentRank = getCurrentRank(RA);

  local CPup, CPlo, RPup, RPlo = 0,0,0,0
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

  local RB_cp = 0;
  if (CPup ~= CPlo) then
    RB_cp = (CPLast - CPlo) / (CPup - CPlo) * (RPup - RPlo) + RPlo;
  end

  local RC = 0.2 * RA;
  local rawEEarns_cp = math.floor(RA + RB_cp - RC);
  local floorRP = getCurrentHP(getCurrentRank(RA));
  local EEarns_cp = math.max(rawEEarns_cp, floorRP)
  local floorApplied_cp = (EEarns_cp > rawEEarns_cp);

  local ladderOK, RB_ladder, EEarns_ladder, floorApplied_ladder, bracket, inside = false, 0, 0, false, nil, nil
  if MorunoRank_SV["ladderEnabled"] and MorunoRank_SV["standing"] then
    local useStanding = MorunoRank_SV["standing"]
    local standingSource = "manual"

    if MorunoRank_SV["estimateStanding"] then
      local est, source = MRE_EstimateStanding()
      if est then
        useStanding = est
        standingSource = source
      end
    end

    local r = MRE_EstimateNextRP({ currentRP = RA, standing = useStanding })
    if r.ok then
      ladderOK = true
      RB_ladder = r.award or 0
      EEarns_ladder = r.nextRP or RA
      bracket, inside = r.bracket, r.inside
      local floorRP2 = MRE_RankFloorRP(RA)
      floorApplied_ladder = (EEarns_ladder < floorRP2)
    end
  end

  local usingLadder = ladderOK and MorunoRank_SV["ladderEnabled"]
  local RB = usingLadder and RB_ladder or RB_cp
  local EEarns = usingLadder and EEarns_ladder or EEarns_cp
  local floorApplied = usingLadder and floorApplied_ladder or floorApplied_cp

  local EarnedRank = getCurrentRank(EEarns);
  local nextRankMin = getCurrentHP(EarnedRank + 1);
  local thisRankMin = getCurrentHP(EarnedRank);
  local denom = (nextRankMin - thisRankMin);
  local PercentNextPVPRank = 0;
  if denom and denom > 0 then
    PercentNextPVPRank = math.floor(((EEarns - thisRankMin) * 100) / denom);
  end
  if PercentNextPVPRank < 0 then PercentNextPVPRank = 0 end
  if PercentNextPVPRank > 100 then PercentNextPVPRank = 100 end

  if MorunoRank_SV["showBanners"] then
    methodTag:SetText(usingLadder and "calc: Ladder" or "")
    if methodTag.Show then methodTag:Show() end
  else
    methodTag:SetText("")
    if methodTag.Hide then methodTag:Hide() end
  end

  -- NEW: Show estimated standing info when using ladder mode
  if usingLadder and MorunoRank_SV["estimateStanding"] then
    local est, source = MRE_EstimateStanding()
    if est and source == "estimated" then
      if MorunoRank_SV["showBanners"] then
        methodTag:SetText("calc: Ladder (est standing: "..est..")")
      end
    end
  end

  if isNAN(PercentNextPVPRank) or not denom or denom == 0 then
    nextRankLabel:SetText("Next week: Unknown");
    totalRPCalcLabel:SetText("Do some PVP!");
    cpLabel:SetText("CP: " .. CPLast)
    statusBar2:SetValue(0);
    if chatReport then
      DEFAULT_CHAT_FRAME:AddMessage("Current RP: "..RA.." at "..PercentPVPRank.."% (Rank "..CurrentRank..") RP To Next Rank: "..NeededRPToNextRank.." This Week RP gained:"..math.floor(RB).." @ Total RP Calc: "..EEarns.." at "..PercentNextPVPRank.."%(Rank "..EarnedRank..")", 1, 1, 0);
      chatReport = false;
    end
  else
    if chatReport then
      local floorNote = floorApplied and " [Floor Applied]" or ""
      local modeNote = usingLadder and " [Ladder]" or " [CP]"
      DEFAULT_CHAT_FRAME:AddMessage("Current RP: "..RA.." at "..PercentPVPRank.."% (Rank "..CurrentRank..") RP To Next Rank: "..NeededRPToNextRank.." This Week RP gained:"..math.floor(RB).." @ Total RP Calc: "..EEarns.." at "..PercentNextPVPRank.."%(Rank "..EarnedRank..")"..floorNote..modeNote, 1, 1, 0);
      chatReport = false;
    end

    local nextMin_forNextRank = getCurrentHP(CurrentRank + 1)
    local weeklyNeededTotal = 0
    if nextMin_forNextRank then
      weeklyNeededTotal = math.max(0, nextMin_forNextRank - (RA - RC))
    end

    local rankChangeText = ""
    if EarnedRank > CurrentRank then
      rankChangeText = " (→ Rank " .. EarnedRank .. ")"
    elseif EarnedRank < CurrentRank then
      rankChangeText = " (↓ Rank " .. EarnedRank .. ")"
    else
      rankChangeText = " (= Rank " .. EarnedRank .. ")"
    end

    local floorTag = floorApplied and " [floored]" or ""
    nextRankLabel:SetText("Next week: " .. PercentNextPVPRank .. "%" .. rankChangeText .. floorTag)

    local weeklyPercent = 0
    if weeklyNeededTotal > 0 then
      weeklyPercent = math.floor((math.max(0, RB) / weeklyNeededTotal) * 100)
      if weeklyPercent > 100 then weeklyPercent = 100 end
    else
      weeklyPercent = 100
    end

    totalRPCalcLabel:SetText("Progress to Rank " .. (CurrentRank + 1) .. ":")

    -- NEW: Format CP with commas for readability
    local cpFormatted = tostring(CPLast)
    if CPLast >= 1000 then
      cpFormatted = string.gsub(cpFormatted, "(%d)(%d%d%d)$", "%1,%2")
      if CPLast >= 1000000 then
        cpFormatted = string.gsub(cpFormatted, "(%d)(%d%d%d),", "%1,%2,")
      end
    end
    cpLabel:SetText("This week CP: " .. cpFormatted)

    statusBar2:SetValue(weeklyPercent)
    statusBar2_Text:SetText(math.floor(RB) .. "/" .. weeklyNeededTotal .. " RP (" .. weeklyPercent .. "%)")
  end

  if MorunoRank_SV["showBanners"] then
    cityLabel:Show(); raceLabel:Show()
    local cutoff = MorunoRank_SV["cityCutoffHK"] or 0
    local raceCut = MorunoRank_SV["raceCutoffHK"] or 0
    local myRace  = MorunoRank_SV["race"] or "race?"
    if cutoff > 0 then
      if hk and hk >= cutoff then cityLabel:SetText("City Protector: Eligible (est.)")
      else cityLabel:SetText("City Protector: Needs +".. math.max(cutoff - (hk or 0),0) .." HK") end
    else cityLabel:SetText("City Protector: set /mre citycutoff <HK>") end
    if raceCut > 0 then
      if hk and hk >= raceCut then raceLabel:SetText("Top "..myRace..": Eligible (est.)")
      else raceLabel:SetText("Top "..myRace..": Needs +".. math.max(raceCut - (hk or 0),0) .." HK") end
    else raceLabel:SetText("Top-of-race title: /mre race <n>, /mre racecutoff <HK>") end
  else
    cityLabel:SetText(""); cityLabel:Hide()
    raceLabel:SetText(""); raceLabel:Hide()
  end
  if type(MRE_SetBannerVisibility) == "function" then
    MRE_SetBannerVisibility()
  end
end

--========================
-- Init
--========================
local function mrInit()
  Frame:UnregisterEvent("ADDON_LOADED")
  Frame:SetPoint(MorunoRank_SV["point"], nil, MorunoRank_SV["relativePoint"], MorunoRank_SV["x"], MorunoRank_SV["y"]);
  if MorunoRank_SV["hidden"] then Frame:Hide() else Frame:Show() end
  Frame:EnableMouse(not MorunoRank_SV["locked"])
  Frame:SetMovable(not MorunoRank_SV["locked"])

  DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced loaded with UI by Stretpaket",1,0.4,0.7);
  if MorunoRank_SV["hidden"] then
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is hidden. \"/mre show\" or \"/mre s\" to show.",1,0.4,0.7);
  else
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is shown \"/mre hide\" or \"/mre h\" to hide.",1,0.4,0.7);
  end
  if MorunoRank_SV["locked"] then
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is locked. \"/mre unlock\" or \"/mre u\" to unlock.",1,0.4,0.7);
  else
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is unlocked \"/mre lock\" or \"/mre l\" to lock.",1,0.4,0.7);
  end

  if MorunoRank_SV["autoPredict"] then
    DEFAULT_CHAT_FRAME:AddMessage("Pool auto-prediction: |cff00ff00ON|r (runs after each BG)",1,0.4,0.7);
  else
    DEFAULT_CHAT_FRAME:AddMessage("Pool auto-prediction: |cffff5555OFF|r (/mre autopredict on to enable)",1,0.4,0.7);
  end

  initDone = true
  MRE_EnsurePoolPredict()
  MRE_SetBannerVisibility()
  MRE_AutoPredictPool(true)
end

--========================
-- Slash Commands
--========================
local function SlashCmd(msg)
  if not msg or msg == "" then
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced(UI by Stretpaket)",1,0.4,0.7);
    DEFAULT_CHAT_FRAME:AddMessage("Help:");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre show\" or \"/mre s\" to show.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre hide\" or \"/mre h\" to hide.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre lock\" or \"/mre l\" to lock.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre unlock\" or \"/mre u\" to unlock.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre report\" or \"/mre r\" to see full MorunoRank report.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre reset\" to reset the window placement.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre turtle on|off\" – apply RP floor (DEFAULT: ON).");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre banners on|off\" – toggle City/Race AND 'calc: Ladder' tag visibility.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre citycutoff <HK>\", \"/mre race <n>\", \"/mre racecutoff <HK>\".");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre ladder on|off\" – use Ladder (standing/pool) instead of CP.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre pool <N>\", \"/mre standing <S>\", \"/mre calc\" for ladder math.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre pool predict\" – predict pool from BG sampler + EMA.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre autopredict on|off\" – toggle auto-prediction after BGs (DEFAULT: ON).");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre pool alpha <0..1>\", \"/mre pool coverage <K>\", \"/mre pool fromcut <br> <standing>\".");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre pool status\" – show current pool prediction confidence.");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre scenarios\" – show best/worst case rank predictions (ladder mode).");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre estimate on|off\" – toggle standing estimation (DEFAULT: ON).");
    DEFAULT_CHAT_FRAME:AddMessage("\"/mre standing status\" – show current/estimated standing.");
    return
  end

  if msg == "hide" or msg == "h" then
    Frame:Hide(); MorunoRank_SV["hidden"] = true;
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is hidden. \"/mre show\" or \"/mre s\" to show.",1,0,0);

  elseif msg == "show" or msg=="s" then
    Frame:Show(); MorunoRank_SV["hidden"] = false;
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is shown \"/mre hide\" or \"/mre h\" to hide.",0,1,0);

  elseif msg == "lock" or msg == "l" then
    MorunoRank_SV["locked"] = true; Frame:EnableMouse(false); Frame:SetMovable(false)
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is locked. \"/mre unlock\" or \"/mre u\" to unlock.",1,0,0);

  elseif msg == "unlock" or msg == "u" then
    MorunoRank_SV["locked"] = false; Frame:EnableMouse(true); Frame:SetMovable(true)
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced is unlocked \"/mre lock\" or \"/mre l\" to lock.",0,1,0);

  elseif msg == "help" then
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced(UI by Stretpaket)",1,0.4,0.7);
    DEFAULT_CHAT_FRAME:AddMessage("See /mre for commands.");

  elseif msg == "report" or msg == "r" then
    chatReport = true; MorunoRank();

  elseif msg == "reset" then
    Frame:ClearAllPoints()
    MorunoRank_SV["y"] = 0; MorunoRank_SV["x"] = 0
    MorunoRank_SV["point"] = "CENTER"; MorunoRank_SV["relativePoint"] = "CENTER"
    MorunoRank_SV["locked"] = false; MorunoRank_SV["hidden"] = false
    Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    Frame:Show(); Frame:EnableMouse(true); Frame:SetMovable(true)
    cityLabel:SetText(""); cityLabel:Hide(); raceLabel:SetText(""); raceLabel:Hide()
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced was reset to original settings (centered).")
    MorunoRank()

  elseif string.find(msg, "^turtle%s") == 1 then
    local _, _, arg = string.find(msg, "^turtle%s+(%S+)")
    if arg == "on" then
      MorunoRank_SV["turtleMode"] = true
      DEFAULT_CHAT_FRAME:AddMessage("Turtle Mode: ON (RP never drops below rank floor, 1 HK minimum).")
    elseif arg == "off" then
      MorunoRank_SV["turtleMode"] = false
      DEFAULT_CHAT_FRAME:AddMessage("Turtle Mode: OFF (RP never drops below rank floor, 15 HK minimum).")
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre turtle on|off")
    end

  elseif string.find(msg, "^citycutoff%s") == 1 then
    local _, _, nstr = string.find(msg, "^citycutoff%s+(%d+)$")
    local n = tonumber(nstr or "")
    if n then MorunoRank_SV["cityCutoffHK"] = n; DEFAULT_CHAT_FRAME:AddMessage("City Protector cutoff set to "..n.." HK.")
    else DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre citycutoff <HK>") end

  elseif string.find(msg, "^racecutoff%s") == 1 then
    local _, _, nstr = string.find(msg, "^racecutoff%s+(%d+)$")
    local n = tonumber(nstr or "")
    if n then MorunoRank_SV["raceCutoffHK"] = n; DEFAULT_CHAT_FRAME:AddMessage("Race Leader cutoff set to "..n.." HK.")
    else DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre racecutoff <HK>") end

  elseif string.find(msg, "^race%s+") == 1 then
    local _, _, r = string.find(msg, "^race%s+(.+)$")
    if r then r = string.gsub(r, "^%s*(.-)%s*$", "%1"); MorunoRank_SV["race"] = r; DEFAULT_CHAT_FRAME:AddMessage("Your race set to: " .. r .. ".")
    else DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre race <yourRaceName>") end

  elseif string.find(msg, "^ladder%s") == 1 then
    local _, _, arg = string.find(msg, "^ladder%s+(%S+)")
    if arg == "on" then
      MorunoRank_SV["ladderEnabled"] = true
      DEFAULT_CHAT_FRAME:AddMessage("MRE: Ladder math ON (standing/pool).")
    elseif arg == "off" then
      MorunoRank_SV["ladderEnabled"] = false
      DEFAULT_CHAT_FRAME:AddMessage("MRE: Ladder math OFF (CP interpolation).")
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre ladder on|off")
    end
    MorunoRank()

  elseif string.find(msg, "^autopredict%s") == 1 then
    local _, _, arg = string.find(msg, "^autopredict%s+(%S+)")
    if arg == "on" then
      MorunoRank_SV["autoPredict"] = true
      DEFAULT_CHAT_FRAME:AddMessage("MRE: Pool auto-prediction |cff00ff00ON|r (will run after each BG)")
    elseif arg == "off" then
      MorunoRank_SV["autoPredict"] = false
      DEFAULT_CHAT_FRAME:AddMessage("MRE: Pool auto-prediction |cffff5555OFF|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre autopredict on|off")
    end

  elseif msg == "pool predict" then
    MRE_EnsurePoolPredict()
    local est, sampleEst, baseline, uniq, conf = MRE_PoolEMA()
    MorunoRank_SV.pool = est

    local confText = ""
    if conf >= 70 then confText = "|cff00ff00High|r"
    elseif conf >= 40 then confText = "|cffffff00Medium|r"
    else confText = "|cffff5555Low|r" end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(
      "|cff00ffffMRE|r Pool predicted: %d | Confidence: %s (%d%%)",
      est, confText, conf
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
      "  Sample≈%d from %d names, %d BGs | Baseline=%d | alpha=%.2f, coverage=%d",
      sampleEst, uniq, MorunoRank_SV.poolPredict.totalBGs or 0, baseline,
      MorunoRank_SV.poolPredict.alpha or 0.5, MorunoRank_SV.poolPredict.coverage or 12
    ))
    MorunoRank()

  elseif msg == "pool status" then
    MRE_EnsurePoolPredict()
    local pp = MorunoRank_SV.poolPredict
    local uniq = 0
    for _ in pairs(pp.seen) do uniq = uniq + 1 end
    local conf = MRE_CalculateConfidence()

    local confText = ""
    if conf >= 70 then confText = "|cff00ff00High|r"
    elseif conf >= 40 then confText = "|cffffff00Medium|r"
    else confText = "|cffff5555Low|r" end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffMRE Pool Prediction Status:|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Current pool: %d", MorunoRank_SV.pool or 800))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Confidence: %s (%d%%)", confText, conf))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Unique names seen: %d", uniq))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  BGs completed: %d", pp.totalBGs or 0))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Historical pools: %d weeks", table.getn(pp.hist or {})))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Settings: alpha=%.2f, coverage=%d", pp.alpha or 0.5, pp.coverage or 12))

  elseif string.find(msg, "^pool%s+alpha%s") == 1 then
    MRE_EnsurePoolPredict()
    local _, _, a = string.find(msg, "^pool%s+alpha%s+(%d*%.?%d+)")
    local val = tonumber(a or "")
    if val and val >= 0 and val <= 1 then
      MorunoRank_SV.poolPredict.alpha = val
      DEFAULT_CHAT_FRAME:AddMessage(string.format("MRE: pool EMA alpha set to %.2f", val))
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre pool alpha <0..1>")
    end

  elseif string.find(msg, "^pool%s+coverage%s") == 1 then
    MRE_EnsurePoolPredict()
    local _, _, k = string.find(msg, "^pool%s+coverage%s+(%d+)")
    local val = tonumber(k or "")
    if val and val >= 1 and val <= 100 then
      MorunoRank_SV.poolPredict.coverage = val
      DEFAULT_CHAT_FRAME:AddMessage("MRE: pool coverage factor set to "..val.." (each seen ≈ "..val..")")
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre pool coverage <1..100>")
    end

  elseif string.find(msg, "^pool%s+fromcut%s") == 1 then
    MRE_EnsurePoolPredict()
    local _, _, br, cut = string.find(msg, "^pool%s+fromcut%s+(%d+)%s+(%d+)")
    local p = MRE_PoolFromCut(br, cut)
    if p then
      MorunoRank_SV.pool = p
      DEFAULT_CHAT_FRAME:AddMessage(string.format("MRE: pool set from cutoff (Br%s=%s) => %d", br, cut, p))
      MorunoRank()
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre pool fromcut <bracket 1..14> <cutoff standing>")
    end

  elseif string.find(msg, "^pool%s+(%d+)") == 1 then
    local _, _, n = string.find(msg, "^pool%s+(%d+)")
    if n then
      MorunoRank_SV["pool"] = tonumber(n)
      DEFAULT_CHAT_FRAME:AddMessage("MRE: pool set to "..MorunoRank_SV["pool"])
      MorunoRank()
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre pool <number>")
    end

  elseif string.find(msg, "^standing%s") == 1 then
    -- Check for "standing status" first
    if msg == "standing status" then
      if not MorunoRank_SV["standing"] then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00MRE: No standing set. Use /mre standing <number> to set it.|r")
        return
      end

      local baseStanding = MorunoRank_SV["standing"]
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffMRE Standing Status:|r")
      DEFAULT_CHAT_FRAME:AddMessage(string.format("  Base standing (last week): %d", baseStanding))

      if MorunoRank_SV["estimateStanding"] then
        local est, source = MRE_EstimateStanding()
        if est then
          if source == "estimated" then
            local hk, cp = 0, 0
            if type(GetPVPThisWeekStats) == "function" then
              hk, cp = GetPVPThisWeekStats()
            end

            local change = est - baseStanding
            local changeText = ""
            if change < 0 then
              changeText = string.format("|cff00ff00%d (improving)|r", change)
            elseif change > 0 then
              changeText = string.format("|cffff5555+%d (falling)|r", change)
            else
              changeText = "|cffffff000 (maintaining)|r"
            end

            DEFAULT_CHAT_FRAME:AddMessage(string.format("  Estimated standing: %d (change: %s)", est, changeText))
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  This week's CP: %d", cp))
            DEFAULT_CHAT_FRAME:AddMessage("  Note: Estimation based on this week's honor vs pool average")
          else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  Using base standing: %d (early in week, <1000 CP)", est))
          end
        else
          DEFAULT_CHAT_FRAME:AddMessage("  Estimation: Not available (need pool set)")
        end
      else
        DEFAULT_CHAT_FRAME:AddMessage("  Estimation: |cffff5555OFF|r (using base standing)")
        DEFAULT_CHAT_FRAME:AddMessage("  Use /mre estimate on to enable automatic adjustment")
      end
    else
      -- Original standing set command
      local _, _, s = string.find(msg, "^standing%s+(%d+)")
      if s then
        MorunoRank_SV["standing"] = tonumber(s)
        DEFAULT_CHAT_FRAME:AddMessage("MRE: standing set to "..MorunoRank_SV["standing"])
        MorunoRank()
      else
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre standing <number>  or  /mre standing status")
      end
    end

  elseif msg == "calc" then
    local r = MRE_EstimateNextRP()
    if not r.ok then
      if r.reason == "NO_STANDING" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00MRE: set your standing with /mre standing <S> and pool with /mre pool <N>.|r")
      else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555MRE calc failed: "..tostring(r.reason).."|r")
      end
      return
    end
    local pct = r.inside and (math.floor(r.inside*100+0.5).."%") or "?"
    local hkNote = r.hkGate and " (HK gate not met: award=0)" or ""
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffffMRE|r pool=%d standing=%d bracket=%s (%s) award=%d nextRP=%d%s",
      r.pool or 0, r.standing or -1, r.bracket or 0, pct, r.award or 0, r.nextRP or 0, hkNote))

  elseif msg == "scenarios" then
    if not MorunoRank_SV["ladderEnabled"] then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00MRE: Enable ladder mode first with /mre ladder on|r")
      return
    end
    if not MorunoRank_SV["standing"] then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00MRE: Set your standing first with /mre standing <S>|r")
      return
    end

    local RA = (UnitPVPRank("player") - 6) * 5000 + 5000 * math.floor((GetPVPRankProgress("player") or 0) * 100) / 100

    -- Use the same standing that the main display uses
    local baseStanding = MorunoRank_SV["standing"]
    local displayStanding = baseStanding

    if MorunoRank_SV["estimateStanding"] then
      local est, source = MRE_EstimateStanding()
      if est and source == "estimated" then
        displayStanding = est
      end
    end

    local scenarios = MRE_CalculateScenarios(RA)

    if not scenarios then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff5555MRE: Could not calculate scenarios|r")
      return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffMRE Rank Scenarios:|r (pool="..MorunoRank_SV["pool"]..")")

    -- Show what standing is being used
    if MorunoRank_SV["estimateStanding"] and displayStanding ~= baseStanding then
      DEFAULT_CHAT_FRAME:AddMessage(string.format("  Base standing: %d | Estimated: %d (using estimated)", baseStanding, displayStanding))
    else
      DEFAULT_CHAT_FRAME:AddMessage(string.format("  Using standing: %d", displayStanding))
    end

    -- Calculate scenarios based on the ESTIMATED standing (what's actually being used)
    local scenariosFromEstimated = {}

    -- Maintain estimated
    local r1 = MRE_EstimateNextRP({ currentRP = RA, standing = displayStanding, pool = MorunoRank_SV["pool"] })
    if r1.ok then
      scenariosFromEstimated.maintain = {
        standing = displayStanding,
        award = r1.award,
        nextRP = r1.nextRP,
        bracket = r1.bracket,
        inside = r1.inside,
        label = "Maintain current"
      }
    end

    -- Improve 15%
    local betterStanding = math.floor(displayStanding * 0.85)
    if betterStanding < 1 then betterStanding = 1 end
    local r2 = MRE_EstimateNextRP({ currentRP = RA, standing = betterStanding, pool = MorunoRank_SV["pool"] })
    if r2.ok then
      scenariosFromEstimated.improve = {
        standing = betterStanding,
        award = r2.award,
        nextRP = r2.nextRP,
        bracket = r2.bracket,
        inside = r2.inside,
        label = "Improve 15%"
      }
    end

    -- Worsen 15%
    local worseStanding = math.floor(displayStanding * 1.15)
    if worseStanding > MorunoRank_SV["pool"] then worseStanding = MorunoRank_SV["pool"] end
    local r3 = MRE_EstimateNextRP({ currentRP = RA, standing = worseStanding, pool = MorunoRank_SV["pool"] })
    if r3.ok then
      scenariosFromEstimated.worsen = {
        standing = worseStanding,
        award = r3.award,
        nextRP = r3.nextRP,
        bracket = r3.bracket,
        inside = r3.inside,
        label = "Worsen 15%"
      }
    end

    if scenariosFromEstimated.improve then
      local s = scenariosFromEstimated.improve
      local nextRank = getCurrentRank(s.nextRP)
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cff00ff00%s|r: Standing %d → Br%d, award %d RP → Rank %d",
        s.label, s.standing, s.bracket or 0, s.award, nextRank
      ))
    end

    if scenariosFromEstimated.maintain then
      local s = scenariosFromEstimated.maintain
      local nextRank = getCurrentRank(s.nextRP)
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cffffff00%s|r: Standing %d → Br%d, award %d RP → Rank %d",
        s.label, s.standing, s.bracket or 0, s.award, nextRank
      ))
    end

    if scenariosFromEstimated.worsen then
      local s = scenariosFromEstimated.worsen
      local nextRank = getCurrentRank(s.nextRP)
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  |cffff5555%s|r: Standing %d → Br%d, award %d RP → Rank %d",
        s.label, s.standing, s.bracket or 0, s.award, nextRank
      ))
    end

  elseif string.find(msg, "^estimate%s") == 1 then
    local _, _, arg = string.find(msg, "^estimate%s+(%S+)")
    if arg == "on" then
      MorunoRank_SV["estimateStanding"] = true
      DEFAULT_CHAT_FRAME:AddMessage("MRE: Standing estimation |cff00ff00ON|r (adjusts based on this week's honor)")
      MorunoRank()
    elseif arg == "off" then
      MorunoRank_SV["estimateStanding"] = false
      DEFAULT_CHAT_FRAME:AddMessage("MRE: Standing estimation |cffff5555OFF|r (uses exact standing value)")
      MorunoRank()
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre estimate on|off")
    end

  elseif string.find(msg, "^banners%s") == 1 then
    local _, _, arg = string.find(msg, "^banners%s+(%S+)")
    if arg == "on" then
      MorunoRank_SV["showBanners"] = true
      DEFAULT_CHAT_FRAME:AddMessage("MRE: banners ON (showing City/Race and calc tag).")
    elseif arg == "off" then
      MorunoRank_SV["showBanners"] = false
      DEFAULT_CHAT_FRAME:AddMessage("MRE: banners OFF (hiding City/Race and calc tag).")
    else
      DEFAULT_CHAT_FRAME:AddMessage("Usage: /mre banners on|off")
    end
    MRE_SetBannerVisibility()
    MorunoRank()
  else
    DEFAULT_CHAT_FRAME:AddMessage("MorunoRankEnhanced(UI by Stretpaket)",1,0.4,0.7);
    DEFAULT_CHAT_FRAME:AddMessage("Use /mre for the full list of commands.")
  end
end

SLASH_MRE1 = '/mre';
SLASH_MRE2 = '/MorunoRankEnhanced';
SlashCmdList["MRE"] = SlashCmd;

--========================
-- Event Listener
--========================
Frame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if not initDone and arg1 == "MorunoRankEnhanced" then
      mrInit()
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    if not initDone then mrInit() end
    MRE_PoolMaybeResetWeek()
    MorunoRank()

  elseif event == "ZONE_CHANGED_NEW_AREA" then
    MRE_CheckBGZone()

  elseif event == "UPDATE_BATTLEFIELD_SCORE" then
    MRE_SampleBGScoreboard()

  elseif event == "PLAYER_PVP_RANK_CHANGED" then
    MRE_PoolMaybeResetWeek()
    MorunoRank()

  elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN"
      or event == "PLAYER_PVP_KILLS_CHANGED"
      or event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then

    MRE_PoolMaybeResetWeek()
    if not isRunning then
      isRunning = true
      MorunoRank()
      isRunning = false
    end
  end
end)
