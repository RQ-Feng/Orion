--Need OrionLib
Setting = Window:MakeTab({
    Name = "UI设置",
    Icon = "rbxassetid://4483345998"
})
Setting:AddButton({
    Name = "关闭UI",
    Callback = function() OrionLib:Destroy() end
})
Setting:AddLabel("此服务器上的游戏ID为:" .. game.GameId)
Setting:AddLabel("此服务器位置ID为:" .. game.PlaceId)
Setting:AddParagraph("此服务器UUID为:", game.JobId)
Setting:AddLabel("此服务器上的游戏版本为:version_" .. game.PlaceVersion)