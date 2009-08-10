--[[
Grunt/Grunt.lua

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

Grunt = CreateFrame("Frame")
Grunt:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local debugf = tekDebug and tekDebug:GetFrame("Grunt")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end

local function IsFriend(name)
	for i = 1, GetNumFriends() do
		if GetFriendInfo(i) == name then
			return true
		end
	end
	return false
end

local function IsGuildMember(name)
	for i = 1, GetNumGuildMembers() do
		if GetGuildRosterInfo(i) == name then
			return true
		end
	end
	return false
end

function Grunt:PLAYER_LOGIN()
	LibStub("tekKonfig-AboutPanel").new(nil, "Grunt")

	-- Event handlers
	self:RegisterEvent("PLAYER_DEAD") -- PvP repop
	self:RegisterEvent("PARTY_INVITE_REQUEST") -- Accept group invites from friends and guildies
	self:RegisterEvent("PLAYER_QUITING") -- No more "Are you sure you wanna quit?" dialog

	-- Show/hide player nameplates when entering/leaving combat
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	-- Skip vendor gossip code
	self:RegisterEvent("GOSSIP_SHOW")

	-- The ultimate duel disable... 
	UIParent:UnregisterEvent("DUEL_REQUESTED")
end

function Grunt:PLAYER_REGEN_DISABLED()
	-- Show nameplates when entering combat
	SetCVar("nameplateShowEnemies", 1)
end

function Grunt:PLAYER_REGEN_ENABLED()
	-- Hide nameplates when leaving combat
	SetCVar("nameplateShowEnemies", 0)
end

function Grunt:PLAYER_DEAD()
	-- Auto-repop to graveyard if in a battleground and don't have a SS
	if (select(2,IsInInstance()) == "pvp") and not HasSoulstone() then RepopMe() end
end

function Grunt:PARTY_INVITE_REQUEST(event, sender)
	-- Auto-accept invites from guildies or friends
	if (IsFriend(sender) or IsGuildMember(sender)) then
		local frame = StaticPopup_FindVisible("PARTY_INVITE")
		if frame then
				frame.inviteAccepted = true
				AcceptGroup()
				frame:Hide()
		end
	end
end

function Grunt:PLAYER_QUITING()
	-- Hide that annoying "Are you sure you want to Quit?" dialog
	StaticPopup_Hide("QUIT")
	ForceQuit()
end

function Grunt:GOSSIP_SHOW()
	if not IsAltKeyDown() then
		self:SkipVendorGossip()
	end
end

function Grunt:SkipVendorGossip()
	local bwlText = "The orb's markings match the brand on your hand."
	local mcText = "You see large cavernous tunnels"
	local text = GetGossipText()

	if test == bwlText or strsub(text, 1, 31) == mcText then
		Debug("Skipping vendor gossip")
		SelectGossipOption(1)
	else
		local gossipOptions = { GetGossipOptions() }
		for i = 2, #gossipOptions, 2 do
			if gossipOptions[i] == "taxi" or gossipOptions[i] == "battlemaster" or gossipOptions[i] == "banker" then
				Debug("Skipping vendor gossip (2)")
				SelectGossipOption(i/2)
			end
		end
	end
end

if IsLoggedIn() then Grunt:PLAYER_LOGIN() else Grunt:RegisterEvent("PLAYER_LOGIN") end
