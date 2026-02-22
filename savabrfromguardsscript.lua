local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | FINAL FIX",
   LoadingTitle = "Загрузка систем...",
   LoadingSubtitle = "Anti-Base & Anti-Robux",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Настройки блокировки
local blockEasy = true
local blockNormal = true

-- Функция получения координат (оригинал) [cite: 1, 2]
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

-- 1. ПРОВЕРКА НА ЧУЖУЮ БАЗУ (Глубокий поиск по именам Tung/Odin/Easy/Normal)
local function isInsideForbiddenBase(obj)
    local current = obj
    while current and current ~= workspace do
        local name = current.Name:lower()
        if blockEasy and (name:find("tung") or name:find("easy")) then return true end
        if blockNormal and (name:find("odin") or name:find("normal")) then return true end
        current = current.Parent
    end
    return false
end

-- 2. ПРОВЕРКА НА РОБУКСЫ (Смотрим на саму кнопку и её содержимое)
local function isPaidPrompt(prompt)
    -- Проверяем текст на самой кнопке
    local combinedText = (prompt.ActionText .. prompt.ObjectText):lower()
    if combinedText:find("r%$") or combinedText:find("robux") or combinedText:find("buy") then
        return true
    end
    
    -- Проверяем, нет ли значков доната внутри модели кнопки (для кастомных UI) [cite: 4, 5]
    local parent = prompt.Parent
    if parent then
        for _, item in pairs(parent:GetDescendants()) do
            if item:IsA("ImageLabel") and (item.Image:find("robux") or item.Image:find("rbx")) then
                return true
            end
            if item:IsA("TextLabel") then
                local t = item.Text:lower()
                if t:find("r%$") or t:find("robux") then return true end
            end
        end
    end
    return false
end

local function getTargets()
    local validTargets = {}
    local allPrompts = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then table.insert(allPrompts, obj) end
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        -- Ищем нужную редкость [cite: 7]
        if obj:IsA("TextLabel") and obj.Text:lower():find(selectedRarity:lower()) then
            
            -- ШАГ 1: Сразу отсекаем по базе (Tung/Odin)
            if isInsideForbiddenBase(obj) then continue end

            local textPos = getSafePosition(obj) or (obj.Parent and getSafePosition(obj.Parent))
            if textPos then
                -- ШАГ 2: Ищем ближайшую кнопку [cite: 8, 9]
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
                
                -- ШАГ 3: Проверка кнопки на донат и свою базу [cite: 11, 12]
                if closestPrompt and not isPaidPrompt(closestPrompt) then
                    local isSafe = true
                    if savedPosition then
                        if (textPos - savedPosition.Position).Magnitude < 65 then
                            isSafe = false -- Слишком близко к твоей базе [cite: 13]
                        end
                    end
                    
                    if isSafe then
                        table.insert(validTargets, {p = closestPrompt, pos = getSafePosition(closestPrompt.Parent) or textPos})
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
                    end
                    task.wait(1.5)
                end
            end)
        end
   end,
})
