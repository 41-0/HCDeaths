-- Unofficial fork: automatic, best-effort same-faction channel synchronization.
-- WoW 1.12 / Lua 5.0. No executable serialization or external libraries.
local addon=HCDeaths_API
if not addon then return end
local S={channel="HCDeathsSyncV2",queue={},seen={},offers={},round=0,stats={},sendInterval=10,capabilities={},announced={},capCount=0,peerDigests={},requests={},requestTimes={}}
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
local function sameName(a,b)
    return type(a)=="string" and type(b)=="string" and string.lower(a)==string.lower(b)
end
local function decodeEnvelope(message)
    if type(message)~="string" then return nil end
    local prefix=string.lower(string.sub(message,1,6))
    local target,kind,body
    local a,b
    if prefix=="hcds2:" then
        a,b,target,kind,body=string.find(message,"^[^:]+:([^:]+):(%a):(.*)$")
    elseif prefix=="hcds2|" then
        -- Receive legacy framing, but never send WoW markup in ordinary chat.
        a,b,target,kind,body=string.find(message,"^[^|]+|([^|]+)|(%a)|(.*)$")
    end
    if not target then return nil end
    kind=string.upper(kind)
    if not string.find("HOQIGDNFVBTRAEWP",kind,1,true) then return nil end
    return target,kind,body
end
function S:BackOff(seconds,reason)
    local now=GetTime()
    local untilTime=now+math.max(30,(tonumber(seconds) or 30)+5)
    local extra=math.max(0,untilTime-math.max(now,self.pauseUntil or 0))
    self.pauseUntil=math.max(self.pauseUntil or 0,untilTime)
    self.nextSend=math.max(self.nextSend or 0,self.pauseUntil)
    self.sendInterval=math.min(60,math.max(10,self.sendInterval or 10)*2)
    if self.pull then
        self.pull.retryAt=(self.pull.retryAt or now)+extra
        self.pull.deadline=(self.pull.deadline or now)+extra
    end
    if self.manualRequest then self.manualRequest.expires=self.manualRequest.expires+extra;self.manualRequest.retryAt=self.manualRequest.retryAt+extra end
    if self.discovery and self.discovery.deadline then self.discovery.deadline=self.discovery.deadline+extra end
    if self.offer then self.offer.due=self.offer.due+extra end
    if self.grant then self.grant.untilTime=self.grant.untilTime+extra end
    self.status="Paused for server chat cooldown";self.wasPaused=true
    self.lastThrottle=reason;self:Count("throttles");self:SaveStatus()
end
function S:HandleThrottle(message)
    if type(message)~="string" then return false end
    local text=string.lower(string.gsub(message,"|c%x%x%x%x%x%x%x%x",""))
    if not string.find(text,"speak",1,true) and not string.find(text,"chat",1,true)
        and not string.find(text,"message",1,true) then return false end
    if string.find(text,"too quickly",1,true) or string.find(text,"too fast",1,true) then
        self:BackOff(60,string.sub(message,1,200));return true
    end
    local _,_,seconds=string.find(text,"you must wait%s+(%d+)%s+seconds?")
    if not seconds and string.find(text,"wait",1,true) and string.find(text,"speak",1,true) then
        _,_,seconds=string.find(text,"(%d+)%s+seconds?")
    end
    if seconds then self:BackOff(seconds,string.sub(message,1,200));return true end
    return false
end
local function bulk(kind) return kind=="D" or kind=="B" end
function S:Advertise(peer)
    local key=string.lower(peer)
    if self.announced[key] and GetTime()-self.announced[key]<300 then return end
    if self.capCount>=64 and not self.capabilities[key] then return end
    self.announced[key]=GetTime();self:Enqueue(peer,"V","C2")
end
-- Lowercase base32 survives chat case folding and uses 20% fewer characters
-- than hexadecimal for the same bytes. No bit library is required on Lua 5.0.
local alphabet="0123456789abcdefghijklmnopqrstuv"
function S:Encode32(data)
    local out={};local buffer,bits=0,0
    for i=1,string.len(data) do
        buffer=buffer*256+string.byte(data,i);bits=bits+8
        while bits>=5 do
            bits=bits-5
            local n=math.floor(buffer/2^bits)
            table.insert(out,string.sub(alphabet,n+1,n+1))
            buffer=math.mod(buffer,2^bits)
        end
    end
    if bits>0 then
        local n=buffer*2^(5-bits);table.insert(out,string.sub(alphabet,n+1,n+1))
    end
    return table.concat(out)
end
function S:Decode32(data)
    local out={};local buffer,bits=0,0
    data=string.lower(data)
    for i=1,string.len(data) do
        local char=string.sub(data,i,i)
        local n=string.find(alphabet,char,1,true)
        if not n then return nil end
        buffer=buffer*32+n-1;bits=bits+5
        if bits>=8 then
            bits=bits-8;local byte=math.floor(buffer/2^bits)
            table.insert(out,string.char(byte));buffer=math.mod(buffer,2^bits)
        end
    end
    local tail=math.mod(string.len(data),8)
    if buffer~=0 or tail==1 or tail==3 or tail==6 then return nil end
    return table.concat(out)
end
function S:PackCompact(r)
    local pieces={"C1:"}
    for i,key in ipairs(fields) do
        local v=r[key]
        if known(v) then
            v=tostring(v)
            if string.len(v)>(key=="lastWords" and 1024 or 160) or string.find(v,"[%z\1-\31]") then return nil end
            table.insert(pieces,i.."="..string.len(v)..":"..v)
        end
    end
    return table.concat(pieces)
end
function S:UnpackCompact(data)
    if string.sub(data,1,3)~="C1:" then return nil,"Invalid compact header" end
    local r={};local seen={};local pos=4
    for _,key in ipairs(fields) do r[key]="Unknown" end
    while pos<=string.len(data) do
        local a,b,index,size=string.find(string.sub(data,pos),"^(%d+)=(%d+):")
        index=integer(index,1,table.getn(fields));size=integer(size,0,1024)
        if not a or not index or not size or seen[index] then return nil,"Invalid compact field" end
        local key=fields[index]
        if size>(key=="lastWords" and 1024 or 160) then return nil,"Compact field too long" end
        b=b+pos-1
        if b+size>string.len(data) then return nil,"Truncated compact value" end
        r[key]=string.sub(data,b+1,b+size);seen[index]=true;pos=b+size+1
    end
    -- Reuse the full-format identity/date/realm/text/coordinate validation.
    local full=self:Pack(r)
    if not full then return nil,"Invalid compact text" end
    return self:Unpack(full)
end
function S:Count(key)
    self.stats[key]=(self.stats[key] or 0)+1
end
function S:ChannelID()
    if not GetChannelName then return 0 end
    local ok,id=pcall(GetChannelName,self.channel)
    if not ok then self.lastError=string.sub(tostring(id),1,300);return 0 end
    return tonumber(id) or 0
end
function S:SaveStatus()
    local stats={}
    for key,value in pairs(self.stats) do stats[key]=value end
    local realm,faction=self:Context()
    HCDeaths_SyncStatus={version="1.5.4-fork",utc=date("!%Y/%m/%d %H:%M:%S"),
        enabled=HCDeaths_Settings.sync and true or false,status=self.status,channel=self.channel,
        channelID=self:ChannelID(),realm=realm,faction=faction,player=UnitName("player"),
        stats=stats,lastError=self.lastError,lastReject=self.lastReject,lastPeer=self.lastPeer,
        lastPacket=self.lastPacket,queue=table.getn(self.queue),
        sendInterval=self.sendInterval,cooldownSeconds=math.max(0,math.ceil((self.pauseUntil or 0)-GetTime())),lastThrottle=self.lastThrottle,
        uiError=self.lastUIError,pendingApprovals=table.getn(self.requests),
        manualRequestPeer=self.manualRequest and self.manualRequest.peer,manualRequestPhase=self.manualRequest and self.manualRequest.phase,
        peer=self.pull and self.pull.peer,cursor=self.pull and self.pull.cursor,
        waitingIndex=self.pull and self.pull.wait and self.pull.wait.index,
        receivedParts=self.pull and self.pull.received,totalParts=self.pull and self.pull.total,
        nextHelloSeconds=math.max(0,math.ceil((self.nextHello or 0)-GetTime()))}
end
function S:Report(check)
    if check then
        self.nextJoin=0
        if not self.pull and not self.discovery then self.nextHello=GetTime() end
        self:SafeTick()
    end
    self:SaveStatus()
    local d=HCDeaths_SyncStatus;local c=d.stats
    addon:print("Sync 1.5.4: "..tostring(d.status).."; enabled="..tostring(d.enabled))
    addon:print("Channel "..d.channel..": id="..d.channelID.."; player="..tostring(d.player).."; realm="..tostring(d.realm).."; faction="..tostring(d.faction))
    addon:print("TX attempted/local OK/errors: "..(c.attempted or 0).."/"..(c.sent or 0).."/"..(c.sendErrors or 0).."; queue="..d.queue)
    addon:print("RX protocol/self echo/peer packets: "..(c.wire or 0).."/"..(c.echo or 0).."/"..(c.peerPackets or 0).."; last peer="..tostring(d.lastPeer or "none"))
    addon:print("Offers/inventory/chunks/decoded/invalid: "..(c.offers or 0).."/"..(c.inventory or 0).."/"..(c.chunks or 0).."/"..(c.decoded or 0).."/"..(c.invalid or 0))
    addon:print("Imported/enriched/filtered: "..(c.imported or 0).."/"..(c.enriched or 0).."/"..(c.filtered or 0))
    addon:print("Retransmissions/timeouts: "..(c.retries or 0).."/"..(c.timeouts or 0).."; waiting record="..tostring(d.waitingIndex or "none").."; parts="..(d.receivedParts or 0).."/"..(d.totalParts or 0))
    addon:print("Send interval: "..d.sendInterval.."+ seconds; cooldown: "..d.cooldownSeconds.." seconds; server throttles: "..(c.throttles or 0))
    addon:print("Compact records received: "..(c.compactRecords or 0).."; peer compact format: "..tostring(self.lastPeer and self.capabilities[string.lower(self.lastPeer)] or "not negotiated"))
    addon:print("Approvals pending: "..d.pendingApprovals.."; request: "..tostring(d.manualRequestPeer or "none").."; phase: "..tostring(d.manualRequestPhase or "none"))
    if d.uiError then addon:print("Approval/status UI error: "..d.uiError) end
    local shareable,total=0,0
    for _,r in ipairs(HCDeaths) do
        if r.deathType=="PVE" or r.deathType=="PVP" then
            total=total+1
            if self:Eligible(r) and self:Stamp(r) and self:Pack(r) then shareable=shareable+1 end
        end
    end
    addon:print("Shareable saved deaths: "..shareable.."/"..total.."; next discovery in "..d.nextHelloSeconds.." seconds (unless syncing)")
    if d.lastError then addon:print("Last sync error: "..d.lastError) end
    if d.lastReject then addon:print("Last rejected packet: "..d.lastReject) end
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
    self:ReconcileUnknown(r)
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
        if not a then return nil,"Missing field length: "..key end
        local size=integer(length,0,key=="lastWords" and 1024 or 160)
        if not size or b+size>string.len(data) then return nil,"Invalid field size: "..key end
        local v=string.sub(data,b+1,b+size)
        if string.find(v,"[%z\1-\31]") or string.find(v,"|") then return nil,"Unsupported field text: "..key end
        r[key]=v;pos=b+size+1
    end
    if pos~=string.len(data)+1 or not player(r.playerName) or not integer(r.playerLevel,1,60)
        or (r.deathType~="PVE" and r.deathType~="PVP") or not self:Stamp(r) or not self:Eligible(r) then return nil,"Invalid identity, date, realm or faction" end
    if known(r.gravePositionKind) and not self:ValidGrave(r) then return nil,"Invalid grave coordinate bundle" end
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
-- Grave observations never supply a death time. Compare shared semantic facts,
-- not visit timestamps, observer coordinates or /who's differently scoped zone.
local reconcileFields={"playerName","playerLevel","playerClass","playerRace","playerGuild",
    "killerName","killerLevel","killerClass","killerRace","killerGuild","lastWords","location","realm","faction","hcType"}
local numericIdentity={playerLevel=true,killerLevel=true}
function S:UnknownMatches(observation,dated)
    if not observation.deathTimeUnknown or (dated.deathType~="PVE" and dated.deathType~="PVP") then return false end
    if string.lower(observation.playerName or "")~=string.lower(dated.playerName or "")
        or tonumber(observation.playerLevel)~=tonumber(dated.playerLevel) then return false end
    local realm,faction=self:Context()
    local function value(record,key)
        local v=record[key]
        if record==dated and not known(v) then
            if key=="realm" then return realm elseif key=="faction" then return faction end
        end
        return v
    end
    for _,key in ipairs({"playerName","playerLevel","killerName","killerLevel","realm","faction"}) do
        if not known(value(observation,key)) or not known(value(dated,key)) or value(observation,key)=="" or value(dated,key)=="" then return false end
    end
    for _,key in ipairs(reconcileFields) do
        local a,b=value(observation,key),value(dated,key)
        if known(a) and known(b) then
            if numericIdentity[key] then
                if not tonumber(a) or tonumber(a)~=tonumber(b) then return false end
            elseif key=="lastWords" then
                if tostring(a)~=tostring(b) then return false end
            elseif string.lower(tostring(a))~=string.lower(tostring(b)) then return false end
        end
    end
    if not self:Stamp(dated) then return false end
    if observation.deathType~="UNKNOWN" and known(observation.deathType) and observation.deathType~=dated.deathType then return false end
    -- A grave cannot belong to a later death. Receipt-time clock differences can
    -- conservatively leave an observation separate rather than guess a match.
    local _,_,day,clock=string.find(observation.firstInspectedAt or "","^(%d%d%d%d/%d%d/%d%d) (%d%d:%d%d:%d%d)$")
    local inspected=day and self:Stamp({sdate=day,stime=clock})
    if inspected and self:Stamp(dated)>inspected then return false end
    return true
end
function S:ReconcileUnknown(dated)
    if not HCDeaths_UnknownDeaths or table.getn(HCDeaths_UnknownDeaths)==0 or not self:Stamp(dated) then return false end
    local found,index
    for i,r in ipairs(HCDeaths_UnknownDeaths) do
        if self:UnknownMatches(r,dated) then
            if found then return false end
            found=r;index=i
        end
    end
    if not found then return false end
    local candidate,count=nil,0
    for _,r in ipairs(HCDeaths) do
        if self:UnknownMatches(found,r) then candidate=r;count=count+1 end
    end
    if count~=1 or candidate~=dated then return false end
    -- Preserve data before deleting the unknown-date observation.
    self:Merge(dated,found,false)
    if found.firstInspectedAt and (not dated.firstInspectedAt or found.firstInspectedAt<dated.firstInspectedAt) then dated.firstInspectedAt=found.firstInspectedAt end
    if found.lastInspectedAt and (not dated.lastInspectedAt or found.lastInspectedAt>dated.lastInspectedAt) then dated.lastInspectedAt=found.lastInspectedAt end
    dated.reconciledGrave=true
    table.remove(HCDeaths_UnknownDeaths,index)
    self:Count("reconciledGraves")
    return true
end
function S:ReconcileSavedGraves()
    if not HCDeaths_UnknownDeaths or table.getn(HCDeaths_UnknownDeaths)==0 then return end
    for _,r in ipairs(HCDeaths) do
        if self:ReconcileUnknown(r) then self:Remember(r) end
    end
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
    if not old and addon.Retention and not addon.Retention:AllowImported(r) then self:Count("filtered");return end
    if old then
        if self:Merge(old,r,false) then self:Count("enriched");old.sharedDetails=true;old.detailsSource=sender end
        self:Remember(old)
        if addon.RefreshToastLastWords then addon:RefreshToastLastWords(old) end
    else self:Count("imported");r.shared=true;r.sourcePlayer=sender;table.insert(HCDeaths,r);self:Remember(r) end
    if addon.Retention then addon.Retention:Enforce() end
    addon:updateLog() -- Imported history never enters the toast or /who queues.
end
function S:Enqueue(target,kind,body)
    local msg="HCDS2:"..target..":"..kind..":"..body
    if string.len(msg)>240 or table.getn(self.queue)>=128 then return false end
    for _,queued in ipairs(self.queue) do if queued==msg then return true end end
    -- Prioritize handshakes and requests over bulk data fragments.
    if not bulk(kind) then
        for i,queued in ipairs(self.queue) do
            local destination,queuedKind=decodeEnvelope(queued)
            if bulk(queuedKind) then table.insert(self.queue,i,msg);return true end
        end
    end
    table.insert(self.queue,msg);return true
end
function S:IsChannel(name,number,full)
    if type(name)=="string" and string.lower(name)==string.lower(self.channel) then return true end
    if type(full)=="string" and string.find(string.lower(full),"^%d+%. "..string.lower(self.channel).."$") then return true end
    local id=self:ChannelID()
    return id>0 and tonumber(number)==id
end
function S:Next()
    local p=self.pull
    if not p then return end
    p.parts=nil;p.received=0;p.total=nil;p.dataKind=nil;p.retries=0;p.retryAt=GetTime()+90
    local item=table.remove(p.items,1)
    if item then
        p.wait=item;p.deadline=GetTime()+90
        self:Enqueue(p.peer,"G",p.token..","..item.index)
    elseif p.cursor>0 then
        p.wait=nil;p.deadline=GetTime()+90
        self:Enqueue(p.peer,"Q",p.token..","..p.cursor)
    else self.lastTransfer={peer=p.peer,reviewed=p.reviewed or 0,downloaded=p.downloaded or 0,completed=true};if p.full then self:HistoryFeedback("Full history completed with "..p.peer..". Downloaded "..(p.downloaded or 0).." entries.","success") end;if p.digest then self.peerDigests[string.lower(p.peer)]=p.digest end;self:Enqueue(p.peer,"F",p.token);self.pull=nil;self.status="Up to date with "..p.peer end
end
function S:RetryPull(now)
    local p=self.pull
    if not p or now<(p.retryAt or p.deadline) then return end
    -- A request still waiting for our send slot is not a lost packet.
    for _,message in ipairs(self.queue) do
        local target,kind,body=decodeEnvelope(message)
        if sameName(target,p.peer) then
            local a,b,token,index=string.find(body,"^(%d+),(%d+)")
            if (p.wait and kind=="G" and token==p.token and tonumber(index)==p.wait.index)
                or (not p.wait and kind=="Q" and body==p.token..","..p.cursor) then
                p.retryAt=now+90;return
            end
        end
    end
    if (p.retries or 0)>=3 then
        self:Count("timeouts");self:Enqueue(p.peer,"F",p.token);self.pull=nil;self.status="Peer timeout after retries; trying later";if p.full then self:HistoryFeedback("Transfer stopped: the sender did not respond after retries. Entries already received are saved. Try again later.","error") end;return
    end
    p.retries=(p.retries or 0)+1;p.retryAt=now+90;p.deadline=now+90
    self:Count("retries")
    if p.wait then
        local body=p.token..","..p.wait.index
        if p.total then
            local mask={}
            for group=0,15 do
                local bits=0
                for bit=0,3 do
                    local part=group*4+bit+1
                    if part<=p.total and not (p.parts and p.parts[part]) then bits=bits+2^bit end
                end
                table.insert(mask,string.format("%X",bits))
            end
            body=body..","..table.concat(mask)
        end
        self:Enqueue(p.peer,"G",body)
    else self:Enqueue(p.peer,"Q",p.token..","..p.cursor) end
end
-- Called once by the dedicated event frame, never once per chat window.
function S:Receive(message,sender)
    if not HCDeaths_Settings.sync or type(message)~="string" or string.len(message)>240 then return end
    local target,kind,body=decodeEnvelope(message)
    if not target then
        if string.find(string.lower(message),"^hcds") then self:Count("incompatible");self.lastReject="Unrecognized protocol/framing" end
        return
    end
    self:Count("wire")
    if sameName(sender,UnitName("player")) then self:Count("echo");return end
    if not player(sender) then self:Count("rejectedSender");self.lastReject="Invalid sender name: "..string.sub(tostring(sender),1,80);return end
    local now=GetTime()
    local _,_,summaryToken,summaryDigest=string.find(body,"^(%d+),(%d+:%d+:%d+)$")
    if (kind=="O" or kind=="T") and self.offer and sameName(self.offer.target,target) and self.offer.token==(kind=="T" and summaryToken or body) then self.offer=nil end
    if target~="*" and not sameName(target,UnitName("player")) then return end
    self:Count("peerPackets");self.lastPeer=sender;self.lastPacket=kind
    -- Bound work per sender and the total sender cache.
    local rate=self.rates[sender]
    if not rate then
        if self.rateCount>=64 then return end
        rate={time=now,count=0};self.rates[sender]=rate;self.rateCount=self.rateCount+1
    end
    if now-rate.time>=60 then rate.time=now;rate.count=0 end
    rate.count=rate.count+1;if rate.count>90 then return end
    if kind=="H" and target=="*" and string.find(body,"^%d+$") and string.len(body)<=12 then
        self:Advertise(sender)
        if not self.offer and (not self.grant or now>self.grant.untilTime) then self.offer={target=sender,token=body,due=now+2+math.random()*6} end
    elseif kind=="V" and (string.upper(body)=="C1" or string.upper(body)=="C2") then
        local key=string.lower(sender)
        if self.capabilities[key] or self.capCount<64 then
            if not self.capabilities[key] then self.capCount=self.capCount+1 end
            self.capabilities[key]=string.upper(body);self:Advertise(sender)
        end
    elseif (kind=="O" or kind=="T") and self.discovery and (kind=="T" and summaryToken or body)==self.discovery.token then
        self:Count("offers")
        if not self.discovery.peer then self.discovery.peer=sender;self.discovery.digest=kind=="T" and summaryDigest or nil;self.discovery.deadline=now end
    elseif kind=="W" then
        local r=self.manualRequest
        if r and sameName(r.peer,sender) and r.token==body then r.acknowledged=true;r.phase="Delivered; waiting for sender approval";r.retryAt=now+120 end
    elseif kind=="P" then
        local _,_,token,count=string.find(body,"^(%d+),(%d+)$")
        local p=self.pull
        if p and sameName(p.peer,sender) and p.token==token then p.totalRecords=integer(count,0,1000000000) end
    elseif kind=="R" or kind=="A" or kind=="E" then
        self:ManualReceive(kind,body,sender,now)
    elseif kind=="F" then
        self:DropPending(sender,body)
        if self.manualRequest and sameName(self.manualRequest.peer,sender) and self.manualRequest.token==body then self.manualRequest=nil;self:HistoryFeedback("Request cancelled by the sender.","warning") end
        if self.pull and self.pull.full and sameName(self.pull.peer,sender) and self.pull.token==body then self.pull=nil;self:HistoryFeedback("Full-history transfer cancelled by the sender.","warning") end
        if self.grant and sameName(self.grant.peer,sender) and self.grant.token==body then
            self.grant=nil
            for i=table.getn(self.queue),1,-1 do
                local target,k,payload=decodeEnvelope(self.queue[i])
                if sameName(target,sender) and bulk(k) and string.sub(payload,1,string.len(body)+1)==body.."," then table.remove(self.queue,i) end
            end
        end
    elseif kind=="Q" or kind=="G" then
        local _,_,token,index,missing=string.find(body,"^(%d+),(%d+),(%x+)$")
        if not token then _,_,token,index=string.find(body,"^(%d+),(%d+)$") end
        if missing and (kind~="G" or string.len(missing)~=16) then return end
        index=integer(index,0,1000000000)
        if not token or string.len(token)>12 or not index then return end
        -- Only service the peer to which we recently offered synchronization.
        local grant=self.grant
        if not grant or not sameName(grant.peer,sender) or grant.token~=token or now>grant.untilTime then return end
        grant.untilTime=now+600
        local records=grant.records
        if not records then return end
        if kind=="Q" then
            if index==0 then index=table.getn(records) end
            if index>table.getn(records) then return end
            local entries={};local cursor=index;local scanned=0
            local pageSize=self.capabilities[string.lower(sender)]=="C2" and 6 or 4
            while cursor>0 and table.getn(entries)<pageSize and scanned<50 do
                scanned=scanned+1
                local r=records[cursor]
                if not (addon.Retention and addon.Retention.removed[r]) and (r.deathType=="PVE" or r.deathType=="PVP") then
                    local data=self:Pack(r)
                    if data and self:Eligible(r) and self:Stamp(r) then
                        local entry=cursor..":"..self:Fingerprint(data)
                        local candidate=table.concat(entries,";")..(table.getn(entries)>0 and ";" or "")..entry
                        if string.len("HCDS2:"..sender..":I:"..token..","..cursor..","..candidate)>240 then break end
                        table.insert(entries,entry)
                    end
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
            local cache=grant.dataCache
            if not cache or cache.index~=index then
                if missing then self:Enqueue(sender,"N",token..","..index);return end
                local compact=self.capabilities[string.lower(sender)]~=nil
                local data=compact and self:PackCompact(r) or self:Pack(r)
                if not data then return end
                local kind=compact and "B" or "D"
                local encoded
                if compact then encoded=self:Encode32(data)
                else encoded=string.gsub(data,".",function(c) return string.format("%02X",string.byte(c)) end) end
                local size=128
                if compact then
                    local header="HCDS2:"..sender..":"..kind..":"..token..","..index..",64,64,"
                    size=math.floor(math.min(192,240-string.len(header))/2)*2
                end
                cache={index=index,wire=encoded,size=size,kind=kind,total=math.ceil(string.len(encoded)/size)}
                if cache.total>64 then return end
                grant.dataCache=cache;grant.served=(grant.served or 0)+1
            end
            for part=1,cache.total do
                local wanted=not missing
                if missing then
                    local nibble=tonumber(string.sub(missing,math.ceil(part/4),math.ceil(part/4)),16)
                    wanted=math.mod(math.floor(nibble/2^math.mod(part-1,4)),2)==1
                end
                if wanted then
                    local payload=token..","..index..","..part..","..cache.total..","..string.sub(cache.wire,(part-1)*cache.size+1,part*cache.size)
                    local queued=false
                    for _,message in ipairs(self.queue) do
                        local dest,k,b=decodeEnvelope(message)
                        if sameName(dest,sender) and k==cache.kind and b==payload then queued=true;break end
                    end
                    if not queued then self:Enqueue(sender,cache.kind,payload) end
                end
            end
        end
    elseif kind=="I" then
        local p=self.pull
        local _,_,token,cursor,entries=string.find(body,"^(%d+),(%d+),(.*)$")
        cursor=integer(cursor,0,1000000000)
        if not p or not sameName(p.peer,sender) or token~=p.token or not cursor or p.wait then return end
        if p.requestedCursor and p.requestedCursor>0 and cursor>=p.requestedCursor then return end
        self:Count("inventory")
        p.cursor=cursor;p.items={};p.totalRecords=p.totalRecords or cursor
        local count=0
        for item in string.gfind(entries,"[^;]+") do
            local _,_,index,hash=string.find(item,"^(%d+):(%d+:%d+:%d+)$")
            index=integer(index,1,1000000000);count=count+1
            if count>(self.capabilities[string.lower(sender)]=="C2" and 6 or 4) or not index or not hash then self.pull=nil;return end
            p.totalRecords=math.max(p.totalRecords or 0,index)
            p.reviewed=(p.reviewed or 0)+1
            if (p.full or p.reviewed<=100) and not self.seen[hash] then table.insert(p.items,{index=index,hash=hash}) end
        end
        if not p.full then
            p.totalRecords=math.min(100,p.totalRecords or 100)
            if (p.reviewed or 0)>=100 then p.cursor=0;p.reviewed=100 end
        end
        p.requestedCursor=cursor
        self:Next()
    elseif kind=="N" then
        local p=self.pull
        local _,_,token,index=string.find(body,"^(%d+),(%d+)$")
        if p and sameName(p.peer,sender) and token==p.token and p.wait and tonumber(index)==p.wait.index then p.digest=nil;self:Next() end
    elseif bulk(kind) then
        local p=self.pull
        local _,_,token,index,part,total,hex=string.find(body,"^(%d+),(%d+),(%d+),(%d+),(%w+)$")
        part=integer(part,1,64);total=integer(total,1,64)
        if not p or not sameName(sender,p.peer) or token~=p.token or not p.wait or tonumber(index)~=p.wait.index
            or not part or not total or part>total or string.len(hex)>(kind=="B" and 192 or 128) or (kind=="D" and (math.mod(string.len(hex),2)~=0 or string.find(hex,"[^%x]"))) then return end
        if p.total and (p.total~=total or p.dataKind~=kind) then return end
        p.dataKind=kind
        self:Count("chunks")
        p.parts=p.parts or {};p.total=total
        if not p.parts[part] then
            p.parts[part]=hex;p.received=p.received+1
            p.deadline=now+90;p.retryAt=now+90
        end
        if p.received==total then
            local all=table.concat(p.parts)
            local data
            if kind=="B" then data=self:Decode32(all)
            else data=string.gsub(all,"%x%x",function(pair) return string.char(tonumber(pair,16)) end) end
            -- Records can be enriched between their inventory and data replies.
            local r,reason
            if kind=="B" then
                if data then r,reason=self:UnpackCompact(data) else reason="Invalid compact base32" end
            else r,reason=self:Unpack(data) end
            if r then
                self:Count("decoded");if kind=="B" then self:Count("compactRecords") end
                p.downloaded=(p.downloaded or 0)+1;self:Import(r,sender);if p.wait.hash then self:MarkSeen(p.wait.hash) end
                local full=self:Pack(r);if full then self:MarkSeen(self:Fingerprint(full)) end
            else p.digest=nil;self:Count("invalid");self.lastReject=reason or "Invalid record data" end
            p.total=nil;self:Next()
        end
    end
end

-- Snapshot indices are private to one grant. Automatic grants can never expose
-- records outside the newest 100, even if a peer guesses an index.
function S:Snapshot(full)
    local rows={}
    for i,r in ipairs(HCDeaths) do
        local stamp=self:Stamp(r)
        if stamp and self:Eligible(r) and (r.deathType=="PVE" or r.deathType=="PVP")
            and not (addon.Retention and addon.Retention.removed[r]) and self:Pack(r) then
            table.insert(rows,{record=r,stamp=stamp,index=i})
        end
    end
    table.sort(rows,function(a,b) if a.stamp==b.stamp then return a.index<b.index end return a.stamp<b.stamp end)
    local records,hashes={},{}
    local first=full and 1 or math.max(1,table.getn(rows)-99)
    for i=first,table.getn(rows) do
        table.insert(records,rows[i].record)
        table.insert(hashes,self:Fingerprint(self:Pack(rows[i].record)))
    end
    return records,self:Fingerprint(table.concat(hashes,";"))
end
function S:DropPending(peer,token)
    for i=table.getn(self.requests),1,-1 do
        local r=self.requests[i]
        if sameName(peer,r.peer) and token==r.token then table.remove(self.requests,i) end
    end
end
function S:InCombat()
    if not UnitAffectingCombat then return false end
    local value=UnitAffectingCombat("player")
    return value==true or value==1 or value=="1"
end
function S:HistoryFeedback(message,kind)
    self.manualStatus=message
    self.historyFeedback={message=message,kind=kind or "info"}
end
function S:RequestHistory(peer)
    local function fail(reason)
        self:HistoryFeedback("Request not sent: "..reason,"error");return false
    end
    if not HCDeaths_Settings.sync then return fail("Enable log sharing first.") end
    if type(peer)=="string" then peer=string.gsub(peer,"^%s*(.-)%s*$","%1") end
    if not player(peer) or sameName(peer,UnitName("player")) then return fail("Enter another player's character name.") end
    if self.manualRequest or (self.pull and self.pull.full) then return fail("A full-history request or transfer is already active. You can keep playing.") end
    if GetTime()<(self.nextManual or 0) then
        return fail("Please wait "..math.ceil(self.nextManual-GetTime()).." seconds before requesting again.")
    end
    if not SendChatMessage or not JoinChannelByName or not GetChannelName then return fail("Chat channel API is unavailable.") end
    if table.getn(self.queue)>124 then return fail("The send queue is full. Please try again later.") end
    if self.pull then self:Enqueue(self.pull.peer,"F",self.pull.token);self.pull=nil end
    if self.discovery then
        local token=self.discovery.token
        for i=table.getn(self.queue),1,-1 do
            local target,kind,body=decodeEnvelope(self.queue[i])
            if kind=="H" and body==token then table.remove(self.queue,i) end
        end
        self.discovery=nil
    end
    self.round=self.round+1
    local token=tostring(self.round)..tostring(math.random(10000,99999))
    self:Advertise(peer)
    if not self:Enqueue(peer,"R",token) then return fail("Could not queue the request. Please try again later.") end
    self.manualRequest={peer=peer,token=token,expires=GetTime()+600,retries=0,retryAt=GetTime()+90,phase="Queued; waiting for a send slot"}
    self.nextManual=GetTime()+300
    self:HistoryFeedback("Request queued for "..peer..". Delivery and approval may take several minutes. You can close this window and keep playing; the request continues in the background.","info")
    return true
end
function S:ManualReceive(kind,token,peer,now)
    if not string.find(token,"^%d+$") or string.len(token)>12 then return end
    if kind=="R" then
        local key=string.lower(peer)
        -- The dedicated R action is itself a feature probe. A lost capability
        -- advertisement must not silently discard an explicit consent request.
        if self.grant and self.grant.full and sameName(self.grant.peer,peer) and self.grant.token==token then
            self:Enqueue(peer,"A",token);return
        end
        for _,r in ipairs(self.requests) do
            if sameName(r.peer,peer) then
                if r.token==token then self:Enqueue(peer,"W",token) end
                return
            end
        end
        if now<(self.requestTimes[key] or 0) or table.getn(self.requests)>=5 then self:Enqueue(peer,"E",token);return end
        local tracked=0;for name in pairs(self.requestTimes) do tracked=tracked+1 end
        if not self.requestTimes[key] and tracked>=64 then self:Enqueue(peer,"E",token);return end
        self.requestTimes[key]=now+300
        table.insert(self.requests,{peer=peer,token=token,expires=now+600})
        self:Enqueue(peer,"W",token)
        if self.RefreshHistoryUI then self:RefreshHistoryUI() end
    elseif self.manualRequest and sameName(peer,self.manualRequest.peer) and token==self.manualRequest.token then
        if kind=="A" and now<=self.manualRequest.expires then
            self.pull={peer=peer,token=token,full=true,cursor=0,items={},deadline=now+90,retryAt=now+90,retries=0}
            self:Enqueue(peer,"Q",token..",0");self.status="Receiving full history from "..peer
            self:HistoryFeedback("Approved by "..peer..". Receiving history in the background; you can keep playing.","success")
        else self:HistoryFeedback("Request unsuccessful: the sender declined, was unavailable, or the request expired.","error") end
        self.manualRequest=nil
    end
end
function S:DecideHistory(allow)
    local r=self.requests[1]
    if not r then return end
    if allow then
        if self:InCombat() then return end
        if not HCDeaths_Settings.sync or GetTime()>r.expires then return end
        if self.grant and self.grant.full then self.manualStatus="Currently sending full history; please wait";return end
        if self.grant then
            local old=self.grant
            for i=table.getn(self.queue),1,-1 do
                local target,kind,body=decodeEnvelope(self.queue[i])
                if sameName(target,old.peer) and (body==old.token or string.sub(body,1,string.len(old.token)+1)==old.token..",") then table.remove(self.queue,i) end
            end
            self:Enqueue(old.peer,"F",old.token);self.grant=nil
        end
        local records=self:Snapshot(true)
        self.grant={peer=r.peer,token=r.token,records=records,full=true,untilTime=GetTime()+600}
        self:Enqueue(r.peer,"A",r.token);self:Enqueue(r.peer,"P",r.token..","..table.getn(records))
    else self:Enqueue(r.peer,"E",r.token) end
    table.remove(self.requests,1)
end
function S:CancelHistory()
    local r=self.manualRequest or (self.pull and self.pull.full and self.pull) or (self.grant and self.grant.full and self.grant)
    if r then
        for i=table.getn(self.queue),1,-1 do
            local target,kind,body=decodeEnvelope(self.queue[i])
            if sameName(target,r.peer) and (body==r.token or string.sub(body,1,string.len(r.token)+1)==r.token..",") then table.remove(self.queue,i) end
        end
        self:Enqueue(r.peer,"F",r.token)
        if self.manualRequest==r then self.manualRequest=nil end
        if self.pull==r then self.pull=nil end
        if self.grant==r then self.grant=nil end
        self:HistoryFeedback("Full-history request or transfer cancelled.","warning")
    end
end
function S:ManualTick(now)
    for peer,expires in pairs(self.requestTimes) do if now>expires then self.requestTimes[peer]=nil end end
    for i=table.getn(self.requests),1,-1 do
        local r=self.requests[i]
        if now>r.expires then self:Enqueue(r.peer,"E",r.token);table.remove(self.requests,i) end
    end
    local request=self.manualRequest
    if request and now>=(request.retryAt or 0) and now<request.expires then
        local queued=false
        for _,msg in ipairs(self.queue) do
            local target,kind,body=decodeEnvelope(msg)
            if kind=="R" and body==request.token and sameName(target,request.peer) then queued=true end
        end
        if not queued and request.retries<3 then
            request.retries=request.retries+1;self:Enqueue(request.peer,"R",request.token)
            request.phase=(request.acknowledged and "Checking approval reply; retry " or "No acknowledgment yet; retry ")..request.retries.." / 3"
        end
        request.retryAt=now+90
    end
    if self.manualRequest and now>self.manualRequest.expires then
        self:CancelHistory();self:HistoryFeedback("Request expired: no approval arrived within the waiting period. The player may be offline or using an older version. Try again later.","error")
    end
    if self.RefreshHistoryUI then
        local ok,err=pcall(self.RefreshHistoryUI,self)
        if not ok then self.lastUIError=tostring(err) end
    end
end
function S:ProgressText()
    local lines={self.status or "Starting"}
    local r=self.manualRequest
    if r then table.insert(lines,"Full history: "..r.peer.." - "..(r.phase or "Waiting")) end
    local p=self.pull
    if p then
        local checked=math.max(0,(p.reviewed or 0)-table.getn(p.items or {})-(p.wait and 1 or 0))
        table.insert(lines,(p.full and "Full history" or "Recent 100").." from "..p.peer..": checked "..checked.." / "..tostring(p.totalRecords or "?")..", downloaded "..(p.downloaded or 0))
        if p.wait then table.insert(lines,"Current entry: fragments "..(p.received or 0).." / "..tostring(p.total or "?")) end
    elseif self.lastTransfer then
        local t=self.lastTransfer;table.insert(lines,"Last completed: "..t.peer.." - checked "..t.reviewed..", downloaded "..t.downloaded)
    end
    if self.grant then table.insert(lines,"Sending "..(self.grant.full and "full history" or "recent history").." to "..self.grant.peer..": "..(self.grant.served or 0).." / "..table.getn(self.grant.records).." entries requested") end
    if self.manualStatus then table.insert(lines,self.manualStatus) end
    table.insert(lines,"Pending approvals: "..table.getn(self.requests)..(self:InCombat() and " (notification deferred during combat)" or ""))
    table.insert(lines,"Queue: "..table.getn(self.queue).." packets; next send in "..math.max(0,math.ceil(math.max(self.nextSend or 0,self.pauseUntil or 0)-GetTime())).."s")
    table.insert(lines,"Imported: "..(self.stats.imported or 0).."; enriched: "..(self.stats.enriched or 0).."; filtered: "..(self.stats.filtered or 0))
    if self.lastUIError then table.insert(lines,"UI error: "..self.lastUIError) end
    return table.concat(lines,"\n")
end

function S:Tick()
    local now=GetTime()
    if not addon.loaded then return end
    self:ManualTick(now)
    if not HCDeaths_Settings.sync then
        self.requests={};self.manualRequest=nil
        if self.approvalFrame then self.approvalFrame:Hide() end
        self.queue={};self.pull=nil;self.discovery=nil;self.offer=nil;self.grant=nil
        self.status="Disabled"
        if self.joined and LeaveChannelByName then LeaveChannelByName(self.channel);self.joined=nil end
        return
    end
    if now<(self.pauseUntil or 0) then self.status="Paused for server chat cooldown";return end
    if self.wasPaused then
        self.wasPaused=nil;self.status=self.pull and "Syncing with "..self.pull.peer or "Resuming after chat cooldown"
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
    local id=self:ChannelID()
    if id==0 then
        self.status="Waiting for channel"
        if now>=(self.nextJoin or 0) then
            self.nextJoin=now+60;self:Count("joinAttempts")
            local ok,err=pcall(JoinChannelByName,self.channel)
            if ok then self.joined=true else self.lastError=string.sub(tostring(err),1,300);self.status="Channel join failed" end
        end
        return
    end
    self.joined=true
    if now>=(self.nextClean or 0) then self.rates={};self.rateCount=0;self.nextClean=now+60 end
    if self.grant and now>self.grant.untilTime then self.grant=nil end
    if self.offer and now>=self.offer.due then
        local snapshot,digest=self:Snapshot(false)
        if self.capabilities[string.lower(self.offer.target)]=="C2" then
            self:Enqueue(self.offer.target,"T",self.offer.token..","..digest)
        else self:Enqueue(self.offer.target,"O",self.offer.token) end
        self.grant={peer=self.offer.target,token=self.offer.token,untilTime=now+600,records=snapshot};self.offer=nil
    end
    self:RetryPull(now)
    if self.discovery and self.discovery.deadline and now>=self.discovery.deadline then
        local d=self.discovery;self.discovery=nil
        if d.peer and d.digest and self.peerDigests[string.lower(d.peer)]==d.digest then
            self:Enqueue(d.peer,"F",d.token);self.status="Recent logs unchanged with "..d.peer;self:Count("unchanged")
        elseif d.peer then
            self.pull={digest=d.digest,peer=d.peer,token=d.token,cursor=0,items={},deadline=now+90,retries=0,retryAt=now+25}
            self.status="Syncing with "..d.peer
            self:Enqueue(d.peer,"Q",d.token..",0")
        else self.status="Waiting for other users" end
    end
    if not self.pull and not self.discovery and not self.manualRequest and now>=self.nextHello then
        self.round=self.round+1
        local token=tostring(self.round)..tostring(math.random(10000,99999))
        self.discovery={token=token}
        self:Enqueue("*","H",token);self.nextHello=now+600+math.random(0,120)
    end
    if table.getn(self.queue)>0 and now>=(self.nextSend or 0) then
        local msg=self.queue[1]
        self.nextSend=now+self.sendInterval+math.random()*2;self:Count("attempted")
        local ok,err=pcall(SendChatMessage,msg,"CHANNEL",nil,id)
        if ok then
            self:Count("sent");table.remove(self.queue,1);self.sendFailures=0
            local target,kind,body=decodeEnvelope(msg)
            if kind=="R" and self.manualRequest and self.manualRequest.token==body then
                self.manualRequest.phase="Sent; waiting for delivery acknowledgment";self.manualRequest.retryAt=now+90
            end
            if kind=="H" and self.discovery and self.discovery.token==body then self.discovery.deadline=now+90 end
            if bulk(kind) and self.grant then self.grant.untilTime=math.max(self.grant.untilTime,now+600) end
        else
            self:Count("sendErrors");self.lastError=string.sub(tostring(err),1,300)
            if self.manualRequest then self:HistoryFeedback("Delivery delayed: channel send failed. Retrying automatically; you can keep playing.","warning") end
            self.status="Channel send failed";self.nextSend=now+math.max(15,self.sendInterval)
            self.sendFailures=(self.sendFailures or 0)+1
            if self.sendFailures>=3 then table.remove(self.queue,1);self.sendFailures=0 end
            self:SaveStatus()
        end
    end
end
function S:SafeTick()
    local ok,err=pcall(self.Tick,self)
    if not ok then
        self:Count("runtimeErrors");self.status="Sync runtime error"
        self.lastError=string.sub(tostring(err),1,300)
    end
    if not self.nextStatus or GetTime()>=self.nextStatus or not ok then
        self.nextStatus=GetTime()+30;self:SaveStatus()
    end
end
S.rates={};S.rateCount=0;S.nextHello=GetTime()+20+math.random(0,30)
S.status="Starting"
local frame=CreateFrame("Frame",nil,UIParent)
S.frame=frame
for _,e in ipairs({"CHAT_MSG_CHANNEL","CHAT_MSG_CHANNEL_NOTICE","CHAT_MSG_SYSTEM","UI_ERROR_MESSAGE",
    "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_GUILD","CHAT_MSG_OFFICER","CHAT_MSG_PARTY",
    "CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_WHISPER_INFORM"}) do frame:RegisterEvent(e) end
frame:SetScript("OnEvent",function()
    local function receiveEvent()
        if not addon.loaded or not HCDeaths_Settings.sync then return end
        if event=="CHAT_MSG_SYSTEM" or event=="UI_ERROR_MESSAGE" then S:HandleThrottle(arg1);return end
        local channel=S:IsChannel(arg9,arg8,arg4)
        if event=="CHAT_MSG_CHANNEL_NOTICE" then
            if channel and arg1=="THROTTLED" then S:BackOff(60,"Channel THROTTLED notice") end
            return
        end
        if event=="CHAT_MSG_CHANNEL" and channel then S:Receive(arg1,arg2);return end
        -- Leave quiet time for the player's normal speech and other ordinary-chat
        -- traffic sent by that player. Never replace/hook the global send API.
        if event=="CHAT_MSG_WHISPER_INFORM" or sameName(arg2,UnitName("player")) then
            S.nextSend=math.max(S.nextSend or 0,GetTime()+10)
        end
    end
    local ok,err=pcall(receiveEvent)
    if not ok then S:Count("runtimeErrors");S.lastError=string.sub(tostring(err),1,300);S.status="Sync receive error";S:SaveStatus() end
end)
local elapsed=0
frame:SetScript("OnUpdate",function()
    elapsed=elapsed+(arg1 or 0)
    if elapsed>=0.5 then elapsed=0;S:SafeTick() end
end)
