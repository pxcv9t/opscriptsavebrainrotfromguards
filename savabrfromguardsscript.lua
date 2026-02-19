local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | Escape Guard to Save Brainrot",
   LoadingTitle = "Загрузка скрипта...",
   LoadingSubtitle = "by Gemini",
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

-- 🔥 УМНЫЙ ПОИСК БРЕЙНРОТА ПО ПАРЯЩЕМУ ТЕКСТУ 🔥
local function getTargetBrainrot(rarity)
    -- Сканируем все модельки в Workspace
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
            -- Ищем внутри модельки текстовые панели (TextLabel)
            for _, desc in pairs(model:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    -- Если текст точно совпадает с выбранной редкостью
                    if desc.Text == rarity or string.match(desc.Text, rarity) then
                        return model
                    end
                end
            end
        end
    end
    return nil
end

Rayfield:Notify({Title = "Умный поиск активирован", Content = "Скрипт готов к работе!", Duration = 3})

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
   CurrentOption = {"Common"},
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
        
        local target = getTargetBrainrot(selectedRarity)
        local char = player.Character
        
        if target and char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
            task.wait(0.2) -- Ждем, чтобы игра засчитала касание
            char.HumanoidRootPart.CFrame = savedPosition
        else
            Rayfield:Notify({Title = "Не найдено", Content = "Брейнрот [" .. selectedRarity .. "] сейчас нет на карте!", Duration = 2})
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

-- Цикл Автофарма
task.spawn(function()
    while task.wait(0.8) do -- Задержка 0.8 сек (чтобы не лагало от поиска)
        if autoCollectEnabled and savedPosition then
            local target = getTargetBrainrot(selectedRarity)
            local char = player.Character
            
            if target and char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                task.wait(0.3) -- Пауза в клетке для сбора
                char.HumanoidRootPart.CFrame = savedPosition
                task.wait(1) -- Пауза на базе, чтобы античит не ругался
            end
        end
    end
end)

-- Пустышки для апгрейдов на будущее
UpgradesTab:CreateSection("Функционал в разработке")
UpgradesTab:CreateToggle({Name = "Auto Buy Speed +5", CurrentValue = false, Callback = function() end})
UpgradesTab:CreateToggle({Name = "Auto Rebirth", CurrentValue = false, Callback = function() end})
UpgradesTab:CreateToggle({Name = "Auto Collect Money", CurrentValue = false, Callback = function() end})
