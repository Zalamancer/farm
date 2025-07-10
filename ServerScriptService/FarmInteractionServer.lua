-- FarmInteractionServer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local destroyBlockEvent = ReplicatedStorage:WaitForChild("DestroyFarmBlock")
local ServerScriptService = game:GetService("ServerScriptService")


-- Get the folder with our farm part templates
local farmTemplates = ReplicatedStorage:WaitForChild("farm")
-- Get the specific template for the tilled soil field
local farmFieldTemplate = farmTemplates:FindFirstChild("farmField")
-- Correctly require the ModuleScript
local farmDataModule = require(ServerScriptService:WaitForChild("FarmDataStore"))


destroyBlockEvent.OnServerEvent:Connect(function(player, blockToDestroy)
	-- First, check if our farmField template exists. If not, stop.
	if not farmFieldTemplate then
		warn("Could not find 'farmField' template in ReplicatedStorage.farm")
		return
	end

	-- Perform all the same security checks as before
	if not (blockToDestroy and blockToDestroy:IsA("BasePart") and blockToDestroy.Name == "grassField") then
		return
	end

	local soilFolder = blockToDestroy.Parent
	if not (soilFolder and soilFolder.Name == "Soil") then
		return
	end

	local farmFolder = soilFolder.Parent
	if not (farmFolder and farmFolder.Name == player.Name .. "_Farm") then
		return
	end

	--- Replacement and Data Update Logic ---
	-- 1. Get the grid position we stored as an attribute
	local gridPos = blockToDestroy:GetAttribute("GridPosition")
	if not gridPos then
		warn("Clicked on a farm block with no GridPosition attribute!")
		return
	end

	-- 2. Update the session data
	local index = (gridPos.X - 1) * 10 + gridPos.Y
	-- Access the data via the SessionData table
	-- Update the correct table in the player's data
	farmDataModule.SessionData[player.UserId].farm_grid[index] = 1

	-- 3. Get position and parent
	local blockCFrame = blockToDestroy.CFrame
	local parentFolder = blockToDestroy.Parent

	-- 4. Destroy the old grass block
	blockToDestroy:Destroy()

	-- 5. Clone and place the new farmField
	local newFarmField = farmFieldTemplate:Clone()
	newFarmField.CFrame = blockCFrame
	newFarmField.Anchored = true
	newFarmField.Parent = parentFolder
	newFarmField:SetAttribute("GridPosition", gridPos) -- Carry over the attribute

	print(player.Name .. " created a farm field and data was updated.")
end)