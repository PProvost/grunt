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

local function HideStaticPopupFrame(type)
	local frame
	for i = 1, STATICPOPUP_NUMDIALOGS do
		frame = getglobal("StaticPopup" .. i)
		if frame.which == type then
			frame:Hide()
		end
	end
end

local function ClickStaticPopupFrame(type, button)
	local frame
	for i = 1, STATICPOPUP_NUMDIALOGS do
		frame = getglobal("StaticPopup" .. i)
		if frame.which == type then
			StaticPopup_OnClick(frame, button)
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

function Grunt:PLAYER_LOGIN()
	LibStub("tekKonfig-AboutPanel").new(nil, "Grunt")

	-- Event handlers
	self:RegisterEvent("PLAYER_DEAD") -- PvP repop
	self:RegisterEvent("PARTY_INVITE_REQUEST") -- Accept group invites from friends and guildies
	self:RegisterEvent("PLAYER_QUITING") -- No more "Are you sure you wanna quit?" dialog

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

function Grunt:PLAYER_DEAD()
	-- Auto-repop to graveyard if in a battleground and don't have a SS
	if (select(2,IsInInstance()) == "pvp") and not HasSoulstone() then RepopMe() end
end

function Grunt:PARTY_INVITE_REQUEST(event, sender)
	-- Auto-accept invites from guildies or friends
	if (IsFriend(sender) or IsGuildMember(sender)) then
		local frame
		for i = 1, STATICPOPUP_NUMDIALOGS do
			frame = getglobal("StaticPopup" .. i)
			if frame.which == "PARTY_INVITE" then
				frame.inviteAccepted = true
				AcceptGroup()
				frame:Hide()
			end
		end
	end
end

function Grunt:PLAYER_QUITING()
	-- Hide that annoying "Are you sure you want to Quit?" dialog
	HideStaticPopupFrame("QUIT")
	ForceQuit()
end

if IsLoggedIn() then Grunt:PLAYER_LOGIN() else Grunt:RegisterEvent("PLAYER_LOGIN") end

