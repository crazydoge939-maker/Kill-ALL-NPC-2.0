-- Объявляем переменные
local killingEnabled = false
local killInterval = 5 -- интервал в секундах
local killTimer = 0
local killedHumanoids = {}
local gui = nil
local toggleButton = nil
local killModeLabel = nil
local timerLabel = nil
local indicator = nil
local lastUpdateTime = 0

-- Создаем главное GUI
local function createGUI()
    gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    gui.Name = "NPCKillerGUI"

    -- Основная рамка
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 2

    -- Перетаскиваемое окно
    local dragging = false
    local dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)

    -- Кнопка переключения режима
    toggleButton = Instance.new("TextButton", frame)
    toggleButton.Size = UDim2.new(1, -20, 0, 30)
    toggleButton.Position = UDim2.new(0, 10, 0, 10)
    toggleButton.Text = "Включить убийство"
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

    toggleButton.MouseButton1Click:Connect(function()
        killingEnabled = not killingEnabled
        if killingEnabled then
            toggleButton.Text = "Выключить убийство"
            toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        else
            toggleButton.Text = "Включить убийство"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        end
    end)

    -- Метка для отображения режима убийства
    killModeLabel = Instance.new("TextLabel", frame)
    killModeLabel.Size = UDim2.new(1, -20, 0, 20)
    killModeLabel.Position = UDim2.new(0, 10, 0, 50)
    killModeLabel.Text = "Режим: Выключен"
    killModeLabel.TextColor3 = Color3.new(1, 1, 1)
    killModeLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    -- Таймер для следующего убийства
    timerLabel = Instance.new("TextLabel", frame)
    timerLabel.Size = UDim2.new(1, -20, 0, 20)
    timerLabel.Position = UDim2.new(0, 10, 0, 80)
    timerLabel.Text = "Следующее убийство через: 5 сек"
    timerLabel.TextColor3 = Color3.new(1, 1, 1)
    timerLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    -- Контейнер для отображения убитых
    local killsContainer = Instance.new("ScrollingFrame", frame)
    killsContainer.Size = UDim2.new(1, -20, 1, -120)
    killsContainer.Position = UDim2.new(0, 10, 0, 110)
    killsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    killsContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    killsContainer.BorderSizePixel = 1

    -- Индикатор времени
    indicator = Instance.new("Frame", frame)
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(0, 10, 0, 140)
    indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

    -- Надпись "Индикатор"
    local indicatorLabel = Instance.new("TextLabel", frame)
    indicatorLabel.Size = UDim2.new(0, 80, 0, 20)
    indicatorLabel.Position = UDim2.new(0, 40, 0, 140)
    indicatorLabel.Text = "След. убийство"
    indicatorLabel.TextColor3 = Color3.new(1, 1, 1)
    indicatorLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end

-- Обновление GUI
local function updateGUI()
    if not gui then return end
    -- Обновляем режим
    if killingEnabled then
        killModeLabel.Text = "Режим: Включен"
    else
        killModeLabel.Text = "Режим: Выключен"
    end

    -- Обновляем таймер
    local timeLeft = math.max(0, killInterval - killTimer)
    timerLabel.Text = "Следующее убийство через: " .. string.format("%.1f", timeLeft) .. " сек"

    -- Обновляем индикатор
    local color = killingEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    indicator.BackgroundColor3 = color
end

-- Функция подсветки NPC
local function highlightNPC(npc)
    if not npc or not npc:FindFirstChildWhichIsA("BasePart") then return end
    local highlight = npc:FindFirstChild("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight.Adornee = npc
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = npc
    end
    highlight.Enabled = true
end

local function removeHighlight(npc)
    local highlight = npc:FindFirstChild("Highlight")
    if highlight then
        highlight.Enabled = false
    end
end

-- Основная логика убийства NPC
local function killNPCs()
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChildWhichIsA("Humanoid") and npc:FindFirstChildWhichIsA("Humanoid").Health > 0 then
            -- Убиваем NPC
            local humanoid = npc:FindFirstChildWhichIsA("Humanoid")
            humanoid.Health = 0

            -- Запоминаем имя Humanoid
            local name = humanoid:GetFullName()
            if killedHumanoids[name] then
                killedHumanoids[name] = killedHumanoids[name] + 1
            else
                killedHumanoids[name] = 1
            end
        end
    end
end

-- Обновление GUI с информацией о убитых
local function refreshKilledDisplay()
    if not gui then return end
    local container = gui:FindFirstChild("ScrollingFrame")
    if not container then return

    -- Удаляем старое содержимое
    for _, child in pairs(container:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Создаем новые строки
    local yPos = 0
    for name, count in pairs(killedHumanoids) do
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 5, 0, yPos)
        label.Text = name .. if count > 1 then " x" .. count else ""
        label.TextColor3 = Color3.new(1, 1, 1)
        label.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        yPos = yPos + 25
    end
    container.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Главный цикл
createGUI()

while true do
    wait(0.1)
    updateGUI()

    if killingEnabled then
        killTimer = killTimer + 0.1
        if killTimer >= killInterval then
            -- Убиваем NPC
            killNPCs()
            refreshKilledDisplay()
            killTimer = 0
        end
    else
        killTimer = 0
    end

    -- Обновляем подсветку
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChildWhichIsA("Humanoid") and npc:FindFirstChildWhichIsA("Humanoid").Health > 0 then
            highlightNPC(npc)
        else
            removeHighlight(npc)
        end
    end
end
