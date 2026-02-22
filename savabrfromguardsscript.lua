local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | COORDINATE EDITION",
   LoadingTitle = "Запуск по координатам...",
   LoadingSubtitle = "Boundary System",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- НАСТРОЙКА ГРАНИЦЫ
local minX = 303.58 -- Твоя точка отсчета. Все, что меньше этого по X, игнорируется.
local useCoordinateFilter = true

-- Функция безопасного получения координат (оригинал)
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

-- Проверка на "платность" (по тексту и значкам)
local function isPaidTarget(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if model then
        for _, t in pairs(model:GetDescendants()) do
            if t:IsA("TextLabel") then
                local txt = t.Text:lower()
                if txt:find("r%$") or txt:find("robux") or txt:find("buy") or txt:find("pay") then
                    return true
                end
            end
            if t:IsA("ImageLabel") and (t.Image:find("robux") or t.Image:find("rbx")) then
                return true
            end
        end
    end
    return false
end

local function getTargets()
    local validTargets = {}
    local allPrompts = {}
    
    -- Собираем кнопки
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then table.insert(allPrompts, obj) end
    end

    -- Ищем по редкости
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            local textPos = getSafePosition(obj)
            if textPos then
                -- === ФИЛЬТР КООРДИНАТ ===
                -- Если X бреинрота меньше 303.58, мы его скипаем (это база сзади)
                if useCoordinateFilter and textPos.X < minX then
                    continue 
                end

                -- ПРОВЕРКА НА РОБУКСЫ
                if not isPaidTarget(obj) then
                    
                    -- Поиск кнопки рядом (оригинал)
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
                    
                    -- Проверка на свою базу (оригинал)
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
    return validTargets
end

-- ИНТЕРФЕЙС
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

MainTab:CreateSection("Filters")

MainTab:CreateToggle({
   Name = "Use Coordinate Gate (X > 303)",
   CurrentValue = true,
   Callback = function(Value) useCoordinateFilter = Value end,
})

-- АВТОФАРМ
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
