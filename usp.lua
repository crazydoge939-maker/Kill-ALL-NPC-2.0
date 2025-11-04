-- Скрипт для чита-инжектора
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Переменные
local killingEnabled = false
local killInterval = 5 -- секунды
local lastKillTime = 0
local killedHumanoids = {}
local guiDragging = false
local dragOffset = Vector2.new()

-- Создаем GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30))
mainFrame.Active = true

-- Перетаскивание GUI
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        guiDragging = true
        local mousePos = UserInputService:GetMouseLocation()
        dragOffset = Vector2.new(mousePos.X - mainFrame.AbsolutePosition.X, mousePos.Y - mainFrame.AbsolutePosition.Y)
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        guiDragging = false
    end
end)

RunService.Heartbeat:Connect(function()
    if guiDragging then
        local mousePos = UserInputService:GetMouseLocation()
        mainFrame.Position = UDim2.new(0, mousePos.X - dragOffset.X, 0, mousePos.Y - dragOffset.Y)
    end
end)

-- Создаем кнопку переключения режима
local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, -20, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Начать убийство"
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Font = Enum.Font.SourceSansBold

toggleButton.MouseButton1Click:Connect(function()
    killingEnabled = not killingEnabled
    if killingEnabled then
        toggleButton.Text = "Остановить убийство"
        -- Включаем подсветку
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                local highlight = npc:FindFirstChildOfClass("Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight", npc)
                end
                highlight.Adornee = npc:FindFirstChild("HumanoidRootPart")
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.OutlineColor = Color3.new(1, 0, 0)
                highlight.Enabled = true
            end
        end
    else
        toggleButton.Text = "Начать убийство"
        -- Убираем подсветку
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChildOfClass("Highlight") then
                npc:FindFirstChildOfClass("Highlight").Enabled = false
            end
        end
    end
end)

-- Создаем таблицу для отображения убийств
local killsLabel = Instance.new("TextLabel", mainFrame)
killsLabel.Size = UDim2.new(1, -20, 0, 100)
killsLabel.Position = UDim2.new(0, 10, 0, 70)
killsLabel.Text = "Убитые Humanoid:\n"
killsLabel.TextColor3 = Color3.new(1,1,1)
killsLabel.BackgroundColor3 = Color3.fromRGB(50,50,50)
killsLabel.Font = Enum.Font.SourceSans
killsLabel.TextWrapped = true

-- Создаем таймер индикатор
local timerLabel = Instance.new("TextLabel", mainFrame)
timerLabel.Size = UDim2.new(1, -20, 0, 30)
timerLabel.Position = UDim2.new(0, 10, 0, 180)
timerLabel.TextColor3 = Color3.new(1,1,1)
timerLabel.BackgroundColor3 = Color3.fromRGB(50,50,50)
timerLabel.Font = Enum.Font.SourceSans
timerLabel.Text = "Следующий цикл через: 0 секунд"

-- Основной цикл
RunService.Heartbeat:Connect(function()
    if killingEnabled then
        local currentTime = os.time()
        if currentTime - lastKillTime >= killInterval then
            lastKillTime = currentTime
            -- Убиваем NPC
            for _, npc in pairs(workspace:GetDescendants()) do
                if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                    -- Проверка, чтобы не убивать игроков
                    local parent = npc.Parent
                    if not parent:FindFirstChildOfClass("Player") then
                        -- Убийство
                        npc:FindFirstChildOfClass("Humanoid")..Health = 0
                        local humanoidName = npc:FindFirstChildOfClass("Humanoid").Name
                        killedHumanoids[humanoidName] = (killedHumanoids[humanoidName] or 0) + 1
                    end
                end
            end
        end
        -- Обновление GUI
        -- Удаляем старое содержание
        killsLabel.Text = "Убитые Humanoid:\n"
        for name, count in pairs(killedHumanoids) do
            killsLabel.Text = killsLabel.Text .. name .. ": " .. count .. "\n"
        end
        -- Обновляем таймер
        local timeLeft = math.max(0, killInterval - (os.time() - lastKillTime))
        timerLabel.Text = "Следующий цикл через: " .. timeLeft .. " секунд"
    end
end)
