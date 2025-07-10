--!/usr/bin/env lua
-- Place this ModuleScript in ServerScriptService

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local FarmData = {}
FarmData.SessionData = {}

local farmDataStore = DataStoreService:GetDataStore("PlayerFarms")

local function onPlayerJoin(player)
	local userId = player.UserId
	local data

	local success, err = pcall(function()
		data = farmDataStore:GetAsync(tostring(userId))
	end)

	if success then
		if data then
			-- >> CFrame FIX: If farm objects exist, convert their CFrame data back from a table to a CFrame object.
			if data.farm_objects then
				for id, objectData in pairs(data.farm_objects) do
					if objectData.CFrameComponents then
						objectData.CFrame = CFrame.new(unpack(objectData.CFrameComponents))
						objectData.CFrameComponents = nil -- Remove the temporary table
					end
				end
			end

			FarmData.SessionData[userId] = data
			print("Loaded farm data for " .. player.Name)

			if not FarmData.SessionData[userId].farm_objects then
				FarmData.SessionData[userId].farm_objects = {}
			end
		else
			print("Creating new farm data for " .. player.Name)
			FarmData.SessionData[userId] = {
				farm_grid = {},
				inventory = { apples = 10, carrots = 10 }, -- Give starter carrots too
				farm_objects = {}
			}
			for i = 1, 100 do
				table.insert(FarmData.SessionData[userId].farm_grid, 0)
			end
		end
	else
		warn("Error loading farm data for " .. player.Name .. ": " .. err)
		player:Kick("Could not load your farm data. Please rejoin.")
	end
end

local function onPlayerLeave(player)
	local userId = player.UserId
	if FarmData.SessionData[userId] then

		-- >> CFrame FIX: Before saving, convert CFrame objects into a simple table of numbers.
		local dataToSave = table.clone(FarmData.SessionData[userId])
		if dataToSave.farm_objects then
			for id, objectData in pairs(dataToSave.farm_objects) do
				if typeof(objectData.CFrame) == "CFrame" then
					objectData.CFrameComponents = {objectData.CFrame:GetComponents()}
					objectData.CFrame = nil -- Remove the complex object before saving
				end
			end
		end

		local success, err = pcall(function()
			farmDataStore:SetAsync(tostring(userId), dataToSave)
		end)

		if success then
			print("Successfully saved farm data for " .. player.Name)
		else
			warn("Error saving farm data for " .. player.Name .. ": " .. err)
		end
		FarmData.SessionData[userId] = nil
	end
end

Players.PlayerAdded:Connect(onPlayerJoin)
Players.PlayerRemoving:Connect(onPlayerLeave)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerLeave(player)
	end
end)

return FarmData
