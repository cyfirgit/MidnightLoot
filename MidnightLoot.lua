local addonEnabled = true;
MidnightLootSaved = {};
MidnightLoot = {};
MidnightLoot.LOOT_ITEM_HEIGHT = 50;
MidnightLoot.ROLL_KINDS = {'main', 'off', 'pass'}
MidnightLoot.activeLootItems = {};
_, MidnightLoot.playerClass = UnitClass('PLAYER');
MidnightLoot.errors = {}
MidnightLoot.PREFIX = 'MidnightLoot'
MidnightLoot.activeRoster = {}
MidnightLoot.rolls = {}
MidnightLoot.intentions = {}
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


--[[* * * * * UI & Utility * * * * *]]--


function MidnightLoot_OnLoad(self)
	self:RegisterForDrag("LeftButton");
	
	self:RegisterEvent("BOSS_KILL")
	self:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("GROUP_ROSTER_CHANGED")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("CHAT_MSG_ADDON")
	
	SLASH_MIDNIGHTLOOT1, SLASH_MIDNIGHTLOOT2 = "/ml", "/midnightloot"
	SlashCmdList["MIDNIGHTLOOT"] = function(msg, editBox)
		self:SetShown(not self:IsShown())
	end
	
	self.scrollFrame.update = MidnightLoot.UpdateActiveLoot;
	self.scrollFrame.buttonHeight = MidnightLoot.LOOT_ITEM_HEIGHT;
	--self.scrollFrame.dynamic = MidnightLoot.CalculateDynamic;
	-- self.scrollFrame.stepSize = 12;
	self.scrollFrame.scrollBar.doNotHide = true;
	HybridScrollFrame_CreateButtons(self.scrollFrame, "MidnightLootItemFrameTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, 0, "TOPLEFT", "BOTTOMLEFT");
	MidnightLoot.UpdateActiveLoot();
	
	if UnitInParty("PLAYER") or UnitInRaid("PLAYER") then
		MidnightLoot.isInGroup = true
		--***Request Loot Status
	else
		MidnightLoot.isInGroup = false
	end
end

--***function MidnightLoot_Show(self)

function MidnightLoot_Hide(self)
	self:Hide();
end

function MidnightLoot_OnDragStart(self)
	self:StartMoving();
end

function MidnightLoot_OnDragStop(self)
	self:StopMovingOrSizing();
end

function MidnightLoot_LootIcon_OnEnter(self)
	local parent = self:GetParent();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetHyperlink(parent.item.link);
	CursorUpdate(self);
end

function MidnightLoot_LootButtonClick(self, kind)
	local parent = self:GetParent()
	local item = parent.item
	local intent = {
		["itemID"] = item.ID,
		["owner"] = item.owner,
		["kind"] = kind
		}
	if item.owner == MidnightLoot.playerName and kind == "Main Spec" then
		item.status = "Claimed"
		intent.kind = item.status
	elseif kind == "Pass" then
		item.status = "Passed"
	else
		item.status = ("Rolled - "..kind)
		RandomRoll(1, 100)
	end
	if item.owner == MidnightLoot.playerName then
		SendAddonMessage(MidnightLoot.PREFIX, "UPDATE_LOOT".."~"..item.ID.."~"..item.owner.."~"..item.status, "RAID")
	SendAddonMessage(MidnightLoot.PREFIX, "INTENT".."~"..intent.itemID.."~"..intent.owner.."~"..intent.kind, "RAID")
	MidnightLoot.UpdateActiveLoot()
end

function MidnightLoot_EventHandler(self, event, ...)
	if event == "BOSS_KILL" then
		MidnightLoot.BossKilled(...)
	elseif event == "ENCOUNTER_LOOT_RECEIVED" then
		MidnightLoot.LootDropped(...)
	elseif event == "CHAT_MSG_SYSTEM" then
		MidnightLoot.NewRoll(...)
	elseif event == "GROUP_ROSTER_CHANGED" then
		MidnightLoot.CheckGroupStatus()
	elseif event == "PLAYER_LOGIN" then
		MidnightLoot.LoadPlayerName()
	elseif event == "CHAT_MSG_ADDON" and ... == MidnightLoot.PREFIX then
		local _, messageStr, _, sender = ...;
		local messageData = {strsplit("~", messageStr)};
		if messageData[1] == "NEW_LOOT" then
			local itemLink = messageData[2];
			local status = messageData[3];
			MidnightLoot.AddLoot(itemLink, status, sender);
		elseif messageData[1] == "UPDATE_LOOT" then
			local itemID = messageData[2];
			local owner = messageData[3];
			local status = messageData[4];
			MidnightLoot.UpdateLootItem(itemID, owner, status);
		elseif messageData[1] == "UPDATE_SPECS" then 
			MidnightLoot.UpdateSpecs(messageData)
		elseif messageData[1] == "INTENT" then
			local itemID = messageData[2];
			local owner = messageData[3];
			local kind = messageData[4];
			local intent = {
				['itemID'] = itemID,
				['owner'] = owner,
				['kind'] = kind
			}
			MidnightLoot.NewIntent(sender, intent)
		elseif messageData[1] == "WINNER" and sender == MidnightLoot.LootMaster then
			local itemID = messageData[2];
			local owner = messageData[3];
			local player = messageData[4];
			local kind = messageData[5];
			MidnightLoot.ItemWon(itemID, owner, player, kind)
		elseif messageData[1] == "ROLLOFF_START" and sender == MidnightLoot.LootMaster then
			RandomRoll(1,100)
		elseif messageData[1] == "ERROR" then
			local errorMessage = messageData[2]
			table.insert(MidnightLoot.errors, {player = sender, timestamp = GetTime(), message = errorMessage});
		end	
	end
end

function MidnightLoot.LoadPlayerName()
	local playerNameTable = {UnitFullName("PLAYER")}
	MidnightLoot.playerName = playerNameTable[1].."-"..playerNameTable[2];
	MidnightLoot.homeRealm = playerNameTable[2]
end
	

function MidnightLoot.BossKilled(...)
	if UnitInRaid("PLAYER") or UnitInParty("PLAYER") then
		MidnightLoot.lastBoss = ...
		--Update the raid roster.
		table.wipe(MidnightLoot.activeRoster)
		table.wipe(MidnightLoot.rolls)
		table.wipe(MidnightLoot.intentions)
		for i = 1, GetNumGroupMembers() do
			local player = MidnightLoot.GetFullName(i)
			local _, playerClass = UnitClass("Raid"..i)
			MidnightLoot.activeRoster[player] = {
				['playerClass'] = playerClass,
				['isInRollOff'] = false,
				['rollOffRolls'] = {};
			}
			MidnightLoot.rolls[player] = {}
			MidnightLoot.intentions[player] = {}
		end
	end
end

function MidnightLoot.ParseItemLink(itemLink)
    local _, _, type = string.find(itemLink, "|.-|H(%a+).+")
    if type == "item" then
        local _, _, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, linkLevel, specID, upgradeTypeID, instanceDifficultyID, numBonusIDs, bonusIDString, name = string.find(itemLink, "|.-|Hitem:(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d-):(%d*):([:%d+]+)|h%[(.-)%]|.+")
		local bonusIDs = {}
		local upgradeValue, unknown1, unknown2, unknown3 = nil, nil, nil, nil
		local numElements = 2 -- 2 because unknown3 will be the remainder on bonusIDString.
		if numBonusIDs ~= "" then
			numBonusIDs = tonumber(numBonusIDs)
			numElements = numElements + numBonusIDs
		else
			numBonusIDs = 0
        end
		if upgradeTypeID ~= nil then
			numElements = numElements + 1
		end
		for i = 1, numElements do
			local _, _, bonus = string.find(bonusIDString, "(%d+):.*")
			table.insert(bonusIDs, bonus)
			bonusIDString = string.gsub(bonusIDString, "%d+:(.*)", "%1")
		end
		if upgradeTypeID ~= nil then
			upgradeValue = table.remove(bonusIDs, numBonusIDs + 1)
		end
		unknown1 = table.remove(bonusIDs, numBonusIDs + 1)
		unknown2 = table.remove(bonusIDs, numBonusIDs + 1)
		_, _, unknown3 = string.find(bonusIDString, "(%d+).*")
			
        return itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, linkLevel, specID, upgradeTypeID, instanceDifficultyID, numBonusIDs, bonusIDs, upgradeValue, unknown1, unknown2, unknown3, name
    end
end

function MidnightLoot.UpdateSpecs(messageData)
	--*** function to update specs should determine what players' changed and only update those.
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
	end
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
			local buttonState = {}
			button.item = MidnightLoot.activeLootItems[index]
			button.color = ITEM_QUALITY_COLORS[button.item.quality]
			button.lootIcon.texture:SetTexture(button.item.texture)
			button.itemName:SetText(button.item.name)
			button.owner:SetText(button.item.owner)
			if button.item.winner ~= nil then
				button.winner:SetText("Winner: "..button.item.winner)
			else
				button.winner:SetText(button.item.status)
			end
			button.itemName:SetVertexColor(button.color.r, button.color.g, button.color.b)
			-- if the item belongs to the player, they get all options.
			if button.item.status == "Pending" and button.item.owner == MidnightLoot.playerName then
				buttonState = {true, true, MidnightLoot.TestTransmog(button.item), true}				
			-- if the player is eligible to roll on the item, give them the roll buttons.
			elseif button.item.status == "Eligible" then
				buttonState = {true, true, MidnightLoot.TestTransmog(button.item), true}							
			-- if the player is eligible to roll off-spec, give them the roll buttons with Main Spec disabled.
			elseif button.item.status == "Eligible - Offspec" then
				buttonState = {false, true, MidnightLoot.TestTransmog(button.item), true}							
			-- in all other states, the buttons are hidden.
			else
				buttonState = {false, false, false, false}				
			end				
			button.mainSpecButton:SetShown(buttonState[1])
			button.offSpecButton:SetShown(buttonState[2])
			button.transmogButton:SetShown(buttonState[3])
			button.passButton:SetShown(buttonState[4])
			button:Show();
		else
			button:Hide();
		end
	end
	
	local totalHeight = numItems * MidnightLoot.LOOT_ITEM_HEIGHT;
	HybridScrollFrame_Update(scrollFrame, totalHeight, scrollFrame:GetHeight())
end

function MidnightLoot.RemoveLoot(index)
	table.remove(MidnightLoot.activeLootItems, index)
	MidnightLoot.UpdateActiveLoot()
end

function MidnightLoot.SetInstanceID() -- ***NEED A HOOK TO FIRE THIS WHEN ENTERING AN INSTANCE OR LOADING THE ADDON.
	MidnightLoot.instanceID = EJ_GetCurrentInstance()
end

function MidnightLoot.GetActiveLootIndex(itemID, owner)
	--Returns the index of a unique item in the activeLootItems table.
	for index, item in ipairs(MidnightLoot.activeLootItems) do
		if item.ID == itemID and item.owner == owner then
			return index
		end
	end
end

function MidnightLoot.GetFullName(player)
	local name = ''
	if type(player) == 'number' then
		name = GetRaidRosterInfo(player)
	else
		name = player
	end
	local isCrossRealm = name:find("-")
	if not isCrossRealm then
		name = name.."-"..MidnightLoot.homeRealm
	end
	return name
end

function MidnightLoot.CheckGroupStatus()
	if not (UnitInParty("PLAYER") or UnitInRaid("PLAYER")) and MidnightLoot.isInGroup then
		MidnightLoot.lastBoss = nil
		MidnightLoot.isInGroup = false
	end
end
	

--[[function MidnightLoot.CalculateDynamic(offset)
	local past = math.floor(offset / MidnightLoot.LOOT_ITEM_HEIGHT)
	local partial = offset % MidnightLoot.LOOT_ITEM_HEIGHT
	return past, partial
end]]


--[[* * * * * Item Detection & Categorization * * * * *]]--


function MidnightLoot.LootDropped(...)
	local encounterID, itemID, itemLink, quantity, simpleName, className = ...;
	local playerName = MidnightLoot.GetFullName(simpleName)
	if encounterID == MidnightLoot.lastBoss and playerName == MidnightLoot.playerName then
		local status = "";
		if MidnightLoot.TestTradeable(itemLink) then
			status = "Pending"
		else
			status = "Locked"
		end
		SendAddonMessage(MidnightLoot.PREFIX, "NEW_LOOT~"..itemLink.."~"..status, "RAID")
	end
end

function MidnightLoot.AddLoot(itemLink, status, owner)
	local item = {};
	item.results = {};
	item.owner = owner;
	item.ID = MidnightLoot.ParseItemLink(itemLink);
	item.link = itemLink
	item.status = status
	item.name, _, item.quality, item.level, item.reqLevel, item.class, item.subclass, item.maxStack, item.equipSlot, item.texture, item.vendorPrice = GetItemInfo(itemLink)
	--If it's an artifact relic, tag it with the appropriate type
	if item.subclass == "Artifact Relic" then
		_,_, item.relicType = C_ArtifactUI.GetRelicInfoByItemID(itemID)
	end
	if item.name ~= nil then
		table.insert(MidnightLoot.activeLootItems, item)
		MidnightLoot.UpdateActiveLoot()
	else
		SendAddonMessage(MidnightLoot.PREFIX, "ERROR~".."ID "..itemID.." has nil response.", "RAID")
	end
	MidnightLootFrame:Show()
	return getn(MidnightLoot.activeLootItems);
end

function MidnightLoot.UpdateLootItem(itemID, owner, ownerStatus)
	--Update loot information for an existing item with the owner's decision.
	local numItems = getn(MidnightLoot.activeLootItems);
	local index = MidnightLoot.GetActiveLootIndex(itemID, owner)
	local item = MidnightLoot.activeLootItems[index]
	local eligibleSpecs = MidnightLoot.eligibleSpecs[MidnightLoot.playerName];
	local playerClass = MidnightLoot.classReference[MidnightLoot.playerClass]['index']
	local isEligible = false;
	
	--Starting with ownerStatus, determine what the status of this loot item is to the player.
	if ownerStatus == "Claimed" then
		item.status = "Claimed"
	elseif ownerStatus == "Locked" then
		item.status = "Locked"
	elseif ownerStatus == "Off Spec" or ownerStatus == "Transmog" or ownerStatus == "Passed" then
		if owner ~= MidnightLoot.playerName then
			if item.equipSlot == "INVTYPE_TRINKET" or item.subclass == "Artifact Relic" then
				--Cycle through the instance's loot, filtered by spec.
				--When/if the item is found in the spec-filtered list, upgrade the item's status as applicable from ineligible -> offspec -> main spec.
				--If it's never found, then it's not eligible.
				EJ_SelectInstance(MidnightLoot.instanceID)
				local statusRanking = {["Ineligible"] = 0, ["Eligible - Offspec"] = 1, ["Eligible"] = 2}; 
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
			item.status = "Released"
		end 
	else
		SendAddonMessage(MidnightLoot.PREFIX, "ERROR~".."Status of '"..ownerStatus.."' failed to parse.", "RAID");
	end
end

function MidnightLoot.TestTradeable(itemLink)
	--Loads an item link into a hidden tooltip, then scans the tooltip to determine if the item is tradable.
	for i = 0, 4 do
		for j = 1, GetContainterNumSlots(i) do
			local item = {GetContainerItemInfo(i, j)}
			local containerItemLink = item[7]
			if containerItemLink == itemLink then
				MidnightLootScanTooltip:ClearLines()
				MidnightLootScanTooltip:SetHyperlink(containerItemLink)
				local tooltipRegions = MidnightLootScanTooltip:GetRegions()
				for i = 1, select("#", tooltipRegions) do
					local region = select(i, tooltipRegions)
					if region and region:GetObjectType() == "FontString" then
						local text = region:GetText()
						if text ~= nil then
							local findTrade = string.find(text, "trade this item")
							if findTrade then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

--[[function MidnightLoot.TestTradable(itemLink)
	--NOTE: This is an old version of TestTradeable.  Saving it for now in case the new version the the bad.
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
end]]--

function MidnightLoot.TestTransmog(item)
	--Checks if the item is transmog eligible for the player.
	return item.class == "Armor" and (item.subclass == MidnightLoot.classReference[MidnightLoot.playerClass]['armor'] or item.equipSlot == "INVTYPE_CLOAK")
end


--[[* * * * * Loot Award Decision * * * * *]]--


function MidnightLoot.NewRoll(...)
	local message = ...
	if message:find("1-100") ~= nil and getn(MidnightLoot.activeLootItems) > 0 then
		local msgPlayer, msgRoll = message:match("^(.+) .+ (%d+) %(1%-100%)$")
		local player = MidnightLoot.GetFullName(msgPlayer)
		local roll = tonumber(msgRoll)
		local intentions = MidnightLoot.intentions[player]
		--[[We have to check if the player has a rolloff active,
		and handle the roll differently in that case.]]
		if MidnightLoot.activeRoster[player].isInRollOff == true then
			table.insert(MidnightLoot.activeRoster[player].rollOffRolls, roll)
			for index, item in ipairs(MidnightLoot.activeLootItems) do
				if item.tiedRollers ~= nil then
					local rollOffComplete = true
					for _, result in ipairs(item.tiedRollers) do
						if getn(MidnightLoot.activeRoster[result.player].rollOffRolls) == 0 then
							rollOffComplete = false
							break
						end
					end
					if rollOffComplete == true then
						--This item's rolloff has rolls in from all players.
						--[[Pop the first rolloff from each of the competing
						players' rolloff rolls and place it in the tiedRollers
						table, and start building a highRoller/tiedRollers again.]]
						local highRoller = {['rollOffRoll'] = 0}
						local tiedRollers = {}
						for _, result in ipairs(item.tiedRollers) do
							result.rollOffRoll = table.remove(MidnightLoot.activeRoster[result.player].rollOffRolls, 1)
							if result.rollOffRoll > highRoller.rollOffRoll then
								highRoller = result
								table.wipe(tiedRollers)
							elseif result.rollOffRoll == highRoller.rollOffRoll then
								table.insert(tiedRollers, result)
							end
						end
						--If we still have a tie, start it all over.  Otherwise, alhamdu Allah we're done and tell everyone that.
						if getn(tiedRollers) > 0 then
							table.insert(tiedRollers, highRoller)
							item.tiedRollers = tiedRollers
							for _, result in ipairs(tiedRollers) do
								SendAddonMessage(MidnightLoot.PREFIX, ("ROLLOFF_START".."~"..item.ID.."~"..item.owner), "WHISPER", result.player)
							end
						else
							item.winner = highRoller
							MidnightLoot.RollComplete(itemID, owner)
							item.tiedRollers = nil
						end
					end
				end
			end				
		else
		--[[Check if there is a matching loot intent to pair a roll to. If there
		is, link them and start saving to results. If not, save the roll for an
		intent to arrive.]]
			if getn(intentions) > 0 then
				MidnightLoot.AddResult(player, roll, table.remove(intentions, 1))
			else
				table.insert(MidnightLoot.rolls[player], roll)
			end
		end
	end
end

function MidnightLoot.NewIntent(player, intent)
	--Check if there is a matching loot roll to pair an intent to.
	--If there is, link them and start saving to results.
	--If not, save the intent for a roll to arrive.
	local rolls = MidnightLoot.rolls[player]
	if intent.kind == "Claimed" and player == intent.owner then
		index = MidnightLoot.GetActiveLootIndex(intent.itemID, intent.owner)
		item = MidnightLoot.activeLootItems[index]
		item.winner = {["player"] = player, ["kind"] = "Claimed"}
		SendAddonMessage(MidnightLoot.PREFIX, "WINNER".."~"..item.ID.."~"..item.owner.."~"..item.winner.player.."~"..item.winner.kind, "RAID")
	elseif intent.kind == "Pass" then
		MidnightLoot.AddResult(player, nil, intent)
	else
		if getn(rolls) > 0 then
			MidnightLoot.AddResult(player, table.remove(rolls, 1), intent)
		else
			table.insert(MidnightLoot.intentions[player], intent)
		end
	end
end

function MidnightLoot.AddResult(player, roll, intent)
	--Take the paired roll and intent, and save them to the results table.
	local index = MidnightLoot.GetActiveLootIndex(intent.itemID, intent.owner)
	local result = {
		['player'] = player,
		['roll'] = roll,
		['kind'] = intent.kind,
	}
	table.insert(MidnightLoot.activeLootItems[index].results, result)
	--If this completes the rolls, determine the winner.
	local results = MidnightLoot.activeLootItems[index].results
	local totalResults = 0
	for _, kindResults in ipairs(results) do
		totalResults = totalResults + kindResults
	end
	if totalResults == getn(MidnightLoot.intentions) then
		MidnightLoot.DetermineWinner(index)
	end
end

function MidnightLoot.DetermineWinner(itemID, owner)
	local index = MidnightLoot.GetActiveLootIndex(itemID, owner)
	local item = MidnightLoot.activeLootItems[index]
	local winner = {}
	for _, kind in ipairs(MidnightLoot.ROLL_KINDS) do
		if kind ~= 'pass' then
			if getn(item.results[kind]) > 0 then
				local highRoller = {['roll'] = 0}
				local tiedRollers = {}
				for _, result in ipairs(item.results[kind]) do
					if result.roll > highRoller.roll then
						highRoller = result
						table.wipe(tiedRollers)
					elseif result.roll == highRoller.roll then
						table.insert(tiedRollers, result)
					end
				end
				if getn(tiedRollers) > 0 then
					table.insert(tiedRollers, highRoller)
					MidnightLoot.activeLootItems[index].tiedRollers = tiedRollers
					for _, result in ipairs(tiedRollers) do
						SendAddonMessage(MidnightLoot.PREFIX, ("ROLLOFF_START".."~"..itemID.."~"..owner), "WHISPER", result.player)
					end
				else
					winner = highRoller
				end
				break
			end
		else
			winner = {
				['player'] = MidnightLoot.disenchanter, 
				['kind'] = 'Disenchant'
			}
		end
	end
	if getn(winner) > 0 then
		MidnightLoot.activeLootItems[index].winner = winner
		MidnightLoot.RollComplete(itemID, owner)
	end
end	

function MidnightLoot.RollComplete(itemID, owner)
	local index = MidnightLoot.GetActiveLootIndex(itemID, owner)
	local item = MidnightLoot.activeLootItems[index]
	for player, rolls in ipairs(MidnightLoot.rolls) do
		if getn(rolls) > 0 then
			SendAddonMessage(MidnightLoot.PREFIX, "ROLL_WARNING", "WHISPER", player)
			table.wipe(rolls)
		end
	end
	SendAddonMessage(MidnightLoot.PREFIX, "WINNER".."~"..itemID.."~"..owner.."~"..item.winner.player.."~"..item.winner.kind, "RAID")
end

function MidnightLoot.ItemWon(itemID, owner, player, kind)
end

function MidnightLoot.TestTradeRange(player)
	local playerName = Ambiguate(player, "none")
	return CheckInteractDistance(playerName, 2)
end