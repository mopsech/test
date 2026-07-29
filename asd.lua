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
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========================================
-- ===== ПЕРЕМЕННЫЕ =====
-- ========================================

-- ESP
local MurderESP = false
local SheriffESP = false
local InnocentESP = false
local SkeletonESP = false
local UpdateConnection = nil

-- Chams
local ChamsEnabled = false
local ChamsMurder = false
local ChamsSheriff = false
local ChamsInnocent = false

-- Box
local BoxMurder = false
local BoxSheriff = false
local BoxInnocent = false
local BoxConnections = {}

-- Visuals
local JumpCircle = false
local ChinaHat = false
local Trail = false
local FOVChanger = 70

-- Rage
local FlyEnabled = false
local FlySpeed = 80
local FlyConnection = nil
local FlyBodyGyro = nil
local FlyBodyVelocity = nil

local BHopEnabled = false
local BHopConnection = nil
local BHopHeight = 3

local SilentAimEnabled = false
local SilentAimFOV = 150
local SilentAimTarget = nil

local TriggerBotEnabled = false

-- Other
local NoclipEnabled = false
local NoclipConnection = nil
local XRayEnabled = false
local AntiFlingEnabled = false
local AntiFlingConnection = nil

local SpinBotEnabled = false
local SpinConnection = nil

-- Fling
local FlingEnabled = false
local FlingConnection = nil
local FlingPart = nil

-- Configs
local Configs = {}
local CurrentConfig = "Default"

-- References storage
local Highlights = {}
local SkeletonParts = {}
local Visuals3D = {}
local TrailAttachments = {}

-- ========================================
-- ===== ЦВЕТА =====
-- ========================================

local COLORS = {
    Murder = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Purple = Color3.fromRGB(138, 43, 226),
    White = Color3.fromRGB(255, 255, 255),
    Gold = Color3.fromRGB(255, 215, 0)
}

-- ========================================
-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
-- ========================================

local function checkKnife(player)
    if player.Character then
        for _, item in ipairs(player.Character:GetDescendants()) do
            if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("blade")) then 
                return true 
            end
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
    if player.Character then
        for _, item in ipairs(player.Character:GetDescendants()) do
            if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("pistol") or item.Name:lower():find("revolver")) then 
                return true 
            end
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

local function getConfigPath()
    return "MurderHubConfigs_" .. LocalPlayer.UserId
end

-- ========================================
-- ===== КОНФИГИ =====
-- ========================================

local function saveConfig(name)
    local config = {
        MurderESP = MurderESP,
        SheriffESP = SheriffESP,
        InnocentESP = InnocentESP,
        SkeletonESP = SkeletonESP,
        ChamsEnabled = ChamsEnabled,
        ChamsMurder = ChamsMurder,
        ChamsSheriff = ChamsSheriff,
        ChamsInnocent = ChamsInnocent,
        BoxMurder = BoxMurder,
        BoxSheriff = BoxSheriff,
        BoxInnocent = BoxInnocent,
        JumpCircle = JumpCircle,
        ChinaHat = ChinaHat,
        Trail = Trail,
        FlyEnabled = FlyEnabled,
        FlySpeed = FlySpeed,
        BHopEnabled = BHopEnabled,
        SilentAimEnabled = SilentAimEnabled,
        TriggerBotEnabled = TriggerBotEnabled,
        NoclipEnabled = NoclipEnabled,
        XRayEnabled = XRayEnabled,
        AntiFlingEnabled = AntiFlingEnabled,
        FOVChanger = FOVChanger
    }
    Configs[name] = config
    
    local success = pcall(function()
        writefile(getConfigPath() .. "/" .. name .. ".json", game:GetService("HttpService"):JSONEncode(config))
    end)
    
    if success then
        StarterGui:SetCore("SendNotification", {
            Title = "Murder Hub",
            Text = "Config '" .. name .. "' saved!",
            Duration = 3
        })
    end
    return success
end

local function loadConfig(name)
    if not Configs[name] then
        local success = pcall(function()
            local data = readfile(getConfigPath() .. "/" .. name .. ".json")
            Configs[name] = game:GetService("HttpService"):JSONDecode(data)
        end)
        if not success then return false end
    end
    
    local config = Configs[name]
    if not config then return false end
    
    -- Apply config values
    MurderESP = config.MurderESP or false
    SheriffESP = config.SheriffESP or false
    InnocentESP = config.InnocentESP or false
    SkeletonESP = config.SkeletonESP or false
    ChamsEnabled = config.ChamsEnabled or false
    ChamsMurder = config.ChamsMurder or false
    ChamsSheriff = config.ChamsSheriff or false
    ChamsInnocent = config.ChamsInnocent or false
    BoxMurder = config.BoxMurder or false
    BoxSheriff = config.BoxSheriff or false
    BoxInnocent = config.BoxInnocent or false
    JumpCircle = config.JumpCircle or false
    ChinaHat = config.ChinaHat or false
    Trail = config.Trail or false
    FlySpeed = config.FlySpeed or 80
    BHopEnabled = config.BHopEnabled or false
    SilentAimEnabled = config.SilentAimEnabled or false
    TriggerBotEnabled = config.TriggerBotEnabled or false
    NoclipEnabled = config.NoclipEnabled or false
    XRayEnabled = config.XRayEnabled or false
    AntiFlingEnabled = config.AntiFlingEnabled or false
    FOVChanger = config.FOVChanger or 70
    
    CurrentConfig = name
    
    StarterGui:SetCore("SendNotification", {
        Title = "Murder Hub",
        Text = "Config '" .. name .. "' loaded!",
        Duration = 3
    })
    return true
end

local function deleteConfig(name)
    if Configs[name] then
        Configs[name] = nil
        pcall(function()
            delfile(getConfigPath() .. "/" .. name .. ".json")
        end)
        StarterGui:SetCore("SendNotification", {
            Title = "Murder Hub",
            Text = "Config '" .. name .. "' deleted!",
            Duration = 3
        })
    end
end

local function getConfigList()
    local list = {}
    pcall(function()
        if isfolder(getConfigPath()) then
            for _, file in ipairs(listfiles(getConfigPath())) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(list, name)
                end
            end
        end
    end)
    return list
end

-- Create config folder
pcall(function()
    if not isfolder(getConfigPath()) then
        makefolder(getConfigPath())
    end
end)

-- ========================================
-- ===== GRAB GUN (Телепорт к оружию) =====
-- ========================================

local function grabGun()
    local gunModel = nil
    
    -- Ищем Gun в workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol") or obj.Name:lower():find("revolver")) then
            gunModel = obj
            break
        elseif obj:IsA("Model") and (obj.Name:lower():find("gun") or obj.Name:lower():find("pistol")) then
            gunModel = obj
            break
        end
    end
    
    -- Ищем позицию
    local gunPos = nil
    if gunModel then
        if gunModel:IsA("Tool") then
            local handle = gunModel:FindFirstChild("Handle")
            if handle then gunPos = handle.Position end
        elseif gunModel:IsA("Model") then
            local primary = gunModel.PrimaryPart
            if primary then gunPos = primary.Position
            else
                local part = gunModel:FindFirstChildWhichIsA("BasePart")
                if part then gunPos = part.Position end
            end
        end
    end
    
    if gunPos and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(gunPos)
            StarterGui:SetCore("SendNotification", {
                Title = "Grab Gun",
                Text = "Teleported to Gun!",
                Duration = 2
            })
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title = "Grab Gun",
            Text = "Gun not found!",
            Duration = 2
        })
    end
end

-- Grab Gun при смерти шерифа
local function setupGrabGun()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function(char)
                local humanoid = char:WaitForChild("Humanoid")
                humanoid.Died:Connect(function()
                    if checkGun(player) then
                        task.wait(0.1)
                        grabGun()
                    end
                end)
            end)
            
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Died:Connect(function()
                        if checkGun(player) then
                            task.wait(0.1)
                            grabGun()
                        end
                    end)
                end
            end
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            local humanoid = char:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                if checkGun(player) then
                    task.wait(0.1)
                    grabGun()
                end
            end)
        end)
    end)
end

-- ========================================
-- ===== 3D РИСОВАНИЕ =====
-- ========================================

local DrawingLib = {} do
    DrawingLib.__index = DrawingLib
    
    function DrawingLib.new(type, props)
        local obj = Drawing.new(type)
        if props then
            for i, v in pairs(props) do
                obj[i] = v
            end
        end
        return obj
    end
    
    function DrawingLib:Destroy()
        if self and self.Remove then
            self:Remove()
        end
    end
end

-- ========================================
-- ===== VISUALS =====
-- ========================================

local function clearVisualEffects()
    -- Clear 3D visuals
    for _, obj in pairs(Visuals3D) do
        if obj then
            pcall(function() obj:Destroy() end)
            pcall(function() obj:Remove() end)
        end
    end
    Visuals3D = {}
    
    -- Clear trails
    for _, attachment in pairs(TrailAttachments) do
        pcall(function() attachment:Destroy() end)
    end
    TrailAttachments = {}
end

local function createJumpCircle(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Удаляем старые
    local old = Visuals3D[player.UserId .. "_jumpcircle"]
    if old then pcall(function() old:Destroy() end) end
    
    -- Создаём кольцо
    local ring = Instance.new("Part")
    ring.Name = "JumpCircle"
    ring.Shape = Enum.PartType.Cylinder
    ring.Radius = 3
    ring.Size = Vector3.new(0.2, 0.2, 0.2)
    ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
    ring.Color = COLORS.Purple
    ring.Material = Enum.Material.Neon
    ring.Transparency = 0.3
    ring.Anchored = true
    ring.CanCollide = false
    ring.Parent = workspace
    Visuals3D[player.UserId .. "_jumpcircle"] = ring
    
    -- Анимация
    task.spawn(function()
        while ring and ring.Parent do
            if hrp and hrp.Parent then
                -- Проверяем, прыгает ли игрок
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Jump then
                    ring.Transparency = 0
                    ring.Size = Vector3.new(0.2, 6, 6)
                else
                    ring.Transparency = 0.5
                    ring.Size = Vector3.new(0.2, 3, 3)
                end
                ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
            end
            task.wait()
        end
    end)
end

local function createChinaHat(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Удаляем старые
    local old = Visuals3D[player.UserId .. "_chinahat"]
    if old then pcall(function() old:Destroy() end) end
    
    -- Создаём "шляпу" над головой
    local hat = Instance.new("Part")
    hat.Name = "ChinaHat"
    hat.Shape = Enum.PartType.Cylinder
    hat.Radius = 2
    hat.Size = Vector3.new(0.3, 0.1, 0.1)
    hat.CFrame = hrp.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(90))
    hat.Color = COLORS.Gold
    hat.Material = Enum.Material.Neon
    hat.Transparency = 0.2
    hat.Anchored = true
    hat.CanCollide = false
    hat.Parent = workspace
    Visuals3D[player.UserId .. "_chinahat"] = hat
    
    -- Анимация вращения
    task.spawn(function()
        local angle = 0
        while hat and hat.Parent do
            if hrp and hrp.Parent then
                angle = angle + 0.05
                hat.CFrame = hrp.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(angle, 0, math.rad(90))
            end
            task.wait()
        end
    end)
end

local function createTrail(player)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Удаляем старые
    for _, att in pairs(TrailAttachments[player.UserId] or {}) do
        pcall(function() att:Destroy() end)
    end
    TrailAttachments[player.UserId] = {}
    
    local color = COLORS.Purple
    local role = getRole(player)
    if role == "Murder" then color = COLORS.Murder
    elseif role == "Sheriff" then color = COLORS.Sheriff
    else color = COLORS.Innocent end
    
    local trail = Instance.new("Trail")
    local att1 = Instance.new("Attachment")
    local att2 = Instance.new("Attachment")
    
    att1.Parent = hrp
    att1.Position = Vector3.new(0, -2, 0)
    
    att2.Parent = hrp
    att2.Position = Vector3.new(0, 2, 0)
    
    trail.Attachment0 = att1
    trail.Attachment1 = att2
    trail.Color = ColorSequence.new(color)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Lifetime = 1
    trail.MinLength = 0.1
    trail.LightEmission = 1
    trail.Parent = hrp
    
    table.insert(TrailAttachments[player.UserId] or {}, att1)
    table.insert(TrailAttachments[player.UserId] or {}, att2)
    table.insert(TrailAttachments[player.UserId] or {}, trail)
end

-- ========================================
-- ===== SKELETON ESP =====
-- ========================================

local SkeletonConnections = {}

local BONE_NAMES = {
    {"Head", "Neck"},
    {"Neck", "RightShoulder"},
    {"Neck", "LeftShoulder"},
    {"RightShoulder", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"LeftShoulder", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"Neck", "UpperTorso"},
    {"UpperTorso", "RightUpperLeg"},
    {"UpperTorso", "LeftUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"}
}

local function getCharacter(player)
    return player and player.Character
end

local function getBonePosition(character, boneName)
    local bone = character:FindFirstChild(boneName)
    if bone and bone:IsA("Motor6D") then
        return bone.Part1 and bone.Part1.Position or nil
    elseif bone and bone:IsA("BasePart") then
        return bone.Position
    end
    return nil
end

local function createSkeletonForPlayer(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    
    -- Очищаем старый скелет
    local old = SkeletonParts[player.UserId]
    if old then
        for _, line in pairs(old) do
            if line then pcall(function() line:Remove() end) end
        end
    end
    SkeletonParts[player.UserId] = {}
    
    local lines = {}
    
    for i, bonePair in ipairs(BONE_NAMES) do
        local line = Drawing.new("Line")
        line.Color = Color3.new(1, 1, 1)
        line.Thickness = 1
        line.Transparency = 0.5
        line.Visible = false
        lines[i] = line
    end
    
    SkeletonParts[player.UserId] = lines
    
    -- Обновление
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not player.Character or not player.Character.Parent then
            connection:Disconnect()
            for _, line in pairs(lines) do
                if line then pcall(function() line:Remove() end) end
            end
            SkeletonParts[player.UserId] = nil
            return
        end
        
        if not SkeletonESP then
            for _, line in pairs(lines) do
                if line then line.Visible = false end
            end
            return
        end
        
        local character = player.Character
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local camCF = Camera.CFrame
        
        for i, bonePair in ipairs(BONE_NAMES) do
            local line = lines[i]
            if not line then continue end
            
            local pos1 = getBonePosition(character, bonePair[1])
            local pos2 = getBonePosition(character, bonePair[2])
            
            if pos1 and pos2 then
                local vec1 = (camCF * CFrame.new(pos1)).Position
                local vec2 = (camCF * CFrame.new(pos2)).Position
                
                local s1, p1 = Camera:WorldToScreenPoint(vec1)
                local s2, p2 = Camera:WorldToScreenPoint(vec2)
                
                if s1.Z > 0 and s2.Z > 0 then
                    line.From = Vector2.new(p1.X, p1.Y)
                    line.To = Vector2.new(p2.X, p2.Y)
                    line.Visible = true
                    line.Color = getRoleColor(player)
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end)
    
    SkeletonConnections[player.UserId] = connection
end

local function clearAllSkeletons()
    for userId, lines in pairs(SkeletonParts) do
        for _, line in pairs(lines) do
            if line then pcall(function() line:Remove() end) end
        end
    end
    SkeletonParts = {}
    
    for _, conn in pairs(SkeletonConnections) do
        pcall(function() conn:Disconnect() end)
    end
    SkeletonConnections = {}
end

local function updateSkeletons()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character and not SkeletonParts[player.UserId] then
                createSkeletonForPlayer(player)
            end
        end
    end
end

-- ========================================
-- ===== HIGHLIGHT ESP =====
-- ========================================

local function createHighlight(obj, color)
    if not obj then return end
    local h = obj:FindFirstChild("H")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "H"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
    end
    h.Adornee = obj
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0.3
    h.Enabled = true
end

local function removeHighlight(obj)
    if obj and obj:FindFirstChild("H") then 
        obj.H:Destroy() 
    end
end

local function clearAllHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then 
            removeHighlight(player.Character) 
        end
    end
end

-- ========================================
-- ===== CHAMS (ВСЕ ФИОЛЕТОВЫЕ) =====
-- ========================================

local function setPlayerChams(player, enabled, colorOverride)
    if not player.Character then return end
    
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if ChamsEnabled then
                part.Material = Enum.Material.ForceField
                part.Color = colorOverride or COLORS.Purple
                part.Transparency = 0.3
            else
                part.Material = Enum.Material.Plastic
                part.Transparency = 0
            end
        end
    end
end

local function clearPlayerChams(player)
    if not player.Character then return end
    
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.Plastic
            part.Transparency = 0
        end
    end
end

local function updateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hasKnife = checkKnife(player)
            local hasGun = checkGun(player)
            
            if ChamsEnabled then
                local color = COLORS.Purple
                if hasKnife and ChamsMurder then
                    color = COLORS.Murder
                elseif hasGun and ChamsSheriff then
                    color = COLORS.Sheriff
                elseif not hasKnife and not hasGun and ChamsInnocent then
                    color = COLORS.Innocent
                end
                setPlayerChams(player, true, color)
            else
                clearPlayerChams(player)
            end
        end
    end
end

-- ========================================
-- ===== BOX ESP =====
-- ========================================

local function clearBoxes()
    for _, item in ipairs(BoxConnections) do
        pcall(function()
            if item:IsA("BoxHandleAdornment") then item:Destroy()
            elseif typeof(item) == "RBXScriptConnection" then item:Disconnect() end
        end)
    end
    BoxConnections = {}
end

local function createBox(player, color)
    if not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3, 6, 3)
    box.CFrame = hrp.CFrame
    box.Color3 = color
    box.Transparency = 0.5
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Parent = hrp
    table.insert(BoxConnections, box)
    
    local conn = RunService.Heartbeat:Connect(function()
        if box and box.Parent then 
            box.CFrame = hrp.CFrame 
        end
    end)
    table.insert(BoxConnections, conn)
end

local function updateBoxes()
    clearBoxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        
        local hasKnife = checkKnife(player)
        local hasGun = checkGun(player)
        
        if hasKnife and BoxMurder then 
            createBox(player, COLORS.Murder)
        elseif hasGun and BoxSheriff then 
            createBox(player, COLORS.Sheriff)
        elseif not hasKnife and not hasGun and BoxInnocent then 
            createBox(player, COLORS.Innocent)
        end
    end
end

-- ========================================
-- ===== UPDATE ESP =====
-- ========================================

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        
        local hasKnife = checkKnife(player)
        local hasGun = checkGun(player)
        local role = getRole(player)
        
        -- Highlight ESP
        if MurderESP and role == "Murder" then
            createHighlight(player.Character, COLORS.Murder)
        elseif SheriffESP and role == "Sheriff" then
            createHighlight(player.Character, COLORS.Sheriff)
        elseif InnocentESP and role == "Innocent" then
            createHighlight(player.Character, COLORS.Innocent)
        else
            removeHighlight(player.Character)
        end
        
        -- Visual Effects
        if JumpCircle then
            createJumpCircle(player)
        else
            local old = Visuals3D[player.UserId .. "_jumpcircle"]
            if old then pcall(function() old:Destroy() end) Visuals3D[player.UserId .. "_jumpcircle"] = nil end
        end
        
        if ChinaHat then
            createChinaHat(player)
        else
            local old = Visuals3D[player.UserId .. "_chinahat"]
            if old then pcall(function() old:Destroy() end) Visuals3D[player.UserId .. "_chinahat"] = nil end
        end
        
        if Trail then
            createTrail(player)
        end
    end
end

local function setupESP()
    if UpdateConnection then UpdateConnection:Disconnect() end
    
    local anyESP = MurderESP or SheriffESP or InnocentESP or SkeletonESP or ChamsEnabled or BoxMurder or BoxSheriff or BoxInnocent or JumpCircle or ChinaHat or Trail
    
    if anyESP then
        UpdateConnection = RunService.Heartbeat:Connect(function()
            updateESP()
            updateBoxes()
            updateChams()
        end)
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                createSkeletonForPlayer(player)
            end)
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                createSkeletonForPlayer(player)
            end
        end
    else
        clearAllHighlights()
        clearAllSkeletons()
        clearBoxes()
        clearVisualEffects()
    end
end

-- ========================================
-- ===== RAGE TAB =====
-- ========================================

local RageTab = Window:Tab({ Title = "Rage", Icon = "sword" })
local RageSection = RageTab:Section({ Title = "Rage Settings", Side = "Left" })

-- FLY
RageSection:Toggle({
    Title = "Fly",
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        if Value then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            FlyBodyGyro = Instance.new("BodyGyro")
            FlyBodyGyro.Name = "FlyBodyGyro"
            FlyBodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 1e9
            FlyBodyGyro.P = 1e4
            FlyBodyGyro.D = 1e3
            FlyBodyGyro.Parent = hrp
            
            FlyBodyVelocity = Instance.new("BodyVelocity")
            FlyBodyVelocity.Name = "FlyBodyVelocity"
            FlyBodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 1e9
            FlyBodyVelocity.Parent = hrp
            
            FlyConnection = RunService.Heartbeat:Connect(function()
                if not FlyEnabled or not LocalPlayer.Character then return end
                
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp or not FlyBodyVelocity or not FlyBodyGyro then return end
                
                local cam = workspace.CurrentCamera
                local forward = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
                local right = cam.CFrame.RightVector * Vector3.new(1, 0, 1)
                local move = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    FlyBodyVelocity.Velocity = Vector3.new(move.X * FlySpeed, FlySpeed, move.Z * FlySpeed)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    FlyBodyVelocity.Velocity = Vector3.new(move.X * FlySpeed, -FlySpeed, move.Z * FlySpeed)
                else
                    FlyBodyVelocity.Velocity = Vector3.new(move.X * FlySpeed, 0, move.Z * FlySpeed)
                end
                
                FlyBodyGyro.CFrame = cam.CFrame
            end)
        else
            if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
            if LocalPlayer.Character then
                for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if v.Name == "FlyBodyGyro" or v.Name == "FlyBodyVelocity" then 
                        v:Destroy() 
                    end
                end
            end
            FlyBodyGyro = nil
            FlyBodyVelocity = nil
        end
    end
})

RageSection:Slider({
    Title = "Fly Speed",
    Default = 80,
    Min = 10,
    Max = 200,
    Callback = function(Value)
        FlySpeed = Value
    end
})

-- BUNNY HOP
RageSection:Toggle({
    Title = "Bunny Hop",
    Default = false,
    Callback = function(Value)
        BHopEnabled = Value
        if Value then
            BHopConnection = RunService.RenderStepped:Connect(function()
                if not BHopEnabled or not LocalPlayer.Character then return end
                
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and hrp then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        humanoid.Jump = true
                        task.wait()
                        humanoid.Jump = false
                    end
                end
            end)
        else
            if BHopConnection then BHopConnection:Disconnect() BHopConnection = nil end
        end    end
})

-- SILENT AIM (Kill through wall)
RageSection:Toggle({
    Title = "Silent Aim (Wall)",
    Default = false,
    Callback = function(Value)
        SilentAimEnabled = Value
    end
})

RageSection:Slider({
    Title = "Silent Aim FOV",
    Default = 150,
    Min = 10,
    Max = 500,
    Callback = function(Value)
        SilentAimFOV = Value
    end
})

-- TRIGGER BOT
RageSection:Toggle({
    Title = "Trigger Bot",
    Default = false,
    Callback = function(Value)
        TriggerBotEnabled = Value
    end
})

-- SPIN BOT
local spinSpeed = 5

RageSection:Toggle({
    Title = "Spin Bot",
    Default = false,
    Callback = function(Value)
        SpinBotEnabled = Value
        if Value then
            SpinConnection = RunService.Heartbeat:Connect(function()
                if not SpinBotEnabled or not LocalPlayer.Character then return end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then 
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0) 
                end
            end)
        else
            if SpinConnection then SpinConnection:Disconnect() SpinConnection = nil end
        end
    end
})

RageSection:Slider({
    Title = "Spin Speed",
    Default = 5,
    Min = 1,
    Max = 50,
    Callback = function(Value)
        spinSpeed = Value
    end
})

-- ========================================
-- ===== COMBAT TAB =====
-- ========================================

local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local CombatSection = CombatTab:Section({ Title = "Combat Settings", Side = "Left" })

-- NOCLIP
CombatSection:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(Value)
        NoclipEnabled = Value
        if Value then
            NoclipConnection = RunService.Stepped:Connect(function()
                if NoclipEnabled and LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then 
                            part.CanCollide = false 
                        end
                    end
                end
            end)
        else
            if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
        end
    end
})

-- ANTI FLING
CombatSection:Toggle({
    Title = "Anti Fling",
    Default = false,
    Callback = function(Value)
        AntiFlingEnabled = Value
        if Value then
            AntiFlingConnection = RunService.Heartbeat:Connect(function()
                if not AntiFlingEnabled or not LocalPlayer.Character then return end
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Velocity.Magnitude > 100 then
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end)
        else
            if AntiFlingConnection then AntiFlingConnection:Disconnect() AntiFlingConnection = nil end
        end
    end
})

-- GRAB GUN
CombatSection:Button({
    Title = "Grab Gun",
    Description = "Teleport to sheriff's gun",
    Callback = function()
        grabGun()
    end
})

-- FOV CHANGER
CombatSection:Slider({
    Title = "FOV Changer",
    Default = 70,
    Min = 50,
    Max = 120,
    Callback = function(Value)
        FOVChanger = Value
        Camera.FieldOfView = Value
    end
})

-- ========================================
-- ===== VISUAL TAB =====
-- ========================================

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local VisualSection = VisualTab:Section({ Title = "ESP Settings", Side = "Left" })

-- XRAY
VisualSection:Toggle({
    Title = "XRay",
    Default = false,
    Callback = function(Value)
        XRayEnabled = Value
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsA("Terrain") then
                part.LocalTransparencyModifier = Value and 0.7 or 0
            end
        end
    end
})

-- HIGHLIGHT ESP
VisualSection:Toggle({
    Title = "ESP Murder (Red)",
    Default = false,
    Callback = function(Value)
        MurderESP = Value
        setupESP()
    end
})

VisualSection:Toggle({
    Title = "ESP Sheriff (Blue)",
    Default = false,
    Callback = function(Value)
        SheriffESP = Value
        setupESP()
    end
})

VisualSection:Toggle({
    Title = "ESP Innocent (Green)",
    Default = false,
    Callback = function(Value)
        InnocentESP = Value
        setupESP()
    end
})

-- BOX ESP
VisualSection:Toggle({
    Title = "Box Murder",
    Default = false,
    Callback = function(Value)
        BoxMurder = Value
        setupESP()
    end
})

VisualSection:Toggle({
    Title = "Box Sheriff",
    Default = false,
    Callback = function(Value)
        BoxSheriff = Value
        setupESP()
    end
})

VisualSection:Toggle({
    Title = "Box Innocent",
    Default = false,
    Callback = function(Value)
        BoxInnocent = Value
        setupESP()
    end
})

-- SKELETON ESP
VisualSection:Toggle({
    Title = "Skeleton ESP",
    Default = false,
    Callback = function(Value)
        SkeletonESP = Value
        if Value then
            updateSkeletons()
        else
            clearAllSkeletons()
        end
        setupESP()
    end
})

-- CHAMS
local ChamsSection = VisualTab:Section({ Title = "Chams Settings", Side = "Right" })

ChamsSection:Toggle({
    Title = "Chams (Purple All)",
    Default = false,
    Callback = function(Value)
        ChamsEnabled = Value
        setupESP()
    end
})

ChamsSection:Toggle({
    Title = "Chams Murder",
    Default = false,
    Callback = function(Value)
        ChamsMurder = Value
        setupESP()
    end
})

ChamsSection:Toggle({
    Title = "Chams Sheriff",
    Default = false,
    Callback = function(Value)
        ChamsSheriff = Value
        setupESP()
    end
})

ChamsSection:Toggle({
    Title = "Chams Innocent",
    Default = false,
    Callback = function(Value)
        ChamsInnocent = Value
        setupESP()
    end
})

-- VISUAL EFFECTS
local EffectsSection = VisualTab:Section({ Title = "Visual Effects", Side = "Right" })

EffectsSection:Toggle({
    Title = "Jump Circle",
    Default = false,
    Callback = function(Value)
        JumpCircle = Value
        setupESP()
    end
})

EffectsSection:Toggle({
    Title = "China Hat",
    Default = false,
    Callback = function(Value)
        ChinaHat = Value
        setupESP()
    end
})

EffectsSection:Toggle({
    Title = "Trail",
    Default = false,
    Callback = function(Value)
        Trail = Value
        setupESP()
    end
})

-- ========================================
-- ===== FLING TAB =====
-- ========================================

local FlingTab = Window:Tab({ Title = "Fling", Icon = "rocket" })
local FlingSection = FlingTab:Section({ Title = "Fling Settings", Side = "Left" })

-- FLING MODE
FlingSection:Toggle({
    Title = "Super Fling",
    Default = false,
    Callback = function(Value)
        FlingEnabled = Value
        if Value then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                FlingEnabled = false
                return
            end
            
            FlingPart = Instance.new("Part")
            FlingPart.Name = "FlingPart"
            FlingPart.Size = Vector3.new(2, 0.5, 2)
            FlingPart.Anchored = true
            FlingPart.CanCollide = false
            FlingPart.Transparency = 1
            FlingPart.Position = hrp.Position
            FlingPart.Parent = workspace
            
            local alignPos = Instance.new("AlignPosition")
            alignPos.Attachment0 = Instance.new("Attachment", hrp)
            alignPos.Attachment1 = Instance.new("Attachment", FlingPart)
            alignPos.RigidityEnabled = true
            alignPos.Responsiveness = math.huge
            alignPos.MaxForce = math.huge
            alignPos.MaxVelocity = math.huge
            alignPos.Parent = FlingPart
            
            local att0 = hrp:FindFirstChildOfClass("Attachment")
            local att1 = FlingPart:FindFirstChildOfClass("Attachment")
            if att0 and att1 then
                alignPos.Attachment0 = att0
                alignPos.Attachment1 = att1
            end
            
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                pcall(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                end)
            end
            
            FlingConnection = RunService.Heartbeat:Connect(function()
                if not FlingEnabled or not LocalPlayer.Character or not FlingPart then return end
                
                local hrp2 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp2 then return end
                
                hrp2.AssemblyAngularVelocity = Vector3.new(
                    math.random(-500, 500),
                    math.random(-500, 500),
                    math.random(-500, 500)
                ) * 2
                
                hrp2.Velocity = Vector3.new(
                    math.random(-200, 200),
                    math.random(-500, 500),
                    math.random(-200, 200)
                )
                
                if math.random(1, 3) == 1 then
                    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        pcall(function() humanoid.Jump = true end)
                    end
                end
            end)
        else
            if FlingConnection then 
                FlingConnection:Disconnect() 
                FlingConnection = nil 
            end
            
            if FlingPart then 
                FlingPart:Destroy() 
                FlingPart = nil 
            end
            
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    pcall(function()
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end)
                end
                
                for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("AlignPosition") then
                        v:Destroy()
                    end
                end
            end
        end
    end
})

-- FLING MURDER
FlingSection:Button({
    Title = "Fling Murder",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and checkKnife(player) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(0, 500, 0)
                    task.wait(0.1)
                    hrp.Velocity = Vector3.new(9999, 9999, 9999)
                    StarterGui:SetCore("SendNotification", {
                        Title = "Fling",
                        Text = "Murder flinged: " .. player.Name,
                        Duration = 3
                    })
                end
            end
        end
    end
})

-- FLING SHERIFF
FlingSection:Button({
    Title = "Fling Sheriff",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and checkGun(player) then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(0, 500, 0)
                    task.wait(0.1)
                    hrp.Velocity = Vector3.new(9999, 9999, 9999)
                    StarterGui:SetCore("SendNotification", {
                        Title = "Fling",
                        Text = "Sheriff flinged: " .. player.Name,
                        Duration = 3
                    })
                end
            end
        end
    end
})

-- FLING ALL
FlingSection:Button({
    Title = "Fling All",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(0, 500, 0)
                    task.wait(0.05)
                    hrp.Velocity = Vector3.new(9999, 9999, 9999)
                end
            end
        end
        StarterGui:SetCore("SendNotification", {
            Title = "Fling",
            Text = "All players flinged!",
            Duration = 3
        })
    end
})

-- ========================================
-- ===== CONFIGS TAB =====
-- ========================================

local ConfigsTab = Window:Tab({ Title = "Configs", Icon = "save" })
local ConfigsSection = ConfigsTab:Section({ Title = "Config Settings", Side = "Left" })

local ConfigNameInput = ""

ConfigsSection:Input({
    Title = "Config Name",
    Default = "MyConfig",
    Placeholder = "Enter config name...",
    Callback = function(Value)
        ConfigNameInput = Value
    end
})

ConfigsSection:Button({
    Title = "Save Config",
    Callback = function()
        local name = ConfigNameInput ~= "" and ConfigNameInput or "Config_" .. tick()
        saveConfig(name)
    end
})

ConfigsSection:Button({
    Title = "Load Config",
    Callback = function()
        local name = ConfigNameInput ~= "" and ConfigNameInput or "Default"
        loadConfig(name)
    end
})

ConfigsSection:Button({
    Title = "Delete Config",
    Callback = function()
        local name = ConfigNameInput ~= "" and ConfigNameInput or "Default"
        deleteConfig(name)
    end
})

ConfigsSection:Button({
    Title = "Refresh Config List",
    Callback = function()
        local list = getConfigList()
        if #list > 0 then
            print("Configs: " .. table.concat(list, ", "))
        else
            print("No configs found")
        end
    end
})

-- ========================================
-- ===== SETTINGS TAB =====
-- ========================================

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "gear" })
local SettingsSection = SettingsTab:Section({ Title = "Settings", Side = "Left" })

SettingsSection:Label({
    Title = "Murder Hub v2.0",
    Description = "Premium hub for Murder Mystery",
    Icon = "info"
})

SettingsSection:Button({
    Title = "Destroy UI",
    Description = "Close the hub",
    Callback = function()
        Window:Destroy()
    end
})

SettingsSection:Button({
    Title = "Rejoin Game",
    Callback = function()
        TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ========================================
-- ===== ИНИЦИАЛИЗАЦИЯ =====
-- ========================================

-- Grab Gun система
setupGrabGun()

-- Очистка при смене персонажа
LocalPlayer.CharacterAdded:Connect(function()
    clearAllHighlights()
    clearAllSkeletons()
    clearBoxes()
    clearVisualEffects()
    
    -- Перезапуск флая
    if FlyEnabled then
        FlyEnabled = false
        task.wait(0.5)
        FlyEnabled = true
    end
end)

-- Очистка при выходе
LocalPlayer.CharacterRemoving:Connect(function()
    clearVisualEffects()
end)

-- Создание скелетонов для уже существующих игроков
task.wait(1)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        createSkeletonForPlayer(player)
    end
end
