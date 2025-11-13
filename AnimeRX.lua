-- Global Section
if game.PlaceId ~= 72829404259339 then return end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Wanz HUB",
    SubTitle = "Private Versions",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 350),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})


local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local playerGui  = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "ElapsedTimerGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0) -- Center horizontally
frame.Position    = UDim2.new(0.5, 0, 0, 30)
frame.Size        = UDim2.new(0, 200, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size          = UDim2.new(1, -12, 0, 20)
title.Position      = UDim2.new(0, 6, 0, 4)
title.Text          = "Timer Since Script Executed:"
title.Font          = Enum.Font.GothamBold
title.TextSize      = 16
title.TextColor3    = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = frame

local body = Instance.new("TextLabel")
body.Size           = UDim2.new(1, -12, 0, 20)
body.Position       = UDim2.new(0, 6, 0, 26)
body.Text           = "0:00"
body.Font           = Enum.Font.Gotham
body.TextSize       = 14
body.TextColor3     = Color3.new(1, 1, 1)
body.BackgroundTransparency = 1
body.TextXAlignment = Enum.TextXAlignment.Center
body.Parent = frame

local startTick = tick()

RunService.RenderStepped:Connect(function()
    local elapsed = math.floor(tick() - startTick)
    local minutes = math.floor(elapsed / 60)
    local seconds = elapsed % 60

    if minutes > 59 then
        local hours = math.floor(minutes / 60)
        minutes = minutes % 60
        body.Text = string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        body.Text = string.format("%d:%02d", minutes, seconds)
    end
end)


local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

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

local isMinimized = false
local function toggleFluent()
    isMinimized = not isMinimized
    Window:Minimize(isMinimized)
end

logoButton.Activated:Connect(toggleFluent)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftControl then
        toggleFluent()
    end
end)

local Tabs = {
    Main = Window:AddTab({ Title = "Menu", Icon = "home" }),
    Other = Window:AddTab({ Title = "Exploit", Icon = "layers" }),
    Joiner = Window:AddTab({ Title = "Auto Join", Icon = "users" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "globe" }),
    Misc = Window:AddTab({ Title = "Other Settings", Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Configuration", Icon = "settings" })
}

local Options = Fluent.Options
local votingActive = { Next = false, Retry = false }
local buyActive = false


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local configFile = "webhook_settings.json"
local Options = _G.Options or {}
_G.Options = Options

local function loadSettings()
    if isfile and isfile(configFile) then
        local success, content = pcall(readfile, configFile)
        if success then
            local decoded = HttpService:JSONDecode(content)
            Options.WebhookURL_Value = decoded.WebhookURL or ""
            Options.ActiveWebhook_Value = decoded.ActiveWebhook or false
        end
    end
end

local function saveSettings()
    if writefile then
        local data = {
            WebhookURL = Options.WebhookURL.Value,
            ActiveWebhook = Options.ActiveWebhook.Value
        }
        writefile(configFile, HttpService:JSONEncode(data))
    end
end

loadSettings()


-- Main Section
Options.SetMaxSpeed = Tabs.Main:AddToggle("SetMaxSpeed", {
    Title = "Set Max GameSpeed",
    Description = "Automatically Set Your GameSpeed",
    Default = false,
    Callback = function(state)
        local args = {
            [1] = "Auto Set Max Speed",
            [2] = state -- true = enable, false = disable
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("Settings"):WaitForChild("Setting_Event"):FireServer(unpack(args))
    end
})

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Tabs.Main:AddParagraph({
    Title = "- Vote Menu -",
    Content = ""
})

Options.VoteNext = Tabs.Main:AddToggle("VoteNext", {
    Title = "Vote Next",
    Description = "Automatically Vote Next",
    Default = false
})

Options.VoteNext:OnChanged(function(v)
    votingActive.Next = v
    if v then
        Options.VoteRetry:SetValue(false)
        Fluent:Notify({
            Title = "Vote",
            Content = "Auto-voting for Next map",
            Duration = 3
        })
    else
        votingActive.Next = false
    end
end)

Options.VoteRetry = Tabs.Main:AddToggle("VoteRetry", {
    Title = "Vote Retry",
    Description = "Automatically Vote Retry",
    Default = false
})

Options.VoteRetry:OnChanged(function(v)
    votingActive.Retry = v
    if v then
        Options.VoteNext:SetValue(false)
        Fluent:Notify({
            Title = "Vote",
            Content = "Auto-voting for Retry map",
            Duration = 3
        })
    else
        votingActive.Retry = false
    end
end)

task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer

    while task.wait(1) do
        if (votingActive.Next or votingActive.Retry) and not workspace:FindFirstChild("Lobby") then
            local pg = LocalPlayer:FindFirstChild("PlayerGui")

            if pg and pg:FindFirstChild("GameEndedAnimationUI") then
                task.wait(1)
                if not pg:FindFirstChild("GameEndedAnimationUI") then
                    continue
                end

                if votingActive.Next then
                    Fluent:Notify({
                        Title = "Vote",
                        Content = "Auto-voting Next...",
                        Duration = 3
                    })
                elseif votingActive.Retry then
                    Fluent:Notify({
                        Title = "Vote",
                        Content = "Auto-voting Retry...",
                        Duration = 3
                    })
                end

                repeat
                    if votingActive.Next then
                        RS.Remote.Server.OnGame.Voting.VoteNext:FireServer()
                    elseif votingActive.Retry then
                        RS.Remote.Server.OnGame.Voting.VoteRetry:FireServer()
                    end
                    task.wait(2)
                until not (pg:FindFirstChild("GameEndedAnimationUI") and (votingActive.Next or votingActive.Retry))
            end
        end
    end
end)


Options.AutoStart = Tabs.Main:AddToggle("AutoStart", {
    Title = "Auto Start",
    Description = "Automatically Start The Game",
    Default = false
})

Options.AutoStart:OnChanged(function(state)
    if not state then
        Fluent:Notify({
            Title = "Auto Start",
            Content = "Disabled (no settings reverted)",
            Duration = 3
        })
        return
    end

    local RS = game:GetService("ReplicatedStorage")
    local SettingFolder = RS:FindFirstChild("Player_Settings") or RS:WaitForChild("Player_Settings")
    local PlayerSettings = SettingFolder and SettingFolder:FindFirstChild(game.Players.LocalPlayer.Name)

    local settingName = "Auto Vote Start"
    local desiredValue = true

    task.spawn(function()
        local currentSetting = nil
        if PlayerSettings then
            local settingObj = PlayerSettings:FindFirstChild(settingName)
            if settingObj and settingObj:IsA("BoolValue") then
                currentSetting = settingObj.Value
            end
        end

        if currentSetting ~= desiredValue then
            RS.Remote.Server.Settings.Setting_Event:FireServer(settingName, desiredValue)
            Fluent:Notify({
                Title = "Auto Start",
                Content = "Setting applied!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Auto Start",
                Content = "Already set, nothing changed",
                Duration = 3
            })
        end
    end)
end)

-- Other Section
Options.RapidRestart = Tabs.Other:AddToggle("RapidRestart", {
    Title = "Rapid Restart Method",
    Description = "Instant Win (Only Works On Kurumi Boss Event)",
    Default = false
})

Options.RapidRestart:OnChanged(function(enabled)
    if not enabled then return end

    local rs = game:GetService("ReplicatedStorage")
    local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    task.spawn(function()
        while Options.RapidRestart.Value and not Fluent.Unloaded do
            pcall(function()
                rs.Remote.Server.OnGame.RestartMatch:FireServer()
            end)

            if pg:FindFirstChild("GameEndedAnimationUI") then
                pcall(function()
                    rs.Remote.Server.OnGame.Voting.VoteRetry:FireServer()
                end)
            end

            task.wait(1.5)
        end
    end)
end)

Options.UnlockAutoTrait = Tabs.Other:AddToggle("UnlockAutoTrait", {
    Title = "Unlock Auto Trait Reroll Gamepass",
    Default = false,
    Callback = function(Value)
        local player = game:GetService("Players").LocalPlayer
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local playerData = replicatedStorage:FindFirstChild("Player_Data")
        
        if playerData then
            local myData = playerData:FindFirstChild(player.Name)
            if myData and myData:FindFirstChild("Gamepass") then
                local autoTrait = myData.Gamepass:FindFirstChild("Auto Trait Reroll")
                if autoTrait then
                    autoTrait.Value = Value
                end
            end
        end
    end
})

task.spawn(function()
    local SoundService = game:GetService("SoundService")
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://130735042055734"
    sound.Volume = 2
    sound.Looped = false
    sound.Parent = SoundService
    sound:Play()
end)

-- Joiner Section
Tabs.Joiner:AddParagraph({
    Title = "- Raid -",
    Content = ""
})

Options.GateRaidChapter = Tabs.Joiner:AddDropdown("GateRaidChapter", {
    Title = "Select Gate Raid Chapter",
    Values = {
        "TheGatedCity_Chapter1",
        "TheGatedCity_Chapter2",
        "TheGatedCity_Chapter3",
        "TheGatedCity_Chapter4"
    },
    Multi = false,
    Default = "TheGatedCity_Chapter1"
})

Options.AutoJoinGateRaid = Tabs.Joiner:AddToggle("AutoJoinGateRaid", {
    Title = "Auto Join Gate Raid",
    Default = false,
    Callback = function(enabled)
        if not enabled then return end

        task.spawn(function()
            while Options.AutoJoinGateRaid.Value and not Fluent.Unloaded do
                if workspace:FindFirstChild("Lobby") then
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local Remote = ReplicatedStorage
                        :WaitForChild("Remote")
                        :WaitForChild("Server")
                        :WaitForChild("PlayRoom")
                        :WaitForChild("Event")

                    Remote:FireServer("Create")
                    Remote:FireServer("Change-Mode", {["Mode"] = "Raids Stage"})
                    Remote:FireServer("Change-World", {["World"] = "TheGatedCity"})
                    local chapter = Options.GateRaidChapter.Value or "TheGatedCity_Chapter1"
                    Remote:FireServer("Change-Chapter", {["Chapter"] = chapter})
                    Remote:FireServer("Submit")
                    Remote:FireServer("Start")

                    Fluent:Notify({
                        Title = "Auto Join Gate Raid",
                        Content = "Joined " .. chapter,
                        Duration = 4
                    })

                    break -- stop after success
                else
                    warn("[AutoJoinGateRaid] Lobby not found, retrying...")
                end
                task.wait(2) -- retry every 2s until lobby exists
            end
        end)
    end
})

Tabs.Joiner:AddParagraph({
    Title = "- Dungeon -",
    Content = ""
})

-- Store the current chosen difficulty
local currentDifficulty = "Normal"

Options.DungeonDifficulty = Tabs.Joiner:AddDropdown("DungeonDifficulty", {
    Title = "Dungeon Difficulty",
    Values = {"Easy", "Normal", "Hell"},
    Default = "Normal"
})

-- Update variable when changed
Options.DungeonDifficulty:OnChanged(function(value)
    currentDifficulty = value
end)

Options.AutoJoinDungeon = Tabs.Joiner:AddToggle("AutoJoinDungeon", {
    Title = "Auto Join Dungeon",
    Default = false
})

Options.AutoJoinDungeon:OnChanged(function(enabled)
    if not enabled then return end

    task.spawn(function()
        while Options.AutoJoinDungeon.Value and not Fluent.Unloaded do
            if workspace:FindFirstChild("Lobby") then
                task.wait(3) -- ⏳ delay before sending remote

                local args = {
                    [1] = "Dungeon",
                    [2] = { ["Difficulty"] = currentDifficulty }
                }

                game:GetService("ReplicatedStorage")
                    :WaitForChild("Remote")
                    :WaitForChild("Server")
                    :WaitForChild("PlayRoom")
                    :WaitForChild("Event")
                    :FireServer(unpack(args))

                Fluent:Notify({
                    Title = "Auto Join Dungeon",
                    Content = "Requested Dungeon (" .. currentDifficulty .. ")",
                    Duration = 4
                })

                break -- run once
            end
            task.wait(2)
        end
    end)
end)

Tabs.Joiner:AddParagraph({
    Title = "- Adventure -",
    Content = ""
})

Options.NextGame = Tabs.Joiner:AddDropdown("NextGame", {
    Title = "Select Next Game:",
    Values = {"Endure", "Evade"},
    Multi = false,
    Default = "Endure",
})

Options.AutoJoinAdventure = Tabs.Joiner:AddToggle("AutoJoinAdventure", {
    Title = "Auto Join Adventure",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                while Options.AutoJoinAdventure.Value do
                    task.wait(1)

                    if workspace:FindFirstChild("Lobby") then
                        local args1 = {"AdventureMode"}
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Remote"):WaitForChild("Server")
                            :WaitForChild("PlayRoom"):WaitForChild("Event")
                            :FireServer(unpack(args1))

                        task.wait(1)

                        local args2 = {"Start"}
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Remote"):WaitForChild("Server")
                            :WaitForChild("PlayRoom"):WaitForChild("Event")
                            :FireServer(unpack(args2))

                        local args3 = {"AdventureMode"}
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Remote"):WaitForChild("Server")
                            :WaitForChild("PlayRoom"):WaitForChild("Event")
                            :FireServer(unpack(args3))

                    else
                        local player = game:GetService("Players").LocalPlayer
                        local VIM = game:GetService("VirtualInputManager")
                        local GuiService = game:GetService("GuiService")

                        local function pressKey(keycode)
                            VIM:SendKeyEvent(true, keycode, false, game)
                            task.wait(0.1)
                            VIM:SendKeyEvent(false, keycode, false, game)
                        end

                        local prompt = player.PlayerGui:FindFirstChild("AdventureContinuePrompt")
                        if prompt and prompt:FindFirstChild("Main") then
                            local btn = prompt.Main.LeftSide.Button:FindFirstChild(Options.NextGame.Value)
                            if btn then
                                GuiService.SelectedObject = btn
                                pressKey(Enum.KeyCode.Return)
                            end
                        end
                    end
                end
            end)
        end
    end
})

Tabs.Joiner:AddParagraph({
    Title = "- Event -",
    Content = ""
})

Options.AutoJoinKurumiBoss = Tabs.Joiner:AddToggle("AutoJoinKurumiBoss", {
    Title = "Auto Join Kurumi Boss Event",
    Description = "Limited Time Event",
    Default = false
})

Options.AutoJoinKurumiBoss:OnChanged(function(enabled)
    if not enabled then return end

    task.spawn(function()
        while Options.AutoJoinKurumiBoss.Value and not Fluent.Unloaded do
            if workspace:FindFirstChild("Lobby") then
                local args = {
                    [1] = "Boss-Event",
                    [2] = {
                        ["Difficulty"] = "Nightmare"
                    }
                }

                game:GetService("ReplicatedStorage")
                    :WaitForChild("Remote")
                    :WaitForChild("Server")
                    :WaitForChild("PlayRoom")
                    :WaitForChild("Event")
                    :FireServer(unpack(args))

                Fluent:Notify({
                    Title = "Auto Join Kurumi Boss",
                    Content = "Joined Kurumi Boss Event (Nightmare)",
                    Duration = 4
                })

                break -- run once per activation
            else
                -- Not in lobby, do nothing
                break
            end
            task.wait(2)
        end
    end)
end)

Tabs.Joiner:AddParagraph({
    Title = "- Others -",
    Content = ""
})

Options.AutoJoinBossRush = Tabs.Joiner:AddToggle("AutoJoinBossRush", {
    Title = "Auto Join Boss Rush",
    Default = false
})

Options.AutoJoinBossRush:OnChanged(function(enabled)
    if not enabled then return end

    task.spawn(function()
        while Options.AutoJoinBossRush.Value and not Fluent.Unloaded do
            if workspace:FindFirstChild("Lobby") then
                local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
                local playRoomGui = playerGui:WaitForChild("PlayRoom")
                playRoomGui.Enabled = true

                local function manageBossRush()
                    local createArgs = {
                        [1] = "BossRush"
                    }
                    game:GetService("ReplicatedStorage").Remote.Server.PlayRoom.Event:FireServer(unpack(createArgs))

                    wait(2)

                    local startArgs = {
                        [1] = "Start"
                    }
                    game:GetService("ReplicatedStorage").Remote.Server.PlayRoom.Event:FireServer(unpack(startArgs))
                end

                manageBossRush()
                break
            else
                warn("Lobby not found - Boss Rush script not executed")
            end
            task.wait(2)
        end
    end)
end)

Options.AutoJoinChallenge = Tabs.Joiner:AddToggle("AutoJoinChallenge", {
    Title = "Auto Join Challenge",
    Default = false
})

Options.AutoJoinChallenge:OnChanged(function(enabled)
    if not enabled then return end

    task.spawn(function()
        while Options.AutoJoinChallenge.Value and not Fluent.Unloaded do
            if workspace:FindFirstChild("Lobby") then
                local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
                local playRoomGui = playerGui:FindFirstChild("PlayRoom")
                if playRoomGui then
                    playRoomGui.Enabled = true
                end

                local function manageRoom()
                    local createArgs = {
                        [1] = "Create",
                        [2] = {
                            ["CreateChallengeRoom"] = true
                        }
                    }
                    game:GetService("ReplicatedStorage").Remote.Server.PlayRoom.Event:FireServer(unpack(createArgs))

                    task.wait(2)

                    local startArgs = {
                        [1] = "Start"
                    }
                    game:GetService("ReplicatedStorage").Remote.Server.PlayRoom.Event:FireServer(unpack(startArgs))
                end

                manageRoom()
                break -- run only once per activation
            end
            task.wait(2)
        end
    end)
end)



-- Shop Section
Tabs.Shop:AddParagraph({
    Title = "- Merchant -",
    Content = ""
})

local buyLoop

local itemList = {
    ["Perfect Stats Key"] = "Perfect Stats Key",
    ["Stats Key"] = "Stats Key",
    ["Soul Fragments"] = "Soul Fragments",
    ["Trait Reroll"] = "Trait Reroll",
    ["Dr. Megga Punk"] = "Dr. Megga Punk",
    ["Cursed Finger"] = "Cursed Finger",
    ["Ranger Crystal"] = "Ranger Crystal"
}

local selectedItems = {}

local function getTableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

local multiBuyDropdown = Tabs.Shop:AddDropdown("AutoBuyItems", {
    Title = "Auto Buy [Merchant]",
    Description = "Select Wanted Items",
    Values = getTableKeys(itemList),
    Multi = true,
    Default = {},
})

multiBuyDropdown:OnChanged(function(Value)
    selectedItems = {}
    for itemName, state in pairs(Value) do
        if state then
            table.insert(selectedItems, itemName)
        end
    end
    Fluent:Notify({
        Title = "Auto Buy",
        Content = "Selected: " .. table.concat(selectedItems, ", "),
        Duration = 4
    })
end)


Options.AutoBuyToggle = Tabs.Shop:AddToggle("AutoBuyToggle", {
    Title = "Buy Items",
    Default = false
})

Options.AutoBuyToggle:OnChanged(function(enabled)
    buyActive = enabled
    if enabled then
        Fluent:Notify({
            Title = "Auto Buy",
            Content = "Started auto-buying...",
            Duration = 4
        })

        buyLoop = task.spawn(function()
            local RS = game:GetService("ReplicatedStorage")
            while buyActive and not Fluent.Unloaded do
                for _, itemName in pairs(selectedItems) do
                    local args = {
                        [1] = itemName,
                        [2] = 1
                    }
                    RS.Remote.Server.Gameplay.Merchant:FireServer(unpack(args))
                    task.wait(0.1) -- delay to avoid flooding
                end
                task.wait(0.1) -- overall loop delay
            end
        end)
    else
        if buyLoop then
            task.cancel(buyLoop)
            buyLoop = nil
        end
        Fluent:Notify({
            Title = "Auto Buy",
            Content = "Stopped auto-buying.",
            Duration = 3
        })
    end
end)

Tabs.Shop:AddParagraph({
    Title = "- Raid Shop -",
    Content = ""
})

local RaidShopItems = {
    "Trait Reroll",
    "Stats Key",
    "Dr. Megga Punk",
    "Perfect Stats Key",
    "Cursed Finger",
    "Gourmet Meal"
}

local RaidDropdown = Tabs.Shop:AddDropdown("RaidShopItems", {
    Title = "Auto Buy [Raid Shop]",
    Description = "Select Wanted Items",
    Values = RaidShopItems,
    Multi = true,
    Default = {},
})

local selectedRaidItems = {}

RaidDropdown:OnChanged(function(Value)
    selectedRaidItems = Value -- Store selected items
end)

Options.AutoBuyRaidShop = Tabs.Shop:AddToggle("AutoBuyRaidShop", {
    Title = "Buy Items",
    Default = false,
})

Options.AutoBuyRaidShop:OnChanged(function(enabled)
    if enabled then
        Fluent:Notify({
            Title = "Raid Shop Auto Buy",
            Content = "Auto-buy started for selected items.",
            Duration = 4
        })

        task.spawn(function()
            while Options.AutoBuyRaidShop.Value and not Fluent.Unloaded do
                for itemName, isSelected in pairs(selectedRaidItems) do
                    if isSelected then
                        local success, err = pcall(function()
                            local args = { [1] = itemName, [2] = 1 }
                            game:GetService("ReplicatedStorage").Remote.Server.Gameplay.Raid_Shop:FireServer(unpack(args))
                        end)
                        if not success then
                            warn("[AutoBuy RaidShop] Failed to buy:", itemName, err)
                        end
                        task.wait(0.1)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        Fluent:Notify({
            Title = "Raid Shop Auto Buy",
            Content = "Auto-buy stopped.",
            Duration = 3
        })
    end
end)

local GraveyardItems = {
    "Trait Reroll",
    "Stats Key",
    "Perfect Stats Key",
    "All-In Toast",
    "Cursed Finger"
}

local selectedGraveyardItems = {}

local GraveyardDropdown = Tabs.Shop:AddDropdown("GraveyardRaidShopItems", {
    Title = "Auto Buy [Graveyard Raid Shop]",
    Description = "Select Wanted Items",
    Values = GraveyardItems,
    Multi = true,
    Default = {},
})

GraveyardDropdown:OnChanged(function(Value)
    selectedGraveyardItems = Value -- Store selected items
    local chosen = {}
    for item, state in pairs(Value) do
        if state then
            table.insert(chosen, item)
        end
    end
    if #chosen > 0 then
        Fluent:Notify({
            Title = "Auto Buy [Graveyard Raid Shop]",
            Content = "Selected: " .. table.concat(chosen, ", "),
            Duration = 4
        })
    end
end)

Options.AutoBuyGraveyard = Tabs.Shop:AddToggle("AutoBuyGraveyard", {
    Title = "Buy Items",
    Default = false,
})

Options.AutoBuyGraveyard:OnChanged(function(enabled)
    if enabled then
        Fluent:Notify({
            Title = "Graveyard Raid Shop",
            Content = "Auto-buy started for selected items.",
            Duration = 4
        })

        task.spawn(function()
            while Options.AutoBuyGraveyard.Value and not Fluent.Unloaded do
                for itemName, isSelected in pairs(selectedGraveyardItems) do
                    if isSelected then
                        local success, err = pcall(function()
                            local args = { [1] = itemName, [2] = 1 }
                            game:GetService("ReplicatedStorage")
                                :WaitForChild("Remote")
                                :WaitForChild("Server")
                                :WaitForChild("Gameplay")
                                :WaitForChild("RaidCSW_Shop")
                                :FireServer(unpack(args))
                        end)
                        if not success then
                            warn("[AutoBuy Graveyard] Failed to buy:", itemName, err)
                        end
                        task.wait(0.2)
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        Fluent:Notify({
            Title = "Graveyard Raid Shop",
            Content = "Auto-buy stopped.",
            Duration = 3
        })
    end
end)



-- Webhook Section
Options.WebhookURL = Tabs.Webhook:AddInput("WebhookInput", {
    Title = "Paste Your Webhook",
    Description = "Sending Webhooks Into Your Discord",
    Default = Options.WebhookURL_Value or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Finished = true,
    Callback = function(Value)
        Options.WebhookURL_Value = Value
        saveSettings()
    end
})

Options.ActiveWebhook = Tabs.Webhook:AddToggle("ActiveWebhookToggle", {
    Title = "Active Webhook",
    Default = Options.ActiveWebhook_Value or false,
    Callback = function(v)
        Options.ActiveWebhook_Value = v
        saveSettings()
    end
})

local function getPlayerItemAmount(name)
    local playerFolder = ReplicatedStorage:FindFirstChild("Player_Data"):FindFirstChild(LocalPlayer.Name)
    if not playerFolder then return 0 end

    local itemsFolder = playerFolder:FindFirstChild("Items")
    if itemsFolder then
        local item = itemsFolder:FindFirstChild(name)
        if item and item:FindFirstChild("Amount") then
            return item.Amount.Value
        end
    end

    local dataFolder = playerFolder:FindFirstChild("Data")
    if dataFolder then
        local stat = dataFolder:FindFirstChild(name)
        if stat and stat:IsA("NumberValue") then
            return stat.Value
        end
    end

    return 0
end

local function sendWebhook(results)
    if not Options.ActiveWebhook.Value then return end
    local url = Options.WebhookURL.Value
    if url == "" then return end

    local placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    local data = {
        username = "WanzHook",
        embeds = {{
            title = "Results:",
            fields = {
                { name = "Place", value = placeName, inline = false },
                { name = "Username", value = "||" .. LocalPlayer.Name .. "||", inline = true },
                { name = "Rewards", value = results, inline = false },
                { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false }
            }
        }}
    }

    local success, err = pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not success then
        warn("Webhook failed:", err)
    end
end

local function showGameResults()
    task.spawn(function()
        local timeout = 5
        local rw
        repeat
            rw = LocalPlayer:FindFirstChild("RewardsShow")
            task.wait(0)
            timeout -= 0.25
        until rw or timeout <= 0

        if not rw then
            Fluent:Notify({ Title = "Game Ended", Content = "No rewards panel found", Duration = 3 })
            return
        end

        task.wait(0)

        local children = rw:GetChildren()
        if #children == 0 then
            Fluent:Notify({ Title = "Game Ended", Content = "No rewards detected", Duration = 3 })
            return
        end

        local lines = {}
        for _, item in ipairs(children) do
            local rewardName = item.Name
            local amount = item:IsA("NumberValue") and item.Value or ((item:FindFirstChild("Amount") and item.Amount.Value) or 1)
            local nowAmount = getPlayerItemAmount(rewardName)
            table.insert(lines, ("[ %dx ] %s  [Now: %dx]"):format(amount, rewardName, nowAmount))
        end

        local resultText = table.concat(lines, "\n")
        Fluent:Notify({ Title = "Results Notify", Content = resultText, Duration = 20 })
        sendWebhook(resultText)
    end)
end

task.spawn(function()
    while task.wait(0) do
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild("GameEndedAnimationUI") then
            showGameResults()
            repeat task.wait(1) until not pg:FindFirstChild("GameEndedAnimationUI")
        end
    end
end)

Options.PingOnUnitDrop = Tabs.Webhook:AddToggle("PingOnUnitDrop", {
    Title = "Ping On Unit Drop",
    Description = "Will Ping @everyone If You Got New Units",
    Default = false
})

local unitDropConnection

Options.PingOnUnitDrop:OnChanged(function(enabled)
    if enabled then
        local url = Options.WebhookURL.Value
        if url == "" then
            Fluent:Notify({
                Title = "Unit Drop Monitor",
                Content = "Please enter a webhook URL first!",
                Duration = 4
            })
            Options.PingOnUnitDrop:SetValue(false)
            return
        end
        
        local playerData = ReplicatedStorage:WaitForChild("Player_Data")
        local playerCollection = playerData:WaitForChild(LocalPlayer.Name):WaitForChild("Collection")
        
        -- Monitor for new units
        unitDropConnection = playerCollection.ChildAdded:Connect(function(newUnit)
            -- Send webhook notification
            local data = {
                content = "@everyone You got unit **" .. newUnit.Name .. "**"
            }
            
            pcall(function()
                request({
                    Url = url,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(data)
                })
            end)
            
            -- Also show in-game notification
            Fluent:Notify({
                Title = "New Unit!",
                Content = "You got: " .. newUnit.Name,
                Duration = 5
            })
        end)
        
        Fluent:Notify({
            Title = "Unit Drop Monitor",
            Content = "Now monitoring for new units!",
            Duration = 4
        })
    else
        if unitDropConnection then
            unitDropConnection:Disconnect()
            unitDropConnection = nil
        end
        
        Fluent:Notify({
            Title = "Unit Drop Monitor",
            Content = "Stopped monitoring units.",
            Duration = 3
        })
    end
end)

-- Misc Section
Options.AutoClaimQuest = Tabs.Misc:AddToggle("AutoClaimQuest", {
    Title   = "Auto Claim All Quest",
    Description = "Claiming All Your Quest",
    Default = false
})

Options.AutoClaimQuest:OnChanged(function(state)
    if not state then return end

    task.spawn(function()
        local RS = game:GetService("ReplicatedStorage")
        local questRemote = RS.Remote.Server.Gameplay.QuestEvent

        while Options.AutoClaimQuest.Value and not Fluent.Unloaded do
            questRemote:FireServer({ [1] = "ClaimAll" })
            task.wait(20)                                   -- loop delay
        end
    end)
end)

Options.AntiLag = Tabs.Misc:AddToggle("AntiLag", {
    Title = "Anti-Lag (Low Quality Mode)",
    Description = "Remove All Textures And Models",
    Default = false
})

local function cleanObject(obj)
    if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
        obj:Destroy()
    end
    if obj:IsA("MeshPart") then
        obj.TextureID = ""
    elseif obj:IsA("SpecialMesh") then
        obj.TextureId = ""
    end
    if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect") 
        or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect")
        or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
        obj:Destroy()
    end
    if obj:IsA("Sound") or obj:IsA("SoundEffect") then
        obj:Destroy()
    end
end

local function resetLighting()
    Lighting.Ambient = Color3.new(1,1,1)
    Lighting.OutdoorAmbient = Color3.new(1,1,1)
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 0
end

local function safeDestroy(obj)
    if obj and obj:IsA("Model") then
        pcall(function() obj:Destroy() end)
    end
end

local function removeOtherPlayers()
    if Workspace:FindFirstChild("Lobby") then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                player.Character:Destroy()
            end
        end
    end
end

Options.AntiLag:OnChanged(function(enabled)
    if enabled then
        if not Workspace:FindFirstChild("Lobby") then
            for _, obj in pairs(Workspace:GetDescendants()) do
                cleanObject(obj)
            end
            resetLighting()
            Workspace.DescendantAdded:Connect(cleanObject)

            local agentFolder = Workspace:FindFirstChild("Agent")
            if agentFolder and agentFolder:FindFirstChild("Agent") then
                agentFolder = agentFolder.Agent
                for _, obj in ipairs(agentFolder:GetDescendants()) do
                    safeDestroy(obj)
                end
                agentFolder.DescendantAdded:Connect(function(desc)
                    safeDestroy(desc)
                end)
            end
        else
            removeOtherPlayers()

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    player.CharacterAdded:Connect(function(char)
                        task.wait(0.1)
                        if Options.AntiLag.Value and Workspace:FindFirstChild("Lobby") then
                            char:Destroy()
                        end
                    end)
                end
            end

            Players.PlayerAdded:Connect(function(player)
                if player ~= LocalPlayer then
                    player.CharacterAdded:Connect(function(char)
                        task.wait(0.1)
                        if Options.AntiLag.Value and Workspace:FindFirstChild("Lobby") then
                            char:Destroy()
                        end
                    end)
                end
            end)
        end
    end
end)

Options.AutoRejoinDisconnect = Tabs.Misc:AddToggle("AutoRejoinDisconnect", {
    Title = "Auto Rejoin If Disconnected",
    Description = "Automatically Rejoin Even If You Disconnected",
    Default = false
})

Options.AutoRejoinDisconnect:OnChanged(function(enabled)
    if enabled then
        Fluent:Notify({
            Title = "Auto Rejoin",
            Content = "Will auto-rejoin if disconnected",
            Duration = 4
        })

        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local retryDelay = 3 -- Retry (s)

        Options._DisconnectConn = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(obj)
            if obj.Name == "ErrorPrompt" and Options.AutoRejoinDisconnect.Value then
                task.spawn(function()
                    while Options.AutoRejoinDisconnect.Value do
                        task.wait(retryDelay)
                        pcall(function()
                            TeleportService:Teleport(game.PlaceId, player)
                        end)
                    end
                end)
            end
        end)
    else
        if Options._DisconnectConn then
            Options._DisconnectConn:Disconnect()
            Options._DisconnectConn = nil
        end

        Fluent:Notify({
            Title = "Auto Rejoin",
            Content = "Disabled",
            Duration = 3
        })
    end
end)

Options.AutoRejoin2H = Tabs.Misc:AddToggle("AutoRejoin2H", {
    Title = "Auto Rejoin After 2 Hours",
    Description = "To Prevent Lag During A Long Playtime",
    Default = false,
    Callback = function(Value)
        if Value then
            task.spawn(function()
                local Players = game:GetService("Players")
                local TeleportService = game:GetService("TeleportService")
                local LocalPlayer = Players.LocalPlayer

                local startTick = tick()
                while Options.AutoRejoin2H.Value do
                    task.wait(5)
                    if tick() - startTick >= 7200 then -- 2 hours
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        break
                    end
                end
            end)
        end
    end,
})

Options.DisableYenNotify = Tabs.Misc:AddToggle("DisableYenNotify", {
    Title = "Disable Yen Notify",
    Description = "Removed Yen Notification",
    Default = false,
    Callback = function(state)
        local args = {
            [1] = "Disable Yen Notify",
            [2] = state -- true = disable, false = enable
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("Server"):WaitForChild("Settings"):WaitForChild("Setting_Event"):FireServer(unpack(args))
    end
})


Options.BlackoutScreen = Tabs.Misc:AddToggle("BlackoutScreen", {
    Title = "Full Black Background",
    Default = false
})

Options.BlackoutScreen:OnChanged(function(state)
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    if state then
        local gui = Instance.new("ScreenGui")
        gui.Name = "BlackoutGui"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.Parent = playerGui

        local frame = Instance.new("Frame")
        frame.Name = "BlackFrame"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Position = UDim2.new(0, 0, 0, 0)
        frame.BackgroundColor3 = Color3.new(0, 0, 0) -- black
        frame.BorderSizePixel = 0
        frame.ZIndex = 0 -- keep it behind GameEndedAnimationUI
        frame.Parent = gui

        Fluent:Notify({
            Title = "Blackout",
            Content = "Screen blacked out (Game End UI still visible).",
            Duration = 3
        })

    else
        local existing = playerGui:FindFirstChild("BlackoutGui")
        if existing then
            existing:Destroy()
        end

        Fluent:Notify({
            Title = "Blackout",
            Content = "Blackout disabled.",
            Duration = 3
        })
    end
end)

-- Settings Section
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("W-Hub")
SaveManager:SetFolder("W-Hub/Arx")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    local player = game:GetService("Players").LocalPlayer

    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

Window:SelectTab(1)
Fluent:Notify({ Title = "Fluent", Content = "The script has been loaded.", Duration = 8 })
SaveManager:LoadAutoloadConfig()
