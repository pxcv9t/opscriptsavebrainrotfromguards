local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | RADAR EDITION",
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

-- Настройки блеклиста зон
local zoneBlacklist = {
    ["Easy"] = true,   -- По умолчанию включено (игнорируем)
    ["Normal"] = true, -- По умолчанию включено (игнорируем)
    ["Hard"] = false
}

-- Функция безопасного получения координат [cite: 2]
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

-- Проверка: не находится ли объект в запрещенной зоне
local function isInBlacklistedZone(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if not model then return false end
    
    -- Проверяем все текстовые метки внутри модели этой базы [cite: 4, 5]
    for _, desc in pairs(model:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local txt = desc.Text:upper()
            for zoneName, isEnabled in pairs(zoneBlacklist) do
                if isEnabled and txt == zoneName:upper() then
                    return true -- Нашли надпись "EASY" или "NORMAL", зона в блеклисте
                end
            end
        end
    end
    return false
end

local function getTargets()
    local validTargets = {}
    
    -- 1. Собираем все кнопки на карте [cite: 2, 3]
    local allPrompts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- 2. Ищем текст с нужной редкостью [cite: 4]
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- ПРОВЕРКА ЗОНЫ (План Б)
            if not isInBlacklistedZone(obj) then
                local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
                
                if textPos then
                    -- 3. Ищем ближайшую кнопку [cite: 7, 8]
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
                    
                    -- 4. Проверка на дистанцию от базы игрока [cite: 11, 12]
                    if closestPrompt then
                        local isSafeZone = false
                        if savedPosition then
                            local distToBase = (textPos - savedPosition.Position).Magnitude [cite: 12]
                            if distToBase < 65 then
                                isSafeZone = true
                            end
                        end
                        
                        if not isSafeZone then
                            table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos}) [cite: 14]
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

-- НОВЫЙ РАЗДЕЛ БЛЕКЛИСТА
MainTab:CreateSection("ZONE BLACKLIST (Ignore bases)")

MainTab:CreateToggle({
   Name = "Ignore EASY Base",
   CurrentValue = true,
   Callback = function(Value) zoneBlacklist["Easy"] = Value end,
})

MainTab:CreateToggle({
   Name = "Ignore NORMAL Base",
   CurrentValue = true,
   Callback = function(Value) zoneBlacklist["Normal"] = Value end,
})

-- АВТОФАРМ (БЕЗ ИЗМЕНЕНИЙ ЛОГИКИ)
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
                Rayfield:Notify({Title = "СТОП", Content = "Сначала сохрани базу!", Duration = 3})
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

MainTab:CreateButton({
   Name = "DEBUG (F9)",
   Callback = function()
        print("--- СКАНИРОВАНИЕ ---")
        local targets = getTargets()
        print("Найдено целей (не в блеклисте): " .. #targets)
   end,
})
