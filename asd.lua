-- ========================================
-- ===== PLANT HUB v3.0 ULTIMATE =====
-- ========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
    game.StarterGui:SetCore("SendNotification", {Title="Ошибка", Text="WindUI не загружен!", Duration=5})
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

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ========================================
-- ===== НАСТРОЙКИ =====
-- ========================================

local Settings = {
    MurderESP              = false,
    SheriffESP             = false,
    InnocentESP            = false,
    ChamsEnabled           = false,
    TracersEnabled         = false,
    JumpCircles            = false,
    Trails                 = false,
    RGBHumanoid            = false,
    XRayEnabled            = false,
    BloomEnabled           = false,
    ColorCorrectionEnabled = false,
    VignetteEnabled        = false,
    CustomSkyId            = "",
    FlyEnabled             = false,
    FlySpeed               = 60,
    BHopEnabled            = false,
    BHopSpeed              = 30,
    SpinBotEnabled         = false,
    SpinBotSpeed           = 9999,
    AntiFlingEnabled       = false,
    FovAimbotEnabled       = false,
    FovRadius              = 120,
    AutoFarmEnabled        = false,
    AutoFarmSpeed          = 20,
    AutoFarmCoinLimit      = 40,
    AutoFarmCoinDelay      = 0.15,
    AutoRespawn            = false,
    AntiAFKEnabled         = false,
}

-- ========================================
-- ===== КЭШ =====
-- ========================================

local Cache = {
    Highlights       = {},
    ChamsObjects     = {},
    PostEffects      = {},
    JumpTracking     = {wasJumping = false},
    RGBConnection    = nil,
    AutoFarmConn     = nil,
    CurrentTween     = nil,
    XRayParts        = setmetatable({}, {__mode = "k"}),
    Tracers          = {},
    TrailObjects     = {},
    FovCircle        = nil,
    FovConnection    = nil,
    KillAllRunning   = false,
}

local COLORS = {
    Murder   = Color3.fromRGB(255, 0,   0),
    Sheriff  = Color3.fromRGB(0,   100, 255),
    Innocent = Color3.fromRGB(0,   255, 0),
    Purple   = Color3.fromRGB(138, 43,  226),
    White    = Color3.fromRGB(255, 255, 255),
    Red      = Color3.fromRGB(255, 50,  50),
}

-- ========================================
-- ===== ХЕЛПЕРЫ =====
-- ========================================

local function safeDisconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title    = title,
        Text     = text,
        Duration = duration or 3,
    })
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
    if checkKnife(player) then return "Murder"  end
    if checkGun(player)   then return "Sheriff" end
    return "Innocent"
end

local function getRoleColor(player)
    local r = getRole(player)
    if r == "Murder"  then return COLORS.Murder  end
    if r == "Sheriff" then return COLORS.Sheriff  end
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

local function getGroundY(origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local char = LocalPlayer.Character
    if char then
        raycastParams.FilterDescendantsInstances = {char}
    end
    local result = Workspace:Raycast(origin, Vector3.new(0, -50, 0), raycastParams)
    if result then return result.Position.Y end
    return origin.Y - 3
end

-- ========================================
-- ===== CHAMS (SelectionBox — не Highlight) =====
-- ========================================

local function applyChams(player)
    if not player or not player.Character then return end
    local userId = player.UserId
    -- уже применено — обновляем цвет
    if Cache.ChamsObjects[userId] then
        local color = getRoleColor(player)
        for _, box in ipairs(Cache.ChamsObjects[userId]) do
            if box and box.Parent then
                box.Color3 = color
            end
        end
        return
    end

    local char  = player.Character
    local color = getRoleColor(player)
    local boxes = {}

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local box                    = Instance.new("SelectionBox")
            box.Adornee                  = part
            box.Color3                   = color
            box.LineThickness            = 0.04
            box.SurfaceTransparency      = 1
            box.SurfaceColor3            = color
            box.Parent                   = Workspace
            table.insert(boxes, box)
        end
    end

    Cache.ChamsObjects[userId] = boxes
end

local function removeChams(player)
    if not player then return end
    local boxes = Cache.ChamsObjects[player.UserId]
    if not boxes then return end
    for _, box in ipairs(boxes) do
        pcall(function() box:Destroy() end)
    end
    Cache.ChamsObjects[player.UserId] = nil
end

local function clearAllChams()
    for _, boxes in pairs(Cache.ChamsObjects) do
        for _, box in ipairs(boxes) do
            pcall(function() box:Destroy() end)
        end
    end
    Cache.ChamsObjects = {}
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
        hl.Name      = "PH_ESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent    = char
    end
    hl.FillColor           = color
    hl.OutlineColor        = color
    hl.FillTransparency    = 0.4
    hl.OutlineTransparency = 0
    hl.Enabled             = true
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
-- ===== TRACERS (на HumanoidRootPart) =====
-- ========================================

local function createTracer(player)
    if not player or player == LocalPlayer then return end
    if Cache.Tracers[player.UserId] then return end
    local line          = Drawing.new("Line")
    line.Thickness      = 2
    line.Transparency   = 0.8
    line.Visible        = false
    line.Color          = getRoleColor(player)
    Cache.Tracers[player.UserId] = line
end

local function updateTracers()
    for userId, line in pairs(Cache.Tracers) do
        local player = Players:GetPlayerByUserId(userId)

        -- игрок вышел — чистим
        if not player then
            pcall(function() line:Remove() end)
            Cache.Tracers[userId] = nil
            continue
        end

        if not Settings.TracersEnabled then
            line.Visible = false
            continue
        end

        -- цель — HumanoidRootPart
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            line.Visible = false
            continue
        end

        local sp, onScreen = Camera:WorldToScreenPoint(hrp.Position)
        if not onScreen or sp.Z < 0 then
            line.Visible = false
            continue
        end

        line.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        line.To      = Vector2.new(sp.X, sp.Y)
        line.Color   = getRoleColor(player)
        line.Visible = true
    end
end

local function clearAllTracers()
    for _, line in pairs(Cache.Tracers) do
        pcall(function() line:Remove() end)
    end
    Cache.Tracers = {}
end

-- ========================================
-- ===== TRAILS (исправлен ресет) =====
-- ========================================

local function removeLocalPlayerTrail()
    local obj = Cache.TrailObjects
    if obj.trail then pcall(function() obj.trail:Destroy() end) end
    if obj.att1  then pcall(function() obj.att1:Destroy()  end) end
    if obj.att2  then pcall(function() obj.att2:Destroy()  end) end
    Cache.TrailObjects = {}
end

local function createLocalPlayerTrail()
    removeLocalPlayerTrail()

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- убираем старые вложения чтобы не было "стада"
    for _, child in ipairs(hrp:GetChildren()) do
        if child:IsA("Attachment") or child:IsA("Trail") then
            pcall(function() child:Destroy() end)
        end
    end

    local att1       = Instance.new("Attachment")
    att1.Position    = Vector3.new(0,  1, 0)
    att1.Parent      = hrp

    local att2       = Instance.new("Attachment")
    att2.Position    = Vector3.new(0, -1, 0)
    att2.Parent      = hrp

    local trail              = Instance.new("Trail")
    trail.Attachment0        = att1
    trail.Attachment1        = att2
    trail.Lifetime           = 0.8
    trail.MinLength          = 0
    trail.FaceCamera         = true
    trail.LightEmission      = 1
    trail.LightInfluence     = 0
    trail.Transparency       = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Color              = ColorSequence.new(COLORS.Purple)
    trail.Parent             = hrp

    Cache.TrailObjects = {trail = trail, att1 = att1, att2 = att2}
end

-- ========================================
-- ===== SHADERS =====
-- ========================================

local function setupBloom(en)
    Lighting.Brightness = en and 1.5 or 1
end

local function setupColorCorrection(en)
    Lighting.Ambient        = en and COLORS.Purple or Color3.fromRGB(0,0,0)
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
        notify("Небо", "Пустой ID!", 2); return
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
    notify("Небо", "Применено: " .. skyId, 2)
end

local function removeSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    notify("Небо", "Небо удалено", 2)
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
                    part.Material    = Enum.Material.Plastic
                    part.Color       = Color3.fromRGB(255,255,255)
                    part.Transparency= 0
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
                part.Material    = Enum.Material.ForceField
                part.Color       = color
                part.Transparency= 0.3
            end
        end
    end)
end

-- ========================================
-- ===== XRAY =====
-- ========================================

local function setupXRay()
    if Settings.XRayEnabled then
        Cache.XRayParts = setmetatable({}, {__mode = "k"})
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
        Cache.XRayParts = setmetatable({}, {__mode = "k"})
    end
end

-- ========================================
-- ===== JUMP CIRCLES =====
-- ========================================

local function createJumpCircle(originPos)
    local groundY = getGroundY(originPos)
    local ringPos = Vector3.new(originPos.X, groundY + 0.08, originPos.Z)

    local ring           = Instance.new("Part")
    ring.Shape           = Enum.PartType.Cylinder
    ring.Size            = Vector3.new(0.08, 0.5, 0.5)
    ring.Material        = Enum.Material.Neon
    ring.Color           = COLORS.Purple
    ring.Transparency    = 0
    ring.Anchored        = true
    ring.CanCollide      = false
    ring.CastShadow      = false
    ring.CFrame          = CFrame.new(ringPos) * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent          = Workspace

    local light          = Instance.new("PointLight")
    light.Brightness     = 4
    light.Color          = COLORS.Purple
    light.Range          = 20
    light.Parent         = ring

    local t0       = tick()
    local duration = 0.7
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not ring or not ring.Parent then safeDisconnect(conn) return end
        local p = (tick() - t0) / duration
        if p >= 1 then
            pcall(function() ring:Destroy() end)
            safeDisconnect(conn); return
        end
        local diameter    = 0.5 + p * 6
        ring.Size         = Vector3.new(0.08, diameter, diameter)
        ring.Transparency = p
        ring.CFrame       = CFrame.new(ringPos) * CFrame.Angles(0, 0, math.rad(90))
        light.Brightness  = 4 * (1 - p)
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
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestP    = nil
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
            bestDist = d; bestP = player
        end
    end
    return bestP
end

local function createFovCircle()
    if Cache.FovCircle then pcall(function() Cache.FovCircle:Remove() end) end
    local c         = Drawing.new("Circle")
    c.Radius        = Settings.FovRadius
    c.Color         = COLORS.White
    c.Thickness     = 1.5
    c.Transparency  = 0.7
    c.Filled        = false
    c.Visible       = false
    c.NumSides      = 64
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
        local center    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        circle.Position = center
        circle.Radius   = Settings.FovRadius
        circle.Visible  = true
        local target    = getClosestMurderInFov()
        if target then
            circle.Color     = COLORS.Red
            circle.Thickness = 2.0
            local predicted  = getPredictedHRPPos(target)
            if not predicted then return end
            -- плавное наведение вместо жёсткого снэпа
            local targetCF   = CFrame.lookAt(Camera.CFrame.Position, predicted, Camera.CFrame.UpVector)
            Camera.CFrame    = Camera.CFrame:Lerp(targetCF, 0.2)
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
    notify("Kill All", "Остановлен", 2)
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
        notify("Kill All", "Нож не найден!", 3); return
    end
    Cache.KillAllRunning = true
    local killRemote     = findKillRemote()
    notify("Kill All", "Запущен", 2)

    task.spawn(function()
        local lastKnifeCheck = tick()
        while Cache.KillAllRunning do
            if tick() - lastKnifeCheck >= 1 then
                lastKnifeCheck = tick()
                if not getLocalKnife() then
                    Cache.KillAllRunning = false
                    notify("Kill All", "Нож пропал, остановлен", 3); break
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
                    pcall(function() mouse1press()  end) task.wait(0.03)
                    pcall(function() mouse1release() end)
                    pcall(function()
                        firetouchinterest(myHRP, tHRP, 0)
                        task.wait(0.02)
                        firetouchinterest(myHRP, tHRP, 1)
                    end)
                    clicks = clicks + 1; task.wait(0.05)
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
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
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
    local c; c = Cache.CurrentTween.Completed:Connect(function() done=true; safeDisconnect(c) end)
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
                notify("Авто-фарм", "Сумка полная!", 3); break
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
        notify("Авто-фарм", "Запущен", 3)
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
-- ===== FLY (ИСПРАВЛЕННЫЙ) =====
-- ========================================

local FlyState = {
    Active       = false,
    BodyVelocity = nil,
    BodyGyro     = nil,
    Connection   = nil,
    OrigGravity  = workspace.Gravity,
    MobileGui    = nil,
    UpHeld       = false,
    DownHeld     = false,
}

local function removeFlyMobileUI()
    FlyState.UpHeld   = false
    FlyState.DownHeld = false
    if FlyState.MobileGui then
        pcall(function() FlyState.MobileGui:Destroy() end)
        FlyState.MobileGui = nil
    end
end

local function createFlyMobileUI()
    removeFlyMobileUI()

    local gui              = Instance.new("ScreenGui")
    gui.Name               = "FlyMobileUI"
    gui.ResetOnSpawn       = false
    gui.IgnoreGuiInset     = true
    gui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
    gui.Parent             = LocalPlayer:WaitForChild("PlayerGui")
    FlyState.MobileGui     = gui

    local frame                     = Instance.new("Frame")
    frame.Size                      = UDim2.new(0, 180, 0, 100)
    frame.Position                  = UDim2.new(0, 20, 1, -130)
    frame.BackgroundColor3          = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency    = 0.2
    frame.BorderSizePixel           = 0
    frame.Parent                    = gui

    local corner        = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent       = frame

    local label                     = Instance.new("TextLabel")
    label.Size                      = UDim2.new(1, 0, 0, 24)
    label.Position                  = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency    = 1
    label.Text                      = "Полёт"
    label.TextColor3                = Color3.fromRGB(180, 180, 180)
    label.Font                      = Enum.Font.GothamBold
    label.TextScaled                = true
    label.Parent                    = frame

    local function makeButton(text, posX, onDown, onUp)
        local btn                       = Instance.new("TextButton")
        btn.Size                        = UDim2.new(0, 78, 0, 60)
        btn.Position                    = UDim2.new(0, posX, 0, 28)
        btn.BackgroundColor3            = Color3.fromRGB(138, 43, 226)
        btn.BackgroundTransparency      = 0.25
        btn.TextColor3                  = Color3.fromRGB(255, 255, 255)
        btn.Text                        = text
        btn.Font                        = Enum.Font.GothamBold
        btn.TextScaled                  = true
        btn.BorderSizePixel             = 0
        btn.Parent                      = frame
        local c2        = Instance.new("UICorner")
        c2.CornerRadius = UDim.new(0, 10)
        c2.Parent       = btn
        btn.MouseButton1Down:Connect(onDown)
        btn.MouseButton1Up:Connect(onUp)
        return btn
    end

    makeButton("Вверх", 8,
        function() FlyState.UpHeld   = true  end,
        function() FlyState.UpHeld   = false end
    )
    makeButton("Вниз", 94,
        function() FlyState.DownHeld = true  end,
        function() FlyState.DownHeld = false end
    )
end

local function stopFly()
    FlyState.Active = false
    safeDisconnect(FlyState.Connection)
    FlyState.Connection = nil
    workspace.Gravity = FlyState.OrigGravity

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end

    if FlyState.BodyVelocity then
        pcall(function() FlyState.BodyVelocity:Destroy() end)
        FlyState.BodyVelocity = nil
    end
    if FlyState.BodyGyro then
        pcall(function() FlyState.BodyGyro:Destroy() end)
        FlyState.BodyGyro = nil
    end
    removeFlyMobileUI()
end

local function startFly()
    if not LocalPlayer.Character then return end
    if FlyState.Active then stopFly() end

    local char = LocalPlayer.Character
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    FlyState.Active      = true
    FlyState.OrigGravity = workspace.Gravity
    workspace.Gravity    = 0
    hum.PlatformStand    = true

    for _, cls in ipairs({"BodyVelocity", "BodyGyro"}) do
        local old = hrp:FindFirstChildOfClass(cls)
        if old then old:Destroy() end
    end

    local bv          = Instance.new("BodyVelocity")
    bv.MaxForce       = Vector3.new(1e8, 1e8, 1e8)
    bv.Velocity       = Vector3.new(0, 0, 0)
    bv.Parent         = hrp
    FlyState.BodyVelocity = bv

    local bg          = Instance.new("BodyGyro")
    bg.MaxTorque      = Vector3.new(1e8, 1e8, 1e8)
    bg.P              = 3000
    bg.D              = 200
    bg.CFrame         = hrp.CFrame
    bg.Parent         = hrp
    FlyState.BodyGyro = bg

    createFlyMobileUI()

    FlyState.Connection = RunService.RenderStepped:Connect(function()
        if not FlyState.Active then stopFly() return end

        char = LocalPlayer.Character
        if not char or not char.Parent then stopFly() return end
        hrp  = char:FindFirstChild("HumanoidRootPart")
        hum  = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then stopFly() return end

        if not (FlyState.BodyVelocity and FlyState.BodyVelocity.Parent) then stopFly() return end
        if not (FlyState.BodyGyro     and FlyState.BodyGyro.Parent)     then stopFly() return end

        local camCF   = Camera.CFrame
        local moveDir = Vector3.new(0, 0, 0)
        local speed   = Settings.FlySpeed
        local vert    = speed * 0.7

        local md = hum.MoveDirection
        if md.Magnitude > 0.1 then
            local flat = Vector3.new(md.X, 0, md.Z)
            if flat.Magnitude > 0.01 then
                moveDir = moveDir + flat.Unit * speed
            end
        end

        if UserInputService.KeyboardEnabled then
            local kbDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then kbDir += camCF.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then kbDir -= camCF.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then kbDir -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then kbDir += camCF.RightVector end
            if kbDir.Magnitude > 0.01 then
                moveDir = Vector3.new(kbDir.X, 0, kbDir.Z).Unit * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then moveDir += Vector3.new(0, vert, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, vert, 0) end
        end

        if FlyState.UpHeld   then moveDir += Vector3.new(0, vert, 0) end
        if FlyState.DownHeld then moveDir -= Vector3.new(0, vert, 0) end

        FlyState.BodyVelocity.Velocity = moveDir

        -- ИСПРАВЛЕНО: правильный BodyGyro без бага ToEulerAnglesYXZ
        local _, ry, _ = camCF:ToEulerAnglesYXZ()
        FlyState.BodyGyro.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, ry, 0)
    end)
end

-- ========================================
-- ===== BUNNY HOP =====
-- ========================================

local bhopConn   = nil
local bhopBV     = nil
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

    bhopActive      = true
    bhopBV          = Instance.new("BodyVelocity")
    bhopBV.Name     = "BHopBV"
    bhopBV.MaxForce = Vector3.new(1e5, 0, 1e5)
    bhopBV.Velocity = Vector3.new(0, 0, 0)
    bhopBV.Parent   = hrp

    local lastJump = 0
    local COOLDOWN = 0.15

    bhopConn = RunService.Stepped:Connect(function()
        if not bhopActive then stopBHop() return end
        char = LocalPlayer.Character; if not char then return end
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

local SpinBot  = {Enabled=false, Speed=9999}
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

local antiFlingConn    = nil
local antiFlingNewConn = nil

local function stopAntiFling()
    safeDisconnect(antiFlingConn);    antiFlingConn    = nil
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
        if hrp.AssemblyLinearVelocity.Magnitude  > 200 then hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0) end
        if hrp.AssemblyAngularVelocity.Magnitude >  20 then hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end
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
            elseif Cache.ChamsObjects[player.UserId] then removeChams(player) end
            continue
        end
        if not player.Character then continue end
        local role = getRole(player)
        if     Settings.MurderESP   and role=="Murder"   then createOrUpdateHighlight(player,COLORS.Murder)
        elseif Settings.SheriffESP  and role=="Sheriff"  then createOrUpdateHighlight(player,COLORS.Sheriff)
        elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player,COLORS.Innocent)
        else removeHighlight(player) end
        if Settings.ChamsEnabled then applyChams(player)
        elseif Cache.ChamsObjects[player.UserId] then removeChams(player) end
        if Settings.TracersEnabled and not Cache.Tracers[player.UserId] then createTracer(player) end
    end
    if Settings.TracersEnabled then updateTracers() else clearAllTracers() end
    if Settings.Trails then
        local obj = Cache.TrailObjects
        if not obj.trail or not obj.trail.Parent then
            createLocalPlayerTrail()
        end
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
                    notify("Шериф", player.Name .. " мёртв!", 3)
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
                        notify("Шериф", player.Name .. " мёртв!", 3)
                    end
                end)
            end
        end)
    end)
end

-- ========================================
-- ===== UI =====
-- ========================================

-- ===== RAGE TAB =====
local RageTab = Window:Tab({Title="Рейдж", Icon="sword"})
local RageL   = RageTab:Section({Title="Движение",  Side="Left"})
local RageR   = RageTab:Section({Title="Полёт",     Side="Right"})

-- Полёт — правая колонка
RageR:Toggle({Title="Полёт (ПК + Мобайл)", Default=false, Callback=function(v)
    Settings.FlyEnabled = v
    if v then startFly() else stopFly() end
end})
RageR:Input({Title="Скорость полёта", Default="60", Placeholder="60", Callback=function(v)
    local n=tonumber(v); if n then Settings.FlySpeed=n end
end})
RageR:Label({Title="ПК: WASD — движение, Пробел — вверх, Shift — вниз"})
RageR:Label({Title="Мобайл: кнопки Вверх / Вниз на экране"})

-- Движение — левая колонка
RageL:Toggle({Title="Банни-хоп (ПК + Мобайл)", Default=false, Callback=function(v)
    Settings.BHopEnabled = v
    if v then startBHop() else stopBHop() end
end})
RageL:Input({Title="Скорость Банни-хопа", Default="30", Placeholder="30", Callback=function(v)
    local n=tonumber(v); if n then Settings.BHopSpeed=n end
end})
RageL:Toggle({Title="Спин-бот", Default=false, Callback=function(v)
    SpinBot.Enabled = v; setupSpinBot()
end})
RageL:Input({Title="Скорость спина", Default="9999", Placeholder="9999", Callback=function(v)
    local n=tonumber(v); if n then SpinBot.Speed=n end
end})

-- ===== COMBAT TAB =====
local CombatTab = Window:Tab({Title="Бой",     Icon="crosshair"})
local CombatL   = CombatTab:Section({Title="Инструменты", Side="Left"})
local CombatR   = CombatTab:Section({Title="Прицел",      Side="Right"})

CombatL:Toggle({Title="Нет клипа (Нет коллизий)", Default=false, Callback=function(v)
    safeDisconnect(noclipConn); noclipConn = nil
    if not v then return end
    noclipConn = RunService.Stepped:Connect(function()
        if not LocalPlayer.Character then return end
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end})

CombatL:Toggle({Title="Защита от флинга", Default=false, Callback=function(v)
    Settings.AntiFlingEnabled = v; setupAntiFling()
end})

CombatL:Button({Title="Подобрать пистолет", Callback=function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol")) then
            local handle = obj:FindFirstChild("Handle")
            if handle and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(handle.Position + Vector3.new(0,3,0))
                    notify("Пистолет", "Телепортирован!", 2); break
                end
            end
        end
    end
end})

CombatL:Button({Title="Убить всех (повторно = стоп)", Callback=function()
    killAllPlayers()
end})

CombatR:Toggle({Title="FOV Прицел (Убийца)", Default=false, Callback=function(v)
    Settings.FovAimbotEnabled = v
    if v then createFovCircle() end
    setupFovAimbot()
end})
CombatR:Input({Title="Радиус FOV", Default="120", Placeholder="120", Callback=function(v)
    local n=tonumber(v)
    if n then
        Settings.FovRadius = math.clamp(n, 10, 600)
        if Cache.FovCircle then Cache.FovCircle.Radius = Settings.FovRadius end
    end
end})

-- ===== VISUAL TAB =====
local VisualTab = Window:Tab({Title="Визуал",    Icon="eye"})
local VisualL   = VisualTab:Section({Title="ESP и эффекты",  Side="Left"})
local VisualR   = VisualTab:Section({Title="Мир и небо",     Side="Right"})

VisualL:Toggle({Title="ESP Убийца",                  Default=false, Callback=function(v) Settings.MurderESP=v   startMainUpdate() end})
VisualL:Toggle({Title="ESP Шериф",                   Default=false, Callback=function(v) Settings.SheriffESP=v  startMainUpdate() end})
VisualL:Toggle({Title="ESP Невинный",                Default=false, Callback=function(v) Settings.InnocentESP=v startMainUpdate() end})
VisualL:Toggle({Title="Чамс (контур сквозь стены)",  Default=false, Callback=function(v)
    Settings.ChamsEnabled = v
    if not v then clearAllChams() end
    startMainUpdate()
end})
VisualL:Toggle({Title="Трейсеры (линии к игрокам)",  Default=false, Callback=function(v)
    Settings.TracersEnabled = v
    if v then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer then createTracer(p) end
        end
    else clearAllTracers() end
    startMainUpdate()
end})
VisualL:Toggle({Title="Круги прыжка (на полу)",      Default=false, Callback=function(v)
    Settings.JumpCircles = v; startMainUpdate()
end})
VisualL:Toggle({Title="Фиолетовый трейл",            Default=false, Callback=function(v)
    Settings.Trails = v
    if v then createLocalPlayerTrail() else removeLocalPlayerTrail() end
    startMainUpdate()
end})
VisualL:Toggle({Title="RGB персонаж",                Default=false, Callback=function(v)
    Settings.RGBHumanoid = v; setupRGBHumanoid()
end})
VisualL:Toggle({Title="XRay (прозрачные стены)",     Default=false, Callback=function(v)
    Settings.XRayEnabled = v; setupXRay()
end})

VisualR:Toggle({Title="Блум",            Default=false, Callback=function(v) Settings.BloomEnabled=v           setupBloom(v) end})
VisualR:Toggle({Title="Коррекция цвета", Default=false, Callback=function(v) Settings.ColorCorrectionEnabled=v setupColorCorrection(v) end})
VisualR:Toggle({Title="Виньетка",        Default=false, Callback=function(v) Settings.VignetteEnabled=v        setupVignette(v) end})
VisualR:Input({Title="ID неба", Default="", Placeholder="rbxassetid://...", Callback=function(v)
    Settings.CustomSkyId=v
end})
VisualR:Button({Title="Применить небо",    Callback=function() setupSky(Settings.CustomSkyId) end})
VisualR:Button({Title="Удалить небо",      Callback=function() removeSky() end})
VisualR:Button({Title="Небо: Хомяк",       Callback=function() setupSky("135457808082953") end})
VisualR:Button({Title="Небо: Ночные тучи", Callback=function() setupSky("100140210065251") end})
VisualR:Button({Title="Небо: Космос",      Callback=function() setupSky("97059048850342")  end})

-- ===== AUTO FARM TAB =====
local FarmTab = Window:Tab({Title="Авто-фарм", Icon="star"})
local FarmL   = FarmTab:Section({Title="Фарм",      Side="Left"})
local FarmR   = FarmTab:Section({Title="Настройки", Side="Right"})

FarmL:Toggle({Title="Авто-фарм монет",                     Default=false, Callback=function(v) Settings.AutoFarmEnabled=v setupAutoFarm() end})
FarmL:Toggle({Title="Авто-возрождение при полной сумке",   Default=false, Callback=function(v) Settings.AutoRespawn=v end})
FarmR:Input({Title="Скорость движения",   Default="20",   Placeholder="20",   Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmSpeed=n end end})
FarmR:Input({Title="Лимит монет",         Default="40",   Placeholder="40",   Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmCoinLimit=n end end})
FarmR:Input({Title="Задержка (сек)",      Default="0.15", Placeholder="0.15", Callback=function(v) local n=tonumber(v) if n then Settings.AutoFarmCoinDelay=n end end})

-- ===== MISC TAB =====
local MiscTab = Window:Tab({Title="Разное", Icon="timer"})
local MiscL   = MiscTab:Section({Title="Прочее", Side="Left"})

MiscL:Toggle({Title="Анти-АФК", Default=false, Callback=function(v)
    Settings.AntiAFKEnabled = v; setupAntiAFK()
end})
MiscL:Button({Title="Переподключиться", Callback=function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end})

-- ========================================
-- ===== СОБЫТИЯ ИГРОКОВ =====
-- ========================================

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Settings.ChamsEnabled then applyChams(player) end
        if Settings.TracersEnabled and player~=LocalPlayer then createTracer(player) end
        local role=getRole(player)
        if     Settings.MurderESP   and role=="Murder"   then createOrUpdateHighlight(player,COLORS.Murder)
        elseif Settings.SheriffESP  and role=="Sheriff"  then createOrUpdateHighlight(player,COLORS.Sheriff)
        elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player,COLORS.Innocent) end
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
    removeChams(player)
    Cache.Highlights[player.UserId] = nil
    if Cache.Tracers[player.UserId] then
        pcall(function() Cache.Tracers[player.UserId]:Remove() end)
        Cache.Tracers[player.UserId] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    clearAllHighlights(); clearAllChams(); clearAllTracers()

    for _, player in ipairs(Players:GetPlayers()) do
        if Settings.ChamsEnabled then applyChams(player) end
        if Settings.TracersEnabled and player~=LocalPlayer then createTracer(player) end
        local role=getRole(player)
        if     Settings.MurderESP   and role=="Murder"   then createOrUpdateHighlight(player,COLORS.Murder)
        elseif Settings.SheriffESP  and role=="Sheriff"  then createOrUpdateHighlight(player,COLORS.Sheriff)
        elseif Settings.InnocentESP and role=="Innocent" then createOrUpdateHighlight(player,COLORS.Innocent) end
    end

    setupRGBHumanoid()
    Cache.JumpTracking = {wasJumping=false}

    -- ИСПРАВЛЕН ТРЕЙЛ: удаляем старый, создаём новый на свежем персонаже
    if Settings.Trails then
        removeLocalPlayerTrail()
        task.wait(0.1)
        createLocalPlayerTrail()
    end

    if Settings.FlyEnabled      then task.wait(0.5); startFly()  end
    if Settings.BHopEnabled     then startBHop()                  end
    if Settings.AntiFlingEnabled then setupAntiFling()            end
    if Settings.FovAimbotEnabled then setupFovAimbot()            end
end)

-- ========================================
-- ===== ЗАПУСК =====
-- ========================================

startMainUpdate()
setupSheriffDeadNotif()
createFovCircle()

notify("PlanetHub v3.0", "Загружен успешно!", 4)
