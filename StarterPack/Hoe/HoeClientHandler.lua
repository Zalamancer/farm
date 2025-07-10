-- This is a LocalScript and should be placed inside your "Hoe" Tool.

local tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

-- The RemoteEvent in ReplicatedStorage
local destroyBlockEvent = game.ReplicatedStorage:WaitForChild("DestroyFarmBlock")

tool.Activated:Connect(function()
	local target = mouse.Target

	-- Check if the player clicked on a valid part
	if not (target and target:IsA("BasePart")) then
		return
	end

	-- Check if the part is a grass field inside the player's own farm
	if target.Name == "grassField" then
		local soilFolder = target.Parent
		-- Verify the parent is the "Soil" folder
		if soilFolder and soilFolder.Name == "Soil" then
			local farmFolder = soilFolder.Parent
			-- Verify the farm folder belongs to the current player
			if farmFolder and farmFolder.Name == player.Name .. "_Farm" then
				-- If all checks pass, tell the server to destroy the block
				destroyBlockEvent:FireServer(target)
			end
		end
	end
end)