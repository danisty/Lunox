local Lunox = game.CoreGui:FindFirstChild("Lunox") or Instance.new("Folder")
local TempScreen = Instance.new("ScreenGui")

local Loading = Instance.new("Frame")
local LoadingTitle = Instance.new("TextLabel")
local Progress = Instance.new("Frame")
local Bar = Instance.new("Frame")
local CurrentResource = Instance.new("TextLabel")
local Default = Instance.new("TextLabel")

Lunox.Name = "Lunox"
Lunox.Parent = game.CoreGui

TempScreen.Name = "TempScreen"
TempScreen.Parent = Lunox

Loading.Name = "Loading"
Loading.Parent = TempScreen
Loading.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
Loading.BorderColor3 = Color3.fromRGB(30, 136, 229)
Loading.Position = UDim2.new(0.5, -170, 0.5, -40)
Loading.Size = UDim2.new(0, 340, 0, 51)

LoadingTitle.Name = "LoadingTitle"
LoadingTitle.Parent = Loading
LoadingTitle.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
LoadingTitle.BorderColor3 = Color3.fromRGB(30, 30, 30)
LoadingTitle.BorderSizePixel = 0
LoadingTitle.Size = UDim2.new(1, 0, 0, 25)
LoadingTitle.Font = Enum.Font.SourceSansLight
LoadingTitle.Text = "Now Loading"
LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingTitle.TextSize = 20

Progress.Name = "Progress"
Progress.Parent = Loading
Progress.BackgroundColor3 = Color3.fromRGB(11, 52, 88)
Progress.BorderSizePixel = 0
Progress.Position = UDim2.new(0, 0, 1, -5)
Progress.Size = UDim2.new(1, 0, 0, 5)

Bar.Name = "Bar"
Bar.Parent = Progress
Bar.BackgroundColor3 = Color3.fromRGB(30, 136, 229)
Bar.BorderSizePixel = 0
Bar.Size = UDim2.new(0, 0, 0, 5)

CurrentResource.Name = "CurrentResource"
CurrentResource.Parent = Loading
CurrentResource.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CurrentResource.BackgroundTransparency = 1.000
CurrentResource.Position = UDim2.new(0, 5, 0, 27)
CurrentResource.Selectable = true
CurrentResource.Size = UDim2.new(1, -5, 0, 21)
CurrentResource.Font = Enum.Font.SourceSans
CurrentResource.Text = "If you see this, something went wrong."
CurrentResource.TextColor3 = Color3.fromRGB(150, 150, 150)
CurrentResource.TextSize = 17.000
CurrentResource.TextXAlignment = Enum.TextXAlignment.Left
CurrentResource.TextYAlignment = Enum.TextYAlignment.Top

Default.Name = "Default"
Default.Parent = TabContent
Default.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Default.BackgroundTransparency = 1.000
Default.Position = UDim2.new(0, 6, 0, -10)
Default.Size = UDim2.new(1, -14, 1, 0)
Default.Font = Enum.Font.SourceSans
Default.Text = '<br/><font size="24">Welcome to Lunox!</font><br/><font color="#999999">This project is still under development. You can find all available tools at <font color="#42a5f5">Tools</font>.</font>'
Default.TextColor3 = Color3.fromRGB(181, 181, 181)
Default.TextSize = 16.000
Default.TextWrapped = true
Default.RichText = true
Default.TextXAlignment = Enum.TextXAlignment.Left
Default.TextYAlignment = Enum.TextYAlignment.Top

--// Services
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HTTPS = game:GetService("HttpService")

--// Loader
local baseUrl = "https://raw.githubusercontent.com/danisty/lunox/main/"
local main, modulesInfo = LunoxData or {
	modules={}
}, {
	{ Name="Utils", Info="[Internal] Utilities." },
	{ Name="Library", Info="[UI] Library." },
	{ Name="EnvironmentBrowser", Info="[Tools] Environment Browser." }
}
local tools = {}

local function getSize(t)
	local c = 0
	for i,v in pairs(t) do
		c = c + 1
	end
	return c
end

local function require(module)
	local success, rawModule = pcall(function()
		return game:HttpGet(baseUrl .. "modules/" .. module)
	end)
	return success and loadstring(rawModule)(main) or nil
end

if not LunoxData then
	local p, s = 1, getSize(modulesInfo)
	for i, module in pairs(modulesInfo) do
		CurrentResource.Text = module.Info
		TS:Create(Bar, TweenInfo.new(.2, Enum.EasingStyle.Linear), {
			Size=UDim2.new(p/s, 0, 0, 5)
		}):Play()

		main.modules[module.Name] = require(module.Name .. ".lua")
		p = p + 1
	end
end
for _,module in pairs(main.modules) do
	if module.Tool then
		table.insert(tools, module.Tool.Name)
	end
end
TempScreen:Destroy()

--// Interface
local menuBarCallbacks = {
	File={},
	Tools=setmetatable({}, {
		__index=function(self, key)
			return function(window)
				local tool = main.modules[table.concat(key:split(" "), "")]
				local tabControl = window.TabControl:AddTab(tool.Tool.Name)
				local toolInstance = tool:Initialize(window, tabControl.Content)
				tabControl.CloseCallback = toolInstance.Terminate
				table.insert(window.LoadedTools, toolInstance)
			end
		end
	})
}

local function CreateWindow()
	local Window = main.modules.Library:Window("LUNOX", 6865413952, nil, Lunox)
	Window.TabControl = main.modules.Library:TabControl(Window.__Instance.Main.Body, Default:Clone())
	Window.MenuBar = main.modules.Library:MenuBar(Window.__Instance.Main.TitleBar, UDim2.new(0, 80, 0, 0), {
		{"File", {"New Window"}},
		{"Tools", tools}
	}, function(menuOption, contextOption)
		menuBarCallbacks[menuOption][contextOption](Window)
	end)
	Window.__Instance.DisplayOrder = 50
end

--getgenv().LunoxData = main
menuBarCallbacks.File["New Window"] = CreateWindow
CreateWindow()