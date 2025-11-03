local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "Wnz Hub",
    Subtitle = "Rogue Piece",
    Size = UDim2.fromOffset(650, 480),
    DragStyle = 2,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local isMinimized = false
local function toggleFluent()
    isMinimized = not isMinimized
    Window:Minimize(isMinimized)
end

-- small logo button (kept from original)
local logoGui = Instance.new("ScreenGui")
logoGui.Name = "FluentLogoToggle"
logoGui.ResetOnSpawn = false
logoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
logoGui.Parent = player:WaitForChild("PlayerGui")

local logoButton = Instance.new("ImageButton")
logoButton.Name = "LogoButton"
logoButton.Size = UDim2.new(0, 50, 0, 50)
logoButton.Position = UDim2.new(0, 10, 0, 10)
logoButton.BackgroundTransparency = 1
logoButton.Image = "rbxassetid://98905775020119"
logoButton.Parent = logoGui

logoButton.Activated:Connect(toggleFluent)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftControl then
        toggleFluent()
    end
end)

-- Variables
local farmingEnabled = false
local questFarmEnabled = false
local selectedMob = nil
local selectedQuestNPC = nil
local autoClickConnection = nil
local farmConnection = nil
local questFarmConnection = nil
local proximityPromptConnection = nil
local autoStatsEnabled = false
local selectedStats = {}
local autoStatsConnection = nil
local farmPosition = "Behind"

-- Handle character respawn
local function onCharacterAdded(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")

    setupBlacklist()

    if farmingEnabled then
        task.wait(1)
        autoClick()
        startAutoFarm()
    end

    if questFarmEnabled then
        task.wait(1)
        autoClick()
        startQuestFarm()
    end

    if autoStatsEnabled then
        task.wait(1)
        allocateStats()
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Blacklist helpers (unchanged)
local blacklistedNames = {}
local function setupBlacklist()
    blacklistedNames = {}
    blacklistedNames["Dummy"] = true

    for _, player in pairs(Players:GetPlayers()) do
        blacklistedNames[player.Name] = true
    end
end
setupBlacklist()

Players.PlayerAdded:Connect(function(player)
    blacklistedNames[player.Name] = true
end)

Players.PlayerRemoving:Connect(function(player)
    blacklistedNames[player.Name] = nil
end)

local function getValidPart(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local function isBlacklisted(model)
    return blacklistedNames[model.Name] == true
end

local function getAllMobsDeep(folder)
    local results = {}
    for _, obj in pairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and not isBlacklisted(obj) and obj ~= Character then
                table.insert(results, obj)
            end
        elseif obj:IsA("Folder") then
            local nested = getAllMobsDeep(obj)
            for _, found in pairs(nested) do
                table.insert(results, found)
            end
        end
    end
    return results
end

local function getAllMobs()
    local mobNames = {}
    local mobsSet = {}
    local charactersFolder = workspace.Main:FindFirstChild("Characters")
    if not charactersFolder then return mobNames end

    local function searchFolder(folder)
        for _, obj in pairs(folder:GetChildren()) do
            if obj:IsA("Model") then
                local humanoid = obj:FindFirstChildOfClass("Humanoid")
                if humanoid and not isBlacklisted(obj) and not mobsSet[obj.Name] then
                    mobsSet[obj.Name] = true
                    table.insert(mobNames, obj.Name)
                end
            elseif obj:IsA("Folder") then
                searchFolder(obj)
            end
        end
    end

    searchFolder(charactersFolder)
    return mobNames
end

local function getAllMaps()
    local maps = {}
    local mapsFolder = workspace:FindFirstChild("Maps")
    if mapsFolder then
        for _, v in pairs(mapsFolder:GetChildren()) do
            table.insert(maps, v.Name)
        end
    end
    return maps
end

local function getAllQuestNPCs()
    local npcs = {}
    local questsFolder = workspace.Main.NPCs:FindFirstChild("Quests")
    if questsFolder then
        for _, v in pairs(questsFolder:GetChildren()) do
            table.insert(npcs, v.Name)
        end
    end
    return npcs
end

local function getCombatSellers()
    local sellers = {}
    local combatFolder = workspace.Main.NPCs:FindFirstChild("Combat")
    if combatFolder then
        for _, v in pairs(combatFolder:GetChildren()) do
            if v:IsA("Model") then
                table.insert(sellers, v.Name)
            end
        end
    end
    return sellers
end

local function getSwordSellers()
    local sellers = {}
    local swordFolder = workspace.Main.NPCs:FindFirstChild("Sword")
    if swordFolder then
        for _, v in pairs(swordFolder:GetChildren()) do
            if v:IsA("Model") then
                table.insert(sellers, v.Name)
            end
        end
    end
    return sellers
end

local function teleportTo(cframe)
    if Character and HumanoidRootPart then
        -- Use a safe teleport (unground then set)
        HumanoidRootPart.CFrame = cframe
        HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
    end
end

local function findNearestMob(mobName)
    local charactersFolder = workspace.Main:FindFirstChild("Characters")
    if not charactersFolder then return nil end

    local allMobs = getAllMobsDeep(charactersFolder)
    local nearestMob = nil
    local shortestDistance = math.huge

    for _, mob in pairs(allMobs) do
        if not mobName or mob.Name:lower():find(mobName:lower()) then
            local mobRoot = getValidPart(mob)

            if mobRoot and HumanoidRootPart then
                local distance = (HumanoidRootPart.Position - mobRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestMob = mob
                end
            end
        end
    end

    return nearestMob
end

local function autoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end

    autoClickConnection = RunService.Heartbeat:Connect(function()
        if (farmingEnabled or questFarmEnabled) and Character and Character.Parent then
            local tool = Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end

            pcall(function()
                for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") and (v.Name:lower():find("attack") or v.Name:lower():find("combat") or v.Name:lower():find("punch") or v.Name:lower():find("hit")) then
                        v:FireServer()
                    end
                end
            end)
        end
    end)
end

-- keep a cleanup in case any legacy body movers exist
local bodyVelocity = nil
local bodyGyro = nil

local function cleanupBodyMovers()
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
    end
    bodyVelocity = nil

    if bodyGyro and bodyGyro.Parent then
        bodyGyro:Destroy()
    end
    bodyGyro = nil
end

-- NEW: Calculate a safe position around the mob and move there smoothly.
-- This avoids teleporting directly *into* the mob.
local function getSafeTargetPositionForMob(mob, positionMode)
    if not mob then return nil end
    local mobRoot = getValidPart(mob)
    if not mobRoot then return nil end

    -- Choose desired offset based on mode (Above / Below / Behind)
    local desiredOffsetCFrame
    if positionMode == "Above" then
        desiredOffsetCFrame = CFrame.new(0, 8, 0)
    elseif positionMode == "Below" then
        desiredOffsetCFrame = CFrame.new(0, -5, 0)
    else -- Behind (default)
        -- put behind the mob relative to its look vector but slightly above to avoid floor clipping
        desiredOffsetCFrame = CFrame.new(0, 3, -5)
    end

    local desiredCFrame = mobRoot.CFrame * desiredOffsetCFrame
    local desiredPos = desiredCFrame.Position

    -- Determine a minimum safe distance to avoid overlap:
    -- Use model extents if available, otherwise fallback to mobRoot.Size.
    local minRadius = 3
    local ok, extents = pcall(function() return mob:GetExtentsSize() end)
    if ok and extents then
        local extMag = extents.Magnitude
        minRadius = math.max(3, extMag / 2)
    else
        if mobRoot:IsA("BasePart") then
            minRadius = math.max(3, mobRoot.Size.Magnitude / 2)
        end
    end

    -- Make sure the resulting target pos is at least minRadius + buffer away from mob center
    local direction = desiredPos - mobRoot.Position
    if direction.Magnitude < 0.001 then
        -- if direction is zero, pick a fallback direction (behind)
        direction = (mobRoot.CFrame * CFrame.new(0, 0, -1)).Position - mobRoot.Position
        if direction.Magnitude < 0.001 then
            direction = Vector3.new(0, 0, -1)
        end
    end

    local safeDistance = math.max(minRadius + 1.5, direction.Magnitude)
    local safePos = mobRoot.Position + direction.Unit * safeDistance

    -- Slightly lift the safePos to avoid being stuck in the floor
    safePos = Vector3.new(safePos.X, safePos.Y + 0.5, safePos.Z)

    return safePos, mobRoot
end

-- NEW: Smooth move + face mob. Avoids violent teleporting into mob.
local function stickToMob(mob)
    if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
        return
    end

    if isBlacklisted(mob) or mob == Character then
        return
    end

    local safePos, mobRoot = getSafeTargetPositionForMob(mob, farmPosition)
    if not safePos or not mobRoot then return end

    -- Prepare humanoid
    local humanoid = Character:FindFirstChild("Humanoid")
    if humanoid then
        -- keep animations but disable default walking so script controls movement
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    end

    -- Use MoveTo to request pathing then gently lerp the CFrame to the target
    if humanoid then
        pcall(function()
            humanoid:MoveTo(safePos)
        end)
    end

    -- Smoothly approach target position
    local maxIterations = 45 -- safety: don't loop forever (about ~1.5 seconds at Heartbeat)
    local iter = 0
    while farmingEnabled and iter < maxIterations do
        if not mob or not mob.Parent then break end -- mob disappeared
        if not Character or not Character.Parent then break end -- player died/despawned

        local currentPos = HumanoidRootPart.Position
        local distance = (currentPos - safePos).Magnitude

        -- if close enough, final snap facing the mob
        if distance <= 2.2 then
            -- face the mob directly
            if mobRoot and mobRoot.Parent then
                local lookAt = mobRoot.Position
                HumanoidRootPart.CFrame = CFrame.new(currentPos, lookAt) * CFrame.new(0, 0, 0)
                HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            end
            break
        end

        -- Lerping towards target to avoid heavy collisions/teleports
        local targetCFrame = CFrame.new(safePos, mobRoot.Position)
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(targetCFrame, 0.28)

        -- zero out momentum to reduce physics jitter
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)

        iter = iter + 1
        RunService.Heartbeat:Wait()
    end

    -- final facing adjustment if mob still exists
    if mobRoot and mobRoot.Parent then
        local finalPos = HumanoidRootPart.Position
        HumanoidRootPart.CFrame = CFrame.new(finalPos, mobRoot.Position)
        HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    end
end

local function startAutoFarm()
    if farmConnection then
        farmConnection:Disconnect()
    end

    farmConnection = RunService.Heartbeat:Connect(function()
        if farmingEnabled and Character and Character.Parent and HumanoidRootPart and HumanoidRootPart.Parent then
            local mob = nil

            if selectedMob then
                mob = findNearestMob(selectedMob)
            else
                mob = findNearestMob(nil)
            end

            if mob then
                -- Important: call cleanup to remove any legacy body movers before using the new mover
                cleanupBodyMovers()
                stickToMob(mob)
            end
        end
    end)
end

local function pressEKey()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function startQuestFarm()
    if questFarmConnection then
        questFarmConnection:Disconnect()
    end

    spawn(function()
        while questFarmEnabled do
            if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
                task.wait(1)
                continue
            end

            if not selectedQuestNPC then 
                task.wait(1)
                continue
            end

            print("[QUEST] Starting quest cycle...")

            local questsFolder = workspace.Main.NPCs:FindFirstChild("Quests")
            if questsFolder then
                local questNPC = questsFolder:FindFirstChild(selectedQuestNPC)
                if questNPC then
                    local npcRoot = questNPC:FindFirstChild("HumanoidRootPart") or questNPC:FindFirstChild("Torso")
                    if npcRoot then
                        print("[QUEST] Teleporting to NPC:", selectedQuestNPC)
                        teleportTo(npcRoot.CFrame * CFrame.new(0, 0, 5))
                        task.wait(1)
                    end
                end
            end

            local questFrame = LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest")
            if not questFrame then
                print("[QUEST] Pressing E to accept quest...")
                local attempts = 0
                while not LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest") and attempts < 20 and questFarmEnabled do
                    pressEKey()
                    task.wait(0.3)
                    attempts = attempts + 1
                end
                task.wait(1)
            end

            questFrame = LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest")
            if questFrame then
                print("[QUEST] Quest accepted! Farming all nearby mobs...")

                while questFarmEnabled do
                    if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
                        print("[QUEST] Character died, breaking to restart cycle...")
                        break
                    end

                    questFrame = LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest")
                    if not questFrame then
                        print("[QUEST] Quest completed! Restarting cycle...")
                        break
                    end

                    local mob = findNearestMob(nil)
                    if mob then
                        cleanupBodyMovers()
                        stickToMob(mob)
                    else
                        task.wait(0.5)
                    end

                    task.wait(0.1)
                end
            else
                print("[QUEST] ERROR: Quest frame not found after pressing E")
                task.wait(2)
            end

            task.wait(1)
        end
    end)
end

local function allocateStats()
    if autoStatsConnection then
        autoStatsConnection:Disconnect()
    end

    autoStatsConnection = RunService.Heartbeat:Connect(function()
        if autoStatsEnabled then
            for stat, enabled in pairs(selectedStats) do
                if enabled then
                    pcall(function()
                        local args = {
                            [1] = stat,
                            [2] = 50
                        }
                        LocalPlayer.PlayerGui.Button.Stats_Frame:FindFirstChild("{}").Event:FireServer(unpack(args))
                    end)
                end
            end
            task.wait(0.5)
        end
    end)
end

spawn(function()
    while true do
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.HoldDuration = 0
            end
        end
        task.wait(5)
    end
end)

-- UI/Tab code unchanged (kept intact from your original script) ...
local tabGroups = {
    TabGroup1 = Window:TabGroup()
}

local tabs = {
    Farm = tabGroups.TabGroup1:Tab({ Name = "Farm", Image = "rbxassetid://18821914323" }),
    Teleport = tabGroups.TabGroup1:Tab({ Name = "Teleport", Image = "rbxassetid://10734950309" }),
    AutoStats = tabGroups.TabGroup1:Tab({ Name = "Auto Stats", Image = "rbxassetid://10747372992" }),
    Settings = tabGroups.TabGroup1:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

local sections = {
    MobFarmSection = tabs.Farm:Section({ Side = "Left" }),
    ModePosition = tabs.Farm:Section({ Side = "Left" }),
    QuestFarmSection = tabs.Farm:Section({ Side = "Right" }),
    TeleportSection = tabs.Teleport:Section({ Side = "Left" }),
    AutoStatsSection = tabs.AutoStats:Section({ Side = "Left" })
}

sections.MobFarmSection:Header({ Name = "Mob Farming" })

local mobDropdown = sections.MobFarmSection:Dropdown({
    Name = "Select Mob",
    Multi = false,
    Required = false,
    Options = getAllMobs(),
    Callback = function(Value)
        selectedMob = Value
        Window:Notify({
            Title = "Mob Selected",
            Description = "Selected: " .. Value,
            Lifetime = 3
        })
    end,
}, "MobDropdown")

sections.MobFarmSection:Button({
    Name = "Refresh Mobs",
    Callback = function()
        setupBlacklist()
        local mobs = getAllMobs()

        Window:Notify({
            Title = "Refreshed",
            Description = "Found " .. #mobs .. " mobs!",
            Lifetime = 3
        })
    end,
})

sections.MobFarmSection:Toggle({
    Name = "Enable Auto Farm",
    Default = false,
    Callback = function(value)
        farmingEnabled = value
        if value then
            autoClick()
            startAutoFarm()
            Window:Notify({
                Title = "Auto Farm",
                Description = "Started farming " .. (selectedMob or "all mobs"),
                Lifetime = 3
            })
        else
            if autoClickConnection then 
                autoClickConnection:Disconnect() 
                autoClickConnection = nil
            end
            if farmConnection then 
                farmConnection:Disconnect() 
                farmConnection = nil
            end

            -- Clean up any leftover movers
            cleanupBodyMovers()

            -- Reset character state
            if Character and Character.Parent then
                local humanoid = Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 16
                    humanoid.JumpPower = 50
                    humanoid.AutoRotate = true
                end

                if HumanoidRootPart and HumanoidRootPart.Parent then
                    HumanoidRootPart.Anchored = false
                    HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
                end
            end

            Window:Notify({
                Title = "Auto Farm",
                Description = "Stopped farming",
                Lifetime = 3
            })
        end
    end,
}, "FarmToggle")

sections.ModePosition:Header({ Name = "Set Mode" })

sections.ModePosition:Dropdown({
    Name = "Auto Farm Position",
    Multi = false,
    Required = false,
    Options = {"Above", "Below", "Behind"},
    Default = "Behind",
    Callback = function(Value)
        farmPosition = Value
        Window:Notify({
            Title = "Position Changed",
            Description = "Farm position set to: " .. Value,
            Lifetime = 3
        })
    end,
}, "FarmPositionDropdown")

sections.QuestFarmSection:Header({ Name = "Quest Farming" })

sections.QuestFarmSection:Dropdown({
    Name = "Select Quest NPC",
    Multi = false,
    Required = false,
    Options = getAllQuestNPCs(),
    Callback = function(Value)
        selectedQuestNPC = Value
        Window:Notify({
            Title = "Quest NPC Selected",
            Description = "Selected: " .. Value,
            Lifetime = 3
        })
    end,
}, "QuestNPCDropdown")

sections.QuestFarmSection:Toggle({
    Name = "Enable Quest Farm",
    Default = false,
    Callback = function(value)
        questFarmEnabled = value
        if value then
            autoClick()
            startQuestFarm()
            Window:Notify({
                Title = "Quest Farm",
                Description = "Started quest farming with " .. (selectedQuestNPC or "no NPC"),
                Lifetime = 3
            })
        else
            if autoClickConnection then 
                autoClickConnection:Disconnect() 
                autoClickConnection = nil
            end
            if questFarmConnection then 
                questFarmConnection:Disconnect() 
                questFarmConnection = nil
            end

            -- Clean up any leftover movers
            cleanupBodyMovers()

            -- Reset character state
            if Character and Character.Parent then
                local humanoid = Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 16
                    humanoid.JumpPower = 50
                    humanoid.AutoRotate = true
                end

                if HumanoidRootPart and HumanoidRootPart.Parent then
                    HumanoidRootPart.Anchored = false
                    HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
                end
            end

            Window:Notify({
                Title = "Quest Farm",
                Description = "Stopped quest farming",
                Lifetime = 3
            })
        end
    end,
}, "QuestFarmToggle")

sections.TeleportSection:Header({ Name = "Teleportation" })

sections.TeleportSection:Dropdown({
    Name = "Teleport to Map",
    Multi = false,
    Required = false,
    Options = getAllMaps(),
    Callback = function(Value)
        local mapsFolder = workspace:FindFirstChild("Maps")
        if mapsFolder then
            local map = mapsFolder:FindFirstChild(Value)
            if map then
                local mapSpawn = map:FindFirstChildWhichIsA("SpawnLocation") or map:FindFirstChildWhichIsA("Part")
                if mapSpawn then
                    teleportTo(mapSpawn.CFrame * CFrame.new(0, 5, 0))
                    Window:Notify({
                        Title = "Teleported",
                        Description = "Teleported to " .. Value,
                        Lifetime = 3
                    })
                end
            end
        end
    end,
}, "MapTeleport")

sections.TeleportSection:Dropdown({
    Name = "Combat Seller",
    Multi = false,
    Required = false,
    Options = getCombatSellers(),
    Callback = function(Value)
        local combatFolder = workspace.Main.NPCs:FindFirstChild("Combat")
        if combatFolder then
            local npc = combatFolder:FindFirstChild(Value)
            if npc then
                local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
                if npcRoot then
                    teleportTo(npcRoot.CFrame * CFrame.new(0, 0, 5))
                    Window:Notify({
                        Title = "Teleported",
                        Description = "Teleported to " .. Value,
                        Lifetime = 3
                    })
                end
            end
        end
    end,
}, "CombatSellerDropdown")

sections.TeleportSection:Dropdown({
    Name = "Sword Seller",
    Multi = false,
    Required = false,
    Options = getSwordSellers(),
    Callback = function(Value)
        local swordFolder = workspace.Main.NPCs:FindFirstChild("Sword")
        if swordFolder then
            for _, v in pairs(swordFolder:GetChildren()) do
            if v:IsA("Model") then
                table.insert(sellers, v.Name)
            end
        end
    end
    return sellers
end

local function teleportTo(cframe)
    if Character and HumanoidRootPart then
        -- Use a safe teleport (unground then set)
        HumanoidRootPart.CFrame = cframe
        HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        HumanoidRootPart.RotVelocity = Vector3.new(0,0,0)
    end
end

local function findNearestMob(mobName)
    local charactersFolder = workspace.Main:FindFirstChild("Characters")
    if not charactersFolder then return nil end

    local allMobs = getAllMobsDeep(charactersFolder)
    local nearestMob = nil
    local shortestDistance = math.huge

    for _, mob in pairs(allMobs) do
        if not mobName or mob.Name:lower():find(mobName:lower()) then
            local mobRoot = getValidPart(mob)

            if mobRoot and HumanoidRootPart then
                local distance = (HumanoidRootPart.Position - mobRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestMob = mob
                end
            end
        end
    end

    return nearestMob
end

local function autoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end

    autoClickConnection = RunService.Heartbeat:Connect(function()
        if (farmingEnabled or questFarmEnabled) and Character and Character.Parent then
            local tool = Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end

            pcall(function()
                for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                    if v:IsA("RemoteEvent") and (v.Name:lower():find("attack") or v.Name:lower():find("combat") or v.Name:lower():find("punch") or v.Name:lower():find("hit")) then
                        v:FireServer()
                    end
                end
            end)
        end
    end)
end

-- keep a cleanup in case any legacy body movers exist
local bodyVelocity = nil
local bodyGyro = nil

local function cleanupBodyMovers()
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
    end
    bodyVelocity = nil

    if bodyGyro and bodyGyro.Parent then
        bodyGyro:Destroy()
    end
    bodyGyro = nil
end

-- NEW: Calculate a safe position around the mob and move there smoothly.
-- This avoids teleporting directly *into* the mob.
local function getSafeTargetPositionForMob(mob, positionMode)
    if not mob then return nil end
    local mobRoot = getValidPart(mob)
    if not mobRoot then return nil end

    -- Choose desired offset based on mode (Above / Below / Behind)
    local desiredOffsetCFrame
    if positionMode == "Above" then
        desiredOffsetCFrame = CFrame.new(0, 8, 0)
    elseif positionMode == "Below" then
        desiredOffsetCFrame = CFrame.new(0, -5, 0)
    else -- Behind (default)
        -- put behind the mob relative to its look vector but slightly above to avoid floor clipping
        desiredOffsetCFrame = CFrame.new(0, 3, -5)
    end

    local desiredCFrame = mobRoot.CFrame * desiredOffsetCFrame
    local desiredPos = desiredCFrame.Position

    -- Determine a minimum safe distance to avoid overlap:
    -- Use model extents if available, otherwise fallback to mobRoot.Size.
    local minRadius = 3
    local ok, extents = pcall(function() return mob:GetExtentsSize() end)
    if ok and extents then
        local extMag = extents.Magnitude
        minRadius = math.max(3, extMag / 2)
    else
        if mobRoot:IsA("BasePart") then
            minRadius = math.max(3, mobRoot.Size.Magnitude / 2)
        end
    end

    -- Make sure the resulting target pos is at least minRadius + buffer away from mob center
    local direction = desiredPos - mobRoot.Position
    if direction.Magnitude < 0.001 then
        -- if direction is zero, pick a fallback direction (behind)
        direction = (mobRoot.CFrame * CFrame.new(0, 0, -1)).Position - mobRoot.Position
        if direction.Magnitude < 0.001 then
            direction = Vector3.new(0, 0, -1)
        end
    end

    local safeDistance = math.max(minRadius + 1.5, direction.Magnitude)
    local safePos = mobRoot.Position + direction.Unit * safeDistance

    -- Slightly lift the safePos to avoid being stuck in the floor
    safePos = Vector3.new(safePos.X, safePos.Y + 0.5, safePos.Z)

    return safePos, mobRoot
end

-- NEW: Smooth move + face mob. Avoids violent teleporting into mob.
local function stickToMob(mob)
    if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
        return
    end

    if isBlacklisted(mob) or mob == Character then
        return
    end

    local safePos, mobRoot = getSafeTargetPositionForMob(mob, farmPosition)
    if not safePos or not mobRoot then return end

    -- Prepare humanoid
    local humanoid = Character:FindFirstChild("Humanoid")
    if humanoid then
        -- keep animations but disable default walking so script controls movement
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
    end

    -- Use MoveTo to request pathing then gently lerp the CFrame to the target
    if humanoid then
        pcall(function()
            humanoid:MoveTo(safePos)
        end)
    end

    -- Smoothly approach target position
    local maxIterations = 45 -- safety: don't loop forever (about ~1.5 seconds at Heartbeat)
    local iter = 0
    while farmingEnabled and iter < maxIterations do
        if not mob or not mob.Parent then break end -- mob disappeared
        if not Character or not Character.Parent then break end -- player died/despawned

        local currentPos = HumanoidRootPart.Position
        local distance = (currentPos - safePos).Magnitude

        -- if close enough, final snap facing the mob
        if distance <= 2.2 then
            -- face the mob directly
            if mobRoot and mobRoot.Parent then
                local lookAt = mobRoot.Position
                HumanoidRootPart.CFrame = CFrame.new(currentPos, lookAt) * CFrame.new(0, 0, 0)
                HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            end
            break
        end

        -- Lerping towards target to avoid heavy collisions/teleports
        local targetCFrame = CFrame.new(safePos, mobRoot.Position)
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(targetCFrame, 0.28)

        -- zero out momentum to reduce physics jitter
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)

        iter = iter + 1
        RunService.Heartbeat:Wait()
    end

    -- final facing adjustment if mob still exists
    if mobRoot and mobRoot.Parent then
        local finalPos = HumanoidRootPart.Position
        HumanoidRootPart.CFrame = CFrame.new(finalPos, mobRoot.Position)
        HumanoidRootPart.Velocity = Vector3.new(0,0,0)
    end
end

local function startAutoFarm()
    if farmConnection then
        farmConnection:Disconnect()
    end

    farmConnection = RunService.Heartbeat:Connect(function()
        if farmingEnabled and Character and Character.Parent and HumanoidRootPart and HumanoidRootPart.Parent then
            local mob = nil

            if selectedMob then
                mob = findNearestMob(selectedMob)
            else
                mob = findNearestMob(nil)
            end

            if mob then
                -- Important: call cleanup to remove any legacy body movers before using the new mover
                cleanupBodyMovers()
                stickToMob(mob)
            end
        end
    end)
end

local function pressEKey()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function startQuestFarm()
    if questFarmConnection then
        questFarmConnection:Disconnect()
    end

    spawn(function()
        while questFarmEnabled do
            if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
                task.wait(1)
                continue
            end

            if not selectedQuestNPC then 
                task.wait(1)
                continue
            end

            print("[QUEST] Starting quest cycle...")

            local questsFolder = workspace.Main.NPCs:FindFirstChild("Quests")
            if questsFolder then
                local questNPC = questsFolder:FindFirstChild(selectedQuestNPC)
                if questNPC then
                    local npcRoot = questNPC:FindFirstChild("HumanoidRootPart") or questNPC:FindFirstChild("Torso")
                    if npcRoot then
                        print("[QUEST] Teleporting to NPC:", selectedQuestNPC)
                        teleportTo(npcRoot.CFrame * CFrame.new(0, 0, 5))
                        task.wait(1)
                    end
                end
            end

            local questFrame = LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest")
            if not questFrame then
                print("[QUEST] Pressing E to accept quest...")
                local attempts = 0
                while not LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest") and attempts < 20 and questFarmEnabled do
                    pressEKey()
                    task.wait(0.3)
                    attempts = attempts + 1
                end
                task.wait(1)
            end

            questFrame = LocalPlayer.PlayerGui.HUD.Bar.List:FindFirstChild("Quest")
            if questFrame then
                print("[QUEST] Quest accepted! Farming all nearby mobs...")

                while questFarmEnabled do
                    if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
                        print("[QUEST] Character died, breaking to restart cycle...")
                        break
                    end
