--!/usr/bin/env lua
-- Place this script in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local farmDataModule = require(ServerScriptService:WaitForChild("FarmDataStore"))

-- Templates
local farmTemplates = ReplicatedStorage:WaitForChild("farm")
local treeTemplatesFolder = farmTemplates:WaitForChild("tree")
local saplingTemplatesFolder = treeTemplatesFolder:WaitForChild("sapling")

local appleSaplingTemplate = saplingTemplatesFolder:WaitForChild("appleSapling")
local carrotSaplingTemplate = saplingTemplatesFolder:WaitForChild("carrotSapling")

-- Remote Events
local eatAppleEvent = ReplicatedStorage:WaitForChild("EatApple")
local plantAppleTreeEvent = ReplicatedStorage:WaitForChild("PlantAppleTree")
local waterFarmPlotEvent = ReplicatedStorage:WaitForChild("WaterFarmPlot")
local plantCarrotEvent = ReplicatedStorage:WaitForChild("PlantCarrot")

local APPLE_HEAL_AMOUNT = 25

-- Listen for a player wanting to eat an apple
eatAppleEvent.OnServerEvent:Connect(function(player)
	local playerData = farmDataModule.SessionData[player.UserId]
	if not playerData or not playerData.inventory.apples or playerData.inventory.apples <= 0 then return end

	playerData.inventory.apples = playerData.inventory.apples - 1
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + APPLE_HEAL_AMOUNT)
		end
	end
end)

-- Logic for planting a 3x3 apple tree
plantAppleTreeEvent.OnServerEvent:Connect(function(player, clickedFarmField)
	if not (clickedFarmField and clickedFarmField:IsA("BasePart") and clickedFarmField.Name == "farmField") then return end
	local soilFolder = clickedFarmField.Parent
	if not (soilFolder and soilFolder.Name == "Soil") then return end
	local farmFolder = soilFolder.Parent
	if not (farmFolder and farmFolder.Name == player.Name .. "_Farm") then return end

	local clickedGridPos = clickedFarmField:GetAttribute("GridPosition")
	if not clickedGridPos then return end

	local potentialOrigins = {}
	for x = 0, 2 do for z = 0, 2 do table.insert(potentialOrigins, clickedGridPos - Vector2.new(x, z)) end end

	local fieldsToOccupy = {}
	local validOriginFound = false
	for _, originPos in ipairs(potentialOrigins) do
		local requiredPositions = {}
		for x = 0, 2 do for z = 0, 2 do table.insert(requiredPositions, originPos + Vector2.new(x, z)) end end
		local foundFields = {}
		local allFieldsAreValid = true
		for _, reqPos in ipairs(requiredPositions) do
			local foundField = nil
			for _, field in ipairs(soilFolder:GetChildren()) do
				if field:GetAttribute("GridPosition") == reqPos then foundField = field break end
			end
			if not foundField or foundField.Name ~= "farmField" or foundField:FindFirstChildOfClass("Model") then allFieldsAreValid = false break end
			table.insert(foundFields, foundField)
		end
		if allFieldsAreValid then fieldsToOccupy = foundFields validOriginFound = true break end
	end

	if not validOriginFound then return end

	local playerData = farmDataModule.SessionData[player.UserId]
	if not playerData or not playerData.inventory.apples or playerData.inventory.apples <= 0 then
		print(player.Name .. " tried to plant an apple tree but has no apples.")
		return
	end
	playerData.inventory.apples = playerData.inventory.apples - 1
	print(player.Name .. " planted an apple tree. Remaining apples: " .. playerData.inventory.apples)

	local totalPosition = Vector3.new(0, 0, 0)
	for _, field in ipairs(fieldsToOccupy) do totalPosition = totalPosition + field.Position end
	local centerPosition = totalPosition / 9
	local saplingCFrame = CFrame.new(centerPosition) * CFrame.new(0, appleSaplingTemplate.PrimaryPart.Size.Y / 2, 0)

	local newSapling = appleSaplingTemplate:Clone()
	newSapling:SetPrimaryPartCFrame(saplingCFrame)
	newSapling.Parent = soilFolder

	for _, field in ipairs(fieldsToOccupy) do field:Destroy() end
end)

-- Logic for watering a plot
local Terrain = workspace:WaitForChild("Terrain")
local TILE_SIZE = Vector3.new(4, 1, 4)
waterFarmPlotEvent.OnServerEvent:Connect(function(player, target)
	if not (target and (target:IsA("Model") or target:IsA("BasePart")) and target.Parent) then return end
	local soilFolder = target.Parent
	if not (soilFolder and soilFolder.Name == "Soil") then return end
	local farmFolder = soilFolder.Parent
	if not (farmFolder and farmFolder.Name == player.Name .. "_Farm") then return end
	local waterRegion
	if target:IsA("Model") and target.PrimaryPart then
		local saplingPosition = target.PrimaryPart.Position
		if target.Name == "appleSapling" then
			local groundCenter = saplingPosition - Vector3.new(0, target.PrimaryPart.Size.Y / 2, 0)
			local regionSize = Vector3.new(TILE_SIZE.X * 3, 20, TILE_SIZE.Z * 3)
			waterRegion = Region3.new(groundCenter - regionSize / 2, groundCenter + regionSize / 2)
		elseif target.Name == "carrotSapling" then
			local regionSize = Vector3.new(TILE_SIZE.X, 20, TILE_SIZE.Z)
			waterRegion = Region3.new(saplingPosition - regionSize / 2, saplingPosition + regionSize / 2)
		end
	elseif target:IsA("BasePart") and target.Name == "farmField" then
		local regionSize = Vector3.new(TILE_SIZE.X, 20, TILE_SIZE.Z)
		waterRegion = Region3.new(target.Position - regionSize / 2, target.Position + regionSize / 2)
	else
		return
	end
	if waterRegion then
		local expandedRegion = waterRegion:ExpandToGrid(4)
		Terrain:ReplaceMaterial(expandedRegion, 4, Enum.Material.Ground, Enum.Material.LeafyGrass)
	end
end)

-- Logic for planting a 1x1 carrot
plantCarrotEvent.OnServerEvent:Connect(function(player, targetField)
	if not (targetField and targetField:IsA("BasePart") and targetField.Name == "farmField") then return end
	local soilFolder = targetField.Parent
	if not (soilFolder and soilFolder.Name == "Soil") then return end
	local farmFolder = soilFolder.Parent
	if not (farmFolder and farmFolder.Name == player.Name .. "_Farm") then return end

	local playerData = farmDataModule.SessionData[player.UserId]
	if not playerData or not playerData.inventory.carrots or playerData.inventory.carrots <= 0 then
		print(player.Name .. " tried to plant a carrot but has none.")
		return
	end
	playerData.inventory.carrots = playerData.inventory.carrots - 1
	print(player.Name .. " planted a carrot. Remaining carrots: " .. playerData.inventory.carrots)

	local fieldCFrame = targetField.CFrame
	targetField:Destroy()

	local newSapling = carrotSaplingTemplate:Clone()
	newSapling:SetPrimaryPartCFrame(fieldCFrame)
	newSapling.Parent = soilFolder
end)
