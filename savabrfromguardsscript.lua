local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | PLAN B",
   LoadingTitle = "Запуск...",
   LoadingSubtitle = "Blacklist Edition",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- ЧЁРНЫЙ СПИСОК ЗОН (По умолчанию включены Easy и Normal)
local zoneBlacklist = {
    ["EASY"] = true,
    ["NORMAL"] = true,
    ["HARD"] = false
}

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

-- ПРОВЕРКА: Не находится ли цель в запретной зоне (EASY/NORMAL)
local function isInsideBadZone(targetObj)
    local current = targetObj
    -- Проверяем 8 уровней вверх по иерархии (ищем модель базы)
    for i = 1, 8 do
        if not current or current == workspace then break end
        
        -- Ищем текстовые надписи в этой модели
        for _, child in pairs(current:GetChildren()) do
            if child:IsA("TextLabel") or (child:IsA("BillboardGui") and child:FindFirstChildOfClass("TextLabel")) then
                local label = child:IsA("TextLabel") and child or child:FindFirstChildOfClass("TextLabel")
                local txt = label.Text:upper()
                
                for zoneName, isIgnored in pairs(zoneBlacklist) do
                    if isIgnored and txt:find(zoneName) then
                        return true -- Нашли надпись EASY/NORMAL, цель в черном списке
                    end
                end
            end
        end
        current = current.Parent
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

    -- Ищем нужную редкость
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- ШАГ 1: Проверка зоны (Easy/Normal)
            if not isInsideBadZone(obj) then
                
                -- ШАГ 2: Анти-Робукс (проверка на текст "Buy" или символ R$)
                local isPaid = false
                local model = obj:FindFirstAncestorOfClass("Model")
                if model then
                    for _, t in pairs(model:GetDescendants()) do
                        if t:IsA("TextLabel") then
                            local txt = t.Text:lower()
                            if txt:find("r%$") or txt:find("robux") or txt:find("buy") then
                                isPaid = true 
                                break
                            end
                        end
                    end
                end

                if not isPaid then
                    local textPos = getSafePosition(obj)
                    if textPos then
                        -- Ищем кнопку рядом с этим текстом
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
                        
                        -- Финальная проверка: не на базе ли игрока (Safe Zone)
                        if closestPrompt then
                            local isSafeZone = false
                            if savedPosition then
                                local distToBase = (textPos - savedPosition.Position).Magnitude
                                if distToBase < 65 then isSafeZone = true end
                            end
                            
                            if not isSafeZone then
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

-- UI ЭЛЕМЕНТЫ
MainTab:CreateButton({
   Name = "1. SAVE BASE POSITION",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "OK", Content = "База сохранена!", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

MainTab:CreateSection("Zone Blacklist (Ignore)")

MainTab:CreateToggle({
   Name = "Ignore EASY Base",
   CurrentValue = true,
   Callback = function(Value) zoneBlacklist["EASY"] = Value end,
})

MainTab:CreateToggle({
   Name = "Ignore NORMAL Base",
   CurrentValue = true,
   Callback = function(Value) zoneBlacklist["NORMAL"] = Value end,
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
                Rayfield:Notify({Title = "Ошибка", Content = "Сначала нажми SAVE BASE!", Duration = 3})
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
