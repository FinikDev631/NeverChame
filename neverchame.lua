-- neverchame v19 - HASHED KEYS PROTECTION

if getgenv then
    if getgenv().__NC_LOADED then return end
    getgenv().__NC_LOADED = true
    pcall(function()
        getgenv().decompile = function() return "-- Access denied" end
    end)
end

-- ⚡ GITHUB URL
local KEYS_URL = "https://raw.githubusercontent.com/FinikDev631/NeverChame/main/keys.json"
local KEY_LIFETIME = 86400

-- 🔐 СЕКРЕТНАЯ СОЛЬ (должна совпадать с ботом!)
local HASH_SALT = "nc_2024_secret_neverchame_x9k2m"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ SHA-256 РЕАЛИЗАЦИЯ ДЛЯ LUA ============
local sha256 = (function()
    local band, bor, bxor, bnot, rshift, lshift = bit32.band, bit32.bor, bit32.bxor, bit32.bnot, bit32.rshift, bit32.lshift

    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    }

    local function rrotate(x, n)
        return bor(rshift(x, n), lshift(x, 32 - n)) % 4294967296
    end

    local function preprocess(msg)
        local len = #msg
        local bit_len = len * 8
        msg = msg .. string.char(0x80)
        while (#msg % 64) ~= 56 do
            msg = msg .. string.char(0)
        end
        for i = 7, 0, -1 do
            msg = msg .. string.char(band(rshift(bit_len, i * 8), 0xFF))
        end
        return msg
    end

    return function(input)
        local msg = preprocess(input)
        local H = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}

        for chunkStart = 1, #msg, 64 do
            local W = {}
            for i = 0, 15 do
                local j = chunkStart + i * 4
                W[i + 1] = lshift(string.byte(msg, j), 24) + lshift(string.byte(msg, j + 1), 16)
                    + lshift(string.byte(msg, j + 2), 8) + string.byte(msg, j + 3)
            end
            for i = 17, 64 do
                local s0 = bxor(rrotate(W[i - 15], 7), rrotate(W[i - 15], 18), rshift(W[i - 15], 3))
                local s1 = bxor(rrotate(W[i - 2], 17), rrotate(W[i - 2], 19), rshift(W[i - 2], 10))
                W[i] = (W[i - 16] + s0 + W[i - 7] + s1) % 4294967296
            end
            local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
            for i = 1, 64 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e) % 4294967296, g))
                local temp1 = (h + S1 + ch + K[i] + W[i]) % 4294967296
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                local temp2 = (S0 + maj) % 4294967296
                h = g
                g = f
                f = e
                e = (d + temp1) % 4294967296
                d = c
                c = b
                b = a
                a = (temp1 + temp2) % 4294967296
            end
            H[1] = (H[1] + a) % 4294967296
            H[2] = (H[2] + b) % 4294967296
            H[3] = (H[3] + c) % 4294967296
            H[4] = (H[4] + d) % 4294967296
            H[5] = (H[5] + e) % 4294967296
            H[6] = (H[6] + f) % 4294967296
            H[7] = (H[7] + g) % 4294967296
            H[8] = (H[8] + h) % 4294967296
        end

        return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8])
    end
end)()

-- Хэшируем ключ (та же логика что в боте)
local function hashKey(key)
    local combined = HASH_SALT .. key
    local fullHash = sha256(combined)
    return string.sub(fullHash, 1, 16)  -- Первые 16 символов
end

-- ============ СЕРВЕРНАЯ ПРОВЕРКА ============
local function fetchServerKeys()
    local url = KEYS_URL .. "?t=" .. tostring(os.time())
    local ok, response = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(response) end)
    if not ok2 or not data then return nil end
    return data.keys or {}
end

local function validateKey(key)
    if not key or type(key) ~= "string" then return false, "invalid" end
    if #key < 10 or not string.find(key, "^NC%-") then return false, "invalid" end
    local keys = fetchServerKeys()
    if not keys then return false, "server_error" end

    -- 🔐 Хэшируем введённый ключ и ищем в списке хэшей
    local userHash = hashKey(key)
    local activatedTime = keys[userHash]

    if not activatedTime then return false, "invalid" end
    local elapsed = os.time() - activatedTime
    if elapsed >= KEY_LIFETIME then return false, "expired" end
    return true, activatedTime
end

local function showKeyPrompt(errorMsg)
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
    frame.Size = UDim2.new(0, 400, 0, 310)
    frame.Position = UDim2.new(0.5, -200, 0.5, -155)
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
    sub.Text = "🔒 SHA-256 encrypted"
    sub.TextSize = 13
    sub.Font = Enum.Font.Gotham
    sub.TextColor3 = Color3.fromRGB(180, 180, 180)
    sub.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -40, 0, 30)
    info.Position = UDim2.new(0, 20, 0, 85)
    info.BackgroundTransparency = 1
    info.Text = "Get key: @neverchame_bot in Telegram"
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
    status.Size = UDim2.new(1, -40, 0, 40)
    status.Position = UDim2.new(0, 20, 0, 235)
    status.BackgroundTransparency = 1
    status.Text = errorMsg or ""
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.TextWrapped = true
    status.Parent = frame

    local warn = Instance.new("TextLabel")
    warn.Size = UDim2.new(1, -40, 0, 20)
    warn.Position = UDim2.new(0, 20, 0, 280)
    warn.BackgroundTransparency = 1
    warn.Text = "🔐 Hash-protected — real keys never leaked"
    warn.TextSize = 10
    warn.Font = Enum.Font.GothamMedium
    warn.TextColor3 = Color3.fromRGB(150, 200, 255)
    warn.Parent = frame

    local result, activationTime = nil, nil
    btn.MouseButton1Click:Connect(function()
        local key = input.Text
        if key == "" then status.Text = "Enter a key first" return end
        btn.Text = "CHECKING..."
        btn.Active = false
        local ok, timeOrErr = validateKey(key)
        if ok then
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            status.Text = "✅ Verified! Loading..."
            result = key
            activationTime = timeOrErr
            task.wait(0.8)
            gui:Destroy()
        else
            btn.Text = "ACTIVATE"
            btn.Active = true
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
            if timeOrErr == "expired" then
                status.Text = "❌ Key expired! Get new one in bot"
            elseif timeOrErr == "server_error" then
                status.Text = "⚠️ GitHub unavailable. Try again"
            else
                status.Text = "❌ Invalid key or not activated in bot"
            end
        end
    end)
    while result == nil do task.wait(0.1) end
    return result, activationTime
end

local savedKey, activationTime = showKeyPrompt()
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
    if flags.espDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        text = text .. "[" .. math.floor((LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude) .. " m]\n"
    end
    if flags.espHealth then
        local h = p.Character:FindFirstChild("Humanoid")
        if h then text = text .. "HP: " .. math.floor(h.Health) end
    end
    lbl.Text = text
end
task.spawn(function()
    while true do task.wait(0.2)
        if flags.espName or flags.espDistance or flags.espHealth then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then updateESPText(p) end
            end
        else
            for _, bg in pairs(espTexts) do if bg then pcall(function() bg:Destroy() end) end end
            espTexts = {}
        end
    end
end)
table.insert(conns, RunService.Stepped:Connect(function()
    if flags.noclip and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    if flags.fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
    end
    if flags.hitboxes then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local head = p.Character:FindFirstChild("Head") or findTargetPart(p.Character)
                if head then
                    head.Size = Vector3.new(flags.hitboxSize, flags.hitboxSize, flags.hitboxSize)
                    head.Transparency = 0.6
                    head.CanCollide = false
                end
            end
        end
    end
    if flags.godMode and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
        if not LocalPlayer.Character:FindFirstChild("ncGodShield") then
            local ff = Instance.new("ForceField") ff.Name = "ncGodShield" ff.Visible = false
            ff.Parent = LocalPlayer.Character
            godForceField = ff
        end
    end
end))
table.insert(conns, UserInputService.JumpRequest:Connect(function()
    if flags.infJump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))
local function applyMovement()
    if LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then h.WalkSpeed = flags.walkSpeed h.JumpPower = flags.jumpPower h.UseJumpPower = true end
    end
end
LocalPlayer.Idled:Connect(function()
    if flags.antiAfk then
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0, 0), Camera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), Camera.CFrame)
    end
end)

local NeverLose = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/NeverLose/refs/heads/main/source.luau"))()
local Notification = NeverLose:CreateNotification()
local Logging = NeverLose:CreateLogger()
local IndicatorSys = NeverLose:CreateIndicator()

local window = NeverLose:CreateWindow({
    Name = "neverchame", Content = "Chameleon Helper v19",
    Size = NeverLose.Scales.Default, ConfigFolder = "NCConfigs",
    Enable3DRenderer = false, Keybind = "Insert"
})

local invisI = IndicatorSys.new({ Name = "INVIS", Icon = "ghost", Color = "Blue" }) invisI:SetRender(false)
local noclipI = IndicatorSys.new({ Name = "NOCLIP", Icon = "plane", Color = "Red" }) noclipI:SetRender(false)
local flyI = IndicatorSys.new({ Name = "FLY", Icon = "feather", Color = "Green" }) flyI:SetRender(false)
local aimI = IndicatorSys.new({ Name = "AIM", Icon = "crosshairs", Color = "Red" }) aimI:SetRender(false)
local godI = IndicatorSys.new({ Name = "GOD", Icon = "shield", Color = "Yellow" }) godI:SetRender(false)

local Watermark = window:Watermark()
Watermark:SetRender(true)
local b1 = Watermark:AddBlock("chart-four-vertical-bars", "0 MS")
local b2 = Watermark:AddBlock("stopwatch", "0 FPS")
local b3 = Watermark:AddBlock("cube-vertexes", "neverchame | " .. LocalPlayer.Name)

task.spawn(function()
    task.wait(1)
    pcall(function()
        local ui = CoreGui:FindFirstChild("Neverlose")
        if ui then
            for _, v in ipairs(ui:GetDescendants()) do
                if v:IsA("Frame") and string.find(string.lower(v.Name), "water") then
                    v.AnchorPoint = Vector2.new(0.5, 0)
                    v.Position = UDim2.new(0.5, 0, 0, 10)
                end
            end
        end
    end)
end)

task.spawn(function()
    task.wait(1.5)
    local targets = {}
    local function scanUI()
        local ui = CoreGui:FindFirstChild("Neverlose")
        if not ui then return end
        for _, obj in ipairs(ui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
                if obj.Text == "Never" and not targets[obj] then
                    targets[obj] = true
                end
            end
        end
    end
    for i = 1, 5 do scanUI() task.wait(0.3) end
    while true do
        scanUI()
        local remaining = KEY_LIFETIME - (os.time() - activationTime)
        local timeText
        if remaining <= 0 then
            timeText = "EXPIRED"
        else
            local h = math.floor(remaining / 3600)
            local m = math.floor((remaining % 3600) / 60)
            local s = remaining % 60
            if h > 0 then timeText = string.format("%dh %dm left", h, m)
            elseif m > 0 then timeText = string.format("%dm %ds left", m, s)
            else timeText = string.format("%ds left", s) end
        end
        local color
        if remaining < 600 then color = Color3.fromRGB(255, 80, 80)
        elseif remaining < 3600 then color = Color3.fromRGB(255, 200, 100)
        else color = Color3.fromRGB(150, 200, 255) end
        for obj in pairs(targets) do
            if obj and obj.Parent then
                pcall(function() obj.Text = timeText obj.TextColor3 = color end)
            else targets[obj] = nil end
        end
        task.wait(1)
    end
end)

local frameCount, fps = 0, 0
table.insert(conns, RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end))
task.spawn(function()
    while task.wait(1) do
        fps = frameCount frameCount = 0
        pcall(function()
            if wmSettings.Ping then b1:SetText(math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " MS") b1:SetRender(true) else b1:SetRender(false) end
            if wmSettings.FPS then b2:SetText(fps .. " FPS") b2:SetRender(true) else b2:SetRender(false) end
            if wmSettings.Custom then b3:SetText(wmSettings.CustomText) b3:SetRender(true)
            elseif wmSettings.User then b3:SetText("neverchame | " .. LocalPlayer.Name) b3:SetRender(true)
            else b3:SetRender(false) end
        end)
    end
end)

local timerGui = Instance.new("ScreenGui")
timerGui.Name = "ncKeyTimer" timerGui.ResetOnSpawn = false
timerGui.IgnoreGuiInset = true timerGui.DisplayOrder = 999
pcall(function() timerGui.Parent = CoreGui end)
local timerFrame = Instance.new("Frame")
timerFrame.Size = UDim2.new(0, 180, 0, 55)
timerFrame.Position = UDim2.new(0, 15, 1, -70)
timerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
timerFrame.BackgroundTransparency = 0.15
timerFrame.BorderSizePixel = 0
timerFrame.Parent = timerGui
Instance.new("UICorner", timerFrame).CornerRadius = UDim.new(0, 6)
local tstroke = Instance.new("UIStroke", timerFrame)
tstroke.Color = Color3.fromRGB(100, 150, 255) tstroke.Thickness = 1.5 tstroke.Transparency = 0.4
local tbar = Instance.new("Frame")
tbar.Size = UDim2.new(0, 3, 1, 0) tbar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
tbar.BorderSizePixel = 0 tbar.Parent = timerFrame
Instance.new("UICorner", tbar).CornerRadius = UDim.new(0, 6)
local timerTitle = Instance.new("TextLabel")
timerTitle.Size = UDim2.new(1, -15, 0, 20) timerTitle.Position = UDim2.new(0, 12, 0, 5)
timerTitle.BackgroundTransparency = 1 timerTitle.Text = "KEY EXPIRES IN"
timerTitle.TextSize = 10 timerTitle.Font = Enum.Font.GothamBold
timerTitle.TextColor3 = Color3.fromRGB(150, 180, 255)
timerTitle.TextXAlignment = Enum.TextXAlignment.Left timerTitle.Parent = timerFrame
local timerLbl = Instance.new("TextLabel")
timerLbl.Size = UDim2.new(1, -15, 0, 25) timerLbl.Position = UDim2.new(0, 12, 0, 25)
timerLbl.BackgroundTransparency = 1 timerLbl.Text = "23:59:59"
timerLbl.TextSize = 18 timerLbl.Font = Enum.Font.GothamBold
timerLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLbl.TextXAlignment = Enum.TextXAlignment.Left timerLbl.Parent = timerFrame
task.spawn(function()
    while true do task.wait(1)
        local elapsed = os.time() - activationTime
        local remaining = KEY_LIFETIME - elapsed
        if remaining <= 0 then
            timerLbl.Text = "EXPIRED"
            timerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            break
        end
        local h = math.floor(remaining / 3600)
        local m = math.floor((remaining % 3600) / 60)
        local s = remaining % 60
        timerLbl.Text = string.format("%02d:%02d:%02d", h, m, s)
        if remaining < 3600 then
            timerLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
            tstroke.Color = Color3.fromRGB(255, 200, 100)
            tbar.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
        end
        if remaining < 600 then
            timerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
            tstroke.Color = Color3.fromRGB(255, 80, 80)
            tbar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        end
    end
end)

window:AddTabLabel("COMBAT")
local CombatTab = window:AddTab({ Icon = "crosshairs", Name = "Combat" })
local AimSec = CombatTab:AddSection({ Name = "AIMBOT", Position = "left" })
local HitSec = CombatTab:AddSection({ Name = "HITBOX", Position = "right" })
local GodSec = CombatTab:AddSection({ Name = "SURVIVAL", Position = "left" })
AimSec:AddLabel("Aimbot"):AddToggle({ Default = false, Callback = function(v) flags.aimbot = v aimI:SetRender(v) end })
AimSec:AddLabel("FOV"):AddSlider({ Min = 20, Max = 500, Rounding = 1, Default = 100, Type = " px", Callback = function(v) flags.aimbotFov = v end })
AimSec:AddLabel("Aim Key"):AddDropdown({ Default = "MouseButton2", Values = {"MouseButton1", "MouseButton2"}, Callback = function(v) flags.aimbotKey = v end })
HitSec:AddLabel("Hitboxes"):AddToggle({ Default = false, Callback = function(v) flags.hitboxes = v end })
HitSec:AddLabel("Size"):AddSlider({ Min = 2, Max = 20, Rounding = 1, Default = 5, Type = " Studs", Callback = function(v) flags.hitboxSize = v end })
GodSec:AddLabel("GOD MODE"):AddToggle({ Default = false, Callback = function(v) flags.godMode = v godI:SetRender(v) toggleGodMode(v) end })

window:AddTabLabel("VISUALS")
local VisTab = window:AddTab({ Icon = "eye", Name = "Visuals" })
local EspSec = VisTab:AddSection({ Name = "ESP", Position = "left" })
local WorldSec = VisTab:AddSection({ Name = "WORLD", Position = "right" })
EspSec:AddLabel("Player ESP"):AddToggle({ Default = false, Callback = function(v)
    flags.esp = v
    if v then for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
    else for _, hl in pairs(highlights) do if hl then pcall(function() hl:Destroy() end) end end highlights = {} end
end })
EspSec:AddLabel("Names"):AddToggle({ Default = false, Callback = function(v) flags.espName = v end })
EspSec:AddLabel("Distance"):AddToggle({ Default = false, Callback = function(v) flags.espDistance = v end })
EspSec:AddLabel("Health"):AddToggle({ Default = false, Callback = function(v) flags.espHealth = v end })
EspSec:AddLabel("Reveal Hidden"):AddToggle({ Default = false, Callback = function(v) flags.reveal = v if v then task.spawn(revealLoop) end end })
WorldSec:AddLabel("Fullbright"):AddToggle({ Default = false, Callback = function(v) flags.fullbright = v end })
WorldSec:AddLabel("Third Person"):AddToggle({ Default = false, Callback = function(v)
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    if v then LocalPlayer.CameraMaxZoomDistance = 15 LocalPlayer.CameraMinZoomDistance = 15
    else LocalPlayer.CameraMaxZoomDistance = 400 LocalPlayer.CameraMinZoomDistance = 0.5 end
end })
WorldSec:AddLabel("Remove Fog"):AddToggle({ Default = false, Callback = function(v) if v then Lighting.FogEnd = 100000 else Lighting.FogEnd = 1000 end end })

window:AddTabLabel("MOVEMENT")
local MoveTab = window:AddTab({ Icon = "person-running", Name = "Movement" })
local SpeedSec = MoveTab:AddSection({ Name = "SPEED", Position = "left" })
local StealthSec = MoveTab:AddSection({ Name = "STEALTH", Position = "right" })
SpeedSec:AddLabel("WalkSpeed"):AddSlider({ Min = 16, Max = 300, Rounding = 1, Default = 16, Type = "", Callback = function(v) flags.walkSpeed = v applyMovement() end })
SpeedSec:AddLabel("JumpPower"):AddSlider({ Min = 50, Max = 500, Rounding = 1, Default = 50, Type = "", Callback = function(v) flags.jumpPower = v applyMovement() end })
SpeedSec:AddLabel("Inf Jump"):AddToggle({ Default = false, Callback = function(v) flags.infJump = v end })
SpeedSec:AddLabel("NoClip"):AddToggle({ Default = false, Callback = function(v) flags.noclip = v noclipI:SetRender(v) end })
SpeedSec:AddLabel("Fly"):AddToggle({ Default = false, Callback = function(v) flags.fly = v toggleFly(v) flyI:SetRender(v) end })
SpeedSec:AddLabel("Fly Speed"):AddSlider({ Min = 10, Max = 300, Rounding = 1, Default = 50, Type = "", Callback = function(v) flags.flySpeed = v end })
StealthSec:AddLabel("REAL Invis"):AddToggle({ Default = false, Callback = function(v) flags.realInvis = v realInvisible(v) invisI:SetRender(v) end })
StealthSec:AddLabel("Visual Invis"):AddToggle({ Default = false, Callback = function(v) flags.invisible = v if v then task.spawn(invisibleLoop) end end })
StealthSec:AddLabel("Ant-Man"):AddToggle({ Default = false, Callback = function(v) flags.tiny = v if LocalPlayer.Character then makeTiny(LocalPlayer.Character, v) end end })

window:AddTabLabel("TELEPORT")
local TpTab = window:AddTab({ Icon = "location-arrow", Name = "Teleport" })
local PSec = TpTab:AddSection({ Name = "TO PLAYER", Position = "left" })
local SSec = TpTab:AddSection({ Name = "SAVED SPOTS", Position = "right" })
local selPlayer = nil
local function getNames()
    local n = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(n, p.Name) end end
    if #n == 0 then table.insert(n, "None") end
    return n
end
local pDrop = PSec:AddLabel("Player"):AddDropdown({ Default = "None", Values = getNames(), Callback = function(v) selPlayer = v end })
PSec:AddButton({ Icon = "rotate", Name = "Refresh", Callback = function()
    local list = getNames()
    pcall(function() pDrop:SetValues(list) end)
    pcall(function() pDrop:SetOptions(list) end)
end })
PSec:AddButton({ Icon = "location-arrow", Name = "Teleport", Callback = function()
    if not selPlayer or selPlayer == "None" then return end
    local t = Players:FindFirstChild(selPlayer)
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    end
end })
local spotName = "spot1"
SSec:AddLabel("Spot Name"):AddTextbox({ Default = "spot1", Callback = function(v) spotName = v end })
SSec:AddButton({ Icon = "bookmark", Name = "Save", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local p = LocalPlayer.Character.HumanoidRootPart.Position
        savedSpots[spotName] = { X = p.X, Y = p.Y, Z = p.Z }
    end
end })
SSec:AddButton({ Icon = "location-arrow", Name = "TP", Callback = function()
    local s = savedSpots[spotName]
    if s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(s.X, s.Y, s.Z)
    end
end })
SSec:AddButton({ Icon = "trash", Name = "Delete", Callback = function() savedSpots[spotName] = nil end })

window:AddTabLabel("UTILITY")
local UtilTab = window:AddTab({ Icon = "wrench", Name = "Utility" })
local USec = UtilTab:AddSection({ Name = "MISC", Position = "left" })
local SrvSec = UtilTab:AddSection({ Name = "SERVER", Position = "right" })
USec:AddLabel("Anti-AFK"):AddToggle({ Default = true, Callback = function(v) flags.antiAfk = v end })
USec:AddButton({ Icon = "arrows-rotate", Name = "Reset Character", Callback = function()
    if LocalPlayer.Character then local h = LocalPlayer.Character:FindFirstChild("Humanoid") if h then h.Health = 0 end end
end })
SrvSec:AddButton({ Icon = "right-from-bracket", Name = "Rejoin", Callback = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end })
SrvSec:AddButton({ Icon = "shuffle", Name = "Server Hop", Callback = function()
    pcall(function()
        local ts = game:GetService("TeleportService")
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                ts:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) return
            end
        end
    end)
end })

window:AddTabLabel("CONFIG")
local CfgTab = window:AddTab({ Icon = "floppy-disk", Name = "Configs" })
local CfgSec = CfgTab:AddSection({ Name = "SAVE/LOAD", Position = "left" })
local WmSec = CfgTab:AddSection({ Name = "WATERMARK", Position = "right" })
local curCfg = "default"
local cfgDrop = nil
local function refreshCfg()
    local list = getConfigList()
    if #list == 0 then table.insert(list, "default") end
    if cfgDrop then
        pcall(function() cfgDrop:SetValues(list) end)
        pcall(function() cfgDrop:SetOptions(list) end)
    end
end
CfgSec:AddLabel("Name"):AddTextbox({ Default = "default", Callback = function(v) if v ~= "" then curCfg = v end end })
local il = getConfigList() if #il == 0 then table.insert(il, "default") end
cfgDrop = CfgSec:AddLabel("List"):AddDropdown({ Default = il[1], Values = il, Callback = function(v) if v then curCfg = v end end })
CfgSec:AddButton({ Icon = "floppy-disk", Name = "Save", Callback = function()
    local ok = saveConfig(curCfg)
    Logging.new(ok and "check" or "xmark", ok and ("Saved: " .. curCfg) or "Failed", 4)
    refreshCfg()
end })
CfgSec:AddButton({ Icon = "folder-open", Name = "Load", Callback = function()
    local ok = loadConfig(curCfg)
    Logging.new(ok and "check" or "xmark", ok and ("Loaded: " .. curCfg) or "Failed", 4)
end })
CfgSec:AddButton({ Icon = "trash", Name = "Delete", Callback = function() deleteConfig(curCfg) refreshCfg() end })
CfgSec:AddButton({ Icon = "rotate", Name = "Refresh", Callback = refreshCfg })
WmSec:AddLabel("Show WM"):AddToggle({ Default = true, Callback = function(v) wmSettings.Show = v Watermark:SetRender(v) end })
WmSec:AddLabel("Ping"):AddToggle({ Default = true, Callback = function(v) wmSettings.Ping = v end })
WmSec:AddLabel("FPS"):AddToggle({ Default = true, Callback = function(v) wmSettings.FPS = v end })
WmSec:AddLabel("Username"):AddToggle({ Default = true, Callback = function(v) wmSettings.User = v end })
WmSec:AddLabel("Custom"):AddToggle({ Default = false, Callback = function(v) wmSettings.Custom = v end })
WmSec:AddLabel("Text"):AddTextbox({ Default = "neverchame.cc", Callback = function(v) if v ~= "" then wmSettings.CustomText = v end end })

window:AddTabLabel("SETTINGS")
local SetTab = window:AddTab({ Icon = "gear", Name = "Settings" })
local UISec = SetTab:AddSection({ Name = "UI", Position = "left" })
local UnSec = SetTab:AddSection({ Name = "SCRIPT", Position = "right" })
local KeySec = SetTab:AddSection({ Name = "LICENSE", Position = "left" })
UISec:AddLabel("Key"):AddKeybind({ Default = "Insert", Callback = function(v) window.Keybind = v end })
UISec:AddLabel("Size"):AddDropdown({ Default = "Default", Values = {"Small", "Default", "Large", "Mobile"}, Callback = function(v) pcall(function() window:SetSize(NeverLose.Scales[v]) end) end })
KeySec:AddLabel("Key: " .. string.sub(savedKey, 1, 8) .. "***")
KeySec:AddLabel("🔒 SHA-256 protected")

local function fullUnload()
    for k, val in pairs(flags) do if type(val) == "boolean" then flags[k] = false end end
    toggleGodMode(false)
    pcall(function()
        if LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16 h.JumpPower = 50 h.MaxHealth = 100 h.Health = 100 end
            makeTiny(LocalPlayer.Character, false)
            realInvisible(false)
        end
    end)
    pcall(function() if flyBv then flyBv:Destroy() end if flyBg then flyBg:Destroy() end if flyConn then flyConn:Disconnect() end end)
    pcall(function() Lighting.Ambient = Color3.fromRGB(0, 0, 0) Lighting.FogEnd = 1000 end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    removeAllHighlights()
    pcall(function() Watermark:SetRender(false) invisI:SetRender(false) noclipI:SetRender(false) flyI:SetRender(false) aimI:SetRender(false) godI:SetRender(false) end)
    pcall(function() timerGui:Destroy() end)
    task.wait(0.2)
    pcall(function() for _, gui in ipairs(CoreGui:GetChildren()) do local nm = string.lower(gui.Name) if string.find(nm, "neverlose") or string.find(nm, "neverchame") or string.find(nm, "nckeytimer") then gui:Destroy() end end end)
end
UnSec:AddButton({ Icon = "power-off", Name = "Unload", Callback = fullUnload })
UnSec:AddButton({ Icon = "triangle-exclamation", Name = "Force Kill", Callback = function()
    pcall(function() for _, gui in ipairs(CoreGui:GetChildren()) do if string.find(string.lower(gui.Name), "neverlose") then gui:Destroy() end end end)
end })

table.insert(conns, LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if flags.tiny then makeTiny(char, true) end
    applyMovement()
    if flags.realInvis then task.wait(0.5) realInvisible(true) end
    if flags.godMode then task.wait(0.5) toggleGodMode(true) end
end))
table.insert(conns, Players.PlayerAdded:Connect(function(p) if flags.esp then applyESP(p) end end))
table.insert(conns, Players.PlayerRemoving:Connect(function(p) highlights[p] = nil revealHighlights[p] = nil espTexts[p] = nil end))

pcall(function() loadConfig("default") end)
Notification.new({ Title = "neverchame v19", Content = "🔐 Hash-protected. Press Insert.", Duration = 6 })
Logging.new("check", "neverchame v19 loaded", 5)
