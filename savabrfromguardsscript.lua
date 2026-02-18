local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KAITO STYLE | Save Brainrot",
   LoadingTitle = "Адаптация систем Kaito Hub...",
   LoadingSubtitle = "by pxcv9t",
   ConfigurationSaving = { Enabled = false }
})

-- Переменные системы
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local SAVE_POS = hrp.CFrame

_G.AutoSteal = false
_G.TargetRarity = "God"

local MainTab = Window:CreateTab("MAIN", 4483362458)

-- Функция "Мгновенной кражи" как у Kaito
local function kaitoCollect(obj)
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        -- Проверка на Анти-Робукс (пропускаем, если рядом кнопки покупки за 99/129 робуксов)
        if obj.Parent:FindFirstChild("Spawn God") or obj.Parent:FindFirstChild("Spawn Secret") then 
            return 
        end
        if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then 
            return 
        end

        -- Сохраняем базу, если она не задана
        if SAVE_POS.Position.Magnitude < 5 then SAVE_POS = hrp.CFrame end

        -- Мгновенный перелет и активация
        local oldPos = hrp.CFrame
        hrp.CFrame = obj:GetModelCFrame()
        task.wait(0.1)
        
        -- Используем fireproximityprompt для мгновенного результата
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
        end
        
        task.wait(0.1)
        hrp.CFrame = SAVE_POS -- Возврат
    end
end

-- Цикл сканирования
local function startKaitoFarm()
    while _G.AutoSteal do
        task.wait(0.2) -- Максимальная скорость
        
        -- Поиск целей по всей карте (включая папки игроков из Dex)
        for _, v in pairs(game.Workspace:GetDescendants()) do
            if not _G.AutoSteal then break end
            
            if v:IsA("Model") then
                -- Проверка редкости через атрибут или имя (как в Kaito)
                local rarityAttr = v:GetAttribute("Secret")
                if rarityAttr == _G.TargetRarity then
                    kaitoCollect(v)
                end
            end
        end
    end
end

-- Кнопки GUI
MainTab:CreateButton({
   Name = "Save Position (Сохранить базу)",
   Callback = function() 
      SAVE_POS = player.Character.HumanoidRootPart.CFrame 
      Rayfield:Notify({Title = "System", Content = "Base Position Saved!", Duration = 2})
   end,
})

MainTab:CreateDropdown({
   Name = "Select Rarity",
   Options = {"Common", "Rare", "Epic", "Legendary", "Mythic", "God", "Secret"},
   CurrentOption = {"God"},
   MultipleOptions = false,
   Callback = function(Option) _G.TargetRarity = Option[1] end,
})

MainTab:CreateToggle({
   Name = "Auto Collect Selected Rarity",
   CurrentValue = false,
   Callback = function(Value)
      _G.AutoSteal = Value
      if Value then
         task.spawn(startKaitoFarm)
      end
   end,
})
