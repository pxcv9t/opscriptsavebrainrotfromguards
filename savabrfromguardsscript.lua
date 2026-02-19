local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO HUB | Ultra Optimized",
   LoadingTitle = "Очистка кэша и запуск...",
   LoadingSubtitle = "by Gemini",
   ConfigurationSaving = {Enabled = false},
   KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local player = game.Players.LocalPlayer
local savedPosition = nil
local selectedRarity = "God"
local autoCollectEnabled = false

-- Оптимизированная функция поиска
local function findWildBrainrot()
    local targetPrompt = nil
    local targetModel = nil

    -- Ищем только среди ProximityPrompts (это быстро)
    for _, prompt in pairs(game:GetService("ProximityPromptService"):GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.ActionText == "Steal" then
            local parentModel = prompt:FindFirstAncestorOfClass("Model")
            
            if parentModel then
                -- 1. Проверка на редкость (ищем текст над головой)
                local hasRarity = false
                for _, label in pairs(parentModel:GetDescendants()) do
                    if label:IsA("TextLabel") and string.find(label.Text, selectedRarity) then
                        hasRarity = true
                        break
                    end
                end

                if hasRarity then
                    -- 2. Анти-Робукс (платные обычно в зонах Easy/Normal или имеют специфику)
                    local modelPath = parentModel:GetFullName():lower()
                    local isPaidZone = string.find(modelPath, "easy") or string.find(modelPath, "normal")
                    
                    -- 3. Проверка, что это не в Safe Zone (дикие мобы обычно далеко)
                    if not isPaidZone and not parentModel:FindFirstAncestor(player.Name) then
                        targetPrompt = prompt
                        targetModel = parentModel
                        break 
                    end
                end
            end
        end
    end
    return targetModel, targetPrompt
end

MainTab:CreateButton({
   Name = "1. Save Base Position (Safe Zone)",
   Callback = function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            savedPosition = player.Character.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Система", Content = "База сохранена!", Duration = 2})
        end
   end,
})

MainTab:CreateDropdown({
   Name = "2. Target Rarity",
   Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   Callback = function(Option) selectedRarity = Option[1] end,
})

local function doSteal()
    if not savedPosition then return end
    
    local model, prompt = findWildBrainrot()
    if model and prompt then
        local hrp = player.Character.HumanoidRootPart
        
        -- ТП чуть выше кнопки, чтобы не провалиться
        hrp.CFrame = (prompt.Parent:IsA("BasePart") and prompt.Parent.CFrame) or model.HumanoidRootPart.CFrame
        task.wait(0.1)
        hrp.Anchored = true -- Фиксируем, чтобы полоска не сбилась
        
        fireproximityprompt(prompt)
        task.wait(prompt.HoldDuration + 0.3) -- Ждем время зажатия
        
        hrp.Anchored = false
        hrp.CFrame = savedPosition -- Домой!
    end
end

MainTab:CreateToggle({
   Name = "3. Start Fast Farm",
   CurrentValue = false,
   Callback = function(Value)
        autoCollectEnabled = Value
        if Value then
            task.spawn(function()
                while autoCollectEnabled do
                    doSteal()
                    task.wait(1.5) -- Пауза между проверками
                end
            end)
        end
   end,
})

Rayfield:Notify({Title = "Готово", Content = "Лаги устранены, фильтр Safe Zone включен.", Duration = 4})
