local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "KAITO HUB | RADAR EDITION (SAFE)",
    LoadingTitle = "Запуск радара...",
    LoadingSubtitle = "by Gemini (Anti-Robux Enhanced)",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false
local minFarmDistance = 70 -- Минимальное расстояние от базы для фарма (тюрьмы ПОСЛЕ сейф зоны)

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
    local paidKeywords = {
        "robux", "r$", "r %", "%r", "buy", "purchase", "premium", "cost", "price", 
        "paid", "vip", "deluxe", "upgrade", "unlock for", "get for", "₽", "USD"
    }
    
    local freeKeywords = {"free", "claim", "collect", "take", "steal"}
    
    -- 1. Проверка текстов внутри модели
    if model then
        for _, t in pairs(model:GetDescendants()) do
            if t:IsA("TextLabel") or t:IsA("TextButton") then
                local txt = t.Text:lower()
                
                -- Сначала проверяем на бесплатное
                for _, key in pairs(freeKeywords) do
                    if txt:find(key:lower()) then
                        return false -- Это бесплатное!
                    end
                end
                                -- Потом проверяем на платное
                for _, key in pairs(paidKeywords) do
                    if txt:find(key:lower()) then
                        return true -- Это платное!
                    end
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
    
    -- 1. Собираем все ProximityPrompt на карте
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- 2. Ищем текст с нужной редкостью
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            local model = obj:FindFirstAncestorOfClass("Model")            local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
            
            if not textPos then continue end
            
            -- 3. ПРОВЕРКА ЗОНЫ - фармим ТОЛЬКО то что ДАЛЬШЕ от базы (после сейф зоны)
            if savedPosition then
                local distToBase = (textPos - savedPosition.Position).Magnitude
                
                -- Если объект СЛИШКОМ БЛИЗКО к базе - пропускаем (это сейф зона)
                if distToBase < minFarmDistance then
                    continue
                end
            end

            -- 4. Ищем ближайшую кнопку к тексту
            local closestPrompt = nil
            local minDist = 30
            
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

                -- Добавляем валидную цель
                table.insert(validTargets, {
                    p = closestPrompt, 
                    pos = getSafePosition(closestPrompt.Parent) or textPos,
                    name = obj.Text
                })
            end
        end
    end
    return validTargets
end

MainTab:CreateButton({
    Name = "1. SAVE BASE POSITION (СТОЙ ЗДЕСЬ)",
    Callback = function()        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({
                Title = "БАЗА СОХРАНЕНА", 
                Content = "Фарм будет происходить ЗА этой зоной (дальше " .. minFarmDistance .. " метров)", 
                Duration = 4
            })
        end
    end,
})

MainTab:CreateSlider({
    Name = "Минимальная дистанция фарма (метров)",
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
        
        -- Показываем информацию
        print("Цель найдена: " .. (target.name or "Unknown") .. " | Дистанция: " .. math.floor((target.pos - hrp.Position).Magnitude))
        
        -- Телепорт к кнопке
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0))
        task.wait(0.3)
        
        -- Фиксация позиции
        hrp.Anchored = true
        
        -- Взлом
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.5)
        
        -- Возврат на базу        hrp.Anchored = false
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
            if not savedPosition then
                Rayfield:Notify({
                    Title = "ОШИБКА", 
                    Content = "Сначала нажми 'SAVE BASE POSITION'!", 
                    Duration = 3
                })
                autoCollectEnabled = false
                return
            end
            
            Rayfield:Notify({
                Title = "АВТОФАРМ ЗАПУЩЕН", 
                Content = "Фарм целей за пределами сейф зоны...", 
                Duration = 2
            })
            
            task.spawn(function()
                while autoCollectEnabled do
                    local success = pcall(function()
                        return doSteal()
                    end)
                    
                    if success then
                        task.wait(1.5)
                    else
                        task.wait(2)
                    end
                end
            end)
        end
    end,
})
MainTab:CreateButton({
    Name = "DEBUG: ПРОВЕРКА ЦЕЛЕЙ",
    Callback = function()
        print("\n========== СКАНИРОВАНИЕ КАРТЫ ==========")
        
        if not savedPosition then 
            print("❌ ОШИБКА: База не сохранена! Нажми кнопку SAVE BASE POSITION")
            return 
        end
        
        print("✓ База сохранена на позиции: " .. tostring(savedPosition.Position))
        print("✓ Минимальная дистанция фарма: " .. minFarmDistance .. " метров")
        print("✓ Ищем редкость: " .. selectedRarity)
        
        local targets = getTargets()
        print("\n✓ Найдено бесплатных целей (" .. selectedRarity .. "): " .. #targets)
        
        if #targets == 0 then
            print("\nВозможные причины:")
            print("1. Нет объектов с редкостью " .. selectedRarity .. " за пределами сейф зоны")
            print("2. Все объекты помечены как ПЛАТНЫЕ (сработал Анти-Робукс)")
            print("3. Увеличь 'Минимальную дистанцию фарма' если фармится не то")
            print("4. Поменяй редкость в dropdown")
        else
            print("\n✓ Первые 5 целей:")
            for i = 1, math.min(5, #targets) do
                local t = targets[i]
                local dist = math.floor((t.pos - savedPosition.Position).Magnitude)
                print("  " .. i .. ". " .. (t.name or "Unknown") .. " | Дистанция: " .. dist .. "м")
            end
            print("\n✓ Автофарм должен работать!")
        end
        
        print("========================================\n")
    end,
})

Rayfield:Notify({
    Title = "KAITO HUB ЗАГРУЖЕН", 
    Content = "1. Сохрани позицию базы\n2. Выбери редкость\n3. Запусти автофарм", 
    Duration = 5
})
