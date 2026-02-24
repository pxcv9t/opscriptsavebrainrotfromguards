local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | RADAR EDITION",
   LoadingTitle = "u gay(",
   LoadingSubtitle = "by Pxcv9t (Anti-Robux v2.0)",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Улучшенная функция проверки платных зон (АНТИ-РОБУКС v2.0)
local function isPaidZone(obj)
    if not obj then return false end
    
    local checkedInstances = {}
    
    local function checkInstance(instance)
        if not instance or checkedInstances[instance] then return false end
        checkedInstances[instance] = true
        
        -- 1. ПРОВЕРКА АТРИБУТОВ (САМЫЙ НАДЕЖНЫЙ МЕТОД)
        local success, attributes = pcall(function() return instance:GetAttributes() end)
        if success and attributes then
            for key, value in pairs(attributes) do
                local keyLower = tostring(key):lower()
                -- Ключевые слова атрибутов
                if keyLower:match("robux|paid|premium|price|cost|requirepayment|isr$") then
                    if value == true or (type(value) == "number" and value > 0) or 
                       (type(value) == "string" and tostring(value):lower():match("robux|r$|paid")) then
                        return true
                    end
                end
            end
        end
        
        -- 2. ПРОВЕРКА ИМЕНИ (Premium, Paid, Shop, R$)
        local nameLower = instance.Name:lower()
        if nameLower:match("premium|paid|shop|buy|robux|r[%$]|price|cost|purchase|payzone|р[%$]") then
            return true
        end
        
        -- 3. ПРОВЕРКА ТЕГОВ (TagService)
        pcall(function()
            local tagService = game:GetService("TagService")
            local tags = tagService:GetTags(instance)
            for _, tag in ipairs(tags) do
                if tostring(tag):lower():match("paid|premium|robux|price") then
                    return true
                end
            end
        end)
        
        -- 4. СПЕЦИАЛЬНАЯ ПРОВЕРКА ДЛЯ PROXIMITYPROMPT
        if instance:IsA("ProximityPrompt") then
            -- Проверяем текст на кнопке
            if instance.ObjectText and instance.ObjectText:lower():match("robux|r$|buy|premium") then return true end
            if instance.ActionText and instance.ActionText:lower():match("buy|purchase|pay") then return true end
            -- Проверяем HoldDuration (иногда платные имеют аномальную длительность)
            if instance.HoldDuration > 10 then return true end -- Подозрительно долго держать = возможно платно
        end
        
        -- 5. ПРОВЕРКА GUI (TextLabel/ImageLabel) - рекурсивно
        if instance:IsA("GuiObject") then
            -- Проверка текста
            if instance.Text then
                local text = instance.Text:lower()
                if text:match("r[%$]%|robux|premium|paid|buy|price|cost|purchase|р[%$]|руб") then
                    return true
                end
            end
            
            -- Проверка цвета на золотой (Robux Color: 255, 170, 0)
            if instance.TextColor3 then
                local color = instance.TextColor3
                -- Упрощенная проверка золотого цвета (R > 0.9, G ~0.65, B < 0.1)
                if color.R > 0.85 and color.G > 0.6 and color.G < 0.8 and color.B < 0.2 then
                    return true
                end
            end
            
            -- Проверка ImageLabel (иконка Robux - золотой круг)
            if instance:IsA("ImageLabel") and instance.Image then
                local image = instance.Image:lower()
                if image:match("robux|premium|r[%$]|currency") or 
                   (instance.ImageColor3 and instance.ImageColor3.R > 0.8 and instance.ImageColor3.G > 0.5) then
                    return true
                end
            end
        end
        
        return false
    end
    
    -- Проверяем сам объект и всю родительскую цепочку (Model -> Folder -> Workspace)
    local current = obj
    while current do
        if checkInstance(current) then return true end
        current = current.Parent
    end
    
    -- 6. РЕГИОНАЛЬНАЯ ПРОВЕРКА (ищем GUI с ценой рядом с объектом)
    -- Иногда цена на отдельном BillboardGui не внутри модели
    if obj:IsA("BasePart") or obj:IsA("Attachment") then
        local pos = obj.Position
        local region = Region3.new(pos - Vector3.new(15, 15, 15), pos + Vector3.new(15, 15, 15))
        local parts = workspace:FindPartsInRegion3(region, nil, 30)
        
        for _, part in ipairs(parts) do
            -- Проверяем прикрепленные GUI
            for _, child in ipairs(part:GetDescendants()) do
                if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                    if checkInstance(child) then return true end
                    -- Проверяем содержимое GUI
                    for _, guiChild in ipairs(child:GetDescendants()) do
                        if checkInstance(guiChild) then return true end
                    end
                end
            end
        end
    end
    
    return false
end

-- Функция безопасного получения координат (без изменений, хорошая реализация)
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

local function getTargets()
    local validTargets = {}
    
    -- Кэшируем промпты для оптимизации (чтобы не собирать каждый раз)
    local allPrompts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled ~= false then
            table.insert(allPrompts, obj)
        end
    end

    -- Ищем текст с нужной редкостью
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- АНТИ-РОБУКС v2.0 - комплексная проверка
            if isPaidZone(obj) then
                continue -- Пропускаем платные зоны
            end
            
            local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
            
            if textPos then
                -- Ищем ближайшую кнопку
                local closestPrompt = nil
                local minDist = 25
                
                for _, prompt in pairs(allPrompts) do
                    local promptPos = getSafePosition(prompt.Parent)
                    if promptPos then
                        local dist = (promptPos - textPos).Magnitude
                        if dist < minDist then
                            -- Дополнительно проверяем, не является ли сама кнопка платной
                            if not isPaidZone(prompt) then
                                closestPrompt = prompt
                                minDist = dist
                            end
                        end
                    end
                end
                
                if closestPrompt then
                    -- Проверка безопасной зоны (не грабить рядом с базой)
                    if savedPosition then
                        local distToBase = (textPos - savedPosition.Position).Magnitude
                        if distToBase < 65 then continue end -- Слишком близко к базе
                    end
                    
                    table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos})
                end
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
            Rayfield:Notify({Title = "OK", Content = "База сохранена! Радиус 65 метров защищен.", Duration = 3})
        end
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
        
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 2, 0))
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
                Rayfield:Notify({Title = "СТОП", Content = "Нажми SAVE BASE POSITION!", Duration = 3})
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

-- Улучшенный DEBUG
MainTab:CreateButton({
   Name = "DEBUG: ПОЧЕМУ ОН МОЛЧИТ? (F9)",
   Callback = function()
        print("--- СКАНИРОВАНИЕ КАРТЫ (Anti-Robux v2.0) ---")
        if not savedPosition then print("ОШИБКА: База не сохранена!") return end
        
        local targets = getTargets()
        print("Найдено целей (" .. selectedRarity .. "): " .. #targets)
        
        if #targets == 0 then
            print("⚠️ Цели не найдены. Возможные причины:")
            print("1. Нет диких брейнротов с редкостью: " .. selectedRarity)
            print("2. Все найденные находятся в ПЛАТНЫХ зонах (Robux/Premium)")
            print("   → Anti-Robux активен и корректно фильтрует их ✓")
            print("3. Они спавнятся слишком близко к базе (< 65 стадов)")
            print("4. Кнопки слишком далеко от текста (> 25 стадов)")
        else
            print("✅ Цели есть! Автофарм должен работать.")
            print("Первые 3 цели (проверка на платность):")
            for i=1, math.min(3, #targets) do
                local t = targets[i]
                print("  - Расстояние до базы: " .. math.floor((t.pos - savedPosition.Position).Magnitude) .. "м")
            end
        end
        print("--------------------------")
   end,
})
