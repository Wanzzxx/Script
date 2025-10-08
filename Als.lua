-- if not table.find({12886143095, 18583778121}, game.PlaceId) then return end

-- Load MacLib
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

-- Create Compact Window
local Window = MacLib:Window({
	Title = "DynaX HUB",
	Subtitle = "Anime Last Stand",
	Size = UDim2.fromOffset(620, 420),
	DragStyle = 1,
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = true,
})

local globalSettings = {
	UIBlurToggle = Window:GlobalSetting({
		Name = "UI Blur",
		Default = Window:GetAcrylicBlurState(),
		Callback = function(bool)
			Window:SetAcrylicBlurState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
				Lifetime = 5
			})
		end,
	}),
	NotificationToggler = Window:GlobalSetting({
		Name = "Notifications",
		Default = Window:GetNotificationsState(),
		Callback = function(bool)
			Window:SetNotificationsState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Enabled" or "Disabled") .. " Notifications",
				Lifetime = 5
			})
		end,
	}),
	ShowUserInfo = Window:GlobalSetting({
		Name = "Show User Info",
		Default = Window:GetUserInfoState(),
		Callback = function(bool)
			Window:SetUserInfoState(bool)
			Window:Notify({
				Title = Window.Settings.Title,
				Description = (bool and "Showing" or "Redacted") .. " User Info",
				Lifetime = 5
			})
		end,
	})
}

------------------------------------------------------------
-- Tabs + Sections
------------------------------------------------------------
local tabGroups = {
	MainGroup = Window:TabGroup()
}

local tabs = {
	Main = tabGroups.MainGroup:Tab({ Name = "Main", Image = "rbxassetid://18821914323" }),
	Joiner = tabGroups.MainGroup:Tab({ Name = "Joiner", Image = "rbxassetid://18821914323" }),
	Macro = tabGroups.MainGroup:Tab({ Name = "Macro", Image = "rbxassetid://18821914323" }),
	Settings = tabGroups.MainGroup:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

local sections = {
	MainLeft = tabs.Main:Section({ Side = "Left" }),
	MainRight = tabs.Main:Section({ Side = "Right" }),
	JoinerLeft = tabs.Joiner:Section({ Side = "Left" }),
	JoinerRight = tabs.Joiner:Section({ Side = "Right" }),
	MacroLeft = tabs.Macro:Section({ Side = "Left" }),
	MacroRight = tabs.Macro:Section({ Side = "Right" }),
}

------------------------------------------------------------
-- Services
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

------------------------------------------------------------
-- Macro State
------------------------------------------------------------
local recording = false
local playing = false
local macroData = {}

------------------------------------------------------------
-- Hook (with position-based anti-duplicate)
------------------------------------------------------------
local hookSuccess = false
do
	local mt = getrawmetatable(game)
	local old = mt.__namecall
	setreadonly(mt, false)

	local lastRecord = { time = 0, name = "", argHash = "" }

	local function hashArgs(args)
		local str = ""
		for i, v in ipairs(args) do
			if typeof(v) == "Vector3" then
				str ..= string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
			elseif typeof(v) == "CFrame" then
				local p = v.Position
				str ..= string.format("CF(%.2f,%.2f,%.2f)", p.X, p.Y, p.Z)
			elseif typeof(v) == "table" then
				str ..= hashArgs(v)
			else
				str ..= tostring(v)
			end
		end
		return string.sub(str, 1, 150)
	end

	mt.__namecall = function(self, ...)
		local method = getnamecallmethod()
		local args = { ... }

		local result = old(self, ...)

		if recording and (method == "FireServer" or method == "InvokeServer") then
			local n = tostring(self.Name or "")
			local lower = n:lower()
			local valid = false

			for _, k in ipairs({ "place", "tower", "deploy", "spawn", "build", "unit" }) do
				if string.find(lower, k, 1, true) then
					valid = true
					break
				end
			end

			if valid then
				task.spawn(function()
					local now = tick()
					local argHash = hashArgs(args)

					if not (n == lastRecord.name and argHash == lastRecord.argHash and (now - lastRecord.time) < 0.25) then
						lastRecord = { time = now, name = n, argHash = argHash }

						table.insert(macroData, {
							Type = "Remote",
							RemoteName = n,
							Args = args,
							Time = now,
							IsInvoke = (method == "InvokeServer"),
							Path = (self.GetFullName and self:GetFullName()) or "unknown"
						})
					end
				end)
			end
		end

		return result
	end

	setreadonly(mt, true)
	hookSuccess = true
end

------------------------------------------------------------
-- Helper: Find Remote
------------------------------------------------------------
local function findRemoteByName(name)
	if not name then return nil end
	name = name:lower()
	for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
		if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower() == name then
			return v
		end
	end
	return nil
end

------------------------------------------------------------
-- UI Controls
------------------------------------------------------------
sections.MainLeft:Toggle({
	Name = "Record Macro",
	Default = false,
	Callback = function(state)
		recording = state
		if state then
			macroData = {}
			Window:Notify({ Title = "Macro Recorder", Description = "Recording started...", Lifetime = 3 })
		else
			Window:Notify({ Title = "Macro Recorder", Description = "Recording stopped. " .. #macroData .. " actions saved.", Lifetime = 4 })
		end
	end
}, "RecordMacro")

sections.MainLeft:Toggle({
	Name = "Play Macro",
	Default = false,
	Callback = function(state)
		if state then
			if #macroData == 0 then
				Window:Notify({ Title = "Macro Recorder", Description = "No recorded actions!", Lifetime = 3 })
				return
			end
			playing = true
			Window:Notify({ Title = "Macro Recorder", Description = "Playing macro...", Lifetime = 3 })

			local startTime = macroData[1].Time
			for _, action in ipairs(macroData) do
				local delayTime = math.max(0, action.Time - startTime)
				task.delay(delayTime, function()
					if not playing then return end
					local remote = findRemoteByName(action.RemoteName)
					if remote then
						pcall(function()
							if action.IsInvoke and remote:IsA("RemoteFunction") then
								remote:InvokeServer(unpack(action.Args))
							else
								remote:FireServer(unpack(action.Args))
							end
						end)
					end
				end)
			end

			task.delay((macroData[#macroData].Time - startTime) + 0.5, function()
				playing = false
				Window:Notify({ Title = "Macro Recorder", Description = "Playback finished.", Lifetime = 3 })
			end)
		else
			playing = false
			Window:Notify({ Title = "Macro Recorder", Description = "Playback stopped.", Lifetime = 2 })
		end
	end
}, "PlayMacro")

sections.MainRight:Button({
	Name = "Clear Macro",
	Callback = function()
		macroData = {}
		Window:Notify({ Title = "Macro Recorder", Description = "Macro cleared.", Lifetime = 2 })
	end
})

sections.MainRight:Button({
	Name = "Save Macro",
	Callback = function()
		if not writefile then
			Window:Notify({ Title = "Macro Recorder", Description = "writefile not supported.", Lifetime = 3 })
			return
		end
		local data = HttpService:JSONEncode(macroData)
		writefile("macro_recording.json", data)
		Window:Notify({ Title = "Macro Recorder", Description = "Saved to macro_recording.json", Lifetime = 3 })
	end
})

sections.MainRight:Button({
	Name = "Load Macro",
	Callback = function()
		if not readfile then
			Window:Notify({ Title = "Macro Recorder", Description = "readfile not supported.", Lifetime = 3 })
			return
		end
		local ok, raw = pcall(readfile, "macro_recording.json")
		if ok and raw then
			macroData = HttpService:JSONDecode(raw)
			Window:Notify({ Title = "Macro Recorder", Description = "Loaded " .. #macroData .. " actions.", Lifetime = 3 })
		else
			Window:Notify({ Title = "Macro Recorder", Description = "Failed to read file.", Lifetime = 3 })
		end
	end
})

sections.MainRight:Button({
	Name = "Copy Macro to Clipboard",
	Callback = function()
		if setclipboard then
			setclipboard(HttpService:JSONEncode(macroData))
			Window:Notify({ Title = "Macro Recorder", Description = "Copied macro to clipboard.", Lifetime = 3 })
		else
			Window:Notify({ Title = "Macro Recorder", Description = "setclipboard not supported.", Lifetime = 3 })
		end
	end
})

sections.MainRight:Button({
	Name = "Import from Clipboard",
	Callback = function()
		if getclipboard then
			local raw = getclipboard()
			macroData = HttpService:JSONDecode(raw)
			Window:Notify({ Title = "Macro Recorder", Description = "Imported " .. #macroData .. " actions.", Lifetime = 3 })
		else
			Window:Notify({ Title = "Macro Recorder", Description = "getclipboard not supported.", Lifetime = 3 })
		end
	end
})

------------------------------------------------------------
-- Load & Finish
------------------------------------------------------------
MacLib:SetFolder("W-Hub/MacroRecorder")
tabs.Settings:InsertConfigSection("Left")

Window:Notify({
	Title = "Macro Recorder",
	Description = hookSuccess and "Loaded successfully with position anti-duplicate." or "Hook failed; recording may not work.",
	Lifetime = 5
})

tabs.Main:Select()
MacLib:LoadAutoLoadConfig()
