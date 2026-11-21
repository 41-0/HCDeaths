-- Unofficial fork: automatic, best-effort same-faction channel synchronization.
-- WoW 1.12 / Lua 5.0. No executable serialization or external libraries.
local addon=HCDeaths_API
if not addon then return end
local S={channel="HCDeathsSyncV2",queue={},seen={},offers={},round=0}
addon.Sync=S
local fields={"playerName","playerLevel","deathType","killerName","killerLevel",
    "killerClass","location","zone","playerClass","playerRace","playerGuild",
    "killerRace","killerGuild","lastWords","sdate","stime","hcType","realm","faction"}
local graveFields={"gravePositionKind","graveObservedAt","graveObserver","graveZone","graveSubzone",
    "graveMap","graveContinent","graveMapZone","graveX","graveY","graveWorld1","graveWorld2","graveWorld3","graveWorld4"}
local graveKeys={}
for _,key in ipairs(graveFields) do table.insert(fields,key);graveKeys[key]=true end
local function known(v) return v~=nil and v~="Unknown" and v~="nil" end
local function integer(v,lo,hi)
    local n=tonumber(v)
    if n and n==math.floor(n) and n>=lo and n<=hi then return n end
end
local function player(v)
    return type(v)=="string" and string.len(v)<=48 and string.find(v,"^[%a\128-\255]+$")
end
-- Pure UTC conversion: independent of the receiving machine's timezone.
function S:Stamp(r)
    if type(r.sdate)~="string" or type(r.stime)~="string" then return nil end
    local _,_,y,m,d=string.find(r.sdate,"^(%d%d%d%d)/(%d%d)/(%d%d)$")
    local _,_,h,n,sec=string.find(r.stime,"^(%d%d):(%d%d):(%d%d)$")
    if not h then _,_,h,n=string.find(r.stime,"^(%d%d):(%d%d)$");sec="0" end
    y=integer(y,2004,2200);m=integer(m,1,12);d=integer(d,1,31)
    h=integer(h,0,23);n=integer(n,0,59);sec=integer(sec,0,59)
    if not y or not m or not d or not h or not n or not sec then return nil end
    local lengths={31,28,31,30,31,30,31,31,30,31,30,31}
    if math.mod(y,4)==0 and (math.mod(y,100)~=0 or math.mod(y,400)==0) then lengths[2]=29 end
    if d>lengths[m] then return nil end
    local days=0
    for year=2004,y-1 do
        days=days+365
        if math.mod(year,4)==0 and (math.mod(year,100)~=0 or math.mod(year,400)==0) then days=days+1 end
    end
    for month=1,m-1 do days=days+lengths[month] end
    return ((days+d-1)*24+h)*3600+n*60+sec
end
function S:Context()
    return GetRealmName and GetRealmName(),UnitFactionGroup and UnitFactionGroup("player")
end
function S:Eligible(r)
    local realm,faction=self:Context()
    return realm and faction and r.realm==realm and r.faction==faction
end
function S:MarkSeen(hash)
    local cap=tonumber(HCDeaths_Settings.maxrecords) or 0
    local limit=cap>0 and math.max(256,cap*4) or 0
    if self.seenLimit~=limit then self.seen={};self.seenRing={};self.seenNext=1;self.seenLimit=limit end
    if self.seen[hash] then return end
    if limit>0 then
        local old=self.seenRing[self.seenNext]
        if old then self.seen[old]=nil end
        self.seenRing[self.seenNext]=hash
        self.seenNext=math.mod(self.seenNext,limit)+1
    end
    self.seen[hash]=true
end
function S:Remember(r)
    if not self:Eligible(r) then return end
    local data=self:Pack(r)
    if data then self:MarkSeen(self:Fingerprint(data)) end
end
function S:ValidGrave(r)
    if r.gravePositionKind~="observer" or not player(r.graveObserver) or not known(r.graveZone)
        or not known(r.graveObservedAt) then return false end
    local _,_,day,clock=string.find(r.graveObservedAt,"^(%d%d%d%d/%d%d/%d%d) (%d%d:%d%d:%d%d)$")
    if not day or not self:Stamp({sdate=day,stime=clock}) then return false end
    local hasMap=false;local hasWorld=false
    if known(r.graveX) or known(r.graveY) then
        local x,y=tonumber(r.graveX),tonumber(r.graveY)
        if not x or not y or x~=x or y~=y or x<0 or x>1 or y<0 or y>1 or (x==0 and y==0)
            or not known(r.graveMap) or not integer(r.graveContinent,1,100) or not integer(r.graveMapZone,1,1000) then return false end
        hasMap=true
    end
    if known(r.graveWorld1) or known(r.graveWorld2) or known(r.graveWorld3) then
        for _,key in ipairs({"graveWorld1","graveWorld2","graveWorld3"}) do
            local n=tonumber(r[key]);if not n or n~=n or math.abs(n)>100000000 then return false end
        end
        hasWorld=true
    end
    return hasMap or hasWorld
end
function S:Pack(r)
    local t={}
    for _,key in ipairs(fields) do
        local v=known(r[key]) and tostring(r[key]) or "Unknown"
        local limit=key=="lastWords" and 1024 or 160
        if string.len(v)>limit or string.find(v,"[%z\1-\31]") then return nil end
        table.insert(t,string.len(v)..":"..v)
    end
    return table.concat(t)
end
function S:Unpack(data)
    local r={};local pos=1
    for _,key in ipairs(fields) do
        local a,b,length=string.find(string.sub(data,pos),"^(%d+):")
        if b then b=b+pos-1 end
        -- Lua 5.0 anchors with an init position are not relied upon.
        if not a then return nil end
        local size=integer(length,0,key=="lastWords" and 1024 or 160)
        if not size or b+size>string.len(data) then return nil end
        local v=string.sub(data,b+1,b+size)
        if string.find(v,"[%z\1-\31]") or string.find(v,"|") then return nil end
        r[key]=v;pos=b+size+1
    end
    if pos~=string.len(data)+1 or not player(r.playerName) or not integer(r.playerLevel,1,60)
        or (r.deathType~="PVE" and r.deathType~="PVP") or not self:Stamp(r) or not self:Eligible(r) then return nil end
    if known(r.gravePositionKind) and not self:ValidGrave(r) then return nil end
    return r
end
function S:Fingerprint(data)
    local a,b=1,7
    for i=1,string.len(data) do
        local c=string.byte(data,i)
        a=math.mod(a*131+c,2147483647);b=math.mod(b*137+c,2147483629)
    end
    return string.len(data)..":"..string.format("%.0f:%.0f",a,b)
end
function S:Match(a,b)
    if string.lower(a.playerName or "")~=string.lower(b.playerName or "")
        or tonumber(a.playerLevel)~=tonumber(b.playerLevel) or a.deathType~=b.deathType then return false end
    for _,key in ipairs({"realm","faction"}) do
        if known(a[key]) and known(b[key]) and a[key]~=b[key] then return false end
    end
    local x,y=self:Stamp(a),self:Stamp(b)
    if not x or not y or math.abs(x-y)>300 then return false end
    for _,key in ipairs({"killerName","killerLevel","location"}) do
        if known(a[key]) and a[key]~="" and known(b[key]) and b[key]~="" and string.lower(tostring(a[key]))~=string.lower(tostring(b[key])) then return false end
    end
    return true
end
function S:Find(r)
    local found
    for _,v in ipairs(HCDeaths) do
        if self:Match(v,r) then
            if found then return nil end -- ambiguity: preserve a separate entry
            found=v
        end
    end
    return found
end
function S:Merge(dest,src,direct)
    local changed=false
    for _,key in ipairs(fields) do
        if not graveKeys[key] and known(src[key]) and (direct or not known(dest[key])) then
            if dest[key]~=src[key] then changed=true end
            dest[key]=src[key]
        end
    end
    -- Never mix X from one visit with Y or map identifiers from another.
    if not self:ValidGrave(dest) and self:ValidGrave(src) then
        for _,key in ipairs(graveFields) do dest[key]=known(src[key]) and src[key] or nil end
        changed=true
    end
    return changed
end
function S:StoreLocal(r)
    r.realm,r.faction=self:Context()
    local old=self:Find(r)
    if old and old.shared then self:Merge(old,r,true);old.shared=nil;old.sourcePlayer=nil;self:Remember(old);return old end
    table.insert(HCDeaths,r);self:Remember(r);return r
end
function S:Import(r,sender)
    local old=self:Find(r)
    if not self:Eligible(r) then return end
    if not old and addon.Retention and not addon.Retention:AllowImported(r) then return end
    if old then
        if self:Merge(old,r,false) then old.sharedDetails=true;old.detailsSource=sender end
        self:Remember(old)
        if addon.RefreshToastLastWords then addon:RefreshToastLastWords(old) end
    else r.shared=true;r.sourcePlayer=sender;table.insert(HCDeaths,r);self:Remember(r) end
    if addon.Retention then addon.Retention:Enforce() end
    addon:updateLog() -- Imported history never enters the toast or /who queues.
end
function S:Enqueue(target,kind,body)
    local msg="HCDS2|"..target.."|"..kind.."|"..body
    if string.len(msg)>240 or table.getn(self.queue)>=128 then return false end
    table.insert(self.queue,msg);return true
end
function S:IsChannel(name,number,full)
    if type(name)=="string" and string.lower(name)==string.lower(self.channel) then return true end
    if type(full)=="string" and string.find(string.lower(full),"^%d+%. "..string.lower(self.channel).."$") then return true end
    local id=GetChannelName and GetChannelName(self.channel)
    return id and id>0 and tonumber(number)==id
end
function S:Next()
    local p=self.pull
    if not p then return end
    p.parts=nil;p.received=0;p.total=nil
    local item=table.remove(p.items,1)
    if item then
        p.wait=item;p.deadline=GetTime()+90
        self:Enqueue(p.peer,"G",p.token..","..item.index)
    elseif p.cursor>0 then
        p.wait=nil;p.deadline=GetTime()+90
        self:Enqueue(p.peer,"Q",p.token..","..p.cursor)
    else self.pull=nil;self.status="Up to date with "..p.peer end
end
-- Called once by the dedicated event frame, never once per chat window.
function S:Receive(message,sender)
    if not HCDeaths_Settings.sync or not player(sender) or sender==UnitName("player") or type(message)~="string"
        or string.len(message)>240 then return end
    local _,_,target,kind,body=string.find(message,"^HCDS2|([^|]+)|([HOQIGDN])|(.*)$")
    if not target then return end
    local now=GetTime()
    if kind=="O" and self.offer and self.offer.target==target and self.offer.token==body then self.offer=nil end
    if target~="*" and target~=UnitName("player") then return end
    -- Bound work per sender and the total sender cache.
    local rate=self.rates[sender]
    if not rate then
        if self.rateCount>=64 then return end
        rate={time=now,count=0};self.rates[sender]=rate;self.rateCount=self.rateCount+1
    end
    if now-rate.time>=60 then rate.time=now;rate.count=0 end
    rate.count=rate.count+1;if rate.count>90 then return end
    if kind=="H" and target=="*" and string.find(body,"^%d+$") and string.len(body)<=12 then
        if not self.offer and (not self.grant or now>self.grant.untilTime) then self.offer={target=sender,token=body,due=now+2+math.random()*6} end
    elseif kind=="O" and self.discovery and body==self.discovery.token then
        if not self.discovery.peer then self.discovery.peer=sender end
    elseif kind=="Q" or kind=="G" then
        local _,_,token,index=string.find(body,"^(%d+),(%d+)$")
        index=integer(index,0,1000000000)
        if not token or string.len(token)>12 or not index then return end
        -- Only service the peer to which we recently offered synchronization.
        local grant=self.grant
        if not grant or grant.peer~=sender or grant.token~=token or now>grant.untilTime then return end
        grant.untilTime=now+180
        local records=grant.records
        if not records then return end
        if kind=="Q" then
            if index==0 then index=table.getn(records) end
            if index>table.getn(records) then return end
            local entries={};local cursor=index;local scanned=0
            while cursor>0 and table.getn(entries)<4 and scanned<50 do
                scanned=scanned+1
                local r=records[cursor]
                if not (addon.Retention and addon.Retention.removed[r]) and (r.deathType=="PVE" or r.deathType=="PVP") then
                    local data=self:Pack(r)
                    if data and self:Eligible(r) and self:Stamp(r) then table.insert(entries,cursor..":"..self:Fingerprint(data)) end
                end
                cursor=cursor-1
            end
            self:Enqueue(sender,"I",token..","..cursor..","..table.concat(entries,";"))
        else
            local r=records[index]
            if not r or (addon.Retention and addon.Retention.removed[r]) then
                self:Enqueue(sender,"N",token..","..index);return
            end
            if not self:Eligible(r) or (r.deathType~="PVE" and r.deathType~="PVP") then return end
            local data=self:Pack(r);if not data then return end
            local hex=string.gsub(data,".",function(c) return string.format("%02X",string.byte(c)) end)
            local total=math.ceil(string.len(hex)/128)
            if total>64 or table.getn(self.queue)+total>128 then return end
            for part=1,total do
                self:Enqueue(sender,"D",token..","..index..","..part..","..total..","..string.sub(hex,(part-1)*128+1,part*128))
            end
        end
    elseif kind=="I" then
        local p=self.pull
        local _,_,token,cursor,entries=string.find(body,"^(%d+),(%d+),(.*)$")
        cursor=integer(cursor,0,1000000000)
        if not p or p.peer~=sender or token~=p.token or not cursor or p.wait then return end
        if p.requestedCursor and p.requestedCursor>0 and cursor>=p.requestedCursor then return end
        p.cursor=cursor;p.items={}
        local count=0
        for item in string.gfind(entries,"[^;]+") do
            local _,_,index,hash=string.find(item,"^(%d+):(%d+:%d+:%d+)$")
            index=integer(index,1,1000000000);count=count+1
            if count>4 or not index or not hash then self.pull=nil;return end
            if not self.seen[hash] then table.insert(p.items,{index=index,hash=hash}) end
        end
        p.requestedCursor=cursor
        self:Next()
    elseif kind=="N" then
        local p=self.pull
        local _,_,token,index=string.find(body,"^(%d+),(%d+)$")
        if p and p.peer==sender and token==p.token and p.wait and tonumber(index)==p.wait.index then self:Next() end
    elseif kind=="D" then
        local p=self.pull
        local _,_,token,index,part,total,hex=string.find(body,"^(%d+),(%d+),(%d+),(%d+),(%x+)$")
        part=integer(part,1,64);total=integer(total,1,64)
        if not p or sender~=p.peer or token~=p.token or not p.wait or tonumber(index)~=p.wait.index
            or not part or not total or part>total or string.len(hex)>128 or math.mod(string.len(hex),2)~=0 then return end
        if p.total and p.total~=total then return end
        p.parts=p.parts or {};p.total=total
        if not p.parts[part] then p.parts[part]=hex;p.received=p.received+1 end
        p.deadline=now+90
        if p.received==total then
            local all=table.concat(p.parts)
            local data=string.gsub(all,"%x%x",function(pair) return string.char(tonumber(pair,16)) end)
            -- Records can be enriched between their inventory and data replies.
            local r=self:Unpack(data)
            if r then self:Import(r,sender);self:MarkSeen(self:Fingerprint(data)) end
            p.total=nil;self:Next()
        end
    end
end
function S:Tick()
    local now=GetTime()
    if not addon.loaded then return end
    if not HCDeaths_Settings.sync then
        self.queue={};self.pull=nil;self.discovery=nil;self.offer=nil;self.grant=nil
        self.status="Disabled"
        if self.joined and LeaveChannelByName then LeaveChannelByName(self.channel);self.joined=nil end
        return
    end
    if not JoinChannelByName or not GetChannelName or not SendChatMessage then self.status="Channel API unavailable";return end
    if not self.initialized then
        local realm,faction=self:Context()
        if not realm or not faction then self.status="Waiting for player realm/faction";return end
        self.initCursor=self.initCursor or 1
        local stop=math.min(table.getn(HCDeaths),self.initCursor+49)
        for i=self.initCursor,stop do
            local r=HCDeaths[i]
            if not r.realm and not r.faction then r.realm=realm;r.faction=faction;r.originAssumed=true end
            self:Remember(r)
        end
        self.initCursor=stop+1
        if self.initCursor<=table.getn(HCDeaths) then self.status="Indexing saved logs";return end
        self.initialized=true
    end
    local id=GetChannelName(self.channel)
    if not id or id==0 then
        self.status="Waiting for channel"
        if now>=(self.nextJoin or 0) then self.nextJoin=now+60;JoinChannelByName(self.channel);self.joined=true end
        return
    end
    self.joined=true
    if now>=(self.nextClean or 0) then self.rates={};self.rateCount=0;self.nextClean=now+60 end
    if self.grant and now>self.grant.untilTime then self.grant=nil end
    if self.offer and now>=self.offer.due then
        self:Enqueue(self.offer.target,"O",self.offer.token)
        local snapshot={}
        for i,r in ipairs(HCDeaths) do snapshot[i]=r end
        self.grant={peer=self.offer.target,token=self.offer.token,untilTime=now+180,records=snapshot};self.offer=nil
    end
    if self.pull and now>self.pull.deadline then self.pull=nil;self.status="Peer timeout; retrying later" end
    if self.discovery and now>=self.discovery.deadline then
        local d=self.discovery;self.discovery=nil
        if d.peer then
            self.pull={peer=d.peer,token=d.token,cursor=0,items={},deadline=now+90}
            self.status="Syncing with "..d.peer
            self:Enqueue(d.peer,"Q",d.token..",0")
        else self.status="Waiting for other users" end
    end
    if not self.pull and not self.discovery and now>=self.nextHello then
        self.round=self.round+1
        local token=tostring(self.round)..tostring(math.random(10000,99999))
        self.discovery={token=token,deadline=now+15}
        self:Enqueue("*","H",token);self.nextHello=now+300+math.random(0,60)
    end
    if table.getn(self.queue)>0 and now>=(self.nextSend or 0) then
        local msg=table.remove(self.queue,1)
        self.nextSend=now+1.5
        pcall(SendChatMessage,msg,"CHANNEL",nil,id)
    end
end
S.rates={};S.rateCount=0;S.nextHello=GetTime()+20+math.random(0,30)
S.status="Starting"
local frame=CreateFrame("Frame",nil,UIParent)
S.frame=frame
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:SetScript("OnEvent",function()
    if S:IsChannel(arg9,arg8,arg4) then S:Receive(arg1,arg2) end
end)
local elapsed=0
frame:SetScript("OnUpdate",function()
    elapsed=elapsed+(arg1 or 0)
    if elapsed>=0.5 then elapsed=0;S:Tick() end
end)
