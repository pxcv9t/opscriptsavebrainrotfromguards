local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | RADAR EDITION",
   LoadingTitle = "Запуск радара...",
   LoadingSubtitle = "Distance Blacklist",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

local ignoreEasy = true
local ignoreNormal = true

-- Оригинальная функция получения координат
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
    local allPrompts = {}
    
    -- Списки опасных координат
    local badZonePositions = {}
    local paidPositions = {}

    -- 1. СКАНИРОВАНИЕ КАРТЫ (Один проход для сбора всех меток)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(allPrompts, obj)
        elseif obj:IsA("TextLabel") then
            local txtUpper = obj.Text:upper()
            local txtLower = obj.Text:lower()
            
            -- Ищем координаты вывесок баз (включая их названия из твоих скриншотов)
            if ignoreEasy and (txtUpper == "EASY" or txtUpper:find("TUNG'S")) then
                local pos = getSafePosition(obj)
                if pos then table.insert(badZonePositions, pos) end
            end
            if ignoreNormal and (txtUpper == "NORMAL" or txtUpper:find("ODIN DIN DUN")) then
                local pos = getSafePosition(obj)
                if pos then table.insert(badZonePositions, pos) end
            end
            
            -- Ищем координаты любых табличек с донатом
            if txtLower:find("r%$") or txtLower:find("robux") or txtLower:find("buy") then
                local pos = getSafePosition(obj)
                if pos then table.insert(paidPositions, pos) end
            end
        end
    end

    -- 2. ПОИСК ЦЕЛЕЙ И ФИЛЬТРАЦИЯ
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
            if not textPos then continue end

            -- ФИЛЬТР 1: Блеклист Баз (Радиус 120 стадов от вывески)
            local inBadZone = false
            for _, badPos in pairs(badZonePositions) do
                if (textPos - badPos).Magnitude < 120 then
                    inBadZone = true
                    break
                end
            end
            if inBadZone then continue end -- Пропускаем, если слишком близко к EASY/NORMAL

            -- ФИЛЬТР 2: Анти-Робукс (Радиус 30 стадов от таблички доната)
            local isPaid = false
            for _, paidPos in pairs(paidPositions) do
                if (textPos - paidPos).Magnitude < 30 then
                    isPaid = true
                    break
                end
            end
            if isPaid then continue end -- Пропускаем, если рядом донат

            -- ПОИСК КНОПКИ (Логика оригинала)
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
            
            -- ПРОВЕРКА НА БЕЗОПАСНУЮ ЗОНУ И ДОБАВЛЕНИЕ (Логика оригинала)
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
    return validTargets
end

-- UI ИНТЕРФЕЙС
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

MainTab:CreateSection("Zone Blacklist (Distance Radar)")

MainTab:CreateToggle({
   Name = "Block EASY Base",
   CurrentValue = true,
   Callback = function(Value) ignoreEasy = Value end,
})

MainTab:CreateToggle({
   Name = "Block NORMAL Base",
   CurrentValue = true,
   Callback = function(Value) ignoreNormal = Value end,
})

-- АВТОФАРМ (Полностью твой оригинал)
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
