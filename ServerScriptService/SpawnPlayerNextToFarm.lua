local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Helper to get player's farm model and origin
local function getPlayerFarm(player)
    if _G.PlayerFarms and _G.PlayerFarms[player.UserId] then
        return _G.PlayerFarms[player.UserId], _G.PlayerFarms[player.UserId]:GetAttribute("FarmOrigin")
    end
    return nil, nil
end

-- Constants (should match PlayerFarmGenerator)
local FARM_SIZE = 10
local GRASS_SIZE = 40

-- Calculate spawn position: center of the player's farm, slightly above the grass
local function getSpawnCFrame(player)
    local farmModel, farmOrigin = getPlayerFarm(player)
    if farmOrigin then
        -- Center of farm: offset by half farm size in X and Z
        local centerOffset = Vector3.new((FARM_SIZE * GRASS_SIZE) / 2 - GRASS_SIZE/2, 0, (FARM_SIZE * GRASS_SIZE) / 2 - GRASS_SIZE/2)
        -- Y: 0.5 (grass center) + 1 (half grass height) + 2 (player above ground)
        local yOffset = 0.5 + 0.5 + 2
        local spawnPos = farmOrigin + centerOffset + Vector3.new(0, yOffset, 0)
        return CFrame.new(spawnPos)
    else
        -- Fallback to default spawn location
        local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
        if spawn then
            return spawn.CFrame + Vector3.new(0, 5, 0)
        else
            return CFrame.new(0, 5, 0)
        end
    end
end

local function moveCharacterToFarm(player)
    local character = player.Character
    if character and character:IsA("Model") then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            character:PivotTo(getSpawnCFrame(player))
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        moveCharacterToFarm(player)
    end)
end)

for _, player in Players:GetPlayers() do
    player.CharacterAdded:Connect(function()
        moveCharacterToFarm(player)
    end)
    if player.Character then
        moveCharacterToFarm(player)
    end
end

