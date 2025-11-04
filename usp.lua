-- Этот скрипт предназначен для работы через чита-инжектор
-- Он создает GUI и управляет убийством NPC

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local isActive = false -- режим убийства
local killInterval = 5 -- интервал убийства в секундах
local lastKillTime = 0
local killedHumanoids = {} -- таблица для подсчета убитых по названиям

-- Создаем GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NPCKillerGUI"
screenGui.Parent = game:GetService("CoreGui") -- для читов

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0, 50, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true -- делаем перетаскиваемым
frame.Parent = screenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 0, 50)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.Text = "Включить убийство"
toggleButton.Parent = frame

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, 0, 1, -50)
infoText.Position = UDim2.new(0, 0, 0, 50)
infoText.Text = "Нажмите кнопку для включения"
infoText.TextColor3 = Color3.new(1, 1, 1)
infoText.BackgroundTransparency = 1
infoText.TextWrapped = true
infoText.Parent = frame

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 20, 0, 20)
indicator.Position = UDim2.new(0, 10, 0, 10)
indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
indicator.Parent = frame

local function updateIndicator()
    if isActive then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end

updateIndicator()

toggleButton.MouseButton1Click:Connect(function()
    isActive = not isActive
    if isActive then
        toggleButton.Text = "Остановить убийство"
        infoText.Text = "Убийство активно"
    else
        toggleButton.Text = "Включить убийство"
        infoText.Text = "Убийство остановлено"
    end
    updateIndicator()
end)

-- Создаем текст для отображения времени до следующего убийства
local timerText = Instance.new("TextLabel")
timerText.Size = UDim2.new(1, 0, 0, 20)
timerText.Position = UDim2.new(0, 0, 1, -20)
timerText.TextColor3 = Color3.new(1, 1, 1)
timerText.BackgroundTransparency = 1
timerText.Parent = frame

local function getHumanoidName(humanoid)
    if humanoid.Parent and humanoid.Parent.Name then
        return humanoid.Parent.Name
    else
        return "Unknown"
    end
end

local function killNPCs()
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChildOfClass("Humanoid").Health > 0 then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            -- Устанавливаем подсветку
            if isActive then
                local highlight = npc:FindFirstChild("Highlight") or Instance.new("Highlight")
                highlight.Name = "Highlight"
                highlight.Adornee = npc
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = npc
            end
            -- Убиваем
            humanoid.Health = 0
        end
    end
end

local function updateKill()
    if isActive and tick() - lastKillTime >= killInterval then
        killNPCs()
        lastKillTime = tick()
    end
end

local function updateGUI()
    -- Обновляем данные о убитых
    local displayData = {}
    for name, count in pairs(killedHumanoids) do
        table.insert(displayData, name .. (count > 1 and (" (" .. count .. ")") or ""))
    end
    infoText.Text = "Убитые:\n" .. table.concat(displayData, "\n")
end

-- Основной цикл
RunService.Heartbeat:Connect(function()
    -- Обновляем таймер
    local timeLeft = math.max(0, killInterval - (tick() - lastKillTime))
    timerText.Text = "Следующее убийство через: " .. string.format("%.1f", timeLeft) .. " сек"
    -- Обновляем GUI
    updateGUI()
    -- Выполняем убийство
    updateKill()
end)

-- Очистка подсветки при отключении
local function clearHighlights()
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChild("Highlight") then
            npc:FindFirstChild("Highlight"):Destroy()
        end
    end
end

-- Обработка отключения режима
RunService.Heartbeat:Connect(function()
    if not isActive then
        clearHighlights()
    end
end)

-- Позволяет перемещать GUI
-- Уже делается через свойство .Draggable = true
