local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | FINAL FIX",
   LoadingTitle = "Запуск принудительного фарма...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- ГЛОБАЛЬНЫЙ ПОИСК ЦЕЛЕЙ
local function getTargets()
    local validTargets = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        -- 1. Ищем текст редкости
        if obj:IsA("TextLabel") and string.find(obj.Text:lower(), selectedRarity:lower()) then
            -- 2. Ищем ближайшую кнопку в радиусе 15 единиц
            local model = obj:FindFirstAncestorOfClass("Model") or obj.Parent
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local promptPos = (prompt.Parent:IsA("BasePart") and prompt.Parent.Position) or (prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition)
                    local textPos = obj.Parent.WorldPosition
                    
                    if promptPos and (promptPos - textPos).Magnitude < 15 then
                        -- 3. ФИЛЬТРЫ (SafeZone и Анти-Робукс)
                        local isPaid = string.find(obj.Text:lower(), "rbx") or string.find(obj.Text:lower(), "r%$")
                        
                        -- Проверка на SafeZone (если мы сохранили позицию)
                        local isNearBase = false
                        if savedPosition then
                            local distToBase = (promptPos - savedPosition.Position).Magnitude
                            if distToBase < 50 then isNearBase = true end -- Если ближе 50 метров к базе - игнор
                        end

                        if not isPaid and not isNearBase then
                            table.insert(validTargets, {p = prompt, m = model})
                        end
                    end
                end
            end
        end
    end
    return validTargets
end

MainTab:CreateButton({
   Name = "1. SAVE BASE POSITION (DO THIS FIRST)",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "СИСТЕМА", Content = "База сохранена. Скрипт будет игнорировать цели рядом с ней.", Duration = 3})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. SELECT RARITY",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

-- Функция самого действия
local function doSteal()
    local targets = getTargets()
    if #targets > 0 then
        local target = targets[1] -- Берем первую найденную
        local hrp = player.Character.HumanoidRootPart
        
        -- ТП и заморозка
        hrp.CFrame = (target.p.Parent:IsA("BasePart") and target.p.Parent.CFrame) or target.m.HumanoidRootPart.CFrame
        task.wait(0.2)
        hrp.Anchored = true
        
        -- Активация
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.5)
        
        -- Домой
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
                Rayfield:Notify({Title = "ОШИБКА", Content = "Сначала сохрани позицию базы!", Duration = 5})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 2 or 1) -- Если украл - пауза 2 сек, если не нашел - 1 сек.
                end
            end)
        end
   end,
})

-- КНОПКА ОТЛАДКИ (ЕСЛИ ОПЯТЬ НИЧЕГО НЕ ПРОИСХОДИТ)
MainTab:CreateButton({
   Name = "DEBUG: SCAN MAP (PRESS F9)",
   Callback = function()
        print("--- ОТЧЕТ СКАНЕРА ---")
        local targets = getTargets()
        print("Найдено подходящих целей: " .. #targets)
        for i, t in pairs(targets) do
            print(i .. ". Кнопка найдена в: " .. t.p:GetFullName())
        end
        print("---------------------")
   end,
})
