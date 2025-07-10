local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local database = DataStoreService:GetDataStore("data")
local sessionData = {}

function PlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local success = nil
	local playerData = nil
	local attempt = 1

	repeat
		success, playerData = pcall(function()
			return database:GetAsync(player.UserId)
		end)

		attempt += 1

		if not success then
			warn(playerData)
			task.wait(3)
		end
	until success or attempt == 5

	if success then
		print("Connected to database")

		if not playerData then
			print("Assigning default data")
			playerData = {
				["Coins"] = 100,
				["Foods"] = {"Strawberry", "Carrot", "Wheat", "Lettuce", "Berries"}
			}
		end

		sessionData[player.UserId] = playerData
	else
		warn("Unable to get data for", player.UserId)

		player:Kick("Unable to load your data. Try again later")
	end

	coins.Value = sessionData[player.UserId].Coins or 0

	coins.Changed:Connect(function()
		sessionData[player.UserId].Coins = coins.Value
	end)

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(PlayerAdded)

function PlayerLeaving(player)
	if sessionData[player.UserId] then
		local success = nil
		local errorMsg = nil
		local attempt = 1

		repeat
			success, errorMsg = pcall(function()
				database:SetAsync(player.UserId, sessionData[player.UserId])
			end)

			attempt += 1

			if not success then
				warn(errorMsg)
				task.wait(3)
			end
		until success or attempt == 5

		if success then
			print("Data saved for", player.Name)
		else
			warn("Unable to save for", player.Name)
		end
	end
end

Players.PlayerRemoving:Connect(PlayerLeaving)

function ServerShutDown()
	if RunService:IsStudio() then
		return
	end

	print("Server shutting down..")
	for i, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerLeaving(player)
		end)
	end
end

game:BindToClose(ServerShutDown)


--BUY ITEM

local buy = game.ReplicatedStorage.Buy

buy.OnServerEvent:Connect(function(player, price)
	local coins = player.leaderstats.Coins

	-- Server-side validation
	if coins.Value >= price then
		coins.Value -= price -- Deduct the price immediately
		print("Purchase successful for", player.Name)

		-- Update player data in the database
		local success, errorMsg = pcall(function()
			local playerData = database:GetAsync(player.UserId) or sessionData[player.UserId]
			playerData.Coins = coins.Value
			database:SetAsync(player.UserId, playerData)
		end)

		if success then
			print("Player data successfully updated in the database")
		else
			warn("Failed to update player data:", errorMsg)
		end
	else
		warn("Insufficient coins for player", player.Name)
	end
end)


-- Sell Item Event
local sell = game.ReplicatedStorage:WaitForChild("Sell")

sell.OnServerEvent:Connect(function(player, sellPrice)
	local coins = player.leaderstats.Coins

	-- Add sell price to player's coins
	local success, errorMsg = pcall(function()
		coins.Value += sellPrice
		local playerData = database:GetAsync(player.UserId) or sessionData[player.UserId]
		playerData.Coins = coins.Value
		database:SetAsync(player.UserId, playerData)
	end)

	if success then
		print("Successfully sold item for", player.Name, "coins added:", sellPrice)
	else
		warn("Failed to update coins for sell transaction:", errorMsg)
	end
end)
