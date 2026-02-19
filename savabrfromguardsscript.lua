local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | Escape Guard to Save Brainrot",
   LoadingTitle = "Загрузка скрипта...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "BrainrotHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true 
   },
   KeySystem = false
})

-- Вкладки
local MainTab = Window:CreateTab("MAIN", 4483362458) -- Иконка домика
local UpgradesTab = Window:CreateTab("UPGRADES", 4483362458)

-- Переменные для логики
local savedPosition = nil
local selectedRarity = "Common"
local autoCollectEnabled = false
local player = game.Players.LocalPlayer

-- Функция для поиска Брейнрота по редкости
local function getTargetBrainrot(rarity)
    -- !!! ОБЯЗАТЕЛЬНО ИЗМЕНИТЬ ПУТЬ !!!
    -- Укажи папку, где лежат брейнроты. Например: game.Workspace.Brainrots или game.Workspace.Map.NPCs
    local brainrotsFolder = workspace -- Замени на нужную папку
    
    for _, obj in pairs(brainrotsFolder:GetChildren()) do
        -- !!! ОБЯЗАТЕЛЬНО ИЗМЕНИТЬ ЛОГИКУ ПОИСКА !!!
        -- Ниже пример: скрипт ищет модельку с нужным именем ИЛИ с объектом Rarity внутри.
        -- Настрой это под структуру плейса.
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            -- Пример 1: Если редкость указана в имени (например "God_Brainrot")
            if string.match(obj.Name, rarity) then
                return obj
            end
            
            -- Пример 2: Если внутри есть StringValue под названием "Rarity"
            -- if obj:FindFirstChild("Rarity") and obj.Rarity.Value == rarity then
            --     return obj
            -- end
        end
    end
    return nil
end

Rayfield:Notify({
   Title = "Скрипт загружен!",
   Content = "Не забудь сохранить позицию перед автофармом.",
   Duration = 5,
   Image = 4483362458,
})

-- === РАЗДЕЛ ТЕЛЕПОРТА (MAIN) ===
MainTab:CreateSection("Teleport Section")

MainTab:CreateButton({
   Name = "Save Position",
   Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            savedPosition = char.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Position Saved", Content = "Your position has been saved!", Duration = 3})
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
   Options = {"Common", "Epic", "Legendary", "Mythic", "God", "Secret"},
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
            Rayfield:Notify({Title = "Ошибка", Content = "Сначала сохрани позицию!", Duration = 3})
            return
        end
        
        local target = getTargetBrainrot(selectedRarity)
        local char = player.Character
        
        if target and char and char:FindFirstChild("HumanoidRootPart") then
            -- Прыгаем к брейнроту
            char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
            task.wait(0.2) -- Ждем, чтобы игра засчитала касание (Touch)
            
            -- Если для сбора нужно нажать кнопку "E" (ProximityPrompt), раскомментируй строку ниже:
            -- fireproximityprompt(target.ProximityPrompt)
            -- task.wait(0.2)
            
            -- Возвращаемся на базу
            char.HumanoidRootPart.CFrame = savedPosition
        else
            Rayfield:Notify({Title = "Не найдено", Content = "Брейнрот с редкостью " .. selectedRarity .. " не найден.", Duration = 2})
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

-- === ЛОГИКА АВТОФАРМА ===
task.spawn(function()
    while task.wait(0.5) do -- Скорость цикла (0.5 сек). Если кикает античит - увеличь до 1-2.
        if autoCollectEnabled and savedPosition then
            local target = getTargetBrainrot(selectedRarity)
            local char = player.Character
            
            if target and char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                task.wait(0.3) -- Пауза на сбор
                
                -- fireproximityprompt(target.ProximityPrompt) -- Убрать коммент, если там кнопка
                
                char.HumanoidRootPart.CFrame = savedPosition
                task.wait(1.5) -- Пауза перед следующим сбором, чтобы не забанило
            end
        end
    end
end)

-- === РАЗДЕЛ АПГРЕЙДОВ (UPGRADES) ===
UpgradesTab:CreateSection("Speed, Rebirth & Money")

UpgradesTab:CreateToggle({Name = "Auto Buy Speed +5", CurrentValue = false, Callback = function(Value) end})
UpgradesTab:CreateToggle({Name = "Auto Rebirth", CurrentValue = false, Callback = function(Value) end})
UpgradesTab:CreateToggle({Name = "Auto Collect Money", CurrentValue = false, Callback = function(Value) end})
