local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | PRO EDITION",
   LoadingTitle = "Запуск системы...",
   LoadingSubtitle = "Improved Blacklist",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Настройки игнорирования баз
local ignoreZones = {
    ["EASY"] = true,
    ["NORMAL"] = true
}

-- Функция для получения позиции
local function getSafePosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    return nil
end

-- УЛУЧШЕННАЯ ПРОВЕРКА ЗОНЫ (через BillboardGui)
local function isTargetInBlockedZone(targetTextLabel)
    local model = targetTextLabel:FindFirstAncestorOfClass("Model")
    if not model then return false end

    -- Ищем BillboardGui (вывеску базы) именно внутри модели этой базы
    for _, item in pairs(model:GetDescendants()) do
        if item:IsA("BillboardGui") then
            local label = item:FindFirstChildOfClass("TextLabel")
            if label then
                local zoneText = label.Text:upper()
                for zoneName, shouldIgnore in pairs(ignoreZones) do
                    if shouldIgnore and zoneText:find(zoneName) then
                        -- Нашли вывеску "EASY" или "NORMAL" внутри этой же модели
                        return true 
                    end
                end
            end
        end
    end
    return false
end

local function getTargets()
    local validTargets = {}
    local allPrompts = {}
    
    -- Собираем все кнопки на карте
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- Ищем только нужную редкость
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- ПРОВЕРКА 1: Не в забаненной ли зоне бреинрот?
            if not isTargetInBlockedZone(obj) then
                
                -- ПРОВЕРКА 2: Анти-Робукс (символы валюты в названии)
                local textLower = obj.Text:lower()
                if not textLower:find("r%$") and not textLower:find("robux") then
                    
                    local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
                    if textPos then
                        -- Ищем кнопку в радиусе 20 стадов от текста редкости
                        local closestPrompt = nil
                        local minDist = 20
                        
                        for _, prompt in pairs(allPrompts) do
                            local promptPos = getSafePosition(prompt.Parent)
                            if promptPos then
                                local dist = (promptPos - textPos).Magnitude
                                if dist < minDist then
                                    closestPrompt = prompt
                                    minDist = dist
                                end
                            end
                        end
                        
                        -- ПРОВЕРКА 3: Не на нашей ли базе?
                        if closestPrompt then
                            local isSafe = true
                            if savedPosition then
                                if (textPos - savedPosition.Position).Magnitude < 65 then
                                    isSafe = false
                                end
                            end
                            
                            if isSafe then
                                table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos})
                            end
                        end
                    end
                end
            end
        end
    end
    return validTargets
end

-- ИНТЕРФЕЙС
MainTab:CreateButton({
   Name = "1. SAVE BASE POSITION",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "ГОТОВО", Content = "База зафиксирована!", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

MainTab:CreateSection("Zone Filter (Ignore Bases)")

MainTab:CreateToggle({
   Name = "Ignore EASY Base",
   CurrentValue = true,
   Callback = function(Value) ignoreZones["EASY"] = Value end,
})

MainTab:CreateToggle({
   Name = "Ignore NORMAL Base",
   CurrentValue = true,
   Callback = function(Value) ignoreZones["NORMAL"] = Value end,
})

-- ФУНКЦИЯ КРАЖИ (БЕЗ ИЗМЕНЕНИЙ)
local function doSteal()
    local targets = getTargets()
    if #targets > 0 then
        local target = targets[1]
        local hrp = player.Character.HumanoidRootPart
        
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.2)
        hrp.Anchored = true
        fireproximityprompt(target.p)
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
                Rayfield:Notify({Title = "ОШИБКА", Content = "Сначала сохрани базу!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1 or 2)
                end
            end)
        end
   end,
})

MainTab:CreateButton({
   Name = "DEBUG (F9)",
   Callback = function()
        local targets = getTargets()
        print("Найдено подходящих целей: " .. #targets)
   end,
})
