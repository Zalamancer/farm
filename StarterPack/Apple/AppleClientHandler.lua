--!/usr/bin/env lua
-- Place this LocalScript inside your "Apple" Tool.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local eatAppleEvent = ReplicatedStorage:WaitForChild("EatApple")
local plantAppleTreeEvent = ReplicatedStorage:WaitForChild("PlantAppleTree")

local outlineFolder = Instance.new("Folder")
outlineFolder.Name = "PlantingOutline"
outlineFolder.Parent = tool

local lastTarget = nil

local function drawOutline(fields)
	outlineFolder:ClearAllChildren()
	if not fields then return end
	for _, field in ipairs(fields) do
		local outlineBox = Instance.new("Part")
		outlineBox.Name = "OutlineBox"
		outlineBox.Size = field.Size + Vector3.new(0.1, 0.1, 0.1)
		outlineBox.CFrame = field.CFrame
		outlineBox.Anchored = true
		outlineBox.CanCollide = false
		outlineBox.Transparency = 0.7
		outlineBox.Color = Color3.fromRGB(0, 255, 127)
		outlineBox.Material = Enum.Material.Neon
		outlineBox.Parent = outlineFolder
	end
end

RunService.RenderStepped:Connect(function()
	local target = mouse.Target
	if target == lastTarget then return end
	lastTarget = target

	if not (target and target.Name == "farmField" and target.Parent and target.Parent.Name == "Soil") then
		drawOutline(nil)
		return
	end

	local soilFolder = target.Parent
	local clickedGridPos = target:GetAttribute("GridPosition")
	if not clickedGridPos then
		drawOutline(nil)
		return
	end

	local potentialOrigins = {}
	for x = 0, 2 do for z = 0, 2 do table.insert(potentialOrigins, clickedGridPos - Vector2.new(x, z)) end end
	local validFields = nil
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
			if not foundField or foundField.Name ~= "farmField" or foundField:FindFirstChildOfClass("Model") then
				allFieldsAreValid = false
				break
			end
			table.insert(foundFields, foundField)
		end
		if allFieldsAreValid then
			validFields = foundFields
			break
		end
	end
	drawOutline(validFields)
end)

tool.Activated:Connect(function()
	local target = mouse.Target

	-- >> FIX: This is a more robust way to check if the target is part of the player's farm.
	local function isTargetOnFarm(part)
		if not part or not part.Parent then return false end
		local current = part
		for i = 1, 10 do -- Search up 10 levels
			if current.Name == player.Name .. "_Farm" then
				return true
			end
			current = current.Parent
			if not current or current == workspace then return false end
		end
		return false
	end

	-- If the player clicks on a valid farm field, attempt to plant.
	if target and target.Name == "farmField" and isTargetOnFarm(target) then
		plantAppleTreeEvent:FireServer(target)
		return -- Stop the function here so it doesn't also try to eat.
	end

	-- If the player clicks, but NOT on their own farm, then eat.
	if not isTargetOnFarm(target) then
		print("Player is not clicking on their farm, attempting to eat.")
		eatAppleEvent:FireServer()
	end
end)

tool.Unequipped:Connect(function()
	drawOutline(nil)
end)
