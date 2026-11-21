-- Added by the unofficial HCDeaths GUI fork (2026-11-20).
-- Distributed under the MIT License; see LICENSE.

-- WoW 1.12 / Lua 5.0 settings and standalone minimap launcher.
local addon=HCDeaths_API
if not addon then return end
local window=CreateFrame("Frame","HCDeathsConfig",UIParent)
window:Hide();window:SetWidth(530);window:SetHeight(465)
window:SetPoint("CENTER",UIParent,"CENTER",0,0)
window:SetFrameStrata("DIALOG");window:SetMovable(true);window:SetClampedToScreen(true)
window:EnableMouse(true);window:RegisterForDrag("LeftButton")
window:SetScript("OnDragStart",function() this:StartMoving() end)
window:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
window:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4}})
window:SetBackdropColor(0.04,0.04,0.04,0.97)
local title=window:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
title:SetPoint("TOP",window,"TOP",0,-17);title:SetText("HCDeaths Settings - Octo WoW")
local close=CreateFrame("Button",nil,window,"UIPanelCloseButton")
close:SetPoint("TOPRIGHT",window,"TOPRIGHT",0,0)
local controls={}
local function label(text,x,y,font)
    local f=window:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",window,"TOPLEFT",x,y);f:SetText(text)
    return f
end
label("Changes apply immediately. Recorded deaths are kept when the log is hidden.",20,-47)
local function checkbox(key,text,x,y)
    local c=CreateFrame("CheckButton","HCDeathsOption_"..key,window,"UICheckButtonTemplate")
    c:SetWidth(24);c:SetHeight(24);c:SetPoint("TOPLEFT",window,"TOPLEFT",x,y)
    getglobal(c:GetName().."Text"):SetText(text)
    c.command=key
    c:SetScript("OnClick",function() addon:RunCommand(this.command,true) end)
    controls[key]=c
end
checkbox("message","System death messages",20,-75)
checkbox("log","Show death log",280,-75)
checkbox("toast","Death toast popups",20,-108)
checkbox("progress","Level progress toasts",280,-108)
checkbox("color","Toast ring colors",20,-141)
checkbox("deathsound","Death sounds",280,-141)
checkbox("levelsound","Level-up sounds",20,-174)
checkbox("roar","Death roar instead of alert",280,-174)
local fields={}
local function button(text,x,y,width,callback)
    local b=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
    b:SetWidth(width);b:SetHeight(25);b:SetPoint("TOPLEFT",window,"TOPLEFT",x,y)
    b:SetText(text);b:SetScript("OnClick",callback);return b
end
local function numeric(key,text,command,y)
    label(text,26,y-5,"GameFontNormal")
    -- Separate backdrop keeps all fields consistent on the 1.12 client,
    -- independently of InputBoxTemplate textures and UI replacements.
    local box=CreateFrame("Frame","HCDeathsNumeric_"..key,window)
    box:SetWidth(82);box:SetHeight(24)
    box:SetPoint("TOPLEFT",window,"TOPLEFT",270,y)
    box:SetBackdrop({bgFile="Interface\\Buttons\\White8x8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,
        edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    box:SetBackdropColor(0,0,0,1)
    box:SetBackdropBorderColor(0.65,0.65,0.65,1)
    local e=CreateFrame("EditBox","HCDeathsNumericInput_"..key,box)
    e:SetWidth(66);e:SetHeight(20);e:SetPoint("CENTER",box,"CENTER",0,0)
    e:SetFontObject("GameFontHighlightSmall");e:SetTextColor(1,1,1)
    e:SetJustifyH("LEFT");e:SetTextInsets(0,0,0,0)
    e:SetAutoFocus(false);e:SetMaxLetters(12)
    e:SetScript("OnEscapePressed",function() this:ClearFocus();addon:RefreshGUI() end)
    local function apply()
        addon:RunCommand(command.." "..e:GetText(),true);e:ClearFocus()
    end
    e:SetScript("OnEnterPressed",apply)
    button("Apply",365,y,135,apply)
    fields[key]=e
end
numeric("logscale","Log scale (0.25 - 3)","log scale",-224)
numeric("toastscale","Toast scale (0.25 - 3)","toast scale",-261)
numeric("toasttime","Toast seconds (0 < n <= 300)","toast time",-298)
button("Show / hide movable toast",20,-346,240,function() addon:RunCommand("move",true) end)
button("Reset settings / positions",280,-346,230,function() addon:RunCommand("reset",true) end)
local help=button("Command help (hover)",20,-387,240,function() end)
help:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
    GameTooltip:SetText("HCDeaths commands")
    GameTooltip:AddLine("/hcd - Settings",1,1,1)
    GameTooltip:AddLine("/hcd message | move | log | toast | progress",1,1,1)
    GameTooltip:AddLine("/hcd color | deathsound | levelsound | roar | reset",1,1,1)
    GameTooltip:AddLine("/hcd log scale number",1,1,1)
    GameTooltip:AddLine("/hcd toast scale number | toast time seconds",1,1,1)
    GameTooltip:Show()
end)
help:SetScript("OnLeave",function() GameTooltip:Hide() end)
button("Close",280,-387,230,function() window:Hide() end)
label("Log: 20 entries per page, newest first. Minimap: left = settings, right = log.",20,-435)

function addon:RefreshGUI()
    for key,c in pairs(controls) do c:SetChecked(HCDeaths_Settings[key]) end
    for key,e in pairs(fields) do e:SetText(tostring(HCDeaths_Settings[key])) end
end
function addon:ToggleGUI()
    if window:IsShown() then window:Hide()
    else self:RefreshGUI();window:Show() end
end
window:SetScript("OnShow",function() addon:RefreshGUI() end)
table.insert(UISpecialFrames,"HCDeathsConfig")

local minimap=CreateFrame("Button","HCDeathsMinimapButton",Minimap)
minimap:SetWidth(32);minimap:SetHeight(32);minimap:SetFrameStrata("MEDIUM")
minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local icon=minimap:CreateTexture(nil,"ARTWORK")
icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
icon:SetWidth(20);icon:SetHeight(20);icon:SetPoint("CENTER",minimap,"CENTER",0,0)
local border=minimap:CreateTexture(nil,"OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetWidth(54);border:SetHeight(54);border:SetPoint("TOPLEFT",minimap,"TOPLEFT",0,0)
minimap:RegisterForClicks("LeftButtonUp","RightButtonUp")
minimap:RegisterForDrag("LeftButton")
function addon:PositionMinimap()
    local angle=(HCDeaths_Settings.minimapAngle or 220)*math.pi/180
    minimap:ClearAllPoints()
    minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*80,math.sin(angle)*80)
end
local dragging=false
minimap:SetScript("OnDragStart",function()
    dragging=true
    this:SetScript("OnUpdate",function()
        local x,y=GetCursorPosition()
        local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale()
        local angle=math.atan2(y/scale-cy,x/scale-cx)
        HCDeaths_Settings.minimapAngle=angle*180/math.pi
        addon:PositionMinimap()
    end)
end)
minimap:SetScript("OnDragStop",function() this:SetScript("OnUpdate",nil) end)
minimap:SetScript("OnClick",function()
    if dragging then dragging=false;return end
    if arg1=="RightButton" then addon:RunCommand("log",true) else addon:ToggleGUI() end
end)
minimap:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_LEFT")
    GameTooltip:AddLine("HCDeaths",1,0.82,0)
    GameTooltip:AddLine("Left-click: settings",1,1,1)
    GameTooltip:AddLine("Right-click: death log",1,1,1)
    GameTooltip:AddLine("Drag: move around minimap",0.7,0.7,0.7)
    GameTooltip:Show()
end)
minimap:SetScript("OnLeave",function() GameTooltip:Hide() end)
function addon:InitializeGUI()
    self:PositionMinimap();self:RefreshGUI()
end
