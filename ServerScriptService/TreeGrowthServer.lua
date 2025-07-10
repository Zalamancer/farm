--!/usr/bin/env lua
-- Place this script in ServerScriptService

print("TreeGrowthServer: Script starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

-- Add waits with prints to find the problem
local farmDataModule = require(ServerScriptService:WaitForChild("FarmDataStore"))
print("TreeGrowthServer: Found FarmDataStore.")

local farmTemplates = ReplicatedStorage:WaitForChild("farm")
print("TreeGrowthServer: Found 'farm' folder.")

local treeTemplatesFolder = farmTemplates:WaitForChild("tree")
print("TreeGrowthServer: Found 'tree' folder.")

local finalPlantFolder = treeTemplatesFolder:WaitForChild("tree")
print("TreeGrowthServer: Found final plant 'tree' subfolder.")

-- A dictionary to hold all our plant templates for easy access
local plantTemplates = {
	appleSapling = finalPlantFolder:WaitForChild("appleTree"),
	carrotSapling = finalPlantFolder:WaitForChild("carrotTree")
}
print("TreeGrowthServer: Successfully loaded all plant templates. Setup complete.")

local GROWTH_CHECK_INTERVAL = 5

local function getMaterialUnderPosition(position)
	local rayOrigin = position + Vector3.new(0, 1, 0) -- Start the ray slightly above to avoid starting inside the ground
	local rayDirection = Vector3.new(0, -10, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}

	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		return raycastResult.Material
	end
	return nil
end

while true do
	task.wait(GROWTH_CHECK_INTERVAL)
	print("TreeGrowthServer: Running growth check cycle...")

	for _, farm in ipairs(Workspace:GetChildren()) do
		if farm:IsA("Folder") and farm.Name:match("_Farm$") then
			local soilFolder = farm:FindFirstChild("Soil")
			if soilFolder then
				for _, sapling in ipairs(soilFolder:GetChildren()) do
					local finalPlantTemplate = plantTemplates[sapling.Name]
					if finalPlantTemplate and sapling.PrimaryPart then

						local material = getMaterialUnderPosition(sapling.PrimaryPart.Position)
						print("TreeGrowthServer: Checking sapling '"..sapling.Name.."'... Ground material is: " .. tostring(material))

						if material == Enum.Material.LeafyGrass then
							print("TreeGrowthServer: LeafyGrass detected! Growing plant:", sapling.Name)
							sapling.Name = "growingSapling"

							local treeCFrame = sapling.PrimaryPart.CFrame
							local parentFolder = sapling.Parent

							local playerName = farm.Name:gsub("_Farm", "")
							local player = Players:FindFirstChild(playerName)
							if not player then continue end

							local playerData = farmDataModule.SessionData[player.UserId]
							if not playerData then continue end

							local treeId = HttpService:GenerateGUID(false)
							local maxFruit = finalPlantTemplate:GetAttribute("MaxFruit") or 0

							playerData.farm_objects[treeId] = {
								Template = finalPlantTemplate.Name,
								CFrame = treeCFrame,
								FruitCount = maxFruit
							}

							local newPlant = finalPlantTemplate:Clone()
							newPlant:SetPrimaryPartCFrame(treeCFrame)
							newPlant.Parent = parentFolder

							newPlant:SetAttribute("TreeId", treeId)
							CollectionService:AddTag(newPlant, "FruitTree")

							sapling:Destroy()
						end
					end
				end
			end
		end
	end
end
