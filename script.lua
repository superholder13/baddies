getgenv().overware = {
	["Auto Swing"] = true,
	["Auto Mop"] =  true,
    ["Loading Sound ID"] = 6276581181,
    ["Auto Sprint"] = true,
    ["Low GFX"] = true,
    ["Show Player Hitboxes"] = {
        ["Enabled"] = true,
        ["Transparency"] = 0.75
    },
    ["Hitbox Extension"] = {
        ["Enabled"] = true,
        ["Size"] = {
			["X"] = 1.25, -- sides
			["Y"] = 3, -- up/down
			["Z"] = 5.5 -- forward
		}
	},
    ["Negate Hitstun"] = true -- wip
}

local replicatedStorage = game:GetService("ReplicatedStorage")
local message = require(replicatedStorage.Modules.Message)

if not getgenv().overware_loaded then
    message.Message("[OVERWARE]: LOADING...", nil, 5)
else
    message.Message("[OVERWARE]: SCRIPT ALREADY LOADED.", nil, 5)
    return
end
getgenv().overware_loaded = 1

if not game:IsLoaded() then game.Loaded:Wait() end

local BaddiesPlaceID = 11158043705
if game.PlaceId ~= BaddiesPlaceID then
    return warn("this is NOT baddies")
end

function overware.get(selection)
    if not string.find(selection, "/") then
        return getgenv().overware[selection]
    end
    local segments = string.split(selection, "/")
    local value = getgenv().overware
    for _, segment in ipairs(segments) do
        value = value and value[segment]
    end
    return value
end
local players = game:GetService("Players")
local player = players.LocalPlayer
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")
local soundFolder = replicatedStorage.Sounds
local isMouseDown = nil
local currentTool
local punchEvent = replicatedStorage:FindFirstChild("PUNCHEVENT")
local initSound = soundFolder:FindFirstChild("overware")

local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

local function lowGfx()
	print(overware.get("Low GFX"))
    if not overware.get("Low GFX") then return end
    local function setToSmoothPlastic(part)
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
			if part.Material == Enum.Material.Glass then
				part.Transparency = 0.66
			end
        end
    end

    local function applySmoothPlasticToMap()
        for _, descendant in ipairs(workspace:GetDescendants()) do
            setToSmoothPlastic(descendant)
        end
    end
    workspace.DescendantAdded:Connect(setToSmoothPlastic)
    applySmoothPlasticToMap()
end

local function showLpHitboxes()
    local directoryEnabled = overware.get("Show Player Hitboxes/Enabled")
    if not directoryEnabled then return end
    local transparency = overware.get("Show Player Hitboxes/Transparency")
    local hitboxEnabled = overware.get("Hitbox Extension/Enabled")
	local char = player.Character or player.CharacterAdded:Wait()
	local extensionSize = overware.get("Hitbox Extension/Size")
	local hrp = char:WaitForChild("HumanoidRootPart")
    if transparency > 1 or transparency < 0 then
        transparency = 0.8
    end
	local mult = hitboxMultiplier
    workspace.Debris.ChildAdded:Connect(function(hitbox)
        if hitbox.Name == "Hitbox" then
            local weldConstraint = hitbox:FindFirstChild("WeldConstraint")
            if weldConstraint and weldConstraint.Part0 == player.Character:FindFirstChild("HumanoidRootPart") then
                if directoryEnabled then
					hitbox.Transparency = transparency
				end
				if hitboxEnabled then
                    hitbox.Size += Vector3.new(extensionSize.X, extensionSize.Y, extensionSize.Z)
					-- hitbox.CFrame = hitbox.CFrame:ToObjectSpace(CFrame.new(hitbox.CFrame + extensionSize.X, hitbox.CFrame + extensionSize.Y, hitbox.CFrame + extensionSize.Z)*5)
                end
            end
        end
    end)
end

local function setSprint()
    if not overware.get("Auto Sprint") then return end
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    task.spawn(function()
        runService.Heartbeat:Connect(function()
            if not hum then return end
            if hum:GetAttribute("NoMultipliers") == 16 then
                hum:SetAttribute("NoMultipliers", 22)
                hum.WalkSpeed = 22
            end
        end)
    end)
    local fakeTag = Instance.new("IntValue")
    fakeTag.Parent = char
    fakeTag.Name = "running"
end

if not initSound then
    local s = Instance.new("Sound")
    s.Parent = soundFolder
    s.SoundId = "rbxassetid://" .. tostring(overware.get("Loading Sound ID"))
    initSound = s
end

local function findEquippedTool()
    local char = player.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") then
                if item:FindFirstChild("broEvent") then
                    currentTool = item
                    return
                elseif item.Name == "1 punches" and punchEvent then
                    currentTool = item
                    return
                end
            end
        end
    end
    currentTool = nil
end

local function setupMouseInput()
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isMouseDown = 1
        end
    end)

    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isMouseDown = nil
        end
    end)
end

local function handleToolUsage()
    runService.Heartbeat:Connect(function()
        if not currentTool then return end
        if isMouseDown and overware.get("Auto Swing") then
            if currentTool.Name == "1 punches" and punchEvent then
                punchEvent:FireServer(1)
            elseif currentTool:FindFirstChild("broEvent") then
                currentTool.broEvent:FireServer(1)
            end
			task.spawn(function()
				local RaycastParams_new_result1 = RaycastParams.new()
				RaycastParams_new_result1.FilterType = Enum.RaycastFilterType.Exclude
				RaycastParams_new_result1.FilterDescendantsInstances = {player.Character}
				local workspace_Raycast_result1 = workspace:Raycast(player.Character:FindFirstChild("HumanoidRootPart").Position, Vector3.new(0, -100, 0), RaycastParams_new_result1)
				if workspace_Raycast_result1 and workspace_Raycast_result1.Instance then
					if workspace_Raycast_result1.Instance.Parent and workspace_Raycast_result1.Instance.Parent:FindFirstChild("Humanoid") then
						punchEvent:FireServer(2)
					end
				end
			end)
        end
    end)
end

local function monitorTools()
    player.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            if child:FindFirstChild("broEvent") or (child.Name == "1 punches" and punchEvent) then
                currentTool = child
            end
        end
    end)

    player.Character.ChildRemoved:Connect(function(child)
        if child == currentTool then
            currentTool = nil
        end
    end)
end

local Main = {
    findEquippedTool,
    setSprint,
	monitorTools,
}

function Main.OnCharacterLoaded()
    for key, func in pairs(Main) do
        if type(func) == "function" and func ~= Main.OnCharacterLoaded then
            func()
        end
    end
end

player.CharacterAdded:Connect(Main.OnCharacterLoaded)
if player.Character then 
	Main.OnCharacterLoaded()
end
handleToolUsage()
showLpHitboxes()
lowGfx()
setupMouseInput()

message.Message("[OVERWARE]: CLOSET CHEAT LOADED SUCCESSFULLY!", initSound, 12)
