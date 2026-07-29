-- ========================================
-- ===== WIND UI ХАБ =====
-- ========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

WindUI:SetTheme("Dark")
WindUI.TransparencyValue = 0.1

local Window = WindUI:CreateWindow({
    Title = "Murder Hub",
    Author = "Vibe Coder",
    Icon = "crown",
    Folder = "MurderHubSettings",
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
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========================================
-- ===== НАСТРОЙКИ =====
-- ========================================

local Settings = {
    -- ESP
    MurderESP = false,
    SheriffESP = false,
    InnocentESP = false,
    SkeletonESP = false,
    
    -- Chams
    ChamsEnabled = false,
    ChamsMurder = false,
    ChamsSheriff = false,
    ChamsInnocent = false,
    ChamsThickness = 0.2,
    
    -- Box
    BoxMurder = false,
    BoxSheriff = false,
    BoxInnocent = false,
    BoxThickness = 0.05,
    
    -- Visuals
    JumpCircles = false,
    Trails = false,
    FogEnabled = false,
    
    -- Particles
    ParticlesEnabled = false,
    ParticleType = "rain",
    ParticleCount = 50,
    ParticleSize = 0.3,
    ParticleSpeed = 1,
    ParticleLifetime = 5,
    
    -- Shaders
    BloomEnabled = false,
    BloomIntensity = 1,
    ColorCorrectionEnabled = false,
    ColorCorrectionTint = Color3.fromRGB(138, 43, 226),
    ColorCorrectionSaturation = 1,
    ColorCorrectionBrightness = 0,
    BlurEnabled = false,
    BlurSize = 10,
    DepthOfFieldEnabled = false,
    DepthOfFieldBlur = 5,
    VignetteEnabled = false,
    VignetteIntensity = 0.3,
    SunRaysEnabled = false,
    
    -- Sky
    CustomSkyId = "",
    
    -- Other
    CrosshairEnabled = false,
    KillIndicatorEnabled = false,
    KillSound = false,
    
    -- Rage
    FlyEnabled = false,
    FlySpeed = 80,
    BHopEnabled = false,
    SpinBotEnabled = false,
    SpinSpeed = 5,
    SilentAimEnabled = false,
    SilentAimFOV = 150,
    
    -- Combat
    NoclipEnabled = false,
    AntiFlingEnabled = false,
    FOVChanger = 70
}

-- ========================================
-- ===== КЭШИ =====
-- ========================================

local Cache = {
    Highlights = {},
    Boxes = {},
    Bones = {},
    Visuals = {},
    Connections = {},
    ChamsParts = {},
    Particles = {},
    PostEffects = {}
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
-- ===== CHAMS (ЧЕРЕЗ СТЕНУ) =====
-- ========================================

local function applyChams(player)
    if not player or not player.Character then return end
    
    local parts = Cache.ChamsParts[player.UserId] or {}
    
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not parts[part] then
                parts[part] = {
                    ogMaterial = part.Material,
                    ogColor = part.Color,
                    ogTransparency = part.Transparency,
                }
            end
            
            if Settings.ChamsEnabled then
                part.Material = Enum.Material.Neon
                part.Color = COLORS.Purple
                part.Transparency = Settings.ChamsThickness
            end
        end
    end
    
    Cache.ChamsParts[player.UserId] = parts
end

local function removeChams(player)
    if not player or not player.Character then return end
    
    local parts = Cache.ChamsParts[player.UserId]
    if not parts then return end
    
    for part, data in pairs(parts) do
        if part and part.Parent then
            pcall(function()
                part.Material = data.ogMaterial
                part.Color = data.ogColor
                part.Transparency = data.ogTransparency
            end)
        end
    end
    
    Cache.ChamsParts[player.UserId] = nil
end

local function clearAllChams()
    for userId, parts in pairs(Cache.ChamsParts) do
        for part, data in pairs(parts) do
            if part and part.Parent then
                pcall(function()
                    part.Material = data.ogMaterial
                    part.Color = data.ogColor
                    part.Transparency = data.ogTransparency
                end)
            end
        end
    end
    Cache.ChamsParts = {}
end

-- ========================================
-- ===== BOX ESP (РАБОЧИЙ) =====
-- ========================================

local boxUpdateConnection = nil

local function updateBoxDisplay(player, color)
    if not player or not player.Character then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local boxKey = "box_" .. player.UserId
    local boxData = Cache.Boxes[boxKey]
    
    if not boxData then
        -- Создаём 8 углов для box'а
        local corners = {}
        for i = 1, 8 do
            local corner = Drawing.new("Line")
            corner.Color = color
            corner.Thickness = Settings.BoxThickness * 100
            corner.Transparency = 0.7
            corner.Visible = false
            table.insert(corners, corner)
        end
        
        boxData = {
            corners = corners,
            color = color,
            lastUpdate = tick()
        }
        Cache.Boxes[boxKey] = boxData
    else
        boxData.color = color
    end
end

local function drawBox3D(player, color)
    if not player or not player.Character then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local boxKey = "box_" .. player.UserId
    local boxData = Cache.Boxes[boxKey]
    
    if not boxData then return end
    
    local corners = boxData.corners
    local size = Vector3.new(3, 6, 3)
    local position = hrp.Position
    
    -- 8 углов куба
    local offsets = {
        Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(size.X/2, size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
        Vector3.new(size.X/2, -size.Y/2, size.Z/2),
        Vector3.new(size.X/2, size.Y/2, size.Z/2),
        Vector3.new(-size.X/2, size.Y/2, size.Z/2),
    }
    
    local screenPoints = {}
    for i, offset in ipairs(offsets) do
        local worldPos = position + offset
        local screenPos, onScreen = Camera:WorldToScreenPoint(worldPos)
        if onScreen then
            screenPoints[i] = Vector2.new(screenPos.X, screenPos.Y)
        else
            screenPoints[i] = nil
        end
    end
    
    -- Рисуем линии между углами
    if screenPoints[1] and screenPoints[2] then
        corners[1].From = screenPoints[1]
        corners[1].To = screenPoints[2]
        corners[1].Visible = true
    end
    if screenPoints[2] and screenPoints[3] then
        corners[2].From = screenPoints[2]
        corners[2].To = screenPoints[3]
        corners[2].Visible = true
    end
    if screenPoints[3] and screenPoints[4] then
        corners[3].From = screenPoints[3]
        corners[3].To = screenPoints[4]
        corners[3].Visible = true
    end
    if screenPoints[4] and screenPoints[1] then
        corners[4].From = screenPoints[4]
        corners[4].To = screenPoints[1]
        corners[4].Visible = true
    end
    
    -- Верхние линии
    if screenPoints[5] and screenPoints[6] then
        corners[5].From = screenPoints[5]
        corners[5].To = screenPoints[6]
        corners[5].Visible = true
    end
    if screenPoints[6] and screenPoints[7] then
        corners[6].From = screenPoints[6]
        corners[6].To = screenPoints[7]
        corners[6].Visible = true
    end
    if screenPoints[7] and screenPoints[8] then
        corners[7].From = screenPoints[7]
        corners[7].To = screenPoints[8]
        corners[7].Visible = true
    end
    if screenPoints[8] and screenPoints[5] then
        corners[8].From = screenPoints[8]
        corners[8].To = screenPoints[5]
        corners[8].Visible = true
    end
end

local function removeBox(player)
    local boxKey = "box_" .. player.UserId
    local boxData = Cache.Boxes[boxKey]
    if boxData then
        for _, corner in ipairs(boxData.corners) do
            pcall(function() corner:Remove() end)
        end
    end
    Cache.Boxes[boxKey] = nil
end

local function clearAllBoxes()
    for key, boxData in pairs(Cache.Boxes) do
        if boxData and boxData.corners then
            for _, corner in ipairs(boxData.corners) do
                pcall(function() corner:Remove() end)
            end
        end
    end
    Cache.Boxes = {}
end

-- ========================================
-- ===== SKELETON ESP =====
-- ========================================

local SKELETON_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
}

local function createSkeletonForPlayer(player)
    if player == LocalPlayer or not player.Character then return end
    
    local bones = Cache.Bones[player.UserId]
    if bones then return end
    
    bones = {}
    for _, bonePair in ipairs(SKELETON_BONES) do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Transparency = 0.8
        line.Visible = false
        table.insert(bones, {pair = bonePair, line = line})
    end
    
    Cache.Bones[player.UserId] = bones
end

local function updateSkeletonBone(player, bone1Name, bone2Name, line)
    if not player.Character then return false end
    
    local bone1 = player.Character:FindFirstChild(bone1Name)
    local bone2 = player.Character:FindFirstChild(bone2Name)
    
    if not bone1 or not bone2 then return false end
    
    local pos1 = bone1.Position
    local pos2 = bone2.Position
    
    local s1, p1 = Camera:WorldToScreenPoint(pos1)
    local s2, p2 = Camera:WorldToScreenPoint(pos2)
    
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
        local player = Players:FindFirstChild(tostring(userId))
        if not player or not Settings.SkeletonESP then
            for _, bone in ipairs(bones) do
                bone.line:Remove()
            end
            Cache.Bones[userId] = nil
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
end

-- ========================================
-- ===== JUMP CIRCLES =====
-- ========================================

local function createJumpCircle(player)
    if not player or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local circle = Instance.new("Part")
    circle.Shape = Enum.PartType.Cylinder
    circle.Size = Vector3.new(0.1, 5, 5)
    circle.Material = Enum.Material.Neon
    circle.Color = COLORS.Purple
    circle.Transparency = 0.3
    circle.Anchored = true
    circle.CanCollide = false
    circle.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
    circle.Parent = workspace
    
    local startTime = tick()
    local lifeTime = 0.6
    
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= lifeTime or not circle or not circle.Parent then
            pcall(function() circle:Destroy() end)
            safeDisconnect(conn)
            return
        end
        
        local alpha = elapsed / lifeTime
        circle.Size = Vector3.new(0.1, 5 + alpha * 8, 5 + alpha * 8)
        circle.Transparency = 0.3 + alpha * 0.7
        circle.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
    end)
end

-- ========================================
-- ===== TRAILS (ТОЛЬКО ЛОКАЛЬНЫЙ ИГРОК) =====
-- ========================================

local function createLocalPlayerTrail()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local oldTrail = hrp:FindFirstChild("LocalTrail")
    if oldTrail then oldTrail:Destroy() end
    
    local att1 = Instance.new("Attachment")
    att1.Parent = hrp
    att1.Position = Vector3.new(-1, 0, 0)
    
    local att2 = Instance.new("Attachment")
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
-- ===== ОПТИМИЗИРОВАННАЯ СИСТЕМА ЧАСТИЦ =====
-- ========================================

local particleSpawnConnection = nil
local particleUpdateConnection = nil
local activeParticles = {}

local PARTICLE_PRESETS = {
    rain = {
        velocity = Vector3.new(0, -15, 0),
        size = 0.2,
        lifetime = 8,
        color = COLORS.Purple,
    },
    snow = {
        velocity = Vector3.new(0.5, -5, 0.5),
        size = 0.4,
        lifetime = 10,
        color = Color3.fromRGB(200, 200, 255),
    },
    sparks = {
        velocity = Vector3.new(10, 15, 10),
        size = 0.15,
        lifetime = 3,
        color = COLORS.Purple,
    },
    magic = {
        velocity = Vector3.new(5, 8, 5),
        size = 0.25,
        lifetime = 5,
        color = COLORS.Purple,
    }
}

local function createOptimizedParticle(position, preset)
    local att = Instance.new("Attachment")
    att.Parent = Workspace
    att.WorldPosition = position
    
    -- Создаём визуальный трейл вместо Part для оптимизации
    local att2 = Instance.new("Attachment")
    att2.Parent = Workspace
    att2.WorldPosition = position + Vector3.new(0.1, 0, 0)
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = att
    trail.Attachment1 = att2
    trail.Lifetime = preset.lifetime
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.Color = ColorSequence.new(preset.color)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Parent = att
    
    local particle = {
        att = att,
        att2 = att2,
        trail = trail,
        lifetime = preset.lifetime,
        startTime = tick(),
        velocity = preset.velocity,
        position = position
    }
    
    table.insert(activeParticles, particle)
    return particle
end

local function updateParticles()
    local toRemove = {}
    
    for i, particle in ipairs(activeParticles) do
        local elapsed = tick() - particle.startTime
        
        if elapsed >= particle.lifetime or not particle.att or not particle.att.Parent then
            pcall(function() 
                particle.trail:Destroy()
                particle.att:Destroy()
                particle.att2:Destroy()
            end)
            table.insert(toRemove, i)
        else
            -- Обновляем позицию частицы
            particle.position = particle.position + particle.velocity * 0.016
            particle.att.WorldPosition = particle.position
            particle.att2.WorldPosition = particle.position + Vector3.new(0.1, 0, 0)
        end
    end
    
    -- Удаляем частицы в обратном порядке
    for i = #toRemove, 1, -1 do
        table.remove(activeParticles, toRemove[i])
    end
end

local function spawnParticles()
    if not Settings.ParticlesEnabled then return end
    
    local preset = PARTICLE_PRESETS[Settings.ParticleType] or PARTICLE_PRESETS.rain
    
    for i = 1, math.ceil(Settings.ParticleCount / 100) do
        local randomPos = Vector3.new(
            math.random(-500, 500),
            math.random(100, 300),
            math.random(-500, 500)
        )
        
        local modifiedPreset = {
            velocity = preset.velocity * Settings.ParticleSpeed,
            size = Settings.ParticleSize,
            lifetime = Settings.ParticleLifetime,
            color = Settings.ParticleType == "magic" and COLORS.Purple or preset.color
        }
        
        createOptimizedParticle(randomPos, modifiedPreset)
    end
end

local function clearAllParticles()
    for _, particle in ipairs(activeParticles) do
        pcall(function() 
            particle.trail:Destroy()
            particle.att:Destroy()
            particle.att2:Destroy()
        end)
    end
    activeParticles = {}
end

-- ========================================
-- ===== POST-EFFECTS (ШЕЙДЕРЫ) =====
-- ========================================

local function setupBloom(intensity)
    if Settings.BloomEnabled then
        Lighting.Brightness = 1.5 + (intensity * 0.5)
    else
        Lighting.Brightness = 1
    end
end

local function setupColorCorrection(tint, saturation, brightness)
    if Settings.ColorCorrectionEnabled then
        Lighting.Ambient = tint
        Lighting.OutdoorAmbient = tint
        Lighting.Brightness = 1 + brightness
    else
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness = 1
    end
end

local function setupVignette(intensity)
    if Settings.VignetteEnabled then
        if not Cache.PostEffects["vignette"] then
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "VignetteEffect"
            screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true
            
            local vignette = Instance.new("Frame")
            vignette.Name = "VignetteFrame"
            vignette.Size = UDim2.new(1, 0, 1, 0)
            vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            vignette.BackgroundTransparency = 0.5
            vignette.BorderSizePixel = 0
            vignette.Parent = screenGui
            
            -- Радиальный градиент (через UIGradient)
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            })
            gradient.Parent = vignette
            
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
end

-- ========================================
-- ===== CROSSHAIR =====
-- ========================================

local crosshairGui = nil

local function createCrosshair()
    if crosshairGui then crosshairGui:Destroy() end
    
    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "Crosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    
    local size = 30
    local center = 1920 / 2
    
    -- Горизонтальная линия
    local horizontal = Instance.new("Frame")
    horizontal.Size = UDim2.new(0, size, 0, 2)
    horizontal.Position = UDim2.new(0.5, -size/2, 0.5, 0)
    horizontal.BackgroundColor3 = COLORS.Purple
    horizontal.BorderSizePixel = 0
    horizontal.Parent = crosshairGui
    
    -- Вертикальная линия
    local vertical = Instance.new("Frame")
    vertical.Size = UDim2.new(0, 2, 0, size)
    vertical.Position = UDim2.new(0.5, 0, 0.5, -size/2)
    vertical.BackgroundColor3 = COLORS.Purple
    vertical.BorderSizePixel = 0
    vertical.Parent = crosshairGui
    
    -- Центр
    local center_dot = Instance.new("Frame")
    center_dot.Size = UDim2.new(0, 4, 0, 4)
    center_dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    center_dot.BackgroundColor3 = COLORS.Purple
    center_dot.BorderSizePixel = 0
    center_dot.Parent = crosshairGui
    
    crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ========================================
-- ===== KILL INDICATOR =====
-- ========================================

local function notifyKill(victim)
    if not Settings.KillIndicatorEnabled then return end
    
    StarterGui:SetCore("SendNotification", {
        Title = "💀 KILL",
        Text = "Убил: " .. victim.Name,
        Duration = 3,
        Icon = "rbxasset://textures/face.png"
    })
    
    if Settings.KillSound then
        -- Воспроизводим звук убийства
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://6947876300"
        sound.Volume = 0.5
        sound.Parent = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or Workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 2)
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
                removeChams(player)
            end
        else
            if not player.Character then continue end
            
            local role = getRole(player)
            
            -- ESP
            if Settings.MurderESP and role == "Murder" then
                createOrUpdateHighlight(player, COLORS.Murder)
            elseif Settings.SheriffESP and role == "Sheriff" then
                createOrUpdateHighlight(player, COLORS.Sheriff)
            elseif Settings.InnocentESP and role == "Innocent" then
                createOrUpdateHighlight(player, COLORS.Innocent)
            else
                removeHighlight(player)
            end
            
            -- Box ESP
            if (Settings.BoxMurder and role == "Murder") or
               (Settings.BoxSheriff and role == "Sheriff") or
               (Settings.BoxInnocent and role == "Innocent") then
                updateBoxDisplay(player, getRoleColor(player))
                drawBox3D(player, getRoleColor(player))
            else
                removeBox(player)
            end
            
            -- Chams
            if Settings.ChamsEnabled then
                applyChams(player)
            else
                removeChams(player)
            end
            
            -- Skeleton
            if Settings.SkeletonESP then
                if not Cache.Bones[player.UserId] then
                    createSkeletonForPlayer(player)
                end
            end
            
            -- Jump Circles
            if Settings.JumpCircles then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Jump then
                    createJumpCircle(player)
                end
            end
        end
    end
    
    -- Skeleton обновление
    if Settings.SkeletonESP then
        updateAllSkeletons()
    end
    
    -- Локальный трейл
    if Settings.Trails then
        if LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("LocalTrail") then
            createLocalPlayerTrail()
        end
    else
        if LocalPlayer.Character then
            local trail = LocalPlayer.Character:FindFirstChild("LocalTrail")
            if trail then pcall(function() trail:Destroy() end) end
        end
    end
end

local function startMainUpdate()
    if mainUpdateConnection then safeDisconnect(mainUpdateConnection) end
    
    mainUpdateConnection = RunService.Heartbeat:Connect(function()
        local anyActive = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP or 
                         Settings.BoxMurder or Settings.BoxSheriff or Settings.BoxInnocent or
                         Settings.ChamsEnabled or Settings.SkeletonESP or Settings.JumpCircles or
                         Settings.Trails
        
        if anyActive then
            updateVisuals()
        end
    end)
    
    -- Particles spawn
    if particleSpawnConnection then safeDisconnect(particleSpawnConnection) end
    if particleUpdateConnection then safeDisconnect(particleUpdateConnection) end
    
    if Settings.ParticlesEnabled then
        particleSpawnConnection = RunService.Heartbeat:Connect(function()
            if Settings.ParticlesEnabled and math.random(1, 20) == 1 then
                spawnParticles()
            end
        end)
        
        particleUpdateConnection = RunService.Heartbeat:Connect(function()
            updateParticles()
        end)
    end
end

-- ========================================
-- ===== RAGE TAB =====
-- ========================================

local RageTab = Window:Tab({ Title = "Rage", Icon = "sword" })
local RageSection = RageTab:Section({ Title = "Rage Settings", Side = "Left" })

-- FLY
local flyConn = nil
local bodyGyro = nil
local bodyVel = nil

RageSection:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(value)
        Settings.FlyEnabled = value
        
        if value then
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            for _, obj in ipairs(hrp:GetChildren()) do
                if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
            end
            
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bodyGyro.P = 1e4
            bodyGyro.D = 1e3
            bodyGyro.Parent = hrp
            
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bodyVel.Parent = hrp
            
            flyConn = RunService.Heartbeat:Connect(function()
                if not Settings.FlyEnabled or not char or not hrp.Parent then
                    safeDisconnect(flyConn)
                    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
                    if bodyVel then bodyVel:Destroy() bodyVel = nil end
                    return
                end
                
                local moveDir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                
                bodyVel.Velocity = moveDir * Settings.FlySpeed
                bodyGyro.CFrame = Camera.CFrame
            end)
        else
            safeDisconnect(flyConn)
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
            if bodyVel then bodyVel:Destroy() bodyVel = nil end
        end
    end
})

RageSection:Slider({
    Title = "Fly Speed",
    Default = 80,
    Min = 10,
    Max = 200,
    Callback = function(v) 
        Settings.FlySpeed = v 
    end
})

-- BUNNY HOP
local bhopConn = nil

RageSection:Toggle({
    Title = "Bunny Hop",
    Default = false,
    Callback = function(value)
        Settings.BHopEnabled = value
        if value then
            bhopConn = RunService.RenderStepped:Connect(function()
                if not Settings.BHopEnabled or not LocalPlayer.Character then return end
                
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    if humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
                        humanoid.Jump = true
                    end
                end
            end)
        else
            safeDisconnect(bhopConn)
        end
    end
})

-- SPIN BOT
local spinConn = nil

RageSection:Toggle({
    Title = "Spin Bot",
    Default = false,
    Callback = function(value)
        Settings.SpinBotEnabled = value
        if value then
            spinConn = RunService.Heartbeat:Connect(function()
                if not Settings.SpinBotEnabled or not LocalPlayer.Character then return end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
                end
            end)
        else
            safeDisconnect(spinConn)
        end
    end
})

RageSection:Slider({
    Title = "Spin Speed",
    Default = 5,
    Min = 1,
    Max = 50,
    Callback = function(v) 
        Settings.SpinSpeed = v 
    end
})

-- ========================================
-- ===== COMBAT TAB =====
-- ========================================

local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local CombatSection = CombatTab:Section({ Title = "Combat", Side = "Left" })

-- NOCLIP
local noclipConn = nil

CombatSection:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(value)
        Settings.NoclipEnabled = value
        if value then
            noclipConn = RunService.Stepped:Connect(function()
                if not Settings.NoclipEnabled or not LocalPlayer.Character then return end
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        else
            safeDisconnect(noclipConn)
        end
    end
})

-- ANTI FLING
local antiFlingConn = nil

CombatSection:Toggle({
    Title = "Anti Fling",
    Default = false,
    Callback = function(value)
        Settings.AntiFlingEnabled = value
        if value then
            antiFlingConn = RunService.Heartbeat:Connect(function()
                if not Settings.AntiFlingEnabled or not LocalPlayer.Character then return end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
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
        end
    end
})

-- GRAB GUN
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

-- FOV
CombatSection:Slider({
    Title = "FOV",
    Default = 70,
    Min = 50,
    Max = 120,
    Callback = function(v)
        Settings.FOVChanger = v
        Camera.FieldOfView = v
    end
})

-- ========================================
-- ===== VISUAL TAB =====
-- ========================================

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local VisualSection = VisualTab:Section({ Title = "ESP", Side = "Left" })
local VisualSection2 = VisualTab:Section({ Title = "Effects", Side = "Right" })

-- ESP
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

-- BOX ESP
VisualSection:Toggle({
    Title = "Box Murder",
    Default = false,
    Callback = function(v) Settings.BoxMurder = v startMainUpdate() end
})

VisualSection:Toggle({
    Title = "Box Sheriff",
    Default = false,
    Callback = function(v) Settings.BoxSheriff = v startMainUpdate() end
})

VisualSection:Toggle({
    Title = "Box Innocent",
    Default = false,
    Callback = function(v) Settings.BoxInnocent = v startMainUpdate() end
})

VisualSection:Slider({
    Title = "Box Thickness",
    Default = 0.05,
    Min = 0.01,
    Max = 0.2,
    Callback = function(v) 
        Settings.BoxThickness = v 
    end
})

-- CHAMS
VisualSection:Toggle({
    Title = "Chams (Purple)",
    Default = false,
    Callback = function(v) Settings.ChamsEnabled = v startMainUpdate() end
})

VisualSection:Slider({
    Title = "Chams Transparency",
    Default = 0.2,
    Min = 0,
    Max = 1,
    Callback = function(v) 
        Settings.ChamsThickness = v 
    end
})

-- SKELETON
VisualSection:Toggle({
    Title = "Skeleton ESP",
    Default = false,
    Callback = function(v) Settings.SkeletonESP = v if not v then clearAllSkeletons() end startMainUpdate() end
})

-- EFFECTS
VisualSection2:Toggle({
    Title = "Jump Circles",
    Default = false,
    Callback = function(v) Settings.JumpCircles = v startMainUpdate() end
})

VisualSection2:Toggle({
    Title = "Purple Trail",
    Default = false,
    Callback = function(v) Settings.Trails = v startMainUpdate() end
})

VisualSection2:Toggle({
    Title = "Crosshair",
    Default = false,
    Callback = function(v) 
        Settings.CrosshairEnabled = v 
        if v then
            createCrosshair()
        else
            if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
        end
    end
})

-- ========================================
-- ===== PARTICLES TAB =====
-- ========================================

local ParticlesTab = Window:Tab({ Title = "Particles", Icon = "cloud" })
local ParticlesSection = ParticlesTab:Section({ Title = "Particle Settings", Side = "Left" })

ParticlesSection:Toggle({
    Title = "Particles",
    Default = false,
    Callback = function(v) 
        Settings.ParticlesEnabled = v 
        startMainUpdate()
        if not v then
            clearAllParticles()
        end
    end
})

ParticlesSection:Dropdown({
    Title = "Particle Type",
    Default = "rain",
    Options = {"rain", "snow", "sparks", "magic"},
    Callback = function(v) Settings.ParticleType = v end
})

ParticlesSection:Slider({
    Title = "Particle Count",
    Default = 50,
    Min = 10,
    Max = 200,
    Callback = function(v) Settings.ParticleCount = v end
})

ParticlesSection:Slider({
    Title = "Particle Size",
    Default = 0.3,
    Min = 0.1,
    Max = 1,
    Callback = function(v) Settings.ParticleSize = v end
})

ParticlesSection:Slider({
    Title = "Particle Speed",
    Default = 1,
    Min = 0.1,
    Max = 5,
    Callback = function(v) Settings.ParticleSpeed = v end
})

ParticlesSection:Slider({
    Title = "Particle Lifetime",
    Default = 5,
    Min = 1,
    Max = 20,
    Callback = function(v) Settings.ParticleLifetime = v end
})

-- ========================================
-- ===== SHADERS TAB =====
-- ========================================

local ShadersTab = Window:Tab({ Title = "Shaders", Icon = "wand" })
local ShadersSection = ShadersTab:Section({ Title = "Post-Effects", Side = "Left" })
local ShadersSection2 = ShadersTab:Section({ Title = "Color", Side = "Right" })

-- BLOOM
ShadersSection:Toggle({
    Title = "Bloom",
    Default = false,
    Callback = function(v) 
        Settings.BloomEnabled = v 
        setupBloom(Settings.BloomIntensity)
    end
})

ShadersSection:Slider({
    Title = "Bloom Intensity",
    Default = 1,
    Min = 0,
    Max = 5,
    Callback = function(v) 
        Settings.BloomIntensity = v 
        if Settings.BloomEnabled then setupBloom(v) end
    end
})

-- COLOR CORRECTION
ShadersSection2:Toggle({
    Title = "Color Correction",
    Default = false,
    Callback = function(v) 
        Settings.ColorCorrectionEnabled = v 
        setupColorCorrection(Settings.ColorCorrectionTint, Settings.ColorCorrectionSaturation, Settings.ColorCorrectionBrightness)
    end
})

ShadersSection2:Slider({
    Title = "Brightness",
    Default = 0,
    Min = -1,
    Max = 1,
    Callback = function(v) 
        Settings.ColorCorrectionBrightness = v 
        if Settings.ColorCorrectionEnabled then setupColorCorrection(Settings.ColorCorrectionTint, Settings.ColorCorrectionSaturation, v) end
    end
})

-- VIGNETTE
ShadersSection:Toggle({
    Title = "Vignette",
    Default = false,
    Callback = function(v) 
        Settings.VignetteEnabled = v 
        setupVignette(Settings.VignetteIntensity)
    end
})

ShadersSection:Slider({
    Title = "Vignette Intensity",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Callback = function(v) 
        Settings.VignetteIntensity = v 
    end
})

-- ========================================
-- ===== SKY TAB =====
-- ========================================

local SkyTab = Window:Tab({ Title = "Sky", Icon = "cloud" })
local SkySection = SkyTab:Section({ Title = "Sky Settings", Side = "Left" })

SkySection:Input({
    Title = "Sky ID",
    Default = "",
    Placeholder = "rbxassetid://...",
    Callback = function(v) Settings.CustomSkyId = v end
})

SkySection:Button({
    Title = "Apply Sky",
    Callback = function()
        if Settings.CustomSkyId ~= "" then
            setupSky(Settings.CustomSkyId)
            StarterGui:SetCore("SendNotification", {
                Title = "Sky",
                Text = "Sky applied!",
                Duration = 2
            })
        end
    end
})

-- ========================================
-- ===== GAMEPLAY TAB =====
-- ========================================

local GameplayTab = Window:Tab({ Title = "Gameplay", Icon = "star" })
local GameplaySection = GameplayTab:Section({ Title = "Gameplay Settings", Side = "Left" })

GameplaySection:Toggle({
    Title = "Kill Indicator",
    Default = false,
    Callback = function(v) Settings.KillIndicatorEnabled = v end
})

GameplaySection:Toggle({
    Title = "Kill Sound",
    Default = false,
    Callback = function(v) Settings.KillSound = v end
})

-- ========================================
-- ===== SETTINGS TAB =====
-- ========================================

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "gear" })
local SettingsSection = SettingsTab:Section({ Title = "Settings", Side = "Left" })

SettingsSection:Label({
    Title = "Murder Hub v5.0",
    Description = "Advanced • Fully Featured",
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
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllHighlights()
    clearAllBoxes()
    clearAllChams()
    clearAllSkeletons()
    
    if Settings.FlyEnabled then
        Settings.FlyEnabled = false
        task.wait(0.2)
        Settings.FlyEnabled = true
    end
end)

startMainUpdate()

print("✅ Murder Hub v5.0 Loaded!")
StarterGui:SetCore("SendNotification", {
    Title = "Murder Hub",
    Text = "✅ v5.0 Complete Edition!",
    Duration = 5
})
