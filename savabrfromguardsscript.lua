local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Brainrot Saver HUB | v5.0 ULTIMATE",
   LoadingTitle = "Активация мгновенной кражи...",
   LoadingSubtitle = "by pxcv9t",
   ConfigurationSaving = { Enabled = false }
})

-- Переменные
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local SAVE_POS = hrp.CFrame

_G.AutoSteal = false
_G.TargetRarity = "God"

local MainTab = Window:CreateTab("Главная", 4483362458)

-- Функция мгновенной активации (как у Kaito Hub)
local function instantInteract(prompt)
    if fireproximityprompt then
        fireproximityprompt(prompt) -- Мгновенная кража (если поддерживает чит)
    else
        -- Запасной быстрый метод
        prompt:InputHoldBegin()
        task.wait(0.1) 
        prompt:InputHoldEnd()
    end
end

-- Проверка на Робуксы
local function isPaid(prompt)
    if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then return true end
    local p = prompt.Parent
    if p:FindFirstChild("RobuxIcon") or p:FindFirstChild("Price") or p:FindFirstChild("Spawn") then return true end
    return false
end

-- ОСНОВНОЙ ЦИКЛ (Мгновенный поиск)
local function startSteal()
    while _G.AutoSteal do
        task.wait(0.3) -- Высокая скорость сканирования
        
        -- Проходим по папкам игроков (как в твоем Dex)
        for _, folder in pairs(game.Workspace:GetChildren()) do
            if not _G.AutoSteal then break end
            
            -- Проверяем, что это папка игрока или база
            for _, model in pairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    local rarity = model:GetAttribute("Secret")
                    
                    if rarity == _G.TargetRarity then
                        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                        
                        if prompt and prompt.Enabled and not isPaid(prompt) then
                            -- Сохраняем базу, если она не задана
                            if SAVE_POS.Position.Magnitude < 10 then SAVE_POS = hrp.CFrame end
                            
                            -- Мгновенный полет и действие
                            hrp.CFrame = model:GetModelCFrame() * CFrame.new(0, 3, 0)
                            task.wait(0.1)
                            
                            instantInteract(prompt)
                            
                            task.wait(0.1)
                            hrp.CFrame = SAVE_POS -- Мгновенно назад
                        end
                    end
                end
            end
        end
    end
end

-- ИНТЕРФЕЙС
MainTab:CreateDropdown({
   Name = "Выбери редкость",
   Options = {"God", "Secret"},
   CurrentOption = {"God"},
   MultipleOptions = false,
   Callback = function(Option) _G.TargetRarity = Option[1] end,
})

MainTab:CreateToggle({
   Name = "Мгновенная Авто-кража",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoSteal = Value
      if Value then
         SAVE_POS = player.Character.HumanoidRootPart.CFrame
         Rayfield:Notify({Title = "Система", Content = "Позиция сохранена. Начинаю мгновенный сбор!", Duration = 3})
         task.spawn(startSteal)
      end
   end,
})

MainTab:CreateButton({
   Name = "Задать текущую точку как Базу",
   Callback = function() 
      SAVE_POS = player.Character.HumanoidRootPart.CFrame 
      Rayfield:Notify({Title = "Успех", Content = "Точка возврата обновлена!", Duration = 2})
   end,
})
