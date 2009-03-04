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

local SelectQuestLogEntry = _G.SelectQuestLogEntry
local IsQuestCompletable = _G.IsQuestCompletable
local CompleteQuest = _G.CompleteQuest

Grunt = CreateFrame("Frame")
Grunt:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local debugf = tekDebug and tekDebug:GetFrame("Grunt")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end

local function HideStaticPopupFrame(type)
	local frame
	for i = 1, STATICPOPUP_NUMDIALOGS do
		frame = getglobal("StaticPopup" .. i)
		if frame.which == type then
			frame:Hide()
		end
	end
end

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

local function SkipVendorGossip()
	local bwlText = "The orb's markings match the brand on your hand."
	local mcText = "You see large cavernous tunnels"
	local text = GetGossipText()


	if text == bwlText or strsub(text, 1, 31) == mcText then
		Debug("Skipping vendor gossip (1)")
		SelectGossipOption(1)
	else
		local gossipOptions = { GetGossipOptions() }
		for i = 2, getn(gossipOptions), 2 do
			if (gossipOptions[i] == "taxi" or gossipOptions[i] == "battlemaster" or gossipOptions[i] == "banker") then
				Debug("Skipping vendor gossip (2)")
				SelectGossipOption(i / 2)
			end
		end
	end
end

function Grunt:PLAYER_LOGIN()
	LibStub("tekKonfig-AboutPanel").new(nil, "Grunt")

	-- Event handlers
	self:RegisterEvent("PLAYER_DEAD") -- PvP repop
	self:RegisterEvent("PARTY_INVITE_REQUEST") -- Accept group invites from friends and guildies
	self:RegisterEvent("GOSSIP_SHOW") -- Hide useless gossip unless Alt pressed
	self:RegisterEvent("PLAYER_QUITING") -- No more "Are you sure you wanna quit?" dialog

	-- self:RegisterEvent("RESURRECT_REQUEST")

	-- Show/hide player nameplates when entering/leaving combat
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

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

function Grunt:RESURRECT_REQUEST(name)
	-- TODO: Make this happen only if the person casting it on me isn't in combat
	Debug("RESURRECT_REQUEST from " .. name)
	if name ~= "Chained Spirit" and GetCorpseRecoveryDelay() == 0 --[[ and not UnitAffectingCombat(name) ]] then
		AcceptResurrect()
		HideStaticPopupFrame("RESURRECT_NO_SICKNESS")
	end
end

function Grunt:PLAYER_DEAD()
	-- Auto-repop to graveyard if in a battleground and don't have a SS
	-- TODO: Add Wintergrasp support
	if (select(2,IsInInstance()) == "pvp") and not HasSoulstone() then
		RepopMe()
	end
end

function Grunt:PARTY_INVITE_REQUEST(event, sender)
	-- Auto-accept invites from guildies or friends
	Debug("PARTY_INVITE_REQUEST - " .. tostring(sender))
	if (IsFriend(sender) or IsGuildMember(sender)) then
		AcceptGroup()
		HideStaticPopupFrame("PARTY_INVITE")
	end
end

function Grunt:PLAYER_QUITING()
	-- Hide that annoying "Are you sure you want to Quit?" dialog
	Debug("PLAYER_QUITING")
	HideStaticPopupFrame("QUIT")
	ForceQuit()
end

function Grunt:GOSSIP_SHOW()
	-- Skip gossip at vendors unless the ALT key is down
	if not IsAltKeyDown() then
		SkipVendorGossip()
	end
end

if IsLoggedIn() then Grunt:PLAYER_LOGIN() else Grunt:RegisterEvent("PLAYER_LOGIN") end

