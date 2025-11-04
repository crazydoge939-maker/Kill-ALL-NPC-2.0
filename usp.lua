-- Основной скрипт
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Создаем GUI
local screenGui = Instance.new("ScreenGui", game.CoreGui)
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true -- Для возможности перетаскивания
mainFrame.Draggable = true

local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, 0, 0, 50)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.Text = "Начать убийство"
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

local killIndicator = Instance.new("TextLabel", mainFrame)
killIndicator.Size = UDim2.new(1, 0, 0, 30)
killIndicator.Position = UDim2.new(0, 0, 0, 50)
killIndicator.Text = "Следующий цикл через: 5 сек"
killIndicator.TextColor3 = Color3.new(1,1,1)
killIndicator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

local consoleLabel = Instance.new("ScrollingFrame", mainFrame)
consoleLabel.Size = UDim2.new(1, 0, 1, -80)
consoleLabel.Position = UDim2.new(0, 0, 0, 80)
consoleLabel.CanvasSize = UDim2.new(0, 0, 0, 0)
consoleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
consoleLabel.BorderSizePixel = 0

local killMode = false -- режим убийства
local killInterval = 5 -- интервал в секундах
local timeLeft = killInterval
local killedHumanoidsCount = {} -- таблица для подсчета

-- Функция для обновления GUI
local function updateConsole()
    consoleLabel:ClearAllChildren()
    local yPos = 0
    for humanoidName, count in pairs(killedHumanoidsCount) do
        local label = Instance.new("TextLabel", consoleLabel)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, yPos)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Text = humanoidName .. " x" .. count
        yPos = yPos + 20
    end
    consoleLabel.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Переключение режима убийства
toggleButton.MouseButton1Click:Connect(function()
    killMode = not killMode
    if killMode then
        toggleButton.Text = "Остановить убийство"
        -- подсветка NPC
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = npc
                highlight.Name = "KillHighlight"
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = npc
            end
        end
    else
        toggleButton.Text = "Начать убийство"
        -- удаляем подсветку
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChild("KillHighlight") then
                npc:FindFirstChild("KillHighlight"):Destroy()
            end
        end
    end
end)

-- Время для следующего убийства
while true do
    if killMode then
        -- Убиваем NPC
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                local name = humanoid.Name
                -- Убиваем
                humanoid.Health = 0
                -- подсчет
                killedHumanoidsCount[name] = (killedHumanoidsCount[name] or 0) + 1
            end
        end
        -- Обновляем GUI
        updateConsole()
        -- Обновляем таймер
        timeLeft = killInterval
        killIndicator.Text = "Следующий цикл через: " .. timeLeft .. " сек"
    end

    -- Таймер
    for i = timeLeft, 0, -1 do
        killIndicator.Text = "Следующий цикл через: " .. i .. " сек"
        wait(1)
    end
end

-- Возможность перетаскивать GUI
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)
