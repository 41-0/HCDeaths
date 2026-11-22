-- Optional full-history transfer controls. WoW 1.12 / Lua 5.0.
local addon=HCDeaths_API
local S=addon and addon.Sync
if not S then return end
local function panel(name,width,height)
    local f=CreateFrame("Frame",name,UIParent)
    f:SetWidth(width);f:SetHeight(height);f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
    f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(0,0,0,.95);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() this:StartMoving() end)
    f:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
    f:Hide();return f
end
local function text(parent,value,x,y,width)
    local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");t:SetText(value)
    return t
end
local function button(parent,name,value,x,y,width,callback)
    local b=CreateFrame("Button",name,parent,"UIPanelButtonTemplate")
    b:SetWidth(width);b:SetHeight(24);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(value);b:SetScript("OnClick",callback);return b
end
local dialog=panel("HCDeathsHistory",470,480)
dialog:SetPoint("CENTER",UIParent,"CENTER",0,0)
text(dialog,"Synchronization status / full history",18,-18,430)
text(dialog,"Automatic sharing covers the latest 100 entries. Full history requires the sender's approval (both players: 1.5.0+). Large transfers may take a long time.",18,-45,430)
local inputBackground=CreateFrame("Frame",nil,dialog)
inputBackground:SetWidth(205);inputBackground:SetHeight(27);inputBackground:SetPoint("TOPLEFT",dialog,"TOPLEFT",18,-98)
inputBackground:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
inputBackground:SetBackdropColor(0,0,0,1)
local box=CreateFrame("EditBox","HCDeathsHistoryPeer",inputBackground)
box:SetWidth(205);box:SetHeight(27);box:SetPoint("CENTER",inputBackground,"CENTER",0,0)
box:SetAutoFocus(false);box:SetFontObject("GameFontHighlightSmall");box:SetTextColor(1,1,1);box:SetTextInsets(7,7,0,0)
box:SetMaxLetters(48)
box:SetScript("OnEscapePressed",function() this:ClearFocus() end)
button(dialog,"HCDeathsHistoryRequest","Request all",268,-99,180,function() box:ClearFocus();S:RequestHistory(box:GetText() or "");S:RefreshHistoryUI() end)
local feedbackBox=CreateFrame("Frame","HCDeathsHistoryFeedback",dialog)
feedbackBox:SetPoint("TOPLEFT",dialog,"TOPLEFT",16,-132);feedbackBox:SetWidth(438);feedbackBox:SetHeight(64)
feedbackBox:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
local feedbackText=text(feedbackBox,"",10,-8,418)
feedbackText:SetHeight(48);feedbackText:SetJustifyV("TOP")
S.feedbackText=feedbackText
local progress=CreateFrame("StatusBar","HCDeathsSyncProgress",dialog)
progress:SetWidth(430);progress:SetHeight(10);progress:SetPoint("TOPLEFT",dialog,"TOPLEFT",18,-206)
progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");progress:SetStatusBarColor(.2,.7,1)
progress:SetMinMaxValues(0,1);progress:SetValue(0)
local status=text(dialog,"Enter the sender's character name.",18,-226,430)
status:SetHeight(200);status:SetJustifyV("TOP")
button(dialog,"HCDeathsHistoryCancel","Cancel transfer",18,-439,205,function() S:CancelHistory();S:RefreshHistoryUI() end)
button(dialog,nil,"Close",243,-439,205,function() dialog:Hide();box:ClearFocus() end)
local notice=panel("HCDeathsHistoryApproval",310,128)
notice:SetFrameStrata("FULLSCREEN_DIALOG");notice:SetFrameLevel(100)
local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
local function validPosition(p)
    return type(p)=="table" and anchors[p.point] and anchors[p.relativePoint]
        and type(p.x)=="number" and p.x-p.x==0 and math.abs(p.x)<100000
        and type(p.y)=="number" and p.y-p.y==0 and math.abs(p.y)<100000
end
function notice:RestorePosition()
    local p=HCDeaths_Settings and HCDeaths_Settings.approvalPosition
    self:ClearAllPoints()
    if validPosition(p) then self:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
    else self:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-24,24) end
end
notice:RestorePosition()
notice:SetScript("OnDragStop",function()
    this:StopMovingOrSizing()
    local point,relative,relativePoint,x,y=this:GetPoint(1)
    local p={point=point,relativePoint=relativePoint,x=x,y=y}
    if validPosition(p) then HCDeaths_Settings.approvalPosition=p end
end)
function S:ResetApprovalPosition()
    HCDeaths_Settings.approvalPosition=nil;notice:RestorePosition()
end
local noticeTitle=text(notice,"HCDeaths",12,-10,286)
noticeTitle:SetFontObject("GameFontNormal");noticeTitle:SetHeight(14)
local noticeText=text(notice,"",12,-30,286)
noticeText:SetHeight(55);noticeText:SetJustifyV("TOP")
S.approvalTitle=noticeTitle
local approve=button(notice,"HCDeathsHistoryApprove","Allow once",12,-94,137,function() S:DecideHistory(true);S:RefreshHistoryUI() end)
button(notice,"HCDeathsHistoryDeny","Decline",161,-94,137,function() S:DecideHistory(false);S:RefreshHistoryUI() end)
S.approvalFrame=notice
function S:RefreshHistoryUI()
    local r=self.requests[1]
    if HCDeaths_Settings.sync and r and not self:InCombat() then
        noticeText:SetText(r.peer.." requests your full death log.\n"..(self.grant and self.grant.full and "Sending history; please wait." or "Allow this transfer once?").."\nPending: "..table.getn(self.requests).." - expires in "..math.max(0,math.ceil(r.expires-GetTime())).."s")
        if self.grant and self.grant.full then approve:Disable() else approve:Enable() end
        notice:Show()
    else notice:Hide() end
    local f=self.historyFeedback
    feedbackText:SetText(f and f.message or "Enter a character name and click Request all. You can keep playing while the request is pending.")
    if f and f.kind=="error" then
        feedbackBox:SetBackdropColor(.28,.02,.02,1);feedbackBox:SetBackdropBorderColor(1,.2,.2,1);feedbackText:SetTextColor(1,.35,.35)
    elseif f and f.kind=="warning" then
        feedbackBox:SetBackdropColor(.2,.12,.01,1);feedbackBox:SetBackdropBorderColor(1,.65,.15,1);feedbackText:SetTextColor(1,.8,.35)
    elseif f and f.kind=="success" then
        feedbackBox:SetBackdropColor(.02,.16,.04,1);feedbackBox:SetBackdropBorderColor(.3,.85,.4,1);feedbackText:SetTextColor(.5,1,.6)
    else
        feedbackBox:SetBackdropColor(.02,.08,.16,1);feedbackBox:SetBackdropBorderColor(.35,.65,1,1);feedbackText:SetTextColor(.7,.85,1)
    end
    status:SetText(self:ProgressText())
    local p=self.pull
    if p and p.totalRecords and p.totalRecords>0 then
        local checked=math.max(0,(p.reviewed or 0)-table.getn(p.items or {})-(p.wait and 1 or 0))
        local fraction=p.wait and p.total and p.received/p.total or 0
        progress:SetValue(math.min(1,(checked+fraction)/p.totalRecords))
    elseif not p and self.lastTransfer and not self.manualRequest then progress:SetValue(1)
    else progress:SetValue(0) end
end
function addon:ToggleHistory()
    if dialog:IsShown() then dialog:Hide();box:ClearFocus()
    else
        if S.lastPeer then box:SetText(S.lastPeer) end
        dialog:Show();S:RefreshHistoryUI()
    end
end
local config=getglobal("HCDeathsConfig")
if config then
    config:SetHeight(570)
    button(config,"HCDeathsHistoryOpen","Sync status / full history...",20,-500,490,function() addon:ToggleHistory() end)
end

local redraw=CreateFrame("Frame",nil,UIParent)
redraw:RegisterEvent("PLAYER_REGEN_ENABLED");redraw:RegisterEvent("PLAYER_REGEN_DISABLED")
redraw:SetScript("OnEvent",function() local ok,err=pcall(S.RefreshHistoryUI,S);if not ok then S.lastUIError=tostring(err) end end)
local elapsed=0
redraw:SetScript("OnUpdate",function()
    if not addon.loaded then return end
    elapsed=elapsed+(arg1 or 0)
    if elapsed<0.5 then return end
    elapsed=0
    local ok,err=pcall(S.RefreshHistoryUI,S);if not ok then S.lastUIError=tostring(err) end
end)
