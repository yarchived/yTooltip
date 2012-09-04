
local TEXTURE = [[Interface\AddOns\yTooltip\FlatSmooth]]
local ICON_SIZE = 24
local COLOR_GUILD_SAME = '|cffff32ff'
local COLOR_GUILD = '|cff25c1eb'
local UPDATE_FREQUENCY = .5
local COLOR = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local TOTAL = 0

local function Script(self, script, func)
    if self:GetScript(script) then
        self:HookScript(script, func)
    else
        self:SetScript(script, func)
    end
end

local function Hex(r, g, b)
    if type(r) == 'table' then
        if r.r then
            r,g,b = r.r, r.g, r.b
        else
            r,g,b = unpack(r)
        end
    end
    r, g, b = r or 1, g or 1, b or 1

    return format('|cff%02x%02x%02x', r*255, g*255, b*255)
end

local function truncate(value)
    if(value >= 1e6) then
        value = format('%.1fm', value / 1e6)
    elseif(value >= 1e3) then
        value = format('%.1fk', value / 1e3)
    end
    return gsub(value, '%.?0+([km])$', '%1')
end

-- OnTooltipSetDefaultAnchor
function GameTooltip_SetDefaultAnchor(tooltip, parent)		
    tooltip:SetOwner(parent, 'ANCHOR_NONE')
    tooltip:SetPoint('BOTTOMLEFT', 'UIParent', 'BOTTOMLEFT', 0, 300)
    tooltip.default = 1
end

-- |TTexturePath:size1:size2:xoffset:yoffset:dimx:dimy:coordx1:coordx2:coordy1:coordy2|t
-- http://www.wowwiki.com/UI_escape_sequences
local function TooltipAddIcon(self, icon)
    local title = _G[self:GetName() .. 'TextLeft1']
    if title and not title:GetText():find('|T' .. icon) then --make sure the icon does not display twice on recipies, which fire OnTooltipSetItem twice
        title:SetFormattedText('|T%s:%d:%d:0:0:64:64:4:60:4:60|t %s', icon, ICON_SIZE, ICON_SIZE, title:GetText())
    end
end

GameTooltip.FadeOut = GameTooltip.Hide

for _, tip in ipairs({GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3}) do
    Script(tip, 'OnTooltipSetItem', function(self)
        local name, item = self:GetItem()
        if(item) then
            local quality = select(3, GetItemInfo(item))
            if(quality) then
                local r, g, b = GetItemQualityColor(quality)
                self:SetBackdropBorderColor(r, g, b)
            end
            local icon = GetItemIcon(item)
            if icon then TooltipAddIcon(self, icon) end
        else
            self:SetBackdropBorderColor(1,1,1,1)
        end
    end)

    Script(tip, 'OnTooltipSetSpell', function(self)
        local name, rank, icon = GetSpellInfo(self:GetSpell())
        if icon then TooltipAddIcon(self, icon) end
    end)
end

local function ColorDetail(self, unit, isPlayer)
    if self:GetText():find(LEVEL) then
        local level = UnitLevel(unit)
        local c = GetQuestDifficultyColor(level>0 and level or 99)
        local creatureType = (not isPlayer) and UnitCreatureType(unit) or ''
        local detail = isPlayer and UnitClass(unit) or UnitCreatureType(unit) or ''
        local levelText

        local cl = UnitClassification(u)
        if(cl == 'worldboss') then
            levelText = '++'
        else
            if(cl == 'elite' or cl == 'rareelite') then
                levelText = (level>0) and level..'+' or '+'
            else
                levelText = (level>0) and level or '??'
            end
        end

        self:SetText(Hex(c) .. levelText .. ' ' .. Hex(GameTooltip_UnitColor(unit)) .. detail)

        return true
    end
end

Script(GameTooltip, 'OnTooltipSetUnit', function(self)
    local name, unit = self:GetUnit()
    if not unit then return end
    local isPlayer = UnitIsPlayer(unit)

    local cc = COLOR[select(2,UnitClass(unit))]
    if cc and cc.r then
        self:SetBackdropBorderColor(cc.r, cc.g, cc.b, 1)
    end

    local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit)
    if isPlayer then
        if guildName then
            local c = (guildName == GetGuildInfo'player') and COLOR_GUILD_SAME or COLOR_GUILD
            GameTooltipTextLeft2:SetText(c .. guildName)
            GameTooltipTextRight2:SetFormattedText('%s %d', guildRankName, guildRankIndex)
            GameTooltipTextRight2:Show()
        end
    end

    if not guildName then
        if not ColorDetail(GameTooltipTextLeft2, unit, isPlayer) then
            ColorDetail(GameTooltipTextLeft3, unit, isPlayer)
        end
    else
        ColorDetail(GameTooltipTextLeft3, unit, isPlayer)
    end

    --local dnd, afk, pvp = UnitIsDND(unit), UnitIsAFK(unit), UnitIsPVP(unit)
    local dnd, afk = UnitIsDND(unit), UnitIsAFK(unit)
    if dnd or afk or pvp then
        local text = GameTooltipTextLeft1:GetText()
        --text = pvp and ('|cffD7BEA5<PVP> |r' .. text) or text
        text = dnd and ('|cffD7BEA5<DND> |r' .. text) or text
        text = afk and ('|cffD7BEA5<AFK> |r' .. text) or text

        GameTooltipTextLeft1:SetText(text)
    end

    --[[local target = UnitName(unit .. 'target')
    if target then
    c = COLOR[select(2,UnitClass(unit .. 'target'))]
    GameTooltipTextRight1:SetText(Hex(c) .. target)
    GameTooltipTextRight1:Show()
    end]]
    GameTooltipTextRight1:SetText('|cffD7BEA5>>|rNONE')
    GameTooltip:AppendText''
    GameTooltipTextRight1:Show()
    TOTAL = 0
end)

local f = CreateFrame'Frame'
f:SetScript('OnUpdate', function(self, elps)
    TOTAL = TOTAL - elps
    if TOTAL > 0 then return end
    TOTAL = UPDATE_FREQUENCY

    local name, unit = GameTooltip:GetUnit()
    if unit and GameTooltip:IsShown() then
        local target = UnitName(unit.. 'target')
        if target then
            if UnitIsUnit('player', unit .. 'target') then
                GameTooltipTextRight1:SetText('|cffD7BEA5>>|cffff0000YOU')
            else
                local c = COLOR[select(2,UnitClass(unit .. 'target'))]
                GameTooltipTextRight1:SetText('|cffD7BEA5>>' .. Hex(c) .. target)
            end
        else
            GameTooltipTextRight1:SetText('|cffD7BEA5>>|rNONE')
        end
        GameTooltipTextRight1:Show()
    end
end)

local _tooltip_color = {r=1,g=1,b=1}
function GameTooltip_UnitColor(unit)
    local c
    if UnitIsPlayer(unit) then
        c = COLOR[select(2,UnitClass(unit))]
    else
        local reaction = UnitReaction(unit, 'player')
        if reaction then
            c = FACTION_BAR_COLORS[reaction]
        end
    end
    c = c or _tooltip_color
    return c.r, c.g, c.b
end

Script(GameTooltipStatusBar, 'OnValueChanged', function(self, value)
    if not value then return end
    local _, unit = GameTooltip:GetUnit()
    if unit then
        local min, max = UnitHealth(unit), UnitHealthMax(unit)
        self.Text:SetText(truncate(min) .. '/' .. truncate(max))
    end
end)

GameTooltipStatusBar:SetStatusBarTexture(TEXTURE)
GameTooltipStatusBar:SetHeight(7)
GameTooltipStatusBar.Text = GameTooltipStatusBar:CreateFontString(nil, 'OVERLAY')
GameTooltipStatusBar.Text:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
GameTooltipStatusBar.Text:SetPoint('CENTER', GameTooltipStatusBar)

local bar = CreateFrame('StatusBar', nil --[[ 'GameTooltipStatusBar2' ]], GameTooltipStatusBar)
bar:SetStatusBarTexture(TEXTURE)
bar:SetHeight(8)
bar:SetPoint('TOPLEFT', GameTooltipStatusBar, 'BOTTOMLEFT', 0, -3)
bar:SetPoint('RIGHT', GameTooltipStatusBar)

bar.Text = bar:CreateFontString(nil, 'OVERLAY')
bar.Text:SetFont(STANDARD_TEXT_FONT, 10, 'OUTLINE')
bar.Text:SetPoint('CENTER', bar)

Script(bar, 'OnShow', function(self)
    local _, u = GameTooltip:GetUnit()
    self.unit = u
    self.total = 0
    self.min = 0
    self.max = 0
    if not u then return end

    local powerType = UnitPowerType(u)
    local c = PowerBarColor[powerType]
    if(c) then
        return self:SetStatusBarColor(c.r, c.g, c.b)
    end
end)

Script(bar, 'OnHide', function(self)
    self.unit = nil
end)

Script(bar, 'OnUpdate', function(self, elps)
    self.total = self.total - elps
    if self.total > 0 then return end
    self.total = .2
    if not self.unit then return end

    if not UnitExists'mouseover' then
        GameTooltip:Hide()
        self.unit = nil
        return
    end

    if not self.unit then return end
    local min, max = UnitMana(self.unit), UnitManaMax(self.unit)

    if (self.min ~= min) or (self.max ~= max) then
        self.min = min
        self.max = max

        self:SetMinMaxValues(0, max)
        self:SetValue(min)
        self.Text:SetText(truncate(min) .. '/' .. truncate(max))
    end
end)

