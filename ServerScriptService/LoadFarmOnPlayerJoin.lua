local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Farm grid constants
local FARM_SIZE = 10
local GRASS_SIZE = 40

-- Helper to create a single grass part
local function createGrassPart(x, z, origin)
    local part = Instance.new("Part")
    part.Name = "grassField"
    part.Size = Vector3.new(GRASS_SIZE, 1, GRASS_SIZE)
    part.Anchored = true
    part.Material = Enum.Material.Grass
    part.Position = origin + Vector3.new(x * GRASS_SIZE, 0.5, z * GRASS_SIZE)
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

-- Helper to create the farm grid model for a player
local function createFarmForPlayer(player)
    local farmFolder = Workspace:FindFirstChild("farm")
    if not farmFolder then
        farmFolder = Instance.new("Folder")
        farmFolder.Name = "farm"
        farmFolder.Parent = Workspace
    end

    local gridName = "GrassFieldGrid_" .. tostring(player.UserId)
    if farmFolder:FindFirstChild(gridName) then
        return -- Already exists
    end

    local farmModel = Instance.new("Model")
    farmModel.Name = gridName

    -- Choose an origin for the farm (space out by userId to avoid overlap)
    local origin = Vector3.new((player.UserId % 100) * 500, 0, math.floor(player.UserId / 100) * 500)
    farmModel:SetAttribute("FarmOrigin", origin)

    for x = 0, FARM_SIZE - 1 do
        for z = 0, FARM_SIZE - 1 do
            local grass = createGrassPart(x, z, origin)
            grass.Parent = farmModel
        end
    end

    farmModel.Parent = farmFolder
end

Players.PlayerAdded:Connect(function(player)
    -- Delay to ensure Workspace is ready
    task.wait(1)
    createFarmForPlayer(player)
end)

-- Also create farms for players already in game (in case of script reset)
for _, player in Players:GetPlayers() do
    createFarmForPlayer(player)
end

