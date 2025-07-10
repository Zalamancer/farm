local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Helper to find and delete the player's farm grid
local function deletePlayerFarm(player)
    local farmFolder = Workspace:FindFirstChild("farm")
    if not farmFolder then return end

    -- Convention: farm grid model is named "GrassFieldGrid_[UserId]"
    local gridName = "GrassFieldGrid_" .. tostring(player.UserId)
    local farmGrid = farmFolder:FindFirstChild(gridName)
    if farmGrid and farmGrid:IsA("Model") then
        farmGrid:Destroy()
    end
end

Players.PlayerRemoving:Connect(function(player)
    deletePlayerFarm(player)
end)

-- Optionally, clean up any leftover grids at server shutdown
game:BindToClose(function()
    local farmFolder = Workspace:FindFirstChild("farm")
    if not farmFolder then return end
    for _, obj in farmFolder:GetChildren() do
        if obj:IsA("Model") and obj.Name:match("^GrassFieldGrid_") then
            obj:Destroy()
        end
    end
end)

