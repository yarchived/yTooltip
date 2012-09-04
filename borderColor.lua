
local COLOR = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

local itemColor = function(self)
    local name, item = self:GetItem()
    if(item) then
        local quality = select(3, GetItemInfo(item))
        if(quality) then
            local r, g, b = GetItemQualityColor(quality)
            self:SetBackdropBorderColor(r, g, b)
        end
    end
end

local unitColor = function(self)
    local name , unit = self:GetUnit()
    if(unit) then
        local c = COLOR[select(2, UnitClass(unit))]
        self:SetBackdropBorderColor(c.r, c.g, c.b)
    end
end

for _, t in pairs{GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3} do
    t:HookScript('OnTooltipSetItem', itemColor)
end

GameTooltip:HookScript('OnTooltipSetUnit', unitColor)

