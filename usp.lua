local autoKill = false
local killIntervalSeconds = 5
local killedCount = 0
local killedHumanoids = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "Humanoid"

local dragFrame = Instance.new("Frame")
dragFrame.Size = UDim2.new(0, 250, 0, 50)
dragFrame.Position = UDim2.new(0, 10, 0, 10)
dragFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dragFrame.BorderSizePixel = 2
dragFrame.Parent = ScreenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 100, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Вкл"
toggleButton.Parent = dragFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 250, 0, 150)
infoLabel.Position = UDim2.new(0, 0, 0, 60)
infoLabel.Text = "Убитых: 0\n"
infoLabel.TextWrapped = true
infoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Parent = ScreenGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 250, 0, 30)
timerLabel.Position = UDim2.new(0, 0, 0, 210)
timerLabel.Text = "Следующий цикл через: " .. tostring(killIntervalSeconds) .. " сек"
timerLabel.TextWrapped = true
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Parent = ScreenGui

-- Перетаскивание GUI
local dragging = false
local startPos, startGuiPos

dragFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startPos = input.Position
        startGuiPos = ScreenGui.Position
    end
end)

dragFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

dragFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - startPos
        ScreenGui.Position = startGuiPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

local function updateConsole()
    -- Полностью пересоздаем вывод
    infoLabel.Text = "Убитых: " .. tostring(killedCount) .. "\n"
    for name, count in pairs(killedHumanoids) do
        infoLabel.Text = infoLabel.Text .. name .. " x" .. count .. "\n"
    end
end

local function createHighlight(npc)
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
    -- Создаем подсветку для новых NPC
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("AutoKillHighlight") == nil then
            createHighlight(npc)
        end
    end
end

toggleButton.MouseButton1Click:Connect(function()
    autoKill = not autoKill
    if autoKill then
        toggleButton.Text = "Выкл"
        -- Создаем подсветку для существующих NPC
        refreshHighlights()
    else
        toggleButton.Text = "Вкл"
        -- Не удаляем подсветки, их можно оставить
    end
end)

local timeLeft = killIntervalSeconds

while true do
    wait(1)
    if autoKill then
        timeLeft = timeLeft - 1
        if timeLeft <= 0 then
            timeLeft = killIntervalSeconds
            -- Удаляем все подсветки перед убийством (чтобы не мешали)
            for _, npc in pairs(workspace:GetChildren()) do
                local highlight = npc:FindFirstChild("AutoKillHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
            -- Убиваем всех NPC
            for _, npc in pairs(workspace:GetChildren()) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid.Health = 0
                    local name = npc.Name
                    killedHumanoids[name] = (killedHumanoids[name] or 0) + 1
                    killedCount = killedCount + 1
                end
            end
            updateConsole()
            -- Создаем подсветки для новых
            refreshHighlights()
        end
        timerLabel.Text = "Следующий цикл через: " .. tostring(timeLeft) .. " сек"
    end
end
