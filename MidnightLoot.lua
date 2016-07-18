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
		['specs'] = {
			[62] = "Arcane",
			[63] = "Fire",
			[64] = "Frost",
		},
	},
	['PALADIN'] = {
		['index'] = 2,
		['armor'] = 'Plate',
		['specs'] = {
			[65] = "Holy",
			[66] = "Protection",
			[70] = "Retribution",
		},
	},
	['WARRIOR'] = {
		['index'] = 1,
		['armor'] = 'Plate',
		['specs'] = {		
			[71] = "Arms",
			[72] = "Fury",
			[73] = "Protection",
		},
	},
	['DRUID'] = {
		['index'] = 11,
		['armor'] = 'Leather',
		['specs'] = {	
			[102] = "Balance",
			[103] = "Feral",
			[104] = "Guardian",
			[105] = "Restoration",
		},
	},
	['DEATHKNIGHT'] = {
		['index'] = 6,
		['armor'] = 'Plate',
		['specs'] = {
			[250] = "Blood",
			[251] = "Frost",
			[252] = "Unholy",
		},
	},
	['HUNTER'] = {
		['index'] = 3,
		['armor'] = 'Mail',
		['specs'] = {
			[253] = "Beast Mastery",
			[254] = "Marksmanship",
			[255] = "Survival",
		},
	},
	['PRIEST'] = {
		['index'] = 5,
		['armor'] = 'Cloth',
		['specs'] = {
			[256] = "Discipline",
			[257] = "Holy",
			[258] = "Shadow",
		},
	},
	['ROGUE'] = {
		['index'] = 4,
		['armor'] = 'Leather',
		['specs'] = {	
			[259] = "Assassination",
			[260] = "Outlaw",
			[261] = "Subtlety",
		},
	},
	['SHAMAN'] = {
		['index'] = 7,
		['armor'] = 'Mail',
		['specs'] = {
			[262] = "Elemental",
			[263] = "Enhancement",
			[264] = "Restoration",
		},
	},
	['WARLOCK'] = {
		['index'] = 9,
		['armor'] = 'Cloth',
		['specs'] = {
			[265] = "Affliction",
			[266] = "Demonology",
			[267] = "Destruction",
		},
	},
	['MONK'] = {
		['index'] = 10,
		['armor'] = 'Leather',
		['specs'] = {		
			[268] = "Brewmaster",
			[269] = "Windwalker",
			[270] = "Mistweaver",
		},
	},
	['DEMONHUNTER'] = {
		['index'] = 12,
		['armor'] = 'Leather',
		['specs'] = {		
			[577] = "Havoc",
			[581] = "Vengeance",
		},
	},
}
MidnightLoot.errors = {}

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

function MidnightLoot.AddLoot(itemLink, itemID, owner)
	local item = {};
	item.owner = owner;
	item.ID = itemID;
	item.link = itemLink
	item.name, _, item.quality, item.iLevel, item.reqLevel, item.class, item.subclass, item.maxStack, item.equipSlot, item.texture, item.vendorPrice = GetItemInfo(itemID)
	--If it's an artifact relic, tag it with the appropriate type
	if item.subclass == "Artifact Relic" then
		_,_, item.relicType = C_ArtifactUI.GetRelicInfoByItemID(itemID)
	end
	if item.name ~= nil then
		table.insert(MidnightLoot.activeLootItems, item)
		MidnightLoot.UpdateActiveLoot()
	else
		SendAddonMessage("MidnightLoot", "ERROR~".."ID "..itemID.." has nil response.", "RAID")
	end
	return getn(MidnightLoot.activeLootItems);
end

function MidnightLoot.RemoveLoot(index)
	table.remove(MidnightLoot.activeLootItems, index)
	MidnightLoot.UpdateActiveLoot()
end

function MidnightLoot.UpdateLootButtons(self, state1, text1, state2, text2)
-- Change what the loot button frame displays.  See MidnightLoot.UpdateActiveLoot for context.
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
			if button.item.status == "Pending" and button.item.owner == MidnightLoot.playerName then
				MidnightLoot.UpdateLootButtons(button, "enabled", "Claim", "enabled", "Release")				
			-- if the player is eligible to roll on the item, give them the roll buttons.
			elseif button.item.status == "Eligible" then
				MidnightLoot.UpdateLootButtons(button, "enabled", "Main Spec", "enabled", "Offspec")				
			-- if the player is eligible to roll off-spec, give them the roll buttons with Main Spec disabled.
			elseif button.item.status == "Eligible - Offspec" then
				MidnightLoot.UpdateLootButtons(button, "disabled", "Main Spec", "enabled", "Offspec")				
			-- if the player is supposed to trade the item, give them the trade button.
			elseif button.item.status == "Tradeable" then
				MidnightLoot.UpdateLootButtons(button, "hidden", "", "enabled", "Trade")			
			-- in all other states, the buttons are hidden.
			else
				MidnightLoot.UpdateLootButtons(button, "hidden", "", "hidden", "")
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
	--local isNewItem = true;
	local index = 0;
	local eligibleSpecs = MidnightLoot.eligibleSpecs[MidnightLoot.playerName];
	local isEligible = false;
	local playerClass = MidnightLoot.classReference[MidnightLoot.playerClass]['index']
	
	--[[Leaving this in here in case I revert, but UpdateLootItem should only ever fire after an item is already in ActiveLootItems now.
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
	]]--
	
	--Starting with ownerStatus, determine what the status of this loot item is to the player.
	local item = MidnightLoot.activeLootItems[index]
	-- PROBABLY SHOULD BUILD THE CHECKS FOR THE PLAYER'S OWN LOOT INTO HERE
	if ownerStatus == "Claimed" then
		item.status = "Claimed"
	elseif ownerStatus == "Locked" then
		item.status = "Locked"
	elseif ownerStatus == "Pending" then
		item.status = "Pending"		
	elseif ownerStatus == "Released" then
		if owner ~= MidnightLoot.playerName then
			if item.equipSlot == "INVTYPE_TRINKET" or item.subclass == "Artifact Relic" then
				--Cycle through the instance's loot, filtered by spec.
				--When/if the item is found in the spec-filtered list, upgrade the item's status as applicable from ineligible -> offspec -> main spec.
				--If it's never found, then it's not eligible.
				EJ_SelectInstance(MidnightLoot.instanceID)
				local statusRanking = {"Ineligible" = 0, "Eligible - Offspec" = 1, "Eligible" = 2}; 
				item.status = "Ineligible";
				for specID, eligibility in ipairs(eligibleSpecs) do
					EJ_SetLootFilter(playerClass, specID);
					for i = 1, EJ_GetNumLoot() do
						local _,_,_,_,ejItemID = GetLootInfoByIndex(i);
						if ejItemID == item.ID and statusRanking[eligibility] > statusRanking[item.status] then
							item.status = eligibility;
						end
					end
				end
			elseif item.class == "Armor" then -- *** It may be easier to just use the above code for all items.
				if item.subclass == "Miscellaneous" or item.subclass == MidnightLoot.classReference[MidnightLoot.playerClass]['armor'] then
					item.status = "Eligible"
				else
					item.status = "Ineligible"
				end
			end
		else
			item.status == "Released"
		end 
	else
		SendAddonMessage("MidnightLoot", "ERROR~".."Status of '"..ownerStatus.."' failed to parse.", "RAID");
	end
end

function MidnightLoot.SetInstanceID() -- ***NEED A HOOK TO FIRE THIS WHEN ENTERING AN INSTANCE OR LOADING THE ADDON.
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
			SendAddonMessage("MidnightLoot", "NEW_LOOT~"..itemLink.."~"..itemID.."~"..status, "RAID")
		end
	elseif event == "CHAT_MSG_ADDON" and ... == "MidnightLoot" then
		local _, messageStr, _, sender = ...;
		local messageData = {strsplit("~", messageStr)};
		if messageData[1] == "NEW_LOOT" then
			local _, itemLink, itemID, status = messageData;
			MidnightLoot.AddLoot(itemLink, itemID, sender);
		elseif messageData[1] == "UPDATE_LOOT" then
			local _, itemID, owner, status = messageData;
			MidnightLoot.UpdateLootItem(itemID, owner, status);
		elseif messageData[1] == "UPDATE_SPECS" then --*** function to update specs should determine what players' changed and only update those.
			--[[Example of output:
					MidnightLoot.eligibleSpecs['Volstatsz-AeriePeak'] = {
						[250] = 'Eligible',
						[251] = 'Eligible - Offspec',
						[252] = 'Ineligible',
						}
			]]--
			local _, player, playerClass, spec1, spec2, spec3, spec4 = messageData;
			local specs = {};
			local eligibility = {spec1, spec2, spec3, spec4};
			for specID, _ in ipairs(MidnightLoot.classReference[playerClass].specs) do
				table.insert(specs, specID);
			end
			for i = 1, 4 do
				if (i <= 2 or playerClass ~= "DEMONHUNTER") and (i <= 3 or playerClass == "DRUID") then
					MidnightLoot.eligibleSpecs[player][specs[i]] = eligibility[i];
				end
			end --STOPHERE (Adding chat message handling for known events.  I need to take the stuff out of "UPDATE_SPECS" and put it in its own function for consistency.)
		elseif messageData[1] == "ERROR" then
			table.insert(MidnightLoot.errors, {player = sender, timestamp = GetTime(), message = sendmessageData[2]});
		end	
	end
end
