-- Added by the unofficial HCDeaths GUI fork (2026-11-20).
-- Distributed under the MIT License; see LICENSE.

-- WoW 1.12 / Lua 5.0 settings and standalone minimap launcher.
local addon=HCDeaths_API
if not addon then return end
local window=CreateFrame("Frame","HCDeathsConfig",UIParent)
window:Hide();window:SetWidth(530);window:SetHeight(535)
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
    c:SetScript("OnClick",function() addon:RunCommand(this.command,true);if this.command=="sync" and addon.Sync then addon.Sync:Tick() end end)
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
checkbox("sync","Automatically share death logs",20,-207)
label("Sync status (hover)",300,-212)
local syncStatus=CreateFrame("Frame",nil,window)
syncStatus:SetWidth(180);syncStatus:SetHeight(24)
syncStatus:SetPoint("TOPLEFT",window,"TOPLEFT",295,-207)
syncStatus:EnableMouse(true)
syncStatus:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
    GameTooltip:SetText("Automatic log sharing")
    GameTooltip:AddLine(addon.Sync and addon.Sync.status or "Unavailable",1,1,1)
    if addon.Sync then
        local s=addon.Sync;local c=s.stats or {}
        GameTooltip:AddLine("Channel ID: "..s:ChannelID().." / TX: "..(c.sent or 0).." / RX peers: "..(c.peerPackets or 0).." / own echo: "..(c.echo or 0),1,1,1,true)
        GameTooltip:AddLine("Send spacing: "..(s.sendInterval or 10).."+ seconds / cooldown: "..math.max(0,math.ceil((s.pauseUntil or 0)-GetTime())).." seconds",.7,.7,.7,true)
        GameTooltip:AddLine("Imported: "..(c.imported or 0).." / updated: "..(c.enriched or 0).." / queued sends: "..table.getn(s.queue),1,1,1,true)
        local peer=s.pull and s.pull.peer or s.lastPeer
        local compact=peer and s.capabilities and s.capabilities[string.lower(peer)]
        GameTooltip:AddLine("Transfer mode: "..(compact and "compact" or "standard (update both players for compact mode)"),.7,.7,.7,true)
        if s.pull and s.pull.total then GameTooltip:AddLine("Current record fragments: "..(s.pull.received or 0).." / "..s.pull.total,.7,.7,.7) end
        if s.lastError then GameTooltip:AddLine("Error: "..s.lastError,1,.3,.3,true) end
        GameTooltip:AddLine("/hcd sync check, then /hcd sync status",0.7,0.7,0.7)
    end
    if addon.Sync and addon.Sync.ProgressText then GameTooltip:AddLine(addon.Sync:ProgressText(),1,1,1,true) end
    GameTooltip:AddLine("Same-faction users in HCDeathsSyncV2. Best effort; no manual setup.",0.7,0.7,0.7,true)
    GameTooltip:Show()
end)
syncStatus:SetScript("OnLeave",function() GameTooltip:Hide() end)
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
numeric("logscale","Log scale (0.25 - 3)","log scale",-254)
numeric("toastscale","Toast scale (0.25 - 3)","toast scale",-291)
numeric("toasttime","Toast seconds (0 < n <= 300)","toast time",-328)
button("Show / hide movable toast",20,-376,240,function() addon:RunCommand("move",true) end)
button("Reset settings / positions",280,-376,230,function() addon:RunCommand("reset",true) end)
local help=button("Command help (hover)",20,-417,240,function() end)
help:SetScript("OnEnter",function()
    GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
    GameTooltip:SetText("HCDeaths commands")
    GameTooltip:AddLine("/hcd - Settings",1,1,1)
    GameTooltip:AddLine("/hcd message | move | log | toast | progress",1,1,1)
    GameTooltip:AddLine("/hcd color | deathsound | levelsound | roar | sync | reset",1,1,1)
    GameTooltip:AddLine("/hcd log scale number | log max number",1,1,1)
    GameTooltip:AddLine("/hcd prune level number | prune days number | prune keep number",1,1,1)
    GameTooltip:AddLine("/hcd toast scale number | toast time seconds",1,1,1)
    GameTooltip:Show()
end)
help:SetScript("OnLeave",function() GameTooltip:Hide() end)
button("Close",280,-417,230,function() window:Hide() end)
button("Manage saved logs",20,-465,490,function() addon:ToggleLogManagement() end)
label("Log: 20 entries per page. Minimap: left = settings, right = log.",20,-545)

function addon:RefreshGUI()
    for key,c in pairs(controls) do c:SetChecked(HCDeaths_Settings[key]) end
    for key,e in pairs(fields) do e:SetText(tostring(HCDeaths_Settings[key])) end
    if self.RefreshLogManagement then self:RefreshLogManagement() end
end
function addon:ToggleGUI()
    if window:IsShown() then window:Hide()
    else self:RefreshGUI();window:Show() end
end
window:SetScript("OnShow",function() addon:RefreshGUI() end)
table.insert(UISpecialFrames,"HCDeathsConfig")

-- Explicit cleanup controls live in a separate, compact dialog.
local management=CreateFrame("Frame","HCDeathsLogManagement",UIParent)
management:Hide();management:SetWidth(530);management:SetHeight(360)
management:SetPoint("CENTER",UIParent,"CENTER",0,0)
management:SetFrameStrata("DIALOG");management:SetMovable(true);management:SetClampedToScreen(true)
management:EnableMouse(true);management:RegisterForDrag("LeftButton")
management:SetScript("OnDragStart",function() this:StartMoving() end)
management:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
management:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
management:SetBackdropColor(0.04,0.04,0.04,0.97)
local function manageLabel(text,x,y,font)
    local f=management:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    f:SetPoint("TOPLEFT",management,"TOPLEFT",x,y);f:SetText(text);return f
end
manageLabel("Manage saved death logs",20,-18,"GameFontNormalLarge")
manageLabel("Changes affect both lists. Unknown dates use last inspection time.",20,-46,"GameFontHighlightSmall")
local manageClose=CreateFrame("Button",nil,management,"UIPanelCloseButton")
manageClose:SetPoint("TOPRIGHT",management,"TOPRIGHT",0,0)
manageClose:SetScript("OnClick",function() management:Hide() end)
local status=manageLabel("",20,-278,"GameFontHighlightSmall")
status:SetWidth(490);status:SetHeight(40);status:SetJustifyH("LEFT")
local summary=manageLabel("",20,-331,"GameFontHighlightSmall")
local manageFields={}
local function manageRow(key,text,y,initial,action,method)
    manageLabel(text,20,y-5)
    local box=CreateFrame("Frame",nil,management)
    box:SetWidth(82);box:SetHeight(24);box:SetPoint("TOPLEFT",management,"TOPLEFT",250,y)
    box:SetBackdrop({bgFile="Interface\\Buttons\\White8x8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=8,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    box:SetBackdropColor(0,0,0,1);box:SetBackdropBorderColor(.65,.65,.65,1)
    local edit=CreateFrame("EditBox","HCDeathsManageInput_"..key,box)
    edit:SetWidth(66);edit:SetHeight(20);edit:SetPoint("CENTER",box,"CENTER",0,0)
    edit:SetFontObject("GameFontHighlightSmall");edit:SetTextColor(1,1,1)
    edit:SetJustifyH("LEFT");edit:SetTextInsets(0,0,0,0);edit:SetAutoFocus(false);edit:SetMaxLetters(10)
    edit:SetText(tostring(initial));manageFields[key]=edit
    local function apply()
        local r=addon.Retention
        if not r then return end
        local count,message=r[method](r,edit:GetText())
        status:SetText(message or "")
        if count==nil then status:SetTextColor(1,.3,.3) else status:SetTextColor(1,1,1) end
        edit:ClearFocus();addon:RefreshLogManagement()
        if key=="maximum" and count~=nil then edit:SetText(tostring(HCDeaths_Settings.maxrecords or 0)) end
    end
    edit:SetScript("OnEscapePressed",function() this:ClearFocus() end)
    -- Enter applies the persistent cap; destructive cleanup requires its button.
    if key=="maximum" then edit:SetScript("OnEnterPressed",apply)
    else edit:SetScript("OnEnterPressed",function() this:ClearFocus() end) end
    local b=CreateFrame("Button","HCDeathsManageButton_"..key,management,"UIPanelButtonTemplate")
    b:SetWidth(170);b:SetHeight(25);b:SetPoint("TOPLEFT",management,"TOPLEFT",340,y)
    b:SetText(action);b:SetScript("OnClick",apply)
end
manageRow("maximum","Maximum entries (0 = unlimited)",-80,0,"Apply limit","SetMaximum")
manageLabel("0 means unlimited. Applying a limit deletes the oldest excess entries.",20,-111,"GameFontHighlightSmall")
manageRow("level","Delete below level",-148,10,"Delete below level","BelowLevel")
manageRow("days","Delete older than days",-190,30,"Delete older entries","OlderThan")
manageRow("keep","Keep newest (0 = delete all)",-232,1000,"Delete excess entries","KeepNewest")
function addon:RefreshLogManagement()
    if not addon.Retention then return end
    local cap=tonumber(HCDeaths_Settings.maxrecords) or 0
    summary:SetText("Saved deaths: "..addon.Retention:Count().."   Maximum: "..(cap==0 and "unlimited" or tostring(cap)))
end
management:SetScript("OnShow",function()
    manageFields.maximum:SetText(tostring(HCDeaths_Settings.maxrecords or 0))
    status:SetText("");addon:RefreshLogManagement()
end)
function addon:ToggleLogManagement()
    if management:IsShown() then management:Hide()
    else manageFields.maximum:SetText(tostring(HCDeaths_Settings.maxrecords or 0));status:SetText("");self:RefreshLogManagement();management:Show() end
end
table.insert(UISpecialFrames,"HCDeathsLogManagement")

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
