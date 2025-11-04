-- Основные переменные
local killing = false
local killInterval = 5
local lastKillTime = 0
local killedHumanoids = {}
local guiMoving = false

-- Создаем ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillNPCGui"
screenGui.Parent = game.CoreGui -- Для чита-инжектора использовать CoreGui

-- Создаем кнопку переключения режима
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Start Killing"
toggleButton.Parent = screenGui

-- Создаем текст для таймера
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 150, 0, 50)
timerLabel.Position = UDim2.new(0, 10, 0, 70)
timerLabel.Text = "Next kill in: 5s"
timerLabel.Parent = screenGui

-- Создаем текст для консоли
local consoleLabel = Instance.new("TextLabel")
consoleLabel.Size = UDim2.new(0, 300, 0, 400)
consoleLabel.Position = UDim2.new(0, 10, 0, 130)
consoleLabel.TextWrapped = true
consoleLabel.Text = "Humanoid Info:\n"
consoleLabel.BackgroundColor3 = Color3.new(0, 0, 0)
consoleLabel.TextColor3 = Color3.new(1, 1, 1)
consoleLabel.Parent = screenGui

-- Создаем кнопку для перемещения GUI
local moveButton = Instance.new("TextButton")
moveButton.Size = UDim2.new(0, 150, 0, 50)
moveButton.Position = UDim2.new(0, 10, 0, 540)
moveButton.Text = "Move GUI"
moveButton.Parent = screenGui

-- Перемещение GUI
moveButton.MouseButton1Click:Connect(function()
    guiMoving = not guiMoving
    if guiMoving then
        moveButton.Text = "Moving..."
    else
        moveButton.Text = "Move GUI"
    end
end)

local dragging = false
local dragInput, dragStart, startPos

screenGui.InputBegan:Connect(function(input)
    if guiMoving and input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = screenGui.Position
    end
end)

screenGui.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

screenGui.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        screenGui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                         startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Функция для обновления консоли
local function updateConsole()
    local humanoidCounts = {}
    for hum, count in pairs(killedHumanoids) do
        if humanoidCounts[hum.Name] then
            humanoidCounts[hum.Name] = humanoidCounts[hum.Name] + count
        else
            humanoidCounts[hum.Name] = count
        end
    end
    local text = "Humanoid Info:\n"
    for name, count in pairs(humanoidCounts) do
        text = text .. name
        if count > 1 then
            text = text .. " (" .. count .. ")"
        end
        text = text .. "\n"
    end
    consoleLabel.Text = text
end

-- Функция для подсветки NPC
local function highlightNPC(npc)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = npc
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 1, 0)
    highlight.Parent = npc
    -- Удаляем подсветку через 0.5 сек чтобы избежать накопления
    game:GetService("RunService").Heartbeat:Wait()
    game.Debris:AddItem(highlight, 0.5)
end

-- Функция для убийства NPC
local function killNPCs()
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChildOfClass("Humanoid").Health > 0 then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            -- Убираем игроков
            if humanoid.Parent:FindFirstChildOfClass("Player") then
                continue
            end
            -- Подсветка
            highlightNPC(npc)
            -- Убийство
            humanoid.Health = 0
            -- Подсчет убитых
            killedHumanoids[npc.Name] = (killedHumanoids[npc.Name] or 0) + 1
        end
    end
end

-- Основной цикл
while true do
    if killing then
        local currentTime = tick()
        local timeSinceLastKill = currentTime - lastKillTime
        local timeLeft = math.max(0, killInterval - timeSinceLastKill)
        timerLabel.Text = "Next kill in: " .. string.format("%.1f", timeLeft) .. "s"
        if timeSinceLastKill >= killInterval then
            killNPCs()
            lastKillTime = currentTime
            updateConsole()
        end
    else
        timerLabel.Text = "Killing paused"
    end
    wait(0.1)
end

-- Обработчик кнопки переключения
toggleButton.MouseButton1Click:Connect(function()
    killing = not killing
    if killing then
        toggleButton.Text = "Stop Killing"
        lastKillTime = tick()
    else
        toggleButton.Text = "Start Killing"
    end
end)
