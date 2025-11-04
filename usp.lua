local autoKill = false
local killIntervalSeconds = 5
local killedCount = 0
local killedHumanoids = {} -- таблица для текущего периода
local guiDragging = false

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

-- Для перетаскивания GUI
local dragFrame = Instance.new("Frame")
dragFrame.Size = UDim2.new(0, 250, 0, 50)
dragFrame.Position = UDim2.new(0, 10, 0, 10)
dragFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dragFrame.BorderSizePixel = 2
dragFrame.Parent = ScreenGui
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
    -- Не удаляем старые, а добавляем новые для новых NPC
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
        -- Можно оставить подсветку или убрать по желанию
    end
end)

local timeLeft = killIntervalSeconds

-- Обработка перетаскивания GUI
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
        local newPos = startGuiPos + UDim2.new(0, delta.X, 0, delta.Y)
        ScreenGui.Position = newPos
    end
end)

while true do
    wait(1)
    if autoKill then
        timeLeft = timeLeft - 1
        if timeLeft < 0 then
            timeLeft = killIntervalSeconds
            -- Удаляем подсветки старых NPC
            for _, npc in pairs(workspace:GetChildren()) do
                if npc:FindFirstChild("AutoKillHighlight") then
                    npc.AutoKillHighlight:Destroy()
                end
            end
            -- Убиваем все NPC в workspace
            for _, npc in pairs(workspace:GetChildren()) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
                    humanoid.Health = 0
                    local name = npc.Name
                    killedHumanoids[name] = (killedHumanoids[name] or 0) + 1
                    killedCount = killedCount + 1
                end
            end
            updateGUI()
            refreshHighlights() -- добавляем новые подсветки
        end
        timerLabel.Text = "Следующий цикл через: " .. tostring(timeLeft) .. " сек"
    end
end
