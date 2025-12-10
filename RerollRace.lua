local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Race Reroll Script " .. Fluent.Version,
    SubTitle = "Auto Reroll Race",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "refresh-cw" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Variables
local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local autoRerollEnabled = false
local selectedRaces = {}

-- Function to get all available races
local function GetRaceList()
    local races = {}
    local success, result = pcall(function()
        local raceList = Player.PlayerGui.Sell.RaceUI.RaceMain.RaceList
        for _, child in pairs(raceList:GetChildren()) do
            if child:IsA("TextButton") then
                table.insert(races, child.Name)
            end
        end
    end)
    
    if not success then
        warn("Failed to get race list:", result)
        return {"Human", "Fishman", "Skypian", "Mink"}
    end
    
    return races
end

-- Function to get current race
local function GetCurrentRace()
    local success, race = pcall(function()
        local username = Player.Name
        local livingFolder = Workspace.Living:FindFirstChild(username)
        
        if not livingFolder then
            return "Human"
        end
        
        local raceFolder = livingFolder:FindFirstChild("RaceFolder")
        
        if not raceFolder then
            return "Human"
        end
        
        -- Get the first Model inside RaceFolder
        for _, child in pairs(raceFolder:GetChildren()) do
            if child:IsA("Model") then
                return child.Name
            end
        end
        
        return "Human"
    end)
    
    if success then
        return race
    else
        warn("Failed to get current race:", race)
        return "Unknown"
    end
end

-- Function to reroll race
local function RerollRace()
    local success, result = pcall(function()
        return ReplicatedStorage.Shared.Packages.Knit.Services.RaceService.RF.Reroll:InvokeServer()
    end)
    
    if not success then
        warn("Failed to reroll race:", result)
    end
    
    return success
end

-- Auto reroll loop
local function AutoRerollLoop()
    while autoRerollEnabled do
        wait(0.5) -- Small delay to prevent spam
        
        local currentRace = GetCurrentRace()
        
        -- Check if current race is in selected races
        local shouldReroll = true
        for raceName, isSelected in pairs(selectedRaces) do
            if isSelected and currentRace == raceName then
                shouldReroll = false
                Fluent:Notify({
                    Title = "Race Found!",
                    Content = "Got desired race: " .. currentRace,
                    Duration = 5
                })
                autoRerollEnabled = false
                Options.SpinRaceToggle:SetValue(false)
                break
            end
        end
        
        if shouldReroll then
            RerollRace()
            wait(1) -- Wait a bit after rerolling
        end
    end
end

-- UI Elements
do
    Tabs.Main:AddParagraph({
        Title = "Race Reroll Script",
        Content = "Select the races you want and enable auto spin.\nThe script will stop when it gets one of your selected races."
    })
    
    -- Function to get current spins
    local function GetCurrentSpins()
        local success, spins = pcall(function()
            return Player.PlayerGui.Sell.RaceUI.Reroll.Spins.Text
        end)
        
        if success then
            return spins
        else
            return "0"
        end
    end
    
    -- Display current race and spins
    local CurrentRaceLabel = Tabs.Main:AddParagraph({
        Title = "Current Race",
        Content = "Loading..."
    })
    
    -- Update current race and spins display every 2 seconds
    task.spawn(function()
        while true do
            wait(2)
            local currentRace = GetCurrentRace()
            local currentSpins = GetCurrentSpins()
            CurrentRaceLabel:SetDesc("Your current race is: " .. currentRace .. "\nCurrent Spin: " .. currentSpins)
            if Fluent.Unloaded then break end
        end
    end)
    
    -- Get race list
    local raceList = GetRaceList()
    
    -- Multi Dropdown for race selection
    local RaceDropdown = Tabs.Main:AddDropdown("SelectRace", {
        Title = "Select Race",
        Description = "Choose which races you want to get",
        Values = raceList,
        Multi = true,
        Default = {},
    })
    
    RaceDropdown:OnChanged(function(Value)
        selectedRaces = Value
        local selectedRaceNames = {}
        for raceName, isSelected in pairs(Value) do
            if isSelected then
                table.insert(selectedRaceNames, raceName)
            end
        end
        
        if #selectedRaceNames > 0 then
            print("Selected races:", table.concat(selectedRaceNames, ", "))
        else
            print("No races selected")
        end
    end)
    
    -- Toggle for auto spin
    local SpinToggle = Tabs.Main:AddToggle("SpinRaceToggle", {
        Title = "Spin Race", 
        Default = false 
    })
    
    SpinToggle:OnChanged(function()
        autoRerollEnabled = Options.SpinRaceToggle.Value
        
        if autoRerollEnabled then
            -- Check if any races are selected
            local hasSelection = false
            for _, isSelected in pairs(selectedRaces) do
                if isSelected then
                    hasSelection = true
                    break
                end
            end
            
            if not hasSelection then
                Fluent:Notify({
                    Title = "Warning",
                    Content = "Please select at least one race first!",
                    Duration = 5
                })
                Options.SpinRaceToggle:SetValue(false)
                return
            end
            
            Fluent:Notify({
                Title = "Auto Reroll Started",
                Content = "Starting race reroll...",
                Duration = 3
            })
            
            task.spawn(AutoRerollLoop)
        else
            Fluent:Notify({
                Title = "Auto Reroll Stopped",
                Content = "Race reroll has been stopped",
                Duration = 3
            })
        end
    end)
    
    -- Auto redeem codes button
    Tabs.Main:AddButton({
        Title = "Auto Redeem Codes",
        Description = "Redeem all working codes (100KLIKES, 200K!)",
        Callback = function()
            local codes = {"FREESPINS"}
            local successCount = 0
            local failCount = 0
            
            for _, code in pairs(codes) do
                wait(0.5) -- Small delay between redemptions
                
                local success, result = pcall(function()
                    local args = {
                        [1] = code
                    }
                    return ReplicatedStorage.Shared.Packages.Knit.Services.CodeService.RF.RedeemCode:InvokeServer(unpack(args))
                end)
                
                if success then
                    successCount = successCount + 1
                    print("Redeemed code:", code)
                else
                    failCount = failCount + 1
                    warn("Failed to redeem code:", code, result)
                end
            end
            
            Fluent:Notify({
                Title = "Code Redemption Complete",
                Content = "Success: " .. successCount .. " | Failed: " .. failCount,
                Duration = 5
            })
        end
    })
end

-- Addons
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("RaceRerollScript")
SaveManager:SetFolder("RaceRerollScript/config")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Race Reroll Script",
    Content = "Script loaded successfully!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
