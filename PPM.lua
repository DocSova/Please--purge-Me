PPM =
{
    name            = "PPM",
    SavedVariables  = nil,
    defaults        = {},
    plaguedMembers  = {},
    globalTimer     = 0
}

PPM.defaults  = {
    posx        = 0,
    posy        = 0,
	anchor      = 3,
    anchorRel   = 3
}

local function createUI()
    PPM.UI = WINDOW_MANAGER:CreateControl(nil, GuiRoot, CT_TOPLEVELCONTROL)
    PPM.UI:SetMouseEnabled(true)
    PPM.UI:SetClampedToScreen(true)
    PPM.UI:SetMovable(true)
    PPM.UI:SetDimensions(64, 92)
    PPM.UI:SetDrawLevel(0)
    PPM.UI:SetDrawLayer(DL_MAX_VALUE-1)
    PPM.UI:SetDrawTier(DT_MAX_VALUE-1)
    PPM.UI:SetHidden(false)

    PPM.UI:ClearAnchors()
    PPM.UI:SetAnchor(PPM.SavedVariables.anchorRel, GuiRoot, PPM.SavedVariables.anchor, PPM.SavedVariables.posx, PPM.SavedVariables.posy)

    PPM.UI.Icon = WINDOW_MANAGER:CreateControl(nil, PPM.UI, CT_TEXTURE)
    PPM.UI.Icon:SetBlendMode(TEX_BLEND_MODE_ALPHA)
    PPM.UI.Icon:SetTexture("PPM/textures/canPurge.dds")
    PPM.UI.Icon:SetDimensions(64, 64)
    PPM.UI.Icon:SetAnchor(TOPLEFT, PPM.UI, TOPLEFT, 0, 18)
    PPM.UI.Icon:SetHidden(false)
    PPM.UI.Icon:SetDrawLevel(0)

    PPM.UI:SetHandler("OnMoveStop", function()
        _, PPM.SavedVariables.anchorRel, _, PPM.SavedVariables.anchor, PPM.SavedVariables.posx, PPM.SavedVariables.posy, _ = PPM.UI:GetAnchor()
    end, PPM.name)

    PPM.fragment = ZO_HUDFadeSceneFragment:New(PPM.UI)
    HUD_SCENE:AddFragment(PPM.fragment)
    HUD_UI_SCENE:AddFragment(PPM.fragment)
    LOOT_SCENE:AddFragment(PPM.fragment)
end

function PPM.ShowBuffs()
   local unitTag = "player"
   local numBuffs = GetNumBuffs(unitTag)
   if numBuffs > 0 then
      for i = 1, numBuffs do
         local buffName, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
         d(zo_strformat("<<1>>. [<<2>>] <<C:3>>", i, abilityId, ZO_SELECTED_TEXT:Colorize(buffName)))
      end
   end
end

local function IsPlayerPlagued(unitTag)
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		for i = 1, numBuffs do
			local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo(unitTag, i)
			if (abilityId == 159612) then return true end
		end
	end
	return false
end

local function IsGroupPlagued()
	if (GetGroupSize() == 0) then return false end
	for i = 1, GetGroupSize() do
		local plaguePlayer = IsPlayerPlagued(zo_strformat("group<<1>>",i))
		if (plaguePlayer) then
			return true
		end
	end
	return false
end

local function savePlaguedPlayer(str)
    local found = false
    for _, value in pairs(PPM.plaguedMembers) do
        if value == str then
            found = true
            break
        end
    end
    
    if not found then
        table.insert(PPM.plaguedMembers, str)
    end
end

local function removePlaguedPlayer(str)
    for i, value in ipairs(PPM.plaguedMembers) do
        if value == str then
            table.remove(PPM.plaguedMembers, i)
            break
        end
    end
end

-- GetFrameTimeSeconds()
local function OnEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, unitName, unitId, abilityId, sourceUnitType)
    if ((unitTag ~= "") and (unitTag ~= "reticleover") and (unitTag ~= "reticleoverplayer") and (unitTag ~= "reticleovertarget"))and (abilityId == 159612) then
        d("Plague: endTime - "..endTime.." target - "..unitName.." sourceUnitType - "..sourceUnitType.." unittag - "..unitTag)
        if (changeType == EFFECT_RESULT_GAINED) then
            savePlaguedPlayer(unitName)
            PPM.globalTimer = endTime
        elseif (changeType == EFFECT_RESULT_FADED) then
            removePlaguedPlayer(unitName)
        end
    end
end

local function mainLoop()
	local texture = ""
    if (#PPM.plaguedMembers == 0) then PPM.globalTimer = 0 end
	if (PPM.globalTimer - GetFrameTimeSeconds()) > 0 then
		texture = "PPM/textures/cantPurge.dds"
	else
		texture = "PPM/textures/canPurge.dds"
	end
	 PPM.UI.Icon:SetTexture(texture)
	zo_callLater(function () mainLoop() end, 200)
end

local function onAddOnLoad(eventCode, addOnName)
    if (PPM.name ~= addOnName) then return end
    EVENT_MANAGER:UnregisterForEvent(PPM.name, EVENT_ADD_ON_LOADED)

    PPM.SavedVariables = ZO_SavedVars:NewAccountWide("PPMSV", 3, nil, PPM.defaults)
    EVENT_MANAGER:RegisterForEvent("PPM_EFFECT_CHANGED", EVENT_EFFECT_CHANGED, OnEffectChanged)
    createUI()
    mainLoop()
end

EVENT_MANAGER:RegisterForEvent(PPM.name, EVENT_ADD_ON_LOADED, function(...) onAddOnLoad(...) end)
