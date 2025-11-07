--Need OrionLib
local SettingTabs = {}

local Themes = {
	['OrionLib.Setting.UItheme.Dark'] = "Dark",
	['OrionLib.Setting.UItheme.Light'] = "Light"
}
local Languages = {
	['中文'] = "zh-cn",
	['English'] = "en-us"
}

task.spawn(function()
	repeat task.wait() until OrionLib and OrionLib.MainWindows[1]
    local MainWindows = OrionLib.MainWindows
	for _,MainWindow in pairs(MainWindows) do
		if SettingTabs[table.find(MainWindows,MainWindow)] then continue end

		local Setting = MainWindow:MakeTab({
			Name = 'OrionLib.Setting.UISetting.Name',
			Icon = "rbxassetid://4483345998"
		})
		Setting:AddButton({
			Name = 'OrionLib.Setting.CloseUI.Name',
			Callback = function() OrionLib:Destroy() end
		})
		Setting:AddDropdown({
			Name = 'OrionLib.Setting.UItheme.Name',
			Default = 'OrionLib.Setting.UItheme.Dark',
			Options = {'OrionLib.Setting.UItheme.Dark','OrionLib.Setting.UItheme.Light'},
			Callback = function(Value)
				print(Value)
				if not Themes[Value] then return end
				OrionLib:SetTheme(Themes[Value])
			end    
		})
		Setting:AddDropdown({
			Name = "语言/Language",
			Default = "中文",
			Options = {"中文","English"},
			Callback = function(Value)
				if not Languages[Value] then return end
				OrionLib:SetLanguage(Languages[Value])
				OrionLib:RefreshLanguage()
			end    
		})
		Setting:AddLabel('OrionLib.Setting.GameId.Name')
		Setting:AddLabel('OrionLib.Setting.PlaceId.Name')
		Setting:AddParagraph('OrionLib.Setting.JobId.Name',game.JobId)
		Setting:AddLabel('OrionLib.Setting.GameVersion.Name')

		table.insert(SettingTabs,table.find(MainWindows,MainWindow),Setting)
	end
end)