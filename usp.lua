local autoKill = false
local killIntervalSeconds = 5
local killedCount = 0
local killedHumanoids = {} -- будет перезаполняться каждый цикл
local highlightedNPCs = {} -- не нужен, так как подсветка всегда создается заново

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "Humanoid"

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 100, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Вкл"
toggleButton.Parent = ScreenGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 250, 0, 150)
infoLabel.Position = UDim2.new(0, 10, 0, 50)
infoLabel.Text = "Убитых: 0\n"
infoLabel.TextWrapped = true
infoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Parent = ScreenGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 250, 0, 30)
timerLabel.Position = UDim2.new(0, 10, 0, 210)
timerLabel.Text = "Следующий цикл через: " .. tostring(killIntervalSeconds) .. " сек"
timerLabel.TextWrapped = true
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Parent = ScreenGui

-- Создаем рамку для перетаскивания
local dragFrame = Instance.new("Frame")
dragFrame.Size = UDim2.new(0, 250, 0, 50)
dragFrame.Position = UDim2.new(0, 10, 0, 10)
dragFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dragFrame.BorderSizePixel = 2
dragFrame.Parent = ScreenGui

-- Внутри рамки размещаем кнопку
toggleButton.Parent = dragFrame

local function updateGUI()
    local text = "Убитых: " .. tostring(killedCount) .. "\n"
    for name, count in pairs(killedHumanoids) do
        text = text .. name .. " x" .. count .. "\n"
    end
    infoLabel.Text = text
end

local function addHighlight(npc)
    if npc:FindFirstChild("AutoKillHighlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "AutoKillHighlight"
    highlight.Adornee = npc
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = npc
end

local function refreshHighlights()
    -- Удаляем все старые подсветки
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChild("AutoKillHighlight") then
            npc.AutoKillHighlight:Destroy()
        end
    end
    -- Добавляем подсветку всем текущим NPC
    for _, npc in pairs(workspace:GetChildren()) do
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
            addHighlight(npc)
        end
    end
end

toggleButton.MouseButton1Click:Connect(function()
    autoKill = not autoKill
    if autoKill then
        toggleButton.Text = "Выкл"
        refreshHighlights()
    else
        toggleButton.Text = "Вкл"
        -- Не удаляем подсветки, чтобы новые NPC все равно подсвечивались
    end
end)

local timeLeft = killIntervalSeconds
local dragging = false
local dragStartPosition
local guiStartPosition

-- Обработки для перетаскивания GUI
dragFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPosition = input.Position
        guiStartPosition = ScreenGui.Position
    end
end)

dragFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

dragFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPosition
        local newPosition = guiStartPosition + UDim2.new(0, delta.X, 0, delta.Y)
        ScreenGui.Position = newPosition
    end
end)

while true do
    wait(1)
    if autoKill then
        timeLeft = timeLeft - 1
        if timeLeft < 0 then
            timeLeft = killIntervalSeconds
            -- Не очищаем таблицу убитых, чтобы она не копилась
            killedHumanoids = {}
            -- Не удаляем подсветки, подсветка создается заново
            refreshHighlights()

            local killedThisCycle = false
            for _, npc in pairs(workspace:GetChildren()) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
                    humanoid.Health = 0
                    local name = npc.Name
                    killedHumanoids[name] = (killedHumanoids[name] or 0) + 1
                    killedCount = killedCount + 1
                    print("Убит: " .. name)
                    killedThisCycle = true
                end
            end
            if killedThisCycle then
                updateGUI()
            end
        end
        timerLabel.Text = "Следующий цикл через: " .. tostring(timeLeft) .. " сек"
    end
end
