-- ========================================
-- ===== PLANT HUB v3.0 ULTIMATE =====
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")

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
    BloomEnabled = false,
    ColorCorrectionEnabled = false,
    VignetteEnabled = false,
    CustomSkyId = "",
    KillAllEnabled = false,

    -- FOV Aimbot
    FovAimbotEnabled = false,
    FovRadius = 120,
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
    PostEffects = {},
    JumpTracking = {},
    RGBConnection = nil,
    AutoFarmConnection = nil,
    CurrentTween = nil,
    XRayParts = {},
    Tracers = {},
    TrailAttachments = {},
    KillAllConnection = nil,
    Knife = nil,

    -- FOV
    FovCircle = nil,
    FovConnection = nil,
    AimbotConnection = nil,

    -- Kill All
    KillAllAutoClicker = nil,
    KillAllActive = false,
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
-- ===== CHAMS =====
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
            part.LocalTransparencyModifier = 0
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
-- ===== ESP =====
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
-- ===== TRACERS =====
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
        local head = player.Character:FindFirstChild("Head")
        if not head then
            line.Visible = false
            continue
        end
        local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
        if not onScreen or screenPos.Z < 0 then
            line.Visible = false
            continue
        end
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
-- ===== TRAILS =====
-- ========================================

local function createLocalPlayerTrail()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if Cache.TrailAttachments["trail"] and Cache.TrailAttachments["trail"].Parent then return end

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
    Cache.TrailAttachments = {trail = trail, att1 = att1, att2 = att2}
end

local function removeLocalPlayerTrail()
    if Cache.TrailAttachments.trail then
        pcall(function() Cache.TrailAttachments.trail:Destroy() end)
    end
    if Cache.TrailAttachments.att1 then
        pcall(function() Cache.TrailAttachments.att1:Destroy() end)
    end
    if Cache.TrailAttachments.att2 then
        pcall(function() Cache.TrailAttachments.att2:Destroy() end)
    end
    Cache.TrailAttachments = {}
end

-- ========================================
-- ===== SHADERS =====
-- ========================================

local function setupBloom(enabled)
    Lighting.Brightness = enabled and 1.5 or 1
end

local function setupColorCorrection(enabled)
    if enabled then
        Lighting.Ambient = COLORS.Purple
        Lighting.OutdoorAmbient = COLORS.Purple
    else
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    end
end

local function setupVignette(enabled)
    if enabled then
        if not Cache.PostEffects["vignette"] then
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "VignetteEffect"
            screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true
            local vignette = Instance.new("Frame")
            vignette.Size = UDim2.new(1, 0, 1, 0)
            vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            vignette.BackgroundTransparency = 0.5
            vignette.BorderSizePixel = 0
            vignette.Parent = screenGui
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            Cache.PostEffects["vignette"] = screenGui
        end
    else
        if Cache.PostEffects["vignette"] then
            pcall(function() Cache.PostEffects["vignette"]:Destroy() end)
            Cache.PostEffects["vignette"] = nil
        end
    end
end

local function setupSky(skyId)
    if skyId == "" then return end
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    if not skyId:find("rbxassetid://") then
        skyId = "rbxassetid://" .. skyId
    end
    pcall(function()
        sky.SkyboxBk = skyId
        sky.SkyboxDn = skyId
        sky.SkyboxFt = skyId
        sky.SkyboxLf = skyId
        sky.SkyboxRt = skyId
        sky.SkyboxUp = skyId
    end)
    StarterGui:SetCore("SendNotification", {
        Title = "Sky",
        Text = "Sky applied! ✅",
        Duration = 2
    })
end

-- ========================================
-- ===== CROSSHAIR =====
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
-- ===== FOV AIMBOT =====
-- ========================================

-- Получить позицию с предсказанием (predict 0.4s)
local PREDICT_TIME = 0.4

local function getPredictedPosition(player)
    if not player or not player.Character then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    -- Берём текущую скорость персонажа и добавляем смещение
    local velocity = hrp.AssemblyLinearVelocity
    local predictedPos = hrp.Position + (velocity * PREDICT_TIME)
    return predictedPos
end

-- Найти ближайшего Murder в FOV
local function getNearestMurderInFov()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestPlayer = nil
    local closestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not checkKnife(player) then continue end
        if not player.Character then continue end

        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Предсказываем позицию
        local predictedPos = getPredictedPosition(player)
        if not predictedPos then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(predictedPos)
        if not onScreen or screenPos.Z < 0 then continue end

        local screenVec = Vector2.new(screenPos.X, screenPos.Y)
        local dist = (center - screenVec).Magnitude

        -- Только если в FOV круге
        if dist <= Settings.FovRadius and dist < closestDist then
            closestDist = dist
            closestPlayer = {
                player = player,
                screenPos = screenVec,
                worldPos = predictedPos,
                dist = dist,
            }
        end
    end

    return closestPlayer
end

-- Создаём FOV круг (Drawing)
local function createFovCircle()
    if Cache.FovCircle then
        pcall(function() Cache.FovCircle:Remove() end)
        Cache.FovCircle = nil
    end

    local circle = Drawing.new("Circle")
    circle.Radius = Settings.FovRadius
    circle.Color = Color3.fromRGB(255, 255, 255)
    circle.Thickness = 1.5
    circle.Transparency = 0.7
    circle.Filled = false
    circle.Visible = false
    circle.NumSides = 64
    Cache.FovCircle = circle
    return circle
end

-- Обновляем FOV круг + аимбот
local function setupFovAimbot()
    safeDisconnect(Cache.FovConnection)
    safeDisconnect(Cache.AimbotConnection)
    Cache.FovConnection = nil
    Cache.AimbotConnection = nil

    if Cache.FovCircle then
        Cache.FovCircle.Visible = false
    end

    if not Settings.FovAimbotEnabled then return end

    local circle = Cache.FovCircle
    if not circle then
        circle = createFovCircle()
    end

    -- Центр экрана
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    Cache.FovConnection = RunService.RenderStepped:Connect(function()
        if not Settings.FovAimbotEnabled then
            circle.Visible = false
            return
        end

        -- Обновляем центр (на случай изменения размера экрана)
        center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        circle.Position = center
        circle.Radius = Settings.FovRadius
        circle.Visible = true

        -- Ищем таргет
        local target = getNearestMurderInFov()

        if target then
            -- Меняем цвет круга на красный когда есть таргет
            circle.Color = Color3.fromRGB(255, 50, 50)
            circle.Thickness = 2

            -- Smoothness = 0 → мгновенная наводка
            -- Наводим камеру прямо на предсказанную позицию
            local _, _, depth = Camera:WorldToScreenPoint(target.worldPos)
            if depth > 0 then
                -- Вычисляем дельту от центра экрана к таргету
                local deltaX = target.screenPos.X - center.X
                local deltaY = target.screenPos.Y - center.Y

                -- Конвертируем смещение экрана в поворот камеры
                -- ViewportSize / (2 * tan(FOV/2)) = focal length
                local fov = math.rad(Camera.FieldOfView)
                local focalLength = (Camera.ViewportSize.Y / 2) / math.tan(fov / 2)

                local angleX = math.atan(deltaX / focalLength)
                local angleY = math.atan(deltaY / focalLength)

                -- Smoothness = 0 → мгновенно
                Camera.CFrame = Camera.CFrame
                    * CFrame.Angles(0, -angleX, 0)
                    * CFrame.Angles(-angleY, 0, 0)
            end
        else
            -- Нет таргета — белый круг
            circle.Color = Color3.fromRGB(255, 255, 255)
            circle.Thickness = 1.5
        end
    end)
end

-- ========================================
-- ===== KILL ALL (RemoteEvent + AutoClicker) =====
-- ========================================

local function getKnife()
    if not LocalPlayer.Character then return nil end
    for _, item in ipairs(LocalPlayer.Character:GetDescendants()) do
        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then
            return item
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then
                return item
            end
        end
    end
    return nil
end

-- Ищем RemoteEvent для убийства в игре MM2
local function findKillRemote()
    -- Типичные пути в MM2 для Kill Remote
    local paths = {
        ReplicatedStorage:FindFirstChild("KillPlayer"),
        ReplicatedStorage:FindFirstChild("Murder"),
        ReplicatedStorage:FindFirstChild("Stab"),
        ReplicatedStorage:FindFirstChild("KnifeHit"),
        ReplicatedStorage:FindFirstChild("HitPlayer"),
    }

    for _, remote in ipairs(paths) do
        if remote and remote:IsA("RemoteEvent") then
            return remote
        end
    end

    -- Ищем во всех children
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name:lower()
            if name:find("kill") or name:find("stab") or name:find("knife") or name:find("murder") or name:find("hit") then
                return obj
            end
        end
    end

    return nil
end

local killAllRunning = false

local function stopKillAll()
    killAllRunning = false
    Cache.KillAllActive = false
    safeDisconnect(Cache.KillAllAutoClicker)
    Cache.KillAllAutoClicker = nil
end

local function killAllPlayers()
    if killAllRunning then
        stopKillAll()
        StarterGui:SetCore("SendNotification", {
            Title = "Kill All",
            Text = "⏹ Остановлено!",
            Duration = 2
        })
        return
    end

    local knife = getKnife()
    if not knife then
        StarterGui:SetCore("SendNotification", {
            Title = "Kill All",
            Text = "❌ Нож не найден! Ты не Murder?",
            Duration = 3
        })
        return
    end

    local killRemote = findKillRemote()

    killAllRunning = true
    Cache.KillAllActive = true

    StarterGui:SetCore("SendNotification", {
        Title = "Kill All",
        Text = "🔪 Kill All запущен!",
        Duration = 2
    })

    task.spawn(function()
        while killAllRunning do
            if not LocalPlayer.Character then
                task.wait(1)
                continue
            end

            local targets = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer
                    and player.Character
                    and player.Character:FindFirstChild("HumanoidRootPart")
                    and player.Character:FindFirstChildOfClass("Humanoid")
                    and player.Character.Humanoid.Health > 0
                then
                    table.insert(targets, player)
                end
            end

            if #targets == 0 then
                task.wait(1)
                continue
            end

            for _, target in ipairs(targets) do
                if not killAllRunning then break end
                if not target.Character then continue end
                if not target.Character:FindFirstChild("HumanoidRootPart") then continue end
                if not target.Character:FindFirstChildOfClass("Humanoid") then continue end
                if target.Character.Humanoid.Health <= 0 then continue end

                local targetHRP = target.Character.HumanoidRootPart
                local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then continue end

                -- 1. Локальная телепортация к игроку
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1.5)
                task.wait(0.05)

                -- 2. Берём нож в руку
                local currentKnife = getKnife()
                if currentKnife then
                    pcall(function()
                        LocalPlayer.Character.Humanoid:EquipTool(currentKnife)
                    end)
                end
                task.wait(0.1)

                -- 3. Пробуем RemoteEvent
                if killRemote then
                    pcall(function()
                        killRemote:FireServer(target)
                    end)
                    pcall(function()
                        killRemote:FireServer(target.Character)
                    end)
                    pcall(function()
                        killRemote:FireServer(targetHRP)
                    end)
                end

                -- 4. Автокликер (симуляция ударов ножом)
                -- Запускаем быстрые клики пока цель жива
                local clickCount = 0
                local maxClicks = 8
                while killAllRunning
                    and target.Character
                    and target.Character:FindFirstChildOfClass("Humanoid")
                    and target.Character.Humanoid.Health > 0
                    and clickCount < maxClicks
                do
                    -- ЛКМ вниз
                    pcall(function()
                        mouse1press()
                    end)
                    task.wait(0.03)
                    -- ЛКМ вверх
                    pcall(function()
                        mouse1release()
                    end)
                    task.wait(0.05)

                    -- Также через VirtualInput
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end)

                    -- firetouchinterest на HRP цели
                    if myHRP and targetHRP then
                        pcall(function()
                            firetouchinterest(myHRP, targetHRP, 0)
                            task.wait(0.02)
                            firetouchinterest(myHRP, targetHRP, 1)
                        end)
                    end

                    clickCount = clickCount + 1
                    task.wait(0.05)
                end

                task.wait(0.2)
            end

            task.wait(0.5)
        end

        stopKillAll()
    end)
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
-- ===== AUTO FARM =====
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
                        table.insert(coins, {part = coin, distance = distance})
                    end
                end
            end
        end
    end

    table.sort(coins, function(a, b) return a.distance < b.distance end)
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
    if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end

    Cache.CurrentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
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
    if getCurrentCoins() >= Settings.AutoFarmCoinLimit then
        pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
        StarterGui:SetCore("SendNotification", {Title = "AutoFarm", Text = "💀 Респавн!", Duration = 2})
        return true
    end
    return false
end

local function farmLoop()
    while Settings.AutoFarmEnabled do
        local character = LocalPlayer.Character
        if not character then task.wait(1) continue end

        local currentCoins = getCurrentCoins()
        if currentCoins >= Settings.AutoFarmCoinLimit then
            if Settings.AutoRespawn then
                autoRespawn()
                task.wait(5)
                continue
            else
                Settings.AutoFarmEnabled = false
                StarterGui:SetCore("SendNotification", {Title = "AutoFarm", Text = "CoinBag полный! ✅", Duration = 3})
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
        StarterGui:SetCore("SendNotification", {Title = "AutoFarm", Text = "Автофарм включен! 🚀", Duration = 3})
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

local function stopFly()
    isFlying = false
    safeDisconnect(flyConnection)
    flyConnection = nil
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
    workspace.Gravity = originalGravity
    if flyBodyVelocity then pcall(function() flyBodyVelocity:Destroy() end) flyBodyVelocity = nil end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) flyBodyGyro = nil end
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
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBodyGyro.P = 1000
    flyBodyGyro.D = 100
    flyBodyGyro.Parent = hrp

    safeDisconnect(flyConnection)
    flyConnection = RunService.RenderStepped:Connect(function()
        if not isFlying or not character or not character.Parent or not hrp or not hrp.Parent then
            stopFly()
            return
        end

        local camCF = Camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * Settings.FlySpeed
        end

        flyBodyVelocity.Velocity = moveDir
        flyBodyGyro.CFrame = camCF
    end)
end

-- ========================================
-- ===== BUNNY HOP =====
-- ========================================

local BHop = { Enabled = false, Speed = 50 }
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

local SpinBot = { Enabled = false, Speed = 9999 }
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
            if Settings.ChamsEnabled then applyChams(player)
            elseif Cache.ChamsPartsList[player.UserId] then removeChams(player) end
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

            if Settings.ChamsEnabled then applyChams(player)
            elseif Cache.ChamsPartsList[player.UserId] then removeChams(player) end

            if Settings.TracersEnabled then
                if not Cache.Tracers[player.UserId] then createTracer(player) end
            end
        end
    end

    if Settings.TracersEnabled then updateTracers()
    else clearAllTracers() end

    if Settings.Trails then
        if LocalPlayer.Character then createLocalPlayerTrail() end
    else
        removeLocalPlayerTrail()
    end
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
    if not player or not player.Character then line.Visible = false return false end
    local parts = Cache.BoneParts[player.UserId]
    if not parts then
        cacheBoneParts(player)
        parts = Cache.BoneParts[player.UserId]
        if not parts then line.Visible = false return false end
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

    if not bone1 or not bone2 then line.Visible = false return false end

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
            for _, bone in ipairs(bones) do pcall(function() bone.line:Remove() end) end
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
        for _, bone in ipairs(bones) do pcall(function() bone.line:Remove() end) end
    end
    Cache.Bones = {}
    Cache.BoneParts = {}
end

local function startMainUpdate()
    safeDisconnect(mainUpdateConnection)
    mainUpdateConnection = RunService.Heartbeat:Connect(function()
        local anyActive = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP or
                          Settings.ChamsEnabled or Settings.Trails or Settings.TracersEnabled
        if anyActive then updateVisuals() end
        if Settings.JumpCircles then updateJumpCircles() end
        if Settings.SkeletonESP then updateAllSkeletons() end
    end)
end

-- ========================================
-- ===== SHERIFF DEAD NOTIF =====
-- ========================================

local function setupSheriffDeadNotif()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterRemoving:Connect(function()
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
        if value then startFly() else stopFly() end
    end
})

RageSection2:Input({
    Title = "Fly Speed",
    Default = "100",
    Placeholder = "100",
    Callback = function(value)
        local num = tonumber(value)
        if num then Settings.FlySpeed = num end
    end
})

RageSection:Toggle({
    Title = "Bunny Hop",
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

-- Kill All кнопка (обновлённая)
CombatSection:Button({
    Title = "🔪 Kill All (Murder Only)",
    Callback = function()
        killAllPlayers()
    end
})

-- ========================================
-- ===== FOV AIMBOT SECTION =====
-- ========================================

CombatSection2:Toggle({
    Title = "FOV Aimbot (Murder Only)",
    Default = false,
    Callback = function(value)
        Settings.FovAimbotEnabled = value
        if value then
            createFovCircle()
        end
        setupFovAimbot()
    end
})

CombatSection2:Input({
    Title = "FOV Radius",
    Default = "120",
    Placeholder = "120",
    Callback = function(value)
        local num = tonumber(value)
        if num then
            Settings.FovRadius = math.clamp(num, 10, 600)
            -- Обновляем размер круга сразу
            if Cache.FovCircle then
                Cache.FovCircle.Radius = Settings.FovRadius
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

VisualSection:Toggle({Title = "ESP Murder", Default = false, Callback = function(v) Settings.MurderESP = v startMainUpdate() end})
VisualSection:Toggle({Title = "ESP Sheriff", Default = false, Callback = function(v) Settings.SheriffESP = v startMainUpdate() end})
VisualSection:Toggle({Title = "ESP Innocent", Default = false, Callback = function(v) Settings.InnocentESP = v startMainUpdate() end})

VisualSection:Toggle({
    Title = "Chams (Purple, Through Walls)",
    Default = false,
    Callback = function(v)
        Settings.ChamsEnabled = v
        if v then
            for _, player in ipairs(Players:GetPlayers()) do cacheCharacterParts(player) end
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
            for _, player in ipairs(Players:GetPlayers()) do createSkeletonForPlayer(player) end
        end
        startMainUpdate()
    end
})

VisualSection2:Toggle({
    Title = "Tracers (Lines to Head)",
    Default = false,
    Callback = function(v)
        Settings.TracersEnabled = v
        if v then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then createTracer(player) end
            end
        else
            clearAllTracers()
        end
        startMainUpdate()
    end
})

VisualSection2:Toggle({Title = "Jump Circles", Default = false, Callback = function(v) Settings.JumpCircles = v setupJumpTracking() startMainUpdate() end})

VisualSection2:Toggle({
    Title = "Purple Trail (Persistent)",
    Default = false,
    Callback = function(v)
        Settings.Trails = v
        if v then createLocalPlayerTrail() else removeLocalPlayerTrail() end
        startMainUpdate()
    end
})

VisualSection2:Toggle({Title = "RGB Humanoid", Default = false, Callback = function(v) Settings.RGBHumanoid = v setupRGBHumanoid() end})
VisualSection2:Toggle({Title = "XRay", Default = false, Callback = function(v) Settings.XRayEnabled = v setupXRay() end})

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
        end
    end
})

-- SHADERS TAB
local ShadersTab = Window:Tab({ Title = "Shaders", Icon = "wand" })
local ShadersSection = ShadersTab:Section({ Title = "Post-Effects", Side = "Left" })

ShadersSection:Toggle({Title = "Bloom", Default = false, Callback = function(v) Settings.BloomEnabled = v setupBloom(v) end})
ShadersSection:Toggle({Title = "Color Correction (Purple)", Default = false, Callback = function(v) Settings.ColorCorrectionEnabled = v setupColorCorrection(v) end})
ShadersSection:Toggle({Title = "Vignette", Default = false, Callback = function(v) Settings.VignetteEnabled = v setupVignette(v) end})

-- ========================================
-- ===== SKY TAB (С ШАБЛОНАМИ) =====
-- ========================================

local SkyTab = Window:Tab({ Title = "Sky", Icon = "cloud" })
local SkySection = SkyTab:Section({ Title = "Custom Sky", Side = "Left" })
local SkyTemplates = SkyTab:Section({ Title = "Sky Templates", Side = "Right" })

SkySection:Input({
    Title = "Sky ID",
    Default = "",
    Placeholder = "rbxassetid://...",
    Callback = function(v) Settings.CustomSkyId = v end
})

SkySection:Button({
    Title = "Apply Custom Sky",
    Callback = function()
        if Settings.CustomSkyId ~= "" then
            setupSky(Settings.CustomSkyId)
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Sky",
                Text = "❌ Введи Sky ID!",
                Duration = 2
            })
        end
    end
})

SkySection:Button({
    Title = "Remove Sky",
    Callback = function()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then
            sky:Destroy()
            StarterGui:SetCore("SendNotification", {
                Title = "Sky",
                Text = "Sky removed! ✅",
                Duration = 2
            })
        end
    end
})

-- Шаблоны (ниже Custom Sky, в правой секции)
SkyTemplates:Button({
    Title = "🐹 Добрый хомяк",
    Callback = function()
        setupSky("135457808082953")
    end
})

SkyTemplates:Button({
    Title = "🌩 Ночные тучи",
    Callback = function()
        setupSky("100140210065251")
    end
})

SkyTemplates:Button({
    Title = "🚀 Космос",
    Callback = function()
        setupSky("97059048850342")
    end
})

-- AUTO FARM TAB
local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "star" })
local AutoFarmSection = AutoFarmTab:Section({ Title = "Farm Settings", Side = "Left" })
local AutoFarmSection2 = AutoFarmTab:Section({ Title = "Config", Side = "Right" })

AutoFarmSection:Toggle({
    Title = "Auto Farm",
    Default = false,
    Callback = function(v) Settings.AutoFarmEnabled = v setupAutoFarm() end
})

AutoFarmSection:Toggle({
    Title = "Auto Respawn (Full Bag)",
    Default = false,
    Callback = function(v) Settings.AutoRespawn = v end
})

AutoFarmSection2:Input({Title = "Farm Speed", Default = "20", Placeholder = "20", Callback = function(v) local n = tonumber(v) if n then Settings.AutoFarmSpeed = n end end})
AutoFarmSection2:Input({Title = "Coin Limit", Default = "40", Placeholder = "40", Callback = function(v) local n = tonumber(v) if n then Settings.AutoFarmCoinLimit = n end end})
AutoFarmSection2:Input({Title = "Coin Delay", Default = "0.15", Placeholder = "0.15", Callback = function(v) local n = tonumber(v) if n then Settings.AutoFarmCoinDelay = n end end})

-- ANTI-AFK TAB
local AntiAFKTab = Window:Tab({ Title = "Anti-AFK", Icon = "timer" })
local AntiAFKSection = AntiAFKTab:Section({ Title = "AFK Protection", Side = "Left" })

AntiAFKSection:Toggle({
    Title = "Anti-AFK",
    Default = false,
    Callback = function(v) Settings.AntiAFKEnabled = v setupAntiAFK() end
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
        local hasKnife = getKnife() ~= nil

        ProfileSection:Label({Title = "Nickname: " .. username, Description = "ID: " .. userId, Icon = "user"})
        ProfileSection:Label({
            Title = "Health: " .. math.floor(health) .. "/" .. maxHealth,
            Description = "Status: " .. (health > 0 and "✅ Alive" or "❌ Dead"),
            Icon = "heart"
        })
        ProfileSection:Label({
            Title = "Knife: " .. (hasKnife and "✅ Yes" or "❌ No"),
            Description = hasKnife and "Ready to kill!" or "Find a knife!",
            Icon = "sword"
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

SettingsSection:Label({Title = "PlanetHub v3.0 ULTIMATE", Description = "By MMV and MM2", Icon = "crown"})

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
-- ===== PLAYER EVENTS =====
-- ========================================

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Settings.SkeletonESP then createSkeletonForPlayer(player) end
        if Settings.ChamsEnabled then cacheCharacterParts(player) applyChams(player) end
        if Settings.JumpCircles then Cache.JumpTracking[player.UserId] = {wasJumping = false} end
        if Settings.TracersEnabled and player ~= LocalPlayer then createTracer(player) end
        if Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP then
            local role = getRole(player)
            if Settings.MurderESP and role == "Murder" then createOrUpdateHighlight(player, COLORS.Murder)
            elseif Settings.SheriffESP and role == "Sheriff" then createOrUpdateHighlight(player, COLORS.Sheriff)
            elseif Settings.InnocentESP and role == "Innocent" then createOrUpdateHighlight(player, COLORS.Innocent) end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    Cache.BoneParts[player.UserId] = nil
    Cache.ChamsPartsList[player.UserId] = nil
    if Cache.Bones[player.UserId] then
        for _, bone in ipairs(Cache.Bones[player.UserId]) do pcall(function() bone.line:Remove() end) end
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
        if Settings.ChamsEnabled then cacheCharacterParts(player) applyChams(player) end
        if Settings.SkeletonESP then createSkeletonForPlayer(player) end
        if Settings.TracersEnabled and player ~= LocalPlayer then createTracer(player) end
        if Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP then
            local role = getRole(player)
            if Settings.MurderESP and role == "Murder" then createOrUpdateHighlight(player, COLORS.Murder)
            elseif Settings.SheriffESP and role == "Sheriff" then createOrUpdateHighlight(player, COLORS.Sheriff)
            elseif Settings.InnocentESP and role == "Innocent" then createOrUpdateHighlight(player, COLORS.Innocent) end
        end
    end

    setupRGBHumanoid()
    updatePlayerInfo()
    if Settings.JumpCircles then setupJumpTracking() end
    if Settings.Trails then createLocalPlayerTrail() end
    if Settings.FlyEnabled then task.wait(0.5) startFly() end
    if Settings.CrosshairEnabled then createCrosshair() end
    if Settings.FovAimbotEnabled then setupFovAimbot() end
end)

-- ========================================
-- ===== ИНИЦИАЛИЗАЦИЯ =====
-- ========================================

startMainUpdate()
setupJumpTracking()
setupSheriffDeadNotif()
createFovCircle()

print("✅ PlanetHub v3.0 ULTIMATE Loaded!")
StarterGui:SetCore("SendNotification", {
    Title = "Welcome",
    Text = "PlanetHub v3.0 | FOV Aimbot + Kill All v2 + Sky Templates",
    Duration = 5
})
