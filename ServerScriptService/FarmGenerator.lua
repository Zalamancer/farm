--!/usr/bin/env lua
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Terrain = Workspace:WaitForChild("Terrain")

local farmDataModule = require(ServerScriptService:WaitForChild("FarmDataStore"))

-- Templates
local templateFolder = ReplicatedStorage:WaitForChild("farm")
local grassTileTemplate = templateFolder:FindFirstChild("grassField")
local farmFieldTemplate = templateFolder:FindFirstChild("farmField")

local fencePostTemplate = templateFolder:FindFirstChild("fencePost")
if not fencePostTemplate then
	warn("Could not find 'fencePost' template, creating a fallback.")
	fencePostTemplate = Instance.new("Part")
	fencePostTemplate.Name = "fencePost"
	fencePostTemplate.Size = Vector3.new(1, 5, 1)
	fencePostTemplate.Color = Color3.fromRGB(139, 69, 19)
	fencePostTemplate.Material = Enum.Material.Wood
	fencePostTemplate.Anchored = true
	fencePostTemplate.Parent = templateFolder
end

local fenceBridgeTemplate = templateFolder:FindFirstChild("fenceBridge")
if not fenceBridgeTemplate then
	warn("Could not find 'fenceBridge' template, creating a fallback.")
	fenceBridgeTemplate = Instance.new("Part")
	fenceBridgeTemplate.Name = "fenceBridge"
	fenceBridgeTemplate.Size = Vector3.new(0.5, 0.5, 5)
	fenceBridgeTemplate.Color = Color3.fromRGB(139, 69, 19)
	fenceBridgeTemplate.Material = Enum.Material.Wood
	fenceBridgeTemplate.Anchored = true
	fenceBridgeTemplate.Parent = templateFolder
end

local objectTemplates = {
	appleTree = templateFolder:WaitForChild("tree"):WaitForChild("tree"):WaitForChild("appleTree"),
	carrotTree = templateFolder:WaitForChild("tree"):WaitForChild("tree"):WaitForChild("carrotTree")
}

local GRID_WIDTH = 10
local GRID_LENGTH = 10
local TILE_SIZE = grassTileTemplate.Size
local FENCE_POST_SPACING = 5.5

local function createFencesBetween(startPost, endPost, parent, postTemplate, bridgeTemplate)
	local allPostsOnEdge = {startPost}
	local startPos = startPost.Position
	local endPos = endPost.Position
	local edgeVector = endPos - startPos
	local edgeLength = edgeVector.Magnitude
	local edgeDir = edgeVector.Unit

	local distance = FENCE_POST_SPACING
	while distance < edgeLength do
		local post = postTemplate:Clone()
		post.Parent = parent
		post.Position = startPos + edgeDir * distance
		post.Anchored = true
		table.insert(allPostsOnEdge, post)
		distance = distance + FENCE_POST_SPACING
	end
	table.insert(allPostsOnEdge, endPost)

	for i = 1, #allPostsOnEdge - 1 do
		local p1 = allPostsOnEdge[i]
		local p2 = allPostsOnEdge[i+1]
		local p1_pos = p1.Position
		local p2_pos = p2.Position
		local postHeight = p1.Size.Y
		local segmentVector = p2_pos - p1_pos
		local segmentLength = segmentVector.Magnitude
		local segmentDir = segmentVector.Unit
		local midPoint = (p1_pos + p2_pos) / 2

		local topBridge = bridgeTemplate:Clone()
		topBridge.Size = Vector3.new(bridgeTemplate.Size.X, bridgeTemplate.Size.Y, segmentLength)
		local topBridgePos = Vector3.new(midPoint.X, p1_pos.Y + postHeight / 2 - 1, midPoint.Z)
		topBridge.CFrame = CFrame.lookAt(topBridgePos, topBridgePos + segmentDir)
		topBridge.Parent = parent

		local bottomBridge = bridgeTemplate:Clone()
		bottomBridge.Size = Vector3.new(bridgeTemplate.Size.X, bridgeTemplate.Size.Y, segmentLength)
		local bottomBridgePos = Vector3.new(midPoint.X, p1_pos.Y - postHeight / 2 + 1, midPoint.Z)
		bottomBridge.CFrame = CFrame.lookAt(bottomBridgePos, bottomBridgePos + segmentDir)
		bottomBridge.Parent = parent
	end
end

local function createFarmForPlayer(player)
	if Workspace:FindFirstChild(player.Name .. "_Farm") then
		return
	end

	while not farmDataModule.SessionData[player.UserId] do task.wait() end

	local playerData = farmDataModule.SessionData[player.UserId]
	local farmFolder = Instance.new("Folder")
	farmFolder.Name = player.Name .. "_Farm"
	farmFolder.Parent = Workspace

	local soilFolder = Instance.new("Folder")
	soilFolder.Name = "Soil"
	soilFolder.Parent = farmFolder

	local startPosition = Vector3.new(-90, 10.5, -190)

	local farmSize = Vector3.new(GRID_WIDTH * TILE_SIZE.X, 20, GRID_LENGTH * TILE_SIZE.Z)
	local farmCenter = startPosition + Vector3.new((farmSize.X - TILE_SIZE.X) / 2, 0, (farmSize.Z - TILE_SIZE.Z) / 2)
	local farmRegion = Region3.new(farmCenter - farmSize / 2, farmCenter + farmSize / 2)
	local expandedRegion = farmRegion:ExpandToGrid(4)
	Terrain:ReplaceMaterial(expandedRegion, 4, Enum.Material.Grass, Enum.Material.Ground)

	for x = 1, GRID_WIDTH do
		for z = 1, GRID_LENGTH do
			local index = (x - 1) * GRID_LENGTH + z
			local tileType = playerData.farm_grid[index] or 0
			local newTile = (tileType == 1 and farmFieldTemplate or grassTileTemplate):Clone()
			newTile.Parent = soilFolder
			newTile.Position = startPosition + Vector3.new((x - 1) * TILE_SIZE.X, 0, (z - 1) * TILE_SIZE.Z)
			newTile:SetAttribute("GridPosition", Vector2.new(x, z))
		end
	end

	if playerData.farm_objects then
		for id, data in pairs(playerData.farm_objects) do
			local existingObjectFound = false
			for _, child in ipairs(soilFolder:GetChildren()) do
				if child:GetAttribute("TreeId") == id then
					existingObjectFound = true
					break
				end
			end
			if existingObjectFound then continue end

			local template = objectTemplates[data.Template]
			if template then
				-- >> THE FIX: This entire section has been replaced with the new, safer logic.
				local newObject = template:Clone()
				newObject:SetPrimaryPartCFrame(data.CFrame)

				local fruitFolder = newObject:FindFirstChild("tree", true):FindFirstChild("fruit")
				if fruitFolder then
					-- Figure out how many fruit to remove to match the saved data
					local maxFruit = template:GetAttribute("MaxFruit") or #fruitFolder:GetChildren()
					local fruitsToRemove = maxFruit - data.FruitCount

					-- Loop and destroy the extra fruit
					for i = 1, fruitsToRemove do
						if #fruitFolder:GetChildren() > 0 then
							fruitFolder:GetChildren()[1]:Destroy()
						else
							break -- Stop if we run out of fruit for some reason
						end
					end
				end

				newObject:SetAttribute("TreeId", id)
				CollectionService:AddTag(newObject, "FruitTree")
				newObject.Parent = soilFolder
			end
		end
	end

	local fencesFolder = Instance.new("Folder")
	fencesFolder.Name = "Fences"
	fencesFolder.Parent = farmFolder
	local postHeight = fencePostTemplate.Size.Y
	local groundY = startPosition.Y - TILE_SIZE.Y / 2
	local postCenterY = groundY + postHeight / 2
	local minX = startPosition.X - TILE_SIZE.X / 2
	local maxX = startPosition.X + (GRID_WIDTH - 1) * TILE_SIZE.X + TILE_SIZE.X / 2
	local minZ = startPosition.Z - TILE_SIZE.Z / 2
	local maxZ = startPosition.Z + (GRID_LENGTH - 1) * TILE_SIZE.Z + TILE_SIZE.Z / 2

	local cornerPost1 = fencePostTemplate:Clone()
	cornerPost1.Position = Vector3.new(minX, postCenterY, minZ)
	cornerPost1.Parent = fencesFolder
	cornerPost1.Anchored = true

	local cornerPost2 = fencePostTemplate:Clone()
	cornerPost2.Position = Vector3.new(maxX, postCenterY, minZ)
	cornerPost2.Parent = fencesFolder
	cornerPost2.Anchored = true

	local cornerPost3 = fencePostTemplate:Clone()
	cornerPost3.Position = Vector3.new(minX, postCenterY, maxZ)
	cornerPost3.Parent = fencesFolder
	cornerPost3.Anchored = true

	local cornerPost4 = fencePostTemplate:Clone()
	cornerPost4.Position = Vector3.new(maxX, postCenterY, maxZ)
	cornerPost4.Parent = fencesFolder
	cornerPost4.Anchored = true

	createFencesBetween(cornerPost1, cornerPost2, fencesFolder, fencePostTemplate, fenceBridgeTemplate)
	createFencesBetween(cornerPost2, cornerPost4, fencesFolder, fencePostTemplate, fenceBridgeTemplate)
	createFencesBetween(cornerPost4, cornerPost3, fencesFolder, fencePostTemplate, fenceBridgeTemplate)
	createFencesBetween(cornerPost3, cornerPost1, fencesFolder, fencePostTemplate, fenceBridgeTemplate)
end

Players.PlayerAdded:Connect(createFarmForPlayer)
