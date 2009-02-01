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

local function GetStaticPopupFrameOfType(type)
	local staticPopupFrame
	for i = 1, STATICPOPUP_NUMDIALOGS do
		staticPopupFrame = getglobal("StaticPopup" .. i)
		if staticPopupFrame.which == type then
			return staticPopupFrame
		end
	end
	return false
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
		SelectGossipOption(1)
	else
		local gossipOptions = { GetGossipOptions() }
		for i = 2, getn(gossipOptions), 2 do
			if (gossipOptions[i] == "taxi" or gossipOptions[i] == "battlemaster" or gossipOptions[i] == "banker") then
				SelectGossipOption(i / 2)
			end
		end
	end
end

local function QuestAutoTurnin()
	-- local activeGossipQuests = { GetGossipActiveQuests() }
	local i
	local numQuestsInLog = GetNumQuestLogEntries()

	for i = 1,numQuestsInLog do
		-- Note: We might need to actually check to see if the quest in the log is the one
		-- this NPC is proffering. It all depends on if IsQuestCompletable already deals with
		-- this or not.
		SelectQuestLogEntry(i)
		if IsQuestCompletable() then
			-- SelectGossipActiveQuest (might not need to do this before the next step, not sure)
			CompleteQuest()
		end
	end
end

function Grunt:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("RESURRECT_REQUEST")
	self:RegisterEvent("DUEL_REQUESTED")
	self:RegisterEvent("PARTY_INVITE_REQUEST")
	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("PLAYER_QUITING")

	LibStub("tekKonfig-AboutPanel").new(nil, "Grunt")
end

function Grunt:PLAYER_DEAD()
	-- Auto-repop to graveyard if in a battleground and don't have a SS
	if (select(2,IsInInstance()) == "pvp") and not HasSoulstone() then
		RepopMe()
	end
end

function Grunt:RESURRECT_REQUEST()
	-- Auto accept resurrect request
	if arg1 ~= "Chained Spirit" and GetCorpseRecoveryDelay() == 0 then
		local staticPopupFrame = GetStaticPopupFrameOfType("RESURRECT_NO_SICKNESS")
		if staticPopupFrame then
			AcceptResurrect()
			staticPopupFrame:Hide()
		end
	end
end

function Grunt:DUEL_REQUESTED()
	-- Decline all duels (not sure this is working right now)
	local staticPopupFrame = GetStaticPopupFrameOfType("DUEL_REQUEST")
	if staticPopupFrame then
		CancelDuel()
		staticPopupFrame:Hide()
	end
end

function Grunt:PLAYER_INVITE_REQUEST()
	-- Auto-accept invites from guildies or friends
	local staticPopupFrame = GetStaticPopupFrameOfType("PARTY_INVITE")
	if staticPopupFrame and (IsFriend(arg1) or IsGuildMember(arg1)) then
		AcceptGroup()
		staticPopupFrame:Hide()
	end
end

function Grunt:PLAYER_QUITTING()
	-- Hide that annoying "Are you sure you want to Quit?" dialog
	local staticPopupFrame = GetStaticPopupFrameOfType("QUIT")
	if staticPopupFrame then
		ForceQuit()
		staticPopupFrame:Hide()
	end
end

function Grunt:GOSSIP_SHOW()
	-- Skip gossip at vendors unless the ALT key is down
	if not IsAltKeyDown() then
		SkipVendorGossip()
		-- QuestAutoTurnin()
	end
end

if IsLoggedIn() then Grunt:PLAYER_LOGIN() else Grunt:RegisterEvent("PLAYER_LOGIN") end

