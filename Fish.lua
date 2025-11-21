if game.PlaceId ~= 121864768012064 then return end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Load Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "Fish It [Wanz HUB]",
    SubTitle = "PRIVATE TESTING",
    TabWidth = 120,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Logo toggle
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

-- Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Fishing", Icon = "users" }),
    Event = Window:AddTab({ Title = "Fish Events", Icon = "map" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "globe" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "layers" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "bot" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    About = Window:AddTab({ Title = "About Script", Icon = "bug" })
}
local Options = Fluent.Options

-- Utility functions (must be defined before they are used)
local function getChildNames(parent)
    local names = {}
    if parent then
        for _, child in ipairs(parent:GetChildren()) do
            table.insert(names, child.Name)
        end
    end
    return names
end

local function getModelCFrame(model)
    if not model then return nil end
    if model:IsA("Model") then
        if model.PrimaryPart then return model.PrimaryPart.CFrame end
        if model:FindFirstChild("HumanoidRootPart") then return model.HumanoidRootPart.CFrame end
        local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
        if firstPart then return firstPart.CFrame end
    elseif model:IsA("BasePart") then
        return model.CFrame
    end
    return nil
end

local function canTeleport()
    return not (Options.AutoFishing.Value and Options.TeleportSaved.Value)
end

-- References
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local EquipToolFromHotbar = Net:WaitForChild("RE/EquipToolFromHotbar")
local ChargeFishingRod = Net:WaitForChild("RF/ChargeFishingRod")
local RequestFishingMinigameStarted = Net:WaitForChild("RF/RequestFishingMinigameStarted")
local FishingCompleted = Net:WaitForChild("RE/FishingCompleted")
local SellAllItems = Net:WaitForChild("RF/SellAllItems")

Tabs.Main:AddParagraph({
        Title = "Fishing Menu",
        Content = "Auto Fish/nAuto Sell/nAuto Weather"
    })

-- Auto Fishing (Replaced with fast detection system)
local rodEquipped = false
local isFishing = false

Options.AutoFishing = Tabs.Main:AddToggle("AutoFishing", {
    Title = "Auto Fishing",
    Default = false,
    Description = "Automatically catches fish using exclaim detection"
})

Options.AutoFishing:OnChanged(function()
    if not Options.AutoFishing.Value then
        rodEquipped = false
        isFishing = false
        return
    end
    
    task.spawn(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        
        local function equipRod()
            local args = { [1] = 1 }
            ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net:FindFirstChild("RE/EquipToolFromHotbar"):FireServer(unpack(args))
            task.wait(0.5)
        end
        
        local function chargeFishingRod()
            local args = { [4] = tick() }
            ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net:FindFirstChild("RF/ChargeFishingRod"):InvokeServer(unpack(args))
        end
        
        local function requestMinigame()
            local args = {
                [1] = -1.233184814453125,
                [2] = 0.9998747641116499,
                [3] = 1763683601.17936
            }
            ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net:FindFirstChild("RF/RequestFishingMinigameStarted"):InvokeServer(unpack(args))
        end
        
        local function completeFishing()
            ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net:FindFirstChild("RE/FishingCompleted"):FireServer()
            isFishing = false
        end
        
        workspace.DescendantAdded:Connect(function(descendant)
            if Options.AutoFishing.Value and descendant:IsA("BillboardGui") and descendant.Name == "Exclaim" then
                print("EXCLAIM BILLBOARD ADDED!")
                task.wait(2)
                completeFishing()
            end
        end)
        
        workspace.DescendantRemoving:Connect(function(descendant)
            if Options.AutoFishing.Value and descendant:IsA("BillboardGui") and descendant.Name == "Exclaim" then
                print("EXCLAIM BILLBOARD REMOVED!")
                task.wait(0.2)
                isFishing = false
            end
        end)
        
        local function startFishing()
            if isFishing or not Options.AutoFishing.Value then
                return
            end
            
            if humanoid.Health <= 0 then
                return
            end
            
            isFishing = true
            
            pcall(function()
                if not rodEquipped then
                    equipRod()
                    rodEquipped = true
                end
                task.wait(0.4)
                chargeFishingRod()
                task.wait(0.4)
                requestMinigame()
            end)
        end
        
        while Options.AutoFishing.Value do
            if not isFishing and humanoid.Health > 0 then
                startFishing()
            end
            task.wait(0.5)
        end
    end)
end)

-- Save / Teleport fishing location
local savedFishingPos, savedFishingLook
local saveFile = "FishingLocation.txt"
if isfile and isfile(saveFile) then
    local data = readfile(saveFile)
    local px, py, pz, lx, ly, lz = string.match(data, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
    if px and lx then
        savedFishingPos = Vector3.new(tonumber(px), tonumber(py), tonumber(pz))
        savedFishingLook = Vector3.new(tonumber(lx), tonumber(ly), tonumber(lz))
        Fluent:Notify({ Title = "Fishing Spot", Content = "Loaded saved fishing location", Duration = 4 })
    end
end
Tabs.Main:AddButton({
    Title = "Set Position",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Position",
            Content = "Do you want to save your current position?",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            savedFishingPos = hrp.Position
                            savedFishingLook = hrp.CFrame.LookVector
                            if writefile then
                                writefile(saveFile, string.format("%f,%f,%f,%f,%f,%f",
                                    savedFishingPos.X, savedFishingPos.Y, savedFishingPos.Z,
                                    savedFishingLook.X, savedFishingLook.Y, savedFishingLook.Z))
                            end
                            Fluent:Notify({
                                Title = "Successfully",
                                Content = "Saved your position",
                                Duration = 4
                            })
                        end
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        Fluent:Notify({
                            Title = "Cancelled",
                            Content = "Fishing position not saved",
                            Duration = 3
                        })
                    end
                }
            }
        })
    end
})

Options.TeleportSaved = Tabs.Main:AddToggle("TeleportSaved", {
    Title = "Teleport To Saved Position",
    Default = false,
    Callback = function(state)
        if state and savedFishingPos and savedFishingLook then
            local hrp = player.Character:WaitForChild("HumanoidRootPart")
            local targetPos = savedFishingPos + Vector3.new(0, 5, 0)
            local lookTarget = targetPos + savedFishingLook
            hrp.CFrame = CFrame.new(targetPos, lookTarget)
            Fluent:Notify({ Title = "Teleporting", Content = "Teleported to saved position", Duration = 4 })
        elseif state then
            Fluent:Notify({ Title = "Set Your Position First!", Content = "No saved position found", Duration = 4 })
            Options.TeleportSaved:SetValue(false)
        end
    end
})

-- Auto Sell
Options.SellAllFish = Tabs.Main:AddToggle("SellAllFish", { Title = "Sell All Fish", Default = false })
Options.SellAllFish:OnChanged(function()
    if Options.SellAllFish.Value then
        Fluent:Notify({ Title = "Auto Sell", Content = "Enabled", Duration = 5 })
        task.spawn(function()
            while Options.SellAllFish.Value do
                SellAllItems:InvokeServer()
                task.wait(3)
            end
        end)
    else
        Fluent:Notify({ Title = "Auto Sell", Content = "Disabled", Duration = 5 })
    end
end)

-- Auto Buy Weather Toggle
Options.AutoBuyWeather = Tabs.Main:AddToggle("AutoBuyWeather", {
    Title = "Auto Buy Weather",
    Default = false,
    Description = "Automatically buys Cloudy -> Storm -> Wind in sequence (1s each)."
})

Options.AutoBuyWeather:OnChanged(function()
    task.spawn(function()
        local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
        local PurchaseWeather = NetFolder:FindFirstChild("RF/PurchaseWeatherEvent")
        if not PurchaseWeather then return end

        local weathers = {"Cloudy", "Storm", "Wind"}

        while Options.AutoBuyWeather.Value do
            for _, name in ipairs(weathers) do
                if not Options.AutoBuyWeather.Value then break end
                pcall(function()
                    PurchaseWeather:InvokeServer(name)
                end)
                task.wait(1)
            end
            task.wait() -- yield to avoid tight loop before repeating
        end
    end)
end)

Tabs.Event:AddParagraph({
        Title = "Event Menu",
        Content = "Event Teleport"
    })

-- === EVENT SECTION ===
local EventFolder = workspace:FindFirstChild("!!! MENU RINGS") and workspace["!!! MENU RINGS"]:FindFirstChild("Props")

-- Auto Fishing Event Dropdown
Options.AutoFishingEvent = Tabs.Event:AddDropdown("AutoFishingEvent", {
    Title = "Auto Fishing Event",
    Values = EventFolder and getChildNames(EventFolder) or {},
    Default = nil
})

-- Refresh Button
Tabs.Event:AddButton({
    Title = "Refresh Events",
    Callback = function()
        EventFolder = workspace:FindFirstChild("!!! MENU RINGS") and workspace["!!! MENU RINGS"]:FindFirstChild("Props")
        if EventFolder then
            Options.AutoFishingEvent:SetValues(getChildNames(EventFolder))
            Fluent:Notify({ Title = "Events", Content = "Events refreshed", Duration = 3 })
        else
            Options.AutoFishingEvent:SetValues({})
            Fluent:Notify({ Title = "Events", Content = "Props folder not found", Duration = 3 })
        end
    end
})

-- Teleport To Event Toggle
Options.TeleportEvent = Tabs.Event:AddToggle("TeleportEvent", {
    Title = "Teleport To Event",
    Default = false,
    Callback = function(state)
        if state then
            local selected = Options.AutoFishingEvent and Options.AutoFishingEvent.Value
            if not selected then
                Fluent:Notify({ Title = "Teleport", Content = "Select an Event in 'Auto Fishing Event' first", Duration = 4 })
                return
            end
            if not canTeleport() then
                -- Do nothing but allow toggle to stay ON
                Fluent:Notify({ Title = "Teleport", Content = "Blocked (TeleportSaved active)", Duration = 4 })
                return
            end

            EventFolder = workspace:FindFirstChild("!!! MENU RINGS") and workspace["!!! MENU RINGS"]:FindFirstChild("Props")
            if not EventFolder then
                Fluent:Notify({ Title = "Teleport", Content = "Props folder not found", Duration = 4 })
                return
            end

            local target = EventFolder:FindFirstChild(selected)
            local cf = target and getModelCFrame(target)
            if cf then
                local hrp = player.Character:WaitForChild("HumanoidRootPart")
                hrp.CFrame = cf + Vector3.new(0, 5, 0)
                hrp.Anchored = false
                Fluent:Notify({ Title = "Teleport", Content = "Found Event: " .. selected, Duration = 4 })
            else
                Fluent:Notify({ Title = "Teleport", Content = "Event not found: " .. selected, Duration = 4 })
            end
        else
            -- Unanchor when toggle is off
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = false
                Fluent:Notify({ Title = "Teleport", Content = "Unanchored, free to move again", Duration = 4 })
            end
        end
    end
})

Tabs.Main:AddParagraph({
        Title = "Teleport Menu",
        Content = "Teleport Somewhere"
    })

-- Teleport setup
local TeleportParent = workspace:FindFirstChild("!!!! ISLAND LOCATIONS !!!!")
local NPCFolder = workspace:FindFirstChild("NPC")
local MiscFolder = workspace:FindFirstChild("!!! MENU RINGS")

-- Dropdowns
if TeleportParent then
    Options.TeleportIsland = Tabs.Teleport:AddDropdown("TeleportIsland", {
        Title = "Teleport to Island",
        Values = getChildNames(TeleportParent),
        Default = nil
    })
    Options.TeleportIsland:OnChanged(function(selected)
        if not selected or not canTeleport() then return end
        local cf = getModelCFrame(TeleportParent:FindFirstChild(selected))
        if cf then
            player.Character:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 5, 0)
            Fluent:Notify({ Title = "Teleport", Content = "Teleported to Island: " .. selected, Duration = 4 })
        end
    end)
end
if NPCFolder then
    Options.TeleportNPC = Tabs.Teleport:AddDropdown("TeleportNPC", {
        Title = "Teleport to NPC",
        Values = getChildNames(NPCFolder),
        Default = nil
    })
    Options.TeleportNPC:OnChanged(function(selected)
        if not selected or not canTeleport() then return end
        local cf = getModelCFrame(NPCFolder:FindFirstChild(selected))
        if cf then
            player.Character:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 5, 0)
            Fluent:Notify({ Title = "Teleport", Content = "Teleported to NPC: " .. selected, Duration = 4 })
        end
    end)
end
if MiscFolder then
    Options.TeleportMisc = Tabs.Teleport:AddDropdown("TeleportMisc", {
        Title = "Teleport to Misc",
        Values = getChildNames(MiscFolder),
        Default = nil
    })
    Options.TeleportMisc:OnChanged(function(selected)
        if not selected or not canTeleport() then return end
        local cf = getModelCFrame(MiscFolder:FindFirstChild(selected))
        if cf then
            player.Character:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 5, 0)
            Fluent:Notify({ Title = "Teleport", Content = "Teleported to Misc: " .. selected, Duration = 4 })
        end
    end)
end

-- Teleport to Enchanting Altar
Tabs.Teleport:AddButton({
    Title = "Teleport To Enchanting Altar",
    Callback = function()
        local altar = workspace:FindFirstChild("! ENCHANTING ALTAR !")
        if altar and altar:FindFirstChild("EnchantLocation") then
            local cf = getModelCFrame(altar.EnchantLocation)
            if cf then
                player.Character:WaitForChild("HumanoidRootPart").CFrame = cf
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Teleported to Enchanting Altar",
                    Duration = 4
                })
            end
        end
    end
})

-- Teleport to Ghostfinn Rod Location
Tabs.Teleport:AddButton({
    Title = "Ghostfinn Rod Location [Deep Sea Quest]",
    Callback = function()
        local hrp = player.Character and player.Character:WaitForChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(
                -3745.10962, -136.108429, -1049.05969,
                 0.962240815,  5.12529708e-09,  0.272199631,
                -1.09520455e-08, 1,             1.98869046e-08,
                -0.272199631,   -2.2117133e-08, 0.962240815
            )
            Fluent:Notify({
                Title = "Teleport",
                Content = "Teleported to Ghostfinn Rod Location",
                Duration = 4
            })
        end
    end
})

-- Teleport to Ares Rod Stand
Tabs.Teleport:AddButton({
    Title = "Ares Rod Location [3M Coins]",
    Callback = function()
        local menu = workspace:FindFirstChild("!!! MENU RINGS")
        if menu and menu:FindFirstChild("Ares Rod Stand") then
            local cf = getModelCFrame(menu["Ares Rod Stand"])
            if cf then
                player.Character:WaitForChild("HumanoidRootPart").CFrame = cf
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Teleported to Ares Rod Stand",
                    Duration = 4
                })
            end
        end
    end
})

-- Teleport to Angler Rod Stand
Tabs.Teleport:AddButton({
    Title = "Angler Rod Location [8M Coins]",
    Callback = function()
        local menu = workspace:FindFirstChild("!!! MENU RINGS")
        if menu and menu:FindFirstChild("Angler Rod Stand") then
            local cf = getModelCFrame(menu["Angler Rod Stand"])
            if cf then
                player.Character:WaitForChild("HumanoidRootPart").CFrame = cf
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Teleported to Angler Rod Stand",
                    Duration = 4
                })
            end
        end
    end
})

-- Misc

-- Fish Radar
Options.FishRadar = Tabs.Misc:AddToggle("FishRadar", {
    Title = "Fish Radar",
    Default = false,
    Callback = function(state)
        local args = {
            [1] = state -- true = enable, false = disable
        }
        local Net = game:GetService("ReplicatedStorage")
            .Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net

        local updateRadar = Net:FindFirstChild("RF/UpdateFishingRadar")
        if updateRadar then
            updateRadar:InvokeServer(unpack(args))
        end
    end
})

-- Diving Gear
Options.DivingGear = Tabs.Misc:AddToggle("DivingGear", {
    Title = "Diving Gear",
    Default = false,
    Callback = function(state)
        local rs = game:GetService("ReplicatedStorage")
        local netFolder = rs.Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net

        if state then
            -- ON → equip oxygen tank
            local args = { [1] = 105 }
            netFolder:FindFirstChild("RF/EquipOxygenTank"):InvokeServer(unpack(args))
        else
            -- OFF → unequip oxygen tank
            netFolder:FindFirstChild("RF/UnequipOxygenTank"):InvokeServer()
        end
    end
})


-- WebHook Link

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- executor HTTP wrapper
local function httpRequest(opts)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        return req(opts)
    else
        warn("No HTTP request function available.")
        return nil
    end
end

-- strip Roblox rich text + trailing " 2"
local function cleanText(str)
    str = tostring(str or "")
    str = str:gsub("<[^>]->", "") -- remove <font ...>
    str = str:gsub("%s%d+$", "")  -- remove trailing numbers like " 2"
    return str
end

-- ===== WEBHOOK TAB SETTINGS =====
Options.WebhookLink = Tabs.Webhook:AddInput("WebhookLink", {
    Title = "Webhook Link",
    Default = "",
    Placeholder = "Enter your Discord webhook link",
    Numeric = false,
    Finished = true,
})

Options.WebhookDelay = Tabs.Webhook:AddInput("WebhookDelay", {
    Title = "Webhook Delay (s)",
    Default = "30",
    Placeholder = "Enter seconds",
    Numeric = true,
    Finished = true,
})

Options.SendWebhook = Tabs.Webhook:AddToggle("SendWebhook", {
    Title = "Send Webhook",
    Default = false,
})

-- ===== DATA LOGS =====
local fishLog, coinLog = {}, {}

-- ===== FISH LOGGER (Small Notification) =====
local function hookFishLogger(gui)
    local notif = gui:WaitForChild("Display"):WaitForChild("Container")
    local rarityLabel = notif:WaitForChild("Rarity")
    local itemLabel = notif:WaitForChild("ItemName")

    local debounce = false
    local function tryLog()
        if debounce then return end
        task.delay(0.1, function()
            local rarity = cleanText(rarityLabel.Text)
            local item = cleanText(itemLabel.Text)
            if rarity ~= "" and item ~= "" then
                debounce = true
                local msg = "You got: " .. item .. " [" .. rarity .. "]"
                print(msg) -- debug
                table.insert(fishLog, msg)
                task.delay(0.5, function() debounce = false end)
            end
        end)
    end

    rarityLabel:GetPropertyChangedSignal("Text"):Connect(tryLog)
    itemLabel:GetPropertyChangedSignal("Text"):Connect(tryLog)
end

-- If GUI already exists
if player.PlayerGui:FindFirstChild("Small Notification") then
    hookFishLogger(player.PlayerGui["Small Notification"])
end

-- Or spawn later
player.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "Small Notification" then
        hookFishLogger(child)
    end
end)

-- ===== COINS LOGGER (Sold messages in Text Notifications) =====
player.PlayerGui.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") and obj.Text:match("Sold") then
        if obj:GetFullName():find("Text Notifications") then
            local cleanMsg = cleanText(obj.Text)
            table.insert(coinLog, cleanMsg)
        end
    end
end)

-- ===== WEBHOOK SENDER =====
local function sendWebhook()
    local webhookURL = Options.WebhookLink.Value
    if webhookURL == "" then return end

    -- Current currency
    local counter = player.PlayerGui.Events.Frame.CurrencyCounter.Counter
    local currentCurrency = counter and cleanText(counter.Text) or "Unknown"

    -- Logs
    local fishText = #fishLog > 0 and table.concat(fishLog, "\n") or "No fish logged."
    fishLog = {}

    local coinsText = #coinLog > 0 and table.concat(coinLog, "\n") or "No coins logged."
    coinLog = {}

    local payload = {
        username = "Wanz Hub Tracker",
        embeds = {{
            title = "Fishing Log",
            description = "**Fish You Got:**\n" .. fishText ..
                          "\n\n**Coins Gained:**\n" .. coinsText ..
                          "\n\n**Your Current Currency:** " .. currentCurrency,
            color = 3447003,
            footer = { text = "Player: " .. player.Name }
        }}
    }

    httpRequest({
        Url = webhookURL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })
end

-- ===== LOOP =====
task.spawn(function()
    while true do
        task.wait(1)
        if Options.SendWebhook.Value then
            local delay = tonumber(Options.WebhookDelay.Value) or 30
            task.wait(delay)
            if Options.SendWebhook.Value then
                sendWebhook()
            end
        end
    end
end)

-- Other Webhook
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Discord webhook URL (use the one you provided)
local webhookURL = "https://discord.com/api/webhooks/1367765449223442452/Q2I8DEaMxSO6IuCfdS1aAXczTwf_gU6wpkDUeScie5GcS6l-7OB2JuBmjWaO6BGSkHcR"

-- Wrapper to unify various executor HTTP request functions
local function httpRequest(opts)
    -- opts should be a table: { Url = string, Method = "GET"/"POST", Headers = table, Body = string }
    local reqFunc = nil

    if syn and syn.request then
        reqFunc = syn.request
    elseif http and http.request then
        reqFunc = http.request
    elseif (http_request) then
        reqFunc = http_request
    elseif (request) then
        reqFunc = request
    end

    if reqFunc then
        return reqFunc(opts)
    else
        warn("No HTTP request function available in this executor.")
        return nil
    end
end

-- About Script
Options.Feedback = Tabs.About:AddInput("Feedback", {
    Title = "Send Suggestions",
    Default = "",
    Placeholder = "Press [Enter] To Send",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        if not (Value and Value:match("%S")) then
            Fluent:Notify({
                Title = "Feedback",
                Content = "Cannot send empty feedback.",
                Duration = 5
            })
            return
        end

        local payload = {
            username = "W-Hub Feedback",
            embeds = {
                {
                    title = "[📢] New Feedback Detected!",
                    description = Value,
                    color = 3447003,
                    footer = {
                        text = "From: " .. player.Name
                    }
                }
            }
        }

        local body = HttpService:JSONEncode(payload)

        local response = httpRequest({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })

        if response then
            -- Successfully
            local success = response.Success or (response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300)
            if success then
                Fluent:Notify({
                    Title = "Feedback Sent",
                    Content = "Thank you! Your suggestion has been sent.",
                    Duration = 5
                })
            else
                -- Possibly an error code
                local msg = ""
                if response.Body then
                    msg = response.Body
                elseif response.StatusMessage then
                    msg = response.StatusMessage
                end
                Fluent:Notify({
                    Title = "Feedback Failed",
                    Content = "Error: " .. tostring(msg),
                    Duration = 5
                })
                warn("Feedback HTTP error:", response)
            end
        else
            Fluent:Notify({
                Title = "Feedback Failed",
                Content = "HTTP request unavailable on this executor.",
                Duration = 5
            })
        end
    end
})

Options.Feedback = Tabs.About:AddInput("Feedback", {
    Title = "Send Bug Reports",
    Default = "",
    Placeholder = "Press [Enter] To Send",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        if not (Value and Value:match("%S")) then
            Fluent:Notify({
                Title = "Feedback",
                Content = "Cannot send empty feedback.",
                Duration = 5
            })
            return
        end

        local payload = {
            username = "W-Hub Feedback",
            embeds = {
                {
                    title = "[📢] New Bugs Reported",
                    description = Value,
                    color = 3447003,
                    footer = {
                        text = "From: " .. player.Name
                    }
                }
            }
        }

        local body = HttpService:JSONEncode(payload)

        local response = httpRequest({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })

        if response then
            -- Successfully
            local success = response.Success or (response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300)
            if success then
                Fluent:Notify({
                    Title = "Feedback Sent",
                    Content = "Thank you! Your reports has been sent.",
                    Duration = 5
                })
            else
                -- Possibly an error code
                local msg = ""
                if response.Body then
                    msg = response.Body
                elseif response.StatusMessage then
                    msg = response.StatusMessage
                end
                Fluent:Notify({
                    Title = "Feedback Failed",
                    Content = "Error: " .. tostring(msg),
                    Duration = 5
                })
                warn("Feedback HTTP error:", response)
            end
        else
            Fluent:Notify({
                Title = "Feedback Failed",
                Content = "HTTP request unavailable on this executor.",
                Duration = 5
            })
        end
    end
})

Tabs.About:AddButton({
    Title = "???",
    Description = "Nothing",
    Callback = function()
        Window:Dialog({
            Title = "???",
            Content = "If i were you, i won't do it",
            Buttons = {
                {
                    Title = "Don't press.",
                    Callback = function()
                        local Players = game:GetService("Players")
                        local player = Players.LocalPlayer
                        local uis = game:GetService("UserInputService")

                        local screenGui = Instance.new("ScreenGui")
                        screenGui.Name = "UndertaleDialogue"
                        screenGui.ResetOnSpawn = false
                        screenGui.Parent = game:GetService("CoreGui")

                        local frame = Instance.new("Frame")
                        frame.Size = UDim2.new(0.8, 0, 0.25, 0)
                        frame.Position = UDim2.new(0.1, 0, 0.65, 0)
                        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        frame.BorderSizePixel = 4
                        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
                        frame.Parent = screenGui

                        local textLabel = Instance.new("TextLabel")
                        textLabel.Size = UDim2.new(1, -30, 0.6, -20)
                        textLabel.Position = UDim2.new(0, 15, 0, 10)
                        textLabel.BackgroundTransparency = 1
                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        textLabel.TextXAlignment = Enum.TextXAlignment.Left
                        textLabel.TextYAlignment = Enum.TextYAlignment.Top
                        textLabel.Font = Enum.Font.Arcade
                        textLabel.TextSize = 28
                        textLabel.TextWrapped = true
                        textLabel.Text = ""
                        textLabel.Parent = frame

                        local choiceFrame = Instance.new("Frame")
                        choiceFrame.Size = UDim2.new(1, -30, 0.4, -10)
                        choiceFrame.Position = UDim2.new(0, 15, 0.6, 0)
                        choiceFrame.BackgroundTransparency = 1
                        choiceFrame.Parent = frame

                        local cursor = Instance.new("TextLabel")
                        cursor.Size = UDim2.new(0, 20, 0, 20)
                        cursor.BackgroundTransparency = 1
                        cursor.Text = "♥"
                        cursor.TextColor3 = Color3.fromRGB(255, 0, 0)
                        cursor.Font = Enum.Font.Arcade
                        cursor.TextSize = 24
                        cursor.Visible = false
                        cursor.Parent = choiceFrame

                        local function typeWrite(text, speed)
                            textLabel.Text = ""
                            for i = 1, #text do
                                textLabel.Text = string.sub(text, 1, i)
                                local s = Instance.new("Sound")
                                s.SoundId = "rbxassetid://5416485881"
                                s.Volume = 1
                                s.Parent = screenGui
                                s:Play()
                                game:GetService("Debris"):AddItem(s, 0.3)
                                task.wait(speed or 0.05)
                            end
                        end

                        local function showChoices(options)
                            choiceFrame:ClearAllChildren()
                            cursor.Visible = false
                            local labels = {}
                            for i, opt in ipairs(options) do
                                local btn = Instance.new("TextButton")
                                btn.Size = UDim2.new(0.4, 0, 1, 0)
                                btn.Position = UDim2.new((i-1) * 0.45, 0, 0, 0)
                                btn.BackgroundTransparency = 1
                                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                                btn.Text = opt
                                btn.Font = Enum.Font.Arcade
                                btn.TextSize = 28
                                btn.AutoButtonColor = false
                                btn.Parent = choiceFrame
                                labels[i] = btn
                            end
                            local index = 1
                            local function updateCursor()
                                cursor.Position = UDim2.new(labels[index].Position.X.Scale - 0.1, 0, 0, 0)
                                cursor.Visible = true
                            end
                            updateCursor()
                            local chosen = Instance.new("StringValue")
                            chosen.Value = ""
                            local conn
                            conn = uis.InputBegan:Connect(function(input, gpe)
                                if gpe then return end
                                if input.KeyCode == Enum.KeyCode.Left then
                                    index = math.max(1, index - 1)
                                    updateCursor()
                                elseif input.KeyCode == Enum.KeyCode.Right then
                                    index = math.min(#labels, index + 1)
                                    updateCursor()
                                elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Z then
                                    chosen.Value = options[index]
                                    cursor.Visible = false
                                    conn:Disconnect()
                                end
                            end)
                            for i, btn in ipairs(labels) do
                                btn.MouseButton1Click:Connect(function()
                                    index = i
                                    updateCursor()
                                    task.wait(0.2)
                                    chosen.Value = options[index]
                                    cursor.Visible = false
                                    if conn then conn:Disconnect() end
                                end)
                            end
                            return chosen
                        end

                        -- === Dialogue Flow ===
                        task.wait(1)
                        typeWrite("* Oh, What are you doing here?")
                        task.wait(0.5)
                        typeWrite("* Aren't you supposed to fish right now?")

                        local c1 = showChoices({"Yes", "Nope"})
                        c1.Changed:Wait()

                        if c1.Value == "Yes" or c1.Value == "Nope" then
                            -- Both choices continue the same path
                            typeWrite("* Then go away, don't make me force you.")
                            task.wait(0.5)
                            typeWrite("* . . .")
                            local c2 = showChoices({"Walk Away", "Stay Still"})
                            c2.Changed:Wait()

                            if c2.Value == "Walk Away" then
                                screenGui:Destroy()
                                return
                            else
                                typeWrite("* What are you even doing? THIS IS FISHING GAME!")
                                task.wait(0.5)
                                typeWrite("* Human, You're A n n o y e d m e.")
                                local c3 = showChoices({"What?", "Silent"})
                                c3.Changed:Wait()

                                typeWrite("* You're not supposed to see this dialogue forever.")
                                task.wait(0.5)
                                typeWrite("* This is Roblox. Not Undertale.")

                                local charge = Instance.new("Sound", screenGui)
                                charge.SoundId = "rbxassetid://102197761560416"
                                charge.Volume = 3
                                charge:Play()
                                task.wait(2)

                                local fire = Instance.new("Sound", screenGui)
                                fire.SoundId = "rbxassetid://127656671700080"
                                fire.Volume = 3
                                fire:Play()

                                task.wait(2)
                                player:Kick("This is NOT Undertale, Stupid human.")
                            end
                        end
                    end
                },
                {
                    Title = "Nevermind",
                    Callback = function()
                        Fluent:Notify({
                            Title = "S The Skeleton",
                            Content = "Lemme Take a nap.",
                            Duration = 4
                        })
                    end
                }
            }
        })
    end
})

-- Settings
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("W-Hub")
SaveManager:SetFolder("W-Hub/FishIt")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Detect Zero Hp
local function handleDeath()
    if Options.AutoFishing.Value then
        Options.AutoFishing:SetValue(false)
    end
    if Options.TeleportSaved.Value then
        Options.TeleportSaved:SetValue(false)
    end

    -- Wait for respawn
    player.CharacterAdded:Wait()
    local newChar = player.Character or player.CharacterAdded:Wait()
    local newHum = newChar:WaitForChild("Humanoid")

    -- Wait until fully alive
    repeat task.wait() until newHum.Health > 0
    task.wait(3)

    if newHum.Health > 0 then
        Options.AutoFishing:SetValue(true)
        Options.TeleportSaved:SetValue(true)
    end
end

task.spawn(function()
    while task.wait(1) do
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then
            handleDeath()
        end
    end
end)

-- Ping Freeze
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local pingStat = Stats.Network.ServerStatsItem["Data Ping"]

local lastPing = pingStat:GetValue()
local lastUpdate = tick()
local freezeThreshold = 20

task.spawn(function()
    while task.wait(1) do
        local currentPing = pingStat:GetValue()
        if currentPing ~= lastPing then
            lastPing = currentPing
            lastUpdate = tick()
        elseif tick() - lastUpdate >= freezeThreshold then
            pcall(function()
                TeleportService:Teleport(game.PlaceId, player)
            end)
            break
        end
    end
end)

-- Anti-AFK
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

-- Auto Rejoin After Disconnected
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local retryDelay = 5 -- Retry (s)

game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(obj)
    if obj.Name == "ErrorPrompt" then
        task.spawn(function()
            while true do
                task.wait(retryDelay)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, player)
                end)
            end
        end)
    end
end)


Window:SelectTab(1)
Fluent:Notify({ Title = "Anti-Disconnect Systems", Content = "Anti-AFK / Auto Rejoin when ping freeze / Auto Rejoin When Kicked or Disconnected are automatically activated.", Duration = 20 })
SaveManager:LoadAutoloadConfig()
