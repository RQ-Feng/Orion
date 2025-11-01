--Need OrionLib
local SettingTabs = {}
task.spawn(function()
	repeat task.wait() until OrionLib and OrionLib.MainWindows[1]
    local MainWindows = OrionLib.MainWindows
	for _,MainWindow in pairs(MainWindows) do
		if SettingTabs[table.find(MainWindows,MainWindow)] then continue end

		local Setting = MainWindow:MakeTab({
			Name = "UI设置",
			Icon = "rbxassetid://4483345998"
		})
		Setting:AddButton({
			Name = "关闭UI",
			Callback = function() OrionLib:Destroy() end
		})
		local Themes = {
			['暗色'] = "Dark",
			['浅色'] = "Light"
		}
		Setting:AddDropdown({
			Name = "UI主题",
			Default = "暗色",
			Options = {"暗色","浅色"},
			Callback = function(Value)
				if not Themes[Value] then return end
				OrionLib:SetTheme(Themes[Value])
			end    
		})
		Setting:AddLabel("此服务器上的游戏ID为:" .. game.GameId)
		Setting:AddLabel("此服务器位置ID为:" .. game.PlaceId)
		Setting:AddParagraph("此服务器UUID为:", game.JobId)
		Setting:AddLabel("此服务器上的游戏版本为:version_" .. game.PlaceVersion)

		table.insert(SettingTabs,table.find(MainWindows,MainWindow),Setting)
	end
end)