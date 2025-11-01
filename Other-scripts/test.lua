if not OrionLib then OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/RQ-Feng/Orion/refs/heads/main/main.lua'))() end--lib
local Window = OrionLib:MakeWindow({--Main Window
    Name = "Title of the library",
    SaveConfig = true,
    ConfigFolder = "OrionTest"
})
OrionLib:MakeNotification({
    Name = "Notity on load",
    Content = "Notification content... what will it say??",
    Image = "rbxassetid://4483345998",
    Time = 5
})
--Tab
local Tab = Window:MakeTab({
	Name = "Tab 1",
	Icon = "rbxassetid://4483345998"
})
--Section
local Section = Tab:AddSection({
	Name = "Section"
})
--Button
Tab:AddButton({
	Name = "Make a notify",
	Callback = function()
      	OrionLib:MakeNotification({
            Name = "Notity by Button",
            Content = "Notification content",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
  	end    
})
--Toggle
Tab:AddToggle({
	Name = "This is a toggle!",
	Default = false,
	Callback = function(Value)
		print(Value)
	end    
})
local CoolToggle = Tab:AddToggle({
	Name = "toggle 2",
	Default = false,
	Callback = function(Value)
		print(Value)
	end    
})
Tab:AddButton({
	Name = "Set toggle 2 to true",
	Callback = function()
      	CoolToggle:Set(true)
  	end    
})
--Colorpicker
local ColorPicker = Tab:AddColorpicker({
	Name = "Colorpicker",
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(Value)
		print(Value)
	end	  
})
Tab:AddButton({
	Name = "Set colorpicker to white",
	Callback = function()
      	ColorPicker:Set(Color3.fromRGB(255,255,255))
  	end    
})
--Slider
local Slider = Tab:AddSlider({
	Name = "Slider",
	Min = 0,
	Max = 20,
	Default = 5,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "bananas",
	Callback = function(Value)
		print(Value)
	end    
})
Tab:AddButton({
	Name = "Set slider to 2",
	Callback = function()
      	Slider:Set(2)
  	end    
})
--Label
local CoolLabel = Tab:AddLabel("Label")
Tab:AddButton({
	Name = "Set lable to 'Label New!'",
	Callback = function()
      	CoolLabel:Set("Label New!")
  	end    
})
Tab:AddButton({
	Name = "Set lable to default",
	Callback = function()
      	CoolLabel:Set("Label")
  	end    
})
--Paragraph
local CoolParagraph = Tab:AddParagraph("Paragraph","Paragraph Content")
Tab:AddButton({
	Name = "Set paragraph to 'Paragraph New!'",
	Callback = function()
        CoolParagraph:Set("Paragraph New!", "New Paragraph Content!")
  	end    
})
Tab:AddButton({
	Name = "Set paragraph to default",
	Callback = function()
        CoolParagraph:Set("Paragraph", "Paragraph Content!")
  	end    
})
--Textbox
Tab:AddTextbox({
	Name = "Textbox",
	Default = "default box input",
	TextDisappear = true,
	Callback = function(Value)
		print(Value)
	end	  
})
--Bind
Tab:AddBind({
	Name = "Bind",
	Default = Enum.KeyCode.E,
	Hold = false,
	Callback = function()
		print("press")
	end    
})
--Dropdown
local Dropdown = Tab:AddDropdown({
	Name = "Dropdown",
	Default = "1",
	Options = {"1", "2"},
	Callback = function(Value)
		print(Value)
	end    
})
Tab:AddButton({
	Name = "Refresh dropdown to idk",
	Callback = function()
        Dropdown:Refresh({'idk',tostring(math.random(1,50))},true)
  	end    
})
Tab:AddButton({
	Name = "Set dropdown to idk",
	Callback = function()
        Dropdown:Set("idk")
  	end    
})
Tab:AddToggle({
    Name = "Toggle flag test",
    Default = true,
    Save = true,
    Flag = "toggle"
})
Tab:AddButton({
    Name = "Print toggle flag",
    Callback = function()
        print("toggle flag:",OrionLib.Flags["toggle"].Value)
    end
})
local Tab2 = Window:MakeTab({
	Name = "destroy",
	Icon = "rbxassetid://4483345998",
})
Tab2:AddButton({
	Name = "Destroy the tab",
	Callback = function() OrionLib:Destroy() end    
})