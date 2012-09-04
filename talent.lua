
local frame = CreateFrame'Frame'
frame:SetScript('OnEvent', function(self, event, ...)
    return self[event](self, event, ...)
end)
frame:RegisterEvent'INSPECT_READY'

local cache = {}

local TALENTS_PREFIX = 'Talents:|cffffffff ';
local CACHE_SIZE = 25

local cache_talent = function(name, talent)
    local entry
    if(#cache >= CACHE_SIZE) then
        entry = table.remove(cache)
    else
        entry = {}
    end

    entry.name = name
    entry.talent = talent
    table.insert(cache, entry)
end

local get_cached_by_name = function(name)
    for _, entry in next, cache do
        if(entry.name == name) then
            return entry.talent
        end
    end
end

local display_talent = function(talent)
    for i = 2, GameTooltip:NumLines() do
        local tl = _G['GameTooltipTextLeft'..i]
        if(tl and tl:match('^'..TALENTS_PREFIX)) then
            return tl:SetText(TALENTS_PREFIX ..talent)
        end
    end
    return GameTooltip:AddLine(TALENTS_PREFIX..talent)
end

local get_talent = function(unit)
    local spec = GetInspectSpecialization(unit)
    if(spec > 0) then
        local id, name, desc, icon, bg = GetSpecializationInfoByID(spec)
        return name
    end
end
function frame:INSPECT_READY()
    if(frame.inspect and GameTooltip:GetUnit() == frame.insName) then
        frame.inspect = false
        local talent = get_talent(frame.insTarget)
        if(talent) then
            cache_talent(frame.insName, talent)
            display_talent(talent)
        end
    end
end

local inspect_unit = function(unit)
    local name = UnitName(unit)

    frame.inspect = true
    frame.insName = name
    frame.insTarget = unit

    local talent = get_cached_by_name(name)
    if(talent) then
        display_talent(talent)
    end

    NotifyInspect(unit)
end

GameTooltip:HookScript('OnTooltipSetUnit',function(self,...)
    local _, unit = self:GetUnit()
    if(not unit) then
        local focus = GetMouseFocus()
        if(focus and focus.unit) then
            unit = focus.unit
        end
    end

    if(unit and not UnitIsUnit(unit, 'player')) then
        return inspect_unit(unit)
    end
end)
