--!/usr/bin/env lua
-- Place this script in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local harvestFruitEvent = ReplicatedStorage:WaitForChild("HarvestFruit")
local farmDataModule = require(ServerScriptService:WaitForChild("FarmDataStore"))

harvestFruitEvent.OnServerEvent:Connect(function(player, targetTree)
	if not targetTree or not targetTree:IsA("Model") or not targetTree.Parent then return end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local distance = (character.HumanoidRootPart.Position - targetTree.PrimaryPart.Position).Magnitude
	if distance > 20 then return end

	local fruitFolder = targetTree:FindFirstChild("tree", true) and targetTree.tree:FindFirstChild("fruit")
	if not fruitFolder or #fruitFolder:GetChildren() == 0 then return end

	-- >> DATA UPDATE LOGIC <<
	-- 1. Get the unique ID from the tree that was clicked
	local treeId = targetTree:GetAttribute("TreeId")
	if not treeId then
		warn("Harvest failed. Clicked tree is missing a 'TreeId' attribute.")
		return
	end

	local playerData = farmDataModule.SessionData[player.UserId]
	if not (playerData and playerData.inventory and playerData.farm_objects) then return end

	-- 2. Find the tree's data using its ID and update it
	local treeData = playerData.farm_objects[treeId]
	if treeData and treeData.FruitCount > 0 then
		treeData.FruitCount = treeData.FruitCount - 1
		print("Updated tree", treeId, "data. New fruit count:", treeData.FruitCount)
	else
		warn("Harvest failed. Could not find data for tree ID:", treeId, "or it's empty.")
		return
	end

	-- 3. Give the fruit to the player's inventory
	local fruitType = targetTree:GetAttribute("FruitType")
	if fruitType then
		if not playerData.inventory[fruitType] then playerData.inventory[fruitType] = 0 end
		playerData.inventory[fruitType] = playerData.inventory[fruitType] + 1
	end

	-- 4. Destroy the visual fruit part in the workspace
	local fruitToHarvest = fruitFolder:GetChildren()[1]
	fruitToHarvest:Destroy()
end)
