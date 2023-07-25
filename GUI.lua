-- // Dependencies
local LinoriaRepo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"

local metadata = loadstring(game:HttpGet("https://raw.githubusercontent.com/wally-rblx/funky-friday-autoplay/main/metadata.lua"))()()

local Library = loadstring(game:HttpGet(LinoriaRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LinoriaRepo .. "addons/ThemeManager.lua"))()

local Aiming = getgenv().Aiming
if (not Aiming) then
    Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/RedGamer12/Fixing/main/Load.lua"))()()
end
repeat wait() until Aiming.Loaded

local AimingSettings = Aiming.Settings
local AimingUtilities = Aiming.Utilities

-- // Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- // Initialising the Library
local AutoShow = AimingSettings.GUIAutoShow
if (AutoShow == nil) then
    AutoShow = true
end

local SaveManager = {} do
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object) 
                return { type = 'Toggle', idx = idx, value = object.Value } 
            end,
            Load = function(idx, data)
                if Toggles[idx] then 
                    Toggles[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = 'Slider', idx = idx, value = tostring(object.Value) }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex() }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValueRGB(Color3.fromHex(data.value))
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value }
            end,
            Load = function(idx, data)
                if Options[idx] then 
                    Options[idx]:SetValue({ data.key, data.mode })
                end
            end,
        }
    }

    function SaveManager:Save(name)
        local fullPath = 'PVP/configs/' .. name .. '.json'

        local data = {
            version = 2,
            objects = {}
        }

        for idx, toggle in next, Toggles do
            if self.Ignore[idx] then continue end
            table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
        end

        for idx, option in next, Options do
            if not self.Parser[option.Type] then continue end
            if self.Ignore[idx] then continue end

            table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
        end 

        local success, encoded = pcall(httpService.JSONEncode, httpService, data)
        if not success then
            return false, 'failed to encode data'
        end

        writefile(fullPath, encoded)
        return true
    end

    function SaveManager:Load(name)
        local file = 'PVP/configs/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end

        local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
        if not success then return false, 'decode error' end
        if decoded.version ~= 2 then return false, 'invalid version' end

        for _, option in next, decoded.objects do
            if self.Parser[option.type] then
                self.Parser[option.type].Load(option.idx, option)
            end
        end

        return true
    end

    function SaveManager.Refresh()
        local list = listfiles('PVP/configs')

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                -- i hate this but it has to be done ...

                local pos = file:find('.json', 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end
        
        Options.ConfigList.Values = out;
        Options.ConfigList:SetValues()
        Options.ConfigList:Display()

        return out
    end

    function SaveManager:Delete(name)
        local file = 'PVP/configs/' .. name .. '.json'
        if not isfile(file) then return false, string.format('Config %q does not exist', name) end

        local succ, err = pcall(delfile, file)
        if not succ then
            return false, string.format('error occured during file deletion: %s', err)
        end

        return true
    end

    function SaveManager:SetIgnoreIndexes(list)
        for i = 1, #list do 
            table.insert(self.Ignore, list[i])
        end
    end

    function SaveManager.Check()
        local list = listfiles('PVP/configs')

        for _, file in next, list do
            if isfolder(file) then continue end

            local data = readfile(file)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success and type(decoded) == 'table' and decoded.version ~= 2 then
                pcall(delfile, file)
            end
        end
    end
end

local Window = Library:CreateWindow({
    Title = string.format("PVP [Blox Fruit] - version %s | updated: %s', metadata.version, metadata.updated"),
    
    Center = true,
    AutoShow = AutoShow
})

-- //
local AimingTab = Window:AddTab("Aiming")
do
    -- // Get some parts
    local function GetCharacterParts()
        -- // Vars
        local Parts = {}

        -- // Loop through Players
        for _, Player in ipairs(Players:GetPlayers()) do
            -- // Attempt to get their character
            local Character = AimingUtilities.Character(Player)
            if (not Character) then
                continue
            end

            -- //
            local CharacterParts = AimingUtilities.GetBodyParts(Character)
            if (#CharacterParts > 0) then
                Parts = CharacterParts
                break
            end
        end

        -- // Return
        table.insert(Parts, "All")
        return Parts
    end

    -- //
    local UniversalTabbox = AimingTab:AddLeftTabbox("Universal")
    local UniversalTab = UniversalTabbox:AddTab("Universal")
    UniversalTab:AddToggle("AimingEnabled", {
        Text = "Enabled",
        Default = AimingSettings.Enabled,
        Tooltip = "Toggle the entirety of Aiming on and off",
        Callback = function(Value)
            AimingSettings.Enabled = Value
        end
    })
    UniversalTab:AddSlider("AimingHitChance", {
        Text = "Hit Chance%",
        Tooltip = "The likelyhood of Aiming 'working'",
        Default = AimingSettings.HitChance,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            AimingSettings.HitChance = Value
        end
    })
    UniversalTab:AddSlider("AimingMaxDistance", {
        Text = "Max Distance",
        Tooltip = "The max amount of studs a target can be away",
        Default = AimingSettings.MaxDistance,
        Min = 0,
        Max = 3000,
        Rounding = 1,
        Callback = function(Value)
            AimingSettings.MaxDistance = Value
        end
    })

    UniversalTab:AddToggle("AimingLockModeEnabled", {
        Text = "Lock Mode",
        Default = AimingSettings.LockMode.Enabled,
        Tooltip = "Your target will remain locked untl the keybind is pressed",
        Callback = function(Value)
            AimingSettings.LockMode.Enabled = Value
        end
    })
    local UnlockBind = AimingSettings.LockMode.UnlockBind
    UniversalTab:AddLabel("Unlock Bind"):AddKeyPicker("AimingLockModeUnlock", {
        Text = "Unlock Bind",
        Default = UnlockBind.EnumType == Enum.KeyCode and UnlockBind.Name or UnlockBind,
        ChangedCallback = function(NewKey)
            AimingSettings.LockMode.UnlockBind = NewKey
        end
    })

    local UniversalChecksBox = UniversalTabbox:AddTab("Checks")
    UniversalChecksBox:AddToggle("AimingVisibleCheck", {
        Text = "Visibility Check",
        Default = AimingSettings.VisibleCheck,
        Tooltip = "Makes sure targets are within LoS",
        Callback = function(Value)
            AimingSettings.VisibleCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingTeamCheck", {
        Text = "Team Check",
        Default = AimingSettings.TeamCheck,
        Tooltip = "Make sure targets are not on the same team",
        Callback = function(Value)
            AimingSettings.TeamCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingPlayerCheck", {
        Text = "Player Check",
        Default = AimingSettings.PlayerCheck,
        Tooltip = "Check if a player is ignored",
        Callback = function(Value)
            AimingSettings.PlayerCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingFriendCheck", {
        Text = "Friend Check",
        Default = AimingSettings.FriendCheck,
        Tooltip = "Makes sure targets are not friends",
        Callback = function(Value)
            AimingSettings.FriendCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingForcefieldCheck", {
        Text = "Forcefield Check",
        Default = AimingSettings.ForcefieldCheck,
        Tooltip = "Makes sure targets do not have a forcefield",
        Callback = function(Value)
            AimingSettings.ForcefieldCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingHealthCheck", {
        Text = "Health Check",
        Default = AimingSettings.HealthCheck,
        Tooltip = "Makes sure targets are alive",
        Callback = function(Value)
            AimingSettings.HealthCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingInvisibleCheck", {
        Text = "Invisible Check",
        Default = AimingSettings.InvisibleCheck,
        Tooltip = "Makes sure targets are visible to the eye",
        Callback = function(Value)
            AimingSettings.InvisibleCheck = Value
        end
    })
    UniversalChecksBox:AddToggle("AimingIgnoredCheck", {
        Text = "Ignored Check",
        Default = AimingSettings.IgnoredCheck,
        Tooltip = "Toggle all ignored checks",
        Callback = function(Value)
            AimingSettings.IgnoredCheck = Value
        end
    })

    -- //
    local TargetPartBox = AimingTab:AddRightTabbox()
    local TargetPartSelected = TargetPartBox:AddTab("Selected")
    local TargetPartSelection = TargetPartBox:AddTab("Selection")

    -- //
    local TargetPartA = TargetPartSelected:AddDropdown("AimingTargetPartSelected", {
        Values = AimingSettings.TargetPart,
        Default = 1,
        Multi = false,
        Text = "Select Target Part",
        Tooltip = "These are the currently selected parts"
    })
    TargetPartSelected:AddButton("Add", function()
        -- // Vars
        local TargetPart = TargetPartA.Value

        -- // Make sure does not exist already
        local TargetPartI = table.find(AimingSettings.TargetPart, TargetPart)
        if (TargetPartI) then
            return Library:Notify("Already added", 3)
        end

        -- // Add
        table.insert(AimingSettings.TargetPart, TargetPartI)

        -- // Update dropdown
        TargetPartA.Values = AimingSettings.TargetPart
        TargetPartA:SetValues()
    end):AddButton("Remove", function()
        -- // Vars
        local TargetPart = TargetPartA.Value

        -- // Make sure does exist already
        local TargetPartI = table.find(AimingSettings.TargetPart, TargetPart)
        if (not TargetPartI) then
            return Library:Notify("Not already added", 3)
        end

        -- // Add
        table.remove(AimingSettings.TargetPart, TargetPartI)

        -- // Update dropdown
        TargetPartA.Values = AimingSettings.TargetPart
        TargetPartA:SetValues()
    end)

    -- //
    local CharacterParts = AimingUtilities.ArrayToString(GetCharacterParts())
    local TargetPartB = TargetPartSelection:AddDropdown("AimingTargetPartSelection", {
        Values = CharacterParts,
        Default = 1,
        Multi = false,
        Text = "Select Target Part",
        Tooltip = "These are the possible target parts"
    })
    TargetPartSelection:AddButton("Add", function()
        -- // Vars
        local TargetPart = TargetPartB.Value

        -- // Make sure does not exist already
        local TargetPartI = table.find(AimingSettings.TargetPart, TargetPart)
        if (TargetPartI) then
            return Library:Notify("Already added", 3)
        end

        -- // Add
        table.insert(AimingSettings.TargetPart, TargetPart)

        -- // Update dropdown
        TargetPartA.Values = AimingSettings.TargetPart
        TargetPartA:SetValues()
    end):AddButton("Remove", function()
        -- // Vars
        local TargetPart = TargetPartB.Value

        -- // Make sure does exist already
        local TargetPartI = table.find(AimingSettings.TargetPart, TargetPart)
        if (not TargetPartI) then
            return Library:Notify("Not already added", 3)
        end

        -- // Add
        table.remove(AimingSettings.TargetPart, TargetPartI)

        -- // Update dropdown
        TargetPartA.Values = AimingSettings.TargetPart
        TargetPartA:SetValues()
    end)

    -- //
    local DrawingManagementBox = AimingTab:AddLeftTabbox()
    local FOVManagement = DrawingManagementBox:AddTab("FOV")
    local DeadzoneFOVManagement = DrawingManagementBox:AddTab("Deadzone")
    local TracerManagement = DrawingManagementBox:AddTab("Tracer")

    -- //
    local AimingSettingsFOVSettings = AimingSettings.FOVSettings
    FOVManagement:AddToggle("AimingFOVEnabled", {
        Text = "Enabled",
        Default = AimingSettingsFOVSettings.Enabled,
        Tooltip = "Toggle the FOV circle's functionality",
        Callback = function(Value)
            AimingSettingsFOVSettings.Enabled = Value
        end
    })
    FOVManagement:AddToggle("AimingFOVFollowSelected", {
        Text = "Follow Selected",
        Default = AimingSettingsFOVSettings.FollowSelected,
        Tooltip = "Make the FOV circle follow the current target",
        Callback = function(Value)
            AimingSettingsFOVSettings.FollowSelected = Value
        end
    })
    FOVManagement:AddToggle("AimingFOVVisible", {
        Text = "Visible",
        Default = AimingSettingsFOVSettings.Visible,
        Tooltip = "Toggle the FOV circle's visibility",
        Callback = function(Value)
            AimingSettingsFOVSettings.Visible = Value
        end
    }):AddColorPicker("AimingFOVColour", {
        Text = "Colour",
        Default = AimingSettingsFOVSettings.Colour,
        Tooltip = "The colour of the FOV circle",
        Callback = function(Value)
            AimingSettingsFOVSettings.Colour = Value
        end
    })
    FOVManagement:AddSlider("AimingFOVScale", {
        Text = "Scale",
        Tooltip = "The size of the FOV circle",
        Default = AimingSettingsFOVSettings.Scale,
        Min = 0,
        Max = 360,
        Rounding = 1,
        Callback = function(Value)
            AimingSettingsFOVSettings.Scale = Value
        end
    })
    FOVManagement:AddDropdown("AimingFOVType", {
        Text = "Type",
        Tooltip = "Whether the FOV scales with distance (disables scale, if dynamic)",
        Default = AimingSettingsFOVSettings.Type,
        Multi = false,
        Values = {"Static", "Dynamic"},
        Callback = function(Value)
            AimingSettingsFOVSettings.Type = Value
        end
    })
    FOVManagement:AddSlider("AimingFOVDConstant", {
        Text = "Dynamic Constant",
        Tooltip = "The constant for the dynamic FOV circle",
        Default = AimingSettingsFOVSettings.DynamicFOVConstant,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            AimingSettingsFOVSettings.DynamicFOVConstant = Value
        end
    })

    -- //
    local AimingSettingsDeadzoneFOVSettings = AimingSettings.DeadzoneFOVSettings
    DeadzoneFOVManagement:AddToggle("AimingDFOVEnabled", {
        Text = "Enabled",
        Default = AimingSettingsDeadzoneFOVSettings.Enabled,
        Tooltip = "Toggle the deadzone circle's functionality",
        Callback = function(Value)
            AimingSettingsDeadzoneFOVSettings.Enabled = Value
        end
    })
    DeadzoneFOVManagement:AddToggle("AimingDFOVVisible", {
        Text = "Visible",
        Default = AimingSettingsDeadzoneFOVSettings.Visible,
        Tooltip = "Toggle the deadzone circle's visibility",
        Callback = function(Value)
            AimingSettingsDeadzoneFOVSettings.Visible = Value
        end
    }):AddColorPicker("AimingDFOVColour", {
        Text = "Colour",
        Default = AimingSettingsDeadzoneFOVSettings.Colour,
        Tooltip = "The colour of the deadzone circle",
        Callback = function(Value)
            AimingSettingsDeadzoneFOVSettings.Colour = Value
        end
    })
    DeadzoneFOVManagement:AddSlider("AimingDFOVScale", {
        Text = "Scale",
        Tooltip = "The size of the deadzone circle",
        Default = AimingSettingsDeadzoneFOVSettings.Scale,
        Min = 0,
        Max = 50,
        Rounding = 1,
        Callback = function(Value)
            AimingSettingsDeadzoneFOVSettings.Scale = Value
        end
    })

    -- //
    local AimingSettingsTracerSettings = AimingSettings.TracerSettings
    TracerManagement:AddToggle("AimingTracerEnabled", {
        Text = "Enabled",
        Default = AimingSettingsTracerSettings.Enabled,
        Tooltip = "Toggle the tracer on and off",
        Callback = function(Value)
            AimingSettingsTracerSettings.Enabled = Value
        end
    }):AddColorPicker("AimingTracerColour", {
        Text = "Colour",
        Default = AimingSettingsTracerSettings.Colour,
        Tooltip = "The colour of the tracer",
        Callback = function(Value)
            AimingSettingsTracerSettings.Colour = Value
        end
    })

    -- //
    local IgnoredManagementBox = AimingTab:AddRightTabbox("Ignored Management")
    local AimingSettingsIgnored = AimingSettings.Ignored
    local PlayerManagement = IgnoredManagementBox:AddTab("Player")
    local TeamManagement = IgnoredManagementBox:AddTab("Team")

    -- //
    local PlayerDropdown = PlayerManagement:AddDropdown("AimingIgnoredPlayerDropdown", {
        Default = 2,
        Multi = false,
        Text = "Select Player",
        Tooltip = "These are the current players",
        SpecialType = "Player"
    })
    PlayerManagement:AddToggle("AimingIgnoreLocalTeam", {
        Text = "Ignore Friends",
        Default = AimingSettingsIgnored.IgnoreFriends,
        Tooltip = "Ignores your Roblox friends",
        Callback = function(Value)
            AimingSettingsIgnored.IgnoreFriends = Value
        end
    })
    PlayerManagement:AddButton("Ignore", function()
        -- // Vars
        local Player = Players:FindFirstChild(PlayerDropdown.Value)

        -- // Make sure we have the player
        if (not Player) then
            return Library:Notify("Player does not exist", 3)
        end

        -- // Make sure the player is not already ignored
        local PlayerI = table.find(AimingSettingsIgnored.Players, Player)
        if (PlayerI) then
            return Library:Notify("Player already ignored", 3)
        end

        -- //
        table.insert(AimingSettingsIgnored.Players, Player)
    end):AddButton("Unignore", function()
        -- // Vars
        local Player = Players:FindFirstChild(PlayerDropdown.Value)

        -- // Make sure we have the player
        if (not Player) then
            return Library:Notify("Player does not exist", 3)
        end

        -- // Make sure the player is not already ignored
        local PlayerI = table.find(AimingSettingsIgnored.Players, Player)
        if (not PlayerI) then
            return Library:Notify("Player not ignored", 3)
        end

        -- //
        table.remove(AimingSettingsIgnored.Players, PlayerI)
    end)

    -- //
    local TeamDropdown = TeamManagement:AddDropdown("AimingIgnoredTeamsDropdown", {
        Default = 1,
        Multi = false,
        Text = "Select Team",
        Tooltip = "These are the current teams",
        SpecialType = "Team"
    })
    TeamManagement:AddToggle("AimingIgnoreLocalTeam", {
        Text = "Ignore Local Team",
        Default = AimingSettingsIgnored.IgnoreLocalTeam,
        Tooltip = "Ignores the local team",
        Callback = function(Value)
            AimingSettingsIgnored.IgnoreLocalTeam = Value
        end
    })
    TeamManagement:AddButton("Ignore", function()
        -- // Vars
        local Team = Teams:FindFirstChild(TeamDropdown.Value)

        -- // Make sure we have the player
        if (not Team) then
            return Library:Notify("Team does not exist", 3)
        end

        -- // Make sure the player is not already ignored
        local TeamI = table.find(AimingSettingsIgnored.Teams, Team)
        if (TeamI) then
            return Library:Notify("Team already ignored", 3)
        end

        -- //
        table.insert(AimingSettingsIgnored.Teams, Team)
    end):AddButton("Unignore", function()
        -- // Vars
        local Team = Teams:FindFirstChild(TeamDropdown.Value)

        -- // Make sure we have the player
        if (not Team) then
            return Library:Notify("Team does not exist", 3)
        end

        -- // Make sure the player is not already ignored
        local TeamI = table.find(AimingSettingsIgnored.Teams, Team)
        if (not TeamI) then
            return Library:Notify("Team not ignored", 3)
        end

        -- //
        table.remove(AimingSettingsIgnored.Teams, TeamI)
    end)
end

-- //
local UISettingsTab = Window:AddTab("Library Settings")
UISettingsTab:SetLayoutOrder(69420) -- // so it sticks to the end
do
    local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu Settings")

    MenuGroup:AddButton("Unload", function()
        Library:Unload()
    end)

    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        Default = "End",
        NoUI = true,
        Text = "Menu keybind"
    })

    Library.ToggleKeybind = Options.MenuKeybind
end

ThemeManager:SetLibrary(Library)

ThemeManager:ApplyToTab(UISettingsTab)

-- // Misc
Library:OnUnload(function()
    Library.Unloaded = true
end)

local Configs = UISettingsTab:AddRightGroupbox('Configs')
local Credits = UISettingsTab:AddRightGroupbox('Credits')
    local function addRichText(label)
        label.TextLabel.RichText = true
    end

    addRichText(Credits:AddLabel('<font color="#3da5ff">wally</font> - script'))
    addRichText(Credits:AddLabel('<font color="#de6cff">Sezei</font> - contributor'))
    Credits:AddLabel('Inori - ui library')
    Credits:AddLabel('Jan - old ui library')


local Misc = UISettingsTab:AddRightGroupbox('Miscellaneous')
    Misc:AddLabel(metadata.message or 'no message found!', true)

    Misc:AddDivider()
    Misc:AddButton('Unload script', function() pcall(shared._unload) end)
    Misc:AddButton('Copy discord', function()
        if pcall(setclipboard, "https://wally.cool/discord") then
            Library:Notify('Successfully copied discord link to your clipboard!', 5)
        end
    end)

    Misc:AddLabel('Menu toggle'):AddKeyPicker('MenuToggle', { Default = 'Delete', NoUI = true })

    Library.ToggleKeybind = Options.MenuToggle

if type(readfile) == 'function' and type(writefile) == 'function' and type(makefolder) == 'function' and type(isfolder) == 'function' then
    makefolder('PVP')
    makefolder('PVP\\configs')

    Configs:AddDropdown('ConfigList', { Text = 'Config list', Values = {}, AllowNull = true })
    Configs:AddInput('ConfigName',    { Text = 'Config name' })

    Configs:AddDivider()

    Configs:AddButton('Save config', function()
        local name = Options.ConfigName.Value;
        if name:gsub(' ', '') == '' then
            return Library:Notify('Invalid config name.', 3)
        end

        local success, err = SaveManager:Save(name)
        if not success then
            return Library:Notify(tostring(err), 5)
        end

        Library:Notify(string.format('Saved config %q', name), 5)
        task.defer(SaveManager.Refresh)
    end)

    Configs:AddButton('Load', function()
        local name = Options.ConfigList.Value
        local success, err = SaveManager:Load(name)
        if not success then
            return Library:Notify(tostring(err), 5)
        end

        Library:Notify(string.format('Loaded config %q', name), 5)
    end):AddButton('Delete', function()
        local name = Options.ConfigList.Value
        if name:gsub(' ', '') == '' then
            return Library:Notify('Invalid config name.', 3)
        end

        local success, err = SaveManager:Delete(name)
        if not success then
            return Library:Notify(tostring(err), 5)
        end

        Library:Notify(string.format('Deleted config %q', name), 5)

        task.spawn(Options.ConfigList.SetValue, Options.ConfigList, nil)
        task.defer(SaveManager.Refresh)
    end)

    Configs:AddButton('Refresh list', SaveManager.Refresh)

    task.defer(SaveManager.Refresh)
    task.defer(SaveManager.Check)
else
    Configs:AddLabel('Your exploit is missing file functions so you are unable to use configs.', true)
    --Library:Notify('Failed to create configs tab due to your exploit missing certain file functions.', 2)
end

-- // Return
Aiming.GUI = {Library, AimingTab, Window, UISettingsTab, ThemeManager, SaveManager}
return Library, AimingTab, Window, UISettingsTab, ThemeManager, SaveManager
