local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | ULTIMATE EDITION",
   LoadingTitle = "Запуск системы...",
   LoadingSubtitle = "Prison Blacklist Fix",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Состояние блеклиста (по умолчанию ВКЛЮЧЕНО для блокировки)
local blockEasy = true
local blockNormal = true

-- Функция получения координат (оригинал) [cite: 2]
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

-- НОВАЯ ФУНКЦИЯ ПРОВЕРКИ ИМЕНИ БАЗЫ (Глубокий поиск)
local function isInsideForbiddenBase(obj)
    local current = obj
    while current and current ~= workspace do
        local name = current.Name:lower()
        
        -- Проверяем по твоим уточненным названиям
        if blockEasy then
            if name:find("tung") or name:find("easy") then return true end
        end
        
        if blockNormal then
            if name:find("odin") or name:find("normal") then return true end
        end
        
        -- Идем выше к родителю
        current = current.Parent
    end
    return false
end

local function getTargets()
    local validTargets = {}
    local allPrompts = {}
    
    -- 1. Сбор кнопок [cite: 3]
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        end
    end

    -- 2. Поиск по редкости [cite: 4]
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- ПРОВЕРКА БЛЕКЛИСТА (ПЕРЕД ВСЕМ ОСТАЛЬНЫМ)
            if isInsideForbiddenBase(obj) then
                continue -- Полный игнор, если база в списке запрещенных
            end

            -- Анти-Робукс (оригинал) [cite: 5]
            local isPaid = false
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                for _, t in pairs(model:GetDescendants()) do
                    if t:IsA("TextLabel") then
                        local txt = t.Text:lower()
                        if txt:find("r%$") or txt:find("robux") or txt:find("buy") then
                            isPaid = true break
                        end
                    end
                end
            end

            if not isPaid then
                local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
                
                if textPos then
                    -- Поиск кнопки (оригинал) [cite: 8, 9]
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
                    
                    -- Проверка на свою базу (оригинал) [cite: 12]
                    if closestPrompt then
                        local isSafeZone = false
                        if savedPosition then
                            local distToBase = (textPos - savedPosition.Position).Magnitude
                            if distToBase < 65 then
                                isSafeZone = true
                            end
                        end
                        
                        if not isSafeZone then
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

MainTab:CreateSection("Zone Blacklist (STRICT)")

MainTab:CreateToggle({
   Name = "Block Tung's Prison (EASY)",
   CurrentValue = true,
   Callback = function(Value) blockEasy = Value end,
})

MainTab:CreateToggle({
   Name = "Block Odin's Prison (NORMAL)",
   CurrentValue = true,
   Callback = function(Value) blockNormal = Value end,
})

-- АВТОФАРМ (Оригинал) [cite: 18, 19]
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
