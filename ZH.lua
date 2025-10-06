
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ✅ FIXED WINDOW CREATION
local Window = Fluent:CreateWindow({
    Title = "Zombie Hunty [Wanz HUB]",
    SubTitle = "PRIVATE TESTING",
    TabWidth = 120,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "skull" }),
    Settings = Window:AddTab({ Title = "Main", Icon = "settings" })
}
local Options = Fluent.Options

local player = game.Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

-- Click attack (if your game uses left click)
local function autoClick()
	local cam = workspace.CurrentCamera
	local c = cam.ViewportSize / 2
	VIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 1)
	task.wait(0.05)
	VIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 1)
end

-- Teleport helper
local function teleportTo(model)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Find a basepart inside the zombie model
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
	if root then
		hrp.CFrame = root.CFrame + Vector3.new(0, 0, 3)
	end
end

-- Main auto kill loop
Options.AutoKill = Tabs.Main:AddToggle("AutoKill", {
	Title = "Auto Kill Zombies",
	Default = false,
	Callback = function(state)
		if state then
			task.spawn(function()
				while Options.AutoKill.Value do
					local zombiesFolder = workspace:FindFirstChild("Entities") and workspace.Entities:FindFirstChild("Zombie")
					if zombiesFolder then
						for _, zombie in ipairs(zombiesFolder:GetChildren()) do
							if tonumber(zombie.Name) then
								local hum = zombie:FindFirstChildOfClass("Humanoid")
								if hum and hum.Health > 0 then
									teleportTo(zombie)
									repeat
										VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                                        task.wait(0.05)
                                        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
										task.wait(0.1)
									until hum.Health <= 0 or not Options.AutoKill.Value
								end
							end
							if not Options.AutoKill.Value then break end
						end
					end
					task.wait(0.3)
				end
			end)
		end
	end
})

-- SM
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("W-Hub")
SaveManager:SetFolder("W-Hub/ZombieSlayer")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Auto Load
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
