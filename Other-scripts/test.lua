if not OrionLib then OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/RQ-Feng/Orion/refs/heads/main/main.lua'))() end--lib
local Window = OrionLib:MakeWindow({--Main Window
    Name = "OrionTest.Window.Name",
    SaveConfig = false,
    ConfigFolder = "OrionTest"
})
OrionLib:MakeNotification({
    Name = "OrionTest.Notification.Load.Name",
    Content = "OrionTest.Notification.Load.Content",
    Image = "rbxassetid://4483345998",
    Time = 5
})
--Tab
local Tab = Window:MakeTab({
	Name = "OrionTest.Tab.Main.Name",
	Icon = "rbxassetid://4483345998"
})
--Section
local Section = Tab:AddSection({
	Name = "OrionTest.Section.Main.Name"
})
--Button
Tab:AddButton({
	Name = "OrionTest.Button.MakeNotify.Name",
	Callback = function()
      	OrionLib:MakeNotification({
            Name = "OrionTest.Notification.Button.Name",
            Content = "OrionTest.Notification.Content.Default",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
  	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.ClickTwice.Name",
	ClickTwice = true,
	Callback = function()
      	OrionLib:MakeNotification({
            Name = "OrionTest.Notification.OtherButton.Name",
            Content = "OrionTest.Notification.Content.Default",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
  	end    
})
--Toggle
Tab:AddToggle({
	Name = "OrionTest.Toggle.First.Name",
	Default = false,
	Callback = function(Value)
		print(Value)
	end    
})
local CoolToggle = Tab:AddToggle({
	Name = "OrionTest.Toggle.Second.Name",
	Default = false,
	Callback = function(Value)
		print(Value)
	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.SetToggleTrue.Name",
	Callback = function()
      	CoolToggle:Set(true)
  	end    
})
--Colorpicker
local ColorPicker = Tab:AddColorpicker({
	Name = "OrionTest.Colorpicker.Main.Name",
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(Value)
		print(Value)
	end	  
})
Tab:AddButton({
	Name = "OrionTest.Button.SetColorpickerWhite.Name",
	Callback = function()
      	ColorPicker:Set(Color3.fromRGB(255,255,255))
  	end    
})
--Slider
local Slider = Tab:AddSlider({
	Name = "OrionTest.Slider.Main.Name",
	Min = 0,
	Max = 20,
	Default = 5,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "OrionTest.Slider.ValueName",
	Callback = function(Value)
		print(Value)
	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.SetSliderTwo.Name",
	Callback = function()
      	Slider:Set(2)
  	end    
})
--Label
local CoolLabel = Tab:AddLabel("OrionTest.Label.Main.Default")
Tab:AddButton({
	Name = "OrionTest.Button.SetLabelNew.Name",
	Callback = function()
      	CoolLabel:Set("OrionTest.Label.New")
  	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.SetLabelDefault.Name",
	Callback = function()
      	CoolLabel:Set("OrionTest.Label.Main.Default")
  	end    
})
--Paragraph
local CoolParagraph = Tab:AddParagraph("OrionTest.Paragraph.Main.Title","OrionTest.Paragraph.Main.Content")
Tab:AddButton({
	Name = "OrionTest.Button.SetParagraphNew.Name",
	Callback = function()
        CoolParagraph:Set("OrionTest.Paragraph.New.Title", "OrionTest.Paragraph.New.Content")
  	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.SetParagraphDefault.Name",
	Callback = function()
        CoolParagraph:Set("OrionTest.Paragraph.Main.Title", "OrionTest.Paragraph.Default.Content")
  	end    
})
--Textbox
Tab:AddTextbox({
	Name = "OrionTest.Textbox.Main.Name",
	Default = "default box input",
	TextDisappear = true,
	Callback = function(Value)
		print(Value)
	end	  
})
--Bind
Tab:AddBind({
	Name = "OrionTest.Bind.Main.Name",
	Default = Enum.KeyCode.E,
	Hold = false,
	Callback = function()
		print("press")
	end    
})
--Dropdown
local Dropdown = Tab:AddDropdown({
	Name = "OrionTest.Dropdown.Main.Name",
	Default = "OrionTest.Dropdown.Option.One",
	Options = {"OrionTest.Dropdown.Option.One", "OrionTest.Dropdown.Option.Two"},
	Callback = function(Value)
		print(Value)
	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.RefreshDropdown.Name",
	Callback = function()
        Dropdown:Refresh({'OrionTest.Dropdown.Option.Idk',tostring(math.random(1,50))},true)
  	end    
})
Tab:AddButton({
	Name = "OrionTest.Button.SetDropdownIdk.Name",
	Callback = function()
        Dropdown:Set("OrionTest.Dropdown.Option.Idk")
  	end    
})
Tab:AddToggle({
    Name = "OrionTest.Toggle.FlagTest.Name",
    Default = true,
    Save = true,
    Flag = "toggle"
})
Tab:AddButton({
    Name = "OrionTest.Button.PrintFlag.Name",
    Callback = function()
        print("toggle flag:",OrionLib.Flags["toggle"].Value)
    end
})
--Visible
local VisibleLabel = Tab:AddLabel("OrionTest.Visible.Label.Default")
local HiddenToggle = Tab:AddToggle({
	Name = "OrionTest.Visible.HiddenDefault.Name",
	Visible = false,
	Default = false,
	Callback = function(Value)
		print(Value)
	end
})
Tab:AddButton({
	Name = "OrionTest.Button.HideLabel.Name",
	Callback = function()
		VisibleLabel:SetVisible(false)
	end
})
Tab:AddButton({
	Name = "OrionTest.Button.ShowLabel.Name",
	Callback = function()
		VisibleLabel:SetVisible(true)
	end
})
Tab:AddToggle({
	Name = "OrionTest.Visible.ToggleHidden.Name",
	Default = false,
	Callback = function(Value)
		HiddenToggle:SetVisible(Value)
	end
})