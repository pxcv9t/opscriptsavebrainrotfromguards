local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Made by pxcv9t, SBFG",
   LoadingTitle = "Loading into the game...",
   LoadingSubtitle = "v2.1 AlphaFix",
   ConfigurationSaving = { Enabled = false }
})

-- Переменные
local player = game.Players.LocalPlayer
local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
local SAVE_POS = root and root.CFrame or CFrame.new(0,0,0)
_G.AutoSteal = false

-- Вкладка
local MainTab = Window:CreateTab("Авто-Фарм", 4483362458)

-- Функция проверки на Робуксы (Anti-Robux)
local function isPaid(prompt)
    if not prompt then return true end
    local p = prompt.Parent
    -- Проверка иконок и текста цены
    if p:FindFirstChild("RobuxIcon") or p:FindFirstChild("Price") or p:FindFirstChild("Robux") then return true end
    if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then return true end
    return false
end

-- Основная логика кражи
local function startSteal()
    while _G.AutoSteal do
        task.wait(1)
        
        -- Свежий поиск персонажа
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Ищем модели в Workspace
        for _, model in pairs(game.Workspace:GetDescendants()) do
            if not _G.AutoSteal then break end
            
            -- Проверяем, является ли это моделью бреинрота
            if model:IsA("Model") and (model:GetAttribute("Secret") == "God" or model:GetAttribute("Secret") == "Secret") then
                
                -- Ищем кнопку "Steal"
                local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt and prompt.Enabled and not isPaid(prompt) then
                    print("Цель найдена: " .. model.Name)
                    
                    -- Сохраняем текущую позицию ПЕРЕД прыжком, если она еще не задана
                    if SAVE_POS.Position.Magnitude < 1 then SAVE_POS = hrp.CFrame end

                    -- 1. Летим к цели (чуть выше, чтобы не застрять в текстурах)
                    hrp.CFrame = model:GetModelCFrame() * CFrame.new(0, 5, 0)
                    task.wait(0.3)
                    
                    -- 2. Прожимаем кнопку (HoldDuration берется из настроек игры)
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.3)
                    prompt:InputHoldEnd()
                    
                    -- 3. Возвращаемся в сейв-зону
                    hrp.CFrame = SAVE_POS
                    task.wait(0.5)
                end
            end
        end
    end
end

-- GUI элементы
MainTab:CreateToggle({
   Name = "Авто-кража (God/Secret)",
   CurrentValue = false,
   Flag = "StealToggle",
   Callback = function(Value)
      _G.AutoSteal = Value
      if Value then
         local char = player.Character
         if char and char:FindFirstChild("HumanoidRootPart") then
            SAVE_POS = char.HumanoidRootPart.CFrame
            Rayfield:Notify({Title = "Фарм", Content = "Позиция возврата сохранена!", Duration = 3})
         end
         task.spawn(startSteal)
      end
   end,
})

MainTab:CreateButton({
   Name = "Обновить точку возврата (встань в сейв-зону!)",
   Callback = function()
      local char = player.Character
      if char and char:FindFirstChild("HumanoidRootPart") then
         SAVE_POS = char.HumanoidRootPart.CFrame
         Rayfield:Notify({Title = "Система", Content = "Точка обновлена успешно!", Duration = 2})
      end
   end,
})
