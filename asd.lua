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
    
    -- Visuals
    JumpCircles = false,
    Trails = false,
    FogEnabled = false,
    ParticlesEnabled = false,
    
    -- Particles (ФИКСИРОВАННЫЕ ЗНАЧЕНИЯ)
    ParticleCount = 100,
    ParticleRange = 50,
    
    -- Shaders
    BloomEnabled = false,
    ColorCorrectionEnabled = false,
    VignetteEnabled = false,
    
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
    
    -- Combat
    NoclipEnabled = false,
    AntiFlingEnabled = false,
    FOVChanger = 70,
    FlingEnabled = false
}

-- ========================================
-- ===== КЭШИ =====
-- ========================================

local Cache = {
    Highlights = {},
    Bones = {},
    Visuals = {},
    Connections = {},
    ChamsParts = {},
    Particles = {},
    PostEffects = {},
    JumpTracking = {}
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
-- ===== CHAMS =====
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
                part.Transparency = 0.2
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
-- ===== SKELETON ESP =====
-- ========================================

local SKELETON_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LowerTorso", "RightUpperLeg"} , {"RightUpperLeg", "RightLowerLeg"},
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
-- ===== PERFECT JUMP CIRCLES =====
-- ========================================

local jumpTracking = {}

local function createJumpCircleAtPosition(position)
    if not Settings.JumpCircles then return end
    
    -- Создаём Part в виде кольца
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
    
    -- Light для свечения
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
        
        -- Увеличиваем размер кольца
        local scale = 0.5 + (progress * 4.5)
        ring.Size = Vector3.new(0.05, scale, scale)
        
        -- Плавное исчезновение
        ring.Transparency = progress
        light.Brightness = 5 * (1 - progress)
        
        ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    end)
end

local function setupJumpTracking()
    for _, player in ipairs(Players:GetPlayers()) do
        if not jumpTracking[player.UserId] then
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    jumpTracking[player.UserId] = {
                        wasJumping = false,
                        lastJumpPos = player.Character:FindFirstChild("HumanoidRootPart").Position
                    }
                end
            end
        end
    end
end

local jumpCircleUpdateConnection = nil

local function updateJumpCircles()
    if not Settings.JumpCircles then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if not player or not player.Character then continue end
        
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and hrp then
            local tracking = jumpTracking[player.UserId]
            if not tracking then
                tracking = {wasJumping = false, lastJumpPos = hrp.Position}
                jumpTracking[player.UserId] = tracking
            end
            
            local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
            
            -- Обнаруживаем момент начала прыжка
            if isJumping and not tracking.wasJumping then
                createJumpCircleAtPosition(tracking.lastJumpPos)
            end
            
            tracking.wasJumping = isJumping
            
            -- Обновляем позицию когда игрок на земле
            if humanoid:GetState() == Enum.HumanoidStateType.Landed or
               humanoid:GetState() == Enum.HumanoidStateType.Running then
                tracking.lastJumpPos = hrp.Position
            end
        end
    end
end

-- ========================================
-- ===== TRAILS (ЛОКАЛЬНЫЙ ИГРОК) =====
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
-- ===== СИСТЕМА ЧАСТИЦ (ОПТИМИЗИРОВАННАЯ) =====
-- ========================================

local particleSpawnConnection = nil
local particleUpdateConnection = nil
local activeParticles = {}

local function createOptimizedParticle(position)
    local att = Instance.new("Attachment")
    att.Parent = Workspace
    att.WorldPosition = position
    
    local att2 = Instance.new("Attachment")
    att2.Parent = Workspace
    att2.WorldPosition = position + Vector3.new(0.1, 0, 0)
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = att
    trail.Attachment1 = att2
    trail.Lifetime = 8
    trail.MinLength = 0
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.LightInfluence = 0
    trail.Color = ColorSequence.new(COLORS.Purple)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Parent = att
    
    local particle = {
        att = att,
        att2 = att2,
        trail = trail,
        lifetime = 8,
        startTime = tick(),
        velocity = Vector3.new(math.random(-10, 10), -5, math.random(-10, 10)),
        position = position
    }
    
    table.insert(activeParticles, particle)
    return particle
end

local function updateParticles()
    if not Settings.ParticlesEnabled then return end
    
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
            particle.position = particle.position + particle.velocity * 0.016
            particle.att.WorldPosition = particle.position
            particle.att2.WorldPosition = particle.position + Vector3.new(0.1, 0, 0)
        end
    end
    
    for i = #toRemove, 1, -1 do
        table.remove(activeParticles, toRemove[i])
    end
end

local function spawnParticles()
    if not Settings.ParticlesEnabled then return end
    
    for i = 1, 3 do
        local randomPos = Vector3.new(
            math.random(-Settings.ParticleRange, Settings.ParticleRange),
            math.random(50, 150),
            math.random(-Settings.ParticleRange, Settings.ParticleRange)
        )
        
        createOptimizedParticle(randomPos)
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
-- ===== POST-EFFECTS =====
-- ========================================

local function setupBloom(enabled)
    if enabled then
        Lighting.Brightness = 1.5
    else
        Lighting.Brightness = 1
    end
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
            vignette.Name = "VignetteFrame"
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
    
    local horizontal = Instance.new("Frame")
    horizontal.Size = UDim2.new(0, size, 0, 2)
    horizontal.Position = UDim2.new(0.5, -size/2, 0.5, 0)
    horizontal.BackgroundColor3 = COLORS.Purple
    horizontal.BorderSizePixel = 0
    horizontal.Parent = crosshairGui
    
    local vertical = Instance.new("Frame")
    vertical.Size = UDim2.new(0, 2, 0, size)
    vertical.Position = UDim2.new(0.5, 0, 0.5, -size/2)
    vertical.BackgroundColor3 = COLORS.Purple
    vertical.BorderSizePixel = 0
    vertical.Parent = crosshairGui
    
    local center_dot = Instance.new("Frame")
    center_dot.Size = UDim2.new(0, 4, 0, 4)
    center_dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    center_dot.BackgroundColor3 = COLORS.Purple
    center_dot.BorderSizePixel = 0
    center_dot.Parent = crosshairGui
    
    crosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ========================================
-- ===== РАБОЧИЙ FLING =====
-- ========================================

local flingConnection = nil

local function startFling()
    if Settings.FlingEnabled then
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not hrp then return end
        
        flingConnection = RunService.Heartbeat:Connect(function()
            if not Settings.FlingEnabled or not character or not hrp.Parent then
                safeDisconnect(flingConnection)
                return
            end
            
            -- Простой и эффективный флинг
            hrp.Velocity = hrp.CFrame.LookVector * 100 + Vector3.new(0, 100, 0)
            hrp.RotVelocity = Vector3.new(500, 500, 500)
            
            humanoid.Jump = true
        end)
    else
        safeDisconnect(flingConnection)
    end
end

-- ========================================
-- ===== ANTI FLING (УБИРАЕТ КОЛЛИЗИИ) =====
-- ========================================

local antiFlingConnection = nil

local function setupAntiFling()
    if Settings.AntiFlingEnabled then
        antiFlingConnection = RunService.Heartbeat:Connect(function()
            if not Settings.AntiFlingEnabled or not LocalPlayer.Character then return end
            
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            -- Убираем коллизии с игроками
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local theirHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if theirHrp then
                        theirHrp.CanCollide = false
                    end
                end
            end
            
            -- Стоп флинг
            if hrp.AssemblyLinearVelocity.Magnitude > 150 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            if hrp.AssemblyAngularVelocity.Magnitude > 50 then
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        safeDisconnect(antiFlingConnection)
        
        -- Возвращаем коллизии
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local theirHrp = player.Character:FindFirstChild("HumanoidRootPart")
                if theirHrp then
                    theirHrp.CanCollide = true
                end
            end
        end
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
        end
    end
    
    if Settings.SkeletonESP then
        updateAllSkeletons()
    end
    
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
                         Settings.ChamsEnabled or Settings.SkeletonESP or Settings.JumpCircles or
                         Settings.Trails
        
        if anyActive then
            updateVisuals()
        end
        
        -- Jump circles update
        if Settings.JumpCircles then
            updateJumpCircles()
        end
        
        -- Particles update
        if Settings.ParticlesEnabled then
            updateParticles()
        end
    end)
    
    -- Particle spawn
    if particleSpawnConnection then safeDisconnect(particleSpawnConnection) end
    
    if Settings.ParticlesEnabled then
        particleSpawnConnection = RunService.Heartbeat:Connect(function()
            if Settings.ParticlesEnabled and math.random(1, 5) == 1 then
                spawnParticles()
            end
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

-- FLING (РАБОЧИЙ)
RageSection:Toggle({
    Title = "Super Fling",
    Default = false,
    Callback = function(value)
        Settings.FlingEnabled = value
        startFling()
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

-- ANTI FLING (УБИРАЕТ КОЛЛИЗИИ)
CombatSection:Toggle({
    Title = "Anti Fling",
    Default = false,
    Callback = function(value)
        Settings.AntiFlingEnabled = value
        setupAntiFling()
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

-- ========================================
-- ===== VISUAL TAB =====
-- ========================================

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local VisualSection = VisualTab:Section({ Title = "ESP", Side = "Left" })

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

-- CHAMS
VisualSection:Toggle({
    Title = "Chams (Purple)",
    Default = false,
    Callback = function(v) Settings.ChamsEnabled = v startMainUpdate() end
})

-- SKELETON
VisualSection:Toggle({
    Title = "Skeleton ESP",
    Default = false,
    Callback = function(v) Settings.SkeletonESP = v if not v then clearAllSkeletons() end startMainUpdate() end
})

-- EFFECTS
VisualSection:Toggle({
    Title = "Jump Circles",
    Default = false,
    Callback = function(v) 
        Settings.JumpCircles = v 
        setupJumpTracking()
        startMainUpdate()
    end
})

VisualSection:Toggle({
    Title = "Purple Trail",
    Default = false,
    Callback = function(v) Settings.Trails = v startMainUpdate() end
})

VisualSection:Toggle({
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
local ParticlesSection = ParticlesTab:Section({ Title = "Particles (100шт / 50м)", Side = "Left" })

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

-- ========================================
-- ===== SHADERS TAB =====
-- ========================================

local ShadersTab = Window:Tab({ Title = "Shaders", Icon = "wand" })
local ShadersSection = ShadersTab:Section({ Title = "Post-Effects", Side = "Left" })

-- BLOOM
ShadersSection:Toggle({
    Title = "Bloom",
    Default = false,
    Callback = function(v) 
        Settings.BloomEnabled = v 
        setupBloom(v)
    end
})

-- COLOR CORRECTION
ShadersSection:Toggle({
    Title = "Color Correction",
    Default = false,
    Callback = function(v) 
        Settings.ColorCorrectionEnabled = v 
        setupColorCorrection(v)
    end
})

-- VIGNETTE
ShadersSection:Toggle({
    Title = "Vignette",
    Default = false,
    Callback = function(v) 
        Settings.VignetteEnabled = v 
        setupVignette(v)
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
    Title = "Murder Hub v7.0",
    Description = "Final Edition",
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
        if Settings.JumpCircles then
            jumpTracking[player.UserId] = {wasJumping = false, lastJumpPos = player.Character:FindFirstChild("HumanoidRootPart").Position}
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllHighlights()
    clearAllChams()
    clearAllSkeletons()
    
    if Settings.JumpCircles then
        setupJumpTracking()
    end
    
    if Settings.FlyEnabled then
        Settings.FlyEnabled = false
        task.wait(0.2)
        Settings.FlyEnabled = true
    end
end)

startMainUpdate()
setupJumpTracking()

print("✅ Murder Hub v7.0 Loaded!")
StarterGui:SetCore("SendNotification", {
    Title = "Murder Hub",
    Text = "✅ v7.0 Final Edition!",
    Duration = 5
})
