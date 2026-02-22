local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "KAITO HUB | RADAR EDITION (SAFE)",
    LoadingTitle = "Запуск радара...",
    LoadingSubtitle = "by Gemini",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false
local minFarmDistance = 70 -- Минимальная дистанция от базы для фарма (метры)

-- Функция безопасного получения координат
local function getSafePosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("BillboardGui") or obj:IsA("TextLabel") then
        if obj:IsA("BillboardGui") and obj.Adornee then return getSafePosition(obj.Adornee) end
        if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    end
    return nil
end

-- УЛУЧШЕННАЯ функция проверки на платность
local function isPaidItem(model, prompt)
    local paidKeywords = {"robux", "r%$", "r %", "buy", "purchase", "premium", "cost", "price", "paid", "vip", "deluxe", "upgrade", "unlock for", "get for", "₽"}
    local freeKeywords = {"free", "claim", "collect", "take", "steal"}
    
    -- 1. Проверка текстов внутри модели
    if model then
        for _, t in pairs(model:GetDescendants()) do
            if t:IsA("TextLabel") or t:IsA("TextButton") then
                local txt = t.Text:lower()
                
                -- Сначала проверяем на бесплатное (приоритет)
                for _, key in pairs(freeKeywords) do
                    if txt:find(key:lower()) then
                        return false -- Это бесплатное!
                    end
                end
                
                -- Потом проверяем на платное
                for _, key in pairs(paidKeywords) do
                    if txt:find(key:lower()) then
                        return true -- Это платное!                    end
                end
            end
        end
    end

    -- 2. Проверка ProximityPrompt
    if prompt then
        local actionText = prompt.ActionText:lower()
        local promptText = prompt.PromptText:lower()
        local combinedText = actionText .. " " .. promptText
        
        -- Проверяем на бесплатное
        for _, key in pairs(freeKeywords) do
            if combinedText:find(key:lower()) then
                return false
            end
        end
        
        -- Проверяем на платное
        for _, key in pairs(paidKeywords) do
            if combinedText:find(key:lower()) then
                return true
            end
        end
    end

    return false -- По умолчанию считаем бесплатным
end

local function getTargets()
    local validTargets = {}
    local allPrompts = {}
    
    -- 1. Собираем все кнопки на карте (один раз, чтобы не лагало)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- 2. Ищем текст с нужной редкостью
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            local model = obj:FindFirstAncestorOfClass("Model")
            local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
            
            if not textPos then continue end
                        -- 3. ПРОВЕРКА ЗОНЫ - фармим ТОЛЬКО то что ДАЛЬШЕ от базы
            if savedPosition then
                local distToBase = (textPos - savedPosition.Position).Magnitude
                local distInMeters = distToBase / 10 -- Примерно 10 studs = 1 meter
                
                -- Если объект СЛИШКОМ БЛИЗКО к базе - пропускаем (это сейф зона)
                if distInMeters < minFarmDistance then
                    continue
                end
            end

            -- 4. Ищем ближайшую кнопку к этому тексту (в радиусе 25 стадов)
            local closestPrompt = nil
            local minDist = 25
            
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

            if closestPrompt then
                -- 5. ПРОВЕРКА АНТИ-РОБУКС
                if isPaidItem(model, closestPrompt) then
                    continue -- Пропускаем платные
                end

                table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos})
            end
        end
    end
    return validTargets
end

MainTab:CreateButton({
    Name = "1. SAVE BASE POSITION",
    Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "OK", Content = "База сохранена! Фарм будет ЗА этой зоной (дальше " .. minFarmDistance .. "м)", Duration = 3})
        end
    end,
})

MainTab:CreateSlider({    Name = "Минимальная дистанция фарма (метров)",
    StartingValue = minFarmDistance,
    Range = {50, 200},
    Increment = 5,
    Callback = function(Value)
        minFarmDistance = Value
    end,
})

MainTab:CreateDropdown({
    Name = "2. SELECT RARITY",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
    CurrentOption = {"God"},
    Callback = function(Option) selectedRarity = Option[1] end,
})

local function doSteal()
    local targets = getTargets()
    if #targets > 0 then
        local target = targets[1]
        local hrp = player.Character.HumanoidRootPart
        
        -- Летим к кнопке
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0))
        task.wait(0.2)
        
        hrp.Anchored = true
        
        -- Взлом
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.3)
        
        -- Домой
        hrp.Anchored = false
        if savedPosition then
            hrp.CFrame = savedPosition
        end
        
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
            if not savedPosition then                Rayfield:Notify({Title = "СТОП", Content = "Нажми SAVE BASE POSITION!", Duration = 3})
                autoCollectEnabled = false
                return
            end
            
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1.5 or 2)
                end
            end)
        end
    end,
})

-- КНОПКА ОТЛАДКИ
MainTab:CreateButton({
    Name = "DEBUG: ПРОВЕРКА ЦЕЛЕЙ",
    Callback = function()
        print("--- СКАНИРОВАНИЕ КАРТЫ ---")
        if not savedPosition then 
            print("ОШИБКА: База не сохранена!") 
            return 
        end
        
        local targets = getTargets()
        print("Найдено бесплатных целей (" .. selectedRarity .. "): " .. #targets)
        
        if #targets == 0 then
            print("Возможные причины:")
            print("1. Нет диких объектов с редкостью " .. selectedRarity .. " за пределами " .. minFarmDistance .. "м")
            print("2. Все объекты помечены как ПЛАТНЫЕ (сработал Анти-Робукс)")
            print("3. Попробуй уменьшить дистанцию фарма")
        else
            print("Цели есть! Автофарм должен работать.")
        end
        print("--------------------------")
    end,
})

Rayfield:Notify({
    Title = "KAITO HUB ЗАГРУЖЕН", 
    Content = "1. Сохрани позицию базы\n2. Выбери редкость\n3. Настрой дистанцию\n4. Запусти автофарм", 
    Duration = 5
})
