local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | FIXED EDITION",
   LoadingTitle = "Запуск системы...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Состояние фильтров баз
local ignoreEasy = true
local ignoreNormal = true

-- Функция получения координат
local function getSafePosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("BillboardGui") and obj.Adornee then return getSafePosition(obj.Adornee) end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

-- Новая точечная проверка зоны
local function isTargetInBlacklistedZone(targetObj)
    local model = targetObj:FindFirstAncestorOfClass("Model")
    if not model then return false end
    
    -- Ищем только BillboardGui (вывески баз), которые висят над моделью
    for _, item in pairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then
            local label = item:FindFirstChildOfClass("TextLabel")
            if label then
                local txt = label.Text:upper()
                if ignoreEasy and txt:find("EASY") then return true end
                if ignoreNormal and txt:find("NORMAL") then return true end
            end
        end
    end
    return false
end

local function getTargets()
    local validTargets = {}
    local allPrompts = {}
    
    -- Собираем кнопки [cite: 3]
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- Ищем редкость [cite: 17]
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- Проверка 1: Зоны (Easy/Normal)
            if not isTargetInBlacklistedZone(obj) then
                
                -- Проверка 2: Анти-Робукс [cite: 5]
                local isPaid = false
                local model = obj:FindFirstAncestorOfClass("Model")
                if model then
                    for _, t in pairs(model:GetDescendants()) do
                        if t:IsA("TextLabel") then
                            local txt = t.Text:lower()
                            if txt:find("r%$") or txt:find("robux") or txt:find("buy") then
                                isPaid = true break
                            end
                        end
                    end
                end

                if not isPaid then
                    local textPos = getSafePosition(obj)
                    if textPos then
                        -- Поиск кнопки рядом [cite: 7, 8]
                        local closestPrompt = nil
                        local minDist = 25
                        for _, prompt in pairs(allPrompts) do
                            local promptPos = getSafePosition(prompt.Parent)
                            if promptPos then
                                local dist = (promptPos - textPos).Magnitude [cite: 9]
                                if dist < minDist then
                                    closestPrompt = prompt
                                    minDist = dist [cite: 10]
                                end
                            end
                        end
                        
                        -- Проверка на свою базу [cite: 12]
                        if closestPrompt then
                            local isSafe = true
                            if savedPosition then
                                if (textPos - savedPosition.Position).Magnitude < 65 then
                                    isSafe = false [cite: 13]
                                end
                            end
                            
                            if isSafe then
                                table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos}) [cite: 14]
                            end
                        end
                    end
                end
            end
        end
    end
    return validTargets
end

-- UI ЭЛЕМЕНТЫ
MainTab:CreateButton({
   Name = "1. SAVE BASE POSITION",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame [cite: 16]
            Rayfield:Notify({Title = "OK", Content = "База сохранена!", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end, [cite: 17]
})

MainTab:CreateSection("Zone Blacklist (Ignore)")

MainTab:CreateToggle({
   Name = "Ignore EASY Base",
   CurrentValue = true,
   Callback = function(Value) ignoreEasy = Value end,
})

MainTab:CreateToggle({
   Name = "Ignore NORMAL Base",
   CurrentValue = true,
   Callback = function(Value) ignoreNormal = Value end,
})

-- АВТОФАРМ (Логика сохранена) 
local function doSteal()
    local targets = getTargets()
    if #targets > 0 then
        local target = targets[1]
        local hrp = player.Character.HumanoidRootPart
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0))
        task.wait(0.2)
        hrp.Anchored = true
        fireproximityprompt(target.p) [cite: 18]
        task.wait(target.p.HoldDuration + 0.3)
        hrp.Anchored = false
        hrp.CFrame = savedPosition
        return true
    end
    return false
end

MainTab:CreateToggle({
   Name = "3. START AUTO FARM",
   CurrentValue = false,
   Callback = function(Value)
        autoCollectEnabled = Value
        if Value then
            if not savedPosition then 
                Rayfield:Notify({Title = "СТОП", Content = "Сначала сохрани базу!", Duration = 3}) [cite: 20]
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1.5 or 2) [cite: 21]
                end
            end)
        end
   end,
})

MainTab:CreateButton({
   Name = "DEBUG (F9)",
   Callback = function()
        local targets = getTargets()
        print("Найдено целей: " .. #targets) [cite: 22]
   end,
})
