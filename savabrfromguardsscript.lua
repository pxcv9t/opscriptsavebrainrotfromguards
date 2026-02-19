local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Norm hub | Escape Guard to Save Brainrot",
   LoadingTitle = "Загрузка скрипта...",
   LoadingSubtitle = "by pxcv9t",
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

-- 🔥 УМНЫЙ ПОИСК (Ищет только диких в клетках с кнопкой) 🔥
local function getTargetBrainrot(rarity)
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
            local isCorrectRarity = false
            
            -- Проверяем редкость по тексту
            for _, desc in pairs(model:GetDescendants()) do
                if desc:IsA("TextLabel") and (desc.Text == rarity or string.match(desc.Text, rarity)) then
                    isCorrectRarity = true
                    break
                end
            end

            if isCorrectRarity then
                -- САМОЕ ВАЖНОЕ: Ищем кнопку ProximityPrompt внутри
                -- Если кнопки нет (это пет в Safe Zone) - игнорируем!
                local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    return model, prompt -- Возвращаем и модельку, и саму кнопку
                end
            end
        end
    end
    return nil, nil
end

Rayfield:Notify({Title = "Обновление", Content = "Добавлен авто-взлом клеток и игнор Safe Zone!", Duration = 3})

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

MainTab:CreateButton({
   Name = "Collect Selected Rarity (Once)",
   Callback = function()
        if not savedPosition then
            Rayfield:Notify({Title = "Ошибка", Content = "Сохрани позицию перед сбором!", Duration = 3})
            return
        end
        
        local target, prompt = getTargetBrainrot(selectedRarity)
        local char = player.Character
        
        if target and prompt and char and char:FindFirstChild("HumanoidRootPart") then
            -- 1. Телепортируемся
            char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
            task.wait(0.3) -- Ждем прогрузки
            
            -- 2. Автоматически "зажимаем" кнопку
            fireproximityprompt(prompt)
            
            -- Ждем, пока заполнится полоска (HoldDuration - это время зажатия в игре)
            if prompt.HoldDuration > 0 then
                task.wait(prompt.HoldDuration + 0.2)
            else
                task.wait(0.5)
            end
            
            -- 3. Возвращаемся на базу
            char.HumanoidRootPart.CFrame = savedPosition
        else
            Rayfield:Notify({Title = "Не найдено", Content = "Дикий Брейнрот [" .. selectedRarity .. "] в клетке не найден!", Duration = 2})
        end
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
    while task.wait(1) do -- Проверяем карту каждую секунду
        if autoCollectEnabled and savedPosition then
            local target, prompt = getTargetBrainrot(selectedRarity)
            local char = player.Character
            
            if target and prompt and char and char:FindFirstChild("HumanoidRootPart") then
                -- Телепорт
                char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                task.wait(0.3) 
                
                -- Зажимаем кнопку
                fireproximityprompt(prompt)
                
                -- Ждем таймер взлома
                if prompt.HoldDuration > 0 then
                    task.wait(prompt.HoldDuration + 0.2)
                else
                    task.wait(0.5)
                end
                
                -- Возврат
                char.HumanoidRootPart.CFrame = savedPosition
                task.wait(1) -- Пауза на базе, чтобы не крашнуло
            end
        end
    end
end)

UpgradesTab:CreateSection("Функционал в разработке")
UpgradesTab:CreateToggle({Name = "Auto Buy Speed +5", CurrentValue = false, Callback = function() end})
