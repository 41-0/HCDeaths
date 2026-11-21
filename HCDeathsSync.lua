-- Unofficial fork: automatic, best-effort same-faction channel synchronization.
-- WoW 1.12 / Lua 5.0. No executable serialization or external libraries.
local addon=HCDeaths_API
if not addon then return end
local S={channel="HCDeathsSyncV2",queue={},seen={},offers={},round=0,stats={},sendInterval=10}
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
    if not string.find("HOQIGDNF",kind,1,true) then return nil end
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
    HCDeaths_SyncStatus={version="1.4.5-fork",utc=date("!%Y/%m/%d %H:%M:%S"),
        enabled=HCDeaths_Settings.sync and true or false,status=self.status,channel=self.channel,
        channelID=self:ChannelID(),realm=realm,faction=faction,player=UnitName("player"),
        stats=stats,lastError=self.lastError,lastReject=self.lastReject,lastPeer=self.lastPeer,
        lastPacket=self.lastPacket,queue=table.getn(self.queue),
        sendInterval=self.sendInterval,cooldownSeconds=math.max(0,math.ceil((self.pauseUntil or 0)-GetTime())),lastThrottle=self.lastThrottle,
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
    addon:print("Sync 1.4.5: "..tostring(d.status).."; enabled="..tostring(d.enabled))
    addon:print("Channel "..d.channel..": id="..d.channelID.."; player="..tostring(d.player).."; realm="..tostring(d.realm).."; faction="..tostring(d.faction))
    addon:print("TX attempted/local OK/errors: "..(c.attempted or 0).."/"..(c.sent or 0).."/"..(c.sendErrors or 0).."; queue="..d.queue)
    addon:print("RX protocol/self echo/peer packets: "..(c.wire or 0).."/"..(c.echo or 0).."/"..(c.peerPackets or 0).."; last peer="..tostring(d.lastPeer or "none"))
    addon:print("Offers/inventory/chunks/decoded/invalid: "..(c.offers or 0).."/"..(c.inventory or 0).."/"..(c.chunks or 0).."/"..(c.decoded or 0).."/"..(c.invalid or 0))
    addon:print("Imported/enriched/filtered: "..(c.imported or 0).."/"..(c.enriched or 0).."/"..(c.filtered or 0))
    addon:print("Retransmissions/timeouts: "..(c.retries or 0).."/"..(c.timeouts or 0).."; waiting record="..tostring(d.waitingIndex or "none").."; parts="..(d.receivedParts or 0).."/"..(d.totalParts or 0))
    addon:print("Send interval: "..d.sendInterval.."+ seconds; cooldown: "..d.cooldownSeconds.." seconds; server throttles: "..(c.throttles or 0))
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
    if kind~="D" then
        for i,queued in ipairs(self.queue) do
            local destination,queuedKind=decodeEnvelope(queued)
            if queuedKind=="D" then table.insert(self.queue,i,msg);return true end
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
    p.parts=nil;p.received=0;p.total=nil;p.retries=0;p.retryAt=GetTime()+90
    local item=table.remove(p.items,1)
    if item then
        p.wait=item;p.deadline=GetTime()+90
        self:Enqueue(p.peer,"G",p.token..","..item.index)
    elseif p.cursor>0 then
        p.wait=nil;p.deadline=GetTime()+90
        self:Enqueue(p.peer,"Q",p.token..","..p.cursor)
    else self:Enqueue(p.peer,"F",p.token);self.pull=nil;self.status="Up to date with "..p.peer end
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
        self:Count("timeouts");self:Enqueue(p.peer,"F",p.token);self.pull=nil;self.status="Peer timeout after retries; trying later";return
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
    if kind=="O" and self.offer and sameName(self.offer.target,target) and self.offer.token==body then self.offer=nil end
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
        if not self.offer and (not self.grant or now>self.grant.untilTime) then self.offer={target=sender,token=body,due=now+2+math.random()*6} end
    elseif kind=="O" and self.discovery and body==self.discovery.token then
        self:Count("offers")
        if not self.discovery.peer then self.discovery.peer=sender end
    elseif kind=="F" then
        if self.grant and sameName(self.grant.peer,sender) and self.grant.token==body then
            self.grant=nil
            for i=table.getn(self.queue),1,-1 do
                local target,k,payload=decodeEnvelope(self.queue[i])
                if sameName(target,sender) and k=="D" and string.sub(payload,1,string.len(body)+1)==body.."," then table.remove(self.queue,i) end
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
            local cache=grant.dataCache
            if not cache or cache.index~=index then
                if missing then self:Enqueue(sender,"N",token..","..index);return end
                local data=self:Pack(r);if not data then return end
                local hex=string.gsub(data,".",function(c) return string.format("%02X",string.byte(c)) end)
                cache={index=index,hex=hex,total=math.ceil(string.len(hex)/128)}
                if cache.total>64 then return end
                grant.dataCache=cache
            end
            for part=1,cache.total do
                local wanted=not missing
                if missing then
                    local nibble=tonumber(string.sub(missing,math.ceil(part/4),math.ceil(part/4)),16)
                    wanted=math.mod(math.floor(nibble/2^math.mod(part-1,4)),2)==1
                end
                if wanted then
                    local payload=token..","..index..","..part..","..cache.total..","..string.sub(cache.hex,(part-1)*128+1,part*128)
                    local queued=false
                    for _,message in ipairs(self.queue) do
                        local dest,k,b=decodeEnvelope(message)
                        if sameName(dest,sender) and k=="D" and b==payload then queued=true;break end
                    end
                    if not queued then self:Enqueue(sender,"D",payload) end
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
        if p and sameName(p.peer,sender) and token==p.token and p.wait and tonumber(index)==p.wait.index then self:Next() end
    elseif kind=="D" then
        local p=self.pull
        local _,_,token,index,part,total,hex=string.find(body,"^(%d+),(%d+),(%d+),(%d+),(%x+)$")
        part=integer(part,1,64);total=integer(total,1,64)
        if not p or not sameName(sender,p.peer) or token~=p.token or not p.wait or tonumber(index)~=p.wait.index
            or not part or not total or part>total or string.len(hex)>128 or math.mod(string.len(hex),2)~=0 then return end
        if p.total and p.total~=total then return end
        self:Count("chunks")
        p.parts=p.parts or {};p.total=total
        if not p.parts[part] then
            p.parts[part]=hex;p.received=p.received+1
            p.deadline=now+90;p.retryAt=now+90
        end
        if p.received==total then
            local all=table.concat(p.parts)
            local data=string.gsub(all,"%x%x",function(pair) return string.char(tonumber(pair,16)) end)
            -- Records can be enriched between their inventory and data replies.
            local r,reason=self:Unpack(data)
            if r then self:Count("decoded");self:Import(r,sender);self:MarkSeen(self:Fingerprint(data))
            else self:Count("invalid");self.lastReject=reason or "Invalid record data" end
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
        self:Enqueue(self.offer.target,"O",self.offer.token)
        local snapshot={}
        for i,r in ipairs(HCDeaths) do snapshot[i]=r end
        self.grant={peer=self.offer.target,token=self.offer.token,untilTime=now+600,records=snapshot};self.offer=nil
    end
    self:RetryPull(now)
    if self.discovery and self.discovery.deadline and now>=self.discovery.deadline then
        local d=self.discovery;self.discovery=nil
        if d.peer then
            self.pull={peer=d.peer,token=d.token,cursor=0,items={},deadline=now+90,retries=0,retryAt=now+25}
            self.status="Syncing with "..d.peer
            self:Enqueue(d.peer,"Q",d.token..",0")
        else self.status="Waiting for other users" end
    end
    if not self.pull and not self.discovery and now>=self.nextHello then
        self.round=self.round+1
        local token=tostring(self.round)..tostring(math.random(10000,99999))
        self.discovery={token=token}
        self:Enqueue("*","H",token);self.nextHello=now+300+math.random(0,60)
    end
    if table.getn(self.queue)>0 and now>=(self.nextSend or 0) then
        local msg=self.queue[1]
        self.nextSend=now+self.sendInterval+math.random()*2;self:Count("attempted")
        local ok,err=pcall(SendChatMessage,msg,"CHANNEL",nil,id)
        if ok then
            self:Count("sent");table.remove(self.queue,1);self.sendFailures=0
            local target,kind,body=decodeEnvelope(msg)
            if kind=="H" and self.discovery and self.discovery.token==body then self.discovery.deadline=now+90 end
            if kind=="D" and self.grant then self.grant.untilTime=math.max(self.grant.untilTime,now+600) end
        else
            self:Count("sendErrors");self.lastError=string.sub(tostring(err),1,300)
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
