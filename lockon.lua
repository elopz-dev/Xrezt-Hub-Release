local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local LockedTarget = nil
local LockOnActive = false
local ToggleKey = Enum.KeyCode.Q

local function GetCharacter(player)
    if not player then return nil end
    local liveFolder = workspace:FindFirstChild("Live")
    if liveFolder then
        local model = liveFolder:FindFirstChild(player.Name)
        if model then return model end
    end
    return player.Character
end

local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local character = GetCharacter(player)
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return false end
    if humanoid.Health <= 0 then return false end
    
    return true
end

local function GetClosestTargetToCenter()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local center = Camera.ViewportSize / 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local character = GetCharacter(player)
            local rootPart = character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (center - targetScreenPos).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

local TargetGui = Instance.new("BillboardGui")
TargetGui.Name = "LockOnTracker"
TargetGui.Size = UDim2.new(0, 16, 0, 16)
TargetGui.AlwaysOnTop = true
TargetGui.Enabled = false
TargetGui.StudsOffset = Vector3.new(0, 1.2, 0)

local ReticleImage = Instance.new("Frame")
ReticleImage.Size = UDim2.new(1, 0, 1, 0)
ReticleImage.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ReticleImage.BackgroundTransparency = 0.2
ReticleImage.Parent = TargetGui

local ReticleCorner = Instance.new("UICorner")
ReticleCorner.CornerRadius = UDim.new(0.5, 0)
ReticleCorner.Parent = ReticleImage

local oldUI = LocalPlayer.PlayerGui:FindFirstChild("SafeCameraUI")
if oldUI then oldUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SafeCameraUI"
ScreenGui.ResetOnSpawn = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "LockToggle"
ToggleButton.Size = UDim2.new(0, 90, 0, 45)
ToggleButton.Position = UDim2.new(0.85, -45, 0.15, -22)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Text = "LOCK: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.2, 0)
UICorner.Parent = ToggleButton

local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

ScreenGui.Parent = LocalPlayer.PlayerGui

local function DisableAutoRotate()
    local myCharacter = GetCharacter(LocalPlayer)
    local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    if myHumanoid then
        myHumanoid.AutoRotate = false
    end
end

local function RestoreAutoRotate()
    local myCharacter = GetCharacter(LocalPlayer)
    local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    if myHumanoid then
        myHumanoid.AutoRotate = true
    end
end

local function ToggleLock()
    if LockOnActive then
        LockOnActive = false
        LockedTarget = nil
        ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        ToggleButton.Text = "LOCK: OFF"
        TargetGui.Enabled = false
        TargetGui.Adornee = nil
        RestoreAutoRotate()
    else
        local target = GetClosestTargetToCenter()
        if target then
            LockedTarget = target
            LockOnActive = true
            ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            ToggleButton.Text = "LOCK: ON"
            DisableAutoRotate()
        else
            task.spawn(function()
                ToggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                ToggleButton.Text = "NO TARGET"
                task.wait(1)
                if not LockOnActive then
                    ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    ToggleButton.Text = "LOCK: OFF"
                end
            end)
        end
    end
end

ToggleButton.MouseButton1Click:Connect(ToggleLock)

pcall(function()
    RunService:UnbindFromRenderStep("CharacterLockOn")
end)

RunService:BindToRenderStep("CharacterLockOn", Enum.RenderPriority.Last.Value, function()
    local myCharacter = GetCharacter(LocalPlayer)
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    
    if LockOnActive and IsValidTarget(LockedTarget) and myRoot then
        local targetCharacter = GetCharacter(LockedTarget)
        local targetPart = targetCharacter.HumanoidRootPart
        
        if myHumanoid and myHumanoid.AutoRotate then
            myHumanoid.AutoRotate = false
        end
        
        local myPos = myRoot.Position
        local targetPos = targetPart.Position
        local lookAtPosition = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
        
        myRoot.CFrame = CFrame.new(myPos, lookAtPosition)
        
        if TargetGui.Adornee ~= targetPart then
            TargetGui.Adornee = targetPart
            TargetGui.Parent = targetPart
            TargetGui.Enabled = true
        end
    else
        if LockOnActive then
            LockOnActive = false
            LockedTarget = nil
            ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            ToggleButton.Text = "LOCK: OFF"
            TargetGui.Enabled = false
            TargetGui.Adornee = nil
            RestoreAutoRotate()
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ToggleKey then ToggleLock() end
end)

print("ENI's BillboardGui-based target tracker executed.")
