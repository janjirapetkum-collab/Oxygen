-- [[ OXYGEN V2 - STABLE HUMANIZED BUILD ]]
-- Version: 2.0.1 (HBSS-Integrated)
-- Purpose: Complete Mobile/Universal Combat & Visual System

-- [[ LOCALIZATION & PERFORMANCE CACHE ]]
local RS, Players, LP, UIS = game:GetService("RunService"), game:GetService("Players"), game:GetService("Players").LocalPlayer, game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild, GetChildren = game.FindFirstChild, game.GetChildren
local CFnew, V2new, tick = CFrame.new, Vector2.new, tick
local lastShot = 0

-- [[ BYPASS ENGINE V3.5 (COMPREHENSIVE HBSS HOOKS) ]]
local function ApplyBypass()
    pcall(function()
        hookfunction(RS.IsStudio, function() return true end)
        local Remote = game:GetService("ReplicatedStorage"):FindFirstChild("ExecutorDetection")
        local mt = getrawmetatable(game)
        local oldNC, oldIdx = mt.__namecall, mt.__index
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method, args = getnamecallmethod(), {...}
            if not checkcaller() then
                if (self == Remote or tostring(self):find("Detection")) and method == "FireServer" then return nil end
                if _G.Config.Testing.SilentAim then
                    local t = _G.GetClosest(nil, nil)
                    if t then
                        if method == "Raycast" and self == workspace then
                            args[2] = (t.Position - args[1]).Unit * 1000
                            return oldNC(self, unpack(args))
                        elseif method:find("FindPartOnRay") then
                            args[1] = Ray.new(Camera.CFrame.Position, (t.Position - Camera.CFrame.Position).Unit * 1000)
                            return oldNC(self, unpack(args))
                        elseif method == "ScreenPointToRay" or method == "ViewportPointToRay" then
                            return Ray.new(t.Position + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0))
                        end
                    end
                end
            end
            return oldNC(self, ...)
        end)

        mt.__index = newcclosure(function(self, idx)
            if not checkcaller() and _G.Config.Testing.SilentAim then
                if self:IsA("Mouse") and (idx == "Hit" or idx == "Target") then
                    local t = _G.GetClosest(nil, nil)
                    if t then return (idx == "Hit" and t.CFrame or t) end
                end
            end
            if _G.Config.Testing.Triggerbot and idx == "UserInputType" then return Enum.UserInputType.Touch end
            return oldIdx(self, idx)
        end)
        setreadonly(mt, true)
    end)
end
ApplyBypass()

-- [[ MASTER CONFIG ]]
_G.Config = {
    Visuals = { Player = false, Scav = false, Health = false },
    Loot = { Master = false, Bot = false, Player = false, Containers = false },
    Gear = { Master = false, Scan = false },
    Aim = { Enabled = false, WallCheck = false, Smoothness = 10, FOV = 100, TargetPart = "Head", ShowFOV = false },
    Targets = { Players = true, NPCs = false },
    Testing = { SilentAim = false, Triggerbot = false, TriggerFOV = 25, TriggerWallCheck = true, ShowTriggerFOV = false, TriggerDelay = 0 }
}

-- [[ UI & VISUALS SETUP ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness, FOVCircle.Color, FOVCircle.Transparency, FOVCircle.Visible = 1.5, Color3.new(1, 1, 1), 0.7, false
local TriggerCircle = Drawing.new("Circle")
TriggerCircle.Thickness, TriggerCircle.Color, TriggerCircle.Transparency, TriggerCircle.Visible = 1, Color3.new(1, 0, 0), 0.5, false

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "OXYGEN | V2", LoadingTitle = "Oxygen Stable Build"})

local VisualsTab = Window:CreateTab("Visuals")
local AimTab = Window:CreateTab("Aimtouch")
local TestTab = Window:CreateTab("Testing")

-- [[ TARGET ACQUISITION SYSTEM ]]
_G.GetClosest = function(cFov, cWall)
    local target, shortest = nil, cFov or _G.Config.Aim.FOV
    local wallCheck = (cWall ~= nil) and cWall or _G.Config.Aim.WallCheck
    local center = V2new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    local function Validate(model)
        local part = model:FindFirstChild(_G.Config.Aim.TargetPart, true)
        if part and part:IsA("BasePart") then
            local pos, screen = WorldToViewportPoint(Camera, part.Position)
            if screen then
                local dist = (V2new(pos.X, pos.Y) - center).Magnitude
                if dist < shortest then
                    if wallCheck then
                        local cast = GetPartsObscuringTarget(Camera, {Camera.CFrame.Position, part.Position}, {LP.Character, model})
                        if #cast > 0 then return end
                    end
                    shortest, target = dist, part
                end
            end
        end
    end

    if _G.Config.Targets.Players then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then Validate(p.Character) end end end
    if _G.Config.Targets.NPCs then
        local AI = workspace:FindFirstChild("ACS_WorkSpace") and workspace.ACS_WorkSpace:FindFirstChild("AI")
        if AI then for _, b in ipairs(AI:GetChildren()) do Validate(b) end end
    end
    return target
end

-- [[ CORE COMBAT LOOP ]]
RS.Heartbeat:Connect(function()
    -- Mobile Triggerbot
    if _G.Config.Testing.Triggerbot then
        local delay = _G.Config.Testing.TriggerDelay / 1000
        if (tick() - lastShot) >= (delay + (math.random(-5,5)/1000)) then
            local t = _G.GetClosest(_G.Config.Testing.TriggerFOV, _G.Config.Testing.TriggerWallCheck)
            if t then
                local Tool = LP.Character:FindFirstChildOfClass("Tool")
                if Tool then lastShot = tick(); Tool:Activate() end
            end
        end
    end

    -- Aimtouch Smooth Interpolation
    if _G.Config.Aim.Enabled and not _G.Config.Testing.SilentAim then
        local t = _G.GetClosest()
        if t then
            local targetCF = CFnew(Camera.CFrame.Position, t.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(1 - (_G.Config.Aim.Smoothness / 105), 0.01, 1))
        end
    end
end)

-- [[ UI ELEMENTS ]]
AimTab:CreateToggle({Name = "Enable Aimtouch", Callback = function(v) _G.Config.Aim.Enabled = v end})
AimTab:CreateSlider({Name = "FOV Size", Range = {10, 600}, Increment = 1, CurrentValue = 100, Callback = function(v) _G.Config.Aim.FOV = v end})

TestTab:CreateSection("Experimental Mobile")
TestTab:CreateToggle({Name = "Silent Aim", Callback = function(v) _G.Config.Testing.SilentAim = v end})
TestTab:CreateToggle({Name = "Triggerbot", Callback = function(v) _G.Config.Testing.Triggerbot = v end})
TestTab:CreateSlider({Name = "Trigger Delay (ms)", Range = {0, 200}, Increment = 1, CurrentValue = 0, Callback = function(v) _G.Config.Testing.TriggerDelay = v end})

RS.RenderStepped:Connect(function()
    FOVCircle.Visible, FOVCircle.Radius, FOVCircle.Position = _G.Config.Aim.ShowFOV, _G.Config.Aim.FOV, Camera.ViewportSize/2
    TriggerCircle.Visible, TriggerCircle.Radius, TriggerCircle.Position = _G.Config.Testing.ShowTriggerFOV, _G.Config.Testing.TriggerFOV, FOVCircle.Position
end)
