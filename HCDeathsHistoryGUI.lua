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
local dialog=panel("HCDeathsHistory",430,230)
dialog:SetPoint("CENTER",UIParent,"CENTER",0,0)
text(dialog,"Full death-log history",18,-18,390)
text(dialog,"Automatic sharing covers the latest 100 entries. Full history requires the sender's approval (both players: 1.5.0+). Large transfers may take a long time.",18,-45,390)
local box=CreateFrame("EditBox","HCDeathsHistoryPeer",dialog)
box:SetWidth(205);box:SetHeight(27);box:SetPoint("TOPLEFT",dialog,"TOPLEFT",18,-98)
box:SetAutoFocus(false);box:SetFontObject(GameFontHighlightSmall);box:SetTextInsets(7,7,0,0)
box:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
box:SetBackdropColor(0,0,0,1);box:SetMaxLetters(48)
box:SetScript("OnEscapePressed",function() this:ClearFocus() end)
button(dialog,"HCDeathsHistoryRequest","Request all",238,-99,170,function() box:ClearFocus();S:RequestHistory(box:GetText() or "");S:RefreshHistoryUI() end)
local status=text(dialog,"Enter the sender's character name.",18,-140,390)
button(dialog,"HCDeathsHistoryCancel","Cancel transfer",18,-190,190,function() S:CancelHistory();S:RefreshHistoryUI() end)
button(dialog,nil,"Close",238,-190,170,function() dialog:Hide();box:ClearFocus() end)
local notice=panel("HCDeathsHistoryApproval",310,130)
notice:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-25,-100)
local noticeText=text(notice,"",14,-15,282)
local approve=button(notice,"HCDeathsHistoryApprove","Allow once",14,-94,135,function() S:DecideHistory(true);S:RefreshHistoryUI() end)
button(notice,"HCDeathsHistoryDeny","Decline",161,-94,135,function() S:DecideHistory(false);S:RefreshHistoryUI() end)
S.approvalFrame=notice
function S:RefreshHistoryUI()
    local r=self.requests[1]
    if HCDeaths_Settings.sync and r and not (UnitAffectingCombat and UnitAffectingCombat("player")) then
        noticeText:SetText(r.peer.." requests ALL saved death logs. Allow this transfer once?\nPending: "..table.getn(self.requests).." / expires in "..math.max(0,math.ceil(r.expires-GetTime())).."s\n"..(self.grant and "Currently sending; please wait." or "Drag this panel to move it."))
        if self.grant then approve:Disable() else approve:Enable() end
        notice:Show()
    else notice:Hide() end
    if self.pull and self.pull.full then status:SetText("Receiving full history from "..self.pull.peer)
    elseif self.grant and self.grant.full then status:SetText("Sending full history to "..self.grant.peer)
    else status:SetText(self.manualStatus or "Enter the sender's character name.") end
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
    button(config,"HCDeathsHistoryOpen","Full history sharing...",20,-500,490,function() addon:ToggleHistory() end)
end
