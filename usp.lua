local killing = false
local killInterval = 5
local killedHumanoids = {}
local lastKillTime = 0
local killToggle = false

-- Создание GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KillGUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Начать убийство"
toggleButton.Parent = ScreenGui

local consoleFrame = Instance.new("Frame")
consoleFrame.Size = UDim2.new(0, 300, 0, 400)
consoleFrame.Position = UDim2.new(0, 10, 0, 70)
consoleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
consoleFrame.Parent = ScreenGui

local consoleText = Instance.new("TextLabel")
consoleText.Size = UDim2.new(1, -20, 1, -20)
consoleText.Position = UDim2.new(0, 10, 0, 10)
consoleText.BackgroundTransparency = 1
consoleText.TextColor3 = Color3.new(1,1,1)
consoleText.TextWrapped = true
consoleText.Text = ""
consoleText.Parent = consoleFrame

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 20, 0, 20)
indicator.Position = UDim2.new(0, 320, 0, 80)
indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
indicator.Parent = ScreenGui

local indicatorLabel = Instance.new("TextLabel")
indicatorLabel.Size = UDim2.new(0, 80, 0, 20)
indicatorLabel.Position = UDim2.new(0, 350, 0, 80)
indicatorLabel.Text = "След. убийство:"
indicatorLabel.TextColor3 = Color3.new(1,1,1)
indicatorLabel.Parent = ScreenGui

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(0, 80, 0, 20)
timeLabel.Position = UDim2.new(0, 440, 0, 80)
timeLabel.Text = tostring(killInterval).." сек"
timeLabel.TextColor3 = Color3.new(1,1,1)
timeLabel.Parent = ScreenGui

-- Перетаскивание GUI
local dragging = false
local dragInput, dragStart, startPos

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = ScreenGui:GetPosition()
    end
end)

toggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        ScreenGui:TranslateToWorldSpace(startPos + delta)
    end
end)

-- Функция для обновления GUI с информацией о убитых NPC
local function updateConsole()
    consoleText.Text = ""
    for name, count in pairs(killedHumanoids) do
        if count > 1 then
            consoleText.Text = consoleText.Text .. name .. " x" .. count .. "\n"
        else
            consoleText.Text = consoleText.Text .. name .. "\n"
        end
    end
end

-- Функция подсветки NPC
local function highlightNPC(npc)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = npc
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = npc
    game:GetService("Debris"):AddItem(highlight, 1)
end

-- Обновленная функция проверки, что это NPC, а не игрок
local function isValidNPC(npc)
    if not npc:FindFirstChildOfClass("Humanoid") then
        return false
    end
    
    -- Исключить модели, находящиеся в workspace.Players
    if npc.Parent and npc.Parent.Name == "Players" then
        return false
    end

    -- Исключить локального персонажа
    local localPlayerChar = game.Players.LocalPlayer.Character
    if localPlayerChar and npc == localPlayerChar then
        return false
    end

    return true
end

-- Основная логика убийства
local function killHumanoids()
    while killing do
        local currentTime = tick()
        if currentTime - lastKillTime >= killInterval then
            lastKillTime = currentTime
            -- Проходим по всем NPC
            for _, npc in pairs(workspace:GetDescendants()) do
                if isValidNPC(npc) then
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid.Health = 0
                        local name = humanoid.Name
                        if not killedHumanoids[name] then
                            killedHumanoids[name] = 1
                        else
                            killedHumanoids[name] = killedHumanoids[name] + 1
                        end
                        highlightNPC(npc)
                    end
                end
            end
            updateConsole()
            indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            wait(0.2)
            indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        end
        local timeRemaining = math.max(0, killInterval - (tick() - lastKillTime))
        timeLabel.Text = string.format("%.1f сек", timeRemaining)
        wait(0.5)
    end
end

-- Обработка кнопки
toggleButton.MouseButton1Click:Connect(function()
    killToggle = not killToggle
    if killToggle then
        killing = true
        toggleButton.Text = "Остановить убийство"
        spawn(killHumanoids)
    else
        killing = false
        toggleButton.Text = "Начать убийство"
    end
end)
