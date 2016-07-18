local addonEnabled = true;
MidnightLoot = {};
MidnightLootSaved = {};
MidnightLoot.LOOT_ITEM_HEIGHT = 50;
MidnightLoot.activeLootItems = {};
_, MidnightLoot.playerClass = UnitClass('PLAYER');
MidnightLoot.playerName = {UnitName('PLAYER')};
MidnightLoot.classReference = {
	['MAGE'] = {
		['index'] = 8,
		['armor'] = 'Cloth',
		[62] = "Arcane",
		[63] = "Fire",
		[64] = "Frost",
	},
	['PALADIN'] = {
		['index'] = 2,
		['armor'] = 'Plate',
		[65] = "Holy",
		[66] = "Protection",
		[70] = "Retribution",
	},
	['WARRIOR'] = {
		['index'] = 1,
		['armor'] = 'Plate',		
		[71] = "Arms",
		[72] = "Fury",
		[73] = "Protection",
	},
	['DRUID'] = {
		['index'] = 11,
		['armor'] = 'Leather',		
		[102] = "Balance",
		[103] = "Feral",
		[104] = "Guardian",
		[105] = "Restoration",
	},
	['DEATHKNIGHT'] = {
		['index'] = 6,
		['armor'] = 'Plate',
		[250] = "Blood",
		[251] = "Frost",
		[252] = "Unholy",
	},
	['HUNTER'] = {
		['index'] = 3,
		['armor'] = 'Mail',
		[253] = "Beast Mastery",
		[254] = "Marksmanship",
		[255] = "Survival",
	},
	['PRIEST'] = {
		['index'] = 5,
		['armor'] = 'Cloth',
		[256] = "Discipline",
		[257] = "Holy",
		[258] = "Shadow",
	},
	['ROGUE'] = {
		['index'] = 4,
		['armor'] = 'Leather',		
		[259] = "Assassination",
		[260] = "Outlaw",
		[261] = "Subtlety",
	},
	['SHAMAN'] = {
		['index'] = 7,
		['armor'] = 'Mail',		
		[262] = "Elemental",
		[263] = "Enhancement",
		[264] = "Restoration",
	},
	['WARLOCK'] = {
		['index'] = 9,
		['armor'] = 'Cloth',		
		[265] = "Affliction",
		[266] = "Demonology",
		[267] = "Destruction",
	},
	['MONK'] = {
		['index'] = 10,
		['armor'] = 'Leather',		
		[268] = "Brewmaster",
		[269] = "Windwalker",
		[270] = "Mistweaver",
	},
	['DEMONHUNTER'] = {
		['index'] = 12,
		['armor'] = 'Leather',		
		[577] = "Havoc",
		[581] = "Vengeance",
	},
}

function MidnightLoot_OnLoad(self)
	self:Show();
	self:RegisterForDrag("LeftButton");
	
	self:RegisterEvent("BOSS_KILL")
	self:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	
	self.scrollFrame.update = MidnightLoot.UpdateActiveLoot;
	self.scrollFrame.buttonHeight = MidnightLoot.LOOT_ITEM_HEIGHT;
	--self.scrollFrame.dynamic = MidnightLoot.CalculateDynamic;
	-- self.scrollFrame.stepSize = 12;
	self.scrollFrame.scrollBar.doNotHide = true;
	HybridScrollFrame_CreateButtons(self.scrollFrame, "MidnightLootItemFrameTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, 0, "TOPLEFT", "BOTTOMLEFT");
	MidnightLoot.UpdateActiveLoot();
end

MidnightLoot_OnDragStart = function(self)
	self:StartMoving();
end

MidnightLoot_OnDragStop = function(self)
	self:StopMovingOrSizing();
end

MidnightLoot_Hide = function(self)
	self:Hide();
end

-- function MidnightLoot.CalculateDynamic(offset)
	-- local past = math.floor(offset / MidnightLoot.LOOT_ITEM_HEIGHT)
	-- local partial = offset % MidnightLoot.LOOT_ITEM_HEIGHT
	-- return past, partial
-- end
-- Consolidated function for updating the two loot frame buttons according to state.

function MidnightLoot.AddLoot(itemID, owner)
	local loot = {};
	loot.ID = itemID;
	loot.owner = owner;
	loot.name, loot.link, loot.quality, loot.iLevel, loot.reqLevel, loot.class, loot.subclass, loot.maxStack, loot.equipSlot, loot.texture, loot.vendorPrice = GetItemInfo(itemID)
	--If it's an artifact relic, tag it with the appropriate type
	if loot.subclass == "Artifact Relic" then
		_,_, loot.relicType = C_ArtifactUI.GetRelicInfoByItemID(itemID)
	end
	if loot.name ~= nil then
		table.insert(MidnightLoot.activeLootItems, loot)
		MidnightLoot.UpdateActiveLoot()
	else
		print("ID "..itemID.." is not a real item, or has not been added to your loot database yet.  Sorry!")
	end
	return getn(MidnightLoot.activeLootItems);
end

function MidnightLoot.RemoveLoot(index)
	table.remove(MidnightLoot.activeLootItems, index)
	MidnightLoot.UpdateActiveLoot()
end

function MidnightLoot.UpdateLootButtons(self, state1, text1, state2, text2)
local buttons = {{self.button1, state1, text1}, {self.button2, state2, text2}}
	for i = 1, 2 do
		local button = buttons[i][1]
		local state = buttons[i][2]
		local text = buttons[i][3]
		if state == "hidden" then
			button:Hide();
		elseif state == "enabled" then
			button:SetText(text);
			button:Enable();
			button:Show();
		elseif state == "disabled" then
			button:SetText(text);
			button:Disable();
			button:Show();
		end;
	end;
end;

function MidnightLoot_LootIcon_OnEnter(self)
	local parent = self:GetParent();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetItemByID(parent.item.ID);
	CursorUpdate(self);
end

function MidnightLoot.UpdateActiveLoot()
	--Updates the loot window display.
	local scrollFrame = MidnightLootFrame.scrollFrame
	local offset = math.floor(scrollFrame.offset + 0.5);
	local buttons = scrollFrame.buttons
	local numButtons = #buttons
	local numItems = getn(MidnightLoot.activeLootItems)
	
	for i = 1, numButtons do
		local button = buttons[i];
		local index = math.floor(offset + i + 0.5);
		if index <= numItems then
			button.item = MidnightLoot.activeLootItems[index]
			button.color = ITEM_QUALITY_COLORS[button.item.quality]
			button.lootIcon.texture:SetTexture(button.item.texture)
			button.itemName:SetText(button.item.name)
			button.itemName:SetVertexColor(button.color.r, button.color.g, button.color.b)
			-- if the item belongs to the player, give them the option to claim or release it.
			if button.item.status == "Claimable" then
				MidnightLoot.UpdateLootButtons(button, "enabled", "Claim", "enabled", "Release")				
			-- if the player is eligible to roll on the item, give them the roll buttons.
			elseif button.item.status == "Eligible" then
				MidnightLoot.UpdateLootButtons(button, "enabled", "Main Spec", "enabled", "Offspec")				
			-- if the player is eligible to roll off-spec, give them the roll buttons with Main Spec disabled.
			elseif button.item.status == "Eligible - Offspec" then
				MidnightLoot.UpdateLootButtons(button, "disabled", "Main Spec", "enabled", "Offspec")				
			-- if the player is supposed to trade the item, give them the trade button.
			elseif button.item.status == "Tradeable" then
				MidnightLoot.UpdateLootButtons(button, "hidden", " ", "enabled", "Trade")			
			-- in all other states, the buttons are hidden.
			else
				MidnightLoot.UpdateLootButtons(button, "hidden", " ", "hidden", "")
			end
			
			button:Show();
		else
			button:Hide();
		end
	end
	
	local totalHeight = numItems * MidnightLoot.LOOT_ITEM_HEIGHT;
	HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight())
end

function MidnightLoot.UpdateLootItem(itemID, owner, ownerStatus)
	--Process new loot information
	local numItems = getn(MidnightLoot.activeLootItems);
	local isNewItem = true;
	local index = 0;
	local eligibleSpecs = MidnightLoot.RequestEligibleSpecs();
	local isEligible = false;
	local playerClass = MidnightLoot.classReference[MidnightLoot.playerClass]['index']
	
	--Check whether the item already exists in the activeLootItems.
	for i = 1, numItems do
		if MidnightLoot.activeLootItems[i].ID == itemID and MidnightLoot.activeLootItems[i].owner == owner then
			index = i
			isNewItem = false
		end
	end
	--If, after iterating through the active items, we determine this is a new loot item, add it to activeLootItems.
	if isNewItem == true then
		index = MidnightLoot.AddLoot(itemID, owner)
	end
	
	--Starting with ownerStatus, determine what the status of this loot item is to the player.
	local item = MidnightLoot.activeLootItems[index]
	-- PROBABLY SHOULD BUILD THE CHECKS FOR THE PLAYER'S OWN LOOT INTO HERE
	if ownerStatus == "Claimed" then
		MidnightLoot.activeLootItems[index].status = "Claimed"
	elseif ownerStatus == "Locked" then
		MidnightLoot.activeLootItems[index].status = "Locked"
	elseif ownerStatus == "Pending" then
		MidnightLoot.activeLootItems[index].status = "Pending"		
	elseif ownerStatus == "Released" then
		if item.equipSlot == "INVTYPE_TRINKET" or item.subclass == "Artifact Relic" then
			EJ_SelectInstance(MidnightLoot.instanceID)
			--Cycle through main spec(s), filtering the instance's loot in the Encounter Journal.  If it is found on a main spec's loot list, flag it eligible.
			for specIndex, spec in ipairs(eligibleSpecs['main']) do
				EJ_SetLootFilter(playerClass, spec)
				for i = 1, EJ_GetNumLoot() do
					local _,_,_,_,ejItemID = GetLootInfoByIndex(i)
					if ejItemID == item.ID then
						MidnightLoot.activeLootItems[index].status = "Eligible"
						break
					end
				end
				if MidnightLoot.activeLootItems[index].status == "Eligible" then
					break
				end
			end				
			--If it's not on the main spec list, repeat the process using the offspec list.  If found flag Eligible - Offspec.
			if isEligible == false then
				for specIndex, spec in ipairs(eligibleSpecs['off']) do
					EJ_SetLootFilter(playerClass, spec)
					for i = 1, EJ_GetNumLoot() do
						local _,_,_,_,ejItemID = GetLootInfoByIndex(i)
						if ejItemID == item.ID then
							MidnightLoot.activeLootItems[index].status = "Eligible"
							break
						end
					end
					if MidnightLoot.activeLootItems[index].status == "Eligible" then
						break
					end
				end
			--Otherwise set Ineligible.
			else
				MidnightLoot.activeLootItems[index].status = "Ineligible"
			end
		elseif item.class == "Armor" then
			if item.subclass == "Miscellaneous" or item.subclass == MidnightLoot.classReference[MidnightLoot.playerClass]['armor'] then
				MidnightLoot.activeLootItems[index].status = "Eligible"
			else
				MidnightLoot.activeLootItems[index].status = "Ineligible"
			end
		end
	else
		print("Could not determine status!")
	end
end

function MidnightLoot.RequestEligibleSpecs()
	if IsRaidLeader() or UnitIsGroupAssistant('PLAYER') then
		--Check local tables
	else
		--Request table update
	end
	
	return nil
end

function MidnightLoot.SetInstanceID() -- NEED A HOOK TO FIRE THIS WHEN ENTERING AN INSTANCE OR LOADING THE ADDON.
	MidnightLoot.instanceID = EJ_GetCurrentInstance()
end

function MidnightLoot.TestTradable(itemLink)
	--Loads an item link into a hidden tooltip, then scans the tooltip to determine if the item is tradable.
	MidnightLootScanTooltip:ClearLines()
	MidnightLootScanTooltip:SetHyperlink(itemLink)
	local isBoundTradable = false
	local tooltipRegions = MidnightLootScanTooltip:GetRegions()
	for i = 1, select("#", tooltipRegions) do
		local region = select(i, tooltipRegions)
		if region and region:GetObjectType() == "FontString" then
			local text = region:GetText()
			if text ~= nil then
				local findTrade = string.find(text, "trade this item")
				if findTrade ~= nil then
					isBoundTradable = true
				end
			end
		end
	end
	return isBoundTradable
end

function MidnightLoot_EventHandler(self, event, ...)
	if event == "BOSS_KILL" then
		MidnightLoot.lastBoss = ...;
	elseif event == "ENCOUNTER_LOOT_RECEIVED" then
		local encounterID, itemID, itemLink, quantity, playerName, className = ...;
		local status = "";
		if encounterID == MidnightLoot.lastBoss and playerName == MidnightLoot.playerName then
			if MidnightLoot.TestTradable(itemLink) then
				status = "Pending"
			else
				status = "Locked"
			end
			SendAddonMessage("MidnightLoot", "NEW_LOOT~"..itemLink.."~"..playerName.."~"..status, "RAID")
		end
	elseif event == "CHAT_MSG_ADDON" and ... == "MidnightLoot" then
		local _, messageStr, _, sender = ...;
		local messageData = {strsplit("~", messageStr)};
		if messageData[1] == --STOPHERE
end
