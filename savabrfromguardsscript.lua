local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | DEBUG EDITION",
   LoadingTitle = "alphaversion so mb doesnt work rn",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- 1. УМНЫЙ ФИЛЬТР (ЗОНЫ И РОБУКСЫ)
local function getTargetStatus(obj)
    local fullName = obj:GetFullName():lower()
    
    -- Проверка на запрещенные зоны
    if fullName:find("easy") or fullName:find("normal") then
        return false, "Зона: Easy/Normal"
    end
    
    -- Ищем признаки робуксов ТОЛЬКО внутри модели моба
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        for _, item in pairs(model:GetDescendants()) do
            if item:IsA("TextLabel") then
                local text = item.Text:lower()
                if text:find("r%$") or text:find("robux") or text:find("buy") then
                    return false, "Платный (Найдено: " .. item.Text .. ")"
                end
            end
        end
    end
    
    return true, "OK"
end

-- 2. ПОЛУЧЕНИЕ КООРДИНАТ
local function getSafePosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function getTargets()
    local validTargets = {}
    print("--- НОВЫЙ ЦИКЛ ПОИСКА ---")
    
    -- Сначала находим ВСЕ надписи с нужной редкостью
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            local isGood, reason = getTargetStatus(obj)
            
            if isGood then
                -- Если моб бесплатный, ищем кнопку ВНУТРИ его модели
                local model = obj:FindFirstAncestorOfClass("Model")
                local prompt = model and model:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                -- Если в модели нет, ищем ближайшую в радиусе 20 стадов
                if not prompt then
                    for _, p in pairs(workspace:GetDescendants()) do
                        if p:IsA("ProximityPrompt") then
                            local pPos = getSafePosition(p.Parent)
                            local tPos = getSafePosition(obj)
                            if pPos and tPos and (pPos - tPos).Magnitude < 20 then
                                prompt = p break
                            end
                        end
                    end
                end

                if prompt then
                    local pos = getSafePosition(prompt.Parent)
                    -- Проверка на расстояние от базы (чтобы не воровать у себя)
                    if savedPosition and pos then
                        if (pos - savedPosition.Position).Magnitude > 50 then
                            table.insert(validTargets, {p = prompt, pos = pos})
                        else
                            -- print("Пропуск: Слишком близко к твоей базе")
                        end
                    end
                else
                    print("Предупреждение: Не нашел кнопку для " .. obj.Text)
                end
            else
                -- Это сообщение объяснит, почему God игнорируется
                print("Игнор " .. obj.Text .. " | Причина: " .. reason)
            end
        end
    end
    
    print("ИТОГО: Найдено рабочих целей: " .. #validTargets)
    return validTargets
end

-- 3. ИНТЕРФЕЙС
MainTab:CreateButton({
   Name = "1. SAVE BASE POSITION",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "ОК", Content = "База сохранена!", Duration = 3})
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
                Rayfield:Notify({Title = "СТОП", Content = "Нажми кнопку 1!", Duration = 3})
                return 
            end
            task.spawn(function()
                while autoCollectEnabled do
                    local success = doSteal()
                    task.wait(success and 1.5 or 2.5)
                end
            end)
        end
   end,
})
