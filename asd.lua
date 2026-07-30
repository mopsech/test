-- ========================================
-- ===== PLANT HUB v3.0 ULTIMATE =====
-- ========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
    game.StarterGui:SetCore("SendNotification", {Title="Error", Text="WindUI not loaded!", Duration=5})
    return
end

WindUI:SetTheme("Dark")
WindUI.TransparencyValue = 0.1

-- ========================================
-- ===== ПЛАШКА "RELEASE" =====
-- ========================================

local function createReleaseBadge()
    local badge = Instance.new("TextLabel")
    badge.Name = "ReleaseBadge"
    badge.Size = UDim2.new(0, 65, 0, 20)
    badge.Position = UDim2.new(0, 160, 0, 12)
    badge.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    badge.BackgroundTransparency = 0.15
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.Text = "Release"
    badge.TextSize = 11
    badge.Font = Enum.Font.GothamBold
    badge.BorderSizePixel = 0
    -- Легкая тень для читаемости
    badge.TextStrokeColor3 = Color3.fromRGB(138, 43, 226)
    badge.TextStrokeTransparency = 0
    -- Скругление
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = badge
    return badge
end

-- ========================================
-- ===== СОЗДАНИЕ ОКНА =====
-- ========================================

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
-- ===== ДОБАВЛЕНИЕ ПЛАШКИ ПОСЛЕ СОЗДАНИЯ ОКНА =====
-- ========================================

local badge = createReleaseBadge()
badge.Parent = Window.UIElements.Main

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

-- ========================================
-- ===== НАСТРОЙКИ =====
-- ========================================

local Settings = {
    MurderESP = false,
    SheriffESP = false,
    InnocentESP = false,
    ChamsEnabled = false,
    TracersEnabled = false,
    JumpCircles = false,
    Trails = false,
    RGBHumanoid = false,
    XRayEnabled = false,
    BloomEnabled = false,
    ColorCorrectionEnabled = false,
    VignetteEnabled = false,
    CustomSkyId = "",
    FlyEnabled = false,
    FlySpeed = 60,
    BHopEnabled = false,
    BHopSpeed = 30,
    SpinBotEnabled = false,
    SpinBotSpeed = 9999,
    AntiFlingEnabled = false,
    FovAimbotEnabled = false,
    FovRadius = 120,
    AutoFarmEnabled = false,
    AutoFarmSpeed = 20,
    AutoFarmCoinLimit = 40,
    AutoFarmCoinDelay = 0.15,
    AutoRespawn = false,
    AntiAFKEnabled = false,
}

-- ========================================
-- ===== КЭШ =====
-- ========================================

local Cache = {
    Highlights = {},
    ChamsPartsList = {},
    PostEffects = {},
    JumpTracking = {wasJumping = false},
    RGBConnection = nil,
    AutoFarmConn = nil,
    CurrentTween = nil,
    XRayParts = {},
    Tracers = {},
    TrailAttachments = {},
    FovCircle = nil,
    FovConnection = nil,
    KillAllRunning = false,
}

local COLORS = {
    Murder = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Purple = Color3.fromRGB(138, 43, 226),
    White = Color3.fromRGB(255, 255, 255),
    Red = Color3.fromRGB(255, 50, 50),
}

-- ========================================
-- ===== ХЕЛПЕРЫ =====
-- ========================================

local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local function checkKnife(player)
    if not player or not player.Character then return false end
    for _, item in ipairs(player.Character:GetDescendants()) do
        if item:IsA("Tool") then
            local n = item.Name:lower()
            if n:find("knife") or n:find("blade") then return true end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("knife") or n:find("blade") then return true end
            end
        end
    end
    return false
end

local function checkGun(player)
    if not player or not player.Character then return false end
    for _, item in ipairs(player.Character:GetDescendants()) do
        if item:IsA("Tool") then
            local n = item.Name:lower()
            if n:find("gun") or n:find("pistol") or n:find("revolver") then return true end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("gun") or n:find("pistol") or n:find("revolver") then return true end
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
    local r = getRole(player)
    if r == "Murder" then return COLORS.Murder end
    if r == "Sheriff" then return COLORS.Sheriff end
    return COLORS.Innocent
end

local function getLocalKnife()
    if not LocalPlayer.Character then return nil end
    for _, item in ipairs(LocalPlayer.Character:GetDescendants()) do
        if item:IsA("Tool") then
            local n = item.Name:lower()
            if n:find("knife") or n:find("blade") then return item end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("knife") or n:find("blade") then return item end
            end
        end
    end
    return nil
end

-- ========================================
-- ===== CHAMS (ИСПРАВЛЕНЫ) =====
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
                ogCastShadow = part.CastShadow,
            }
        end
    end
    Cache.ChamsPartsList[player.UserId] = list
end

local function applyChams(player)
    if not player or not player.Character then return end
    local char = player.Character
    
    local oldHL = char:FindFirstChild("PH_Chams")
    if oldHL then pcall(function() oldHL:Destroy() end) end
    
    if not Cache.ChamsPartsList[player.UserId] then
        cacheCharacterParts(player)
    end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not Cache.ChamsPartsList[player.UserId] then
                Cache.ChamsPartsList[player.UserId] = {}
            end
            if not Cache.ChamsPartsList[player.UserId][part] then
                Cache.ChamsPartsList[player.UserId][part] = {
                    ogMaterial = part.Material,
                    ogColor = part.Color,
                    ogTransparency = part.Transparency,
                    ogCastShadow = part.CastShadow,
                }
            end
            part.Material = Enum.Material.ForceField
            part.Color = COLORS.Purple
            part.Transparency = 0.0
            part.CastShadow = false
        end
    end
end

local function removeChams(player)
    if not player or not player.Character then return end
    local char = player.Character
    local hl = char:FindFirstChild("PH_Chams")
    if hl then pcall(function() hl:Destroy() end) end
    
    local list = Cache.ChamsPartsList[player.UserId]
    if not list then return end
    
    for part, data in pairs(list) do
        if part and part.Parent then
            pcall(function()
                part.Material = data.ogMaterial
                part.Color = data.ogColor
                part.Transparency = data.ogTransparency
                part.CastShadow = data.ogCastShadow
            end)
        end
    end
    Cache.ChamsPartsList[player.UserId] = nil
end

local function clearAllChams()
    for userId, _ in pairs(Cache.ChamsPartsList) do
        local p = Players:GetPlayerByUserId(userId)
        if p then removeChams(p) end
    end
    Cache.ChamsPartsList = {}
end

-- ========================================
-- ===== ESP =====
-- ========================================

local function createOrUpdateHighlight(player, color)
    if not player or not player.Character then return end
    local char = player.Character
    local hl = char:FindFirstChild("PH_ESP")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "PH_ESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
    end
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.Enabled = true
    Cache.Highlights[player.UserId] = hl
end

local function removeHighlight(player)
    if not player or not player.Character then return end
    local hl = player.Character:FindFirstChild("PH_ESP")
    if hl then pcall(function() hl:Destroy() end) end
    Cache.Highlights[player.UserId] = nil
end

local function clearAllHighlights()
    for _, hl in pairs(Cache.Highlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    Cache.Highlights = {}
end

-- ========================================
-- ===== TRACERS (НА HRP) =====
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
        local sp, onScreen = Camera:WorldToScreenPoint(hrp.Position)
        if not onScreen or sp.Z < 0 then
            line.Visible = false
            continue
        end
        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        line.To = Vector2.new(sp.X, sp.Y)
        line.Visible = true
        line.Color = getRoleColor(player)
    end
end

local function clearAllTracers()
    for _, line in pairs(Cache.Tracers) do
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
    if Cache.TrailAttachments.trail and Cache.TrailAttachments.trail.Parent then return end

    local att1 = Instance.new("Attachment"); att1.Position = Vector3.new(-1,0,0); att1.Parent = hrp
    local att2 = Instance.new("Attachment"); att2.Position = Vector3.new( 1,0,0); att2.Parent = hrp

    local trail           = Instance.new("Trail")
    trail.Attachment0     = att1
    trail.Attachment1     = att2
    trail.Lifetime        = 0.8
    trail.MinLength       = 0
    trail.FaceCamera      = true
    trail.LightEmission   = 1
    trail.LightInfluence  = 0
    trail.Transparency    = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Color           = ColorSequence.new(COLORS.Purple)
    trail.Parent          = hrp
    Cache.TrailAttachments = {trail=trail, att1=att1, att2=att2}
end

local function removeLocalPlayerTrail()
    if Cache.TrailAttachments.trail then pcall(function() Cache.TrailAttachments.trail:Destroy() end) end
    if Cache.TrailAttachments.att1 then pcall(function() Cache.TrailAttachments.att1:Destroy() end) end
    if Cache.TrailAttachments.att2 then pcall(function() Cache.TrailAttachments.att2:Destroy() end) end
    Cache.TrailAttachments = {}
end

-- ========================================
-- ===== SHADERS =====
-- ========================================

local function setupBloom(en)
    Lighting.Brightness = en and 1.5 or 1
end

local function setupColorCorrection(en)
    Lighting.Ambient = en and COLORS.Purple or Color3.fromRGB(0,0,0)
    Lighting.OutdoorAmbient = en and COLORS.Purple or Color3.fromRGB(0,0,0)
end

local function setupVignette(en)
    if en then
        if Cache.PostEffects.vignette then return end
        local sg = Instance.new("ScreenGui")
        sg.Name = "VignetteEffect"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,0,1,0)
        f.BackgroundColor3 = Color3.fromRGB(0,0,0)
        f.BackgroundTransparency = 0.5
        f.BorderSizePixel = 0
        f.Parent = sg
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
        Cache.PostEffects.vignette = sg
    else
        if Cache.PostEffects.vignette then
            pcall(function() Cache.PostEffects.vignette:Destroy() end)
            Cache.PostEffects.vignette = nil
        end
    end
end

-- ========================================
-- ===== SKY =====
-- ========================================

local function setupSky(skyId)
    if not skyId or skyId == "" then
        StarterGui:SetCore("SendNotification",{Title="Sky",Text="❌ Пустой ID!",Duration=2})
        return
    end
    skyId = tostring(skyId):gsub("%s+",""):gsub("rbxassetid://","")
    local url = "rbxassetid://" .. skyId
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    local sky = Instance.new("Sky")
    sky.SkyboxBk = url; sky.SkyboxDn = url; sky.SkyboxFt = url
    sky.SkyboxLf = url; sky.SkyboxRt = url; sky.SkyboxUp = url
    sky.Parent = Lighting
    StarterGui:SetCore("SendNotification",{Title="Sky",Text="✅ ID: "..skyId,Duration=2})
end

local function removeSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    StarterGui:SetCore("SendNotification",{Title="Sky",Text="Sky удалён!",Duration=2})
end

-- ========================================
-- ===== RGB HUMANOID =====
-- ========================================

local function setupRGBHumanoid()
    safeDisconnect(Cache.RGBConnection); Cache.RGBConnection = nil
    if not Settings.RGBHumanoid then
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Plastic
                    part.Color = Color3.fromRGB(255,255,255)
                    part.Transparency = 0
                end
            end
        end
        return
    end
    Cache.RGBConnection = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character then return end
        local color = Color3.fromHSV(tick() % 1, 1, 1)
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Material = Enum.Material.ForceField
                part.Color = color
                part.Transparency = 0.3
            end
        end
    end)
end

-- ========================================
-- ===== XRAY =====
-- ========================================

local function setupXRay()
    if Settings.XRayEnabled then
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsA("Terrain") then
                Cache.XRayParts[part] = part.LocalTransparencyModifier
                part.LocalTransparencyModifier = 0.6
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

local function getGroundY(origin)
    local rayOrigin = origin
    local rayDirection = Vector3.new(0, -50, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local char = LocalPlayer.Character
    if char then
        raycastParams.FilterDescendantsInstances = {char}
    end
    local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        return result.Position.Y
    end
    return origin.Y - 3
end

local function createJumpCircle(originPos)
    local groundY = getGroundY(originPos)
    local ringPos = Vector3.new(originPos.X, groundY + 0.08, originPos.Z)

    local ring = Instance.new("Part")
    ring.Shape       = Enum.PartType.Cylinder
    ring.Size        = Vector3.new(0.08, 0.5, 0.5)
    ring.Material    = Enum.Material.Neon
    ring.Color       = COLORS.Purple
    ring.Transparency = 0
    ring.Anchored    = true
    ring.CanCollide  = false
    ring.CastShadow  = false
    ring.CFrame      = CFrame.new(ringPos) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent      = Workspace

    local light = Instance.new("PointLight")
    light.Brightness = 4
    light.Color      = COLORS.Purple
    light.Range      = 20
    light.Parent     = ring

    local t0       = tick()
    local duration = 0.7
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not ring or not ring.Parent then safeDisconnect(conn) return end
        local p = (tick() - t0) / duration
        if p >= 1 then
            pcall(function() ring:Destroy() end)
            safeDisconnect(conn)
            return
        end
        local diameter = 0.5 + p * 6
        ring.Size        = Vector3.new(0.08, diameter, diameter)
        ring.Transparency = p
        ring.CFrame      = CFrame.new(ringPos) * CFrame.Angles(0, 0, math.rad(90))
        light.Brightness = 4 * (1 - p)
    end)
end

local function updateJumpCircles()
    if not Settings.JumpCircles or not LocalPlayer.Character then return end
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local isJumping = hum:GetState() == Enum.HumanoidStateType.Jumping
    if isJumping and not Cache.JumpTracking.wasJumping then
        createJumpCircle(hrp.Position)
    end
    Cache.JumpTracking.wasJumping = isJumping
end

-- ========================================
-- ===== FOV AIMBOT =====
-- ========================================

local PREDICT_TIME = 0.3

local function getPredictedHRPPos(player)
    if not player or not player.Character then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local vel = hrp.AssemblyLinearVelocity
    return hrp.Position + Vector3.new(vel.X, 0, vel.Z) * PREDICT_TIME
end

local function getClosestMurderInFov()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestP = nil
    local bestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer  then continue end
        if not checkKnife(player) then continue end
        if not player.Character   then continue end
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local sp, onScreen = Camera:WorldToScreenPoint(hrp.Position)
        if not onScreen or sp.Z < 0 then continue end

        local d = (center - Vector2.new(sp.X, sp.Y)).Magnitude
        if d <= Settings.FovRadius and d < bestDist then
            bestDist = d
            bestP    = player
        end
    end
    return bestP
end

local function createFovCircle()
    if Cache.FovCircle then pcall(function() Cache.FovCircle:Remove() end) end
    local c = Drawing.new("Circle")
    c.Radius = Settings.FovRadius
    c.Color = COLORS.White
    c.Thickness = 1.5
    c.Transparency = 0.7
    c.Filled = false
    c.Visible = false
    c.NumSides = 64
    Cache.FovCircle = c
end

local function setupFovAimbot()
    safeDisconnect(Cache.FovConnection)
    Cache.FovConnection = nil
    if Cache.FovCircle then Cache.FovCircle.Visible = false end
    if not Settings.FovAimbotEnabled then return end
    if not Cache.FovCircle then createFovCircle() end

    local circle = Cache.FovCircle

    Cache.FovConnection = RunService.RenderStepped:Connect(function()
        if not Settings.FovAimbotEnabled then
            circle.Visible = false
            return
        end

        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        circle.Position = center
        circle.Radius   = Settings.FovRadius
        circle.Visible  = true

        local target = getClosestMurderInFov()

        if target then
            circle.Color     = COLORS.Red
            circle.Thickness = 2.0

            local predictedPos = getPredictedHRPPos(target)
            if not predictedPos then return end

            local camPos = Camera.CFrame.Position
            local newCF = CFrame.lookAt(camPos, predictedPos, Camera.CFrame.UpVector)
            Camera.CFrame = newCF
        else
            circle.Color     = COLORS.White
            circle.Thickness = 1.5
        end
    end)
end

-- ========================================
-- ===== KILL ALL =====
-- ========================================

local function stopKillAll()
    Cache.KillAllRunning = false
    StarterGui:SetCore("SendNotification",{Title="Kill All",Text="⏹ Остановлен!",Duration=2})
end

local function findKillRemote()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("kill") or n:find("stab") or n:find("knife") or n:find("murder") or n:find("hit") then
                return obj
            end
        end
    end
    return nil
end

local function killAllPlayers()
    if Cache.KillAllRunning then stopKillAll() return end

    if not getLocalKnife() then
        StarterGui:SetCore("SendNotification",{Title="Kill All",Text="❌ Нож не найден!",Duration=3})
        return
    end

    Cache.KillAllRunning = true
    local killRemote     = findKillRemote()
    StarterGui:SetCore("SendNotification",{Title="Kill All",Text="🔪 Запущен!",Duration=2})

    task.spawn(function()
        local lastKnifeCheck = tick()

        while Cache.KillAllRunning do
            if tick() - lastKnifeCheck >= 1 then
                lastKnifeCheck = tick()
                if not getLocalKnife() then
                    Cache.KillAllRunning = false
                    StarterGui:SetCore("SendNotification",{
                        Title="Kill All", Text="🚫 Нож пропал! Остановлен.", Duration=3
                    })
                    break
                end
            end

            if not LocalPlayer.Character then task.wait(1) continue end
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then task.wait(1) continue end

            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer
                    and p.Character
                    and p.Character:FindFirstChild("HumanoidRootPart")
                    and p.Character:FindFirstChildOfClass("Humanoid")
                    and p.Character.Humanoid.Health > 0
                then
                    table.insert(targets, p)
                end
            end

            for _, target in ipairs(targets) do
                if not Cache.KillAllRunning then break end
                if not target.Character then continue end
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChildOfClass("Humanoid")
                if not tHRP or not tHum or tHum.Health <= 0 then continue end

                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 1.5)
                task.wait(0.05)

                local k = getLocalKnife()
                if k then pcall(function() LocalPlayer.Character.Humanoid:EquipTool(k) end) end
                task.wait(0.1)

                if killRemote then
                    pcall(function() killRemote:FireServer(target) end)
                    pcall(function() killRemote:FireServer(target.Character) end)
                    pcall(function() killRemote:FireServer(tHRP) end)
                end

                local clicks = 0
                while Cache.KillAllRunning
                    and target.Character
                    and target.Character:FindFirstChildOfClass("Humanoid")
                    and target.Character.Humanoid.Health > 0
                    and clicks < 8
                do
                    pcall(function() mouse1press()   end) task.wait(0.03)
                    pcall(function() mouse1release()  end)
                    pcall(function()
                        firetouchinterest(myHRP, tHRP, 0)
                        task.wait(0.02)
                        firetouchinterest(myHRP, tHRP, 1)
                    end)
                    clicks = clicks + 1
                    task.wait(0.05)
                end
                task.wait(0.2)
            end
            task.wait(0.5)
        end
    end)
end

-- ========================================
-- ===== ANTI-AFK =====
-- ========================================

local afkConn = nil

local function setupAntiAFK()
    safeDisconnect(afkConn); afkConn = nil
    if not Settings.AntiAFKEnabled then return end
    local last = 0
    afkConn = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character then return end
        local now = tick()
        if now - last > 60 then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump = true; last = now end
        end
    end)
end

-- ========================================
-- ===== AUTO FARM =====
-- ========================================

local function getCurrentCoins()
    local ok, res = pcall(function()
        return LocalPlayer.PlayerGui.MainGUI.Game.CoinBags.Container.Coin.CurrencyFrame.Icon.Coins.Text
    end)
    return ok and (tonumber(res) or 0) or 0
end

local function getValidCoins()
    local coins = {}
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return coins end
    for _, map in pairs(Workspace:GetChildren()) do
        local container = map:FindFirstChild("CoinContainer")
        if container then
            for _, coin in pairs(container:GetChildren()) do
                if coin.Name == "Coin_Server" and coin:IsA("BasePart") and coin:FindFirstChild("TouchInterest") then
                    table.insert(coins, {part=coin, distance=(hrp.Position-coin.Position).Magnitude})
                end
            end
        end
    end
    table.sort(coins, function(a,b) return a.distance < b.distance end)
    return coins
end

local function tweenToCoin(coin)
    if not coin or not coin.Parent or not coin:FindFirstChild("TouchInterest") then return false end
    local char = LocalPlayer.Character; if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    local target = coin.Position + Vector3.new(0, 2, 0)
    if (hrp.Position - target).Magnitude < 5 then return true end
    if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
    Cache.CurrentTween = TweenService:Create(hrp,
        TweenInfo.new((hrp.Position-target).Magnitude / Settings.AutoFarmSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {CFrame = CFrame.new(target)}
    )
    hum.Sit = true
    Cache.CurrentTween:Play()
    local done = false
    local c; c = Cache.CurrentTween.Completed:Connect(function() done=true safeDisconnect(c) end)
    local t0 = tick()
    while not done and Settings.AutoFarmEnabled do
        task.wait(0.1)
        if not coin or not coin.Parent or not coin:FindFirstChild("TouchInterest") then
            if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
            hum.Sit = false; return false
        end
        if tick() - t0 > 30 then
            if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
            hum.Sit = false; return false
        end
    end
    hum.Sit = false; return done
end

local function collectCoin(coin)
    if not coin or not coin.Parent then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        firetouchinterest(hrp, coin, 0)
        task.wait(0.05)
        firetouchinterest(hrp, coin, 1)
    end)
end

local function farmLoop()
    while Settings.AutoFarmEnabled do
        if not LocalPlayer.Character then task.wait(1) continue end
        if getCurrentCoins() >= Settings.AutoFarmCoinLimit then
            if Settings.AutoRespawn then
                pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
                task.wait(5); continue
            else
                Settings.AutoFarmEnabled = false
                StarterGui:SetCore("SendNotification",{Title="AutoFarm",Text="Bag full! ✅",Duration=3})
                break
            end
        end
        local coins = getValidCoins()
        if #coins == 0 then task.wait(2) continue end
        local ok = tweenToCoin(coins[1].part)
        if ok and Settings.AutoFarmEnabled then
            collectCoin(coins[1].part)
            task.wait(Settings.AutoFarmCoinDelay)
        end
        task.wait(0.1)
    end
    Cache.AutoFarmConn = nil
end

local function setupAutoFarm()
    if Settings.AutoFarmEnabled then
        if not LocalPlayer.Character then return end
        Cache.AutoFarmConn = task.spawn(farmLoop)
        StarterGui:SetCore("SendNotification",{Title="AutoFarm",Text="Запущен! 🚀",Duration=3})
    else
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = false end
        end
        if Cache.CurrentTween then
            pcall(function() Cache.CurrentTween:Cancel() end)
            Cache.CurrentTween = nil
        end
    end
end

-- ========================================
-- ===== FLY (БЕЗ КНОПОК) =====
-- ========================================

local flyConn = nil
local isFlying = false
local flyBV = nil
local flyBG = nil
local origGravity = workspace.Gravity

local function stopFly()
    isFlying = false
    safeDisconnect(flyConn); flyConn = nil
    workspace.Gravity = origGravity
    
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
end

local function startFly()
    if not LocalPlayer.Character then return end
    if isFlying then stopFly() end
    
    local char = LocalPlayer.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    isFlying = true
    origGravity = workspace.Gravity
    workspace.Gravity = 0
    hum.PlatformStand = true
    
    for _, cls in ipairs({"BodyVelocity", "BodyGyro"}) do
        local old = hrp:FindFirstChildOfClass(cls)
        if old then old:Destroy() end
    end
    
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e8, 1e8, 1e8)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = hrp
    
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
    flyBG.P = 3000
    flyBG.D = 200
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    
    safeDisconnect(flyConn)
    flyConn = RunService.RenderStepped:Connect(function()
        if not isFlying or not char or not char.Parent or not hrp or not hrp.Parent then
            stopFly()
            return
        end
        
        local camCF = Camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)
        
        if UserInputService.KeyboardEnabled then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        end
        
        if UserInputService.KeyboardEnabled then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir += Vector3.new(0, Settings.FlySpeed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir -= Vector3.new(0, Settings.FlySpeed, 0)
            end
        end
        
        local horiz = Vector3.new(moveDir.X, 0, moveDir.Z)
        if horiz.Magnitude > 0.01 then
            horiz = horiz.Unit * Settings.FlySpeed
        end
        
        local finalVel = Vector3.new(horiz.X, moveDir.Y, horiz.Z)
        flyBV.Velocity = finalVel
        flyBG.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, camCF:ToEulerAnglesYXZ(), 0)
    end)
end

-- ========================================
-- ===== BUNNY HOP =====
-- ========================================

local bhopConn = nil
local bhopBV = nil
local bhopActive = false

local function stopBHop()
    bhopActive = false
    safeDisconnect(bhopConn); bhopConn = nil
    if bhopBV then pcall(function() bhopBV:Destroy() end) bhopBV = nil end
end

local function startBHop()
    if not LocalPlayer.Character then return end
    if bhopActive then stopBHop() end

    local char = LocalPlayer.Character
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    bhopActive = true

    if bhopBV then pcall(function() bhopBV:Destroy() end) bhopBV = nil end
    bhopBV          = Instance.new("BodyVelocity")
    bhopBV.Name     = "BHopBV"
    bhopBV.MaxForce = Vector3.new(1e5, 0, 1e5)
    bhopBV.Velocity = Vector3.new(0, 0, 0)
    bhopBV.Parent   = hrp

    local lastJump = 0
    local COOLDOWN = 0.15

    safeDisconnect(bhopConn)
    bhopConn = RunService.Stepped:Connect(function()
        if not bhopActive then stopBHop() return end

        char = LocalPlayer.Character
        if not char then return end
        hum  = char:FindFirstChildOfClass("Humanoid")
        hrp  = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        if not bhopBV or not bhopBV.Parent then
            bhopBV          = Instance.new("BodyVelocity")
            bhopBV.Name     = "BHopBV"
            bhopBV.MaxForce = Vector3.new(1e5, 0, 1e5)
            bhopBV.Velocity = Vector3.new(0, 0, 0)
            bhopBV.Parent   = hrp
        end

        local moveDir  = hum.MoveDirection
        local isMoving = moveDir.Magnitude > 0.1
        local state    = hum:GetState()
        local onGround = (
            state == Enum.HumanoidStateType.Running or
            state == Enum.HumanoidStateType.Landed  or
            state == Enum.HumanoidStateType.RunningNoPhysics
        )

        if isMoving then
            local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
            if horizontal.Magnitude > 0.01 then
                bhopBV.Velocity = horizontal.Unit * Settings.BHopSpeed
            end
            if onGround and tick() - lastJump > COOLDOWN then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                lastJump = tick()
            end
        else
            bhopBV.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- ========================================
-- ===== SPIN BOT =====
-- ========================================

local SpinBot = {Enabled=false, Speed=9999}
local spinConn = nil

local function setupSpinBot()
    safeDisconnect(spinConn); spinConn = nil
    if not SpinBot.Enabled then return end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinBot.Speed * dt), 0) end
    end)
end

-- ========================================
-- ===== ANTI FLING =====
-- ========================================

local antiFlingConn = nil
local antiFlingNewConn = nil

local function stopAntiFling()
    safeDisconnect(antiFlingConn); antiFlingConn = nil
    safeDisconnect(antiFlingNewConn); antiFlingNewConn = nil
end

local function setupAntiFling()
    stopAntiFling()
    if not Settings.AntiFlingEnabled then return end

    antiFlingConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiFlingEnabled then stopAntiFling() return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
        local char = LocalPlayer.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        if hrp.AssemblyLinearVelocity.Magnitude > 200 then
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
        if hrp.AssemblyAngularVelocity.Magnitude > 20 then
            hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
    end)

    antiFlingNewConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(charNew)
            task.wait(0.5)
            if not Settings.AntiFlingEnabled then return end
            for _, part in ipairs(charNew:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end)
end

-- ========================================
-- ===== NOCLIP =====
-- ========================================

local noclipConn = nil

-- ========================================
-- ===== MAIN UPDATE LOOP =====
-- ========================================

local mainConn = nil

local function updateVisuals()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if Settings.ChamsEnabled then applyChams(player)
            elseif Cache.ChamsPartsList[player.UserId] then removeChams(player) end
            continue
        end
        if not player.Character then continue end
        local role = getRole(player)
        if Settings.MurderESP and role=="Murder" then createOrUpdateHighlight(player,COLORS.Murder)
        elseif Settings.SheriffESP and role=="Sheriff" then createOrUpdateHighlight(player,COLORS.Sheriff)
        elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player,COLORS.Innocent)
        else removeHighlight(player) end
        if Settings.ChamsEnabled then applyChams(player)
        elseif Cache.ChamsPartsList[player.UserId] then removeChams(player) end
        if Settings.TracersEnabled and not Cache.Tracers[player.UserId] then createTracer(player) end
    end
    if Settings.TracersEnabled then updateTracers() else clearAllTracers() end
    if Settings.Trails then
        if LocalPlayer.Character then createLocalPlayerTrail() end
    else
        removeLocalPlayerTrail()
    end
end

local function startMainUpdate()
    safeDisconnect(mainConn)
    mainConn = RunService.Heartbeat:Connect(function()
        local any = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP
            or Settings.ChamsEnabled or Settings.Trails or Settings.TracersEnabled
        if any then updateVisuals() end
        if Settings.JumpCircles then updateJumpCircles() end
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
                    StarterGui:SetCore("SendNotification",{Title="⚠️ SHERIFF",Text=player.Name.." is dead!",Duration=3})
                end
            end)
        end
    end
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Died:Connect(function()
                    if checkGun(player) then
                        StarterGui:SetCore("SendNotification",{Title="⚠️ SHERIFF",Text=player.Name.." is dead!",Duration=3})
                    end
                end)
            end
        end)
    end)
end

-- ========================================
-- ===== UI =====
-- ========================================

-- RAGE
local RageTab = Window:Tab({Title="Rage", Icon="sword"})
local RageL = RageTab:Section({Title="Movement", Side="Left"})
local RageR = RageTab:Section({Title="Flight", Side="Right"})

RageR:Toggle({Title="Fly (Mobile+PC)", Default=false, Callback=function(v)
    Settings.FlyEnabled = v
    if v then startFly() else stopFly() end
end})
RageR:Input({Title="Fly Speed", Default="60", Placeholder="60", Callback=function(v)
    local n=tonumber(v); if n then Settings.FlySpeed=n end
end})

RageL:Toggle({Title="Bunny Hop (Mobile+PC)", Default=false, Callback=function(v)
    Settings.BHopEnabled = v
    if v then startBHop() else stopBHop() end
end})
RageL:Input({Title="BHop Speed", Default="30", Placeholder="30", Callback=function(v)
    local n=tonumber(v); if n then Settings.BHopSpeed=n end
end})

RageL:Toggle({Title="Spin Bot", Default=false, Callback=function(v)
    SpinBot.Enabled = v; setupSpinBot()
end})
RageL:Input({Title="Spin Speed", Default="9999", Placeholder="9999", Callback=function(v)
    local n=tonumber(v); if n then SpinBot.Speed=n end
end})

-- COMBAT
local CombatTab = Window:Tab({Title="Combat", Icon="crosshair"})
local CombatL = CombatTab:Section({Title="Combat", Side="Left"})
local CombatR = CombatTab:Section({Title="Aimbot", Side="Right"})

CombatL:Toggle({Title="Noclip", Default=false, Callback=function(v)
    safeDisconnect(noclipConn); noclipConn = nil
    if not v then return end
    noclipConn = RunService.Stepped:Connect(function()
        if not LocalPlayer.Character then return end
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end})

CombatL:Toggle({Title="Anti Fling", Default=false, Callback=function(v)
    Settings.AntiFlingEnabled = v; setupAntiFling()
end})

CombatL:Button({Title="Grab Gun", Callback=function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol")) then
            local handle = obj:FindFirstChild("Handle")
            if handle and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0,3,0))
                    StarterGui:SetCore("SendNotification",{Title="Gun",Text="Teleported!",Duration=2})
                    break
                end
            end
        end
    end
end})

CombatL:Button({Title="🔪 Kill All (снова = стоп)", Callback=function()
    killAllPlayers()
end})

CombatR:Toggle({Title="FOV Aimbot (Murder→HRP)", Default=false, Callback=function(v)
    Settings.FovAimbotEnabled = v
    if v then createFovCircle() end
    setupFovAimbot()
end})
CombatR:Input({Title="FOV Radius", Default="120", Placeholder="120", Callback=function(v)
    local n=tonumber(v)
    if n then
        Settings.FovRadius = math.clamp(n, 10, 600)
        if Cache.FovCircle then Cache.FovCircle.Radius = Settings.FovRadius end
    end
end})

-- VISUAL
local VisualTab = Window:Tab({Title="Visual", Icon="eye"})
local VisualL = VisualTab:Section({Title="ESP & Effects", Side="Left"})
local VisualR = VisualTab:Section({Title="World & Sky", Side="Right"})

VisualL:Toggle({Title="ESP Murder", Default=false, Callback=function(v) Settings.MurderESP=v startMainUpdate() end})
VisualL:Toggle({Title="ESP Sheriff", Default=false, Callback=function(v) Settings.SheriffESP=v startMainUpdate() end})
VisualL:Toggle({Title="ESP Innocent", Default=false, Callback=function(v) Settings.InnocentESP=v startMainUpdate() end})
VisualL:Toggle({Title="Chams (Purple, AlwaysOnTop)", Default=false, Callback=function(v)
    Settings.ChamsEnabled = v
    if v then for _,p in ipairs(Players:GetPlayers()) do cacheCharacterParts(p) end
    else clearAllChams() end
    startMainUpdate()
end})
VisualL:Toggle({Title="Tracers (HRP)", Default=false, Callback=function(v)
    Settings.TracersEnabled = v
    if v then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then createTracer(p) end end
    else clearAllTracers() end
    startMainUpdate()
end})
VisualL:Toggle({Title="Jump Circles (Floor)", Default=false, Callback=function(v)
    Settings.JumpCircles = v; startMainUpdate()
end})
VisualL:Toggle({Title="Purple Trail", Default=false, Callback=function(v)
    Settings.Trails = v
    if v then createLocalPlayerTrail() else removeLocalPlayerTrail() end
    startMainUpdate()
end})
VisualL:Toggle({Title="RGB Humanoid", Default=false, Callback=function(v)
    Settings.RGBHumanoid = v; setupRGBHumanoid()
end})
VisualL:Toggle({Title="XRay", Default=false, Callback=function(v)
    Settings.XRayEnabled = v; setupXRay()
end})

VisualR:Toggle({Title="Bloom", Default=false, Callback=function(v) Settings.BloomEnabled=v setupBloom(v) end})
VisualR:Toggle({Title="Color Correction", Default=false, Callback=function(v) Settings.ColorCorrectionEnabled=v setupColorCorrection(v) end})
VisualR:Toggle({Title="Vignette", Default=false, Callback=function(v) Settings.VignetteEnabled=v setupVignette(v) end})

VisualR:Input({Title="Sky ID", Default="", Placeholder="rbxassetid://...", Callback=function(v) Settings.CustomSkyId=v end})
VisualR:Button({Title="Apply Custom Sky", Callback=function() setupSky(Settings.CustomSkyId) end})
VisualR:Button({Title="Remove Sky", Callback=function() removeSky() end})
VisualR:Button({Title="🐹 Добрый хомяк", Callback=function() setupSky("135457808082953") end})
VisualR:Button({Title="🌩 Ночные тучи", Callback=function() setupSky("100140210065251") end})
VisualR:Button({Title="🚀 Космос", Callback=function() setupSky("97059048850342") end})

-- AUTO FARM
local FarmTab = Window:Tab({Title="Auto Farm", Icon="star"})
local FarmL = FarmTab:Section({Title="Farm", Side="Left"})
local FarmR = FarmTab:Section({Title="Config", Side="Right"})

FarmL:Toggle({Title="Auto Farm", Default=false, Callback=function(v) Settings.AutoFarmEnabled=v setupAutoFarm() end})
FarmL:Toggle({Title="Auto Respawn (Full Bag)", Default=false, Callback=function(v) Settings.AutoRespawn=v end})
FarmR:Input({Title="Farm Speed", Default="20", Placeholder="20", Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmSpeed=n end end})
FarmR:Input({Title="Coin Limit", Default="40", Placeholder="40", Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmCoinLimit=n end end})
FarmR:Input({Title="Coin Delay", Default="0.15", Placeholder="0.15", Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmCoinDelay=n end end})

-- MISC
local MiscTab = Window:Tab({Title="Misc", Icon="timer"})
local MiscL = MiscTab:Section({Title="Misc", Side="Left"})

MiscL:Toggle({Title="Anti-AFK", Default=false, Callback=function(v)
    Settings.AntiAFKEnabled = v; setupAntiAFK()
end})
MiscL:Button({Title="Rejoin", Callback=function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end})

-- ========================================
-- ===== PLAYER EVENTS =====
-- ========================================

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Settings.ChamsEnabled then cacheCharacterParts(player) applyChams(player) end
        if Settings.TracersEnabled and player~=LocalPlayer then createTracer(player) end
        if Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP then
            local r=getRole(player)
            if Settings.MurderESP and r=="Murder" then createOrUpdateHighlight(player,COLORS.Murder)
            elseif Settings.SheriffESP and r=="Sheriff" then createOrUpdateHighlight(player,COLORS.Sheriff)
            elseif Settings.InnocentESP and r=="Innocent" then createOrUpdateHighlight(player,COLORS.Innocent) end
        end
        if Settings.AntiFlingEnabled and player~=LocalPlayer then
            task.spawn(function()
                task.wait(0.5)
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide=false end
                    end
                end
            end)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    Cache.ChamsPartsList[player.UserId] = nil
    Cache.Highlights[player.UserId] = nil
    if Cache.Tracers[player.UserId] then
        pcall(function() Cache.Tracers[player.UserId]:Remove() end)
        Cache.Tracers[player.UserId] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllHighlights(); clearAllChams(); clearAllTracers()
    Cache.ChamsPartsList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if Settings.ChamsEnabled then cacheCharacterParts(player) applyChams(player) end
        if Settings.TracersEnabled and player~=LocalPlayer then createTracer(player) end
        if Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP then
            local r=getRole(player)
            if     Settings.MurderESP   and r=="Murder"   then createOrUpdateHighlight(player,COLORS.Murder)
            elseif Settings.SheriffESP  and r=="Sheriff"  then createOrUpdateHighlight(player,COLORS.Sheriff)
            elseif Settings.InnocentESP and r=="Innocent" then createOrUpdateHighlight(player,COLORS.Innocent) end
        end
    end

    setupRGBHumanoid()
    Cache.JumpTracking = {wasJumping=false}

    if Settings.Trails          then createLocalPlayerTrail() end
    if Settings.FlyEnabled      then task.wait(0.5) startFly()  end
    if Settings.BHopEnabled     then startBHop() end
    if Settings.AntiFlingEnabled then setupAntiFling() end
    if Settings.FovAimbotEnabled then setupFovAimbot() end
end)

-- ========================================
-- ===== INIT =====
-- ========================================

startMainUpdate()
setupSheriffDeadNotif()
createFovCircle()

StarterGui:SetCore("SendNotification",{
    Title = "PlanetHub v3.0",
    Text = "✅ Loaded! Fly+BHop Mobile, JumpCircles Fixed, FOV→HRP",
    Duration = 4
})
