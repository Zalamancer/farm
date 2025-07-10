--!/usr/bin/env lua
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts

print("TreeClientManager: Starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local harvestFruitEvent = ReplicatedStorage:WaitForChild("HarvestFruit")

local COLOR_GREEN = Color3.fromHex("28B463")
local COLOR_RED = Color3.fromHex("E74C3C")

-- >> FIX: Create a table to track the debounce status for each tree individually.
local harvestDebounce = {}

local function setupTree(tree)
	print("TreeClientManager: Setting up new tree:", tree:GetFullName())

	local fruitFolder = tree:WaitForChild("tree", 5) and tree.tree:WaitForChild("fruit", 5)
	local prompt = tree:WaitForChild("ProximityPrompt", 5)
	local backgroundFrame = tree:WaitForChild("BillboardGui", 5) and tree.BillboardGui:WaitForChild("Frame", 5)

	if not (fruitFolder and prompt and backgroundFrame) then return end

	local statusBar = backgroundFrame:WaitForChild("StatusBar", 5)
	local statusText = backgroundFrame:WaitForChild("StatusText", 5)

	if not (statusBar and statusText) then return end

	statusBar.ZIndex = 1
	statusText.ZIndex = 2

	local totalFruit = tree:GetAttribute("MaxFruit") or #fruitFolder:GetChildren()

	local function updateBillboard()
		local remainingFruit = #fruitFolder:GetChildren()
		statusText.Text = tostring(remainingFruit) .. " / " .. tostring(totalFruit)

		if totalFruit > 0 then
			local percentage = remainingFruit / totalFruit
			statusBar.Size = UDim2.new(percentage, 0, 1, 0)
			statusBar.BackgroundColor3 = COLOR_GREEN:Lerp(COLOR_RED, 1 - percentage)
		else
			statusBar.Size = UDim2.new(0, 0, 1, 0)
			statusBar.BackgroundColor3 = COLOR_RED
		end
		prompt.Enabled = (remainingFruit > 0)
	end

	-- >> FIX: The entire Triggered connection has been updated for a better debounce.
	prompt.Triggered:Connect(function()
		-- 1. If this specific tree is on cooldown, do nothing.
		if harvestDebounce[tree] then return end

		-- 2. Set the cooldown for this tree.
		harvestDebounce[tree] = true

		-- 3. Fire the server event.
		harvestFruitEvent:FireServer(tree)

		-- 4. After 0.5 seconds, remove this tree from the cooldown table.
		task.delay(0.5, function()
			harvestDebounce[tree] = nil
		end)
	end)

	fruitFolder.ChildAdded:Connect(updateBillboard)
	fruitFolder.ChildRemoved:Connect(updateBillboard)

	updateBillboard()
	print("TreeClientManager: Finished setup for tree:", tree:GetFullName(), "with a max of", totalFruit, "fruit.")
end

-- Listen for the generic "FruitTree" tag
CollectionService:GetInstanceAddedSignal("FruitTree"):Connect(setupTree)
for _, tree in ipairs(CollectionService:GetTagged("FruitTree")) do
	setupTree(tree)
end

print("TreeClientManager: Ready.")
