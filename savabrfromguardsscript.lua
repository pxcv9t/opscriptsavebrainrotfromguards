local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | Anti-Robux Edition",
   LoadingTitle = "Загрузка системы защиты...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local UpgradesTab = Window:CreateTab("UPGRADES", 4483362458)

local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false
local player = game.Players.LocalPlayer

-- Функция проверки на Робуксы и запретные зоны
local function isSafeToCollect(model, prompt)
    -- 1. Проверка на платные элементы (Anti-Robux)
    for _, item in pairs(model:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("TextBox") then
            local txt = item.Text:lower()
            if string.match(txt, "rbx") or string.match(txt, "robux") or string.match(txt, "r%$") or string.match(txt, "buy") then
                return false -- Это донатная клетка
            end
        end
    end

    -- 2. Проверка на нахождение в Easy/Normal базах
    local path = model:GetFullName():lower()
    if string.match(path, "easy") or string.match(path, "normal") then
        return false -- Пропускаем начальные базы
    end

    -- 3. Проверка на Safe Zone (если объект принадлежит игроку)
    if model:FindFirstAncestor("SafeZone") or model:FindFirstAncestor(player.Name) then
        return false 
    end

    return true
end

local function getTargetBrainrot(rarity)
    for _, desc in pairs(workspace:GetDescendants()) do
        if desc:IsA("TextLabel") and (desc.Text == rarity or string.match(desc.Text, rarity)) then
            local model = desc:FindFirstAncestorOfClass("Model")
            if model then
                -- Ищем кнопку "Steal" (украсть) в радиусе 15 единиц
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.ActionText == "Steal" then
                        local pPos = (p.Parent:IsA("BasePart") and p.Parent.Position) or (p.Parent:IsA("Attachment") and p.Parent.WorldPosition)
                        if pPos and (pPos - desc.Parent.WorldPosition).Magnitude < 15 then
                            -- Проверяем на донат и зоны
                            if isSafeToCollect(model, p) then
                                return model, p
                            end
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

MainTab:CreateButton({
   Name = "Save Home Position",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "ОК", Content = "Позиция базы сохранена!", Duration = 2})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "Select Rarity",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

local function startSteal()
    if not savedPosition then 
        Rayfield:Notify({Title = "Внимание", Content = "Сначала нажми Save Home Position!", Duration = 3})
        return 
    end
    
    local target, prompt = getTargetBrainrot(selectedRarity)
    local char = player.Character
    if target and prompt and char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        
        -- Летим к кнопке
        hrp.CFrame = (prompt.Parent:IsA("BasePart") and prompt.Parent.CFrame) or target.HumanoidRootPart.CFrame
        task.wait(0.2)
        hrp.Anchored = true -- Замораживаем для стабильности
        
        fireproximityprompt(prompt)
        task.wait(prompt.HoldDuration + 0.3)
        
        hrp.Anchored = false
        hrp.CFrame = savedPosition
    end
end

MainTab:CreateToggle({
   Name = "Start Auto-Farming (Beyond SafeZone)",
   CurrentValue = false,
   Callback = function(Value)
        autoCollectEnabled = Value
        while autoCollectEnabled do
            startSteal()
            task.wait(2)
        end
   end,
})

-- ВКЛАДКА UPGRADES (Набросок для теста)
UpgradesTab:CreateButton({
    Name = "Fix Upgrades (Beta)",
    Callback = function()
        Rayfield:Notify({Title = "Инфо", Content = "Скинь мне в следующем сообщении скриншот кнопок апгрейдов из Dex, чтобы я их привязал!", Duration = 5})
    end
})
