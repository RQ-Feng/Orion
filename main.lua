local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UIParent = gethui and gethui() or game.CoreGui or LocalPlayer.PlayerGui
local IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local OldMouseBehavior = Enum.MouseBehavior.Default
local InputKeys = {--输入键
	['Input'] = {Enum.UserInputType.MouseButton1,Enum.UserInputType.Touch},
	['Drag'] = {Enum.UserInputType.MouseMovement,Enum.UserInputType.Touch}
}
local OrionLib = { -- OrionLib
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	MainWindows = {},
	Themes = {
		Dark = {
			Main = Color3.fromRGB(25, 25, 25),
			Second = Color3.fromRGB(32, 32, 32),
			Stroke = Color3.fromRGB(60, 60, 60),
			Divider = Color3.fromRGB(60, 60, 60),
			Text = Color3.fromRGB(240, 240, 240),
			TextDark = Color3.fromRGB(150, 150, 150),
			TextNotify = Color3.fromRGB(200, 200, 200)
		},
		Light = {
			Main = Color3.fromRGB(240, 240, 240),
			Second = Color3.fromRGB(225, 225, 225),
			Stroke = Color3.fromRGB(200, 200, 200),
			Divider = Color3.fromRGB(200, 200, 200),
			Text = Color3.fromRGB(15, 15, 15),
			TextDark = Color3.fromRGB(100, 100, 100),
			TextNotify = Color3.fromRGB(50, 50, 50)
		}
		--Custom = {}
	},
	SelectedTheme = "Dark",
	Language = 'zh-cn',
	Folder = nil,
	SaveCfg = false
}

--Resources:Localization and Icons
local suc,Localization,Icons = pcall(function()
	local Localization = loadstring(game:HttpGet("https://raw.githubusercontent.com/RQ-Feng/Orion/refs/heads/main/Resources/Localization.lua"))() 
	local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/RQ-Feng/Orion/refs/heads/main/Resources/Icons.lua"))().icons
	return Localization,Icons
end)
--Check about resources
if not suc then pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification",{
		Title = "OrionLib",Text = "Problem encountered while loading resources.\nStop loading.",
		Duration = 30
	})
end); return end

-- 删除之前加载过的OrionLib
for _, Interface in ipairs(UIParent:GetChildren()) do if Interface.Name == 'OrionUI' then Interface:Destroy() end end

local OrionUI = Instance.new("ScreenGui")
OrionUI.Name = "OrionUI"
OrionUI.Parent = UIParent

function OrionLib:IsRunning() return OrionUI.Parent ~= nil and true or false end -- IsRunning函数

local function AddConnection(Signal, Function) -- OrionUI-添加事件连接
	if not OrionLib:IsRunning() then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(OrionLib.Connections, SignalConnect)
	return SignalConnect
end

local function AddDraggingFunctionality(DragPoint, Main)
	local Dragging = false
	local DragInput, MousePos, FramePos
	DragPoint.InputBegan:Connect(function(Input)
		if table.find(InputKeys['Input'],Input.UserInputType) then
			Dragging = true
			MousePos = Input.Position
			FramePos = Main.Position
			Input.Changed:Connect(function() if Input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
		end
	end)
	DragPoint.InputChanged:Connect(function(Input) if table.find(InputKeys['Drag'],Input.UserInputType) then DragInput = Input	end end)
	UserInputService.InputChanged:Connect(function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale,
					FramePos.Y.Offset + Delta.Y)
			}):Play()
		end
	end)
end

local function GetLocalizationString(originalString)
	return (Localization and Localization[OrionLib.Language]) and Localization[OrionLib.Language][originalString] or originalString
end

local function SetLocalizationString(TextLabel:TextLabel,...)
	local originalString = TextLabel:GetAttribute('sourceString')
	if not TextLabel:IsA('TextLabel') or type(originalString) ~= 'string' then return end

    local count = 0;for _ in string.gmatch(originalString,string.gsub("%s","([%%%[%]])","%%%1")) do count = count + 1 end
	if #{...} ~= count then return originalString end
	
	local _suc,LocalizationString = pcall(function() return GetLocalizationString(originalString) end)
	if not LocalizationString then return originalString end
	TextLabel.Text = LocalizationString:format(...)
	return
end

local function Create(Name, Properties, Children)---Instance Creator
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do Object[i] = v  end
	for i, v in next, Children or {} do v.Parent = Object end
	return Object
end

local function CreateElement(ElementName, ElementFunction)--Element Setter
	OrionLib.Elements[ElementName] = function(...) return ElementFunction(...) end
end

local function MakeElement(ElementName, ...)--Create instance by element 
	local NewElement = OrionLib.Elements[ElementName](...)
	return NewElement
end

local function SetProps(Element, Props)--Set instance properties
	for Property, Value in pairs(Props) do Element[Property] = Value end
	return Element
end

local function SetChildren(Element, Children)--将Children里的实例移动到Element
	for _, Child in pairs(Children) do Child.Parent = Element end
	return Element
end

--Theme
local function ReturnColorProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then return "BackgroundColor3"
	elseif Object:IsA("ScrollingFrame") then return "ScrollBarImageColor3"
	elseif Object:IsA("UIStroke") then return "Color"
	elseif Object:IsA("TextLabel") or Object:IsA("TextBox") then return "TextColor3"
	elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return "ImageColor3"
	else return end
end

local function AddThemeObject(Object, Type)--添加UI对象到对应的主题table
	if not OrionLib.ThemeObjects[Type] then OrionLib.ThemeObjects[Type] = {} end
	table.insert(OrionLib.ThemeObjects[Type], Object)
	Object[ReturnColorProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
	return Object
end

function OrionLib:SetTheme(ThemeName)--设置主题
	if not OrionLib.Themes[ThemeName] then warn("Orion Lib - Unknown theme: " .. ThemeName) return end
	OrionLib.SelectedTheme = ThemeName
	for Name, Type in pairs(OrionLib.ThemeObjects) do
		for _, Object in pairs(Type) do
			Object[ReturnColorProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Name]
		end
	end
end

--Color Pack/Unpack
local function PackColor(Color) return {R = Color.R * 255,G = Color.G * 255,B = Color.B * 255} end
local function UnpackColor(Color) return Color3.fromRGB(Color.R, Color.G, Color.B) end
--Config
local Config = ''

function OrionLib:LoadConfig(CfgName)
	Config = OrionLib.Folder .. "/" .. (CfgName or game.PlaceId) .. ".cfg"
	if not OrionLib.SaveCfg or not isfile(Config) then return end
	local LoadSuc,_ = pcall(function()
		local Data = HttpService:JSONDecode(readfile(Config))
		for flagName,value in pairs(Data) do
			if not OrionLib.Flags[flagName] then continue end
			local flag = OrionLib.Flags[flagName]
			task.spawn(function() 
				if flag.Type ~= "Colorpicker" then flag:Set(value)
				else flag:Set(UnpackColor(value)) end
			end)
		end
	end)
	OrionLib:MakeNotification({
		Name = 'OrionLib.Configuration.Name',
		Content = 'OrionLib.Configuration.'..(LoadSuc and 'Success' or 'Failed')..'.Content',
		Image = LoadSuc and Icons['check'] or Icons['alert-triangle'],
		Time = 5
	})
end

local function SaveCfg()
	if not OrionLib.SaveCfg then return end
	local Data = {}
	for flagName, flagConfig in pairs(OrionLib.Flags) do
		if not flagConfig.Save then continue end
		if flagConfig.Type ~= "Colorpicker" then Data[flagName] = flagConfig.Value
		else Data[flagName] = PackColor(flagConfig.Value) end
	end
	local suc,err = pcall(function() writefile(Config, tostring(HttpService:JSONEncode(Data))) end)
	if not suc then warn("Orion Lib - 保存配置错误,原因:" .. err) end
end
--Keybind tables with checker
local WhitelistedMouseInputType = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3
}
local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash,
	Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
}
local function CheckKey(Table, Key) 
	for _, v in next, Table do 
		if v == Key then return true end 
	end; return false
end
--UI Elements
CreateElement("Corner", function(Scale, Offset)
	local Corner = Create("UICorner", {
		CornerRadius = UDim.new(Scale or 0, Offset or 10)
	})
	return Corner
end)

CreateElement("Stroke", function(Color, Thickness)
	local Stroke = Create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1
	})
	return Stroke
end)

CreateElement("List", function(Scale, Offset)
	local List = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
	return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	local Padding = Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
	return Padding
end)

CreateElement("Constraint", function(aspectRatio)
	local Constraint = Create("UIAspectRatioConstraint", {
		AspectRatio = aspectRatio or 1
	})
	return Constraint
end)

CreateElement("TFrame", function()
	local TFrame = Create("Frame", {
		BackgroundTransparency = 1
	})
	return TFrame
end)

CreateElement("Frame", function(Color)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	})
	return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {Create("UICorner", {
		CornerRadius = UDim.new(Scale, Offset)
	})})
	return Frame
end)

CreateElement("Button", function()
	local Button = Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
	local ScrollFrame = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
	return ScrollFrame
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {
		Image = ImageID,
		BackgroundTransparency = 1
	})
	return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
	local Image = Create("ImageButton", {
		Image = ImageID,
		BackgroundTransparency = 1
	})
	return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	local Label = Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Enum.Font.Gotham,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	Label:SetAttribute("sourceString",Text)
	SetLocalizationString(Label)
	return Label
end)
--NotificationHolder & Function
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {SetProps(MakeElement("List"), {
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Padding = UDim.new(0, 5)
})}), {
	Name = 'NotificationHolder',
	Position = UDim2.new(1, -25, 1, -25),
	Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	Parent = OrionUI
})

--Notification
function OrionLib:CloseNotification(NotificationParent)
	if not NotificationParent or not NotificationParent:GetAttribute('WaitingForClose') then return end
	local NotificationFrame = NotificationParent:FindFirstChild('NotificationFrame')
	if not NotificationFrame then return end
	NotificationParent:SetAttribute('WaitingForClose',false)

	task.spawn(function()
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
			ImageTransparency = 1
		}):Play()
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {
			BackgroundTransparency = 0.6
		}):Play()
		task.wait(0.3)
		TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
			Transparency = 0.9
		}):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
			TextTransparency = 0.4
		}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
			TextTransparency = 0.5
		}):Play()
		task.wait(0.05)
		if not OrionLib:IsRunning() then return end
		NotificationFrame:TweenPosition(UDim2.new(1, 100, 0, 0), 'In', 'Quint', 1, true)
		task.wait(1.35)
		NotificationParent:Destroy()
	end)
end

function OrionLib:MakeNotification(NotificationConfig)
	local NotificationParent
	task.spawn(function()
		NotificationConfig = NotificationConfig or {}
		NotificationConfig.Name = NotificationConfig.Name or "Title"
		NotificationConfig.Content = NotificationConfig.Content or "Content"
		NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
		NotificationConfig.SoundId = NotificationConfig.SoundId or "rbxassetid://4590662766"
		NotificationConfig.Time = NotificationConfig.Time or 5

		NotificationParent = SetProps(MakeElement("TFrame"), {
			Name = 'NotificationParent',
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(AddThemeObject(MakeElement("RoundFrame",Color3.fromRGB(25, 25, 25), 0, 10),'Main'), {
			Parent = NotificationParent,
			Name = 'NotificationFrame',
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2), MakeElement("Padding", 12, 12, 12, 12),
			SetProps(AddThemeObject(MakeElement("Image", NotificationConfig.Image),'Text'), {
				Size = UDim2.new(0, 20, 0, 20),
				Name = "Icon"
			}), SetProps(AddThemeObject(MakeElement("Label", NotificationConfig.Name, 15),'Text'), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}), SetProps(AddThemeObject(MakeElement("Label", NotificationConfig.Content, 14),'TextNotify'), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Enum.Font.GothamSemibold,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true
			})})

		local Sound = Instance.new("Sound", NotificationParent)
		Sound.SoundId = NotificationConfig.SoundId
		Sound.Volume = 3
		Sound.Playing = true
		NotificationParent:SetAttribute('WaitingForClose',true)
		if not OrionLib:IsRunning() then return end
		
		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()
		
		task.wait(NotificationConfig.Time - 0.88)
		OrionLib:CloseNotification(NotificationParent)
	end)
	repeat task.wait() until NotificationParent or not OrionLib:IsRunning()
	return NotificationParent
end

local function CatchError(Config,...)
	local Table = {...}
	local suc,err = pcall(function() if Table then Config.Callback(unpack(Table)) else Config.Callback() end end)
	if not suc then 
		warn('"'..Config.Name..'"','got a error:' .. err)
		OrionLib:MakeNotification({
			Name = 'OrionLib.CatchError.Name',
			Content = 'OrionLib.CatchError.Content',
			Image = Icons['alert-triangle'],
			Time = 5
		})
	end
end

if IsOnMobile then-- Mobile 
	local MobileButton = SetProps(SetChildren(MakeElement("Frame"),
		{MakeElement("Constraint"),MakeElement("Corner",1,0),
			SetProps(MakeElement("Image",'rbxassetid://8834748103'),{
				Size = UDim2.new(0.7,0,0.7,0),
				Position = UDim2.new(0.5,0,0.5,0),
				ZIndex = 256,
				AnchorPoint = Vector2.new(0.5,0.5)}
			)}),{
			Name = 'MobileButton',
			Active = true,
			Position = UDim2.new(1,-10,0,10),
			BackgroundColor3 = Color3.fromRGB(25,25,25),
			Size = UDim2.new(0.05,30,0.05,30),
			AnchorPoint = Vector2.new(1,0),
			ZIndex = 255,
			Visible = false,
			Parent = OrionUI
		})

	AddConnection(MobileButton.TouchTap,function()
		if not OrionUI.MainWindow then return end
		OrionUI.MainWindow.Visible = not OrionUI.MainWindow.Visible
		if OrionUI.MainWindow.Visible then MobileButton.Visible = false end
	end)
end

function OrionLib:SetLanguage(language)
	if type(language) ~= 'string' then return end
	if not Localization[language] then warn('OrionLib - Unsupport language:',language) return end
	OrionLib.Language = language

	for _,TextLabel in pairs(OrionUI:GetDescendants()) do
		if not TextLabel:IsA('TextLabel') then continue end
		SetLocalizationString(TextLabel)
	end
end

function OrionLib:InsertLanguage(LocalizationTable)
	if type(LocalizationTable) ~= 'table' then return end
	for Language,Table in pairs(LocalizationTable) do
		if type(Table) ~= 'table' then continue end
		if not Localization[Language] then Localization[Language] = {} end
		
		for originalString,localizationString in pairs(Table) do
			if type(originalString) ~= 'string' or string.match(originalString,'OrionLib') then continue end
			Localization[Language][originalString] = localizationString
		end
	end
end

--MainUI
function OrionLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local UIHidden = false

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "Orion Library"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.IntroEnabled = WindowConfig.IntroEnabled or true
	WindowConfig.IntroText = WindowConfig.IntroText or "Orion Library"
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
	WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"

	if WindowConfig.SaveConfig then--File Functions Check
		local filefuncs = {'isfolder', 'makefolder', 'writefile','readfile'}
		warn('By OrionLib - SaveConfig is enabled,testing file functions...')
		for _,func in pairs(filefuncs) do
			local suc,bool = pcall(function() return getfenv(0)[func] and true or false end)
			if not suc or not bool then warn('❌',func,"doesn't work.") WindowConfig.SaveConfig = false
			else print('✅',func,'is working.') end
		end
		warn('File functions test completed,'..(WindowConfig.SaveConfig and 'config saving/loading is available.' or 'config saving/loading is unavailable,auto disabled.'))
	end

	OrionLib.Folder = WindowConfig.ConfigFolder
	OrionLib.SaveCfg = WindowConfig.SaveConfig

	pcall(function() if WindowConfig.SaveConfig and not isfolder(WindowConfig.ConfigFolder) then makefolder(WindowConfig.ConfigFolder) end end)

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4),
		{Size = UDim2.new(1, 0, 1, -50)}),
		{MakeElement("List"), MakeElement("Padding", 8, 0, 0, 8)}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
		Position = UDim2.new(0, 9, 0, 6),
		Size = UDim2.new(0, 18, 0, 18)
	}), "Text")})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1
	}), {AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
		Position = UDim2.new(0, 9, 0, 6),
		Size = UDim2.new(0, 18, 0, 18),
		Name = "Ico"
	}), "Text")})

	local DragPoint = SetProps(MakeElement("TFrame"), {Size = UDim2.new(1, 0, 0, 50)})

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0,
		10), {
			Size = UDim2.new(0, 150, 1, -50),
			Position = UDim2.new(0, 0, 0, 50)
		}), {AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 0)
		}), "Second"), AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(0, 10, 1, 0),
				Position = UDim2.new(1, -10, 0, 0)
			}), "Second"), AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(0, 1, 1, 0),
				Position = UDim2.new(1, -1, 0, 0)
			}), "Stroke"), TabHolder, SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 50),
				Position = UDim2.new(0, 0, 1, -50)
			}), {AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1)
			}), "Stroke"), AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.new(0, 32, 0, 32),
					Position = UDim2.new(0, 10, 0.5, 0)
				}),
				{SetProps(--Display avatar
					MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId ..
						"&width=420&height=420&format=png"), {
							Size = UDim2.new(1, 0, 1, 0)
						}), AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
						Size = UDim2.new(1, 0, 1, 0)
					}), "Second"), MakeElement("Corner", 1)}), "Divider"), SetChildren(
					SetProps(MakeElement("TFrame"), {
						AnchorPoint = Vector2.new(0, 0.5),
						Size = UDim2.new(0, 32, 0, 32),
						Position = UDim2.new(0, 10, 0.5, 0)
					}), {AddThemeObject(MakeElement("Stroke"), "Stroke"), MakeElement("Corner", 1)}),
				AddThemeObject(
					SetProps(MakeElement("Label", LocalPlayer.DisplayName,13), {
						Name = 'PlayerName',
						Size = UDim2.new(1, -60, 0, 13),
						Position = UDim2.new(0, 50, 0, 12),
						Font = Enum.Font.GothamBold,
						ClipsDescendants = true
					}), "Text"),})}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Name = 'Title',
		Size = UDim2.new(1, -30, 2, 0),
		Position = UDim2.new(0, 25, 0, -24),
		Font = Enum.Font.GothamBlack,
		TextSize = 20
	}), "Text")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1)
	}), "Stroke")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0,--MainWindow初始化
		10), {
			Name = 'MainWindow',
			Parent = OrionUI,
			Position = UDim2.new(0.5, -307, 0.5, -172),
			Size = UDim2.new(0, 615, 0, 344),
			ClipsDescendants = true
		}), {SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 50),
				Name = "TopBar"
			}), {WindowName, WindowTopBarLine,
				AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
					Size = UDim2.new(0, 70, 0, 30),
					Position = UDim2.new(1, -90, 0, 10)
				}), {AddThemeObject(MakeElement("Stroke"), "Stroke"), AddThemeObject(
					SetProps(MakeElement("Frame"), {
						Size = UDim2.new(0, 1, 1, 0),
						Position = UDim2.new(0.5, 0, 0, 0)
					}), "Stroke"), CloseBtn, MinimizeBtn}), "Second")}), DragPoint, WindowStuff}), "Main")

	if WindowConfig.ShowIcon then
		WindowName.Position = UDim2.new(0, 50, 0, -24)
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 25, 0, 15)
		})
		WindowIcon.Parent = MainWindow.TopBar
	end

	local function LoadSequence()--Intro function
		MainWindow.Visible = false
		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = OrionUI,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 28, 0, 28),
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 1
		})

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
			Parent = OrionUI,
			Name = 'IntroLabel',
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 19, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
		task.wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X / 2), 0.5, 0)
		}):Play()
		task.wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0
		}):Play()
		task.wait(2)
		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1
		}):Play()
		MainWindow.Visible = true
		LoadSequenceLogo:Destroy()
		LoadSequenceText:Destroy()
	end

	if WindowConfig.IntroEnabled then LoadSequence() end--Intro

	AddDraggingFunctionality(DragPoint, MainWindow)

	AddConnection(UserInputService.InputChanged,function() IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end)

	AddConnection(CloseBtn.MouseButton1Down, function()--关闭按钮
		MainWindow.Visible = false
		UIHidden = true
		OrionLib:MakeNotification({
			Name = 'OrionLib.InterfaceHidden.Name',
			Content = IsOnMobile and 'OrionLib.InterfaceHidden.Content.Mobile' or 'OrionLib.InterfaceHidden.Content.Computer',
			Time = 5
		})
		UserInputService.MouseBehavior = OldMouseBehavior
		if IsOnMobile and OrionUI.MobileButton then OrionUI.MobileButton.Visible = true end
		WindowConfig.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(Input)--右Shift检测
		if Input.KeyCode ~= Enum.KeyCode.RightShift then return end
		if UIHidden == false then
			MainWindow.Visible = false
			UIHidden = true
			OrionLib:MakeNotification({
				Name = 'OrionLib.InterfaceHidden.Name',
				Content = 'OrionLib.InterfaceHidden.Content.Computer.ShiftAgain',
				Time = 5
			})
			UserInputService.MouseBehavior = OldMouseBehavior
			WindowConfig.CloseCallback()
		else MainWindow.Visible = true
			UIHidden = false
			OldMouseBehavior = UserInputService.MouseBehavior
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()-- 最小化按钮
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 615, 0, 344)
			}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			task.wait(0.02)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"

			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)
			}):Play()
			task.wait(0.1)
			WindowStuff.Visible = false
		end
		Minimized = not Minimized
	end)

	if not OrionLib.SaveCfg then OrionLib:MakeNotification({--Notify
		Name = 'OrionLib.Configuration.Name',
		Content = 'OrionLib.Configuration.NotSaveCfg.Content',
		Time = 5
		}) end

	local TabFunction = {}
	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or ""

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder
		}), {AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(0, 10, 0.5, 0),
			ImageTransparency = 0.4,
			Name = "Ico"
		}), "Text"), AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -35, 1, 0),
				Position = UDim2.new(0, 35, 0, 0),
				Font = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				Name = "Title"
			}), "Text")})

		local Container = AddThemeObject(SetChildren(SetProps(
			MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
				Size = UDim2.new(1, -150, 1, -50),
				Position = UDim2.new(0, 150, 0, 50),
				Parent = MainWindow,
				Visible = false,
				Name = "ItemContainer"
			}), {MakeElement("List", 0, 6), MakeElement("Padding", 15, 10, 10, 15)}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		if FirstTab then
			FirstTab = false
			TabFrame.Ico.ImageTransparency = 0
			TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true
		end

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{
							ImageTransparency = 0.4
						}):Play()
					TweenService:Create(Tab.Title,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							TextTransparency = 0.4
						}):Play()
				end
			end
			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then ItemContainer.Visible = false	end
			end
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				TextTransparency = 0
			}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true
		end)

		local function GetElements(ItemParent)
			local ElementFunction = {}

			function ElementFunction:AddLabel(Text)
				local LabelFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Name = 'Label',
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 0.7,
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke")}), "Second")

				local LabelFunction = {}
				function LabelFunction:Set(ToChange) LabelFrame.Content.Text = ToChange	end
				return LabelFunction
			end

			function ElementFunction:DestroyLabel(Text)
				for _,Element in pairs(Container:GetChildren()) do
					if not Element:IsA('Frame') then continue end
					if Element:FindFirstChild('Content').ContentText == Text then Element:Destroy(); return end
				end
			end

			function ElementFunction:AddParagraph(Text, Content)
				Text = Text or "Text"
				Content = Content or "Content"

				local ParagraphFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 0.7,
						Name = 'Paragraph',
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"), AddThemeObject(SetProps(MakeElement("Label", Content, 13), {
						Size = UDim2.new(1, -24, 0, 0),
						Position = UDim2.new(0, 12, 0, 26),
						Font = Enum.Font.GothamSemibold,
						Name = "Content",
						TextWrapped = true
					}), "TextDark"), AddThemeObject(MakeElement("Stroke"), "Stroke")})
				,"Second")
				
				ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
				ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)

				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
				end)

				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange)
					ParagraphFrame.Content:SetAttribute('sourceString',ToChange)
					SetLocalizationString(ParagraphFrame.Content)
				end
				return ParagraphFunction
			end

			function ElementFunction:AddButton(ButtonConfig)
				ButtonConfig = ButtonConfig or {}
				ButtonConfig.Name = ButtonConfig.Name or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end
				ButtonConfig.ClickTwice = ButtonConfig.ClickTwice or false
				ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"

				local Button = {}
				local CooldownTask
				local CanClick = if ButtonConfig.ClickTwice then false else true

				local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})

				local ButtonFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Size = UDim2.new(1, 0, 0, 33),
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"), AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
						Size = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -30, 0, 7)
					}), "TextDark"), AddThemeObject(MakeElement("Stroke"), "Stroke"), Click})
				,"Second")

				ButtonFrame.Name = 'Button'

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ButtonFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ButtonFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
						}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ButtonFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
					if not CanClick then 
						CanClick = true
						ButtonFrame.Content.Text = GetLocalizationString('OrionLib.Button.ClickTwice.Tip')
						CooldownTask = task.spawn(function()
							task.wait(1)
							ButtonFrame.Content.Text = ButtonConfig.Name
							CanClick = false
						end); return
					end
					if CooldownTask then task.cancel(CooldownTask) end
					ButtonFrame.Content.Text = ButtonConfig.Name
					CanClick = if ButtonConfig.ClickTwice then false else true
					CatchError(ButtonConfig)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ButtonFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
						}):Play()
				end)

				function Button:Set(ButtonText) ButtonFrame.Content.Text = GetLocalizationString(ButtonText) or ButtonText end

				return Button
			end

			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig = ToggleConfig or {}
				ToggleConfig.Name = ToggleConfig.Name or "Toggle"
				ToggleConfig.Default = ToggleConfig.Default or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(9, 99, 195)
				ToggleConfig.Flag = ToggleConfig.Flag or nil
				ToggleConfig.Save = ToggleConfig.Save or false

				local Toggle = {
					Value = ToggleConfig.Default,
					Save = ToggleConfig.Save
				}
				
				if ToggleConfig.Flag then OrionLib.Flags[ToggleConfig.Flag] = Toggle end

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -24, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5)
				}), {SetProps(MakeElement("Stroke"), {
					Color = ToggleConfig.Color,
					Name = "Stroke",
					Transparency = 0.5
				}), SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
						Size = UDim2.new(0, 20, 0, 20),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Name = "Ico"
					})})

				local ToggleFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Size = UDim2.new(1, 0, 0, 38),
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), ToggleBox, Click})
				,"Second")

				ToggleFrame.Name = 'Toggle'

				function Toggle:Set(Value,Loading)
					if Value == nil or not OrionLib:IsRunning() then return end
					Toggle.Value = Value
					TweenService:Create(ToggleBox,
						TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Dark.Divider
						}):Play()
					TweenService:Create(ToggleBox.Stroke,
						TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							Color = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Dark.Stroke
						}):Play()
					TweenService:Create(ToggleBox.Ico,
						TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							ImageTransparency = Toggle.Value and 0 or 1,
							Size = Toggle.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)
						}):Play()
					if Loading and not Value then return end
					CatchError(ToggleConfig,Toggle.Value)
				end

				Toggle:Set(Toggle.Value,true)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ToggleFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ToggleFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
						}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ToggleFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
					SaveCfg()
					Toggle:Set(not Toggle.Value)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ToggleFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
						}):Play()
				end)

				return Toggle
			end

			function ElementFunction:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Default = SliderConfig.Default or 50
				SliderConfig.Callback = SliderConfig.Callback or function()
				end
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(9, 149, 98)
				SliderConfig.Flag = SliderConfig.Flag or nil
				SliderConfig.Save = SliderConfig.Save or false

				local Slider = {
					Value = SliderConfig.Default,
					Save = SliderConfig.Save
				}
				local Dragging = false

				if SliderConfig.Flag then OrionLib.Flags[SliderConfig.Flag] = Slider end

				local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 0.3,
					ClipsDescendants = true
				}), {AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 6),
					Font = Enum.Font.GothamBold,
					Name = "Value",
					TextTransparency = 0
				}), "Text")})

				local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
					Size = UDim2.new(1, -24, 0, 26),
					Position = UDim2.new(0, 12, 0, 30),
					BackgroundTransparency = 0.9
				}), {SetProps(MakeElement("Stroke"), {
					Color = SliderConfig.Color
				}), AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0.8
					}), "Text"), SliderDrag})

				local SliderFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
						Size = UDim2.new(1, 0, 0, 65),
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), SliderBar})
				,"Second")

				SliderFrame.Name = 'Slider'

				SliderBar.InputBegan:Connect(function(Input) if table.find(InputKeys['Input'],Input.UserInputType) then Dragging = true end end)
				SliderBar.InputEnded:Connect(function(Input) if table.find(InputKeys['Input'],Input.UserInputType) then Dragging = false end end)

				UserInputService.InputChanged:Connect(function(Input)
					if Dragging and table.find(InputKeys['Drag'],Input.UserInputType) then
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) /
							SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
						SaveCfg()
					end
				end)

				function Slider:Set(Value,Loading)
					if Value == nil or not OrionLib:IsRunning() then return end
					local float = #tostring(SliderConfig.Increment) - (
						#string.format("%.0f",SliderConfig.Increment) + (string.find(SliderConfig.Increment, "%.") and 1 or 0)
					)

					self.Value = math.clamp(string.format("%."..float.."f",Value), SliderConfig.Min, SliderConfig.Max)
					
					TweenService:Create(SliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}
					):Play()
					SliderBar.Value.Text = tostring(self.Value),SliderConfig.ValueName
					SliderDrag.Value.Text = tostring(self.Value),SliderConfig.ValueName
					if Loading and not Value then return end
					CatchError(SliderConfig,self.Value)
				end

				Slider:Set(Slider.Value,true)
				return Slider
			end

			function ElementFunction:AddDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
				DropdownConfig.Options = DropdownConfig.Options or {}
				DropdownConfig.Required = if DropdownConfig.Required ~= nil then DropdownConfig.Required else true
				DropdownConfig.Default = DropdownConfig.Default or DropdownConfig.Required and "..."
				DropdownConfig.Multiple = DropdownConfig.Multiple or false
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag = DropdownConfig.Flag or nil
				DropdownConfig.Save = DropdownConfig.Save or false
				
				local Dropdown = {
					Value = DropdownConfig.Default,
					Options = DropdownConfig.Options,
					Buttons = {},
					Save = DropdownConfig.Save
				}

				local MaxDisplayElements = 5
				local Toggled = false

				if DropdownConfig.Flag then OrionLib.Flags[DropdownConfig.Flag] = Dropdown end

				if not table.find(Dropdown.Options, Dropdown.Value) then Dropdown.Value = "..."	end

				local DropdownList = MakeElement("List")
				local DropdownContainer = AddThemeObject(SetProps(
					SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40, 40, 40), 4), {DropdownList}), {
						Parent = ItemParent,
						Position = UDim2.new(0, 0, 0, 38),
						Size = UDim2.new(1, 0, 1, -38),
						ClipsDescendants = true
					})
				,"Divider")
				AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
				end)

				local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})

				local DropdownFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromHSV(0, 0, 1), 0, 5), {
						Size = UDim2.new(1, 0, 0, 38),
						Name = 'Dropdown',
						Parent = ItemParent,
						ClipsDescendants = true
					}), {DropdownContainer, SetProps(SetChildren(MakeElement("TFrame"),
						{AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "Text"), AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
							Size = UDim2.new(0, 20, 0, 20),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(1, -30, 0.5, 0),
							ImageColor3 = Color3.fromRGB(240, 240, 240),
							Name = "Ico"
						}), "TextDark"), AddThemeObject(SetProps(MakeElement("Label", "Selected", 13), {
							Size = UDim2.new(1, -40, 1, 0),
							Font = Enum.Font.Gotham,
							Name = "Selected",
							TextXAlignment = Enum.TextXAlignment.Right
						}), "TextDark"), 
						-- AddThemeObject(SetProps(MakeElement("Frame"), {
						-- 	Size = UDim2.new(1, 0, 0, 1),
						-- 	Position = UDim2.new(0, 0, 1, -1),
						-- 	Name = "Line",
						-- 	Visible = false
						-- }), "Stroke"),
						 Click}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}), AddThemeObject(MakeElement("Stroke"), "Stroke")})
				,"Second")

				local function AddOptionBtn(Option)
					local OptionBtn = AddThemeObject(SetProps(
						SetChildren(MakeElement("Button", Color3.fromRGB(40, 40, 40)),
							{MakeElement("Corner", 0, 6),
								AddThemeObject(SetProps(MakeElement("Label", Option, 13, 0.4), {
									Position = UDim2.new(0, 8, 0, 0),
									Size = UDim2.new(1, -8, 1, 0),
									Name = "Title"
								}), "Text")}), {
							Parent = DropdownContainer,
							Size = UDim2.new(1, 0, 0, 28),
							BackgroundTransparency = 1,
							ClipsDescendants = true
						})
					,"Divider")
					AddConnection(OptionBtn.MouseButton1Click, function() Dropdown:Set(Option); SaveCfg() end)
					AddConnection(OptionBtn:GetAttributeChangedSignal('Selected'), function()--Tween on select
						local Selected = OptionBtn:GetAttribute('Selected')
						TweenService:Create(OptionBtn,
							TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								BackgroundTransparency = Selected and 0 or 1
							}):Play()
						TweenService:Create(OptionBtn.Title,
							TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								TextTransparency = Selected and 0 or 0.4
							}):Play()
					end)
					OptionBtn:SetAttribute('Selected',false)
					Dropdown.Buttons[Option] = OptionBtn
					return OptionBtn
				end

				local function GetSelectedOptionsInfo()
					local optionsInfo = {
						['Source'] = {},
						['Localization'] = {}
					}
					for _, button in pairs(Dropdown.Buttons) do
						if button:GetAttribute('Selected') then
							local Title = button.Title
							table.insert(optionsInfo['Source'],Title:GetAttribute('sourceString'))
							table.insert(optionsInfo['Localization'],Title.Text)
						end
					end	
					return optionsInfo
				end

				function Dropdown:Refresh(Options)
					if type(Options) ~= "table" then return end

					for _,v in pairs(Dropdown.Buttons) do v:Destroy() end
					table.clear(Dropdown.Buttons)
					Dropdown.Options = Options
					
					for _, Option in pairs(Dropdown.Options) do AddOptionBtn(Option) end
				end

				function Dropdown:Set(Option,Loading)
					if type(Option) ~= "string" or not table.find(Dropdown.Options,Option) then return end

					local LocalizationOption = GetLocalizationString(Option)
					local Button = Dropdown['Buttons'][Option]

					if DropdownConfig.Required and #GetSelectedOptionsInfo()['Source'] == 1 and Button:GetAttribute('Selected') then return end

					Button:SetAttribute('Selected',not Button:GetAttribute('Selected'))
					local SelectedOptionsInfo = GetSelectedOptionsInfo()
					local LocalizationOptions = SelectedOptionsInfo['Localization']
					local SourceOptions = SelectedOptionsInfo['Source']
					
					if DropdownConfig.Multiple then Dropdown.Value = SourceOptions
					else Dropdown.Value = Dropdown['Buttons'][Option]:GetAttribute('Selected') and Option or nil end

					DropdownFrame.F.Selected.Text = DropdownConfig.Multiple and table.concat(LocalizationOptions,',') or Dropdown.Value or ''
					
					if not DropdownConfig.Multiple then
						DropdownFrame.F.Selected:SetAttribute('sourceString',Option)
						SetLocalizationString(DropdownFrame.F.Selected)

						for _, button in pairs(Dropdown.Buttons) do if button.Title.Text ~= LocalizationOption then button:SetAttribute('Selected',false) end end
					end

					if Loading then return end
					if DropdownConfig.Multiple then return CatchError(DropdownConfig,unpack(SourceOptions)) else return CatchError(DropdownConfig,Dropdown.Value) end
				end

				--Toggle tween
				AddConnection(Click.MouseButton1Click, function()
					Toggled = not Toggled
					--DropdownFrame.F.Line.Visible = Toggled
					TweenService:Create(DropdownFrame.F.Ico,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = Toggled and 180 or 0}
					):Play()
					TweenService:Create(DropdownFrame,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = 
						Toggled and UDim2.new(1, 0, 0, 38 + (#Dropdown.Options > MaxDisplayElements and MaxDisplayElements * 28 or DropdownList.AbsoluteContentSize.Y))
						or UDim2.new(1, 0, 0, 38)}
					):Play()
				end)

				Dropdown:Refresh(Dropdown.Options)
				Dropdown:Set(Dropdown.Value,true)
				return Dropdown
			end

			function ElementFunction:AddBind(BindConfig)
				BindConfig.Name = BindConfig.Name or "Bind"
				BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
				BindConfig.Hold = BindConfig.Hold or false
				BindConfig.Callback = BindConfig.Callback or function()
				end
				BindConfig.Flag = BindConfig.Flag or nil
				BindConfig.Save = BindConfig.Save or false

				local Bind = {
					Value = Enum.KeyCode.Unknown,
					Binding = false,
					Holding = false,
					Save = BindConfig.Save
				}

				local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0)})

				local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",
					Color3.fromRGB(255, 255, 255), 0, 4), {
						Size = UDim2.new(0, 24, 0, 24),
						Position = UDim2.new(1, -12, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5)
					}), {AddThemeObject(MakeElement("Stroke"), "Stroke"),
						AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
							Size = UDim2.new(1, 0, 1, 0),
							Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Center,
							Name = "Value"
						}), "Text")}), "Main")

				local BindFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Size = UDim2.new(1, 0, 0, 38),
						Name = 'Bind',
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), BindBox, Click})
				,"Second")

				function Bind:SetKey(Key)
					Bind.Binding = false
					Bind.Value = Key or Bind.Value
					Bind.Value = Bind.Value.Name or Bind.Value
					BindBox.Value.Text = Bind.Value
				end

				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)}):Play()
				end)

				AddConnection(Click.InputEnded, function(Input)
					if Input.UserInputType ~= Enum.UserInputType.MouseButton1 or Bind.Binding then return end
					Bind.Binding = true
					BindBox.Value.Text = ""
				end)

				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if not Bind.Binding then
						if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
						if BindConfig.Hold then Bind.Holding = true end
						CatchError(BindConfig,Bind.Holding)
					else
						local Suc,Key = pcall(function() 
							if not CheckKey(BlacklistedKeys, Input.KeyCode) then return Input.KeyCode end
							if CheckKey(WhitelistedMouseInputType, Input.UserInputType) then return Input.UserInputType end
							return false
						end)
						Key = Suc and Key or Bind.Value
						Bind:SetKey(Key); SaveCfg()
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name ~= Bind.Value and Input.UserInputType.Name ~= Bind.Value then return end
					if BindConfig.Hold and Bind.Holding then Bind.Holding = false; CatchError(BindConfig,Bind.Holding) end
				end)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(BindFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(BindFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
						}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(BindFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(BindFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
						}):Play()
				end)

				Bind:SetKey(BindConfig.Default)
				if BindConfig.Flag then
					OrionLib.Flags[BindConfig.Flag] = Bind
				end
				return Bind
			end

			function ElementFunction:AddTextbox(TextboxConfig)
				TextboxConfig = TextboxConfig or {}
				TextboxConfig.Name = TextboxConfig.Name or "Textbox"
				TextboxConfig.Default = TextboxConfig.Default or ""
				TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
				TextboxConfig.Callback = TextboxConfig.Callback or function()
				end

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local TextboxActual = AddThemeObject(Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					PlaceholderColor3 = Color3.fromRGB(210, 210, 210),
					PlaceholderText = "Input",
					Font = Enum.Font.GothamSemibold,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 14,
					ClearTextOnFocus = false
				}), "Text")

				local TextContainer = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
						Size = UDim2.new(0, 24, 0, 24),
						Position = UDim2.new(1, -12, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5)
					}), {AddThemeObject(MakeElement("Stroke"), "Stroke"), TextboxActual}), "Main")

				local TextboxFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Size = UDim2.new(1, 0, 0, 38),
						Parent = ItemParent
					}), {AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), TextContainer, Click}), 
				"Second")

				TextboxFrame.Name = 'Textbox'

				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
					-- TextContainer.Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)
					TweenService:Create(TextContainer,
						TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)
						}):Play()
				end)

				AddConnection(TextboxActual.FocusLost, function()
					CatchError(TextboxConfig,TextboxActual.Text)
					if TextboxConfig.TextDisappear then TextboxActual.Text = ""	end
				end)

				TextboxActual.Text = TextboxConfig.Default

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(TextboxFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(TextboxFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
						}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(TextboxFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)
						}):Play()
					TextboxActual:CaptureFocus()
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(TextboxFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
							BackgroundColor3 = Color3.fromRGB(
								OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6,
								OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)
						}):Play()
				end)
			end

			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function()
				end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
				ColorpickerConfig.Save = ColorpickerConfig.Save or false

				local ColorH, ColorS, ColorV = 1, 1, 1
				local ColorInput,HueInput
				local Colorpicker = {
					Value = ColorpickerConfig.Default,
					Toggled = false,
					Save = ColorpickerConfig.Save
				}
				
				if ColorpickerConfig.Flag then OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker end

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -25, 1, 0),
					Visible = false,
					Image = "rbxassetid://4155801252"
				}, {Create("UICorner", {
					CornerRadius = UDim.new(0, 5)
				}), ColorSelection})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -20, 0, 0),
					Visible = false
				}, {Create("UIGradient", {
					Rotation = 270,
					Color = ColorSequence.new {ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
						ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
						ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
						ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
						ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))}
				}), Create("UICorner", {
						CornerRadius = UDim.new(0, 5)
					}), HueSelection})

				local ColorpickerContainer = Create("Frame", {
					Position = UDim2.new(0, 0, 0, 32),
					Size = UDim2.new(1, 0, 1, -32),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {Hue, Color, Create("UIPadding", {
					PaddingLeft = UDim.new(0, 35),
					PaddingRight = UDim.new(0, 35),
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 17)
				})})

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ColorpickerBox = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
						Size = UDim2.new(0, 24, 0, 24),
						Position = UDim2.new(1, -12, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5)
					}), {AddThemeObject(MakeElement("Stroke"), "Stroke")}), "Main")

				local ColorpickerFrame = AddThemeObject(SetChildren(
					SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
						Size = UDim2.new(1, 0, 0, 38),
						Parent = ItemParent
					}), {SetProps(SetChildren(MakeElement("TFrame"),
						{AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "Text"), ColorpickerBox, Click, AddThemeObject(
								SetProps(MakeElement("Frame"), {
									Size = UDim2.new(1, 0, 0, 1),
									Position = UDim2.new(0, 0, 1, -1),
									Name = "Line",
									Visible = false
								}), "Stroke")}), {
							Size = UDim2.new(1, 0, 0, 38),
							ClipsDescendants = true,
							Name = "F"
						}), ColorpickerContainer, AddThemeObject(MakeElement("Stroke"), "Stroke")}),
					"Second")

					ColorpickerFrame.Name = 'Colorpicker'

				AddConnection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					TweenService:Create(ColorpickerFrame,
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 148) or UDim2.new(1, 0, 0, 38)
						}):Play()
					Color.Visible = Colorpicker.Toggled
					Hue.Visible = Colorpicker.Toggled
					ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)

				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					Colorpicker:Set(ColorpickerBox.BackgroundColor3)
					CatchError(ColorpickerConfig,ColorpickerBox.BackgroundColor3)
					SaveCfg()
				end

				ColorH = 1 -
					(math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) /
						Hue.AbsoluteSize.Y)
				ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0,
					Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
				ColorV = 1 -
					(math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0,
						Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)

				AddConnection(Color.InputBegan, function(input)
					if not table.find(InputKeys['Input'],input.UserInputType) then return end
					if ColorInput then ColorInput:Disconnect() end
					ColorInput = AddConnection(RunService.RenderStepped, function()
						local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) /
							Color.AbsoluteSize.X)
						local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) /
							Color.AbsoluteSize.Y)
						ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
						ColorS = ColorX
						ColorV = 1 - ColorY
						UpdateColorPicker()
					end)
				end)

				AddConnection(Color.InputEnded, function(input)
					if not table.find(InputKeys['Input'],input.UserInputType) then return end
					if ColorInput then ColorInput:Disconnect() end
				end)

				AddConnection(Hue.InputBegan, function(input)
					if not table.find(InputKeys['Input'],input.UserInputType) then return end
					if HueInput then HueInput:Disconnect() end
					HueInput = AddConnection(RunService.RenderStepped, function()
						local HueY = math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y
						HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
						ColorH = 1 - HueY
						UpdateColorPicker()
					end)
				end)

				AddConnection(Hue.InputEnded, function(input)
					if not table.find(InputKeys['Input'],input.UserInputType) then return end
					if HueInput then HueInput:Disconnect() end
				end)

				function Colorpicker:Set(Value,Loading)
					if Value == nil or not OrionLib:IsRunning() then return end
					Colorpicker.Value = Value
					ColorpickerBox.BackgroundColor3 = Colorpicker.Value
					if Loading and not Value then return end
					CatchError(ColorpickerConfig,Colorpicker.Value)
				end

				Colorpicker:Set(Colorpicker.Value,true)
				return Colorpicker
			end

			return ElementFunction
		end

		local ElementFunction = {}

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 26),
				Parent = Container
			}), {AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
				Size = UDim2.new(1, -12, 0, 16),
				Position = UDim2.new(0, 0, 0, 3),
				Font = Enum.Font.GothamSemibold
			}), "TextDark"), SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0, 0),
				Size = UDim2.new(1, 0, 1, -24),
				Position = UDim2.new(0, 0, 0, 23),
				Name = "Holder"
			}), {MakeElement("List", 0, 6)})})

			SectionFrame.Name = 'Section'

			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}
			for i, v in next, GetElements(SectionFrame.Holder) do SectionFunction[i] = v end
			return SectionFunction
		end

		for i, v in next, GetElements(Container) do ElementFunction[i] = v end

		return ElementFunction
	end
	table.insert(self.MainWindows,TabFunction)
	return TabFunction
end

function OrionLib:Destroy() OrionUI:Destroy() end

local function OnExit() -- 停止运行后的处理
	for _, Connection in next, OrionLib.Connections do Connection:Disconnect() end
	SaveCfg()
end

task.spawn(function()
	while OrionLib:IsRunning() do task.wait() end
	OnExit()
end)
AddConnection(game:GetService('Players').PlayerRemoving,function(plr)
	if plr ~= LocalPlayer then return end
	OnExit()
end)

return OrionLib