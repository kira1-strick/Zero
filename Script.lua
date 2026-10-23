--[[
  FLOW HUB - COMMAND AN ARMY (FINAL ANTI-NIL)
============================================================
]]

-- 1. CLEANUP (ANTI DOUBLE GUI)
local CoreGui = game:GetService("CoreGui")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
for _, parent in pairs({CoreGui, PlayerGui}) do
    local old = parent:FindFirstChild("FlowHub")
    if old then old:Destroy() end
end

if _G.FlowHubConnections then
    for _, conn in pairs(_G.FlowHubConnections) do
        pcall(function() conn:Disconnect() end)
    end
    _G.FlowHubConnections = nil
end

-- 2. SETUP GLOBAL (PASTIIN GA NIL)
if not _G.STHAIN then _G.STHAIN = {} end
if not _G.STHAIN.Modules then _G.STHAIN.Modules = {} end

-- 3. SETUP CONFIG
local Config = {
    ConfigVersion = 2,
    Combat = { AutoAttack = false, AutoRush = false, AutoFollow = false, KillAura = false, TargetLock = false, AutoHeal = false, AntiStun = false, AttackDelay = 0.35, RushDelay = 0.5, FollowDelay = 0.35, KillAuraRange = 20, HealThreshold = 30 },
    Spawn = { UnitSlot = 1, AutoSpawn = false },
    Visual = { Chams = false, ESPSupply = false, ESPCapture = false, ESPShowDistance = false, ESPHealth = false, ESPName = false, Fullbright = false, NoFog = false },
    Teleport = { OffsetY = 5, EnemySupplyTarget = "AttackerSupply1", OwnerSupplyTarget = "DefenderSupply1" },
    Movement = { WalkSpeed = 16, EnableRunSpeed = false, Noclip = false, Fly = false, InfJump = false, FlySpeed = 60, JumpPower = 50 },
    Misc = { AutoJoinTeam = "none", AntiAFK = true },
    Config = { AutoSave = true },
}
_G.STHAIN.Config = Config

-- 4. FETCH GUI (DENGAN PROTEKSI _G.STHAIN)
local BASE_GUI = "https://raw.githubusercontent.com/Kira-128/Flow-GUI/main/src/"
local GuiModules = {"1_services", "3_theme", "4_utils", "5_gui", "6_components", "7_pages"}

for _, mod in ipairs(GuiModules) do
    local ok, src = pcall(game.HttpGet, game, BASE_GUI .. mod .. ".lua")
    if ok and src and #src > 0 then
        local fn = loadstring(src, "@" .. mod .. ".lua")
        if fn then pcall(fn) end
    end
    task.wait(0.1)
end

-- 5. PASTIIN _G.STHAIN GA KE-RESET SAMA GUI
if not _G.STHAIN then _G.STHAIN = {} end
if not _G.STHAIN.Config then _G.STHAIN.Config = Config end
if not _G.STHAIN.Modules then _G.STHAIN.Modules = {} end

-- 6. JEDA BENTAR
task.wait(0.5)

-- 7. LOAD CONFIG DARI FILE
if readfile and isfile then
    local CONFIG_FOLDER = "FlowHub_Configs"
    local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(readfile, CONFIG_FILE)
        if ok and data and #data > 0 then
            local Http = game:GetService("HttpService")
            local ok2, decoded = pcall(function() return Http:JSONDecode(data) end)
            if ok2 and type(decoded) == "table" then
                local savedVersion = decoded.ConfigVersion or 1
                if savedVersion < Config.ConfigVersion then
                    pcall(function() delfile(CONFIG_FILE) end)
                else
                    for category, values in pairs(decoded) do
                        if _G.STHAIN.Config[category] then
                            for key, val in pairs(values) do
                                _G.STHAIN.Config[category][key] = val
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 8. LOAD LOGIC (KODE PANJANG LU)
local S = _G.STHAIN
if not S then return end
local Utils = S.Utils
local Run = S.Services.Run
local Lighting = S.Services.Lighting
local Cam = S.Cam
local LP = S.LP
local VIM = S.Services.VIM
local VU = S.Services.VU
local UIS = S.Services.UIS
local Players = S.Services.Players
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:FindFirstChild("Shared")
local Remotes = Shared and Shared:FindFirstChild("Remotes")
local TroopStateRequest = Remotes and Remotes:FindFirstChild("TroopStateRequest")
local RushRequest = Remotes and Remotes:FindFirstChild("RushRequest")
local RespawnUnitRequest = Remotes and Remotes:FindFirstChild("RespawnUnitRequest")

local State = { Fly = false, Noclip = false, Invisible = false, Fullbright = false, NoFog = false, ESP = false, TargetLock = false }
_G.FlowHubConnections = _G.FlowHubConnections or {}
local function addConn(conn) table.insert(_G.FlowHubConnections, conn) return conn end
local function getChar() return LP.Character end
local function getHRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end

local function sendKey(keyCode, hold)
    if S.IsMobile then return false end
    local delay = hold or 0.05
    if keypress and keyrelease then
        local keyStr = keyCode.Name:lower()
        local ok = pcall(function() keypress(keyStr) task.wait(delay) keyrelease(keyStr) end)
        if ok then return true end
    end
    if VIM then
        local ok = pcall(function() VIM:SendKeyEvent(true, keyCode, false, game) task.wait(delay) VIM:SendKeyEvent(false, keyCode, false, game) end)
        if ok then return true end
    end
    return false
end

task.spawn(function() repeat task.wait(0.1) until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") end)

addConn(Run.RenderStepped:Connect(function()
    local hum = getHum()
    if not hum then return end
    local mv = Config.Movement
    if mv.EnableRunSpeed then
        if mv.WalkSpeed and mv.WalkSpeed > 0 and hum.WalkSpeed ~= mv.WalkSpeed then hum.WalkSpeed = mv.WalkSpeed end
    else
        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
    end
    if mv.JumpPower and mv.JumpPower > 0 then
        hum.UseJumpPower = true
        if hum.JumpPower ~= mv.JumpPower then hum.JumpPower = mv.JumpPower end
    end
end))

local noclipOriginal = {}
local function cleanupNoclip()
    for part, orig in pairs(noclipOriginal) do if part and part.Parent then pcall(function() part.CanCollide = orig end) end end
    noclipOriginal = {}
end

addConn(Run.Heartbeat:Connect(function()
    if not Config.Movement.Noclip then if State.Noclip then cleanupNoclip() State.Noclip = false end return end
    local char = getChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipOriginal[part] == nil then noclipOriginal[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
    State.Noclip = true
end))

local flyConn, flyBV, flyBG = nil, nil, nil
local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hrp = getHRP()
    if hrp then hrp.Velocity = Vector3.zero hrp.RotVelocity = Vector3.zero hrp.CanCollide = true end
    local hum = getHum()
    if hum then pcall(function() hum.PlatformStand = false end) end
end

local function startFly()
    stopFly()
    local hrp, hum = getHRP(), getHum()
    if not (hrp and hum) then return end
    hum.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 10000
    flyBG.D = 100
    flyBG.Parent = hrp
    flyConn = Run.RenderStepped:Connect(function()
        if not Config.Movement.Fly then return end
        local h, hm = getHRP(), getHum()
        if not (h and hm and flyBV and flyBG) then return end
        flyBG.CFrame = Cam.CFrame
        local d = hm.MoveDirection
        local f = Vector3.zero
        if d.Magnitude > 0.1 then f = Cam.CFrame.LookVector * d.Z + Cam.CFrame.RightVector * d.X end
        flyBV.Velocity = f * Config.Movement.FlySpeed
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        if Config.Movement.Fly and not State.Fly then startFly() State.Fly = true
        elseif not Config.Movement.Fly and State.Fly then stopFly() State.Fly = false end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if Config.Movement.InfJump then
            local hum = getHum()
            if hum then
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.Combat.AntiStun then
            local hum = getHum()
            if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end) end
        end
    end
end)

local atkTimer, rushTimer, followTimer = 0, 0, 0
task.spawn(function()
    while task.wait(0.15) do
        local anyActive = Config.Combat.AutoAttack or Config.Combat.AutoRush or Config.Combat.AutoFollow
        if not anyActive then continue end
        local now = tick()
        if Config.Combat.AutoAttack and now - atkTimer >= Config.Combat.AttackDelay then
            atkTimer = now
            if TroopStateRequest then pcall(function() TroopStateRequest:FireServer("Attack") end) end
        end
        if Config.Combat.AutoRush and now - rushTimer >= Config.Combat.RushDelay then
            rushTimer = now
            if RushRequest then pcall(function() RushRequest:FireServer() end) end
        end
        if Config.Combat.AutoFollow and now - followTimer >= Config.Combat.FollowDelay then
            followTimer = now
            if TroopStateRequest then pcall(function() TroopStateRequest:FireServer("Follow") end) end
        end
    end
end)

local killAuraCD = 0
task.spawn(function()
    while task.wait(0.5) do
        if Config.Combat.KillAura then
            local char, hrp = getChar(), getHRP()
            if char and hrp then
                local nearest, nearestDist = nil, Config.Combat.KillAuraRange
                for _, model in pairs(workspace:GetChildren()) do
                    if model == char or not model:IsA("Model") then continue end
                    local mhum = model:FindFirstChildOfClass("Humanoid")
                    if not mhum or mhum.Health <= 0 then continue end
                    local thrp = model:FindFirstChild("HumanoidRootPart")
                    if not thrp then continue end
                    local dist = (thrp.Position - hrp.Position).Magnitude
                    if dist > 5 and dist < nearestDist then nearest = thrp nearestDist = dist end
                end
                if nearest and tick() - killAuraCD >= 0.5 then
                    killAuraCD = tick()
                    if TroopStateRequest then pcall(function() TroopStateRequest:FireServer("Attack") end) end
                end
            end
        end
    end
end)

local healCD = 0
task.spawn(function()
    while task.wait(0.5) do
        if Config.Combat.AutoHeal then
            local hum = getHum()
            if hum and hum.Health > 0 then
                local pct = (hum.Health / hum.MaxHealth) * 100
                if pct <= Config.Combat.HealThreshold and tick() - healCD >= 2.5 then
                    healCD = tick()
                    sendKey(Enum.KeyCode.H, 0.05)
                end
            end
        end
    end
end)

local aimLock, aimLostAt, aimSmoothCF = nil, 0, nil
local function aimAlive(p) if not p.Character then return false end local hum = p.Character:FindFirstChildOfClass("Humanoid") if not hum or hum.Health <= 0 then return false end return p.Character:FindFirstChild("Head") ~= nil end
local function aimValid(p) if not p or not aimAlive(p) then return false end if p.Team == LP.Team and p.Team ~= nil then return false end local part = p.Character:FindFirstChild("Head") if not part then return false end if (part.Position - Cam.CFrame.Position).Magnitude > 500 then return false end return true end

local function aimClosest()
    local best, bd = nil, math.huge
    local ctr = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local list = Players:GetPlayers()
    for i = 1, #list do
        local p = list[i]
        if p ~= LP and aimValid(p) then
            local part = p.Character:FindFirstChild("Head")
            if part then
                local sp, on = Cam:WorldToViewportPoint(part.Position)
                if on then
                    local dx, dy = sp.X - ctr.X, sp.Y - ctr.Y
                    local m = math.sqrt(dx*dx + dy*dy)
                    if m < 300 and m < bd then best = p bd = m end
                end
            end
        end
    end
    return best
end

local function aimPredict(part) local v = part.AssemblyLinearVelocity or Vector3.new() return part.Position + (v * 0.18) end

addConn(Run.RenderStepped:Connect(function(dt)
    if not Config.Combat.TargetLock then
        if State.TargetLock then aimLock = nil aimSmoothCF = nil State.TargetLock = false end
        return
    end
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    if not aimSmoothCF then aimSmoothCF = Cam.CFrame end
    if aimLock then if not aimValid(aimLock) then aimLock = nil aimLostAt = tick() end end
    if not aimLock and (tick() - aimLostAt) >= 0.5 then local t = aimClosest() if t then aimLock = t end end
    if not aimLock then return end
    local part = aimLock.Character and aimLock.Character:FindFirstChild("Head")
    if not part then return end
    local target = CFrame.lookAt(Cam.CFrame.Position, aimPredict(part))
    local a = 1 - math.pow(0.15, dt * 60)
    a = math.clamp(a, 0, 1)
    aimSmoothCF = aimSmoothCF:Lerp(target, a)
    Cam.CFrame = aimSmoothCF
    State.TargetLock = true
end))

local espCache = {}
local espGuiParent = (gethui and gethui()) or game:GetService("CoreGui")
local COLOR_ENEMY = Color3.fromRGB(255, 60, 60)
local COLOR_TEAM = Color3.fromRGB(74, 158, 255)

local function isTeammate(model)
    local plr = game.Players:GetPlayerFromCharacter(model)
    if not plr then return false end
    local myTeam = LP:GetAttribute("SelectedTeam") or (LP.Team and LP.Team.Name)
    local theirTeam = plr:GetAttribute("SelectedTeam") or (plr.Team and plr.Team.Name)
    if myTeam and theirTeam then return myTeam == theirTeam end
    return false
end

local function cleanupESP()
    for _, objs in pairs(espCache) do
        for _, obj in pairs(objs) do if obj and typeof(obj) == "Instance" then pcall(function() obj:Destroy() end) end end
    end
    espCache = {}
end

task.spawn(function()
    while task.wait(0.5) do
        if not Config.Visual.Chams then if next(espCache) then cleanupESP() end continue end
        local myChar, myHRP = getChar(), getHRP()
        local anySetting = Config.Visual.ESPShowDistance or Config.Visual.ESPHealth or Config.Visual.ESPName
        for _, model in pairs(workspace:GetChildren()) do
            if model == myChar or not model:IsA("Model") then continue end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            local isTeam = isTeammate(model)
            local markerColor = isTeam and COLOR_TEAM or COLOR_ENEMY
            if not espCache[model] then
                espCache[model] = { isTeam = isTeam }
                local hl = Instance.new("Highlight")
                hl.FillColor = markerColor
                hl.OutlineColor = Color3.new(1,1,1)
                hl.FillTransparency = 0.5
                hl.Adornee = model
                hl.Parent = espGuiParent
                espCache[model].hl = hl
            end
            if anySetting and not espCache[model].infoBB then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 200, 0, 24)
                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = hrp
                bb.Parent = espGuiParent
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.TextColor3 = markerColor
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.new(0,0,0)
                lbl.TextSize = 13
                lbl.Font = Enum.Font.GothamBold
                lbl.BackgroundTransparency = 1
                lbl.Parent = bb
                espCache[model].infoBB = bb
                espCache[model].infoLbl = lbl
            end
            if espCache[model].infoLbl and myHRP then
                local parts = {}
                if Config.Visual.ESPName then table.insert(parts, model.Name) end
                if Config.Visual.ESPHealth then table.insert(parts, "[ "..math.floor(hum.Health).." HP ]") end
                if Config.Visual.ESPShowDistance then table.insert(parts, "[ "..math.floor((hrp.Position - myHRP.Position).Magnitude).." M ]") end
                espCache[model].infoLbl.Text = table.concat(parts, " ")
                espCache[model].infoLbl.TextColor3 = markerColor
            end
        end
        for model, objs in pairs(espCache) do
            if not model.Parent then
                for _, obj in pairs(objs) do if obj and typeof(obj) == "Instance" then pcall(function() obj:Destroy() end) end end
                espCache[model] = nil
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.Visual.Fullbright then Lighting.Brightness = 3 Lighting.Ambient = Color3.fromRGB(200, 200, 200) Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200) end
        if Config.Visual.NoFog then Lighting.FogEnd = 100000 Lighting.FogStart = 100000 end
    end
end)

task.spawn(function()
    while task.wait(120) do
        if Config.Misc.AntiAFK then pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end) end
    end
end)

function _G.STHAIN.SpawnUnit(slot)
    local PG = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not PG then return false end
    local spawnBtn = nil
    for _, v in pairs(PG:GetDescendants()) do
        if (v:IsA("ImageButton") or v:IsA("TextButton")) and v.Name == "Spawn" and v.Visible then spawnBtn = v break end
    end
    if spawnBtn then pcall(function() if firesignal then firesignal(spawnBtn.MouseButton1Click) else spawnBtn:Activate() end end) return true end
    if RespawnUnitRequest then pcall(function() RespawnUnitRequest:FireServer(tonumber(slot) or 1) end) return true end
    return false
end

task.spawn(function()
    while task.wait(3) do
        if Config.Spawn.AutoSpawn then if _G.STHAIN.SpawnUnit then _G.STHAIN.SpawnUnit(Config.Spawn.UnitSlot or 1) end end
    end
end)

local teamAttempts = 0
task.spawn(function()
    while task.wait(1) do
        local team = Config.Misc.AutoJoinTeam
        if team and team ~= "none" then
            local targetName = (team == "defender") and "Defenders" or "Attackers"
            if LP.Team and LP.Team.Name == targetName then Config.Misc.AutoJoinTeam = "none" else
                local TeamRequest = Remotes and Remotes:FindFirstChild("TeamRequest")
                if TeamRequest then pcall(function() TeamRequest:FireServer(targetName) end) end
                teamAttempts = teamAttempts + 1
                if teamAttempts > 10 then Config.Misc.AutoJoinTeam = "none" end
            end
        else teamAttempts = 0 end
    end
end)

function _G.STHAIN.ClaimQuests()
    local PG = LP:FindFirstChild("PlayerGui")
    if not PG then return 0 end
    local hud = PG:FindFirstChild("HUD")
    if hud then local rightBar = hud:FindFirstChild("RightBar") if rightBar then local questBtn = rightBar:FindFirstChild("Quest") if questBtn then pcall(function() if firesignal then firesignal(questBtn.MouseButton1Click) else questBtn:Activate() end end) task.wait(1) end end end
    local interactable = PG:FindFirstChild("Interactable")
    local questUI = interactable and interactable:FindFirstChild("QuestUI")
    if not questUI then return 0 end
    local claimed = 0
    local function processTab(tabName)
        local tabBtn = questUI:FindFirstChild(tabName)
        if tabBtn then pcall(function() if firesignal then firesignal(tabBtn.MouseButton1Click) else tabBtn:Activate() end end) task.wait(1) end
        for _, c in pairs(questUI:GetDescendants()) do
            if (c:IsA("ImageButton") or c:IsA("TextButton")) and c.Name == "Claim" then
                if c.Visible then local ok = pcall(function() if firesignal then firesignal(c.MouseButton1Click) else c:Activate() end end) if ok then claimed = claimed + 1 task.wait(0.3) end end
            end
        end
    end
    processTab("DailyQuests") processTab("WeeklyQuests")
    task.wait(0.3)
    local exitBtn = questUI:FindFirstChild("Exit")
    if exitBtn then pcall(function() if firesignal then firesignal(exitBtn.MouseButton1Click) else exitBtn:Activate() end end) end
    return claimed
end

local function ambilCode()
    local url = "https://www.radiotimes.com/technology/gaming/command-an-army-codes/"
    local ok, html = pcall(game.HttpGet, game, url)
    if not ok or not html or #html < 500 then return {} end
    local startPos = html:find("Active codes")
    local endPos = html:find("expired codes")
    if not startPos then return {} end
    local section = html:sub(startPos, endPos or #html)
    local codes = {}
    local seen = {}
    for li in section:gmatch("<li[^>]*>(.-)</li>") do
        local code = li:match("<strong>([A-Z][A-Z0-9]+)</strong>") or li:match("^%s*([A-Z][A-Z0-9]+)")
        if code and #code >= 3 and #code <= 20 and not seen[code] then seen[code] = true table.insert(codes, code) end
    end
    return codes
end

function _G.STHAIN.RedeemAllCodes()
    local codes = ambilCode()
    if #codes == 0 then return 0 end
    local PG = LP:FindFirstChild("PlayerGui")
    if PG then local hud = PG:FindFirstChild("HUD") if hud then local rightBar = hud:FindFirstChild("RightBar") if rightBar then local codeBtn = rightBar:FindFirstChild("Code") if codeBtn and codeBtn.Visible then pcall(function() if firesignal then firesignal(codeBtn.MouseButton1Click) else codeBtn:Activate() end end) task.wait(1) end end end end
    local interactable = PG and PG:FindFirstChild("Interactable")
    local codeUI = interactable and interactable:FindFirstChild("CodeUI")
    local tb = codeUI and codeUI:FindFirstChild("TextBox")
    local btn = codeUI and codeUI:FindFirstChild("Claim")
    if not tb then return 0 end
    local focusBlock = UIS:AddFocusBlock()
    local savedEditable = tb.TextEditable
    pcall(function() tb.TextEditable = false end)
    local sukses = 0
    for i, code in ipairs(codes) do
        pcall(function() tb.Text = code end) task.wait(0.3)
        local fired = false
        if btn then fired = pcall(function() if firesignal then firesignal(btn.MouseButton1Click) else btn:Activate() end end) end
        if fired then sukses = sukses + 1 end
        task.wait(1)
    end
    pcall(function() tb.TextEditable = savedEditable end) focusBlock:Disconnect() task.wait(0.3)
    if codeUI then local exitBtn = codeUI:FindFirstChild("Exit") if exitBtn then pcall(function() if firesignal then firesignal(exitBtn.MouseButton1Click) else exitBtn:Activate() end end) end end
    return sukses
end

local function getMapFolder()
    local activeMap = workspace:FindFirstChild("ActiveMap")
    if not activeMap then return nil end
    for _, child in pairs(activeMap:GetChildren()) do if (child:IsA("Folder") or child:IsA("Model")) and child:FindFirstChild("Interactable") then return child end end
    return nil
end

function _G.STHAIN.TeleportScan()
    local results = { supplies = {}, captures = {} }
    local mapFolder = getMapFolder()
    if not mapFolder then return results end
    local interactable = mapFolder:FindFirstChild("Interactable")
    if not interactable then return results end
    local suppliesFolder = interactable:FindFirstChild("Supplies")
    if suppliesFolder then
        for _, obj in pairs(suppliesFolder:GetChildren()) do
            if obj:IsA("Model") then
                local n = string.lower(obj.Name)
                local teamType = "unknown"
                if n:find("attacker") then teamType = "attacker" elseif n:find("defender") then teamType = "defender" end
                table.insert(results.supplies, {name = obj.Name, instance = obj, capturePart = obj:FindFirstChild("CapturePoint"), team = teamType})
            end
        end
    end
    local pointsFolder = interactable:FindFirstChild("Points")
    if pointsFolder then for _, obj in pairs(pointsFolder:GetChildren()) do if obj:IsA("Model") then local cp = obj:FindFirstChild("CapturePoint") if cp then table.insert(results.captures, {name = obj.Name, instance = cp, model = obj}) end end end end
    return results
end

function _G.STHAIN.GetMyTeam()
    local sel = LP:GetAttribute("SelectedTeam")
    if sel then local n = string.lower(tostring(sel)) if n:find("attacker") then return "attacker" end if n:find("defender") then return "defender" end end
    if LP.Team then local n = string.lower(LP.Team.Name) if n:find("attacker") then return "attacker" end if n:find("defender") then return "defender" end end
    return "unknown"
end

local function godmodeOn()
    local char = getChar()
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local original = { MaxHealth = hum.MaxHealth, Health = hum.Health }
    local GOD_HP = 1000000
    pcall(function() hum.MaxHealth = GOD_HP hum.Health = GOD_HP end)
    local lockConn = Run.Stepped:Connect(function()
        if hum and hum.Parent then pcall(function() if hum.MaxHealth < GOD_HP then hum.MaxHealth = GOD_HP end if hum.Health < GOD_HP then hum.Health = GOD_HP end end) end
    end)
    return {
        restore = function()
            if lockConn then lockConn:Disconnect() end
            if hum and hum.Parent then pcall(function() hum.MaxHealth = original.MaxHealth hum.Health = original.MaxHealth end) end
        end
    }
end

function _G.STHAIN.TeleportTo(part)
    local char = getChar()
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hrp and part) then return false end
    local targetPos = typeof(part) == "Vector3" and part or part.Position
    local offY = (Config.Teleport and Config.Teleport.OffsetY) or 5
    local god = godmodeOn()
    local savedCollide = {}
    for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then savedCollide[p] = p.CanCollide p.CanCollide = false end end
    pcall(function() hrp.Velocity = Vector3.zero hrp.RotVelocity = Vector3.zero end)
    pcall(function() hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, offY, 0)) end)
    task.wait(1.5)
    pcall(function() hrp.Velocity = Vector3.zero hrp.RotVelocity = Vector3.zero end)
    task.wait(1)
    for p, cc in pairs(savedCollide) do if p and p.Parent then pcall(function() p.CanCollide = cc end) end end
    if god then god.restore() end
    return true
end

function _G.STHAIN.GetSupplyList()
    local results = _G.STHAIN.TeleportScan()
    if not results or #results.supplies == 0 then return nil end
    local myTeam = _G.STHAIN.GetMyTeam()
    if myTeam == "unknown" then return nil end
    local enemyTeam = (myTeam == "attacker") and "defender" or "attacker"
    local ownerSupplies = {}
    local enemySupplies = {}
    for _, sup in ipairs(results.supplies) do
        if sup.team == myTeam then table.insert(ownerSupplies, sup.name)
        elseif sup.team == enemyTeam then table.insert(enemySupplies, sup.name) end
    end
    return { myTeam = myTeam, enemyTeam = enemyTeam, ownerSupplies = ownerSupplies, enemySupplies = enemySupplies }
end

function _G.STHAIN.TeleportToSupplyEnemy(target)
    target = target or ""
    local results = _G.STHAIN.TeleportScan()
    if #results.supplies == 0 then return false end
    local myTeam = _G.STHAIN.GetMyTeam()
    if myTeam == "unknown" then return false end
    local enemyTeam = (myTeam == "attacker") and "defender" or "attacker"
    local candidates = {}
    for _, sup in ipairs(results.supplies) do if sup.team == enemyTeam then table.insert(candidates, sup) end end
    if #candidates == 0 then return false end
    if target ~= "" then for _, sup in ipairs(candidates) do if sup.name == target then _G.STHAIN.TeleportTo(sup.capturePart or sup.instance) return true end end end
    local targetSup = candidates[1]
    _G.STHAIN.TeleportTo(targetSup.capturePart or targetSup.instance)
    return true
end

function _G.STHAIN.TeleportToSupplyOwner(target)
    target = target or ""
    local results = _G.STHAIN.TeleportScan()
    if #results.supplies == 0 then return false end
    local myTeam = _G.STHAIN.GetMyTeam()
    if myTeam == "unknown" then return false end
    local candidates = {}
    for _, sup in ipairs(results.supplies) do if sup.team == myTeam then table.insert(candidates, sup) end end
    if #candidates == 0 then return false end
    if target ~= "" then for _, sup in ipairs(candidates) do if sup.name == target then _G.STHAIN.TeleportTo(sup.capturePart or sup.instance) return true end end end
    local targetSup = candidates[1]
    _G.STHAIN.TeleportTo(targetSup.capturePart or targetSup.instance)
    return true
end

function _G.STHAIN.TeleportToNearestCapture()
    local hrp = getHRP()
    if not hrp then return false end
    local results = _G.STHAIN.TeleportScan()
    local nearest, nd = nil, math.huge
    for _, cap in ipairs(results.captures) do
        if cap.instance and cap.instance.Parent then
            local d = (cap.instance.Position - hrp.Position).Magnitude
            if d < nd then nearest = cap nd = d end
        end
    end
    if nearest then _G.STHAIN.TeleportTo(nearest.instance) return true end
    return false
end

local function tpToNamed(name)
    local results = _G.STHAIN.TeleportScan()
    for _, cap in ipairs(results.captures) do if string.lower(cap.name) == string.lower(name) then _G.STHAIN.TeleportTo(cap.instance) return true end end
    return false
end

function _G.STHAIN.TeleportToBase()
    if tpToNamed("base") then return true end
    if tpToNamed("pointa") then return true end
    if tpToNamed("pointb") then return true end
    return false
end

function _G.STHAIN.TeleportToPointA() return tpToNamed("pointa") end
function _G.STHAIN.TeleportToPointB() return tpToNamed("pointb") end

function _G.STHAIN.TeleportToNearestEnemy()
    local char = getChar()
    local hrp = getHRP()
    if not (char and hrp) then return false end
    local nearest, nd = nil, math.huge
    for _, model in pairs(workspace:GetChildren()) do
        if model ~= char and model:IsA("Model") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local thrp = model:FindFirstChild("HumanoidRootPart")
                if thrp then local d = (thrp.Position - hrp.Position).Magnitude if d > 5 and d < nd then nearest = thrp nd = d end end
            end
        end
    end
    if nearest then _G.STHAIN.TeleportTo(nearest) return true end
    return false
end

function _G.STHAIN.TeleportToTeammate()
    local char = getChar()
    local hrp = getHRP()
    if not (char and hrp) then return false end
    local myTeam = _G.STHAIN.GetMyTeam()
    if myTeam == "unknown" then return false end
    local nearest, nd = nil, math.huge
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local pTeam = ""
            if player:GetAttribute("SelectedTeam") then pTeam = string.lower(tostring(player:GetAttribute("SelectedTeam")))
            elseif player.Team then pTeam = string.lower(player.Team.Name) end
            if pTeam:find(myTeam) then
                local thrp = player.Character:FindFirstChild("HumanoidRootPart")
                if thrp then local d = (thrp.Position - hrp.Position).Magnitude if d < nd then nearest = thrp nd = d end end
            end
        end
    end
    if nearest then _G.STHAIN.TeleportTo(nearest) return true end
    return false
end

local isDirty = false
local saveThread = nil

function _G.STHAIN.MarkDirty()
    if not _G.STHAIN.Config.Config.AutoSave then return end 
    isDirty = true
    if saveThread then task.cancel(saveThread) end
    saveThread = task.delay(2, function()
        if isDirty then
            if _G.STHAIN.Config.Config.AutoSave then if Utils and Utils.SaveConfig then Utils.SaveConfig() end end
            isDirty = false
            saveThread = nil
        end
    end)
end

function _G.STHAIN.SaveConfig() if Utils and Utils.SaveConfig then return Utils.SaveConfig() end return false end
function _G.STHAIN.LoadConfig() if Utils and Utils.LoadConfig then return Utils.LoadConfig() end return false end
function _G.STHAIN.DeleteConfig() if Utils and Utils.DeleteConfig then return Utils.DeleteConfig() end return false end

LP.CharacterAdded:Connect(function(char)
    task.wait(1.5)
    State.Invisible = false
    State.Noclip = false
    State.Fly = false
    if flyConn then stopFly() end
    cleanupESP()
    cleanupNoclip()
    aimLock = nil
    aimSmoothCF = nil
end)

task.spawn(function()
    task.wait(0.5)
    if S.Utils and S.Utils.LoadConfig then S.Utils.LoadConfig() end
end)
