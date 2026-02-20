local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm HUB | REBORN",
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

-- 1. Функция проверки на Робуксы и Зоны
local function checkTarget(obj)
    local path = obj:GetFullName():lower()
    
    -- Проверка на Easy/Normal зоны
    if path:find("easy") or path:find("normal") then
        return false, "Зона Easy/Normal"
    end
    
    -- Поиск признаков доната в модели
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        for _, descendant in pairs(model:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                local t = descendant.Text:lower()
                if t:find("r$") or t:find("robux") or t:find("buy") then
                    return false, "Обнаружен донат (R$/Buy)"
                end
            end
        end
    end
    
    return true
end

-- 2. Безопасные координаты
local function getPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("BillboardGui") and obj.Adornee then return obj.Adornee.Position end
    if obj.Parent and obj.Parent:IsA("BasePart") then return obj.Parent.Position end
    return nil
end

local function getTargets()
    local targets = {}
    print("--- ЗАПУСК СКАНЕРА ---")

    for _, obj in pairs(workspace:GetDescendants()) do
        -- Ищем надпись редкости
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            local isGood, reason = checkTarget(obj)
            if isGood then
                -- Ищем кнопку в той же модели или рядом
                local parent = obj:FindFirstAncestorOfClass("Model") or obj.Parent
                local prompt = parent:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt then
                    -- Проверяем, не на нашей ли это базе
                    local pos = getPos(prompt.Parent) or getPos(obj)
                    if pos and savedPosition then
                        local distToBase = (pos - savedPosition.Position).Magnitude
                        if distToBase > 50 then -- Если дальше 50 стадов от базы
                            table.insert(targets, {p = prompt, pos = pos})
                        end
                    end
                end
            else
                -- print("Пропущено: " .. reason) -- Раскомментируй для детального лога
            end
        end
    end
    
    print("Найдено целей: " .. #targets)
    return targets
end

-- ИНТЕРФЕЙС
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
        
        -- Летим
        hrp.CFrame = CFrame.new(target.pos + Vector3.new(0, 3, 0))
        task.wait(0.2)
        hrp.Anchored = true
        
        -- Жмем
        fireproximityprompt(target.p)
        task.wait(target.p.HoldDuration + 0.3)
        
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
                Rayfield:Notify({Title = "ОШИБКА", Content = "Сначала нажми SAVE BASE!", Duration = 3})
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
