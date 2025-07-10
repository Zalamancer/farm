--!/usr/bin/env lua
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

local farmDataModule = require(ServerScriptService:WaitForChild("FarmDataStore"))
local farmDataStore = DataStoreService:GetDataStore("PlayerFarms")

local ADMIN_USERNAMES = {
	["Gamer_Creative"] = true,
}

local function onPlayerChatted(player, message)
	if not ADMIN_USERNAMES[player.Name] then return end

	local words = message:split(" ")
	local command = words[1]:lower()
	local targetName = words[2]
	local amount = tonumber(words[3])

	if not targetName or not amount or amount <= 0 then
		print("Invalid format. Use: /<command> [PlayerName] [Amount]")
		return
	end

	local targetPlayer = Players:FindFirstChild(targetName)
	if not targetPlayer then
		print("Could not find a player named '" .. targetName .. "'.")
		return
	end

	local targetData = farmDataModule.SessionData[targetPlayer.UserId]
	if not targetData or not targetData.inventory then
		print("Could not access data for '" .. targetName .. "'.")
		return
	end

	-- --- /addapples Command ---
	if command == "/addapples" then
		if not targetData.inventory.apples then targetData.inventory.apples = 0 end
		targetData.inventory.apples = targetData.inventory.apples + amount
		print("Gave " .. amount .. " apples to " .. targetName .. ". They now have " .. targetData.inventory.apples .. ".")

		-- --- /addcarrots Command ---
	elseif command == "/addcarrots" then
		if not targetData.inventory.carrots then targetData.inventory.carrots = 0 end
		targetData.inventory.carrots = targetData.inventory.carrots + amount
		print("Gave " .. amount .. " carrots to " .. targetName .. ". They now have " .. targetData.inventory.carrots .. ".")

		-- --- /resetdata Command ---
	elseif command == "/resetdata" then
		-- Note: The reset command doesn't need an amount.
		local success, err = pcall(function()
			farmDataStore:RemoveAsync(tostring(targetPlayer.UserId))
		end)
		if success then
			print("Successfully removed data for " .. targetName .. " from the DataStore.")
			targetPlayer:Kick("Your game data has been reset by an administrator. Please rejoin.")
		else
			warn("Failed to remove data for " .. targetName .. ": " .. tostring(err))
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end)
