local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local connections = {}
local UI = game:GetObjects("rbxassetid://113459241808343")[1]

local function notify(t)
    game:GetService("StarterGui"):SetCore("SendNotification", t)
end

if getgenv().scriptRunning then
    notify({Title = "logger", Text = "script is already running", Duration = 5})
    return
end
getgenv().scriptRunning = true

local function randomString(length)
    length = length or math.random(10, 20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

getgenv().killScript = function()
    for _, v in connections do
        v:Disconnect()
    end
    UI:Destroy()
    getgenv().scriptRunning = false 
end

local Main = UI:WaitForChild("Main")
local ScrollingFrame = Main.ScrollingFrame
local Examples = ScrollingFrame.Examples
local ExampleLog = Examples:GetChildren()[1]

UI.Parent = game:GetService("CoreGui")
UI.Name = randomString(math.random(50, 150))

Main.Title.Text = "bytepenguin logger"

local function addLog(text)
    local clone = ExampleLog:Clone()
    clone.Parent = ScrollingFrame
    clone.Text = text
    clone.Name = "log"
    clone.Visible = true
    return clone
end

local existingLogs = {}

local function clearLogs()
    for logId, logInfo in pairs(existingLogs) do
        if logInfo.label.Text ~= "welcome!" then
            logInfo.label:Destroy()
            existingLogs[logId] = nil
        end
    end
end

local function updateLogs()
    local currentLogs = {}

    for _, v in pairs(game.Workspace:GetDescendants()) do
        local logId, logText

        if v:IsA("Sound") and v.Playing then
            local id = string.gsub(v.SoundId, "%D", "")
            if id ~= "" and id ~= "3" then
                logId = id
                logText = "Sound | ID: " .. id .. " | Name: " .. v.Name
            end
        elseif v:IsA("Decal") then
            local id = string.gsub(v.Texture, "%D", "")
            if id ~= "" and v.Name ~= "face" then
                logId = id
                logText = "Decal | ID: " .. id .. " | Name: " .. v.Name
            end
        end

        if logId then
            currentLogs[logId] = {text = logText, object = v}
        end
    end

    for logId, logInfo in pairs(currentLogs) do
        if not existingLogs[logId] then
            local log = addLog(logInfo.text)
            existingLogs[logId] = {label = log, object = logInfo.object}
        else
            local existingLog = existingLogs[logId]
            existingLog.label.Text = logInfo.text
            existingLog.object = logInfo.object
        end
    end

    for logId, logInfo in pairs(existingLogs) do
        if not currentLogs[logId] then
            TweenService:Create(logInfo.label, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(110, 110, 110)}):Play()
        end
    end
end

updateLogs()

connections.update = RunService.Heartbeat:Connect(function()
    updateLogs()
end)

local buttonConnections = {}

local function setupButton(v)
    if not buttonConnections[v] then
        buttonConnections[v] = true
        v.MouseButton1Click:Connect(function()
            local idValue = v:FindFirstChildOfClass("StringValue")
            local id

            if idValue then
                id = string.gsub(idValue.Value, "%D", "")
            else
                local logText = v.Text
                local idMatch = logText:match("ID: (%d+)")
                if idMatch then
                    id = idMatch
                else
                    notify({Title = "bytepenguin logger", Text = "no ID found for this button", Duration = 5})
                    return
                end
            end
            
            setclipboard(id)
            notify({Title = "bytepenguin logger", Text = id .. " set to clipboard", Duration = 5})
        end)
    end
end

for _, v in pairs(Main.ScrollingFrame:GetChildren()) do
    if v:IsA("TextButton") then
        setupButton(v)
    end
end

Main.ScrollingFrame.ChildAdded:Connect(function(child)
    if child:IsA("TextButton") then
        setupButton(child)
    end
end)

Main.Title.MouseEnter:Connect(function()
    TweenService:Create(Main.Title, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255, 135, 135)}):Play()
end)

Main.Title.MouseLeave:Connect(function()
    TweenService:Create(Main.Title, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

Main.Title.MouseButton1Click:Connect(clearLogs)

Main.Save.MouseEnter:Connect(function()
    TweenService:Create(Main.Save, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
end)

Main.Save.MouseLeave:Connect(function()
    TweenService:Create(Main.Save, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

Main.Save.MouseButton1Click:Connect(function()
    local data = {}

    for _, v in pairs(Main.ScrollingFrame:GetChildren()) do
        if v:IsA("TextButton") then
            data[v.Text] = v.Text
        end
    end
    
    local baseFileName = "bytepenguin_logger_save"
    local fileName = baseFileName .. ".txt"
    local counter = 1
    
    while isfile(fileName) do
        fileName = baseFileName .. "_" .. counter .. ".txt"
        counter = counter + 1
    end
    
    local content = fileName .. "\n\n"
    for _, entry in pairs(data) do
        content = content .. "log entry: " .. entry .. "\n"
    end

    writefile(fileName, content)
    notify({Title = "bytepenguin logger", Text = "successfully saved as " .. fileName})
end)

Main.Close.MouseButton1Click:Connect(getgenv().killScript)

local function dragify(Frame)
    local dragToggle, dragInput, dragStart, startPos

    local function updateInput(input)
        local Delta = input.Position - dragStart
        local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
        TweenService:Create(Frame, TweenInfo.new(0.1), {Position = Position}):Play()
    end

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:GetFocusedTextBox() == nil then
            dragToggle = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            updateInput(input)
        end
    end)
end

dragify(Main)
