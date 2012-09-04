

local addid = function(self, id)
    if(id) then
        self:AddDoubleLine('Spellid:', id)
        self:Show()
    end
end

--hooks.SetUnitBuff, function(self, ...)
--end

--hooks.SetUnitDebuff, function()
--end

hooksecurefunc(GameTooltip, 'SetUnitAura', function(self, ...)
    local id = select(11, UnitAura(...))
    addid(self, id)
end)

GameTooltip:HookScript('OnTooltipSetSpell', function(self)
    local id = select(3, self:GetSpell())
    addid(self, id)
end)


--hooksecurefunc('SetItemRef', function(link, text, button, chatFrame)
--    if link:find'^spell:' then
--        local id = link:sub(7)
--    end
--end)



