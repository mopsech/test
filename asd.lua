-- ========================================
-- ===== PLANT HUB v3.0 FINAL =====
-- ========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
    game.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "WindUI not loaded!", Duration = 5})
    return
end

WindUI:SetTheme("Dark")
WindUI.TransparencyValue = 0.1

local Window = WindUI:CreateWindow({
    Title = "PlanetHub",
    Author = "MMV & MM2",
    Icon = "crown",
    Folder = "PlanetHubSettings",
    Size = UDim2.fromOffset(720, 600),
    Resizable = true,
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 190,
    HideSearchBar = false
})

-- ========================================
-- ===== СЕРВИСЫ =====
-- ========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ========================================
-- ===== НАСТРОЙКИ =====
-- ========================================

local Settings = {
    MurderESP = false,
    SheriffESP = false,
    InnocentESP = false,
    SkeletonESP = false,
    ChamsEnabled = false,
    JumpCircles = false,
    Trails = false,
    ParticlesEnabled = false,
    RGBHumanoid = false,
    XRayEnabled = false,
    CrosshairEnabled = false,
    FlyEnabled = false,
    FlySpeed = 100,
    BHopEnabled = false,
    BHopSpeed = 50,
    SpinBotEnabled = false,
    SpinBotSpeed = 9999,
    NoclipEnabled = false,
    AntiFlingEnabled = false,
    WallThoughtEnabled = false,
    WallThoughtRadius = 50,
    AntiAFKEnabled = false,
    AutoFarmEnabled = false,
    AutoFarmSpeed = 20,
    AutoFarmCoinLimit = 40,
    AutoFarmCoinDelay = 0.15,
    AutoRespawn = false,
    TracersEnabled = false,
}

-- ========================================
-- ===== КЭШИ =====
-- ========================================

local Cache = {
    Highlights = {},
    Bones = {},
    BoneParts = {},
    Visuals = {},
    Connections = {},
    ChamsParts = {},
    ChamsPartsList = {},
    Particles = {},
    PostEffects = {},
    JumpTracking = {},
    RGBConnection = nil,
    AutoFarmConnection = nil,
    CurrentTween = nil,
    XRayParts = {},
    Tracers = {},
}

local COLORS = {
    Murder = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Purple = Color3.fromRGB(138, 43, 226),
    White = Color3.fromRGB(255, 255, 255),
}

-- ========================================
-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
-- ========================================

local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local function checkKnife(player)
    if not player or not player.Character then return false end
    for _, item in ipairs(player.Character:GetDescendants()) do
        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then
            return true
        end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then
                return true
            end
        end
    end
    return false
end

local function checkGun(player)
    if not player or not player.Character then return false end
    for _, item in ipairs(player.Character:GetDescendants()) do
        if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("pistol") or item.Name:lower():find("revolver")) then
            return true
        end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("pistol") or item.Name:lower():find("revolver")) then
                return true
            end
        end
    end
    return false
end

local function getRole(player)
    if checkKnife(player) then return "Murder" end
    if checkGun(player) then return "Sheriff" end
    return "Innocent"
end

local function getRoleColor(player)
    local role = getRole(player)
    if role == "Murder" then return COLORS.Murder end
    if role == "Sheriff" then return COLORS.Sheriff end
    return COLORS.Innocent
end

-- ========================================
-- ===== TRACERS (ЛИНИИ К ИГРОКАМ) =====
-- ========================================

local function createTracer(player)
    if not player or player == LocalPlayer then return end
    if Cache.Tracers[player.UserId] then return end

    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Transparency = 0.8
    line.Visible = false
    line.Color = getRoleColor(player)

    Cache.Tracers[player.UserId] = line
end

local function updateTracers()
    for userId, line in pairs(Cache.Tracers) do
        local player = Players:GetPlayerByUserId(userId)
        if not player or not player.Character or not Settings.TracersEnabled then
            line.Visible = false
            continue
        end

        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            line.Visible = false
            continue
        end

        local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
        if not onScreen or screenPos.Z < 0 then
            line.Visible = false
            continue
        end

        -- Линия от нижней части экрана к игроку
        local bottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        line.From = bottom
        line.To = Vector2.new(screenPos.X, screenPos.Y)
        line.Visible = true
        line.Color = getRoleColor(player)
    end
end

local function clearAllTracers()
    for userId, line in pairs(Cache.Tracers) do
        pcall(function() line:Remove() end)
    end
    Cache.Tracers = {}
end

-- ========================================
-- ===== CHAMS (ФИОЛЕТОВЫЕ ЧЕРЕЗ СТЕНЫ) =====
-- ========================================

local function cacheCharacterParts(player)
    if not player or not player.Character then return end
    local list = {}
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            list[part] = {
                ogMaterial = part.Material,
                ogColor = part.Color,
                ogTransparency = part.Transparency,
            }
        end
    end
    Cache.ChamsPartsList[player.UserId] = list
end

local function applyChams(player)
    if not player or not player.Character then return end
    local list = Cache.ChamsPartsList[player.UserId]
    if not list then
        cacheCharacterParts(player)
        list = Cache.ChamsPartsList[player.UserId]
        if not list then return end
    end

    for part, _ in pairs(list) do
        if part and part.Parent then
            part.Material = Enum.Material.ForceField
            part.Color = COLORS.Purple
            part.Transparency = 0.15
            part.LocalTransparencyModifier = 0 -- ВИДНЫ ЧЕРЕЗ СТЕНЫ
        end
    end
end

local function removeChams(player)
    if not player or not player.Character then return end
    local list = Cache.ChamsPartsList[player.UserId]
    if not list then return end

    for part, data in pairs(list) do
        if part and part.Parent then
            pcall(function()
                part.Material = data.ogMaterial
                part.Color = data.ogColor
                part.Transparency = data.ogTransparency
                part.LocalTransparencyModifier = 1
            end)
        end
    end
    Cache.ChamsPartsList[player.UserId] = nil
end

local function clearAllChams()
    for userId, list in pairs(Cache.ChamsPartsList) do
        for part, data in pairs(list) do
            if part and part.Parent then
                pcall(function()
                    part.Material = data.ogMaterial
                    part.Color = data.ogColor
                    part.Transparency = data.ogTransparency
                    part.LocalTransparencyModifier = 1
                end)
            end
        end
    end
    Cache.ChamsPartsList = {}
end

-- ========================================
-- ===== HIGHLIGHT ESP =====
-- ========================================

local function createOrUpdateHighlight(player, color)
    if not player or not player.Character then return end
    local char = player.Character
    local highlight = char:FindFirstChild("MurderESP_Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "MurderESP_Highlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
    end
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.Enabled = true
    Cache.Highlights[player.UserId] = highlight
end

local function removeHighlight(player)
    if not player or not player.Character then return end
    local highlight = player.Character:FindFirstChild("MurderESP_Highlight")
    if highlight then pcall(function() highlight:Destroy() end) end
    Cache.Highlights[player.UserId] = nil
end

local function clearAllHighlights()
    for userId, highlight in pairs(Cache.Highlights) do
        if highlight then pcall(function() highlight:Destroy() end) end
    end
    Cache.Highlights = {}
end

-- ========================================
-- ===== RGB HUMANOID =====
-- ========================================

local function setupRGBHumanoid()
    if Settings.RGBHumanoid then
        safeDisconnect(Cache.RGBConnection)
        Cache.RGBConnection = RunService.Heartbeat:Connect(function()
            if not Settings.RGBHumanoid or not LocalPlayer.Character then return end
            local t = tick()
            local color = Color3.fromHSV(t % 1, 1, 1)
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Material = Enum.Material.ForceField
                    part.Color = color
                    part.Transparency = 0.3
                end
            end
        end)
    else
        safeDisconnect(Cache.RGBConnection)
        Cache.RGBConnection = nil
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Plastic
                    part.Color = Color3.fromRGB(255, 255, 255)
                    part.Transparency = 0
                end
            end
        end
    end
end

-- ========================================
-- ===== XRAY =====
-- ========================================

local function setupXRay()
    if Settings.XRayEnabled then
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsA("Terrain") then
                Cache.XRayParts[part] = part.LocalTransparencyModifier
                part.LocalTransparencyModifier = 0.5
            end
        end
    else
        for part, val in pairs(Cache.XRayParts) do
            if part and part.Parent then
                pcall(function() part.LocalTransparencyModifier = val end)
            end
        end
        Cache.XRayParts = {}
    end
end

-- ========================================
-- ===== CROSSHAIR (꩜) =====
-- ========================================

local crosshairGui = nil
local shiftLockConn = nil

local function createCrosshair()
    if crosshairGui then crosshairGui:Destroy() end
    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "Crosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    crosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 50, 0, 50)
    label.Position = UDim2.new(0.5, -25, 0.5, -25)
    label.BackgroundTransparency = 1
    label.Text = "꩜"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = crosshairGui

    crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    if not Settings.CrosshairEnabled then
        safeDisconnect(shiftLockConn)
        return
    end

    shiftLockConn = RunService.RenderStepped:Connect(function()
        if not Settings.CrosshairEnabled then
            safeDisconnect(shiftLockConn)
            shiftLockConn = nil
            return
        end
        local shiftLock = LocalPlayer.PlayerGui:FindFirstChild("ShiftLock")
        if shiftLock then
            shiftLock.Enabled = false
            shiftLock.ResetOnSpawn = false
        end
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name:lower():find("crosshair") or gui.Name:lower():find("aim") then
                if gui ~= crosshairGui then
                    gui.Enabled = false
                end
            end
        end
    end)
end

-- ========================================
-- ===== JUMP CIRCLES =====
-- ========================================

local function createJumpCircleAtPosition(position)
    if not Settings.JumpCircles then return end

    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.05, 0.5, 0.5)
    ring.Material = Enum.Material.Neon
    ring.Color = COLORS.Purple
    ring.Transparency = 0
    ring.Anchored = true
    ring.CanCollide = false
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = workspace

    local light = Instance.new("PointLight")
    light.Brightness = 5
    light.Color = COLORS.Purple
    light.Range = 25
    light.Parent = ring

    local startTime = tick()
    local duration = 0.8

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not ring or not ring.Parent then
            safeDisconnect(conn)
            return
        end
        local elapsed = tick() - startTime
        local progress = elapsed / duration
        if progress >= 1 then
            pcall(function() ring:Destroy() end)
            safeDisconnect(conn)
            return
        end
        local scale = 0.5 + (progress * 4.5)
        ring.Size = Vector3.new(0.05, scale, scale)
        ring.Transparency = progress
        light.Brightness = 5 * (1 - progress)
        ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    end)
end

local function setupJumpTracking()
    if LocalPlayer.Character then
        if not Cache.JumpTracking["local"] then
            Cache.JumpTracking["local"] = {wasJumping = false}
        end
    end
end

local function updateJumpCircles()
    if not Settings.JumpCircles or not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoid and hrp then
        local tracking = Cache.JumpTracking["local"]
        if not tracking then
            tracking = {wasJumping = false}
            Cache.JumpTracking["local"] = tracking
        end
        local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
        if isJumping and not tracking.wasJumping then
            createJumpCircleAtPosition(hrp.Position)
        end
        tracking.wasJumping = isJumping
    end
end

-- ========================================
-- ===== TRAILS =====
-- ========================================

local function createLocalPlayerTrail()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local oldTrail = hrp:FindFirstChild("LocalTrail")
    if oldTrail then oldTrail:Destroy() end
    local oldAtt1 = hrp:FindFirstChild("TrailAtt1")
    if oldAtt1 then oldAtt1:Destroy() end
    local oldAtt2 = hrp:FindFirstChild("TrailAtt2")
    if oldAtt2 then oldAtt2:Destroy() end

    local att1 = Instance.new("Attachment")
    att1.Name = "TrailAtt1"
    att1.Parent = hrp
    att1.Position = Vector3.new(-1, 0, 0)

    local att2 = Instance.new("Attachment")
    att2.Name = "TrailAtt2"
    att2.Parent = hrp
    att2.Position = Vector3.new(1, 0, 0)

    local trail = Instance.new("Trail")
    trail.Name = "LocalTrail"
    trail.Attachment0 = att1
    trail.Attachment1 = att2
    trail.Lifetime = 0.8
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Color = ColorSequence.new(COLORS.Purple)
    trail.Parent = hrp

    Cache.Visuals["localtrail"] = {trail = trail, att1 = att1, att2 = att2}
end

-- ========================================
-- ===== ANTI-AFK =====
-- ========================================

local afkConnection = nil
local lastAfkJump = 0

local function setupAntiAFK()
    if Settings.AntiAFKEnabled then
        safeDisconnect(afkConnection)
        afkConnection = RunService.Heartbeat:Connect(function()
            if not Settings.AntiAFKEnabled or not LocalPlayer.Character then return end
            local now = tick()
            if now - lastAfkJump > 60 then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Jump = true
                    lastAfkJump = now
                end
            end
        end)
    else
        safeDisconnect(afkConnection)
        afkConnection = nil
    end
end

-- ========================================
-- ===== AUTO FARM + АВТОРЕСПАВН =====
-- ========================================

local function getCoinBag()
    local success, result = pcall(function()
        return LocalPlayer.PlayerGui.MainGUI.Game.CoinBags.Container.Coin.CurrencyFrame.Icon.Coins
    end)
    return success and result or nil
end

local function getCurrentCoins()
    local coinBagGui = getCoinBag()
    if coinBagGui then
        local text = coinBagGui.Text
        local num = tonumber(text)
        return num or 0
    end
    return 0
end

local function getValidCoins()
    local coins = {}
    local character = LocalPlayer.Character
    if not character then return coins end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return coins end

    for _, map in pairs(Workspace:GetChildren()) do
        local container = map:FindFirstChild("CoinContainer")
        if container then
            for _, coin in pairs(container:GetChildren()) do
                if coin.Name == "Coin_Server" and coin:IsA("BasePart") then
                    if coin:FindFirstChild("TouchInterest") then
                        local distance = (hrp.Position - coin.Position).Magnitude
                        table.insert(coins, {
                            part = coin,
                            distance = distance
                        })
                    end
                end
            end
        end
    end

    table.sort(coins, function(a, b)
        return a.distance < b.distance
    end)

    return coins
end

local function tweenToCoin(coin)
    if not coin or not coin.Parent then return false end
    if not coin:FindFirstChild("TouchInterest") then return false end

    local character = LocalPlayer.Character
    if not character then return false end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end

    local targetPos = coin.Position + Vector3.new(0, 2, 0)
    local distance = (hrp.Position - targetPos).Magnitude

    if distance < 5 then return true end

    local duration = distance / Settings.AutoFarmSpeed

    if Cache.CurrentTween then
        pcall(function() Cache.CurrentTween:Cancel() end)
    end

    Cache.CurrentTween = TweenService:Create(hrp, TweenInfo.new(
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ), {
        CFrame = CFrame.new(targetPos)
    })

    humanoid.Sit = true
    Cache.CurrentTween:Play()

    local completed = false
    local connection
    connection = Cache.CurrentTween.Completed:Connect(function()
        completed = true
        safeDisconnect(connection)
    end)

    local startTime = tick()
    while not completed and Settings.AutoFarmEnabled do
        task.wait(0.1)
        if not coin or not coin.Parent or not coin:FindFirstChild("TouchInterest") then
            if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
            humanoid.Sit = false
            return false
        end
        if tick() - startTime > 30 then
            if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
            humanoid.Sit = false
            return false
        end
    end

    humanoid.Sit = false
    return completed
end

local function collectCoin(coin)
    if not coin or not coin.Parent then return false end
    if not coin:FindFirstChild("TouchInterest") then return false end

    local character = LocalPlayer.Character
    if not character then return false end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local success = pcall(function()
        firetouchinterest(hrp, coin, 0)
        task.wait(0.05)
        firetouchinterest(hrp, coin, 1)
    end)

    return success
end

local function autoRespawn()
    if not Settings.AutoRespawn then return end
    local coinBag = getCurrentCoins()
    if coinBag >= Settings.AutoFarmCoinLimit then
        local respawnBtn = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
        if respawnBtn then
            local btn = respawnBtn:FindFirstChild("Game")
            if btn then
                local respawn = btn:FindFirstChild("Respawn")
                if respawn then
                    pcall(function()
                        respawn:FindFirstChild("RespawnButton"):Click()
                    end)
                end
            end
        end
        StarterGui:SetCore("SendNotification", {
            Title = "AutoFarm",
            Text = "💀 Респавн! Баг полный!",
            Duration = 2
        })
    end
end

local function farmLoop()
    while Settings.AutoFarmEnabled do
        local character = LocalPlayer.Character
        if not character then
            task.wait(1)
            continue
        end

        local currentCoins = getCurrentCoins()
        if currentCoins >= Settings.AutoFarmCoinLimit then
            if Settings.AutoRespawn then
                autoRespawn()
                task.wait(3)
                continue
            else
                Settings.AutoFarmEnabled = false
                StarterGui:SetCore("SendNotification", {
                    Title = "AutoFarm",
                    Text = "CoinBag полный! ✅",
                    Duration = 3
                })
                break
            end
        end

        local validCoins = getValidCoins()
        if #validCoins == 0 then
            task.wait(2)
        else
            local nearestCoin = validCoins[1].part
            local success = tweenToCoin(nearestCoin)
            if success and Settings.AutoFarmEnabled then
                collectCoin(nearestCoin)
                task.wait(Settings.AutoFarmCoinDelay)
            end
        end

        task.wait(0.1)
    end

    safeDisconnect(Cache.AutoFarmConnection)
    Cache.AutoFarmConnection = nil
end

local function setupAutoFarm()
    if Settings.AutoFarmEnabled then
        if not LocalPlayer.Character then return end
        safeDisconnect(Cache.AutoFarmConnection)
        Cache.AutoFarmConnection = task.spawn(farmLoop)
        StarterGui:SetCore("SendNotification", {
            Title = "AutoFarm",
            Text = "Автофарм включен! 🚀",
            Duration = 3
        })
    else
        safeDisconnect(Cache.AutoFarmConnection)
        Cache.AutoFarmConnection = nil

        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.Sit = false end
        end

        if Cache.CurrentTween then
            pcall(function() Cache.CurrentTween:Cancel() end)
            Cache.CurrentTween = nil
        end
    end
end

-- ========================================
-- ===== FLY =====
-- ========================================

local flyConnection = nil
local isFlying = false
local flyBodyVelocity = nil
local flyBodyGyro = nil
local originalGravity = workspace.Gravity
local flySpeed = 100

local function stopFly()
    isFlying = false
    safeDisconnect(flyConnection)
    flyConnection = nil

    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end

    workspace.Gravity = originalGravity

    if flyBodyVelocity then
        pcall(function() flyBodyVelocity:Destroy() end)
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        pcall(function() flyBodyGyro:Destroy() end)
        flyBodyGyro = nil
    end
end

local function startFly()
    if not LocalPlayer.Character then return end

    if isFlying then stopFly() end

    local character = LocalPlayer.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then return end

    isFlying = true
    originalGravity = workspace.Gravity
    workspace.Gravity = 0
    humanoid.PlatformStand = true

    local oldBV = hrp:FindFirstChildOfClass("BodyVelocity")
    if oldBV then oldBV:Destroy() end
    local oldBG = hrp:FindFirstChildOfClass("BodyGyro")
    if oldBG then oldBG:Destroy() end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "FlyBodyVelocity"
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "FlyBodyGyro"
    flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBodyGyro.P = 1000
    flyBodyGyro.D = 100
    flyBodyGyro.Parent = hrp

    flySpeed = Settings.FlySpeed

    safeDisconnect(flyConnection)
    flyConnection = RunService.RenderStepped:Connect(function(dt)
        if not isFlying then
            stopFly()
            return
        end

        if not character or not character.Parent then
            stopFly()
            return
        end

        if not hrp or not hrp.Parent then
            stopFly()
            return
        end

        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            stopFly()
            return
        end

        local camCF = Camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * flySpeed
        else
            moveDir = Vector3.new(0, 0, 0)
        end

        flyBodyVelocity.Velocity = moveDir
        flyBodyGyro.CFrame = camCF
    end)
end

-- ========================================
-- ===== BUNNY HOP =====
-- ========================================

local BHop = {
    Enabled = false,
    Speed = 50,
}
local bhopConnection = nil
local bhopJumpCooldown = 0

local function setupBHop()
    if BHop.Enabled then
        safeDisconnect(bhopConnection)
        bhopConnection = RunService.RenderStepped:Connect(function()
            if not BHop.Enabled or not LocalPlayer.Character then return end

            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if not humanoid or not hrp then return end

            if humanoid:GetState() == Enum.HumanoidStateType.Landed then
                local isMoving = UserInputService:IsKeyDown(Enum.KeyCode.W) or
                                 UserInputService:IsKeyDown(Enum.KeyCode.A) or
                                 UserInputService:IsKeyDown(Enum.KeyCode.S) or
                                 UserInputService:IsKeyDown(Enum.KeyCode.D)

                if isMoving and tick() - bhopJumpCooldown > 0.05 then
                    humanoid.Jump = true
                    bhopJumpCooldown = tick()

                    local moveDir = Vector3.new(0, 0, 0)
                    local camCF = Camera.CFrame

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end

                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit * BHop.Speed
                        hrp.Velocity = Vector3.new(moveDir.X, hrp.Velocity.Y, moveDir.Z)
                    end
                end
            end
        end)
    else
        safeDisconnect(bhopConnection)
        bhopConnection = nil
    end
end

-- ========================================
-- ===== SPIN BOT =====
-- ========================================

local SpinBot = {
    Enabled = false,
    Speed = 9999,
}
local spinConnection = nil

local function setupSpinBot()
    if SpinBot.Enabled then
        safeDisconnect(spinConnection)
        spinConnection = RunService.Heartbeat:Connect(function(dt)
            if not SpinBot.Enabled or not LocalPlayer.Character then return end
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinBot.Speed * dt), 0)
            end
        end)
    else
        safeDisconnect(spinConnection)
        spinConnection = nil
    end
end

-- ========================================
-- ===== WALL THOUGHT =====
-- ========================================

local wallThoughtConnection = nil

local function setupWallThought()
    if Settings.WallThoughtEnabled then
        safeDisconnect(wallThoughtConnection)
        wallThoughtConnection = RunService.Heartbeat:Connect(function()
            if not Settings.WallThoughtEnabled or not LocalPlayer.Character then return end
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer or not player.Character then continue end
                local theirHRP = player.Character:FindFirstChild("HumanoidRootPart")
                local theirHumanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if not theirHRP or not theirHumanoid then continue end
                local dist = (myHRP.Position - theirHRP.Position).Magnitude
                if dist <= Settings.WallThoughtRadius then
                    theirHumanoid.Health = 0
                end
            end
        end)
    else
        safeDisconnect(wallThoughtConnection)
        wallThoughtConnection = nil
    end
end

-- ========================================
-- ===== MAIN UPDATE LOOP =====
-- ========================================

local mainUpdateConnection = nil

local function updateVisuals()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if Settings.ChamsEnabled then
                applyChams(player)
            else
                if Cache.ChamsPartsList[player.UserId] then
                    removeChams(player)
                end
            end
        else
            if not player.Character then continue end

            local role = getRole(player)

            if Settings.MurderESP and role == "Murder" then
                createOrUpdateHighlight(player, COLORS.Murder)
            elseif Settings.SheriffESP and role == "Sheriff" then
                createOrUpdateHighlight(player, COLORS.Sheriff)
            elseif Settings.InnocentESP and role == "Innocent" then
                createOrUpdateHighlight(player, COLORS.Innocent)
            else
                removeHighlight(player)
            end

            if Settings.ChamsEnabled then
                applyChams(player)
            else
                if Cache.ChamsPartsList[player.UserId] then
                    removeChams(player)
                end
            end

            -- Создаём трассеры
            if Settings.TracersEnabled then
                if not Cache.Tracers[player.UserId] then
                    createTracer(player)
                end
            end
        end
    end

    -- Обновляем трассеры
    if Settings.TracersEnabled then
        updateTracers()
    else
        clearAllTracers()
    end

    if Settings.Trails then
        if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("LocalTrail") then
            createLocalPlayerTrail()
        end
    else
        if LocalPlayer.Character then
            local trail = LocalPlayer.Character:FindFirstChild("LocalTrail")
            if trail then pcall(function() trail:Destroy() end) end
            local att1 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                         LocalPlayer.Character.HumanoidRootPart:FindFirstChild("TrailAtt1")
            if att1 then att1:Destroy() end
            local att2 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                         LocalPlayer.Character.HumanoidRootPart:FindFirstChild("TrailAtt2")
            if att2 then att2:Destroy() end
        end
    end
end

local function startMainUpdate()
    safeDisconnect(mainUpdateConnection)

    mainUpdateConnection = RunService.Heartbeat:Connect(function()
        local anyActive = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP or
                          Settings.ChamsEnabled or Settings.Trails or Settings.TracersEnabled

        if anyActive then
            updateVisuals()
        end

        if Settings.JumpCircles then
            updateJumpCircles()
        end
    end)
end

-- ========================================
-- ===== SHERIFF DEAD NOTIF =====
-- ========================================

local function setupSheriffDeadNotif()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterRemoving:Connect(function(character)
                if checkGun(player) then
                    StarterGui:SetCore("SendNotification", {
                        Title = "⚠️ SHERIFF",
                        Text = player.Name .. " is dead!",
                        Duration = 3
                    })
                end
            end)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Died:Connect(function()
                    if checkGun(player) then
                        StarterGui:SetCore("SendNotification", {
                            Title = "⚠️ SHERIFF",
                            Text = player.Name .. " is dead!",
                            Duration = 3
                        })
                    end
                end)
            end
        end)
    end)
end

-- ========================================
-- ===== SKELETON ESP =====
-- ========================================

local SKELETON_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function cacheBoneParts(player)
    if not player or not player.Character then return end
    local parts = {}
    for _, bone in ipairs(SKELETON_BONES) do
        parts[bone[1]] = player.Character:FindFirstChild(bone[1])
        parts[bone[2]] = player.Character:FindFirstChild(bone[2])
    end
    Cache.BoneParts[player.UserId] = parts
end

local function createSkeletonForPlayer(player)
    if not player or player == LocalPlayer or not player.Character then return end
    if Cache.Bones[player.UserId] then return end

    cacheBoneParts(player)

    local bones = {}
    for _, bonePair in ipairs(SKELETON_BONES) do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Transparency = 0.8
        line.Visible = false
        table.insert(bones, {pair = bonePair, line = line})
    end

    Cache.Bones[player.UserId] = bones
end

local function updateSkeletonBone(player, bone1Name, bone2Name, line)
    if not player or not player.Character then
        line.Visible = false
        return false
    end

    local parts = Cache.BoneParts[player.UserId]
    if not parts then
        cacheBoneParts(player)
        parts = Cache.BoneParts[player.UserId]
        if not parts then
            line.Visible = false
            return false
        end
    end

    local bone1 = parts[bone1Name]
    local bone2 = parts[bone2Name]

    if not bone1 or not bone1.Parent then
        bone1 = player.Character:FindFirstChild(bone1Name)
        if bone1 then parts[bone1Name] = bone1 end
    end
    if not bone2 or not bone2.Parent then
        bone2 = player.Character:FindFirstChild(bone2Name)
        if bone2 then parts[bone2Name] = bone2 end
    end

    if not bone1 or not bone2 then
        line.Visible = false
        return false
    end

    local s1, p1 = Camera:WorldToScreenPoint(bone1.Position)
    local s2, p2 = Camera:WorldToScreenPoint(bone2.Position)

    if s1.Z > 0 and s2.Z > 0 then
        line.From = Vector2.new(p1.X, p1.Y)
        line.To = Vector2.new(p2.X, p2.Y)
        line.Visible = true
        line.Color = getRoleColor(player)
        return true
    else
        line.Visible = false
        return false
    end
end

local function updateAllSkeletons()
    for userId, bones in pairs(Cache.Bones) do
        local player = Players:GetPlayerByUserId(userId)
        if not player or not Settings.SkeletonESP then
            for _, bone in ipairs(bones) do
                pcall(function() bone.line:Remove() end)
            end
            Cache.Bones[userId] = nil
            Cache.BoneParts[userId] = nil
        else
            for _, bone in ipairs(bones) do
                updateSkeletonBone(player, bone.pair[1], bone.pair[2], bone.line)
            end
        end
    end
end

local function clearAllSkeletons()
    for userId, bones in pairs(Cache.Bones) do
        for _, bone in ipairs(bones) do
            pcall(function() bone.line:Remove() end)
        end
    end
    Cache.Bones = {}
    Cache.BoneParts = {}
end

-- Восстанавливаем скелетон в апдейт
local oldUpdateVisuals = updateVisuals
updateVisuals = function()
    oldUpdateVisuals()
    if Settings.SkeletonESP then
        updateAllSkeletons()
    end
end

-- ========================================
-- ===== UI TABS =====
-- ========================================

-- RAGE TAB
local RageTab = Window:Tab({ Title = "Rage", Icon = "sword" })
local RageSection = RageTab:Section({ Title = "Rage", Side = "Left" })
local RageSection2 = RageTab:Section({ Title = "Flight", Side = "Right" })

RageSection2:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(value)
        Settings.FlyEnabled = value
        if value then
            startFly()
        else
            stopFly()
        end
    end
})

RageSection2:Input({
    Title = "Fly Speed",
    Default = "100",
    Placeholder = "100",
    Callback = function(value)
        local num = tonumber(value)
        if num then
            Settings.FlySpeed = num
            flySpeed = num
        end
    end
})

RageSection:Toggle({
    Title = "Bunny Hop (AutoJump + Speed)",
    Default = false,
    Callback = function(value)
        BHop.Enabled = value
        Settings.BHopEnabled = value
        setupBHop()
    end
})

RageSection:Input({
    Title = "BHop Speed",
    Default = "50",
    Placeholder = "50",
    Callback = function(value)
        local num = tonumber(value)
        if num then BHop.Speed = math.clamp(num, 10, 100) end
    end
})

RageSection:Toggle({
    Title = "Spin Bot (Anti-Aim)",
    Default = false,
    Callback = function(value)
        SpinBot.Enabled = value
        Settings.SpinBotEnabled = value
        setupSpinBot()
    end
})

RageSection:Input({
    Title = "Spin Speed",
    Default = "9999",
    Placeholder = "9999",
    Callback = function(value)
        local num = tonumber(value)
        if num then SpinBot.Speed = num end
    end
})

-- COMBAT TAB
local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local CombatSection = CombatTab:Section({ Title = "Combat", Side = "Left" })
local CombatSection2 = CombatTab:Section({ Title = "Advanced", Side = "Right" })

local noclipConn = nil

CombatSection:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(value)
        if value then
            noclipConn = RunService.Stepped:Connect(function()
                if not LocalPlayer.Character then return end
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        else
            safeDisconnect(noclipConn)
            noclipConn = nil
        end
    end
})

local antiFlingConn = nil

CombatSection:Toggle({
    Title = "Anti Fling",
    Default = false,
    Callback = function(value)
        if value then
            antiFlingConn = RunService.Heartbeat:Connect(function()
                if not LocalPlayer.Character then return end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local theirHrp = player.Character:FindFirstChild("HumanoidRootPart")
                            if theirHrp then theirHrp.CanCollide = false end
                        end
                    end
                    if hrp.AssemblyLinearVelocity.Magnitude > 150 then
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                    if hrp.AssemblyAngularVelocity.Magnitude > 50 then
                        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        else
            safeDisconnect(antiFlingConn)
            antiFlingConn = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local theirHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if theirHrp then theirHrp.CanCollide = true end
                end
            end
        end
    end
})

CombatSection:Button({
    Title = "Grab Gun",
    Callback = function()
        local gunModel = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol")) then
                gunModel = obj
                break
            end
        end
        if gunModel then
            local handle = gunModel:FindFirstChild("Handle")
            if handle and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0, 3, 0))
                    StarterGui:SetCore("SendNotification", {Title = "Gun", Text = "Teleported!", Duration = 2})
                end
            end
        end
    end
})

CombatSection2:Toggle({
    Title = "Kill Through Wall",
    Default = false,
    Callback = function(value)
        Settings.WallThoughtEnabled = value
        setupWallThought()
    end
})

CombatSection2:Input({
    Title = "Wall Radius",
    Default = "50",
    Placeholder = "50",
    Callback = function(value)
        local num = tonumber(value)
        if num then Settings.WallThoughtRadius = num end
    end
})

-- VISUAL TAB
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local VisualSection = VisualTab:Section({ Title = "ESP", Side = "Left" })
local VisualSection2 = VisualTab:Section({ Title = "Effects", Side = "Right" })

VisualSection:Toggle({
    Title = "ESP Murder",
    Default = false,
    Callback = function(v) Settings.MurderESP = v startMainUpdate() end
})

VisualSection:Toggle({
    Title = "ESP Sheriff",
    Default = false,
    Callback = function(v) Settings.SheriffESP = v startMainUpdate() end
})

VisualSection:Toggle({
    Title = "ESP Innocent",
    Default = false,
    Callback = function(v) Settings.InnocentESP = v startMainUpdate() end
})

VisualSection:Toggle({
    Title = "Chams (Purple, Through Walls)",
    Default = false,
    Callback = function(v)
        Settings.ChamsEnabled = v
        if v then
            for _, player in ipairs(Players:GetPlayers()) do
                cacheCharacterParts(player)
            end
        else
            clearAllChams()
        end
        startMainUpdate()
    end
})

VisualSection:Toggle({
    Title = "Skeleton ESP",
    Default = false,
    Callback = function(v)
        Settings.SkeletonESP = v
        if not v then
            clearAllSkeletons()
        else
            for _, player in ipairs(Players:GetPlayers()) do
                createSkeletonForPlayer(player)
            end
        end
        startMainUpdate()
    end
})

VisualSection2:Toggle({
    Title = "Tracers (Lines to Players)",
    Default = false,
    Callback = function(v)
        Settings.TracersEnabled = v
        if v then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    createTracer(player)
                end
            end
        else
            clearAllTracers()
        end
        startMainUpdate()
    end
})

VisualSection2:Toggle({
    Title = "Jump Circles",
    Default = false,
    Callback = function(v)
        Settings.JumpCircles = v
        setupJumpTracking()
        startMainUpdate()
    end
})

VisualSection2:Toggle({
    Title = "Purple Trail",
    Default = false,
    Callback = function(v)
        Settings.Trails = v
        if v and LocalPlayer.Character then
            createLocalPlayerTrail()
        end
        startMainUpdate()
    end
})

VisualSection2:Toggle({
    Title = "RGB Humanoid",
    Default = false,
    Callback = function(v)
        Settings.RGBHumanoid = v
        setupRGBHumanoid()
    end
})

VisualSection2:Toggle({
    Title = "XRay",
    Default = false,
    Callback = function(v)
        Settings.XRayEnabled = v
        setupXRay()
    end
})

VisualSection2:Toggle({
    Title = "Crosshair ꩜",
    Default = false,
    Callback = function(v)
        Settings.CrosshairEnabled = v
        if v then
            createCrosshair()
        else
            if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
            safeDisconnect(shiftLockConn)
            shiftLockConn = nil
            local shiftLock = LocalPlayer.PlayerGui:FindFirstChild("ShiftLock")
            if shiftLock then
                shiftLock.Enabled = true
            end
        end
    end
})

-- AUTO FARM TAB
local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "star" })
local AutoFarmSection = AutoFarmTab:Section({ Title = "Farm Settings", Side = "Left" })
local AutoFarmSection2 = AutoFarmTab:Section({ Title = "Config", Side = "Right" })

AutoFarmSection:Toggle({
    Title = "Auto Farm",
    Default = false,
    Callback = function(v)
        Settings.AutoFarmEnabled = v
        setupAutoFarm()
    end
})

AutoFarmSection:Toggle({
    Title = "Auto Respawn (Full Bag)",
    Default = false,
    Callback = function(v)
        Settings.AutoRespawn = v
    end
})

AutoFarmSection2:Input({
    Title = "Farm Speed",
    Default = "20",
    Placeholder = "20",
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.AutoFarmSpeed = num end
    end
})

AutoFarmSection2:Input({
    Title = "Coin Limit",
    Default = "40",
    Placeholder = "40",
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.AutoFarmCoinLimit = num end
    end
})

AutoFarmSection2:Input({
    Title = "Coin Delay",
    Default = "0.15",
    Placeholder = "0.15",
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.AutoFarmCoinDelay = num end
    end
})

-- ANTI-AFK TAB
local AntiAFKTab = Window:Tab({ Title = "Anti-AFK", Icon = "timer" })
local AntiAFKSection = AntiAFKTab:Section({ Title = "AFK Protection", Side = "Left" })

AntiAFKSection:Toggle({
    Title = "Anti-AFK",
    Default = false,
    Callback = function(v)
        Settings.AntiAFKEnabled = v
        setupAntiAFK()
    end
})

-- PROFILE TAB
local ProfileTab = Window:Tab({ Title = "Profile", Icon = "user" })
local ProfileSection = ProfileTab:Section({ Title = "Player Info", Side = "Left" })

local function updatePlayerInfo()
    pcall(function()
        ProfileSection:Clear()

        local username = LocalPlayer.Name
        local userId = LocalPlayer.UserId
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local health = humanoid and humanoid.Health or 0
        local maxHealth = humanoid and humanoid.MaxHealth or 100

        ProfileSection:Label({
            Title = "Nickname: " .. username,
            Description = "ID: " .. userId,
            Icon = "user"
        })

        ProfileSection:Label({
            Title = "Health: " .. math.floor(health) .. "/" .. maxHealth,
            Description = "Status: " .. (health > 0 and "✅ Alive" or "❌ Dead"),
            Icon = "heart"
        })
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updatePlayerInfo()
end)

task.spawn(function()
    while true do
        updatePlayerInfo()
        task.wait(1)
    end
end)

updatePlayerInfo()

-- SETTINGS TAB
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "gear" })
local SettingsSection = SettingsTab:Section({ Title = "Settings", Side = "Left" })

SettingsSection:Label({
    Title = "PlanetHub v3.0 FINAL",
    Description = "By MMV and MM2",
    Icon = "crown"
})

SettingsSection:Button({
    Title = "Close UI",
    Callback = function() Window:Destroy() end
})

SettingsSection:Button({
    Title = "Rejoin Game",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ========================================
-- ===== ИНИЦИАЛИЗАЦИЯ =====
-- ========================================

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Settings.SkeletonESP then
            createSkeletonForPlayer(player)
        end
        if Settings.ChamsEnabled then
            cacheCharacterParts(player)
        end
        if Settings.JumpCircles then
            Cache.JumpTracking[player.UserId] = {wasJumping = false}
        end
        if Settings.TracersEnabled and player ~= LocalPlayer then
            createTracer(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    Cache.BoneParts[player.UserId] = nil
    Cache.ChamsPartsList[player.UserId] = nil
    if Cache.Bones[player.UserId] then
        for _, bone in ipairs(Cache.Bones[player.UserId]) do
            pcall(function() bone.line:Remove() end)
        end
        Cache.Bones[player.UserId] = nil
    end
    Cache.Highlights[player.UserId] = nil
    if Cache.Tracers[player.UserId] then
        pcall(function() Cache.Tracers[player.UserId]:Remove() end)
        Cache.Tracers[player.UserId] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllHighlights()
    clearAllChams()
    clearAllSkeletons()
    clearAllTracers()

    Cache.BoneParts = {}
    Cache.ChamsPartsList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if Settings.ChamsEnabled then
            cacheCharacterParts(player)
        end
        if Settings.SkeletonESP then
            createSkeletonForPlayer(player)
        end
        if Settings.TracersEnabled and player ~= LocalPlayer then
            createTracer(player)
        end
    end

    setupRGBHumanoid()
    updatePlayerInfo()

    if Settings.JumpCircles then
        setupJumpTracking()
    end

    if Settings.Trails then
        createLocalPlayerTrail()
    end

    if Settings.FlyEnabled then
        task.wait(0.5)
        startFly()
    end

    if Settings.CrosshairEnabled then
        createCrosshair()
    end
end)

startMainUpdate()
setupJumpTracking()
setupSheriffDeadNotif()

print("✅ PlanetHub v3.0 FINAL Loaded!")
StarterGui:SetCore("SendNotification", {
    Title = "Welcome",
    Text = "PlanetHub v3.0 | Chams + Tracers + Crosshair",
    Duration = 5
})
