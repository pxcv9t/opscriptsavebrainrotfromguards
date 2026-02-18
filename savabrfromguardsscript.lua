local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Brainrot Saver HUB | v3.0 Working",
   LoadingTitle = "Запуск систем взлома...",
   LoadingSubtitle = "by pxcv9t",
   ConfigurationSaving = { Enabled = false }
})

-- Настройки и переменные
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local SAVE_POS = hrp.CFrame

_G.AutoSteal = false
_G.TargetRarity = "God" -- По умолчанию

local MainTab = Window:CreateTab("Главная", 4483362458)

-- Функция безопасного телепорта
local function teleport(targetCFrame)
    if hrp then
        hrp.CFrame = targetCFrame * CFrame.new(0, 5, 0) -- Телепорт чуть выше цели
    end
end

-- Функция проверки на Робуксы (Anti-Robux)
local function isPaid(obj)
    -- Ищем кнопку и проверяем текст на наличие символа робуксов
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then return true end
    end
    -- Проверка на наличие объектов цены, которые мы видели в Dex
    if obj:FindFirstChild("Robux") or obj:FindFirstChild("Price") then return true end
    return false
end

-- ОСНОВНОЙ ЦИКЛ КРАЖИ
local function startSteal()
    while _G.AutoSteal do
        task.wait(0.5)
        
        -- Ищем в Workspace (где лежат клетки с персонажами из твоего Dex)
        for _, model in pairs(game.Workspace:GetChildren()) do
            if not _G.AutoSteal then break end
            
            -- Проверка: это модель? У нее есть нужный атрибут редкости?
            local rarity = model:GetAttribute("Secret")
            if model:IsA("Model") and rarity == _G.TargetRarity then
                
                local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                -- Если кнопка есть, она активна и НЕ за робуксы
                if prompt and prompt.Enabled and not isPaid(model) then
                    
                    Rayfield:Notify({Title = "Цель!", Content = "Краду: " .. model.Name, Duration = 2})
                    
                    -- 1. Летим к цели
                    teleport(model:GetModelCFrame())
                    task.wait(0.3)
                    
                    -- 2. Зажимаем кнопку (имитация игрока)
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.2)
                    prompt:InputHoldEnd()
                    
                    -- 3. Возвращаемся на сохраненную точку
                    teleport(SAVE_POS)
                    task.wait(0.5)
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
   Flag = "RarityDropdown",
   Callback = function(Option)
      _G.TargetRarity = Option[1]
   end,
})

MainTab:CreateToggle({
   Name = "Авто-сбор выбранной редкости",
   CurrentValue = false,
   Flag = "AutoStealToggle",
   Callback = function(Value)
      _G.AutoSteal = Value
      if Value then
         -- Сохраняем позицию в момент включения
         SAVE_POS = player.Character.HumanoidRootPart.CFrame
         task.spawn(startSteal)
      end
   end,
})

MainTab:CreateButton({
   Name = "Сохранить текущую позицию (как базу)",
   Callback = function()
      SAVE_POS = player.Character.HumanoidRootPart.CFrame
      Rayfield:Notify({Title = "Система", Content = "Точка возврата установлена!", Duration = 2})
   end,
})

MainTab:CreateButton({
   Name = "Вернуться на базу",
   Callback = function()
      teleport(SAVE_POS)
   end,
})
