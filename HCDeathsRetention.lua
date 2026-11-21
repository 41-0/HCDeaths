-- Local log limits and explicit cleanup. WoW 1.12 / Lua 5.0.
local addon=HCDeaths_API
if not addon then return end
local R={removed=setmetatable({},{__mode="k"})}
addon.Retention=R
local function death(r) return r and (r.deathType=="PVE" or r.deathType=="PVP") end
local function number(value,min,max)
    local n=tonumber(value)
    if n and n==n and n==math.floor(n) and n>=min and n<=max then return n end
end
function R:Scope(r)
    local realm=r and r.realm
    local faction=r and r.faction
    if not realm or realm=="Unknown" then realm=GetRealmName and GetRealmName() or "Unknown" end
    if not faction or faction=="Unknown" then faction=UnitFactionGroup and UnitFactionGroup("player") or "Unknown" end
    return realm.."/"..faction
end
function R:Rules(r)
    HCDeaths_PruneRules=HCDeaths_PruneRules or {}
    local key=self:Scope(r)
    HCDeaths_PruneRules[key]=HCDeaths_PruneRules[key] or {levels={}}
    return HCDeaths_PruneRules[key]
end
function R:Stamp(r) return addon.Sync and addon.Sync:Stamp(r) end
function R:Now()
    return self:Stamp({sdate=date("!%Y/%m/%d"),stime=date("!%H:%M:%S")})
end
function R:Count()
    local count=0
    for _,r in ipairs(HCDeaths or {}) do if death(r) then count=count+1 end end
    return count
end
function R:AllowImported(r)
    local rules=HCDeaths_PruneRules and HCDeaths_PruneRules[self:Scope(r)]
    local stamp=self:Stamp(r)
    if not rules or not stamp then return true end
    if rules.before and stamp<rules.before then return false end
    local level=number(r.playerLevel,1,60)
    local cutoff=level and rules.levels and rules.levels[level]
    return not cutoff or stamp>cutoff
end
function R:Commit(remove,rememberAge)
    local count=0;local write=1;local total=table.getn(HCDeaths)
    for i=1,total do
        local r=HCDeaths[i]
        if remove[r] then
            count=count+1;self.removed[r]=true
            if rememberAge then
                local stamp=self:Stamp(r)
                if stamp then
                    local rules=self:Rules(r)
                    rules.before=math.max(rules.before or 0,stamp+1)
                end
            end
        else HCDeaths[write]=r;write=write+1 end
    end
    for i=write,total do HCDeaths[i]=nil end
    if count>0 then
        if addon.OnPrunedRecords then addon:OnPrunedRecords(remove) end
        addon:updateLog()
        if addon.RefreshLogManagement then addon:RefreshLogManagement() end
    end
    return count
end
function R:Trim(keep)
    local entries={}
    for index,r in ipairs(HCDeaths) do
        if death(r) then table.insert(entries,{record=r,index=index,stamp=self:Stamp(r)}) end
    end
    if table.getn(entries)<=keep then return 0 end
    table.sort(entries,function(a,b)
        if a.stamp and b.stamp and a.stamp~=b.stamp then return a.stamp<b.stamp end
        if not a.stamp and b.stamp then return true end
        if a.stamp and not b.stamp then return false end
        return a.index<b.index
    end)
    local remove={}
    for i=1,table.getn(entries)-keep do remove[entries[i].record]=true end
    return self:Commit(remove,true)
end
function R:Enforce()
    local cap=number(HCDeaths_Settings.maxrecords,0,2147483647) or 0
    if cap==0 then return 0 end
    return self:Trim(cap)
end
function R:SetMaximum(value)
    local n=number(value,0,2147483647)
    if not n then return nil,"Enter a whole number: 0 = unlimited, or 1-2147483647." end
    HCDeaths_Settings.maxrecords=n
    if addon.Sync then addon.Sync.seen={};addon.Sync.seenRing=nil;addon.Sync.seenLimit=nil end
    local count=self:Enforce()
    return count,n==0 and "Maximum saved entries: unlimited." or "Maximum saved entries: "..n..". Deleted "..count.." oldest entries."
end
function R:BelowLevel(value)
    local level=number(value,1,61)
    if not level then return nil,"Enter a whole level from 1 to 61. Only lower levels are deleted." end
    local now=self:Now()
    if not now then return nil,"Cannot determine the current UTC time." end
    local remove={};local scopes={};scopes[self:Scope()]=self:Rules()
    for _,r in ipairs(HCDeaths) do
        if death(r) then
            scopes[self:Scope(r)]=self:Rules(r)
            local n=number(r.playerLevel,1,60)
            if n and n<level then remove[r]=true end
        end
    end
    for _,rules in pairs(scopes) do
        rules.levels=rules.levels or {}
        for n=1,level-1 do rules.levels[n]=math.max(rules.levels[n] or 0,now) end
    end
    local count=self:Commit(remove,false)
    return count,"Deleted "..count.." entries below level "..level.."."
end
function R:OlderThan(value)
    local days=number(value,1,36500)
    if not days then return nil,"Enter a whole number of days from 1 to 36500." end
    local now=self:Now()
    if not now then return nil,"Cannot determine the current UTC time." end
    local cutoff=now-days*86400;local remove={}
    local rules=self:Rules();rules.before=math.max(rules.before or 0,cutoff)
    for _,r in ipairs(HCDeaths) do
        if death(r) then
            local rule=self:Rules(r);rule.before=math.max(rule.before or 0,cutoff)
            local stamp=self:Stamp(r)
            if stamp and stamp<cutoff then remove[r]=true end
        end
    end
    local count=self:Commit(remove,false)
    return count,"Deleted "..count.." entries older than "..days.." days (UTC)."
end
function R:KeepNewest(value)
    local n=number(value,0,2147483647)
    if not n then return nil,"Enter a whole number: 0 deletes all death entries." end
    local count=self:Trim(n)
    return count,"Deleted "..count.." oldest entries; kept at most "..n.."."
end
function R:Initialize()
    HCDeaths_Settings.maxrecords=number(HCDeaths_Settings.maxrecords,0,2147483647) or 0
    HCDeaths_PruneRules=HCDeaths_PruneRules or {}
    self:Enforce()
end
function R:Command(msg,silent)
    local _,_,area,action,value=string.find(msg,"^(%a+)%s+(%a+)%s+(%S+)$")
    local fn
    if area=="log" and action=="max" then fn=self.SetMaximum end
    if area=="prune" then
        if action=="level" then fn=self.BelowLevel elseif action=="days" then fn=self.OlderThan
        elseif action=="keep" then fn=self.KeepNewest end
    end
    if not fn then return false end
    local count,message=fn(self,value)
    if not silent then addon:print(message) end
    return true
end
