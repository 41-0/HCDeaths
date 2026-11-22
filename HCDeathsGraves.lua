-- Octo gravestone observations; WoW 1.12 / Lua 5.0.
local addon=HCDeaths_API
if not addon then return end
local G={status="Waiting for a grave window"}
addon.Graves=G
local classes={"Warrior","Paladin","Hunter","Rogue","Priest","Shaman","Mage","Warlock","Druid"}
local function known(v) return v and v~="" and v~="Unknown" and v~="nil" end
local function clean(s)
    if type(s)~="string" then return "" end
    s=string.gsub(s,"|c%x%x%x%x%x%x%x%x","");s=string.gsub(s,"|r","")
    s=string.gsub(s,"%s+"," ")
    return string.gsub(s,"^%s*(.-)%s*$","%1")
end
local function same(a,b) return string.lower(string.gsub(clean(tostring(a)),"%s+",""))==string.lower(string.gsub(clean(tostring(b)),"%s+","")) end
-- Lua 5.0 has no math.huge. Infinity and NaN fail this subtraction check.
local function finite(n) return type(n)=="number" and n-n==0 end
function G:Parse(frame)
    if not frame or not frame.GetRegions then return nil end
    local name,level,race,class,killer,killerLevel
    self.lastTexts={}
    local regions={}
    local function collect(f,depth)
        if depth>3 then return end
        if f.GetRegions then for _,r in ipairs({f:GetRegions()}) do table.insert(regions,r) end end
        if f.GetChildren then for _,child in ipairs({f:GetChildren()}) do if not child.IsShown or child:IsShown() then collect(child,depth+1) end end end
    end
    collect(frame,0)
    local rawTexts={}
    for _,region in ipairs(regions) do
        if region.GetText and (not region.IsShown or region:IsShown()) then
            local raw=region:GetText()
            if type(raw)~="string" then raw="" end
            raw=string.gsub(raw,"|c%x%x%x%x%x%x%x%x","");raw=string.gsub(raw,"|r","")
            table.insert(rawTexts,raw)
            local s=clean(raw)
            if s~="" and table.getn(self.lastTexts)<16 then table.insert(self.lastTexts,string.sub(s,1,300)) end
            local _,_,v=string.find(s,"^Grave of (.+)$")
            if v then name=v end
            local _,_,n,description=string.find(s,"^Level (%d+) (.+)$")
            if n then
                for _,c in ipairs(classes) do
                    local _,_,r=string.find(description,"^(.+) "..c.."$")
                    if r then level=n;race=r;class=c end
                end
            end
            local _,_,k,kl=string.find(s,"^Fell to (.+) %(level (%d+)%)%.?$")
            if k then killer=k;killerLevel=kl end
        end
    end
    local lastWords,wordsConflict
    local quoted={}
    local function accept(words)
        if lastWords~=nil and lastWords~=words then wordsConflict=true else lastWords=words end
    end
    for _,raw in ipairs(rawTexts) do
        local _,_,wholeQuote=string.find(raw,'^%s*"(.*)"%s*$')
        local _,_,value=string.find(raw,"^%s*.-[Ll][Aa][Ss][Tt]%s+[Ww][Oo][Rr][Dd][Ss]%s*:%s*(.-)%s*$")
        if wholeQuote~=nil then table.insert(quoted,wholeQuote)
        elseif value then
            local _,_,message=string.find(value,'^"(.*)"$')
            if message~=nil then accept(message) elseif value~="" then accept(value) end
        else
            local _,_,message=string.find(raw,'^%s*"(.*)"%s*$')
            if message~=nil then table.insert(quoted,message) end
        end
    end
    -- Some grave UIs put the label and quote in separate regions, or show
    -- only one standalone quote. Never choose among multiple different quotes.
    if lastWords==nil and table.getn(quoted)==1 then accept(quoted[1]) end
    if wordsConflict then lastWords=nil end
    if not name or not level or not killer or tonumber(level)<1 or tonumber(level)>60 then return nil end
    return {playerName=name,playerLevel=level,playerRace=race,playerClass=class,killerName=killer,killerLevel=killerLevel,lastWords=lastWords}
end
local function visible(frame)
    if not frame then return false end
    if frame.IsVisible then return frame:IsVisible() end
    return frame.IsShown and frame:IsShown()
end
function G:Position()
    local diagnostic={}
    self.positionDiagnostic=diagnostic
    local r={gravePositionKind="observer",graveObservedAt=date("!%Y/%m/%d %H:%M:%S"),
        graveObserver=UnitName("player"),graveZone=GetZoneText(),graveSubzone=GetSubZoneText()}
    if UnitPosition then
        local ok,a,b,c,d=pcall(UnitPosition,"player")
        if ok then
            a,b,c,d=tonumber(a),tonumber(b),tonumber(c),tonumber(d)
            if finite(a) and finite(b) and finite(c) then
                r.graveWorld1=a;r.graveWorld2=b;r.graveWorld3=c
                if finite(d) then r.graveWorld4=d end
            else diagnostic.raw="UnitPosition did not return three numeric values" end
        else diagnostic.raw=tostring(a) end
    else diagnostic.raw="UnitPosition unavailable" end
    local function readMap()
        if not GetPlayerMapPosition or not GetCurrentMapContinent or not GetCurrentMapZone or not GetMapInfo then return false end
        local ok,x,y=pcall(GetPlayerMapPosition,"player")
        if not ok then diagnostic.map=tostring(x);return false end
        x,y=tonumber(x),tonumber(y)
        local c,z=tonumber(GetCurrentMapContinent()),tonumber(GetCurrentMapZone())
        local map=GetMapInfo()
        if finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1 and (x~=0 or y~=0)
            and c and c>=1 and z and z>=1 and known(map) then
            r.graveX=x;r.graveY=y;r.graveMap=map;r.graveContinent=c;r.graveMapZone=z
            return true
        end
        diagnostic.map="Map position unavailable (zero/invalid coordinates or map context)"
        return false
    end
    -- The diagnostic proved direct map reads work. Use them without changing
    -- selection when the selected map's zone can be verified as the current zone.
    local verified=false
    if GetMapZones and GetCurrentMapContinent and GetCurrentMapZone then
        local c,z=tonumber(GetCurrentMapContinent()),tonumber(GetCurrentMapZone())
        if c and c>=1 and z and z>=1 then
            local ok,zones=pcall(function() return {GetMapZones(c)} end)
            local current=GetRealZoneText and GetRealZoneText() or r.graveZone
            verified=ok and zones[z] and same(zones[z],current)
        end
    end
    if verified then readMap() end
    diagnostic.worldMapVisible=visible(WorldMapFrame) and true or false
    if not r.graveX and not diagnostic.worldMapVisible and SetMapToCurrentZone and SetMapZoom
        and GetCurrentMapContinent and GetCurrentMapZone then
        local c,z=GetCurrentMapContinent(),GetCurrentMapZone()
        if c~=nil and z~=nil then
            local ok,err=pcall(SetMapToCurrentZone)
            if ok then
                local success,problem=pcall(readMap)
                if not success then diagnostic.map=tostring(problem) end
            else diagnostic.map=tostring(err) end
            local restored,problem=pcall(SetMapZoom,c,z)
            if not restored then diagnostic.restore=tostring(problem) end
        end
    elseif not r.graveX and diagnostic.worldMapVisible then
        diagnostic.map="Visible world map is not verified as the current zone; selection left unchanged"
    end
    if not r.graveX and not r.graveWorld1 then return nil end
    return r
end
function G:Find(info)
    local found
    local details={sameName=0,matches=0,rejected={}}
    self.matchDiagnostic=details
    local realm=GetRealmName and GetRealmName()
    for _,r in ipairs(HCDeaths or {}) do
        if (r.deathType=="PVE" or r.deathType=="PVP") and same(r.playerName,info.playerName) then
            details.sameName=details.sameName+1
            local reason
            if known(r.playerLevel) and tonumber(r.playerLevel)~=tonumber(info.playerLevel) then reason="player level differs"
            elseif known(r.realm) and realm and r.realm~=realm then reason="realm differs"
            else
                for _,key in ipairs({"killerName","killerLevel","playerRace","playerClass"}) do
                    if known(r[key]) and not same(r[key],info[key]) then
                        reason=key.." differs: log="..tostring(r[key])..", grave="..tostring(info[key]);break
                    end
                end
            end
            if not reason and known(r.lastWords) and known(info.lastWords) and r.lastWords~=info.lastWords then reason="lastWords differs" end
            if not reason then found=r;details.matches=details.matches+1
            elseif table.getn(details.rejected)<5 then table.insert(details.rejected,reason) end
        end
    end
    if details.matches>1 then return nil,"More than one saved death matches this grave" end
    if found then return found end
    for _,r in ipairs(HCDeaths_UnknownDeaths or {}) do
        if same(r.playerName,info.playerName) and tonumber(r.playerLevel)==tonumber(info.playerLevel)
            and same(r.killerName,info.killerName) and tonumber(r.killerLevel)==tonumber(info.killerLevel)
            and same(r.playerRace,info.playerRace) and same(r.playerClass,info.playerClass)
            and (not realm or r.realm==realm)
            and (not known(r.lastWords) or not known(info.lastWords) or r.lastWords==info.lastWords) then
            if found then return nil,"More than one unknown-date grave matches" end
            found=r
        end
    end
    return found
end
function G:Apply(info,pos,inspectedAt)
    local r,reason=self:Find(info)
    if reason then return false,reason end
    local created=false
    inspectedAt=inspectedAt or (pos and pos.graveObservedAt) or date("!%Y/%m/%d %H:%M:%S")
    if not r then
        r={deathTimeUnknown=true,deathType="UNKNOWN",sdate="Unknown",stime="Unknown",
            firstInspectedAt=inspectedAt,lastInspectedAt=inspectedAt,realm=GetRealmName and GetRealmName(),
            faction=UnitFactionGroup and UnitFactionGroup("player"),location="Unknown",zone="Unknown",
            playerGuild="Unknown",lastWords="Unknown",killerClass="Unknown",killerRace="Unknown",killerGuild="Unknown"}
        for key,value in pairs(info) do r[key]=value end
        HCDeaths_UnknownDeaths=HCDeaths_UnknownDeaths or {};table.insert(HCDeaths_UnknownDeaths,r);created=true
    end
    if known(info.lastWords) and not known(r.lastWords) then r.lastWords=info.lastWords end
    if r.deathTimeUnknown then r.lastInspectedAt=inspectedAt end
    local valid=addon.Sync and addon.Sync:ValidGrave(r)
    if not pos and not valid then
        if addon.Retention then addon.Retention:Enforce() end
        addon:updateLog()
        return false,r.deathTimeUnknown and "Unknown-date entry saved; player coordinates unavailable" or "Player coordinates unavailable"
    end
    -- Keep an existing coordinate bundle intact; later visits may be farther away.
    local result="Already recorded; existing observation retained"
    if not valid and pos then
        -- Replace the entire invalid bundle, never leave stale X/Y/map values.
        for key in pairs(r) do if string.find(key,"^grave") then r[key]=nil end end
        for key,value in pairs(pos) do r[key]=value end
        result="Observer coordinates recorded"
    elseif valid and pos and not tonumber(r.graveX) and pos.graveX then
        local identical=true
        for _,key in ipairs({"graveWorld1","graveWorld2","graveWorld3"}) do
            local a,b=tonumber(r[key]),tonumber(pos[key])
            if not a or not b or math.abs(a-b)>0.01 then identical=false end
        end
        if identical then
            for _,key in ipairs({"graveX","graveY","graveMap","graveContinent","graveMapZone"}) do r[key]=pos[key] end
            result="Map coordinates added at the same verified raw position"
        end
    end
    for _,key in ipairs({"playerLevel","playerRace","playerClass","killerName","killerLevel"}) do
        if not known(r[key]) then r[key]=info[key] end
    end
    if r.deathTimeUnknown then
        if pos then r.location=known(pos.graveSubzone) and pos.graveSubzone or pos.graveZone;r.zone=pos.graveZone end
        if created then result="Unknown-date grave entry created" end
    elseif addon.Sync then addon.Sync:Remember(r) end
    if r.deathTimeUnknown and addon.Sync then
        -- Also resolve observations created after a dated history was received.
        for _,dated in ipairs(HCDeaths) do
            if addon.Sync:ReconcileUnknown(dated) then addon.Sync:Remember(dated) end
        end
    end
    if addon.Retention then addon.Retention:Enforce() end
    addon:updateLog()
    return true,result
end
local timer=CreateFrame("Frame",nil,UIParent)
G.timer=timer
local elapsed=0
local opened,position,signature,nextTry,stopAt,completed,inspectedAt,wordSignature
function G:SetStatus(state,info)
    self.status=state
    HCDeaths_GraveStatus={version="1.5.4-fork",utc=date("!%Y/%m/%d %H:%M:%S"),state=state,
        info=info,texts=self.lastTexts,matching=self.matchDiagnostic,position=self.positionDiagnostic,
        observerPosition=position}
end
function G:Poll(force)
    local frame=getglobal("OctoReplayGraveFrame")
    if not frame or not visible(frame) then
        opened=nil;position=nil;signature=nil;completed=nil;wordSignature=nil
        if force then self.matchDiagnostic=nil;self.lastTexts=nil;self.positionDiagnostic=nil;self:SetStatus(frame and "Grave window is closed" or "OctoReplayGraveFrame not found") end
        return
    end
    local now=GetTime()
    if not opened then
        opened=true;inspectedAt=date("!%Y/%m/%d %H:%M:%S");self.matchDiagnostic=nil;position=self:Position();signature=nil;nextTry=0;stopAt=now+30;completed=nil
    end
    local info=self:Parse(frame)
    if not info then
        self.matchDiagnostic=nil
        self:SetStatus("Cannot parse grave window text")
        return
    end
    local key=info.playerName..":"..info.playerLevel..":"..info.killerName..":"..info.killerLevel
    if signature~=key then
        if signature then position=self:Position();inspectedAt=date("!%Y/%m/%d %H:%M:%S") end
        signature=key;nextTry=0;stopAt=now+30;completed=nil
    end
    if wordSignature~=info.lastWords then
        wordSignature=info.lastWords;completed=nil;nextTry=0;stopAt=now+30
    end
    if force then completed=nil;nextTry=0;stopAt=now+30 end
    if completed or now>stopAt or now<nextTry then return end
    nextTry=now+0.5
    -- Retry unavailable coordinates briefly; do not replace an already captured
    -- observer position after movement or replay.
    if not position then position=self:Position() end
    local ok,message=self:Apply(info,position,inspectedAt)
    self:SetStatus(message,info)
    if ok then completed=true end
end
function G:Report(check)
    if check then
        local ok,err=pcall(self.Poll,self,true)
        if not ok then self:SetStatus("Error: "..tostring(err)) end
    end
    local d=HCDeaths_GraveStatus
    addon:print("Grave: "..(d and d.state or self.status))
    if not d then return end
    if d.info then addon:print(d.info.playerName.." / level "..d.info.playerLevel.." / "..d.info.killerName.." ("..d.info.killerLevel..")") end
    if d.matching then
        addon:print("Saved entries with this name: "..d.matching.sameName.."; matching entries: "..d.matching.matches)
        for _,reason in ipairs(d.matching.rejected) do addon:print(reason) end
    end
    if d.position then
        if d.position.map then addon:print("Map: "..d.position.map) end
        if d.position.raw then addon:print("Raw position: "..d.position.raw) end
        if d.position.restore then addon:print("Map restore: "..d.position.restore) end
    end
end
-- Contain optional client API errors and record the error instead of silently
-- losing the attempt. Automatic operation never prints chat messages.
timer:SetScript("OnUpdate",function()
    if not addon.loaded then return end
    elapsed=elapsed+(arg1 or 0)
    if elapsed<0.1 then return end
    elapsed=0
    local ok,err=pcall(G.Poll,G,false)
    if not ok then G:SetStatus("Error: "..tostring(err)) end
end)
