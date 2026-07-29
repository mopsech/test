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
    Size = UDim2.fromOffset(680, 550),
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
-- ===== ПЕРЕМЕННЫЕ =====
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
    
    -- Box
    BoxMurder = false,
    BoxSheriff = false,
    BoxInnocent = false,
    
    -- Visuals
    JumpCircles = false,
    ChinaHat = false,
    Trails = false,
    FogEnabled = false,
    ParticlesEnabled = false,
    
    -- Rage
    FlyEnabled = false,
    FlySpeed = 80,
    BHopEnabled = false,
    SpinBotEnabled = false,
    SpinSpeed = 5,
    
    -- Aim
    SilentAimEnabled = false,
    SilentAimFOV = 150,
    
    -- Combat
    NoclipEnabled = false,
    AntiFlingEnabled = false,
    FOVChanger = 70
}

-- ========================================
-- ===== КЭШИ И ССЫЛКИ =====
-- ========================================

local Cache = {
    Highlights = {},
    Boxes = {},
    Bones = {},
    BodyParts = {},
    Visuals = {},
    Connections = {},
    ChamsParts = {}
}

local COLORS = {
    Murder = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Purple = Color3.fromRGB(138, 43, 226),
    White = Color3.fromRGB(255, 255, 255),
    Gold = Color3.fromRGB(255, 215, 0),
    Pink = Color3.fromRGB(255, 0, 255)
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
-- ===== HIGHLIGHT ESP (ОПТИМИЗИРОВАННАЯ) =====
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
-- ===== CHAMS (ОПТИМИЗИРОВАННЫЕ) =====
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
                    ogTransparency = part.Transparency
                }
            end
            
            local role = getRole(player)
            local color = COLORS.Purple
            
            if role == "Murder" and Settings.ChamsMurder then
                color = COLORS.Murder
            elseif role == "Sheriff" and Settings.ChamsSheriff then
                color = COLORS.Sheriff
            elseif role == "Innocent" and Settings.ChamsInnocent then
                color = COLORS.Innocent
            end
            
            if Settings.ChamsEnabled then
                part.Material = Enum.Material.ForceField
                part.Color = color
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
-- ===== BOX ESP (ОПТИМИЗИРОВАННАЯ) =====
-- ========================================

local function createBox(player, color)
    if not player or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local box = Instance.new("SelectionBox")
    box.Adornee = player.Character
    box.Color3 = color
    box.LineThickness = 0.05
    box.SurfaceTransparency = 0.8
    box.SurfaceColor3 = color
    box.Parent = workspace
    
    Cache.Boxes[player.UserId] = box
end

local function removeBox(player)
    local box = Cache.Boxes[player.UserId]
    if box then pcall(function() box:Destroy() end) end
    Cache.Boxes[player.UserId] = nil
end

local function clearAllBoxes()
    for userId, box in pairs(Cache.Boxes) do
        if box then pcall(function() box:Destroy() end) end
    end
    Cache.Boxes = {}
end

-- ========================================
-- ===== SKELETON ESP (ОПТИМИЗИРОВАННАЯ) =====
-- ========================================

local SKELETON_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
}

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
        circle.Color = Color3.fromHSV(0.75, 1 - alpha * 0.3, 1)
        circle.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
    end)
end

-- ========================================
-- ===== CHINA HAT =====
-- ========================================

local function createChinaHat(player)
    if not player or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local old = player.Character:FindFirstChild("ChinaHat_Mesh")
    if old then old:Destroy() end
    
    local hat = Instance.new("Part")
    hat.Name = "ChinaHat_Mesh"
    hat.Size = Vector3.new(3, 1, 3)
    hat.Material = Enum.Material.Neon
    hat.Color = COLORS.Gold
    hat.Transparency = 0.2
    hat.Anchored = false
    hat.CanCollide = false
    hat.TopSurface = Enum.SurfaceType.Smooth
    hat.BottomSurface = Enum.SurfaceType.Smooth
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Sphere
    mesh.Scale = Vector3.new(1.5, 0.5, 1.5)
    mesh.Parent = hat
    
    hat.Parent = player.Character
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hat
    weld.Part1 = hrp
    weld.Parent = hat
    hat.Position = hrp.Position + Vector3.new(0, 3.5, 0)
    
    Cache.Visuals[player.UserId .. "_hat"] = hat
    
    task.spawn(function()
        local angle = 0
        while hat and hat.Parent and Settings.ChinaHat do
            angle = angle + 0.02
            hat.CFrame = hrp.CFrame * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, angle, 0)
            task.wait()
        end
        if hat then pcall(function() hat:Destroy() end) end
    end)
end

-- ========================================
-- ===== TRAILS =====
-- ========================================

local function createTrail(player)
    if not player or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Очищаем старые
    local oldTrail = hrp:FindFirstChild("MurderTrail")
    if oldTrail then oldTrail:Destroy() end
    
    local att1 = Instance.new("Attachment")
    att1.Parent = hrp
    att1.Position = Vector3.new(-1, 0, 0)
    
    local att2 = Instance.new("Attachment")
    att2.Parent = hrp
    att2.Position = Vector3.new(1, 0, 0)
    
    local trail = Instance.new("Trail")
    trail.Name = "MurderTrail"
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
    
    local color = getRoleColor(player)
    trail.Color = ColorSequence.new(color)
    trail.Parent = hrp
    
    Cache.Visuals[player.UserId .. "_trail"] = {trail = trail, att1 = att1, att2 = att2}
end

-- ========================================
-- ===== PURPLE FOG =====
-- ========================================

local function setupFog()
    if Settings.FogEnabled then
        local originalFog = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows
        }
        
        Lighting.Brightness = 1.5
        Lighting.ClockTime = 16
        Lighting.FogEnd = 500
        Lighting.Ambient = COLORS.Purple
        Lighting.OutdoorAmbient = COLORS.Purple
        Lighting.GlobalShadows = false
        
        Cache.Connections["fog"] = function()
            if not Settings.FogEnabled then
                Lighting.Brightness = originalFog.Brightness
                Lighting.ClockTime = originalFog.ClockTime
                Lighting.FogEnd = originalFog.FogEnd
                Lighting.GlobalShadows = originalFog.GlobalShadows
                Lighting.Ambient = Color3.fromRGB(0, 0, 0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
            end
        end
    else
        local cleanup = Cache.Connections["fog"]
        if cleanup then cleanup() end
        Cache.Connections["fog"] = nil
    end
end

-- ========================================
-- ===== PARTICLES =====
-- ========================================

local function spawnParticles()
    if not Settings.ParticlesEnabled then return end
    
    for i = 1, 5 do
        task.spawn(function()
            local particle = Instance.new("Part")
            particle.Shape = Enum.PartType.Ball
            particle.Size = Vector3.new(0.5, 0.5, 0.5)
            particle.Material = Enum.Material.Neon
            particle.Color = COLORS.Purple
            particle.Transparency = 0.3
            particle.Anchored = true
            particle.CanCollide = false
            particle.CFrame = CFrame.new(
                math.random(-500, 500),
                math.random(50, 200),
                math.random(-500, 500)
            )
            particle.Parent = workspace
            
            local lifetime = math.random(3, 8)
            local startTime = tick()
            
            local conn
            conn = RunService.Heartbeat:Connect(function()
                local elapsed = tick() - startTime
                if elapsed >= lifetime or not particle or not particle.Parent then
                    pcall(function() particle:Destroy() end)
                    safeDisconnect(conn)
                    return
                end
                
                particle.CFrame = particle.CFrame * CFrame.new(
                    math.sin(elapsed) * 0.5,
                    -0.3,
                    math.cos(elapsed) * 0.5
                )
                particle.Transparency = 0.3 + (elapsed / lifetime) * 0.7
            end)
        end)
    end
end

-- ========================================
-- ===== SILENT AIM (НА МАРДЕРА) =====
-- ========================================

local function findAimTarget()
    local closestPlayer = nil
    local closestDistance = Settings.SilentAimFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and checkKnife(player) then
            local targetPos = player.Character:FindFirstChild("Head")
            if targetPos then
                local screenPos, onScreen = Camera:WorldToScreenPoint(targetPos.Position)
                if onScreen then
                    local mousePos = Mouse.Hit.Position
                    local distance = (screenPos - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local aimHeartbeat = nil

local function setupSilentAim()
    if Settings.SilentAimEnabled then
        if not aimHeartbeat then
            aimHeartbeat = RunService.Heartbeat:Connect(function()
                if not Settings.SilentAimEnabled then return end
                
                local target = findAimTarget()
                if target and target.Character then
                    local targetHead = target.Character:FindFirstChild("Head")
                    if targetHead then
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
                    end
                end
            end)
        end
    else
        safeDisconnect(aimHeartbeat)
        aimHeartbeat = nil
    end
end

-- ========================================
-- ===== MAIN UPDATE LOOP =====
-- ========================================

local mainUpdateConnection = nil

local function updateVisuals()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        
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
        if Settings.BoxMurder and role == "Murder" then
            createBox(player, COLORS.Murder)
        elseif Settings.BoxSheriff and role == "Sheriff" then
            createBox(player, COLORS.Sheriff)
        elseif Settings.BoxInnocent and role == "Innocent" then
            createBox(player, COLORS.Innocent)
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
        
        -- Visuals
        if Settings.JumpCircles then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Jump then
                createJumpCircle(player)
            end
        end
        
        if Settings.ChinaHat then
            if not player.Character:FindFirstChild("ChinaHat_Mesh") then
                createChinaHat(player)
            end
        end
        
        if Settings.Trails then
            if not player.Character:FindFirstChild("MurderTrail") then
                createTrail(player)
            end
        end
    end
    
    -- Skeleton обновления
    if Settings.SkeletonESP then
        updateAllSkeletons()
    end
    
    -- Particles
    if Settings.ParticlesEnabled and math.random(1, 10) == 1 then
        spawnParticles()
    end
end

local function startMainUpdate()
    if mainUpdateConnection then safeDisconnect(mainUpdateConnection) end
    
    mainUpdateConnection = RunService.Heartbeat:Connect(function()
        local anyActive = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP or 
                         Settings.BoxMurder or Settings.BoxSheriff or Settings.BoxInnocent or
                         Settings.ChamsEnabled or Settings.SkeletonESP or Settings.JumpCircles or
                         Settings.ChinaHat or Settings.Trails or Settings.ParticlesEnabled
        
        if anyActive then
            updateVisuals()
        end
    end)
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
            
            -- Чистим старые
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
    Callback = function(v) Settings.FlySpeed = v end
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
    Callback = function(v) Settings.SpinSpeed = v end
})

-- SILENT AIM
RageSection:Toggle({
    Title = "Silent Aim (Murders)",
    Default = false,
    Callback = function(value)
        Settings.SilentAimEnabled = value
        setupSilentAim()
    end
})

RageSection:Slider({
    Title = "Aim FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Callback = function(v) Settings.SilentAimFOV = v end
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

-- ESP TOGGLES
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

-- CHAMS
VisualSection:Toggle({
    Title = "Chams (Purple All)",
    Default = false,
    Callback = function(v) Settings.ChamsEnabled = v startMainUpdate() end
})

VisualSection:Toggle({
    Title = "Chams Murder Color",
    Default = false,
    Callback = function(v) Settings.ChamsMurder = v end
})

VisualSection:Toggle({
    Title = "Chams Sheriff Color",
    Default = false,
    Callback = function(v) Settings.ChamsSheriff = v end
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
    Title = "China Hat",
    Default = false,
    Callback = function(v) Settings.ChinaHat = v startMainUpdate() end
})

VisualSection2:Toggle({
    Title = "Trails",
    Default = false,
    Callback = function(v) Settings.Trails = v startMainUpdate() end
})

VisualSection2:Toggle({
    Title = "Purple Fog",
    Default = false,
    Callback = function(v) Settings.FogEnabled = v setupFog() end
})

VisualSection2:Toggle({
    Title = "Particles",
    Default = false,
    Callback = function(v) Settings.ParticlesEnabled = v startMainUpdate() end
})

-- ========================================
-- ===== FLING TAB =====
-- ========================================

local FlingTab = Window:Tab({ Title = "Fling", Icon = "rocket" })
local FlingSection = FlingTab:Section({ Title = "Fling", Side = "Left" })

FlingSection:Button({
    Title = "Fling Murder",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and checkKnife(player) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(math.random(-999, 999), 500, math.random(-999, 999))
                end
            end
        end
    end
})

FlingSection:Button({
    Title = "Fling Sheriff",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and checkGun(player) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(math.random(-999, 999), 500, math.random(-999, 999))
                end
            end
        end
    end
})

FlingSection:Button({
    Title = "Fling All",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(math.random(-999, 999), 500, math.random(-999, 999))
                end
            end
        end
        StarterGui:SetCore("SendNotification", {Title = "Fling", Text = "All flinged!", Duration = 2})
    end
})

-- ========================================
-- ===== SETTINGS TAB =====
-- ========================================

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "gear" })
local SettingsSection = SettingsTab:Section({ Title = "Settings", Side = "Left" })

SettingsSection:Label({
    Title = "Murder Hub v3.0",
    Description = "Optimized & Working",
    Icon = "crown"
})

SettingsSection:Button({
    Title = "Close UI",
    Callback = function() Window:Destroy() end
})

-- ========================================
-- ===== ИНИЦИАЛИЗАЦИЯ =====
-- ========================================

-- New player handler
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Settings.SkeletonESP then
            createSkeletonForPlayer(player)
        end
    end)
end)

-- Character respawn handler
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

-- Startup
startMainUpdate()

print("✅ Murder Hub v3.0 Loaded!")
StarterGui:SetCore("SendNotification", {
    Title = "Murder Hub",
    Text = "✅ v3.0 Loaded & Optimized!",
    Duration = 5
})
