-- ========================================
-- ===== PLANT HUB v2.3 FIXED FULL =====
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
    Folder = "PlantHubSettings",
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
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

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
    FogEnabled = false,
    ParticlesEnabled = false,
    RGBHumanoid = false,
    NimbEnabled = false,
    XRayEnabled = false,
    WingsEnabled = false,
    ParticleCount = 100,
    ParticleRange = 50,
    BloomEnabled = false,
    ColorCorrectionEnabled = false,
    VignetteEnabled = false,
    CustomSkyId = "",
    CrosshairEnabled = false,
    FlyEnabled = false,
    FlySpeed = 100,
    MaxFlySpeed = 1000,
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
    NimbConnection = nil,
    NimbPart = nil,
    AutoFarmConnection = nil,
    CurrentTween = nil,
    XRayParts = {},
    WingsPart = nil,
    WingsLeftPart = nil,
    WingsConnection = nil,
    WingsParticles = {},
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
            part.Transparency = 0.3
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
                end)
            end
        end
    end
    Cache.ChamsPartsList = {}
    Cache.ChamsParts = {}
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
-- ===== NIMB (HALO) =====
-- ========================================

local function setupNimb()
    if Settings.NimbEnabled then
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if Cache.NimbPart then
            pcall(function() Cache.NimbPart:Destroy() end)
            Cache.NimbPart = nil
        end
        local nimb = Instance.new("Part")
        nimb.Name = "Nimb"
        nimb.Shape = Enum.PartType.Ball
        nimb.Size = Vector3.new(3.5, 0.35, 3.5)
        nimb.Material = Enum.Material.Neon
        nimb.Color = COLORS.Purple
        nimb.Transparency = 0.2
        nimb.CanCollide = false
        nimb.Anchored = false
        nimb.TopSurface = Enum.SurfaceType.Smooth
        nimb.BottomSurface = Enum.SurfaceType.Smooth
        nimb.Parent = LocalPlayer.Character

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://3270017"
        mesh.Scale = Vector3.new(1.2, 0.15, 1.2)
        mesh.Parent = nimb

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = nimb
        weld.Part1 = hrp
        weld.Parent = nimb

        nimb.CFrame = hrp.CFrame + Vector3.new(0, 3.5, 0)
        Cache.NimbPart = nimb

        safeDisconnect(Cache.NimbConnection)
        Cache.NimbConnection = RunService.Heartbeat:Connect(function()
            if not Settings.NimbEnabled or not Cache.NimbPart or not Cache.NimbPart.Parent then
                safeDisconnect(Cache.NimbConnection)
                Cache.NimbConnection = nil
                return
            end
            local t = tick()
            Cache.NimbPart.Color = Color3.fromHSV(t % 1, 1, 1)
            Cache.NimbPart.CFrame = Cache.NimbPart.CFrame * CFrame.Angles(0, math.rad(3), 0)
        end)
    else
        safeDisconnect(Cache.NimbConnection)
        Cache.NimbConnection = nil
        if Cache.NimbPart then
            pcall(function() Cache.NimbPart:Destroy() end)
            Cache.NimbPart = nil
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
-- ===== WINGS (FIXED) =====
-- ========================================

local function clearWings()
    safeDisconnect(Cache.WingsConnection)
    Cache.WingsConnection = nil

    for _, emitter in ipairs(Cache.WingsParticles) do
        pcall(function() emitter:Destroy() end)
    end
    Cache.WingsParticles = {}

    if Cache.WingsPart then
        pcall(function() Cache.WingsPart:Destroy() end)
        Cache.WingsPart = nil
    end
    if Cache.WingsLeftPart then
        pcall(function() Cache.WingsLeftPart:Destroy() end)
        Cache.WingsLeftPart = nil
    end
end

local function createManualWings()
    local character = LocalPlayer.Character
    if not character then return end

    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end

    local function createWingPart(side, offsetX, angle)
        local wing = Instance.new("Part")
        wing.Name = "Wing_" .. side
        wing.Size = Vector3.new(0.3, 2.5, 4)
        wing.Material = Enum.Material.Neon
        wing.Color = COLORS.Purple
        wing.Transparency = 0.15
        wing.CanCollide = false
        wing.Anchored = false
        wing.TopSurface = Enum.SurfaceType.Smooth
        wing.BottomSurface = Enum.SurfaceType.Smooth
        wing.Parent = character

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://1285237"
        mesh.Scale = Vector3.new(1.5, 1.5, 1.5)
        mesh.Parent = wing

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = wing
        weld.Part1 = torso
        weld.Parent = wing

        wing.CFrame = torso.CFrame * CFrame.new(offsetX, 0.5, 0.8) * CFrame.Angles(0, angle, 0)

        -- Эмиттер частиц
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://241685484"
        emitter.LightEmission = 1
        emitter.LightInfluence = 0
        emitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, COLORS.Purple),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        })
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(0.5, 0.12),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Speed = NumberRange.new(1, 4)
        emitter.Lifetime = NumberRange.new(0.4, 1.0)
        emitter.Rate = 25
        emitter.SpreadAngle = Vector2.new(40, 40)
        emitter.RotSpeed = NumberRange.new(-30, 30)
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.Parent = wing
        table.insert(Cache.WingsParticles, emitter)

        -- Искровой эмиттер
        local sparkEmitter = Instance.new("ParticleEmitter")
        sparkEmitter.Texture = "rbxassetid://1266576587"
        sparkEmitter.LightEmission = 1
        sparkEmitter.LightInfluence = 0
        sparkEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, COLORS.Purple),
        })
        sparkEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 0),
        })
        sparkEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        sparkEmitter.Speed = NumberRange.new(2, 6)
        sparkEmitter.Lifetime = NumberRange.new(0.2, 0.6)
        sparkEmitter.Rate = 15
        sparkEmitter.SpreadAngle = Vector2.new(50, 50)
        sparkEmitter.Parent = wing
        table.insert(Cache.WingsParticles, sparkEmitter)

        return wing
    end

    local leftWing = createWingPart("Left", -2.5, math.rad(30))
    local rightWing = createWingPart("Right", 2.5, math.rad(-30))

    Cache.WingsPart = rightWing
    Cache.WingsLeftPart = leftWing

    -- Анимация
    safeDisconnect(Cache.WingsConnection)
    Cache.WingsConnection = RunService.Heartbeat:Connect(function()
        if not Settings.WingsEnabled then
            safeDisconnect(Cache.WingsConnection)
            Cache.WingsConnection = nil
            return
        end

        local t = tick()
        local color = Color3.fromHSV(t % 1, 1, 1)

        if Cache.WingsPart and Cache.WingsPart.Parent then
            Cache.WingsPart.Color = color
        end
        if Cache.WingsLeftPart and Cache.WingsLeftPart.Parent then
            Cache.WingsLeftPart.Color = color
        end

        for _, emitter in ipairs(Cache.WingsParticles) do
            if emitter and emitter.Parent then
                pcall(function()
                    emitter.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, color),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
                    })
                end)
            end
        end
    end)
end

local function setupWings()
    clearWings()

    if not Settings.WingsEnabled then return end
    if not LocalPlayer.Character then
        task.wait(0.5)
        if not LocalPlayer.Character then return end
    end

    -- ПЫТАЕМСЯ ЗАГРУЗИТЬ МОДЕЛЬ (ТИХО ПАДАЕМ)
    local success, model = pcall(function()
        return InsertService:LoadAsset(114504871813760)
    end)

    if success and model then
        local wingPart = model:FindFirstChildOfClass("BasePart") or model:FindFirstChildOfClass("MeshPart")
        if wingPart then
            wingPart.Parent = LocalPlayer.Character
            wingPart.CanCollide = false
            wingPart.Anchored = false

            local torso = LocalPlayer.Character:FindFirstChild("UpperTorso") or LocalPlayer.Character:FindFirstChild("Torso")
            if torso then
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = wingPart
                weld.Part1 = torso
                weld.Parent = wingPart
                wingPart.CFrame = torso.CFrame * CFrame.new(0, 0.5, 1.5)
            end

            Cache.WingsPart = wingPart
            pcall(function() model:Destroy() end)
            return
        end
        pcall(function() model:Destroy() end)
    end

    -- ЗАПАСНОЙ ВАРИАНТ
    createManualWings()
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
-- ===== СИСТЕМА ЧАСТИЦ =====
-- ========================================

local particleSpawnConnection = nil
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
-- ===== ANTI-AFK (FIXED) =====
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

local function farmLoop()
    while Settings.AutoFarmEnabled do
        local character = LocalPlayer.Character
        if not character then
            task.wait(1)
            continue
        end

        local currentCoins = getCurrentCoins()
        if currentCoins >= Settings.AutoFarmCoinLimit then
            Settings.AutoFarmEnabled = false
            StarterGui:SetCore("SendNotification", {
                Title = "AutoFarm",
                Text = "CoinBag полный! ✅",
                Duration = 3
            })
            break
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
-- ===== FLY (FIXED) =====
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
    safeDisconnect(particleSpawnConnection)

    mainUpdateConnection = RunService.Heartbeat:Connect(function()
        local anyActive = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP or
                          Settings.ChamsEnabled or Settings.SkeletonESP or Settings.JumpCircles or
                          Settings.Trails

        if anyActive then
            updateVisuals()
        end

        if Settings.JumpCircles then
            updateJumpCircles()
        end

        if Settings.ParticlesEnabled then
            updateParticles()
        end
    end)

    if Settings.ParticlesEnabled then
        particleSpawnConnection = RunService.Heartbeat:Connect(function()
            if Settings.ParticlesEnabled and math.random(1, 5) == 1 then
                spawnParticles()
            end
        end)
    end
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
    Title = "Chams",
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
    Title = "Nimb (Halo)",
    Default = false,
    Callback = function(v)
        Settings.NimbEnabled = v
        setupNimb()
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
    Title = "Wings ✨ (FIXED)",
    Default = false,
    Callback = function(value)
        Settings.WingsEnabled = value
        setupWings()
    end
})

VisualSection2:Toggle({
    Title = "Crosshair",
    Default = false,
    Callback = function(v)
        if v then
            createCrosshair()
        else
            if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
        end
    end
})

-- PARTICLES TAB
local ParticlesTab = Window:Tab({ Title = "Particles", Icon = "cloud" })
local ParticlesSection = ParticlesTab:Section({ Title = "Particles", Side = "Left" })

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

-- SHADERS TAB
local ShadersTab = Window:Tab({ Title = "Shaders", Icon = "wand" })
local ShadersSection = ShadersTab:Section({ Title = "Post-Effects", Side = "Left" })

ShadersSection:Toggle({
    Title = "Bloom",
    Default = false,
    Callback = function(v)
        Settings.BloomEnabled = v
        setupBloom(v)
    end
})

ShadersSection:Toggle({
    Title = "Color Correction",
    Default = false,
    Callback = function(v)
        Settings.ColorCorrectionEnabled = v
        setupColorCorrection(v)
    end
})

ShadersSection:Toggle({
    Title = "Vignette",
    Default = false,
    Callback = function(v)
        Settings.VignetteEnabled = v
        setupVignette(v)
    end
})

-- SKY TAB
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
    Title = "PlanetHub v2.3 FIXED",
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
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllHighlights()
    clearAllChams()
    clearAllSkeletons()

    Cache.BoneParts = {}
    Cache.ChamsPartsList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if Settings.ChamsEnabled then
            cacheCharacterParts(player)
        end
        if Settings.SkeletonESP then
            createSkeletonForPlayer(player)
        end
    end

    setupRGBHumanoid()
    setupNimb()
    updatePlayerInfo()

    if Settings.WingsEnabled then
        task.wait(0.5)
        setupWings()
    end

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
end)

startMainUpdate()
setupJumpTracking()
setupSheriffDeadNotif()

print("✅ PlanetHub v2.3 FIXED Loaded!")
StarterGui:SetCore("SendNotification", {
    Title = "Welcome",
    Text = "PlanetHub v2.3 FIXED | Wings work!",
    Duration = 5
})
