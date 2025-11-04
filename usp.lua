local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Создаем GUI
local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui")) -- или StarterGui, если работает в тесте
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
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

local consoleFrame = Instance.new("ScrollingFrame", mainFrame)
consoleFrame.Size = UDim2.new(1, 0, 1, -80)
consoleFrame.Position = UDim2.new(0, 0, 0, 80)
consoleFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
consoleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
consoleFrame.BorderSizePixel = 0

local killedHumanoidsCount = {} -- таблица для подсчета
local killMode = false
local killInterval = 5
local timeLeft = killInterval

-- Функция для обновления GUI
local function updateConsole()
    consoleFrame:ClearAllChildren()
    local yPos = 0
    for name, count in pairs(killedHumanoidsCount) do
        local label = Instance.new("TextLabel", consoleFrame)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, yPos)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Text = name .. " x" .. count
        yPos = yPos + 20
    end
    consoleFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- Переключение режима убийства
toggleButton.MouseButton1Click:Connect(function()
    killMode = not killMode
    if killMode then
        toggleButton.Text = "Остановить убийство"
        -- добавляем подсветку NPC
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                if not npc:FindFirstChild("Highlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "Highlight"
                    highlight.Adornee = npc
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.Parent = npc
                end
            end
        end
    else
        toggleButton.Text = "Начать убийство"
        -- удаляем подсветку
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:FindFirstChild("Highlight") then
                npc:FindFirstChild("Highlight"):Destroy()
            end
        end
    end
end)

-- Основной цикл
spawn(function()
    while true do
        if killMode then
            -- Убиваем NPC
            for _, npc in pairs(workspace:GetDescendants()) do
                if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    local name = humanoid.Name
                    humanoid.Health = 0
                    killedHumanoidsCount[name] = (killedHumanoidsCount[name] or 0) + 1
                end
            end
            updateConsole()
        end
        -- Таймер и обновление
        for i = killInterval, 1, -1 do
            killIndicator.Text = "Следующий цикл через: " .. i .. " сек"
            wait(1)
        end
        -- Обновляем таймер
        killInterval = 5 -- можно изменить
    end
end)

-- Перетаскивание GUI
local dragging = false
local dragStart, startPos

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
