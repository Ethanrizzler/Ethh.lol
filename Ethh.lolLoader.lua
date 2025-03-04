Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/Library.lua'))()

Window = Library:CreateWindow({
-- Set Center to true if you want the menu to appear in the center
-- Set AutoShow to true if you want the menu to appear when it is created
-- Position and Size are also valid options here
-- but you do not need to define them unless you are changing them :)

Title = 'Hexploit V2 | .gg/traced',
Center = true,
AutoShow = true,
TabPadding = 9
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.

Tabs = {
Main = Window:AddTab('Main'),
Visuals = Window:AddTab('Visuals'),
Movement = Window:AddTab('Movement'),
Misc = Window:AddTab('Misc'),
Teleport = Window:AddTab('Teleport'),
D = Window:AddTab('D'),
['UI Settings'] = Window:AddTab('UI Settings'),  -- This is fine with proper syntax
}
local AimLockV2GroupBox = Tabs.Main:AddLeftGroupbox('AimLockV2')

local aimbotEnabledV2 = false
local lockedTargetV2 = nil
local currentKeybindV2 = Enum.KeyCode.C -- Default key for AimLockV2
local highlightsEnabledV2 = false
local autoPredictionV2 = false -- Fake AutoPrediction toggle
local ragelockV2 = false
local orbitActiveV2 = false

local function ethantherizzler_1V2()
    local maxDistance = 10000
    local closestPlayer = nil
    local closestMagnitude = math.huge

    -- Limit the number of players to check
    local playersChecked = 0
    for _, player in pairs(Players:GetPlayers()) do
        if playersChecked >= 10 then break end  -- Limit to checking 10 players
        playersChecked = playersChecked + 1

        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePos).Magnitude

                if distance < closestMagnitude then
                    local rayOrigin = camera.CFrame.Position
                    local rayDirection = (head.Position - rayOrigin).unit * maxDistance
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

                    if raycastResult and raycastResult.Instance:IsDescendantOf(player.Character) then
                        closestMagnitude = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Add the AimLockV2 toggle
AimLockV2GroupBox:AddToggle('Enable AimLockV2', {
    Default = false,
    Callback = function(state)
        aimbotEnabledV2 = state
        if state then
            lockedTargetV2 = ethantherizzler_1V2()
        else
            lockedTargetV2 = nil
        end
    end
})

-- Add keybind for AimLockV2
AimLockV2GroupBox:AddKeybind('Keybind for AimLockV2', {
    Default = currentKeybindV2,
    Callback = function(key)
        currentKeybindV2 = key
    end
})

-- Add toggle for AimLockV2 highlight
AimLockV2GroupBox:AddToggle('Enable Highlights', {
    Default = highlightsEnabledV2,
    Callback = function(state)
        highlightsEnabledV2 = state
    end
})

-- Add toggle for AutoPrediction (fake toggle)
AimLockV2GroupBox:AddToggle('Auto Prediction', {
    Default = false,
    Callback = function(state)
        autoPredictionV2 = state
    end
})

-- Add toggle for Orbiting (ragelockV2)
AimLockV2GroupBox:AddToggle('Orbit Lock (RageLock)', {
    Default = false,
    Callback = function(state)
        ragelockV2 = state
    end
})

-- Function to run AimLockV2 logic
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == currentKeybindV2 then
        if aimbotEnabledV2 then
            aimbotEnabledV2 = false
            lockedTargetV2 = nil
        else
            lockedTargetV2 = ethantherizzler_1V2()
            aimbotEnabledV2 = (lockedTargetV2 ~= nil)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if aimbotEnabledV2 then
        if lockedTargetV2 then
            lockOnTargetV2()
        end
    end
end)

LeftGroupBox = Tabs.Main:AddLeftGroupbox('Aimlock')


-- Services and Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local cursorLocked = false
local targetHead = nil
local targetPlayer = nil
local previewHighlight = nil
local lockedHighlight = nil
local predictionLevel = 0 -- Default prediction level, can be changed (higher value = more prediction)
local currentKeybind = Enum.KeyCode.C
local previewColor = Color3.fromRGB(0, 0, 255) -- Default preview color
local lockedHighlightColor = Color3.fromRGB(255, 0, 0) -- Default locked highlight color
local smoothness = 0 -- Default smoothness value
local highlightsEnabled = false -- Default value for highlights toggle

local ragelock = false  -- Default value for ragelock
local orbitActive = false  -- Flag for orbit feature
local orbitSpeed = 10 -- Orbit speed
local radius = 8 -- Orbit size
local rotation = CFrame.Angles(0, 0, 0) -- Rotation angles

-- Ensure aimlock state is toggled correctly on each execution
if _G.aimlock == nil then
    _G.aimlock = false  -- Default value if not previously set
end

-- Function to check if the player is knocked or grabbed
local function IsPlayerKnockedOrGrabbed(player)
    local character = player.Character
    if character then
        local bodyEffects = character:FindFirstChild("BodyEffects")
        local grabbingConstraint = character:FindFirstChild("GRABBING_CONSTRAINT")
        if bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value or grabbingConstraint then
            return true
        end
    end
    return false
end

-- Function to calculate the predicted position based on velocity
local function GetPredictedPosition(player)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if humanoid and head then
            local velocity = humanoid.RootPart.AssemblyLinearVelocity
            return head.Position + velocity * predictionLevel
        end
    end
    return nil
end

-- Function to find the closest player's head, with prediction
local function FindClosestPlayerHead()
    local closestPlayer = nil
    local closestDistance = math.huge
    local mousePosition = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid and humanoid.Health > 0 then
                if IsPlayerKnockedOrGrabbed(player) then continue end  -- Skip locked/knocked/grabbed players
                local head = character.Head
                local predictedHeadPosition = GetPredictedPosition(player) or head.Position
                local screenPoint = Camera:WorldToScreenPoint(predictedHeadPosition)
                local distance = (mousePosition - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                local playerDistance = (Camera.CFrame.Position - predictedHeadPosition).Magnitude

                local ray = Ray.new(Camera.CFrame.Position, predictedHeadPosition - Camera.CFrame.Position)
                local hitPart, hitPosition = Workspace:FindPartOnRay(ray, LocalPlayer.Character)

                -- Lock even through walls for players within 100 studs
                if playerDistance <= 100 or (not hitPart or hitPart.Parent == character) then
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    if closestPlayer then
        return closestPlayer.Character.Head, closestPlayer
    end
    return nil, nil
end

-- Function to add a preview highlight for the closest player
local function AddPreviewHighlight(player)
    if not highlightsEnabled then return end -- Skip if highlights are disabled

    -- If preview highlight already exists for this player, return early
    if previewHighlight and previewHighlight.Parent == player.Character then
        previewHighlight.FillColor = previewColor
        return
    end

    -- Destroy previous preview highlight if it exists
    if previewHighlight then
        previewHighlight:Destroy()
    end

    -- Create a new preview highlight for the closest player
    if player and player.Character then
        previewHighlight = Instance.new("Highlight")
        previewHighlight.Parent = player.Character
        previewHighlight.FillTransparency = 0.5
        previewHighlight.FillColor = previewColor
    end
end

-- Function to add a red highlight to the locked player
local function AddLockedHighlight(player)
    if not highlightsEnabled then return end -- Skip if highlights are disabled

    -- If locked highlight already exists for this player, return early
    if lockedHighlight and lockedHighlight.Parent == player.Character then
        lockedHighlight.FillColor = lockedHighlightColor
        return
    end

    -- Destroy previous locked highlight if it exists
    if lockedHighlight then
        lockedHighlight:Destroy()
    end

    -- Create a new locked highlight for the locked player
    if player and player.Character then
        lockedHighlight = Instance.new("Highlight")
        lockedHighlight.Parent = player.Character
        lockedHighlight.FillTransparency = 0.5
        lockedHighlight.FillColor = lockedHighlightColor
    end
end

-- Lock the cursor to the nearest player's head
local function LockCursorToHead()
    targetHead, targetPlayer = FindClosestPlayerHead()
    if targetHead then
        AddLockedHighlight(targetPlayer)  -- Add highlight to locked player
        if previewHighlight then previewHighlight:Destroy() end  -- Destroy preview highlight if it exists
        UserInputService.MouseIconEnabled = false
    end
end

-- Unlock the cursor
local function UnlockCursor()
    UserInputService.MouseIconEnabled = true
    targetHead = nil
    targetPlayer = nil
    if lockedHighlight then lockedHighlight:Destroy() end
end

-- Function to activate orbiting around the target player
local function ActivateOrbit(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        targetPlayer = player
    end
end

-- Function to deactivate orbiting
local function DeactivateOrbit()
    targetPlayer = nil
end

-- Function to handle automatic targeting for RageLock
local function HandleRageLock()
    -- Ensure RageLock only locks onto the target if it's valid
    if ragelock then
        -- Check if targetPlayer is invalid or knocked
        if targetPlayer and IsPlayerKnockedOrGrabbed(targetPlayer) then
            -- If the locked target is knocked or grabbed, unlock and search for the next target
            cursorLocked = false
            UnlockCursor()
            DeactivateOrbit()
            print("[RageLock] Target is knocked/grabbed, unlocking and searching for next target.")
            targetHead, targetPlayer = FindClosestPlayerHead()
            if targetPlayer then
                cursorLocked = true
                LockCursorToHead()
                AddLockedHighlight(targetPlayer)  -- Add highlight to new target
            end
            return
        end

        -- If no valid target is locked, search for a new one
        if not targetPlayer then
            targetHead, targetPlayer = FindClosestPlayerHead()
            if targetPlayer then
                cursorLocked = true
                LockCursorToHead()
                AddLockedHighlight(targetPlayer)  -- Add highlight to new target
            end
        end
    end
end

-- Orbit update loop (only runs when orbit toggle is true)
RunService.Stepped:Connect(function(_, dt)
    if orbitActive then
        -- Only update orbit if the toggle is true and the player is locked onto a valid target
        if cursorLocked and targetPlayer then
            -- Only update orbit if the target is locked (Aimlock or RageLock)
            local targetHumanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHumanoidRootPart then
                local rot = tick() * orbitSpeed
                local lpr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if lpr then
                    -- Orbit calculation (only orbits if locked onto target)
                    lpr.CFrame = CFrame.new(
                        targetHumanoidRootPart.Position + Vector3.new(math.sin(rot) * radius, 0, math.cos(rot) * radius)
                    )
                end
            end
        end
    end

    -- Update loop to continuously follow the locked target for aimlock
    if cursorLocked and _G.aimlock and targetHead then
        -- Handle ragelock to auto lock onto next target if necessary
        if ragelock then
            HandleRageLock()  -- Call the function to handle RageLock auto-targeting
        end

        -- Check if the locked player is knocked or grabbed and unlock if necessary
        if IsPlayerKnockedOrGrabbed(targetPlayer) then
            cursorLocked = false
            UnlockCursor()
            DeactivateOrbit()
            print("[Auto Unlock] Target player is knocked or grabbed, unlocking cursor.")
        else
                    -- Proceed with the normal aimlock and orbit
    local predictedHeadPosition = GetPredictedPosition(targetPlayer) or targetHead.Position
    -- Smoothly interpolate the camera's CFrame
    local alpha = 1 - smoothness
    alpha = math.max(alpha, 0.01)  -- Ensure alpha is never 0
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedHeadPosition), alpha)
        end
    elseif not cursorLocked and _G.aimlock then
        local closestHead, closestPlayer = FindClosestPlayerHead()
        if closestPlayer ~= targetPlayer then
            AddPreviewHighlight(closestPlayer)
        end
    end
end)

-- Handle key press (C) for locking the cursor
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKeybind then
        if _G.aimlock then
            cursorLocked = not cursorLocked
            if cursorLocked then
                LockCursorToHead()
                if orbitActive then
                    ActivateOrbit(targetPlayer)  -- Activate orbit when locking onto a player and orbiting is enabled
                end
            else
                UnlockCursor()
                DeactivateOrbit()  -- Deactivate orbit when unlocking
            end
        end
    end
end)

-- UI Controls for setting various values like keybinds and highlight colors
LeftGroupBox:AddToggle('Aimlock', {
    Text = 'Aimlock',
    Default = false,
    Tooltip = 'Locks your aim onto players heads',
    Callback = function(Value)
        _G.aimlock = Value
        print('[cb] Aimlock changed to:', Value)
        if _G.aimlock then
            cursorLocked = false  -- Ensure cursor is not locked when aimlock is turned on
        end
    end
})

LeftGroupBox:AddToggle('RageLock', {
    Text = 'RageLock',
    Default = false,
    Tooltip = 'Automatically locks onto the next available player',
    Callback = function(Value)
        ragelock = Value
        print('[cb] RageLock changed to:', Value)
    end
})

LeftGroupBox:AddToggle('OrbitFeature', {
    Text = 'Orbit Around Target',
    Default = false,
    Tooltip = 'Toggle to start orbiting around the player you lock onto.',
    Callback = function(value)
        orbitActive = value  -- Directly set orbitActive based on toggle state
        if orbitActive and cursorLocked then
            ActivateOrbit(targetPlayer) -- Activate orbit only if locked onto a player
        else
            DeactivateOrbit()  -- Deactivate orbit when the toggle is off
        end
    end
})

-- Add Toggle for Highlights
LeftGroupBox:AddToggle('HighlightsToggle', {
    Text = 'Highlights',
    Default = highlightsEnabled,
    Tooltip = 'Toggle to enable or disable highlights',
    Callback = function(Value)
        highlightsEnabled = Value
        print('[cb] Highlights toggled:', Value)
        if not Value then
            -- Destroy highlights if they exist
            if previewHighlight then
                previewHighlight:Destroy()
                previewHighlight = nil
            end
            if lockedHighlight then
                lockedHighlight:Destroy()
                lockedHighlight = nil
            end
        end
    end
})

LeftGroupBox:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
    Default = 'C',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Aimlock',
    ChangedCallback = function(New)
        print('[cb] Keybind changed!', New)
        currentKeybind = New
    end
})

LeftGroupBox:AddLabel('Preview Color'):AddColorPicker('PreviewColorPicker', {
    Default = previewColor,
    Title = 'Preview Color',
    Transparency = 0,
    Callback = function(Value)
        print('[cb] Preview Color changed!', Value)
        previewColor = Value
        if previewHighlight then
            previewHighlight.FillColor = Value
        end
    end
})

LeftGroupBox:AddLabel('Locked Highlight Color'):AddColorPicker('LockedColorPicker', {
    Default = lockedHighlightColor,
    Title = 'Locked Player Highlight Color',
    Transparency = 0,
    Callback = function(Value)
        print('[cb] Locked Highlight Color changed!', Value)
        lockedHighlightColor = Value
        if lockedHighlight then
            lockedHighlight.FillColor = Value
        end
    end
})

-- Add Smoothness Slider
LeftGroupBox:AddSlider('SmoothnessSlider', {
    Text = 'Smoothness',
    Default = smoothness,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        print('[cb] Smoothness changed!', Value)
        smoothness = Value
    end
})

LeftGroupBox:AddSlider('Orbit Speed', {
    Text = 'Orbit Speed',
    Default = orbitSpeed,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        print('[cb] Orbit Speed changed!', Value)
        orbitSpeed = Value
    end
})

LeftGroupBox:AddSlider('PredictionSlider', {
    Text = 'Prediction',
    Default = predictionLevel,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        print('[cb] Prediction changed!', Value)
        predictionLevel = Value
    end
})
--- more code comes next
