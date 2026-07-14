-- neverchame v13 SECURE - Chameleon Helper
-- Защищённая версия с закодированными ключами

-- ============ АНТИ-ДЕКОМПИЛЯТОР ============
if getgenv then
    if getgenv().__NC_LOADED then return end
    getgenv().__NC_LOADED = true
    -- Ломаем декомпиляторы
    pcall(function()
        getgenv().decompile = function() return "-- Access denied" end
    end)
end

-- ============ ЗАКОДИРОВАННЫЕ КЛЮЧИ ============
-- Ключи закодированы через string.char (нельзя прочитать глазами)
local _k = {
    string.char(78,67,45,55,75,50,77,45,57,80,88,52,45,81,56,84,78),
    string.char(78,67,45,51,70,54,74,45,87,49,82,66,45,53,76,89,72),
    string.char(78,67,45,56,68,52,86,45,67,50,88,65,45,54,71,77,90),
    string.char(78,67,45,49,78,53,84,45,82,55,75,69,45,52,80,87,83),
    string.char(78,67,45,57,72,51,81,45,54,89,74,66,45,50,77,70,67),
    string.char(78,67,45,52,88,56,76,45,68,53,78,65,45,55,86,82,84),
    string.char(78,67,45,54,87,50,80,45,56,71,75,83,45,49,74,66,89),
    string.char(78,67,45,53,65,57,67,45,51,77,72,90,45,56,70,88,81),
    string.char(78,67,45,50,82,55,86,45,52,84,74,78,45,57,76,75,68),
    string.char(78,67,45,56,66,49,71,45,53,87,80,65,45,51,67,89,72),
}

local KEY_LIFETIME = 86400
local KEY_FOLDER = string.char(110,101,118,101,114,99,104,97,109,101,95,107,101,121,115)
local KEY_FILE = string.char(97,99,116,105,118,97,116,105,111,110,46,106,115,111,110)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Функция проверки ключа с обфусцированной логикой
local function _validate(input)
    if not input or type(input) ~= "string" then return false end
    for _, encoded in ipairs(_k) do
        if input == encoded then return true end
    end
    return false
end

local function checkKey()
    if not readfile or not writefile then return "no_files" end
    local path = KEY_FOLDER .. "/" .. KEY_FILE
    pcall(function() if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end end)
    if not (isfile and isfile(path)) then return "need_key" end
    local ok, content = pcall(readfile, path)
    if not ok then return "need_key" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or not data.key or not data.time then return "need_key" end
    if not _validate(data.key) then return "need_key" end
    local elapsed = os.time() - data.time
    if elapsed >= KEY_LIFETIME then return "need_key" end
    return "valid", data.key, data.time
end

local function activateKey(key)
    if not _validate(key) then return false end
    if writefile then
        pcall(function() if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end end)
        local data = { key = key, time = os.time() }
        pcall(function() writefile(KEY_FOLDER .. "/" .. KEY_FILE, HttpService:JSONEncode(data)) end)
    end
    return true, os.time()
end

local function showKeyPrompt()
    local old = CoreGui:FindFirstChild("ncKeyPrompt")
    if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "ncKeyPrompt"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = CoreGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 280)
    frame.Position = UDim2.new(0.5, -200, 0.5, -140)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(100, 150, 255)
    stroke.Thickness = 2

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "neverchame"
    title.TextSize = 26
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(100, 150, 255)
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 60)
    sub.BackgroundTransparency = 1
    sub.Text = "Enter your license key"
    sub.TextSize = 13
    sub.Font = Enum.Font.Gotham
    sub.TextColor3 = Color3.fromRGB(180, 180, 180)
    sub.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -40, 0, 30)
    info.Position = UDim2.new(0, 20, 0, 85)
    info.BackgroundTransparency = 1
    info.Text = "Get key: @neverchame_keys_bot in Telegram"
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.TextColor3 = Color3.fromRGB(120, 180, 255)
    info.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -60, 0, 40)
    input.Position = UDim2.new(0, 30, 0, 125)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    input.BorderSizePixel = 0
    input.PlaceholderText = "NC-XXXX-XXXX-XXXX"
    input.Text = ""
    input.TextSize = 14
    input.Font = Enum.Font.GothamMedium
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    input.ClearTextOnFocus = false
    input.Parent = frame
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -60, 0, 40)
    btn.Position = UDim2.new(0, 30, 0, 180)
    btn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    btn.BorderSizePixel = 0
    btn.Text = "ACTIVATE"
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 235)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.Parent = frame

    local result, activationTime = nil, nil
    btn.MouseButton1Click:Connect(function()
        local key = input.Text
        if key == "" then status.Text = "Enter a key first" return end
        local ok, timeOrErr = activateKey(key)
        if ok then
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            status.Text = "Activated! Loading..."
            result = key
            activationTime = timeOrErr
            task.wait(0.8)
            gui:Destroy()
        else
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
            status.Text = "Invalid key"
        end
    end)
    while result == nil do task.wait(0.1) end
    return result, activationTime
end

local status, savedKey, activationTime = checkKey()
if status == "need_key" or status == "no_files" then
    savedKey, activationTime = showKeyPrompt()
end
if not savedKey then return end

-- ============ ОСНОВНОЙ СКРИПТ ============
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

local flags = {}
flags.esp = false flags.reveal = false flags.invisible = false flags.realInvis = false
flags.tiny = false flags.fullbright = false flags.noclip = false flags.infJump = false
flags.hitboxes = false flags.hitboxSize = 5 flags.walkSpeed = 16 flags.jumpPower = 50
flags.fly = false flags.flySpeed = 50 flags.aimbot = false flags.aimbotFov = 100
flags.aimbotKey = "MouseButton2" flags.antiAfk = true
flags.espName = false flags.espDistance = false flags.espHealth = false flags.godMode = false

local wmSettings = { Show = true, Ping = true, FPS = true, User = true, Custom = false, CustomText = "neverchame.cc" }
local highlights, revealHighlights, espTexts, conns, savedSpots, savedParts = {}, {}, {}, {}, {}, {}
local flyBv, flyBg, flyConn, godForceField, godConn = nil, nil, nil, nil, nil

local configFolder = "neverchame"
local function saveConfig(name)
    if not writefile then return false end
    pcall(function() if not isfolder(configFolder) then makefolder(configFolder) end end)
    local data = { flags = flags, wm = wmSettings, spots = savedSpots }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    return pcall(function() writefile(configFolder .. "/" .. name .. ".json", encoded) end)
end
local function loadConfig(name)
    if not readfile or not isfile then return false end
    local path = configFolder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok, content = pcall(readfile, path)
    if not ok then return false end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 then return false end
    if data.flags then for k, v in pairs(data.flags) do flags[k] = v end end
    if data.wm then for k, v in pairs(data.wm) do wmSettings[k] = v end end
    if data.spots then savedSpots = data.spots end
    return true
end
local function getConfigList()
    local list = {}
    if not listfiles or not isfolder then return list end
    if not isfolder(configFolder) then return list end
    local ok, files = pcall(listfiles, configFolder)
    if not ok then return list end
    for _, f in ipairs(files) do
        local n = string.match(f, "([^/\\]+)%.json$")
        if n then table.insert(list, n) end
    end
    return list
end
local function deleteConfig(name) pcall(function() delfile(configFolder .. "/" .. name .. ".json") end) end

local function createHighlight(char, color, name)
    if not char then return end
    if char:FindFirstChild(name) then return char:FindFirstChild(name) end
    local hl = Instance.new("Highlight")
    hl.Name = name hl.FillColor = color hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop hl.Parent = char
    return hl
end
local function applyESP(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        task.wait(0.3)
        if flags.esp then highlights[player] = createHighlight(char, Color3.fromRGB(100, 150, 255), "ncESP") end
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end
local function removeAllHighlights()
    for _, hl in pairs(highlights) do if hl then pcall(function() hl:Destroy() end) end end
    for _, hl in pairs(revealHighlights) do if hl then pcall(function() hl:Destroy() end) end end
    for _, bg in pairs(espTexts) do if bg then pcall(function() bg:Destroy() end) end end
    highlights, revealHighlights, espTexts = {}, {}, {}
end
local function revealLoop()
    while flags.reveal do
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.Transparency > 0.1 then part.Transparency = 0 end
                        if part.LocalTransparencyModifier > 0.1 then part.LocalTransparencyModifier = 0 end
                    end
                end
                if not revealHighlights[p] then
                    revealHighlights[p] = createHighlight(p.Character, Color3.fromRGB(255, 50, 50), "ncReveal")
                end
            end
        end
        task.wait(0.3)
    end
    for _, hl in pairs(revealHighlights) do if hl then pcall(function() hl:Destroy() end) end end
    revealHighlights = {}
end
local function invisibleLoop()
    while flags.invisible do
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
            end
        end
        task.wait(0.5)
    end
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
        end
    end
end
local function makeTiny(char, state)
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    pcall(function()
        local s = state and 0.3 or 1
        if hum:FindFirstChild("BodyDepthScale") then hum.BodyDepthScale.Value = s end
        if hum:FindFirstChild("BodyHeightScale") then hum.BodyHeightScale.Value = s end
        if hum:FindFirstChild("BodyWidthScale") then hum.BodyWidthScale.Value = s end
        if hum:FindFirstChild("HeadScale") then hum.HeadScale.Value = s end
    end)
end
local function realInvisible(state)
    local char = LocalPlayer.Character
    if not char then return end
    if state then
        savedParts = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                savedParts[part] = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide, Massless = part.Massless, LocalTrans = part.LocalTransparencyModifier }
                part.Transparency = 1
                part.LocalTransparencyModifier = 1
                if part.Name ~= "HumanoidRootPart" then
                    part.Size = Vector3.new(0.05, 0.05, 0.05)
                    part.CanCollide = false
                    part.Massless = true
                end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                savedParts[part] = { Transparency = part.Transparency }
                part.Transparency = 1
            end
        end
    else
        for part, data in pairs(savedParts) do
            if part and part.Parent then
                pcall(function()
                    if data.Size then part.Size = data.Size end
                    if data.Transparency then part.Transparency = data.Transparency end
                    if data.CanCollide ~= nil then part.CanCollide = data.CanCollide end
                    if data.Massless ~= nil then part.Massless = data.Massless end
                    if data.LocalTrans then part.LocalTransparencyModifier = data.LocalTrans end
                end)
            end
        end
        savedParts = {}
    end
end
local function toggleGodMode(state)
    if state then
        local function protect(char)
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if godForceField then pcall(function() godForceField:Destroy() end) end
            godForceField = Instance.new("ForceField")
            godForceField.Name = "ncGodShield"
            godForceField.Visible = false
            godForceField.Parent = char
            if godConn then godConn:Disconnect() end
            godConn = hum.HealthChanged:Connect(function(health)
                if flags.godMode and hum and hum.Parent then
                    if health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                end
            end)
            pcall(function() hum.BreakJointsOnDeath = false end)
        end
        if LocalPlayer.Character then protect(LocalPlayer.Character) end
    else
        if godForceField then pcall(function() godForceField:Destroy() end) godForceField = nil end
        if godConn then godConn:Disconnect() godConn = nil end
    end
end
local function toggleFly(state)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if state then
        flyBv = Instance.new("BodyVelocity")
        flyBv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBv.Velocity = Vector3.new(0, 0, 0)
        flyBv.Parent = hrp
        flyBg = Instance.new("BodyGyro")
        flyBg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBg.CFrame = hrp.CFrame
        flyBg.P = 3000
        flyBg.Parent = hrp
        flyConn = RunService.Heartbeat:Connect(function()
            if not flags.fly or not flyBv then return end
            local cf = Camera.CFrame
            local d = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.new(0, 1, 0) end
            if d.Magnitude > 0 then flyBv.Velocity = d.Unit * flags.flySpeed else flyBv.Velocity = Vector3.new(0, 0, 0) end
            flyBg.CFrame = cf
        end)
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBv then flyBv:Destroy() flyBv = nil end
        if flyBg then flyBg:Destroy() flyBg = nil end
    end
end
local function findTargetPart(char)
    if not char then return nil end
    local candidates = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(candidates) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then return p end
    end
    return nil
end
local function getClosest()
    local closest, closestPart, minDist = nil, nil, flags.aimbotFov
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part = findTargetPart(p.Character)
                if part then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local mp = UserInputService:GetMouseLocation()
                        local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                        if d < minDist then minDist = d closest = p closestPart = part end
                    end
                end
            end
        end
    end
    return closest, closestPart
end
table.insert(conns, RunService.RenderStepped:Connect(function()
    if flags.aimbot then
        local key = Enum.UserInputType[flags.aimbotKey] or Enum.UserInputType.MouseButton2
        if UserInputService:IsMouseButtonPressed(key) then
            local t, part = getClosest()
            if t and part then Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position) end
        end
    end
end))
local function updateESPText(p)
    if p == LocalPlayer or not p.Character then return end
    local head = p.Character:FindFirstChild("Head") or findTargetPart(p.Character)
    if not head then return end
    if not espTexts[p] then
        local bg = Instance.new("BillboardGui")
        bg.Name = "ncESPText" bg.Adornee = head bg.Size = UDim2.new(0, 200, 0, 60)
        bg.StudsOffset = Vector3.new(0, 2.5, 0) bg.AlwaysOnTop = true bg.Parent = head
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0) lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold lbl.TextSize = 13
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255) lbl.TextStrokeTransparency = 0 lbl.Parent = bg
        espTexts[p] = bg
    end
    local lbl = espTexts[p]:FindFirstChildOfClass("TextLabel")
    local text = ""
    if flags.espName then text = text .. p.Name .. "\n" end
    
