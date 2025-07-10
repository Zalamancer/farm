--!/usr/bin/env lua
-- Place this LocalScript inside your "Carrot" Tool.

local tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local RunService = game:GetService("RunService")

local plantCarrotEvent = game.ReplicatedStorage:WaitForChild("PlantCarrot")

-- Folder to hold the outline part
local outline = Instance.new("SelectionBox")
outline.LineThickness = 0.05
outline.Color3 = Color3.fromRGB(0, 150, 255)
outline.Adornee = nil
outline.Parent = tool

-- Function to update the outline every frame
local function onRenderStep()
	local target = mouse.Target
	-- Check if the mouse is pointing at a valid, empty dirt plot
	if target and target.Name == "farmField" and target:FindFirstChildOfClass("Model") == nil then
		outline.Adornee = target
	else
		outline.Adornee = nil
	end
end

tool.Activated:Connect(function()
	local target = mouse.Target
	if not (target and target:IsA("BasePart") and target.Name == "farmField") then return end
	local soilFolder = target.Parent
	if not (soilFolder and soilFolder.Name == "Soil") then return end
	local farmFolder = soilFolder.Parent
	if not (farmFolder and farmFolder.Name == player.Name .. "_Farm") then return end

	print("Client: Firing PlantCarrot event for target:", target:GetFullName())
	plantCarrotEvent:FireServer(target)
end)

-- Connect and disconnect the outline logic when the tool is equipped/unequipped
tool.Equipped:Connect(function()
	RunService:BindToRenderStep("CarrotOutline", Enum.RenderPriority.Input.Value, onRenderStep)
end)

tool.Unequipped:Connect(function()
	outline.Adornee = nil
	RunService:UnbindFromRenderStep("CarrotOutline")
end)
