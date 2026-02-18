local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Brainrot Saver HUB",
   LoadingTitle = "Загрузка скрипта...",
   LoadingSubtitle = "by pxcv9t",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "BrainrotSaveConfig",
      FileName = "MainConfig"
   }
})

-- Переменные
local WANTED_RARITIES = {["God"] = true, ["Secret"] = true}
local SAVE_POS = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
_G.AutoSteal = false

-- Вкладка
local MainTab = Window:CreateTab("Авто-Фарм", 4483362458)

-- Функции логики
local function isPaid(prompt)
    local parent = prompt.Parent
    if parent:FindFirstChild("RobuxIcon") or parent:FindFirstChild("Price") then return true end
    if prompt.ActionText:find("R$") or prompt.ObjectText:find("R$") then return true end
    return false
end

local function startSteal()
    while _G.AutoSteal do
        task.wait(0.5)
        local player = game.Players.LocalPlayer
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        for _, obj in pairs(game.Workspace:GetDescendants()) do
            if not _G.AutoSteal then break end
            
            if obj:IsA("Model") then
                local rarity = obj:GetAttribute("Secret")
                
                if rarity and WANTED_RARITIES[rarity] then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    if prompt and prompt.Enabled and not isPaid(prompt) then
                        -- Телепорт и кража
                        root.CFrame = obj:GetModelCFrame() * CFrame.new(0, 3, 0)
                        task.wait(0.3)
                        
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.2)
                        prompt:InputHoldEnd()
                        
                        -- Возврат на позицию
                        root.CFrame = SAVE_POS
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end

-- Элементы GUI
MainTab:CreateToggle({
   Name = "Авто-кража (God/Secret)",
   CurrentValue = false,
   Flag = "AutoStealFlag",
   Callback = function(Value)
      _G.AutoSteal = Value
      if Value then
         SAVE_POS = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
         Rayfield:Notify({Title = "Старт", Content = "Позиция сохранена, фарм запущен!", Duration = 3})
         task.spawn(startSteal)
      else
         Rayfield:Notify({Title = "Стоп", Content = "Фарм остановлен", Duration = 3})
      end
   end,
})

MainTab:CreateButton({
   Name = "Обновить точку возврата",
   Callback = function()
      SAVE_POS = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
      Rayfield:Notify({Title = "Успех", Content = "Новая точка сохранения установлена!", Duration = 3})
   end,
})

Rayfield:LoadConfiguration()
