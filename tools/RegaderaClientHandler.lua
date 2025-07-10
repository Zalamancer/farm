--!/usr/bin/env lua
-- Place this LocalScript inside your "Regadera" (Watering Can) Tool.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = script.Parent
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local waterFarmPlotEvent = ReplicatedStorage:WaitForChild("WaterFarmPlot")

-- A SelectionBox for single objects (carrots, empty plots)
local selectionOutline = Instance.new("SelectionBox")
selectionOutline.LineThickness = 0.05
selectionOutline.Color3 = Color3.fromRGB(0, 150, 255)
selectionOutline.Adornee = nil
selectionOutline.Parent = tool

-- A Part for the large 3x3 apple area
local areaOutline = Instance.new("Part")
areaOutline.Name = "AreaOutline"
areaOutline.Size = Vector3.new(12, 0.2, 12)
areaOutline.Anchored = true
areaOutline.CanCollide = false
areaOutline.Transparency = 0.7
areaOutline.Color = Color3.fromRGB(0, 150, 255)
areaOutline.Material = Enum.Material.Neon
-- >> FIX: Hide the part by parenting it to nil initially
areaOutline.Parent = nil

-- Helper function to find the parent sapling model
local function findSaplingModel(part)
	if not part or not part.Parent then return nil end
	local currentPart = part
	for i = 1, 5 do
		if currentPart.Name == "appleSapling" or currentPart.Name == "carrotSapling" then
			return currentPart
		end
		currentPart = currentPart.Parent
		if not currentPart or currentPart == workspace then return nil end
	end
	return nil
end

local function onRenderStep()
	local target = mouse.Target
	local saplingModel = findSaplingModel(target)

	selectionOutline.Adornee = nil
	-- >> FIX: Hide the part by parenting it to nil each frame
	areaOutline.Parent = nil

	if saplingModel and saplingModel.PrimaryPart then
		if saplingModel.Name == "appleSapling" then
			areaOutline.CFrame = saplingModel.PrimaryPart.CFrame
			-- >> FIX: Show the part by parenting it to the tool
			areaOutline.Parent = tool
		elseif saplingModel.Name == "carrotSapling" then
			selectionOutline.Adornee = saplingModel.PrimaryPart
		end
	elseif target and target.Name == "farmField" then
		selectionOutline.Adornee = target
	end
end

tool.Activated:Connect(function()
	local target = mouse.Target
	local saplingModel = findSaplingModel(target)

	local targetToSend
	if saplingModel then
		targetToSend = saplingModel
	elseif target and target.Name == "farmField" then
		targetToSend = target
	else
		return
	end

	local soilFolder = targetToSend.Parent
	if not (soilFolder and soilFolder.Name == "Soil") then return end

	local farmFolder = soilFolder.Parent
	if not (farmFolder and farmFolder.Name == player.Name .. "_Farm") then return end

	waterFarmPlotEvent:FireServer(targetToSend)
end)

tool.Equipped:Connect(function()
	RunService:BindToRenderStep("WateringOutline", Enum.RenderPriority.Input.Value, onRenderStep)
end)

tool.Unequipped:Connect(function()
	selectionOutline.Adornee = nil
	-- >> FIX: Ensure the part is hidden when unequipped
	areaOutline.Parent = nil
	RunService:UnbindFromRenderStep("WateringOutline")
end)
