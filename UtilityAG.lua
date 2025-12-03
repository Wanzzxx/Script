if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Anime Guardians Helper Script",
    SubTitle = "Half Human & Half AI",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local logoGui = Instance.new("ScreenGui")
logoGui.Name = "WnZGUI"
logoGui.ResetOnSpawn = false
logoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
logoGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local logoButton = Instance.new("ImageButton")
logoButton.Name = "VeryNormalImage"
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

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftControl then
        toggleFluent()
    end
end)

local Tabs = {
    Tracker = Window:AddTab({ Title = "Tracker", Icon = "users" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "wrench" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Joiner = Window:AddTab({ Title = "Joiner", Icon = "layers" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "send" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "plus" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local targetPlaceId = 17282336195
local retryDelay = 5

local challengeFired = false
local startFired = false
local joinerActive = false
local webhookSent = false
local HttpService = game:GetService("HttpService")

local eventActMap = {
    ["Saitama"] = 1,
    ["Blast"] = 2,
    ["Garou"] = 3,
    ["Sai Akuto"] = 4,
    ["Platinum Cell"] = 5,
    ["Waguri"] = 6
}

local eventStageMap = {
    ["Robin (HSR)"] = "Mushroom",
    ["Castorice (HSR)"] = "Mushroom2",
    ["Shibuya"] = "Shibuya",
    ["Ragna"] = "Ragna",
    ["World Boss (Shinbara)"] = "Shinbara"
}

local function formatNumber(num)
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

do
    local EventCurrencyParagraph = Tabs.Tracker:AddParagraph({
        Title = "Event Currency",
        Content = "Getting your data..."
    })

    local MainCurrencyParagraph = Tabs.Tracker:AddParagraph({
        Title = "Main Currency",
        Content = "Getting your data..."
    })

    local allowedMainCurrency = {
        "Coins",
        "Mushroom",
        "MoonNight",
        "Reroll_Tokens",
        "StatReroll",
        "SuperStatReroll"
    }

    task.spawn(function()
        while true do
            task.wait(1)
            
            local eventContent = ""
            if LocalPlayer:FindFirstChild("ItemsInventory") then
                for _, item in pairs(LocalPlayer.ItemsInventory:GetChildren()) do
                    if item.Name:find("Coin") and item:FindFirstChild("Amount") then
                        local amount = formatNumber(item.Amount.Value)
                        eventContent = eventContent .. item.Name .. ": " .. amount .. "\n"
                    end
                end
            end
            
            if eventContent == "" then
                eventContent = "No event coins found"
            end
            
            EventCurrencyParagraph:SetDesc(eventContent)
            
            local mainContent = ""
            if LocalPlayer:FindFirstChild("Data") then
                for _, currencyName in ipairs(allowedMainCurrency) do
                    local currencyObj = LocalPlayer.Data:FindFirstChild(currencyName)
                    if currencyObj and currencyObj:IsA("NumberValue") then
                        local amount = formatNumber(currencyObj.Value)
                        mainContent = mainContent .. currencyName .. ": " .. amount .. "\n"
                    end
                end
            end
            
            if mainContent == "" then
                mainContent = "No currency data found"
            end
            
            MainCurrencyParagraph:SetDesc(mainContent)
            
            if Fluent.Unloaded then break end
        end
    end)
end

do
    local ChallengeDropdown = Tabs.Utility:AddDropdown("SelectChallenge", {
        Title = "Select Challenge",
        Description = "Choose your challenge type",
        Values = {"Normal", "Fast Wave", "Super Faster Wave"},
        Multi = false,
        Default = 1,
    })

    local AutoVoteToggle = Tabs.Utility:AddToggle("AutoVote", {
        Title = "Auto Vote Start and Challenge",
        Default = false
    })

local BackToLobbyToggle = Tabs.Utility:AddToggle("BackToLobby", {
    Title = "Back to Lobby When Disconnected",
    Description = "IF you're using DELTA, Make sure to disable "Verify Teleports". Else it's not going to work.",
    Default = false
})

game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(obj)
    if obj.Name == "ErrorPrompt" then
        task.spawn(function()
            while Options.BackToLobby.Value do
                task.wait(retryDelay)
                pcall(function()
                    TeleportService:Teleport(targetPlaceId, LocalPlayer)
                end)
            end
        end)
    end
end)
    
    task.spawn(function()
        while true do
            task.wait(0.5)
            
            if Options.AutoVote.Value then
                local endGUIEnabled = LocalPlayer.PlayerGui:FindFirstChild("EndGUI") and LocalPlayer.PlayerGui.EndGUI.Enabled
                
                if endGUIEnabled then
                    challengeFired = false
                    startFired = false
                else
                    local stagesChallengeEnabled = LocalPlayer.PlayerGui:FindFirstChild("StagesChallenge") and LocalPlayer.PlayerGui.StagesChallenge.Enabled
                    local gameStarted = workspace:FindFirstChild("GameSettings") and workspace.GameSettings:FindFirstChild("GameStarted") and workspace.GameSettings.GameStarted.Value
                    
                    if stagesChallengeEnabled and not challengeFired then
                        local selectedChallenge = Options.SelectChallenge.Value
                        if selectedChallenge then
                            pcall(function()
                                ReplicatedStorage.PlayMode.Events.StageChallenge:FireServer(selectedChallenge)
                            end)
                            challengeFired = true
                        end
                    end
                    
                    if not stagesChallengeEnabled and challengeFired and not gameStarted and not startFired then
                        task.wait(2)
                        pcall(function()
                            ReplicatedStorage.PlayMode.Events.Vote:FireServer("start")
                        end)
                        startFired = true
                    end
                    
                    if gameStarted then
                        startFired = false
                        challengeFired = false
                    end
                    
                    if not stagesChallengeEnabled and not challengeFired then
                        challengeFired = false
                    end
                end
            else
                challengeFired = false
                startFired = false
            end
            
            if Fluent.Unloaded then break end
        end
    end)
end

do
    
    local function getCSMShopItems()
    local items = {}
    local csmShop = LocalPlayer:FindFirstChild("NpcShop") and LocalPlayer.NpcShop:FindFirstChild("ChainsawMan")
    if csmShop then
        for _, item in pairs(csmShop:GetChildren()) do
            if item:IsA("Folder") and item:FindFirstChild("Price") then
                local price = item.Price.Value
                table.insert(items, item.Name .. " - " .. formatNumber(price))
            end
        end
    end
    return items
    end
    
    local function getCapsules()
        local capsules = {}
        if LocalPlayer:FindFirstChild("ItemsInventory") then
            for _, item in pairs(LocalPlayer.ItemsInventory:GetChildren()) do
                if item.Name:find("Capsule") and item:FindFirstChild("Amount") then
                    table.insert(capsules, item.Name)
                end
            end
        end
        return capsules
    end
    
    local CSMShopDropdown = Tabs.Shop:AddDropdown("AutoBuyCSMShop", {
        Title = "Auto Buy CSM Shop",
        Description = "Select item to auto-buy",
        Values = getCSMShopItems(),
        Multi = false,
        Default = nil,
    })
    
    local BuyAmountInput = Tabs.Shop:AddInput("BuyAmountItems", {
        Title = "Buy Amount Items",
        Default = "1",
        Placeholder = "Amount to buy per cycle",
        Numeric = true
    })
    
    local StartBuyingToggle = Tabs.Shop:AddToggle("StartBuying", {
        Title = "Start Buying",
        Default = false
    })
    
    local CapsuleDropdown = Tabs.Shop:AddDropdown("AutoOpenCapsule", {
        Title = "Auto Open Capsule",
        Description = "Select capsule to auto-open",
        Values = getCapsules(),
        Multi = false,
        Default = nil,
    })
    
    local UseAmountInput = Tabs.Shop:AddInput("UseAmountCapsule", {
        Title = "Use Amount Capsule",
        Default = "1",
        Placeholder = "Amount to use per cycle",
        Numeric = true
    })
    
    local StartOpeningToggle = Tabs.Shop:AddToggle("StartOpening", {
        Title = "Start Opening",
        Default = false
    })
    
    Tabs.Shop:AddButton({
        Title = "Refresh Lists",
        Description = "Refresh shop items and capsules",
        Callback = function()
            CSMShopDropdown:SetValues(getCSMShopItems())
            CapsuleDropdown:SetValues(getCapsules())
            Fluent:Notify({
                Title = "Refreshed",
                Content = "Shop and capsule lists updated",
                Duration = 3
            })
        end
    })

task.spawn(function()
    while true do
        task.wait(0.5)
        
        if Options.StartBuying.Value then
            local selectedItem = Options.AutoBuyCSMShop.Value
            local buyAmount = tonumber(Options.BuyAmountItems.Value) or 1
            
            if selectedItem then
                local itemName = selectedItem:match("^(.-)%s*%-%s*") or selectedItem
                itemName = itemName:gsub("%s+$", "")
                
                local csmCoin = LocalPlayer.ItemsInventory:FindFirstChild("CSM Coin")
                local currentTokens = csmCoin and csmCoin:FindFirstChild("Amount") and csmCoin.Amount.Value or 0
                
                local itemPrice = 0
                local csmShop = LocalPlayer:FindFirstChild("NpcShop") and LocalPlayer.NpcShop:FindFirstChild("ChainsawMan")
                if csmShop and csmShop:FindFirstChild(itemName) and csmShop[itemName]:FindFirstChild("Price") then
                    itemPrice = csmShop[itemName].Price.Value
                end
                
                local affordableAmount = itemPrice > 0 and math.floor(currentTokens / itemPrice) or 0
                
                if itemName:find("Capsule") then
                    local currentAmount = 0
                    local capsuleItem = LocalPlayer.ItemsInventory:FindFirstChild(itemName)
                    
                    if capsuleItem and capsuleItem:FindFirstChild("Amount") then
                        currentAmount = capsuleItem.Amount.Value
                    end
                    
                    local maxCapacity = 1000
                    local spaceAvailable = maxCapacity - currentAmount
                    
                    if spaceAvailable > 0 and affordableAmount > 0 then
                        local finalBuyAmount = math.min(buyAmount, affordableAmount, spaceAvailable)
                        
                        pcall(function()
                            ReplicatedStorage.PlayMode.Events.EventShop:InvokeServer(
                                finalBuyAmount,
                                itemName,
                                "ChainsawMan"
                            )
                        end)
                    end
                else
                    if affordableAmount > 0 then
                        local finalBuyAmount = math.min(buyAmount, affordableAmount)
                        
                        pcall(function()
                            ReplicatedStorage.PlayMode.Events.EventShop:InvokeServer(
                                finalBuyAmount,
                                itemName,
                                "ChainsawMan"
                            )
                        end)
                    end
                end
            end
        end
        
        if Options.StartOpening.Value then
            local selectedCapsule = Options.AutoOpenCapsule.Value
            local useAmount = tonumber(Options.UseAmountCapsule.Value) or 1
            
            if selectedCapsule then
                local capsuleItem = LocalPlayer.ItemsInventory:FindFirstChild(selectedCapsule)
                if capsuleItem and capsuleItem:FindFirstChild("Amount") and capsuleItem.Amount.Value > 0 then
                    pcall(function()
                        ReplicatedStorage.PlayMode.Events.Use:InvokeServer(
                            selectedCapsule,
                            useAmount
                        )
                    end)
                end
            end
        end
        
        if Fluent.Unloaded then break end
    end
end)
end

do
    Tabs.Joiner:AddParagraph({
        Title = "Event Joiner",
        Content = "Quick join for OPM and Event stages"
    })

    local OPMEventDropdown = Tabs.Joiner:AddDropdown("SelectOPMEvent", {
        Title = "Select OPM Event",
        Description = "Choose which OPM character event to host",
        Values = {"Saitama", "Blast", "Garou", "Sai Akuto", "Platinum Cell", "Waguri"},
        Multi = false,
        Default = nil,
    })

    local JoinerStartToggle = Tabs.Joiner:AddToggle("JoinerStart", {
        Title = "Start",
        Default = false
    })

    task.spawn(function()
        while true do
            task.wait(1)
            
            if Options.JoinerStart.Value then
                local selectedEvent = Options.SelectOPMEvent.Value
                if selectedEvent and eventActMap[selectedEvent] then
                    local actNumber = eventActMap[selectedEvent]
                    pcall(function()
                        ReplicatedStorage.Remote.RoomFunction:InvokeServer("host", {
                            ["stage"] = "Cosmic Annihilation",
                            ["friendOnly"] = false,
                            ["act"] = actNumber
                        })
                    end)
                    
                    task.wait(0.5)
                    
                    pcall(function()
                        ReplicatedStorage.Remote.RoomFunction:InvokeServer("start")
                    end)
                end
            end
            
            if Fluent.Unloaded then break end
        end
    end)

    local JoinEventDropdown = Tabs.Joiner:AddDropdown("SelectJoinEvent", {
        Title = "Select Join Event",
        Description = "Choose which event stage to host",
        Values = {"Robin (HSR)", "Castorice (HSR)", "Shibuya", "Ragna", "World Boss (Shinbara)"},
        Multi = false,
        Default = nil,
    })

    local JoinEventStartToggle = Tabs.Joiner:AddToggle("JoinEventStart", {
        Title = "Start",
        Default = false
    })

    task.spawn(function()
        while true do
            task.wait(1)
            
            if Options.JoinEventStart.Value then
                local selectedEvent = Options.SelectJoinEvent.Value
                if selectedEvent and eventStageMap[selectedEvent] then
                    local stageName = eventStageMap[selectedEvent]
                    pcall(function()
                        ReplicatedStorage.Remote.RoomFunction:InvokeServer("host", {
                            ["stage"] = stageName,
                            ["friendOnly"] = false
                        })
                    end)
                    
                    task.wait(0.5)
                    
                    pcall(function()
                        ReplicatedStorage.Remote.RoomFunction:InvokeServer("start")
                    end)
                end
            end
            
            if Fluent.Unloaded then break end
        end
    end)

    Tabs.Joiner:AddParagraph({
        Title = "Raid & Tower",
        Content = "Auto-create and start Raid or Tower stages"
    })

    local ModeDropdown = Tabs.Joiner:AddDropdown("SelectMode", {
        Title = "Select Mode",
        Description = "Choose Raid or Tower Adventures",
        Values = {"Raid", "Tower Adventures"},
        Multi = false,
        Default = nil,
    })

    local StageDropdown = Tabs.Joiner:AddDropdown("SelectStage", {
        Title = "Select Stage",
        Description = "Choose stage based on selected mode",
        Values = {},
        Multi = false,
        Default = nil,
    })

    local ModeStartToggle = Tabs.Joiner:AddToggle("ModeStart", {
        Title = "Start",
        Default = false
    })

    ModeDropdown:OnChanged(function(Value)
        local stageList = {}
        
        if Value == "Tower Adventures" then
            for _, folder in pairs(LocalPlayer.Stages:GetChildren()) do
                if folder:IsA("Folder") and folder:FindFirstChild("Floor") then
                    table.insert(stageList, folder.Name)
                end
            end
        elseif Value == "Raid" then
            local raidFrame = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("PortalFrame") and LocalPlayer.PlayerGui.Main.PortalFrame:FindFirstChild("StageFrame") and LocalPlayer.PlayerGui.Main.PortalFrame.StageFrame:FindFirstChild("RaidScrollingFrame")
            if raidFrame then
                for _, frame in pairs(raidFrame:GetChildren()) do
                    if frame:IsA("Frame") then
                        table.insert(stageList, frame.Name)
                    end
                end
            end
        end
        
        StageDropdown:SetValues(stageList)
        Options.SelectStage:SetValue(nil)
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            
            if Options.ModeStart.Value then
                local selectedMode = Options.SelectMode.Value
                local selectedStage = Options.SelectStage.Value
                
                if selectedMode and selectedStage then
                    if selectedMode == "Tower Adventures" then
                        local stageFolder = LocalPlayer.Stages:FindFirstChild(selectedStage)
                        if stageFolder and stageFolder:FindFirstChild("Floor") then
                            local currentFloor = tostring(stageFolder.Floor.Value)
                            
                            pcall(function()
                                ReplicatedStorage.PlayMode.Events.CreatingPortal:InvokeServer("Tower Adventures", {
                                    selectedStage,
                                    currentFloor,
                                    "Tower Adventures"
                                })
                            end)
                            
                            task.wait(0.5)
                            
                            pcall(function()
                                ReplicatedStorage.PlayMode.Events.CreatingPortal:InvokeServer("Create", {
                                    selectedStage,
                                    currentFloor,
                                    "Tower Adventures"
                                })
                            end)
                        end
                    elseif selectedMode == "Raid" then
                        pcall(function()
                            ReplicatedStorage.PlayMode.Events.CreatingPortal:InvokeServer("Raid", {
                                selectedStage,
                                "1",
                                "Raid"
                            })
                        end)
                        
                        task.wait(0.5)
                        
                        pcall(function()
                            ReplicatedStorage.PlayMode.Events.CreatingPortal:InvokeServer("Create", {
                                selectedStage,
                                "1",
                                "Raid"
                            })
                        end)
                    end
                end
            end
            
            if Fluent.Unloaded then break end
        end
    end)
end

do
    local WebhookInput = Tabs.Webhook:AddInput("WebhookURL", {
        Title = "Insert Webhook",
        Default = "",
        Placeholder = "https://discord.com/api/webhooks/..."
    })

    local PingInput = Tabs.Webhook:AddInput("PingOnSecret", {
        Title = "Ping on Secret Drop",
        Default = "",
        Placeholder = "User/Role ID (empty = @everyone)"
    })

    local EnableWebhookToggle = Tabs.Webhook:AddToggle("EnableWebhook", {
        Title = "Enable Webhook",
        Default = false
    })

    task.spawn(function()
        while true do
            task.wait(0.2)
            
            if Options.EnableWebhook.Value and Options.WebhookURL.Value ~= "" then
                local endGUI = LocalPlayer.PlayerGui:FindFirstChild("EndGUI")
                
                if endGUI and endGUI.Enabled and not webhookSent then
                    print("EndGUI detected as enabled!")
                    task.wait(0.2)
                    
                    if endGUI.Enabled then
                        webhookSent = true
                        print("Starting reward collection...")
                        
                        local rewardsData = {}
                        local unitsObtained = {}
                        local hasSecretDrop = false
                        
                        local context = endGUI:FindFirstChild("Main") and endGUI.Main:FindFirstChild("Context") and endGUI.Main.Context.Text or "Unknown"
                        local stageName = endGUI:FindFirstChild("Main") and endGUI.Main:FindFirstChild("Stage") and endGUI.Main.Stage:FindFirstChild("Stageinfo") and endGUI.Main.Stage.Stageinfo:FindFirstChild("stages") and endGUI.Main.Stage.Stageinfo.stages.Text or "Unknown"
                        local actName = endGUI:FindFirstChild("Main") and endGUI.Main:FindFirstChild("Stage") and endGUI.Main.Stage:FindFirstChild("Stageinfo") and endGUI.Main.Stage.Stageinfo:FindFirstChild("Act") and endGUI.Main.Stage.Stageinfo.Act.Text or "Unknown"
                        local difficulty = endGUI:FindFirstChild("Main") and endGUI.Main:FindFirstChild("Stage") and endGUI.Main.Stage:FindFirstChild("Stageinfo") and endGUI.Main.Stage.Stageinfo:FindFirstChild("Difficulty") and endGUI.Main.Stage.Stageinfo.Difficulty.Text or "Unknown"
                        local playTimeRaw = endGUI:FindFirstChild("Main") and endGUI.Main:FindFirstChild("Stage") and endGUI.Main.Stage:FindFirstChild("Statistics") and endGUI.Main.Stage.Statistics:FindFirstChild("PlayTime") and endGUI.Main.Stage.Statistics.PlayTime:FindFirstChild("Label") and endGUI.Main.Stage.Statistics.PlayTime.Label.Text or "Unknown"
                        local playTime = playTimeRaw:gsub("Play Time: ", "")
                        
                        local scrollingFrame = endGUI:FindFirstChild("Main") and endGUI.Main:FindFirstChild("Stage") and endGUI.Main.Stage:FindFirstChild("Rewards") and endGUI.Main.Stage.Rewards:FindFirstChild("ScrollingFrame")
                        
                        if scrollingFrame then
                            print("ScrollingFrame found!")
                            for _, rewardFrame in pairs(scrollingFrame:GetChildren()) do
                                if rewardFrame:IsA("Frame") then
                                    local itemName = rewardFrame.Name
                                    local nameLabel = rewardFrame:FindFirstChild("name")
                                    local quantityObj = rewardFrame:FindFirstChild("Quantity")
                                    
                                    if nameLabel and nameLabel:IsA("TextLabel") then
                                        local unitName = nameLabel.Text
                                        print("Found unit drop: +1 " .. unitName)
                                        hasSecretDrop = true
                                        table.insert(rewardsData, {
                                            name = unitName,
                                            quantity = "+1",
                                            currentAmount = nil,
                                            isUnit = true
                                        })
                                    elseif quantityObj then
                                        local quantityValue = "0"
                                        if quantityObj:IsA("TextLabel") or quantityObj:IsA("TextBox") then
                                            quantityValue = quantityObj.Text:gsub("^x", "+")
                                        elseif quantityObj:IsA("NumberValue") or quantityObj:IsA("IntValue") then
                                            quantityValue = "+" .. tostring(quantityObj.Value)
                                        end
                                        
                                        local currentAmount = 0
                                        
                                        pcall(function()
                                            if LocalPlayer.ItemsInventory[itemName] and LocalPlayer.ItemsInventory[itemName].Amount then
                                                currentAmount = LocalPlayer.ItemsInventory[itemName].Amount.Value
                                            end
                                        end)
                                        
                                        pcall(function()
                                            if LocalPlayer.Data:FindFirstChild(itemName) and LocalPlayer.Data[itemName]:IsA("NumberValue") then
                                                currentAmount = LocalPlayer.Data[itemName].Value
                                            end
                                        end)
                                        
                                        print("Found reward: " .. quantityValue .. " " .. itemName)
                                        
                                        table.insert(rewardsData, {
                                            name = itemName,
                                            quantity = quantityValue,
                                            currentAmount = currentAmount,
                                            isUnit = false
                                        })
                                    end
                                end
                            end
                        else
                            print("ScrollingFrame not found!")
                        end
                        
                        local unitsConnection
                        unitsConnection = LocalPlayer.UnitsInventory.ChildAdded:Connect(function(unitFrame)
                            if unitFrame:FindFirstChild("Unit") then
                                local unitName = unitFrame.Unit.Value
                                print("Found unit: +" .. unitName)
                                table.insert(unitsObtained, unitName)
                            end
                        end)
                        
                        task.wait(0.5)
                        unitsConnection:Disconnect()
                        
                        local description = ""
                        
                        if hasSecretDrop then
                            local pingText = "@everyone"
                            if Options.PingOnSecret.Value and Options.PingOnSecret.Value ~= "" then
                                pingText = "<@" .. Options.PingOnSecret.Value .. ">"
                            end
                            description = pingText .. "\n\n"
                        end
                        
                        description = description .. "**Anime Guardian**\n\n||" .. LocalPlayer.Name .. "||\n\n**Result:**\n"
                        description = description .. difficulty .. " (" .. stageName .. " - " .. actName .. ") " .. context .. "\n"
                        description = description .. "Time Cleared: " .. playTime .. "\n\n**Rewards:**\n"
                        
                        for _, reward in ipairs(rewardsData) do
                            if reward.isUnit then
                                description = description .. reward.quantity .. " " .. reward.name .. "\n"
                            elseif reward.name == "Gems" then
                                description = description .. reward.quantity .. " " .. reward.name .. "\n"
                            else
                                local formattedAmount = formatNumber(reward.currentAmount)
                                description = description .. reward.quantity .. " " .. reward.name .. " [" .. formattedAmount .. "]\n"
                            end
                        end
                        
                        for _, unitName in ipairs(unitsObtained) do
                            description = description .. "+" .. unitName .. "\n"
                        end
                        
                        if description == "" then
                            description = "No rewards detected"
                        end
                        
                        local embedColor = 16777215
                        if context:lower():find("fail") or context:lower():find("defeat") or context:lower():find("loss") then
                            embedColor = 16711680
                        end
                        
                        print("Sending webhook with description:\n" .. description)
                        
                        local embed = {
                            ["embeds"] = {{
                                ["description"] = description,
                                ["color"] = embedColor,
                                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                          }}
                        }
                        
                        local success, response = pcall(function()
                            local requestFunc = syn and syn.request or http_request or request
                            return requestFunc({
                                Url = Options.WebhookURL.Value,
                                Method = "POST",
                                Headers = {
                                    ["Content-Type"] = "application/json"
                                },
                                Body = HttpService:JSONEncode(embed)
                            })
                        end)
                        
                        if success then
                            print("Webhook sent successfully!")
                        else
                            print("Webhook failed:", response)
                        end
                    end
                elseif not endGUI or not endGUI.Enabled then
                    webhookSent = false
                end
            end
            
            if Fluent.Unloaded then break end
        end
    end)
end

do
    local proximityMap = {}
    
    local function scanProximityPrompts()
        proximityMap = {}
        local promptList = {}
        
        local npcsFolder = workspace:FindFirstChild("NPCS")
        if npcsFolder then
            for _, obj in pairs(npcsFolder:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local parentName = obj.Parent.Name
                    proximityMap[parentName] = obj
                    table.insert(promptList, parentName)
                end
            end
        end
        
        return promptList
    end
    
    local ProximityDropdown = Tabs.Misc:AddDropdown("SelectProximity", {
        Title = "Select Proximity",
        Description = "Choose NPC proximity prompt",
        Values = scanProximityPrompts(),
        Multi = false,
        Default = nil,
    })
    
    Tabs.Misc:AddButton({
        Title = "Fire ProximityPrompt",
        Description = "Activate the selected proximity prompt",
        Callback = function()
            local selected = Options.SelectProximity.Value
            if selected and proximityMap[selected] then
                pcall(function()
                    fireproximityprompt(proximityMap[selected])
                end)
                Fluent:Notify({
                    Title = "Proximity Fired",
                    Content = "Fired prompt for: " .. selected,
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Please select a proximity prompt first!",
                    Duration = 3
                })
            end
        end
    })
    
    Tabs.Misc:AddButton({
        Title = "Refresh Proximity List",
        Description = "Rescan for proximity prompts",
        Callback = function()
            local newList = scanProximityPrompts()
            ProximityDropdown:SetValues(newList)
            Fluent:Notify({
                Title = "Refreshed",
                Content = "Found " .. #newList .. " proximity prompts",
                Duration = 3
            })
        end
    })
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "Auto Challenge script loaded.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
