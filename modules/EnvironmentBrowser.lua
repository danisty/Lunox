local main = ...
local modules = main.modules
local utils = modules.Utils
local menuItem = modules.Library.MenuItem

--// Services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local VU = game:GetService("VirtualUser")

local Adapters = {}
local EnvironmentBrowser = {
	Tool={
		Name="Environment Browser",
		Icon=nil
	}
}

local selectionColors = {
	Default=Color3.fromRGB(27, 121, 204),
	Started=Color3.fromRGB(29, 130, 219),
	Hovering=Color3.fromRGB(28, 126, 212)
}

local currentScript;
local function filterGarbage(script, pause)
	local data = {}
	local source = script:GetFullName()
	currentScript = script
	for i,v in pairs(getgc()) do
		if getinfo(v).source:sub(2) == source then
			data[#data+1] = v
		end
		if currentScript ~= script then
			return nil
		end
		if pause and i % 300 == 0 then
			wait()
		end
	end
	return data
end

local function getIndex(t, index)
	local c = 1
	for i,v in pairs(t) do
		if index == c then
			return i
		end
		c = c + 1
	end
end

local returnFromModule = '<font color="#1e88e5">[Return From Module]</font>'
local waterMark = "--// Script generated with Lunox [Environment Browser]\n"
local templates = {
	Garbage="local function filterGarbage(script)\n\tlocal values = {}\n\tlocal source = script:GetFullName()\n\tfor i,v in pairs(getgc()) do\n\t\tif getinfo(v).source:sub(2) == source then\n\t\t\tvalues[#values+1] = v\n\t\tend\n\tend\n\treturn values\nend",
	ValueIndex="local function getIndex(t, index)\n\tlocal c = 1\n\tfor i,v in pairs(t) do\n\t\tif index == c then\n\t\t\treturn i\n\t\tend\n\t\tc = c + 1\n\tend\nend"
}

local function filterRequire(module)
	local r = require(module)
	return {[returnFromModule]=r}
end

local valueTypes = {
	LocalScript={{"Script Environment", getsenv, "getsenv", "s"}, {"Garbage", filterGarbage, "filterGarbage", "g"}},
	ModuleScript={{"Module Return", filterRequire, "require", "m"}, {"Garbage", filterGarbage, "filterGarbage", "g"}},
	["function"]={{"Upvalues", getupvalues, "debug.getupvalues", "u"}, {"Constants", getconstants, "debug.getconstants", "c"}, {"Protos", getprotos, "debug.getprotos", "p"}, {"Function Environment", getfenv, "getfenv", "f"}},
	["table"]={{"Table Entries", function(t) return t end, "pairs", "t"}, {"Metatable", getrawmetatable, "getrawmetatable", "m"}},
	["userdata"]={{"Metatable", getrawmetatable, "getrawmetatable", "m"}}
}

--// Filter scripts
local player = game.Players.LocalPlayer
local blacklist = {
	"PlayerScriptsLoader.", "StarterGui.", "CorePackages.", "CoreGui.RobloxGui.",
	"Chat.", "StarterPlayer.", "StarterPack.", "Lighting.",
	"Players." .. player.Name .. ".PlayerScripts.ChatScript.",
	"Players." .. player.Name .. ".PlayerScripts.PlayerModule."
}
for i,p in pairs(game.Players:GetPlayers())do
	if p ~= player then
		table.insert(blacklist, "Players." .. p.Name)
		coroutine.wrap(function() --// Their character may not exist
			table.insert(blacklist, (p.Character or p.CharacterAdded:Wait()):GetFullName())
		end)()
	end
end
game.Players.PlayerAdded:Connect(function(p)
	if p ~= player then
		table.insert(blacklist, "Players." .. p.Name)
		coroutine.wrap(function()
			table.insert(blacklist, (p.Character or p.CharacterAdded:Wait()):GetFullName())
		end)()
	end
end)

local function isValidScript(script)
	local source = script:GetFullName()
	for i,v in pairs(blacklist) do
		if source:sub(1, #v) == v then --// Faster than string.find in this case
			return false
		end
	end
	return blacklist
end

local function createValueType(type)
	local Type = Instance.new("TextButton")
	local Name = Instance.new("TextLabel")
	local Icon = Instance.new("ImageLabel")
	local Count = Instance.new("TextLabel")

	Type.Name = "Type"
	Type.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Type.BorderSizePixel = 0
	Type.Size = UDim2.new(1, 0, 0, 25)
	Type.ZIndex = 2
	Type.AutoButtonColor = false
	Type.Font = Enum.Font.SourceSans
	Type.Text = ""
	Type.TextColor3 = Color3.fromRGB(255, 255, 255)
	Type.TextSize = 14.000

	Name.Name = "TypeName"
	Name.Parent = Type
	Name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Name.BackgroundTransparency = 1.000
	Name.Position = UDim2.new(0, 25, 0, 0)
	Name.Size = UDim2.new(1, -25, 1, 0)
	Name.ZIndex = 2
	Name.Font = Enum.Font.SourceSans
	Name.Text = type
	Name.TextColor3 = Color3.fromRGB(255, 255, 255)
	Name.TextSize = 14.000
	Name.TextXAlignment = Enum.TextXAlignment.Left

	Icon.Name = "Icon"
	Icon.Parent = Type
	Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Icon.BackgroundTransparency = 1.000
	Icon.Position = UDim2.new(0, 4, 0, 5)
	Icon.Size = UDim2.new(0, 16, 0, 16)
	Icon.ZIndex = 2
	Icon.ImageRectOffset = Vector2.new(0, 32)
	Icon.ImageRectSize = Vector2.new(16, 16)
	Icon.ScaleType = Enum.ScaleType.Crop
	Icon.SliceScale = 0.000
	Icon.TileSize = UDim2.new(0, 16, 0, 16)

	Count.Name = "Count"
	Count.Parent = Type
	Count.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Count.BackgroundTransparency = 1
	Count.Text = "?"
	Count.Position = UDim2.new(0, 0, 0, 0)
	Count.Size = UDim2.new(0, 25, 0, 25)
	Count.ZIndex = 2
	Count.Font = Enum.Font.SourceSans
	Count.Text = type
	Count.TextColor3 = Color3.fromRGB(255, 255, 255)
	Count.TextSize = 14

	return Type
end

local function createPathPart(pathInfo)
	local Part = Instance.new("Frame")
	local Listener = Instance.new("TextButton")
	local Arrow = Instance.new("TextButton")

	local text = tostring(pathInfo.Script and pathInfo.Script.Name or pathInfo.Index):gsub("\n", "")
	if #text > 25 and text ~= returnFromModule then
		text = text:sub(1, 25) .. "..."
	end

	Part.Name = "Part"
	Part.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Part.BackgroundTransparency = 1.000
	Part.Size = UDim2.new(0, 85, 0, 25)

	Listener.Name = "Listener"
	Listener.Parent = Part
	Listener.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Listener.BorderColor3 = Color3.fromRGB(30, 136, 229)
	Listener.BorderSizePixel = 0
	Listener.Text = text
	Listener.Font = Enum.Font.SourceSans
	Listener.RichText = true
	Listener.TextColor3 = Color3.fromRGB(255, 255, 255)
	Listener.TextSize = 14.000
	Listener.BorderMode = Enum.BorderMode.Inset
	Listener.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)

	Arrow.Name = "Arrow"
	Arrow.Parent = Part
	Arrow.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Arrow.BorderColor3 = Color3.fromRGB(30, 136, 229)
	Arrow.BorderSizePixel = 0
	Arrow.Position = UDim2.new(1, -14, 0, 0)
	Arrow.Size = UDim2.new(0, 14, 0, 25)
	Arrow.Font = Enum.Font.SciFi
	Arrow.Text = "›"
	Arrow.TextColor3 = Color3.fromRGB(255, 255, 255)
	Arrow.TextSize = 14.000
	Arrow.BorderMode = Enum.BorderMode.Inset
	Arrow.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)

	local function onMouseEnter()
		Arrow.BorderSizePixel = 1
		Listener.BorderSizePixel = 1
	end

	local function onMouseLeave()
		if not utils:inArea(Part) then
			Arrow.BorderSizePixel = 0
			Listener.BorderSizePixel = 0
		end
	end

	Listener.MouseEnter:Connect(onMouseEnter)
	Arrow.MouseEnter:Connect(onMouseEnter)

	Listener.MouseLeave:Connect(onMouseLeave)
	Arrow.MouseLeave:Connect(onMouseLeave)

	return Part
end

local function generateScript(explorerPath, pathDepth)
	local compactEnvIndex = 0
	local compactOutput = ""
	local stepEnvIndex = 0
	local stepOutput = ""
	local hasUnknownIndex = false
	
	for i = 1, pathDepth do
		local part = explorerPath[i]
		local indexType = type(part.Index)
		if part.Script then
			compactOutput = part.Type[3] .. "(" .. utils:getPath(part.Script) .. ")"
			stepOutput = compactOutput
		else
			local isModuleReturn = part.Index == returnFromModule
			local index = isModuleReturn and "" or utils:fixIndex(part.Index)
			local isLast = i == pathDepth and part.Type[3]:find("debug")

			if part.Type[1] == "Table Entries" or (isLast and not isModuleReturn) then
				local compactEnvIndexStr = compactEnvIndex == 0 and "" or tostring(compactEnvIndex)
				local stepEnvIndexStr = stepEnvIndex == 0 and "" or tostring(stepEnvIndex)
				local isValidIndex = indexType == "string" or indexType == "number"

				if not isValidIndex then
					hasUnknownIndex = true

					compactOutput = compactOutput .. ("\nlocal env%s = env%s"):format(compactEnvIndex + 1, compactEnvIndexStr)
					stepOutput = stepOutput .. ("\nlocal env%s = env%s"):format(stepEnvIndex + 1, stepEnvIndexStr)

					compactEnvIndex += 1
					stepEnvIndex += 1
				end

				compactOutput = compactOutput .. (isValidIndex and index or ("[getIndex(env%s, %d)]"):format(compactEnvIndexStr, part.ArrayIndex))
				stepOutput = stepOutput .. (isValidIndex and index or ("[getIndex(env%s, %d)]"):format(stepEnvIndexStr, part.ArrayIndex))
			else
				stepOutput = stepOutput .. ("\nlocal env%d = %s(env%s%s)"):format(stepEnvIndex + 1, part.Type[3], stepEnvIndex > 0 and tostring(stepEnvIndex) or "", index)
				compactOutput = ("%s(%s%s)"):format(part.Type[3], compactOutput, index)
				stepEnvIndex += 1
			end
		end
	end

	return {
		Compact="local env = " .. compactOutput,
		Step="local env = " .. stepOutput,
		CompactEnv="env" .. (compactEnvIndex > 0 and compactEnvIndex or ""),
		StepEnv="env" .. (stepEnvIndex > 0 and stepEnvIndex or ""),
		HasUnknownIndex=hasUnknownIndex
	}
end

local function serialize(explorerPath, pathDepth)
	local parts = {}
	for i = 1, pathDepth do
		local part = explorerPath[i]
		if part.Index == returnFromModule then
			parts[1] = parts[1]:sub(1, 1) .. part.Type[4] .. parts[1]:sub(2)
		else
			local indexType = type(part.Index)
			local isValidIndex = indexType == "string" or indexType == "number"
			local index = isValidIndex and tostring(part.Index):gsub("\\", "%%b") or part.ArrayIndex
			table.insert(parts, ("%s:%s"):format(part.Type[4] .. (part.Script and "" or (isValidIndex and type(part.Index):sub(1,1) or "o")),  part.Script and utils:getPath(part.Script) or index))
		end
	end
	return table.concat(parts, "\\")
end

local function deserialize(path)
	local explorerPath = {}
	local parts = path:split("\\")
	local depth = 1
	local prevValues;
	
	for _,part in pairs(parts) do
		part = part:gsub("%%b", "\\")
		local info, index = unpack(part:split(":"))
		local script = prevValues == nil and utils:fromPath(index or info)
		
		if index == nil then
			index = info
			info = valueTypes[script.ClassName][1][4]
		end
		
		local valueType, indexType = unpack(info:split(""))
		local parsedIndex = indexType=="n" and tonumber(index) or (indexType=="o" and getIndex(prevValues, tonumber(index)) or index:gsub("%%b", "\\"))

		local value = prevValues ~= nil and prevValues[parsedIndex]
		local types = valueTypes[depth == 1 and script.ClassName or typeof(value)]
		local _, type = utils:find(types, function(_, t) return t[4] == valueType end)

		if depth == 1 then
			prevValues = type[2](script)
			explorerPath[depth] = { Type=type, Value=script, Script=script }

			if indexType ~= nil then --// Module Script return
				depth += 1
				prevValues = prevValues[returnFromModule]

				local _, type = utils:find(valueTypes[typeof(prevValues)], function(_, t) return t[4] == indexType end)
				explorerPath[depth] = { Index=returnFromModule, Type=type, Value=prevValues }
			end
		else
			prevValues = type[2](value)
			explorerPath[depth] = { Index=parsedIndex, Type=type, Value=value, ArrayIndex=indexType=="o" and tonumber(index) or nil }
		end

		depth += 1
	end

	return explorerPath
end

local function Load(window, root, tool)
	local ScriptsList = Instance.new("Frame")
	local ScriptsOptions = Instance.new("Frame")
	local SearchBox = Instance.new("TextBox")
	local FilterScripts = Instance.new("ImageButton")
	local SearchIcon = Instance.new("ImageLabel")
	local RefreshScripts = Instance.new("ImageButton")
	local ScriptsDropShadow = Instance.new("Frame")
	local Explorer = Instance.new("Frame")
	local ExplorerOptions = Instance.new("Frame")
	local Generate = Instance.new("ImageButton")
	local Back = Instance.new("ImageButton")
	local Forward = Instance.new("ImageButton")
	local Refresh = Instance.new("ImageButton")
	local Path = Instance.new("Frame")
	local PathParts = Instance.new("ScrollingFrame")
	local PathLayout = Instance.new("UIListLayout")
	local AbsolutePath = Instance.new("ScrollingFrame")
	local AbsolutePathInput = Instance.new("TextBox")
	local ExplorerDropShadow = Instance.new("Frame")
	local ValueTypes = Instance.new("ScrollingFrame")
	local ValueTypesLayout = Instance.new("UIListLayout")
	local FavouritePaths = Instance.new("ScrollingFrame")
	local FavouritePathsLayout = Instance.new("UIListLayout")
	local PathRecyclerHandle = Instance.new("Frame")

	ScriptsList.Name = "ScriptsList"
	ScriptsList.Parent = root
	ScriptsList.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	ScriptsList.BorderColor3 = Color3.fromRGB(30, 30, 30)
	ScriptsList.BorderSizePixel = 0
	ScriptsList.Size = UDim2.new(0, 180, 1, 0)
	ScriptsList.ZIndex = 2

	ScriptsOptions.Name = "ScriptsOptions"
	ScriptsOptions.Parent = ScriptsList
	ScriptsOptions.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	ScriptsOptions.BorderSizePixel = 0
	ScriptsOptions.Size = UDim2.new(1, 0, 0, 25)
	ScriptsOptions.ZIndex = 2

	SearchBox.Name = "SearchBox"
	SearchBox.Parent = ScriptsOptions
	SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	SearchBox.BackgroundTransparency = 1.000
	SearchBox.BorderSizePixel = 0
	SearchBox.ClipsDescendants = true
	SearchBox.Position = UDim2.new(0, 25, 0, 0)
	SearchBox.Size = UDim2.new(1, -75, 0, 25)
	SearchBox.ZIndex = 2
	SearchBox.ClearTextOnFocus = false
	SearchBox.Font = Enum.Font.SourceSans
	SearchBox.PlaceholderText = "Search Script..."
	SearchBox.Text = ""
	SearchBox.TextColor3 = Color3.fromRGB(233, 233, 233)
	SearchBox.TextSize = 14.000
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left

	FilterScripts.Name = "FilterScripts"
	FilterScripts.Parent = ScriptsOptions
	FilterScripts.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	FilterScripts.BorderSizePixel = 0
	FilterScripts.Position = UDim2.new(1, -50, 0, 0)
	FilterScripts.Size = UDim2.new(0, 25, 0, 25)
	FilterScripts.ZIndex = 2
	FilterScripts.Image = "rbxassetid://6875536784"

	SearchIcon.Name = "SearchIcon"
	SearchIcon.Parent = ScriptsOptions
	SearchIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SearchIcon.BackgroundTransparency = 1.000
	SearchIcon.Size = UDim2.new(0, 25, 0, 25)
	SearchIcon.ZIndex = 2
	SearchIcon.Image = "rbxassetid://6875607749"

	RefreshScripts.Name = "RefreshScripts"
	RefreshScripts.Parent = ScriptsOptions
	RefreshScripts.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	RefreshScripts.BorderSizePixel = 0
	RefreshScripts.Position = UDim2.new(1, -25, 0, 0)
	RefreshScripts.Size = UDim2.new(0, 25, 0, 25)
	RefreshScripts.ZIndex = 2
	RefreshScripts.Image = "rbxassetid://7203691992"

	ScriptsDropShadow.Name = "DropShadow"
	ScriptsDropShadow.Parent = ScriptsList
	ScriptsDropShadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ScriptsDropShadow.BorderSizePixel = 0
	ScriptsDropShadow.Position = UDim2.new(0, 0, 0, -4)
	ScriptsDropShadow.Size = UDim2.new(1, 5, 1, 8)
	ScriptsDropShadow.Style = Enum.FrameStyle.DropShadow

	Explorer.Name = "Explorer"
	Explorer.Parent = root
	Explorer.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Explorer.BorderSizePixel = 0
	Explorer.Position = UDim2.new(0, 180, 0, 0)
	Explorer.Size = UDim2.new(1, -330, 1, 0)

	ExplorerOptions.Name = "ExplorerOptions"
	ExplorerOptions.Parent = Explorer
	ExplorerOptions.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	ExplorerOptions.BorderSizePixel = 0
	ExplorerOptions.Size = UDim2.new(1, 0, 0, 25)
	ExplorerOptions.ZIndex = 2

	Generate.Name = "Generate"
	Generate.Parent = ExplorerOptions
	Generate.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Generate.BorderSizePixel = 0
	Generate.Position = UDim2.new(1, -50, 0, 0)
	Generate.Size = UDim2.new(0, 25, 0, 25)
	Generate.ZIndex = 2
	Generate.Image = "rbxassetid://6875932153"

	Back.Name = "Back"
	Back.Parent = ExplorerOptions
	Back.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Back.BorderSizePixel = 0
	Back.Size = UDim2.new(0, 25, 0, 25)
	Back.ZIndex = 2
	Back.ImageColor3 = Color3.fromRGB(120, 120, 120)
	Back.Image = "rbxassetid://6875665107"

	Forward.Name = "Forward"
	Forward.Parent = ExplorerOptions
	Forward.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Forward.BorderSizePixel = 0
	Forward.Position = UDim2.new(0, 25, 0, 0)
	Forward.Size = UDim2.new(0, 25, 0, 25)
	Forward.ZIndex = 2
	Forward.ImageColor3 = Color3.fromRGB(120, 120, 120)
	Forward.Image = "rbxassetid://6875803625"

	Refresh.Name = "Refresh"
	Refresh.Parent = ExplorerOptions
	Refresh.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Refresh.BorderSizePixel = 0
	Refresh.Position = UDim2.new(1, -25, 0, 0)
	Refresh.Size = UDim2.new(0, 25, 0, 25)
	Refresh.ZIndex = 2
	Refresh.Image = "rbxassetid://7203691992"

	Path.Name = "Path"
	Path.Parent = ExplorerOptions
	Path.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Path.BackgroundTransparency = 1.000
	Path.ClipsDescendants = true
	Path.Position = UDim2.new(0, 50, 0, 0)
	Path.Size = UDim2.new(1, -100, 0, 25)

	PathParts.Name = "PathParts"
	PathParts.Parent = Path
	PathParts.Active = true
	PathParts.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	PathParts.ScrollBarThickness = 0
	PathParts.BorderSizePixel = 0
	PathParts.Size = UDim2.new(1, 0, 0, 25)

	PathLayout.Name = "Layout"
	PathLayout.Parent = PathParts
	PathLayout.FillDirection = Enum.FillDirection.Horizontal
	PathLayout.SortOrder = Enum.SortOrder.LayoutOrder
	PathLayout.Padding = UDim.new(0, 1)

	AbsolutePath.Name = "AbsolutePath"
	AbsolutePath.Parent = Path
	AbsolutePath.Active = true
	AbsolutePath.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	AbsolutePath.ScrollBarThickness = 2
	AbsolutePath.Visible = false
	AbsolutePath.BorderSizePixel = 0
	AbsolutePath.Size = UDim2.new(1, 0, 0, 25)

	AbsolutePathInput.Name = "AbsolutePathInput"
	AbsolutePathInput.Parent = AbsolutePath
	AbsolutePathInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	AbsolutePathInput.BackgroundTransparency = 1
	AbsolutePathInput.ClearTextOnFocus = false
	AbsolutePathInput.BorderSizePixel = 0
	AbsolutePathInput.Position = UDim2.new(0, 5, 0, 0)
	AbsolutePathInput.Size = UDim2.new(1, -5, 0, 25)
	AbsolutePathInput.Font = Enum.Font.SourceSans
	AbsolutePathInput.PlaceholderText = "Script path [Ex: game.Players.LocalPlayer.PlayerScripts.LocalScript]"
	AbsolutePathInput.Text = ""
	AbsolutePathInput.TextColor3 = Color3.fromRGB(233, 233, 233)
	AbsolutePathInput.TextSize = 14
	AbsolutePathInput.TextXAlignment = Enum.TextXAlignment.Left

	ExplorerDropShadow.Name = "DropShadow"
	ExplorerDropShadow.Parent = Explorer
	ExplorerDropShadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ExplorerDropShadow.BorderSizePixel = 0
	ExplorerDropShadow.Position = UDim2.new(0, 0, 0, -4)
	ExplorerDropShadow.Size = UDim2.new(1, 5, 1, 8)
	ExplorerDropShadow.Style = Enum.FrameStyle.DropShadow

	ValueTypes.Name = "ValueTypes"
	ValueTypes.Parent = root
	ValueTypes.Active = true
	ValueTypes.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	ValueTypes.BorderSizePixel = 0
	ValueTypes.Position = UDim2.new(1, -150, 0, 0)
	ValueTypes.Size = UDim2.new(0, 150, 0.5, 0)
	ValueTypes.ZIndex = 0
	ValueTypes.BottomImage = "rbxassetid://6721574480"
	ValueTypes.CanvasSize = UDim2.new(0, 0, 0, 0)
	ValueTypes.MidImage = "rbxassetid://6721574480"
	ValueTypes.ScrollBarThickness = 4
	ValueTypes.TopImage = "rbxassetid://6721574480"

	ValueTypesLayout.Name = "Layout"
	ValueTypesLayout.Parent = ValueTypes
	ValueTypesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ValueTypesLayout.Padding = UDim.new(0, 1)

	FavouritePaths.Name = "FavouritePaths"
	FavouritePaths.Parent = root
	FavouritePaths.Active = true
	FavouritePaths.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	FavouritePaths.BorderSizePixel = 0
	FavouritePaths.Position = UDim2.new(1, -150, 0.5, 0)
	FavouritePaths.Size = UDim2.new(0, 150, 0.5, 0)
	FavouritePaths.ZIndex = 0
	FavouritePaths.BottomImage = "rbxassetid://6721574480"
	FavouritePaths.CanvasSize = UDim2.new(0, 0, 0, 0)
	FavouritePaths.MidImage = "rbxassetid://6721574480"
	FavouritePaths.ScrollBarThickness = 4
	FavouritePaths.TopImage = "rbxassetid://6721574480"

	FavouritePathsLayout.Name = "Layout"
	FavouritePathsLayout.Parent = ValueTypes
	FavouritePathsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	FavouritePathsLayout.Padding = UDim.new(0, 1)

	PathRecyclerHandle.Name = "PathRecyclerHandle"
	PathRecyclerHandle.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	PathRecyclerHandle.BorderSizePixel = 1
	PathRecyclerHandle.BorderColor3 = Color3.fromRGB(30, 136, 229)

	local explorerPath = {}
	local pathHistory = {}
	local selectedValues = {}
	local pathParts = {}
	local searchFilter = {}
	local favouritePaths = {}
	local pathDepth = 0
	local historyDepth = 0

	local configurePathValue;
	local updateValueTypes;
	local selectValueType;
	local selectedScript;
	local selectedValueType;

	searchFilter.Filter = {
		LocalScripts=menuItem.CheckBox("LocalScripts", true),
		ModuleScripts=menuItem.CheckBox("ModuleScripts", true)
	}

	local scriptsAdapter = Adapters.Scripts()
	local scriptsRecycler = modules.Library:RecyclerFrame(ScriptsList, UDim2.new(0, 0, 0, 25), UDim2.new(1, 0, 1, -25), scriptsAdapter)

	local explorerAdapter = Adapters.Explorer()
	local explorerRecycler = modules.Library:RecyclerFrame(Explorer, UDim2.new(0, 0, 0, 25), UDim2.new(1, 0, 1, -25), explorerAdapter)

	local pathAdapter = Adapters.Explorer()
	local pathRecycler = modules.Library:RecyclerFrame(PathRecyclerHandle, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), pathAdapter)

	local valueOptions = {
		["Copy Value(s)"] = function(data, contextMenu)
			local values = {}
			local part = explorerPath[pathDepth]
			local output = generateScript(explorerPath, pathDepth, true)
			local absolutePath = output.Compact:gsub("local " .. output.CompactEnv .. " = ", "")

			local hasUnknownIndex = false
			local isDebug = part.Type[3]:find("debug")
			local steps = absolutePath:split("\n")
			
			local extra = ""
			if output.HasUnknownIndex then
				--// First check for path indices
				absolutePath = steps[#steps]
			end
			
			for i,v in pairs(selectedValues) do
				local data = explorerAdapter.Data[i]
				local value = utils:stringify(data.Value)

				if data.Index == returnFromModule then
					values[#values+1] = absolutePath
				elseif value ~= nil then
					values[#values+1] = value
				else
					local indexType = type(data.Index)
					local isValidIndex = indexType == "string" or indexType == "number"

					if output.HasUnknownIndex then
						hasUnknownIndex = true
					end

					if isDebug then
						values[#values+1] = ("%s(%s, %d)"):format(part.Type[3]:sub(1, -2), absolutePath, data.Index)
					else
						if isValidIndex then
							values[#values+1] = absolutePath .. utils:fixIndex(data.Index)
						else
							hasUnknownIndex = true
							values[#values+1] = output.CompactEnv .. ("[getIndex(%s, %d)]"):format(output.CompactEnv, i)
						end
					end
				end
			end

			if hasUnknownIndex then
				--// Second check for values indices
				extra = templates.ValueIndex .. "\n\n"
				if output.HasUnknownIndex then
					extra = extra .. table.concat(steps, "\n", 1, #steps-1) .. "\n\n"
				else
					extra = extra .. output.Compact .. "\n\n"
				end
			end

			setclipboard(extra .. table.concat(values, "\n"))
		end, 
		Favourite = function(data, contextMenu)
			local output = generateScript(explorerPath, pathDepth)
			local path = favouritePaths[data]
		end
	}

	local generateOptions = modules.Library:ContextMenu(Generate, window.__Instance, UDim2.new(0, -50, 1, 0), {"Step by step output", "Compact output"}, function(option)
		local output = generateScript(explorerPath, pathDepth)
		local isCompact = option == "Compact output"
		local valuesOutput = "\n"

		local path = explorerPath[pathDepth]
		local isDebugValue = type(path.Value) == "function" and path.Type[3] ~= "getfenv"
		local setter = path.Type[3]:sub(1, -2):gsub("get", "set")

		local hasUnknownValue = false
		local hasUnknownIndex = output.HasUnknownIndex
		env = isCompact and output.CompactEnv or output.StepEnv

		local count = 1
		local useSelection = utils:getSize(selectedValues) > 0
		for i,v in pairs(path.Type[2](path.Value)) do
			if i ~= returnFromModule and (not useSelection or selectedValues[count] ~= nil) then
				local fixedIndex;
				local indexType = type(i)
				local isValidIndex = indexType == "string" or indexType == "number"
				local value = utils:stringify(v)
				local lineEnd =  isValidIndex and "" or (" --// Unknown index %s [%s]"):format(tostring(i), typeof(i))

				if isValidIndex then
					fixedIndex = utils:fixIndex(i)
				else
					hasUnknownIndex = true
					fixedIndex = ("[getIndex(%s, %s)]"):format(env, count)
				end
				if value == nil then
					hasUnknownValue = isDebugValue
					value = (isDebugValue and "values" or env) .. fixedIndex
				end
				if isDebugValue then
					valuesOutput = valuesOutput .. ("\n%s(%s, %s, %s)"):format(setter, env, type(i) == "number" and i or '"' .. tostring(i) .. '"', value) .. lineEnd
				else
					valuesOutput = valuesOutput .. ("\n%s%s = %s"):format(env, fixedIndex, value) .. lineEnd
				end
			end
			count += 1
		end

		if hasUnknownValue then
			if path.Type[1] == "Table Entries" then
				valuesOutput = "local values = " .. env .. valuesOutput
			else
				valuesOutput = ("\n\nlocal values = %s(%s)"):format(path.Type[3], env) .. valuesOutput
			end
		end

		local initalPath = explorerPath[1]
		local wMark = waterMark

		if initalPath.Type[1] == "Garbage" then
			wMark = wMark .. templates.Garbage .. "\n\n"
		end
		if hasUnknownIndex then
			wMark = wMark .. templates.ValueIndex .. "\n\n"
		end

		setclipboard(wMark .. (isCompact and output.Compact or output.Step) .. valuesOutput)
	end, false, false)

	local function refreshValues()
		local path = explorerPath[pathDepth]
		if path ~= nil then
			local valueType = typeof(path.Value)

			updateValueTypes(valueTypes[valueType == "Instance" and path.Value.ClassName or valueType])
			selectValueType(path.Type)

			if path.ScrollPosition ~= nil then
				explorerRecycler.__Instance.CanvasPosition = path.ScrollPosition
				path.ScrollPosition = nil
			end
		end
	end

	local function updatePathLayout()
		local contentSize = PathLayout.AbsoluteContentSize
		local containerSize = utils:scaleToOffset(Path, UDim2.new(1, 0, 0, 0))
		PathParts.CanvasSize = UDim2.new(0, math.max(contentSize.X + 70, containerSize.X.Offset), 0, 0)
		PathParts.CanvasPosition = Vector2.new(contentSize.X + 70, 0)
	end
	
	local function setPathDepth(depth, refresh)
		pathDepth = depth
		refresh = refresh == nil and true
		
		--// Update path parts
		if #pathParts > 0 then
			for i = pathDepth + 1, #pathParts do
				pathParts[i]:Destroy()
				pathParts[i] = nil
			end
		end

		for depth = 1, pathDepth do
			local part = pathParts[depth]

			if part == nil then
				local pathPart = explorerPath[depth]
				part = createPathPart(pathPart)

				part.Listener.MouseButton1Click:Connect(function()
					setPathDepth(depth)
				end)
				part.Arrow.MouseButton1Click:Connect(function()
					local absPos = part.Arrow.AbsolutePosition
					local values = pathPart.Type[2](pathPart.Value)
					local size = utils:getSize(values)

					if size > 0 then
						PathRecyclerHandle.Parent = window.__Instance
						PathRecyclerHandle.Position = UDim2.new(0, absPos.X - 10, 0, absPos.Y + 25)
						PathRecyclerHandle.Size = UDim2.new(0, 300, 0, math.min(size * 26, 350) - 1)

						local data = {}
						for i,v in pairs(values) do
							data[#data+1] = { Index=i, Value=v, Configure=configurePathValue, PathDepth=depth }
						end

						pathAdapter.Data = data
						pathRecycler:NotifyDataChange()
					end
				end)

				part.Parent = PathParts
				pathParts[depth] = part
			end

			local textBounds = utils:getBounds(part.Listener)
			local showArrow = depth < pathDepth

			part.Arrow.Visible = showArrow
			part.Size = UDim2.new(0, textBounds.X + (showArrow and 21 or 8), 0, 25)
			part.Listener.Size = UDim2.new(0, textBounds.X + 8, 0, 25)
		end

		updatePathLayout()
		if refresh then
			refreshValues()
		end

		Forward.ImageColor3 = (pathHistory[historyDepth + 1] or pathDepth ~= #explorerPath) and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 120)
		Back.ImageColor3 = (pathHistory[historyDepth - 1] or pathDepth > 1) and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 120)
	end

	local function storePath(index, type, value, script, arrayIndex)
		local part = { Index=index, Type=type, Value=value, Script=script, ArrayIndex=arrayIndex }
		pathHistory[historyDepth].Depths[#pathHistory[historyDepth].Depths + 1] = pathDepth + 1
		explorerPath[pathDepth + 1] = part
		setPathDepth(pathDepth + 1)
	end

	local lastSelectedValueIndex = 0
	local function selectValue(valueItem, controlHeld, shiftHeld)
		local index = valueItem.LayoutOrder
		local text = valueItem.Index.Text
		if not controlHeld then
			for i,v in pairs(selectedValues) do
				if i ~= index and (not shiftHeld or i ~= lastSelectedValueIndex) then
					selectedValues[i] = nil
					if type(v) == "userdata" then
						v.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
						v.Index.Text = v.Index.Text:gsub('color="#ffffff"', 'color="#1e88e5"')
					end
				end
			end
		end
		if shiftHeld then
			local min = math.min(index, lastSelectedValueIndex)
			local max = math.max(index, lastSelectedValueIndex)
			for i,v in pairs(explorerAdapter.Data) do
				if i > min and i < max then
					local item = explorerRecycler.VisibleItems[i]
					selectedValues[i] = item or explorerAdapter.Data[i]
					if item ~= nil then
						item.BackgroundColor3 = selectionColors.Default
						item.Index.Text = item.Index.Text:gsub('color="#1e88e5"', 'color="#ffffff"')
					end
				end
			end
		end
		selectedValues[index] = (not controlHeld or selectedValues[index] == nil) and valueItem or nil
		valueItem.Index.Text = selectedValues[index] and text:gsub('color="#1e88e5"', 'color="#ffffff"') or text:gsub('color="#ffffff"', 'color="#1e88e5"')
		lastSelectedValueIndex = index
	end

	local function clearHistory(depth)
		--// Remove parts that may not exist anymore
		for i = depth + 1, #explorerPath do
			explorerPath[i] = nil
		end
		for i = historyDepth + 1, #pathHistory do
			pathHistory[i] = nil
		end
	end

	function configurePathValue(data, valueItem)
		local types = valueTypes[typeof(data.Value)]
		local type = types and types[1] or nil
		
		local strIndex = tostring(data.Index)

		if type ~= nil then
			valueItem.MouseButton1Click:Connect(function()
				clearHistory(data.PathDepth)
				setPathDepth(data.PathDepth, false)
				explorerPath[pathDepth].ScrollPosition = explorerRecycler.__Instance.CanvasPosition
				storePath(data.Index, type, data.Value, nil, valueItem.LayoutOrder)
				PathRecyclerHandle.Parent = nil
			end)
		end

		utils:setHovering(valueItem, {"BackgroundColor3"}, function()
			return {
				Default=Color3.fromRGB(33, 33, 33),
				ClickStarted=Color3.fromRGB(44, 44, 44),
				ClickEnded=Color3.fromRGB(33, 33, 33),
				Hovering=Color3.fromRGB(40, 40, 40)
			}
		end, 0.07)
	end

	local function configureValue(data, valueItem)
		local types = valueTypes[typeof(data.Value)]
		local type = types and types[1] or nil
		local parent = explorerPath[pathDepth]

		local timeDelay = 0.4
		local lastClick = 0
		local contextMenu;

		valueItem.MouseButton1Click:Connect(function()
			if (tick() - lastClick) <= timeDelay and type ~= nil then
				clearHistory(pathDepth)
				explorerPath[pathDepth].ScrollPosition = explorerRecycler.__Instance.CanvasPosition
				storePath(data.Index, type, data.Value, nil, valueItem.LayoutOrder)
			else
				selectValue(valueItem, UIS:IsKeyDown(Enum.KeyCode.LeftControl), UIS:IsKeyDown(Enum.KeyCode.LeftShift))
			end
			lastClick = tick()
		end)

		valueItem.MouseButton2Click:Connect(function()
			if selectedValues[valueItem.LayoutOrder] == nil then
				selectValue(valueItem, false, false)
				valueItem.BackgroundColor3 = selectionColors.Hovering
			end
		end)

		local conn;
		conn = valueItem.MouseButton2Click:Connect(function()
			if contextMenu == nil then
				local valueType = typeof(data.Value)
				local options = {"Copy Value(s)", "Favourite", "Edit", 0, "Find References"}

				if valueType == "function" or valueType == "table" or valueType == "userdata" then
					table.insert(options, "Recursive Value Search")
					if valueType == "function" then
						table.insert(options, "Spy Closure")
					end
				elseif valueType == "Instance" and (data.Value:IsA("LocalScript") or data.Value:IsA("ModuleScript")) then
					table.insert(options, "Browse Script")
				end

				contextMenu = modules.Library:ContextMenu(valueItem, window.__Instance, nil, options, function(option)
					local valueOption = valueOptions[option]
					if valueOption ~= nil then
						valueOption(data, contextMenu)
					end
				end)

				contextMenu:Show()
				conn:Disconnect()
			end
		end)

		utils:setHovering(valueItem, {"BackgroundColor3"}, function()
			local isSelected = selectedValues[valueItem.LayoutOrder] ~= nil
			return {
				Default=isSelected and selectionColors.Default or Color3.fromRGB(33, 33, 33),
				ClickStarted=isSelected and selectionColors.Started or Color3.fromRGB(44, 44, 44),
				ClickEnded=isSelected and selectionColors.Hovering or Color3.fromRGB(33, 33, 33),
				Hovering=isSelected and selectionColors.Hovering or Color3.fromRGB(40, 40, 40)
			}
		end, 0.07)
	end

	local valueTypeInstances = {}
	function updateValueTypes(types)
		for i,v in pairs(valueTypeInstances) do
			v.Visible = false
		end
		for i,type in pairs(types) do
			local typeName = type[1]
			local typeInstance = valueTypeInstances[typeName]
			if typeInstance == nil then
				typeInstance = createValueType(typeName)
				valueTypeInstances[typeName] = typeInstance

				typeInstance.Parent = ValueTypes
				typeInstance.MouseButton1Click:Connect(function()
					selectValueType(type)
				end)

				utils:setHovering(typeInstance, {"BackgroundColor3"}, function()
					local isSelected = selectedValueType.Type[1] == typeName
					local success = selectedValueType.Success
					return {
						Default=isSelected and (success and selectionColors.Default or Color3.new(0.5, 0, 0)) or Color3.fromRGB(33, 33, 33),
						ClickStarted=isSelected and (success and selectionColors.Started or Color3.new(0.5, 0, 0)) or Color3.fromRGB(44, 44, 44),
						ClickEnded=isSelected and (success and selectionColors.Hovering or Color3.new(0.5, 0, 0)) or Color3.fromRGB(33, 33, 33),
						Hovering=isSelected and (success and selectionColors.Hovering or Color3.new(0.5, 0, 0)) or Color3.fromRGB(40, 40, 40)
					}
				end, 0.07)
			end
			
			typeInstance.LayoutOrder = i
			typeInstance.Count.Text = "..."
			typeInstance.Visible = true

			--// Count values
			coroutine.wrap(function()
				local path = explorerPath[pathDepth]
				local success, size = pcall(function()
					return utils:getSize(type[2](path.Value, true))
				end)
				
				typeInstance.Count.Text = success and tostring(size) or (typeName == "Garbage" and "..." or "?")
				typeInstance.TypeName.TextColor3 = (success or typeName == "Garbage") and Color3.new(1, 1, 1) or Color3.new(1, 0, 0)
			end)()
		end
	end

	function selectValueType(valueType)
		local data = {}
		local selected = valueTypeInstances[valueType[1]]
		local pathInfo = explorerPath[pathDepth]

		local isDifferentPath = selectedValueType ~= nil and (selectedValueType.Path ~= pathInfo or selectedValueType.Type ~= valueType)

		if isDifferentPath then
			selectedValues = {}
			lastSelectedValueIndex = 0
		end

		local success, values = pcall(function()
			return valueType[2](pathInfo.Value)
		end)

		success = success and values ~= nil
		selectedValueType = { Type=valueType, Success=success, Path=pathInfo }
		values = success and values or {}

		if success then
			for i,v in pairs(values) do
				data[#data+1] = { Index=i, Value=v, Configure=configureValue }
			end
			selected.TypeName.TextColor3 = Color3.new(1, 1, 1)
		end

		for i,v in pairs(valueTypeInstances) do
			if v ~= selected then
				v.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
			elseif math.round(v.BackgroundColor3.R*255) == 33 then
				v.BackgroundColor3 = success and selectionColors.Default or Color3.new(0.5, 0, 0)
			end
		end

		local selectedValuesRef = selectedValues
		selectedValues = {}

		pathInfo.Type = valueType
		explorerAdapter.Data = data
		explorerRecycler:NotifyDataChange(isDifferentPath==false and utils:getSize(values) <= 300)

		for i,item in pairs(utils:copy(selectedValuesRef)) do
			local index;
			if type(item) == "table" then
				index = utils:find(explorerAdapter.Data, function(i,v) return item.Index == v.Index end)
			else
				index = utils:find(explorerRecycler.Items, function(i,v) return item == v end)
			end
			if index ~= nil then
				selectedValues[index] = item
			end
		end
	end

	local function getScripts()
		local scripts = {}
		for i,script in pairs(game:GetDescendants()) do
			if (script:IsA("LocalScript") or script:IsA("ModuleScript")) and isValidScript(script) then
				scripts[#scripts+1] = {
					Text=script.Name:gsub("\n", ""),
					Type=script.ClassName,
					Script=script,
					OnClick=function(item)
						--// Remove parts that are not accessible anymore
						local part = pathHistory[historyDepth]
						if part then
							local times = #part.Depths - (utils:find(part.Depths, pathDepth) or #part.Depths)
							for i = 1, times do
								table.remove(part.Depths)
							end
						end

						--// Reset path
						setPathDepth(0, false)
						explorerPath = {}

						--// Store in history
						historyDepth += 1
						pathHistory[historyDepth] = {
							ExplorerPath=explorerPath,
							Depths={}
						}

						--// Start of path
						storePath(nil, valueTypes[script.ClassName][1], script, script)
						
						if selectedScript ~= nil and selectedScript ~= item then
							selectedScript.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
							selectedScript.ScriptName.Text = selectedScript.ScriptName.Text:gsub('color="#ffffff"', 'color="#1e88e5"')
						end
						item.ScriptName.Text = item.ScriptName.Text:gsub('color="#1e88e5"', 'color="#ffffff"')
						selectedScript = item
					end
				}
			end
		end
		return scripts
	end

	local function navigate(i)
		if #pathHistory == 0 then
			return 
		end

		local part = pathHistory[historyDepth]
		if utils:find(part.Depths, pathDepth + i) then
			setPathDepth(pathDepth + i)
		else
			part = pathHistory[historyDepth + i]
			if part ~= nil then
				historyDepth += i
				setPathDepth(0, false)
				explorerPath = part.ExplorerPath
				setPathDepth(part.Depths[#part.Depths])
			end
		end
	end

	--// Connections
	local function onRenderValue(self, position, item)
		local data = self.Data[position]
		local index = tostring(data.Index)

		item.Value.Text = table.concat(tostring(data.Value):split("\n"), " ")

		if type(data.Value) == "function" and type(data.Index) == "number" then
			local funcName = getinfo(data.Value).name
			item.Index.Text = index .. (#funcName > 0 and (' <font color="#1e88e5">[' .. funcName .. "]</font>") or "")
		else
			item.Index.Text = index
		end

		if self == explorerAdapter and selectedValues[position] ~= nil then
			selectedValues[position] = item
			item.BackgroundColor3 = selectionColors.Default
			item.Index.Text = item.Index.Text:gsub('color="#1e88e5"', 'color="#ffffff"')
		end
	end

	local function searchScripts()
		local text = SearchBox.Text
		local hasFilter = utils:find(searchFilter.Filter, function(_,f) return f.Checked == false end)
		searchFilter.Keyword = text~="" and text:lower() or nil
		scriptsRecycler:Search((searchFilter.Keyword or hasFilter) and searchFilter or nil)
	end

	local filterContextMenu = modules.Library:ContextMenu(FilterScripts, window.__Instance, UDim2.new(0, -50, 1, 0), searchFilter.Filter, searchScripts, false, false)

	explorerAdapter.RenderAgain = true
	explorerAdapter.OnRenderItem = onRenderValue
	pathAdapter.OnRenderItem = onRenderValue

	filterContextMenu.OnFocusLost = function()
		if not utils:inArea(FilterScripts) then
			filterContextMenu:Hide()
		end
	end

	generateOptions.OnFocusLost = function()
		if not utils:inArea(Generate) then
			generateOptions:Hide()
		end
	end

	scriptsAdapter.OnRenderItem = function(self, position, item)
		local text = self.Data[position].Text
		local searchKeyword = searchFilter.Keyword

		if searchKeyword then
			local i = text:lower():find(searchKeyword, nil, true)
			local color = selectedScript == item and "ffffff" or "1e88e5"
			item.ScriptName.Text = text:sub(1, i - 1) .. ('<font color="#%s">%s</font>'):format(color, text:sub(i, i + #searchKeyword - 1)) .. text:sub(i + #searchKeyword)
		else
			item.ScriptName.Text = text
		end

		utils:setHovering(item, {"BackgroundColor3"}, function()
			local isSelected = selectedScript == item
			return {
				Default=isSelected and selectionColors.Default or Color3.fromRGB(33, 33, 33),
				ClickStarted=isSelected and selectionColors.Started or Color3.fromRGB(44, 44, 44),
				ClickEnded=isSelected and selectionColors.Hovering or Color3.fromRGB(33, 33, 33),
				Hovering=isSelected and selectionColors.Hovering or Color3.fromRGB(40, 40, 40)
			}
		end, 0.07)
	end
	
	Back.MouseButton1Click:Connect(function()
		navigate(-1)
	end)

	Forward.MouseButton1Click:Connect(function()
		navigate(1)
	end)

	PathParts.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local serializedPath = serialize(explorerPath, pathDepth)

			PathParts.Visible = false
			AbsolutePath.Visible = true

			AbsolutePathInput:CaptureFocus()
			AbsolutePathInput.Text = serializedPath
			AbsolutePathInput.CursorPosition = #serializedPath + 1

			local textBounds = utils:getBounds(AbsolutePathInput).X + 5
			AbsolutePath.CanvasSize = UDim2.new(0, textBounds, 0, 0)
			AbsolutePath.CanvasPosition = Vector2.new(textBounds, 0)
		end
	end)

	AbsolutePathInput.FocusLost:Connect(function()
		local success, expPath = pcall(deserialize, AbsolutePathInput.Text)

		if success then
			setPathDepth(0, false) --// Reset path
			explorerPath = expPath
			setPathDepth(#expPath)
		else
			warn(expPath)
		end

		PathParts.Visible = true
		AbsolutePath.Visible = false
	end)

	AbsolutePathInput.Changed:Connect(function(p)
		if p == "Text" then
			local textBounds = utils:getBounds(AbsolutePathInput).X + 5
			AbsolutePath.CanvasSize = UDim2.new(0, textBounds, 0, 0)
			AbsolutePath.CanvasPosition = Vector2.new(textBounds, 0)
			updatePathLayout()
		end
	end)

	SearchBox.Changed:Connect(function(p)
		if p == "Text" then
			searchScripts()
		end
	end)

	PathLayout.Changed:Connect(function(p)
		if p == "AbsoluteContentSize" then
			updatePathLayout()
		end
	end)

	root.Changed:Connect(function(p)
		if p == "AbsoluteSize" then
			updatePathLayout()
		end
	end)

	RefreshScripts.MouseButton1Click:Connect(function()
		scriptsAdapter.Data = getScripts()
		scriptsRecycler:NotifyDataChange()

		if selectedScript ~= nil then
			selectedScript = scriptsRecycler:GetItem(selectedScript.LayoutOrder)
			selectedScript.BackgroundColor3 = selectionColors.Default
			selectedScript.ScriptName.Text = selectedScript.ScriptName.Text:gsub('color="#1e88e5"', 'color="#ffffff"')
		end
	end)

	FilterScripts.MouseButton1Click:Connect(filterContextMenu.Toggle)
	Generate.MouseButton1Click:Connect(generateOptions.Toggle)
	Refresh.MouseButton1Click:Connect(refreshValues)

	tool:AddConnection(UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard and PathRecyclerHandle.Parent ~= nil and not utils:inArea(PathRecyclerHandle) then
			PathRecyclerHandle.Parent = nil
		end
	end))

	local stopUpdating = false
	tool:OnTerminate(function()
		stopUpdating = true
	end)

	coroutine.wrap(function()
		while not stopUpdating do
			local path = explorerPath[pathDepth]
			if path ~= nil and path.Type[1] ~= "Garbage" then
				local s, values = pcall(path.Type[2], path.Value, true)
				values = s and values or {}
				
				local sizeCheck = 0
				for i,v in pairs(values) do
					sizeCheck += 1
					if sizeCheck > 300 then
						break
					end
				end

				if sizeCheck > 0 and sizeCheck <= 300 then
					local changedArray = false
					for i,v in pairs(values) do
						local found = utils:find(explorerAdapter.Data, function(_, d) return d.Index == i end)
						local item = explorerRecycler.VisibleItems[found or 0]
						changedArray = changedArray or found == nil
	
						if item ~= nil and explorerAdapter.Data[found].Value ~= v then
							item.Value.Text = table.concat(tostring(v):split("\n"), " ")
						end

						explorerAdapter.Data[found or #explorerAdapter.Data+1] = { Index=i, Value=v, Configure=configureValue }
					end
					for i,v in pairs(explorerAdapter.Data) do
						local found = utils:find(values, function(vi) return vi == v.Index end)
						if found == nil then
							changedArray = true
						end
					end
					if changedArray then
						refreshValues()
					end
				end
			end
			wait(1)
		end
	end)()

	scriptsAdapter.Data = getScripts()
	scriptsRecycler:NotifyDataChange()
end

function Adapters:Scripts(data)
	return {
		Data=data or {},
		FixedSize=25,
		Padding=1,
		OnCreateItem=function(self, position)
			local Script = Instance.new("TextButton")
			local ScriptName = Instance.new("TextLabel")
			local ScriptIcon = Instance.new("ImageLabel")

			local data = self.Data[position]
			local isModule = data.Type == "ModuleScript"
	
			Script.Name = "Script"
			Script.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
			Script.BorderSizePixel = 0
			Script.Size = UDim2.new(1, 0, 0, 25)
			Script.ZIndex = 2
			Script.AutoButtonColor = false
			Script.Font = Enum.Font.SourceSans
			Script.Text = ""
			Script.TextColor3 = Color3.fromRGB(255, 255, 255)
			Script.TextSize = 14.000

			ScriptName.Name = "ScriptName"
			ScriptName.Parent = Script
			ScriptName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ScriptName.BackgroundTransparency = 1.000
			ScriptName.Position = UDim2.new(0, 25, 0, 0)
			ScriptName.Size = UDim2.new(1, -25, 1, 0)
			ScriptName.ZIndex = 2
			ScriptName.RichText = true
			ScriptName.Font = Enum.Font.SourceSans
			ScriptName.Text = data.Text
			ScriptName.TextColor3 = Color3.fromRGB(255, 255, 255)
			ScriptName.TextSize = 14.000
			ScriptName.TextXAlignment = Enum.TextXAlignment.Left

			ScriptIcon.Name = "ScriptIcon"
			ScriptIcon.Parent = Script
			ScriptIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ScriptIcon.BackgroundTransparency = 1.000
			ScriptIcon.Position = UDim2.new(0, 4, 0, 5)
			ScriptIcon.Size = UDim2.new(0, 16, 0, 16)
			ScriptIcon.ZIndex = 2
			ScriptIcon.Image = "rbxassetid://6873499343"
			ScriptIcon.ImageRectOffset = Vector2.new(isModule and 64 or 0, isModule and 128 or 32)
			ScriptIcon.ImageRectSize = Vector2.new(16, 16)
			ScriptIcon.ScaleType = Enum.ScaleType.Crop
			ScriptIcon.SliceScale = 0.000
			ScriptIcon.TileSize = UDim2.new(0, 16, 0, 16)
	
			Script.MouseButton1Click:Connect(function()
				data.OnClick(Script)
			end)
	
			return Script
		end,
		OnSearch=function(self, searchFilter)
			local keyword = searchFilter.Keyword
			local allowed = {
				LocalScript=searchFilter.Filter.LocalScripts.Checked,
				ModuleScript=searchFilter.Filter.ModuleScripts.Checked
			}
			return utils:filter(self.Data, function(i)
				return (not keyword or i.Text:lower():find(keyword, nil, true)) and allowed[i.Type]
			end, true)
		end
	}
end

function Adapters:Explorer(data)
	return {
		Data=data or {},
		FixedSize=25,
		Padding=1,
		OnCreateItem=function(self, position)
			local data = self.Data[position]

			local ValueItem = Instance.new("TextButton")
			local Icon = Instance.new("ImageLabel")
			local Index = Instance.new("TextLabel")
			local Value = Instance.new("TextLabel")
			local Separator = Instance.new("Frame")

			ValueItem.Name = "ValueItem"
			ValueItem.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
			ValueItem.BorderSizePixel = 0
			ValueItem.AutoButtonColor = false
			ValueItem.Size = UDim2.new(1, 0, 0, 25)
			ValueItem.Font = Enum.Font.SourceSans
			ValueItem.Text = ""
			ValueItem.TextColor3 = Color3.fromRGB(0, 0, 0)
			ValueItem.TextSize = 14.000

			Icon.Name = "Icon"
			Icon.Parent = ValueItem
			Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Icon.BackgroundTransparency = 1.000
			Icon.Position = UDim2.new(0, 4, 0, 5)
			Icon.Size = UDim2.new(0, 16, 0, 16)
			Icon.ZIndex = 2
			Icon.ImageRectOffset = Vector2.new(0, 32)
			Icon.ImageRectSize = Vector2.new(16, 16)
			Icon.ScaleType = Enum.ScaleType.Crop
			Icon.SliceScale = 0.000
			Icon.TileSize = UDim2.new(0, 16, 0, 16)

			Index.Name = "Index"
			Index.Parent = ValueItem
			Index.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Index.BackgroundTransparency = 1.000
			Index.Position = UDim2.new(0, 25, 0, 0)
			Index.Size = UDim2.new(0.5, -25, 0, 25)
			Index.ClipsDescendants = true
			Index.Font = Enum.Font.SourceSans
			Index.RichText = true
			Index.TextColor3 = Color3.fromRGB(255, 255, 255)
			Index.TextSize = 14.000
			Index.TextXAlignment = Enum.TextXAlignment.Left

			Value.Name = "Value"
			Value.Parent = ValueItem
			Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Value.BackgroundTransparency = 1.000
			Value.Position = UDim2.new(0.5, 10, 0, 0)
			Value.Size = UDim2.new(0.5, -10, 0, 25)
			Value.Font = Enum.Font.SourceSans
			Value.TextColor3 = Color3.fromRGB(255, 255, 255)
			Value.TextSize = 14.000
			Value.TextXAlignment = Enum.TextXAlignment.Left

			Separator.Name = "Separator"
			Separator.Parent = ValueItem
			Separator.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			Separator.BorderSizePixel = 0
			Separator.Position = UDim2.new(0.5, 0, 0, 0)
			Separator.Size = UDim2.new(0, 1, 0, 25)

			data.Configure(data, ValueItem)
			return ValueItem
		end
	}
end

function EnvironmentBrowser:Initialize(window, content)
	local tool = {
		_Connections={},
		_Events={}
	}

	function tool:AddConnection(connection)
		table.insert(tool._Connections, connection)
	end

	function tool:Terminate()
		for i,callback in pairs(tool._Events) do
			callback()
		end
		for i,connection in pairs(tool._Connections) do
			connection:Disconnect()
		end
	end

	function tool:OnTerminate(callback)
		table.insert(tool._Events, callback)
	end

	Load(window, content, tool)
	return tool
end

return EnvironmentBrowser