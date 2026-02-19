local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm Hub | Escape Guard to Save Brainrot",
   LoadingTitle = "Загрузка скрипта...",
   LoadingSubtitle = "by Pxcv9t",
   ConfigurationSaving = {Enabled = false},
   Discord = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local UpgradesTab = Window:CreateTab("UPGRADES", 4483362458)

local savedPosition = nil
local selectedRarity = "Common"
local autoCollectEnabled = false
local player = game.Players.LocalPlayer

-- 🔥 СУПЕР-УМНЫЙ ПОИСК (Ищет кнопку клетки рядом с мобом) 🔥
local function getTargetBrainrot(rarity)
    for _, desc in pairs(workspace:GetDescendants()) do
        -- Ищем текст редкости (например, "God")
        if desc:IsA("TextLabel") and (desc.Text == rarity or string.match(desc.Text, rarity)) then
            local model = desc:FindFirstAncestorOfClass("Model")
            
            if model and model:FindFirstChild("HumanoidRootPart") then
                local hrp = model.HumanoidRootPart
                local closestPrompt = nil
                local minDistance = 25 -- Радиус поиска кнопки (в стадах)
                
                -- Ищем все кнопки (ProximityPrompt) на карте
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local pos = nil
                        -- Узнаем, где физически находится кнопка
                        if prompt.Parent:IsA("BasePart") then 
                            pos = prompt.Parent.Position
                        elseif prompt.Parent:IsA("Attachment") then 
                            pos = prompt.Parent.WorldPosition 
                        end
                        
                        -- Если кнопка близко к нашему брейнроту, берем её!
                        if pos then
                            local dist = (pos - hrp.Position).Magnitude
                            if dist < minDistance then
                                closestPrompt = prompt
                                minDistance = dist
                            end
                        end
                    end
                end
                
                -- Если нашли кнопку рядом с этим брейнротом, значит он в клетке! Возвращаем.
                if closestPrompt then
                    return model, closestPrompt
                end
            end
        end
    end
    return nil, nil
end

Rayfield:Notify({Title = "Исправления применены", Content = "Теперь перс замораживается при взломе!", Duration = 3})

MainTab:CreateSection("Teleport Section")

MainTab:CreateButton({
   Name = "Save Position",
   Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            savedPosition = char.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Успешно!", Content = "Позиция сохранена.", Duration = 2})
        end
   end,
})

MainTab:CreateButton({
   Name = "Return to Saved Position",
   Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and savedPosition then
            char.HumanoidRootPart.CFrame = savedPosition
        end
   end,
})

MainTab:CreateDropdown({
   Name = "Select Rarity",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   MultipleOptions = false,
   Flag = "RarityDropdown",
   Callback = function(Option)
        selectedRarity = Option[1]
   end,
})

-- Функция для кражи (чтобы не писать дважды один и тот же код)
local function performSteal()
    if not savedPosition then
        Rayfield:Notify({Title = "Ошибка", Content = "Сохрани позицию перед сбором!", Duration = 3})
        return false
    end
    
    local target, prompt = getTargetBrainrot(selectedRarity)
    local char = player.Character
    
    if target and prompt and char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        
        -- 1. Телепортируемся к самой кнопке (клетке), а не внутрь моба
        local promptPart = prompt.Parent
        if promptPart and promptPart:IsA("BasePart") then
            hrp.CFrame = promptPart.CFrame + Vector3.new(0, 2, 0)
        else
            hrp.CFrame = target.HumanoidRootPart.CFrame
        end
        
        -- 2. ЗАМОРАЖИВАЕМ персонажа, чтобы зажатие не сбилось
        hrp.Anchored = true
        task.wait(0.5) -- Ждем долю секунды, чтобы игра прогрузила зону
        
        -- 3. Зажимаем кнопку
        fireproximityprompt(prompt)
        
        -- Ждем, пока заполнится полоска + небольшой запас
        if prompt.HoldDuration > 0 then
            task.wait(prompt.HoldDuration + 0.3)
        else
            task.wait(0.5)
        end
        
        -- 4. Размораживаем и возвращаем на базу
        hrp.Anchored = false
        hrp.CFrame = savedPosition
        return true
    else
        Rayfield:Notify({Title = "Не найдено", Content = "Дикий Брейнрот [" .. selectedRarity .. "] в клетке не найден!", Duration = 2})
        return false
    end
end

MainTab:CreateButton({
   Name = "Collect Selected Rarity (Once)",
   Callback = function()
        performSteal()
   end,
})

MainTab:CreateToggle({
   Name = "Auto Collect Selected Rarity",
   CurrentValue = false,
   Flag = "AutoCollectToggle",
   Callback = function(Value)
        autoCollectEnabled = Value
   end,
})

-- ⚙️ ЦИКЛ АВТОФАРМА ⚙️
task.spawn(function()
    while task.wait(1.5) do -- Проверяем каждые 1.5 секунды
        if autoCollectEnabled and savedPosition then
            local success = performSteal()
            if success then
                task.wait(1) -- Доп. пауза на базе, чтобы античит не ругался
            end
        end
    end
end)

UpgradesTab:CreateSection("Функционал в разработке")
UpgradesTab:CreateToggle({Name = "Auto Buy Speed +5", CurrentValue = false, Callback = function() end})
