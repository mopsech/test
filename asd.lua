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

-- ========================================
-- ===== НАСТРОЙКИ =====
-- ========================================

local Settings = {
    -- ESP
    MurderESP = false,
    SheriffESP = false,
    InnocentESP = false,
    ChamsEnabled = false,
    TracersEnabled = false,
    JumpCircles = false,
    Trails = false,
    RGBHumanoid = false,
    XRayEnabled = false,

    -- Shaders
    BloomEnabled = false,
    ColorCorrectionEnabled = false,
    VignetteEnabled = false,

    -- Sky
    CustomSkyId = "",

    -- Movement
    FlyEnabled = false,
    FlySpeed = 100,
    BHopEnabled = false,
    BHopSpeed = 30,
    SpinBotEnabled = false,
    SpinBotSpeed = 9999,

    -- Combat
    NoclipEnabled = false,
    AntiFlingEnabled = false,
    FovAimbotEnabled = false,
    FovRadius = 120,

    -- Farm
    AutoFarmEnabled = false,
    AutoFarmSpeed = 20,
    AutoFarmCoinLimit = 40,
    AutoFarmCoinDelay = 0.15,
    AutoRespawn = false,

    -- Misc
    AntiAFKEnabled = false,
}

-- ========================================
-- ===== КЭШ =====
-- ========================================

local Cache = {
    Highlights = {},
    Visuals = {},
    Connections = {},
    ChamsPartsList = {},
    PostEffects = {},
    JumpTracking = {},
    RGBConnection = nil,
    AutoFarmConnection = nil,
    CurrentTween = nil,
    XRayParts = {},
    Tracers = {},
    TrailAttachments = {},
    FovCircle = nil,
    FovConnection = nil,
    AimbotConnection = nil,
}

local COLORS = {
    Murder  = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent= Color3.fromRGB(0, 255, 0),
    Purple  = Color3.fromRGB(138, 43, 226),
    White   = Color3.fromRGB(255, 255, 255),
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
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
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
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
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
    local r = getRole(player)
    if r == "Murder" then return COLORS.Murder end
    if r == "Sheriff" then return COLORS.Sheriff end
    return COLORS.Innocent
end

local function getKnife()
    if not LocalPlayer.Character then return nil end
    for _, item in ipairs(LocalPlayer.Character:GetDescendants()) do
        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then
            return item
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then
                return item
            end
        end
    end
    return nil
end

-- ========================================
-- ===== CHAMS (видно сквозь стены) =====
-- ========================================

-- Используем SelectionBox + Highlight с правильными настройками
-- чтобы чамс был виден через любые стены

local function cacheCharacterParts(player)
    if not player or not player.Character then return end
    local list = {}
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            list[part] = {
                ogMaterial    = part.Material,
                ogColor       = part.Color,
                ogTransparency= part.Transparency,
                ogCastShadow  = part.CastShadow,
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

    -- Highlight с AlwaysOnTop обеспечивает видимость через стены
    local char = player.Character
    local existing = char:FindFirstChild("PH_Chams")
    if not existing then
        local hl = Instance.new("Highlight")
        hl.Name = "PH_Chams"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = COLORS.Purple
        hl.OutlineColor = COLORS.Purple
        hl.FillTransparency = 0.0   -- полностью непрозрачный чамс
        hl.OutlineTransparency = 0
        hl.Enabled = true
        hl.Parent = char
    end

    -- Дополнительно меняем материал на ForceField для свечения
    for part, _ in pairs(list) do
        if part and part.Parent then
            pcall(function()
                part.Material = Enum.Material.ForceField
                part.Color = COLORS.Purple
                part.CastShadow = false
            end)
        end
    end
end

local function removeChams(player)
    if not player or not player.Character then return end

    -- Убираем Highlight
    local hl = player.Character:FindFirstChild("PH_Chams")
    if hl then pcall(function() hl:Destroy() end) end

    local list = Cache.ChamsPartsList[player.UserId]
    if not list then return end
    for part, data in pairs(list) do
        if part and part.Parent then
            pcall(function()
                part.Material     = data.ogMaterial
                part.Color        = data.ogColor
                part.Transparency = data.ogTransparency
                part.CastShadow   = data.ogCastShadow
            end)
        end
    end
    Cache.ChamsPartsList[player.UserId] = nil
end

local function clearAllChams()
    for userId, _ in pairs(Cache.ChamsPartsList) do
        local player = Players:GetPlayerByUserId(userId)
        if player then removeChams(player) end
    end
    Cache.ChamsPartsList = {}
end

-- ========================================
-- ===== ESP (Highlight) =====
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
        if not head then line.Visible = false continue end
        local sp, onScreen = Camera:WorldToScreenPoint(head.Position)
        if not onScreen or sp.Z < 0 then line.Visible = false continue end
        line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        line.To   = Vector2.new(sp.X, sp.Y)
        line.Visible = true
        line.Color   = getRoleColor(player)
    end
end

local function clearAllTracers()
    for _, line in pairs(Cache.Tracers) do pcall(function() line:Remove() end) end
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
    att1.Position = Vector3.new(-1, 0, 0)
    att1.Parent = hrp

    local att2 = Instance.new("Attachment")
    att2.Position = Vector3.new(1, 0, 0)
    att2.Parent = hrp

    local trail = Instance.new("Trail")
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
    Cache.TrailAttachments = {trail=trail, att1=att1, att2=att2}
end

local function removeLocalPlayerTrail()
    if Cache.TrailAttachments.trail  then pcall(function() Cache.TrailAttachments.trail:Destroy()  end) end
    if Cache.TrailAttachments.att1   then pcall(function() Cache.TrailAttachments.att1:Destroy()   end) end
    if Cache.TrailAttachments.att2   then pcall(function() Cache.TrailAttachments.att2:Destroy()   end) end
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
        Lighting.Ambient = Color3.fromRGB(0,0,0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
    end
end

local function setupVignette(enabled)
    if enabled then
        if not Cache.PostEffects["vignette"] then
            local sg = Instance.new("ScreenGui")
            sg.Name = "VignetteEffect"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1,0,1,0)
            f.BackgroundColor3 = Color3.fromRGB(0,0,0)
            f.BackgroundTransparency = 0.5
            f.BorderSizePixel = 0
            f.Parent = sg
            sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
            Cache.PostEffects["vignette"] = sg
        end
    else
        if Cache.PostEffects["vignette"] then
            pcall(function() Cache.PostEffects["vignette"]:Destroy() end)
            Cache.PostEffects["vignette"] = nil
        end
    end
end

-- ========================================
-- ===== SKY =====
-- ========================================

local function setupSky(skyId)
    if not skyId or skyId == "" then
        StarterGui:SetCore("SendNotification", {Title="Sky", Text="❌ Пустой ID!", Duration=2})
        return
    end

    -- Чистим ID от лишнего
    skyId = tostring(skyId):gsub("%s+","")
    if skyId:find("rbxassetid://") then
        skyId = skyId:gsub("rbxassetid://","")
    end

    local assetUrl = "rbxassetid://" .. skyId

    -- Удаляем старое небо
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end

    local sky = Instance.new("Sky")
    sky.SkyboxBk = assetUrl
    sky.SkyboxDn = assetUrl
    sky.SkyboxFt = assetUrl
    sky.SkyboxLf = assetUrl
    sky.SkyboxRt = assetUrl
    sky.SkyboxUp = assetUrl
    sky.Parent = Lighting

    StarterGui:SetCore("SendNotification", {
        Title = "Sky",
        Text  = "✅ Sky применён! ID: " .. skyId,
        Duration = 2
    })
end

local function removeSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    StarterGui:SetCore("SendNotification", {Title="Sky", Text="Sky удалён!", Duration=2})
end

-- ========================================
-- ===== RGB HUMANOID =====
-- ========================================

local function setupRGBHumanoid()
    if Settings.RGBHumanoid then
        safeDisconnect(Cache.RGBConnection)
        Cache.RGBConnection = RunService.Heartbeat:Connect(function()
            if not Settings.RGBHumanoid or not LocalPlayer.Character then return end
            local color = Color3.fromHSV(tick() % 1, 1, 1)
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
                    part.Color = Color3.fromRGB(255,255,255)
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

local function createJumpCircleAtPosition(position)
    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.05, 0.5, 0.5)
    ring.Material = Enum.Material.Neon
    ring.Color = COLORS.Purple
    ring.Transparency = 0
    ring.Anchored = true
    ring.CanCollide = false
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
    ring.Parent = Workspace

    local light = Instance.new("PointLight")
    light.Brightness = 5
    light.Color = COLORS.Purple
    light.Range = 25
    light.Parent = ring

    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not ring or not ring.Parent then safeDisconnect(conn) return end
        local p = (tick()-startTime)/0.8
        if p >= 1 then pcall(function() ring:Destroy() end) safeDisconnect(conn) return end
        ring.Size = Vector3.new(0.05, 0.5+p*4.5, 0.5+p*4.5)
        ring.Transparency = p
        light.Brightness = 5*(1-p)
        ring.CFrame = CFrame.new(position)*CFrame.Angles(0,0,math.rad(90))
    end)
end

local function updateJumpCircles()
    if not Settings.JumpCircles or not LocalPlayer.Character then return end
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local tracking = Cache.JumpTracking
    local isJumping = hum:GetState() == Enum.HumanoidStateType.Jumping
    if isJumping and not tracking.wasJumping then
        createJumpCircleAtPosition(hrp.Position)
    end
    tracking.wasJumping = isJumping
end

-- ========================================
-- ===== FOV AIMBOT =====
-- ========================================

local PREDICT_TIME = 0.4

local function getPredictedPosition(player)
    if not player or not player.Character then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return hrp.Position + hrp.AssemblyLinearVelocity * PREDICT_TIME
end

local function getNearestMurderInFov()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not checkKnife(player) then continue end
        if not player.Character then continue end
        local pos = getPredictedPosition(player)
        if not pos then continue end
        local sp, onScreen = Camera:WorldToScreenPoint(pos)
        if not onScreen or sp.Z < 0 then continue end
        local d = (center - Vector2.new(sp.X, sp.Y)).Magnitude
        if d <= Settings.FovRadius and d < bestDist then
            bestDist = d
            best = {player=player, screenPos=Vector2.new(sp.X,sp.Y), worldPos=pos}
        end
    end
    return best
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
        if not Settings.FovAimbotEnabled then circle.Visible = false return end
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        circle.Position = center
        circle.Radius   = Settings.FovRadius
        circle.Visible  = true

        local target = getNearestMurderInFov()
        if target then
            circle.Color = Color3.fromRGB(255,50,50)
            circle.Thickness = 2
            local _, _, depth = Camera:WorldToScreenPoint(target.worldPos)
            if depth > 0 then
                local dx = target.screenPos.X - center.X
                local dy = target.screenPos.Y - center.Y
                local fov = math.rad(Camera.FieldOfView)
                local fl  = (Camera.ViewportSize.Y/2) / math.tan(fov/2)
                local ax  = math.atan(dx/fl)
                local ay  = math.atan(dy/fl)
                Camera.CFrame = Camera.CFrame
                    * CFrame.Angles(0,-ax,0)
                    * CFrame.Angles(-ay,0,0)
            end
        else
            circle.Color = COLORS.White
            circle.Thickness = 1.5
        end
    end)
end

-- ========================================
-- ===== KILL ALL =====
-- ========================================

local killAllRunning = false

local function stopKillAll()
    killAllRunning = false
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
    if killAllRunning then
        stopKillAll()
        StarterGui:SetCore("SendNotification", {Title="Kill All", Text="⏹ Остановлено!", Duration=2})
        return
    end

    local knife = getKnife()
    if not knife then
        StarterGui:SetCore("SendNotification", {Title="Kill All", Text="❌ Нож не найден!", Duration=3})
        return
    end

    killAllRunning = true
    local killRemote = findKillRemote()

    StarterGui:SetCore("SendNotification", {Title="Kill All", Text="🔪 Kill All запущен!", Duration=2})

    task.spawn(function()
        while killAllRunning do
            if not LocalPlayer.Character then task.wait(1) continue end

            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then task.wait(1) continue end

            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character
                    and p.Character:FindFirstChild("HumanoidRootPart")
                    and p.Character:FindFirstChildOfClass("Humanoid")
                    and p.Character.Humanoid.Health > 0
                then
                    table.insert(targets, p)
                end
            end

            for _, target in ipairs(targets) do
                if not killAllRunning then break end
                if not target.Character then continue end
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChildOfClass("Humanoid")
                if not tHRP or not tHum or tHum.Health <= 0 then continue end

                -- Телепорт к цели
                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 1.5)
                task.wait(0.05)

                -- Берём нож
                local k = getKnife()
                if k then
                    pcall(function()
                        LocalPlayer.Character.Humanoid:EquipTool(k)
                    end)
                end
                task.wait(0.1)

                -- RemoteEvent
                if killRemote then
                    pcall(function() killRemote:FireServer(target) end)
                    pcall(function() killRemote:FireServer(target.Character) end)
                    pcall(function() killRemote:FireServer(tHRP) end)
                end

                -- Автокликер
                local clicks = 0
                while killAllRunning
                    and target.Character
                    and target.Character:FindFirstChildOfClass("Humanoid")
                    and target.Character.Humanoid.Health > 0
                    and clicks < 8
                do
                    pcall(function() mouse1press() end)
                    task.wait(0.03)
                    pcall(function() mouse1release() end)
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
    safeDisconnect(afkConn)
    afkConn = nil
    if not Settings.AntiAFKEnabled then return end
    local last = 0
    afkConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiAFKEnabled or not LocalPlayer.Character then return end
        local now = tick()
        if now - last > 60 then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump = true last = now end
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
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    local target = coin.Position + Vector3.new(0,2,0)
    if (hrp.Position-target).Magnitude < 5 then return true end
    if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
    Cache.CurrentTween = TweenService:Create(hrp,
        TweenInfo.new((hrp.Position-target).Magnitude/Settings.AutoFarmSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {CFrame = CFrame.new(target)}
    )
    hum.Sit = true
    Cache.CurrentTween:Play()
    local done = false
    local c; c = Cache.CurrentTween.Completed:Connect(function() done=true safeDisconnect(c) end)
    local t = tick()
    while not done and Settings.AutoFarmEnabled do
        task.wait(0.1)
        if not coin or not coin.Parent or not coin:FindFirstChild("TouchInterest") then
            if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
            hum.Sit = false
            return false
        end
        if tick()-t > 30 then
            if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) end
            hum.Sit = false
            return false
        end
    end
    hum.Sit = false
    return done
end

local function collectCoin(coin)
    if not coin or not coin.Parent then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() firetouchinterest(hrp,coin,0) task.wait(0.05) firetouchinterest(hrp,coin,1) end)
end

local function farmLoop()
    while Settings.AutoFarmEnabled do
        if not LocalPlayer.Character then task.wait(1) continue end
        if getCurrentCoins() >= Settings.AutoFarmCoinLimit then
            if Settings.AutoRespawn then
                pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
                task.wait(5)
                continue
            else
                Settings.AutoFarmEnabled = false
                StarterGui:SetCore("SendNotification", {Title="AutoFarm", Text="Bag full! ✅", Duration=3})
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
    Cache.AutoFarmConnection = nil
end

local function setupAutoFarm()
    if Settings.AutoFarmEnabled then
        if not LocalPlayer.Character then return end
        Cache.AutoFarmConnection = task.spawn(farmLoop)
        StarterGui:SetCore("SendNotification", {Title="AutoFarm", Text="Запущен! 🚀", Duration=3})
    else
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = false end
        end
        if Cache.CurrentTween then pcall(function() Cache.CurrentTween:Cancel() end) Cache.CurrentTween = nil end
    end
end

-- ========================================
-- ===== FLY =====
-- ========================================

local flyConn = nil
local isFlying = false
local flyBV, flyBG = nil, nil
local origGravity = workspace.Gravity

local function stopFly()
    isFlying = false
    safeDisconnect(flyConn)
    flyConn = nil
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
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    isFlying = true
    origGravity = workspace.Gravity
    workspace.Gravity = 0
    hum.PlatformStand = true

    for _, v in ipairs({"BodyVelocity","BodyGyro"}) do
        local old = hrp:FindFirstChildOfClass(v)
        if old then old:Destroy() end
    end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
    flyBV.Velocity = Vector3.new(0,0,0)
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyBG.P = 1000
    flyBG.D = 100
    flyBG.Parent = hrp

    safeDisconnect(flyConn)
    flyConn = RunService.RenderStepped:Connect(function()
        if not isFlying or not char or not char.Parent or not hrp or not hrp.Parent then stopFly() return end
        local cf  = Camera.CFrame
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit*Settings.FlySpeed or Vector3.new(0,0,0)
        flyBG.CFrame   = cf
    end)
end

-- ========================================
-- ===== BUNNY HOP (РАБОЧИЙ) =====
-- ========================================

-- Принцип:
-- 1. Убираем кулдаун прыжка через Humanoid (WalkSpeed буст + мгновенный прыжок)
-- 2. Используем Stepped для чтения состояния КАЖДЫЙ ФИЗИЧЕСКИЙ ШАГ
-- 3. Добавляем горизонтальный импульс через AssemblyLinearVelocity
-- 4. Отключаем friction через PhysicalProperties

local bhopConn   = nil
local bhopActive = false

local function stopBHop()
    bhopActive = false
    safeDisconnect(bhopConn)
    bhopConn = nil
    -- Восстанавливаем физику персонажа
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CustomPhysicalProperties = PhysicalProperties.new(
                0.7, 0.3, 0.5, 0.1, 1
            )
        end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end
end

local function startBHop()
    if not LocalPlayer.Character then return end
    if bhopActive then stopBHop() end

    local char = LocalPlayer.Character
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    bhopActive = true

    -- Убираем трение с пола чтобы скорость не гасилась
    hrp.CustomPhysicalProperties = PhysicalProperties.new(
        0.7,  -- density
        0.0,  -- friction (0 = нет трения → скорость не падает)
        0.5,  -- elasticity
        0.0,  -- frictionWeight
        0.0   -- elasticityWeight
    )

    local lastJumpTime = 0
    local jumpCooldown = 0.1 -- секунд между прыжками

    safeDisconnect(bhopConn)
    bhopConn = RunService.Stepped:Connect(function()
        if not bhopActive then stopBHop() return end
        if not char or not char.Parent then stopBHop() return end
        if not hrp  or not hrp.Parent  then stopBHop() return end

        local now = tick()

        -- Определяем направление движения
        local cf = Camera.CFrame
        local moveDir = Vector3.new(0,0,0)
        local moving = false

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir += Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            moving = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir -= Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            moving = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir -= Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
            moving = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir += Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
            moving = true
        end

        local state = hum:GetState()

        -- Состояние: на земле / приземлился → прыгаем сразу
        if (state == Enum.HumanoidStateType.Running or
            state == Enum.HumanoidStateType.Landed  or
            state == Enum.HumanoidStateType.RunningNoPhysics) and moving then

            if now - lastJumpTime > jumpCooldown then
                -- Прыжок
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                lastJumpTime = now

                -- Добавляем горизонтальный импульс
                if moveDir.Magnitude > 0 then
                    local horizontal = moveDir.Unit * Settings.BHopSpeed
                    -- Сохраняем вертикальную составляющую
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        horizontal.X,
                        hrp.AssemblyLinearVelocity.Y,
                        horizontal.Z
                    )
                end
            end

        elseif state == Enum.HumanoidStateType.Freefall or
               state == Enum.HumanoidStateType.Jumping then
            -- В воздухе — продолжаем разгонять горизонтально (air strafing)
            if moving and moveDir.Magnitude > 0 then
                local curVel = hrp.AssemblyLinearVelocity
                local targetH = moveDir.Unit * Settings.BHopSpeed
                -- Плавно интерполируем горизонтальную скорость к целевой
                hrp.AssemblyLinearVelocity = Vector3.new(
                    math.lerp(curVel.X, targetH.X, 0.15),
                    curVel.Y,
                    math.lerp(curVel.Z, targetH.Z, 0.15)
                )
            end
        end
    end)
end

-- ========================================
-- ===== SPIN BOT =====
-- ========================================

local SpinBot  = {Enabled=false, Speed=9999}
local spinConn = nil

local function setupSpinBot()
    safeDisconnect(spinConn)
    spinConn = nil
    if not SpinBot.Enabled then return end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinBot.Speed*dt), 0) end
    end)
end

-- ========================================
-- ===== ANTI FLING (РАБОЧИЙ) =====
-- ========================================
-- Полностью убираем коллизию между игроками.
-- Ты проходишь сквозь всех, никто не может тебя отбросить.

local antiFlingConn     = nil
local antiFlingVelConn  = nil

local function stopAntiFling()
    safeDisconnect(antiFlingConn)
    safeDisconnect(antiFlingVelConn)
    antiFlingConn    = nil
    antiFlingVelConn = nil

    -- Восстанавливаем коллизию для всех
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CollisionGroup = "Default"
                end
            end
        end
    end
end

local function setupAntiFling()
    safeDisconnect(antiFlingConn)
    safeDisconnect(antiFlingVelConn)
    antiFlingConn    = nil
    antiFlingVelConn = nil

    if not Settings.AntiFlingEnabled then
        stopAntiFling()
        return
    end

    -- Основной цикл: каждый Heartbeat убираем CanCollide у всех чужих частей
    -- и ограничиваем скорость нашего персонажа
    antiFlingConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiFlingEnabled then stopAntiFling() return end

        -- Убираем коллизию у ВСЕХ других игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- CanCollide = false убирает физическое столкновение
                        if part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end

        -- Защита нашего персонажа от внезапного ускорения (anti-fling)
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local vel = hrp.AssemblyLinearVelocity
        local maxVel = 200 -- максимально допустимая скорость

        if vel.Magnitude > maxVel then
            hrp.AssemblyLinearVelocity = vel.Unit * maxVel
        end

        -- Угловая скорость тоже ограничиваем
        if hrp.AssemblyAngularVelocity.Magnitude > 20 then
            hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
    end)

    -- Применяем к новым игрокам когда они спавнятся
    antiFlingVelConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if not Settings.AntiFlingEnabled then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

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

        -- ESP
        local role = getRole(player)
        if     Settings.MurderESP   and role=="Murder"   then createOrUpdateHighlight(player, COLORS.Murder)
        elseif Settings.SheriffESP  and role=="Sheriff"  then createOrUpdateHighlight(player, COLORS.Sheriff)
        elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player, COLORS.Innocent)
        else removeHighlight(player) end

        -- Chams
        if Settings.ChamsEnabled then applyChams(player)
        elseif Cache.ChamsPartsList[player.UserId] then removeChams(player) end

        -- Tracers
        if Settings.TracersEnabled and not Cache.Tracers[player.UserId] then
            createTracer(player)
        end
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
        local anyActive = Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP
                       or Settings.ChamsEnabled or Settings.Trails or Settings.TracersEnabled
        if anyActive then updateVisuals() end
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
                    StarterGui:SetCore("SendNotification", {
                        Title="⚠️ SHERIFF", Text=player.Name.." is dead!", Duration=3
                    })
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
                        StarterGui:SetCore("SendNotification", {
                            Title="⚠️ SHERIFF", Text=player.Name.." is dead!", Duration=3
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

-- ===== RAGE =====
local RageTab      = Window:Tab({ Title="Rage",   Icon="sword" })
local RageLeft     = RageTab:Section({ Title="Movement", Side="Left"  })
local RageRight    = RageTab:Section({ Title="Flight",   Side="Right" })

RageRight:Toggle({Title="Fly", Default=false, Callback=function(v)
    Settings.FlyEnabled = v
    if v then startFly() else stopFly() end
end})

RageRight:Input({Title="Fly Speed", Default="100", Placeholder="100", Callback=function(v)
    local n = tonumber(v) if n then Settings.FlySpeed = n end
end})

RageLeft:Toggle({Title="Bunny Hop (AutoJump)", Default=false, Callback=function(v)
    Settings.BHopEnabled = v
    if v then startBHop() else stopBHop() end
end})

RageLeft:Input({Title="BHop Speed", Default="30", Placeholder="30", Callback=function(v)
    local n = tonumber(v)
    if n then Settings.BHopSpeed = n end
end})

RageLeft:Toggle({Title="Spin Bot (Anti-Aim)", Default=false, Callback=function(v)
    SpinBot.Enabled = v
    Settings.SpinBotEnabled = v
    setupSpinBot()
end})

RageLeft:Input({Title="Spin Speed", Default="9999", Placeholder="9999", Callback=function(v)
    local n = tonumber(v) if n then SpinBot.Speed = n end
end})

-- ===== COMBAT =====
local CombatTab    = Window:Tab({ Title="Combat", Icon="crosshair" })
local CombatLeft   = CombatTab:Section({ Title="Combat",   Side="Left"  })
local CombatRight  = CombatTab:Section({ Title="Aimbot",   Side="Right" })

local noclipConn = nil
CombatLeft:Toggle({Title="Noclip", Default=false, Callback=function(v)
    safeDisconnect(noclipConn) noclipConn = nil
    if not v then return end
    noclipConn = RunService.Stepped:Connect(function()
        if not LocalPlayer.Character then return end
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end})

CombatLeft:Toggle({Title="Anti Fling (No Collision)", Default=false, Callback=function(v)
    Settings.AntiFlingEnabled = v
    setupAntiFling()
end})

CombatLeft:Button({Title="Grab Gun", Callback=function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol")) then
            local handle = obj:FindFirstChild("Handle")
            if handle and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0,3,0))
                    StarterGui:SetCore("SendNotification", {Title="Gun", Text="Teleported!", Duration=2})
                    break
                end
            end
        end
    end
end})

CombatLeft:Button({Title="🔪 Kill All (Murder Only)", Callback=function()
    killAllPlayers()
end})

CombatRight:Toggle({Title="FOV Aimbot (Murder Only)", Default=false, Callback=function(v)
    Settings.FovAimbotEnabled = v
    if v then createFovCircle() end
    setupFovAimbot()
end})

CombatRight:Input({Title="FOV Radius", Default="120", Placeholder="120", Callback=function(v)
    local n = tonumber(v)
    if n then
        Settings.FovRadius = math.clamp(n, 10, 600)
        if Cache.FovCircle then Cache.FovCircle.Radius = Settings.FovRadius end
    end
end})

-- ===== VISUAL =====
local VisualTab    = Window:Tab({ Title="Visual", Icon="eye" })
local VisualLeft   = VisualTab:Section({ Title="ESP & Effects",  Side="Left"  })
local VisualRight  = VisualTab:Section({ Title="World Effects",  Side="Right" })

VisualLeft:Toggle({Title="ESP Murder",   Default=false, Callback=function(v) Settings.MurderESP=v   startMainUpdate() end})
VisualLeft:Toggle({Title="ESP Sheriff",  Default=false, Callback=function(v) Settings.SheriffESP=v  startMainUpdate() end})
VisualLeft:Toggle({Title="ESP Innocent", Default=false, Callback=function(v) Settings.InnocentESP=v startMainUpdate() end})

VisualLeft:Toggle({Title="Chams (Purple, AlwaysOnTop)", Default=false, Callback=function(v)
    Settings.ChamsEnabled = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do cacheCharacterParts(p) end
    else
        clearAllChams()
    end
    startMainUpdate()
end})

VisualLeft:Toggle({Title="Tracers", Default=false, Callback=function(v)
    Settings.TracersEnabled = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then createTracer(p) end
        end
    else
        clearAllTracers()
    end
    startMainUpdate()
end})

VisualLeft:Toggle({Title="Jump Circles", Default=false, Callback=function(v)
    Settings.JumpCircles = v
    startMainUpdate()
end})

VisualLeft:Toggle({Title="Purple Trail", Default=false, Callback=function(v)
    Settings.Trails = v
    if v then createLocalPlayerTrail() else removeLocalPlayerTrail() end
    startMainUpdate()
end})

VisualLeft:Toggle({Title="RGB Humanoid", Default=false, Callback=function(v)
    Settings.RGBHumanoid = v
    setupRGBHumanoid()
end})

VisualLeft:Toggle({Title="XRay", Default=false, Callback=function(v)
    Settings.XRayEnabled = v
    setupXRay()
end})

-- Shaders (правая колонка Visual)
VisualRight:Toggle({Title="Bloom",             Default=false, Callback=function(v) Settings.BloomEnabled=v           setupBloom(v)           end})
VisualRight:Toggle({Title="Color Correction",  Default=false, Callback=function(v) Settings.ColorCorrectionEnabled=v setupColorCorrection(v) end})
VisualRight:Toggle({Title="Vignette",          Default=false, Callback=function(v) Settings.VignetteEnabled=v        setupVignette(v)        end})

-- Sky (в правой колонке Visual, ниже шейдеров)
VisualRight:Input({Title="Sky ID", Default="", Placeholder="rbxassetid://...", Callback=function(v)
    Settings.CustomSkyId = v
end})

VisualRight:Button({Title="Apply Custom Sky", Callback=function()
    setupSky(Settings.CustomSkyId)
end})

VisualRight:Button({Title="Remove Sky", Callback=function()
    removeSky()
end})

VisualRight:Button({Title="🐹 Добрый хомяк",  Callback=function() setupSky("135457808082953") end})
VisualRight:Button({Title="🌩 Ночные тучи",   Callback=function() setupSky("100140210065251") end})
VisualRight:Button({Title="🚀 Космос",         Callback=function() setupSky("97059048850342")  end})

-- ===== AUTO FARM =====
local FarmTab    = Window:Tab({ Title="Auto Farm", Icon="star" })
local FarmLeft   = FarmTab:Section({ Title="Farm",   Side="Left"  })
local FarmRight  = FarmTab:Section({ Title="Config", Side="Right" })

FarmLeft:Toggle({Title="Auto Farm",              Default=false, Callback=function(v) Settings.AutoFarmEnabled=v setupAutoFarm() end})
FarmLeft:Toggle({Title="Auto Respawn (Full Bag)",Default=false, Callback=function(v) Settings.AutoRespawn=v end})

FarmRight:Input({Title="Farm Speed",  Default="20",   Placeholder="20",   Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmSpeed=n end end})
FarmRight:Input({Title="Coin Limit",  Default="40",   Placeholder="40",   Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmCoinLimit=n end end})
FarmRight:Input({Title="Coin Delay",  Default="0.15", Placeholder="0.15", Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmCoinDelay=n end end})

-- ===== MISC =====
local MiscTab   = Window:Tab({ Title="Misc", Icon="timer" })
local MiscLeft  = MiscTab:Section({ Title="Misc", Side="Left" })

MiscLeft:Toggle({Title="Anti-AFK", Default=false, Callback=function(v)
    Settings.AntiAFKEnabled = v
    setupAntiAFK()
end})

MiscLeft:Button({Title="Rejoin", Callback=function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end})

-- ========================================
-- ===== PLAYER EVENTS =====
-- ========================================

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Settings.ChamsEnabled    then cacheCharacterParts(player) applyChams(player) end
        if Settings.TracersEnabled and player~=LocalPlayer then createTracer(player) end
        if Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP then
            local role = getRole(player)
            if     Settings.MurderESP   and role=="Murder"   then createOrUpdateHighlight(player, COLORS.Murder)
            elseif Settings.SheriffESP  and role=="Sheriff"  then createOrUpdateHighlight(player, COLORS.Sheriff)
            elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player, COLORS.Innocent) end
        end
        -- Применяем anti-fling к новому игроку
        if Settings.AntiFlingEnabled and player ~= LocalPlayer then
            task.spawn(function()
                task.wait(0.5)
                if player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
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
    clearAllHighlights()
    clearAllChams()
    clearAllTracers()
    Cache.ChamsPartsList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if Settings.ChamsEnabled    then cacheCharacterParts(player) applyChams(player) end
        if Settings.TracersEnabled and player~=LocalPlayer then createTracer(player) end
        if Settings.MurderESP or Settings.SheriffESP or Settings.InnocentESP then
            local role = getRole(player)
            if     Settings.MurderESP   and role=="Murder"   then createOrUpdateHighlight(player, COLORS.Murder)
            elseif Settings.SheriffESP  and role=="Sheriff"  then createOrUpdateHighlight(player, COLORS.Sheriff)
            elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player, COLORS.Innocent) end
        end
    end

    setupRGBHumanoid()
    Cache.JumpTracking = {}

    if Settings.Trails       then createLocalPlayerTrail() end
    if Settings.FlyEnabled   then task.wait(0.5) startFly() end
    if Settings.BHopEnabled  then startBHop() end
    if Settings.AntiFlingEnabled then setupAntiFling() end
    if Settings.FovAimbotEnabled then setupFovAimbot() end
end)

-- ========================================
-- ===== INIT =====
-- ========================================

startMainUpdate()
setupSheriffDeadNotif()
createFovCircle()

StarterGui:SetCore("SendNotification", {
    Title   = "PlanetHub v3.0",
    Text    = "✅ Loaded! BHop + AntiFling + FOV + Sky",
    Duration = 4
})
