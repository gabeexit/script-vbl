local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://gist.githubusercontent.com/Tremaxz/f971e382d992904045ad6bb4a2e31aee/raw/83684fc4540524c2b1027f412d42ae0f5fbbdc0c/gistfile1.txt'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'GABEE HUB',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Game'),
    Others = Window:AddTab('Others'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

Library.KeybindFrame.Visible = false -- <<< desativa o "keybinds" da tela!

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Variáveis
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local humanoid = character:WaitForChild("Humanoid")

local lastCamCFrame = camera.CFrame
local airRotateEnabled = false

local hitboxSize = 12
local hitboxAtivado = false
local hitboxLoop = nil

-- Funções do Air Rotate
local function isInAir()
    return humanoid.FloorMaterial == Enum.Material.Air
end

local function isShiftLockEnabled()
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

-- Função que roda a cada frame
local function airRotate()
    RunService.RenderStepped:Connect(function()
        if airRotateEnabled and isShiftLockEnabled() then
            local currentCam = camera.CFrame
            local deltaYaw = (currentCam.LookVector - lastCamCFrame.LookVector).Magnitude

            -- Se a câmera foi girada e o personagem estiver no ar
            if deltaYaw > 0.01 and isInAir() then
                local lookVector = currentCam.LookVector
                local flatDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

                if flatDirection.Magnitude > 0 then
                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatDirection)
                end
            end
            lastCamCFrame = currentCam
        end
    end)
end

-- Funções da Hitbox
local function duplicarHitbox(bolaModel)
    local cubeOriginal = bolaModel:FindFirstChild("Cube.001", true)
    if cubeOriginal and cubeOriginal:IsA("BasePart") then
        if bolaModel:FindFirstChild("CustomHitbox") then return end

        local cubeClone = cubeOriginal:Clone()
        cubeClone.Name = "CustomHitbox"
        cubeClone.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        cubeClone.Transparency = 1
        cubeClone.CanCollide = false
        cubeClone.Anchored = false
        cubeClone.Massless = true
        cubeClone.Parent = bolaModel

        cubeClone.CFrame = cubeOriginal.CFrame

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = cubeOriginal
        weld.Part1 = cubeClone
        weld.Parent = cubeClone
    end
end

local function verificarBolas()
    while hitboxAtivado do
        for _, model in ipairs(Workspace:GetChildren()) do
            if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
                local cube = model:FindFirstChild("Cube.001", true)
                if cube then
                    duplicarHitbox(model)
                end
            end
        end
        task.wait(1)
    end
end

local function removerHitboxes()
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local customHitbox = model:FindFirstChild("CustomHitbox")
            if customHitbox then
                customHitbox:Destroy()
            end
        end
    end
end

-- Adicionando Group Functions
local FunctionsGroup = Tabs.Main:AddLeftGroupbox('Functions')

FunctionsGroup:AddToggle('AirRotateToggle', {
    Text = 'Air Rotate',
    Default = false,
    Tooltip = 'Gira o personagem no ar baseado na câmera',
}):OnChanged(function(state)
    airRotateEnabled = state

    if state then
        airRotate() -- Ativa o Air Rotate quando o toggle estiver ativado
    end
end)

FunctionsGroup:AddToggle('BallHitboxToggle', {
    Text = 'Ball Hitbox',
    Default = false,
    Tooltip = 'Ativa/desativa hitbox nas bolas',
}):OnChanged(function(state)
    hitboxAtivado = state

    if hitboxAtivado then
        hitboxLoop = task.spawn(verificarBolas)
    else
        removerHitboxes()
        if hitboxLoop then
            task.cancel(hitboxLoop)
        end
    end
end)

FunctionsGroup:AddSlider('BallHitboxSizeSlider', {
    Text = 'Ball Hitbox Size',
    Default = 12,
    Min = 2.5,
    Max = 20,
    Rounding = 1,
    Tooltip = 'Ajusta o tamanho da hitbox',
}):OnChanged(function(value)
    hitboxSize = value

    -- Atualiza hitboxes existentes
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local customHitbox = model:FindFirstChild("CustomHitbox")
            if customHitbox then
                customHitbox.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            end
        end
    end
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind 

-- Managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('NatumHub')
SaveManager:SetFolder('NatumHub/specific-game')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
