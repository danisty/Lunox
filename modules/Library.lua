local main = ...
local utils = main.modules.Utils

--// Services
local Mouse = game.Players.LocalPlayer:GetMouse()
local RS = game:GetService("RunService")
local TXTS = game:GetService("TextService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

local Library = {}

local reset = Vector2.new(-1, -1)
local function makeDraggable(panel, handle, exception, onDrag)
	local controller = {
		Dragging=false
	}
	local mouseIn = false
	local scale, yOffset;
	local dragStart;
	panel.Active = true
	handle.Active = true
	handle.InputBegan:connect(function(inp)
		dragStart = Vector2.new(Mouse.X, Mouse.Y)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 and not mouseIn and not exception() then
			mouseIn = true
			scale = (Mouse.X - panel.AbsolutePosition.X)/panel.AbsoluteSize.X
			yOffset = Mouse.Y - panel.AbsolutePosition.Y
			while mouseIn do
				if (Vector2.new(Mouse.X, Mouse.Y) - dragStart).Magnitude > 0 then
					panel.Position = UDim2.new(0, Mouse.X - panel.AbsoluteSize.X*scale, 0, Mouse.Y - yOffset)
					controller.Dragging = true
					dragStart = reset
					if onDrag then
						onDrag()
					end
				end
				RS.RenderStepped:wait()
			end
		end
	end)
	handle.InputEnded:connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseIn = false
			controller.Dragging = false
		end
	end)
	panel.Changed:Connect(function(p) --// Fix position on size change
		if p == "Size" and controller.Dragging then
			panel.Position = UDim2.new(0, Mouse.X - panel.AbsoluteSize.X*scale, 0, Mouse.Y - yOffset)
		end
	end)
	exception = exception or function()end
	return controller
end

local windows = {}
function Library:Window(title, icon, tools, parent)
	local Window = Instance.new("ScreenGui")
	local Main = Instance.new("Frame")
	local Body = Instance.new("Frame")
	local TitleBar = Instance.new("Frame")
	local Icon = Instance.new("ImageLabel")
	local Title = Instance.new("TextLabel")
	local Close = Instance.new("ImageButton")
	local Maximize = Instance.new("ImageButton")
	local Minimize = Instance.new("ImageButton")
	local Snap = Instance.new("Frame")
	
	Window.Name = "Window"
	Window.Parent = parent
	Window.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	Main.Name = "Main"
	Main.Parent = Window
	Main.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Main.BorderColor3 = Color3.fromRGB(30, 136, 229)
	Main.Position = UDim2.new(0.5, -350, 0.5, -200)
	Main.Size = UDim2.new(0, 700, 0, 396)

	Body.Name = "Body"
	Body.Parent = Main
	Body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Body.BackgroundTransparency = 1.000
	Body.BorderSizePixel = 0
	Body.ClipsDescendants = true
	Body.Position = UDim2.new(0, 0, 0, 30)
	Body.Size = UDim2.new(1, 0, 1, -30)

	TitleBar.Name = "TitleBar"
	TitleBar.Parent = Main
	TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TitleBar.BackgroundTransparency = 1.000
	TitleBar.BorderSizePixel = 0
	TitleBar.Size = UDim2.new(1, 0, 0, 30)

	Icon.Name = "Icon"
	Icon.Parent = TitleBar
	Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Icon.BackgroundTransparency = 1.000
	Icon.Size = UDim2.new(0, 30, 0, 30)
	Icon.Image = "rbxassetid://" .. icon

	Title.Name = "Title"
	Title.Parent = TitleBar
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0, 30, 0, 2)
	Title.BackgroundTransparency = 1
	Title.Size = UDim2.new(1, 0, 0, 27)
	Title.Font = Enum.Font.SourceSansSemibold
	Title.Text = title
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 16.000
	Title.TextXAlignment = Enum.TextXAlignment.Left

	Close.Name = "Close"
	Close.Parent = TitleBar
	Close.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Close.BorderSizePixel = 0
	Close.Position = UDim2.new(1, -40, 0, 0)
	Close.Size = UDim2.new(0, 40, 0, 30)
	Close.Image = "rbxassetid://6875911058"
	Close.ScaleType = Enum.ScaleType.Fit

	Maximize.Name = "Maximize"
	Maximize.Parent = TitleBar
	Maximize.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Maximize.BorderSizePixel = 0
	Maximize.Position = UDim2.new(1, -80, 0, 0)
	Maximize.Size = UDim2.new(0, 40, 0, 30)
	Maximize.ScaleType = Enum.ScaleType.Fit
	Maximize.Image = "rbxassetid://7160912599"

	Minimize.Name = "Minimize"
	Minimize.Parent = TitleBar
	Minimize.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Minimize.BorderSizePixel = 0
	Minimize.Position = UDim2.new(1, -120, 0, 0)
	Minimize.Size = UDim2.new(0, 40, 0, 30)
	Minimize.Image = "rbxassetid://6875921379"
	Minimize.ScaleType = Enum.ScaleType.Fit

	Snap.Name = "Snap"
	Snap.Parent = Window
	Snap.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
	Snap.BorderColor3 = Color3.fromRGB(255, 255, 255)
	Snap.BackgroundTransparency = 1
	Snap.BorderSizePixel = 2
	Snap.ZIndex = 0

	local window = {
		__Instance=Window,
		MinWindowSize=Vector2.new(600, 350),
		Maximized=false,
		Minimized=false,
		Snapped=false,
		LoadedTools={}
	}
	local lastSize = Main.Size
	local lastPosition = Main.Position
	local iBeganConn, iChangeConn, iEndedConn;
	local contextMenu, dragController;

	function window:Minimize()
		window.Minimized = not window.Minimized
	end
	function window:Maximize()
		window.Snapped = false
		window.Maximized = not window.Maximized

		Main.Size = window.Maximized and UDim2.new(1, 0, 1, 0) or lastSize
		Main.Position = window.Maximized and UDim2.new(0, 0, 0, 0) or lastPosition
		Maximize.Image = "rbxassetid://" .. (window.Maximized and 6875927724 or 7160912599)
		
		contextMenu:Update(2, window.Maximized and "Restore" or "Maximize")
	end
	function window:Close()
		table.remove(windows, table.find(windows, window))
		for _,tool in pairs(window.LoadedTools) do
			tool:Terminate()
		end
		iBeganConn:Disconnect()
		iChangeConn:Disconnect()
		iEndedConn:Disconnect()
		Window:Destroy()
	end
	window.Restore = window.Maximize

	Minimize.MouseButton1Click:Connect(window.Minimize)
	Maximize.MouseButton1Click:Connect(window.Maximize)
	Close.MouseButton1Click:Connect(window.Close)

	Main.Changed:Connect(function(p)
		if window.Maximized or window.Snapped then
			return
		elseif p == "Size" then
			lastSize = Main.Size
		elseif p == "Position" then
			lastPosition = Main.Position
		end
	end)

	Main.InputBegan:connect(function(inp) --// Wake focused Window
		local focusedWindow = utils:filter(windows, function(v) return v._Focused end)[1]
		if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2) and (not focusedWindow or focusedWindow.__Instance.DisplayOrder < Window.DisplayOrder) then
			local windows = Window.Parent:GetChildren()
			Window.DisplayOrder = 50
			table.sort(windows, function(w1, w2)
				return w1.DisplayOrder < w2.DisplayOrder
			end)
			for i,v in pairs(windows) do
				v.DisplayOrder = i
			end
		end
	end)

	local resize, snap = {}, {}
	local snapping = false
	local mouseIn = false
	iBeganConn = UIS.InputBegan:Connect(function(input)
		local topWindow = utils:filter(windows, function(w) return w.__Instance.DisplayOrder == #windows end)[1]
		local cancelResize = topWindow and (utils:inArea(topWindow.__Instance.Main) and Window.DisplayOrder < #windows) or false
		if input.UserInputType == Enum.UserInputType.MouseButton1 and utils:find(resize, true) ~= nil and (not cancelResize or (window.Snapped and (topWindow and topWindow.Snapped))) then
			local top, left, right, bottom = resize.Top, resize.Left, resize.Right, resize.Bottom
			local sOffset = Vector2.new(Mouse.X, Mouse.Y) - (Main.AbsolutePosition + Main.AbsoluteSize)
			local pOffset = Vector2.new(Mouse.X, Mouse.Y) - Main.AbsolutePosition

			local viewSize = workspace.CurrentCamera.ViewportSize
			local snapLimit = #utils:filter(windows, function(w) return w.Snapped and w.__Instance.Main.Size.X.Scale~=1 end) > 1 and viewSize.X - window.MinWindowSize.X or 1e4

			while UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				if right or bottom then
					Main.Size = UDim2.new(
						0, right and math.min(snapLimit, math.max(window.MinWindowSize.X, Mouse.X - Main.AbsolutePosition.X - sOffset.X)) or Main.AbsoluteSize.X,
						0, bottom and math.max(window.MinWindowSize.Y, Mouse.Y - Main.AbsolutePosition.Y - sOffset.Y) or Main.AbsoluteSize.Y
					)
				end
				if left or top then
					local size = Main.AbsolutePosition + Main.AbsoluteSize
					local newPos = UDim2.new(
						0, left and math.max(size.X - snapLimit, math.min(size.X - window.MinWindowSize.X, Mouse.X - pOffset.X)) or Main.AbsolutePosition.X,
						0, top and math.min(size.Y - window.MinWindowSize.Y, Mouse.Y - pOffset.Y) or Main.AbsolutePosition.Y
					)
					local diff = Main.AbsolutePosition - Vector2.new(newPos.X.Offset, newPos.Y.Offset)
					local newSize = UDim2.new(
						0, left and Main.AbsoluteSize.X + diff.X or Main.AbsoluteSize.X,
						0, top and Main.AbsoluteSize.Y + diff.Y or Main.AbsoluteSize.Y
					)
					Main.Position = newPos
					Main.Size = newSize
				end
				RS.RenderStepped:Wait()
			end
		end
	end)
	local function inputChanged(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and not window.Maximized then
			--// Resizing
			local o = window.Snapped and 3 or 6
			local absolutePosition = Main.AbsolutePosition
			local absoluteSize = Main.AbsoluteSize

			resize.Top = utils:vInArea(absolutePosition - Vector2.new(6, 6), absolutePosition + Vector2.new(absoluteSize.X + 6, 0))
			resize.Left = utils:vInArea(absolutePosition - Vector2.new(o, 6), absolutePosition + Vector2.new(window.Snapped and 3 or 0, absoluteSize.Y + 6))
			resize.Right = utils:vInArea(absolutePosition + Vector2.new(absoluteSize.X - (window.Snapped and 3 or 0), -6), absolutePosition + Vector2.new(absoluteSize.X + o, absoluteSize.Y + 6))
			resize.Bottom = utils:vInArea(absolutePosition + Vector2.new(-6, absoluteSize.Y), absolutePosition + Vector2.new(absoluteSize.X + 6, absoluteSize.Y + 6))

			window._Focused = utils:find(resize, true) ~= nil
			if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				if resize.Top or resize.Bottom then
					Mouse.Icon = "rbxassetid://" .. (resize.Left and (resize.Top and 7190489269 or 7190489412) or (resize.Right and (resize.Top and 7190489412 or 7190489269) or 7190489199))
					mouseIn = true
				elseif resize.Left or resize.Right then
					Mouse.Icon = "rbxassetid://7190489338"
					mouseIn = true
				elseif mouseIn then
					Mouse.Icon = ""
					mouseIn = false
				end
			end

			--// Snapping
			local snappedWindow = utils:filter(windows, function(w) return w.Snapped and w.__Instance.Main.Size.X.Scale~=1 end)[1]
			local viewSize = workspace.CurrentCamera.ViewportSize

			snap.Left = utils:vInArea(Vector2.new(0, 0), Vector2.new(15, viewSize.Y))
			snap.Top = utils:vInArea(Vector2.new(15, 0), Vector2.new(viewSize.X - 30, 15))
			snap.Right = utils:vInArea(Vector2.new(viewSize.X - 15, 0), Vector2.new(viewSize.X, viewSize.Y))

			local canSnap = dragController.Dragging and utils:find(snap, true) ~= nil
			if canSnap and not snapping then
				local leftSnapped = snappedWindow and snappedWindow.__Instance.Main.AbsolutePosition.X==0
				local size = snappedWindow and snappedWindow.__Instance.Main.AbsoluteSize.X or 0
				snapping = true
				
				Snap.BackgroundTransparency = 1
				Snap.Position = UDim2.new(snap.Right and (snappedWindow and (leftSnapped~=snap.Right and viewSize.X - size or size)/viewSize.X or 0.5) or 0, 0, 0, 0)
				Snap.Size = UDim2.new(snap.Top and 1 or (snappedWindow and ((leftSnapped==snap.Left or leftSnapped~=snap.Right) and size or viewSize.X - size)/viewSize.X or 0.5), 0, 1, 0)

				TS:Create(Snap, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
					BackgroundTransparency=0.5
				}):Play()
			elseif not canSnap then
				snapping = false
				TS:Create(Snap, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
					BackgroundTransparency=1
				}):Play()
			end
		end
	end
	iChangeConn = UIS.InputChanged:Connect(inputChanged)
	iEndedConn = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and snapping then
			window.Snapped = true
			inputChanged({UserInputType=Enum.UserInputType.MouseMovement})
			if snap.Top then
				window:Maximize()
			else
				Main.Position = Snap.Position
				Main.Size = Snap.Size
			end
		end
	end)
	
	contextMenu = Library:ContextMenu(TitleBar, Window, nil, {"Minimize", "Maximize", 0, "Close"}, function(option)
		if window[option] then
			window[option]()
		end
	end)
	
	dragController = makeDraggable(Main, TitleBar, function()
		local focusedWindow = utils:filter(windows, function(v) return v._Focused end)[1]
		return focusedWindow and focusedWindow.__Instance.DisplayOrder == #windows
	end, function()
		if window.Maximized then
			window.Maximized = false
			Maximize.Image = "rbxassetid://7160912599"
			Main.Size = lastSize
			contextMenu:Update(2, "Maximize")
		elseif window.Snapped then
			window.Snapped = false
			Main.Size = lastSize
		end
	end)
	
	table.insert(windows, window)
	return window
end

function Library:TabControl(parent, defaultContent)
	local TabControl = Instance.new("Frame")
	local TabContent = Instance.new("Frame")
	local Tabs = Instance.new("ScrollingFrame")
	local TabsLayout = Instance.new("UIListLayout")
	local TabPlaceHolder = Instance.new("Frame")
	local TabsDropShadow = Instance.new("Frame")

	TabControl.Name = "TabControl"
	TabControl.Parent = parent
	TabControl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabControl.BackgroundTransparency = 1.000
	TabControl.Position = UDim2.new(0, 0, 0, 0)
	TabControl.Size = UDim2.new(1, 0, 1, 0)

	TabContent.Name = "TabContent"
	TabContent.Parent = TabControl
	TabContent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabContent.BackgroundTransparency = 1.000
	TabContent.Position = UDim2.new(0, 0, 0, 30)
	TabContent.Size = UDim2.new(1, 0, 1, -30)

	Tabs.Name = "Tabs"
	Tabs.Parent = TabControl
	Tabs.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	Tabs.BorderSizePixel = 0
	Tabs.Size = UDim2.new(1, 0, 0, 30)
	Tabs.ZIndex = 2
	Tabs.CanvasSize = UDim2.new(0, 180, 0, 0)
	Tabs.ScrollBarThickness = 0

	TabsLayout.Parent = Tabs
	TabsLayout.FillDirection = Enum.FillDirection.Horizontal
	TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	TabPlaceHolder.Name = "TabPlaceHolder"
	TabPlaceHolder.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	TabPlaceHolder.BorderSizePixel = 0
	TabPlaceHolder.Size = UDim2.new(0, 180, 0, 30)

	TabsDropShadow.Name = "TabsDropShadow"
	TabsDropShadow.Parent = Body
	TabsDropShadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabsDropShadow.BorderSizePixel = 0
	TabsDropShadow.Size = UDim2.new(1, 0, 0, 33)
	TabsDropShadow.Style = Enum.FrameStyle.DropShadow

	if defaultContent then
		defaultContent.Parent = TabContent
	end

	local root = parent:FindFirstAncestorWhichIsA("ScreenGui")
	local tabControl = {
		Tabs={},
		SelectedTab=nil
	}
	
	local function selectTab(tab)
		for i,v in pairs({tab, tabControl.SelectedTab}) do
			v.__Instance.Title.TextColor3 = v==tab and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
			v.__Instance.BackgroundColor3 = v==tab and Color3.fromRGB(33, 33, 33) or Color3.fromRGB(27, 27, 27)
			v.Content.Parent = v==tab and TabContent or nil
		end
		tabControl.SelectedTab = tab
	end
	
	function tabControl:AddTab(name, closeCallback)
		local Tab = Instance.new("TextButton")
		local TabTitle = Instance.new("TextLabel")
		local TabClose = Instance.new("ImageButton")
		local Content = Instance.new("Frame")
		
		Tab.Name = "Tab"
		Tab.Parent = Tabs
		Tab.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
		Tab.BorderSizePixel = 0
		Tab.Size = UDim2.new(0, 180, 0, 30)
		Tab.AutoButtonColor = false
		Tab.Font = Enum.Font.SourceSans
		Tab.Text = ""
		Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
		Tab.TextSize = 14.000
		Tab.ZIndex = 2

		TabTitle.Name = "Title"
		TabTitle.Parent = Tab
		TabTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TabTitle.BackgroundTransparency = 1.000
		TabTitle.Position = UDim2.new(0, 10, 0, 0)
		TabTitle.Size = UDim2.new(1, -10, 1, 0)
		TabTitle.Font = Enum.Font.SourceSans
		TabTitle.Text = name
		TabTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
		TabTitle.TextSize = 14.000
		TabTitle.TextXAlignment = Enum.TextXAlignment.Left

		TabClose.Name = "TabClose"
		TabClose.Parent = Tab
		TabClose.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		TabClose.BorderSizePixel = 0
		TabClose.Position = UDim2.new(1, -23, 0, 8)
		TabClose.Size = UDim2.new(0, 15, 0, 15)
		TabClose.AutoButtonColor = false
		TabClose.Image = "rbxassetid://6876957469"
		TabClose.Visible = false

		Content.Name = "Content"
		Content.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		Content.Size = UDim2.new(1, 0, 1, 0)
		Content.Position = UDim2.new(0, 0, 0, 0)
		
		local mouseDown = false
		local mouseDownPosition;
		local dragging = false
		local tab = {
			__Instance=Tab,
			Name=name,
			Content=Content,
			CloseCallback=closeCallback
		}

		tab.Select = selectTab
		function tab:Close()
			Tab:Destroy()
			tab.Content:Destroy()
			if tabControl.SelectedTab == tab then
				tabControl.SelectedTab = nil
			end
			table.remove(tabControl.Tabs, table.find(tabControl.Tabs, tab))
			tab:CloseCallback()
		end

		TabClose.MouseButton1Click:Connect(tab.Close)
		Library:ContextMenu(Tab, root, nil, {"Close", "Close Others", "Close All"}, function(option)
			if option == "Close" then
				tab:Close()
			else
				for i = #tabControl.Tabs, 1, -1 do
					local v = tabControl.Tabs[i]
					if v ~= tab or option == "Close All" then
						v:Close()
					end
				end
			end
		end)
		
		Tab.MouseEnter:Connect(function()
			TabClose.Visible = true
		end)
		Tab.MouseLeave:Connect(function()
			TabClose.Visible = false
		end)
		
		Tab.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not mouseDown then
				mouseDown = true
				mouseDownPosition = Vector2.new(Mouse.X, Mouse.Y)
				local rX = Mouse.X - Tab.AbsolutePosition.X
				while mouseDown do
					if (mouseDownPosition - Vector2.new(Mouse.X, Mouse.Y)).Magnitude > 10 then
						TabPlaceHolder.Parent = Tabs
						TabPlaceHolder.LayoutOrder = table.find(tabControl.Tabs, tab)
						Tab.Parent = TabControl
						while mouseDown do
							Tab.Position = UDim2.new(0, Mouse.X - TabControl.AbsolutePosition.X - rX, 0, 0)
							dragging = true

							--// Order tabs, homemade method, probably not recommended
							local tabsSorted = {}
							for i,v in pairs(tabControl.Tabs) do
								table.insert(tabsSorted, {v, v==tab and (Tab.AbsolutePosition.X + Tab.AbsoluteSize.X/2) - TabControl.AbsolutePosition.X or (i-1)*Tab.AbsoluteSize.X + Tab.AbsoluteSize.X/2})
							end
							table.sort(tabsSorted, function(v1, v2)
								return v1[2] < v2[2]
							end)
							for i,v in pairs(tabsSorted) do
								tabControl.Tabs[i] = v[1]
								tabControl.Tabs[i].__Instance.LayoutOrder = i
								if v[1] == tab then
									TabPlaceHolder.LayoutOrder = i
								end
							end

							RS.RenderStepped:Wait()
						end
						TabPlaceHolder.Parent = nil
						Tab.Parent = Tabs
					end
					RS.RenderStepped:Wait()
				end
			end
		end)
		Tab.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseDown = false
				if utils:inArea(Tab) and not dragging then
					selectTab(tab)
				end
				dragging = false
			elseif input.UserInputType == Enum.UserInputType.MouseButton3 and utils:inArea(Tab) then
				tab:Close()
			end
		end)

		utils:setHovering(Tab, {"BackgroundColor3"}, function()
			return {
				Default=tabControl.SelectedTab==tab and Color3.fromRGB(33, 33, 33) or Color3.fromRGB(27, 27, 27),
				Hovering=tabControl.SelectedTab==tab and Color3.fromRGB(36, 36, 36) or Color3.fromRGB(33, 33, 33),
				ClickStarted=Color3.fromRGB(40, 40, 40),
				ClickEnded=Color3.fromRGB(36, 36, 36)
			}
		end)

		if not tabControl.SelectedTab then
			selectTab(tab)
		end

		table.insert(tabControl.Tabs, tab)
		Tab.LayoutOrder = #tabControl.Tabs
		return tab
	end

	return tabControl
end

function Library:ContextMenu(handle, parent, offset, items, callback, showOnLeftClick, hideOnFocusLoss)
	local ContextMenu = Instance.new("Frame")
	local Options = Instance.new("Frame")
	local Layout = Instance.new("UIListLayout")
	local Padding = Instance.new("UIPadding")

	ContextMenu.Name = "ContextMenu"
	ContextMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	ContextMenu.BorderSizePixel = 0
	ContextMenu.Position = UDim2.new(0, 0, 0, 0)
	ContextMenu.Size = UDim2.new(0, 160, 0, 150)

	Options.Name = "Options"
	Options.Parent = ContextMenu
	Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Options.BackgroundTransparency = 1.000
	Options.Size = UDim2.new(1, 0, 1, 0)

	Layout.Name = "Layout"
	Layout.Parent = Options
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 1)

	Padding.Name = "Padding"
	Padding.Parent = Options
	Padding.PaddingBottom = UDim.new(0, 2)
	Padding.PaddingLeft = UDim.new(0, 2)
	Padding.PaddingRight = UDim.new(0, 2)
	Padding.PaddingTop = UDim.new(0, 2)

	local contextMenu = {
		__Instance=ContextMenu,
		Offset=offset,
		Items=items,
		Visible=false,
		Callback=callback or function()end,
		ShowOnLeftClick=showOnLeftClick==nil and true or showOnLeftClick,
		HideOnFocusLoss=hideOnFocusLoss==nil and true or hideOnFocusLoss
	}
	local cachedItems = {}

	local function updateLayout()
		ContextMenu.Size = UDim2.new(0, 160, 0, Layout.AbsoluteContentSize.Y + 4)
	end

	local function updateItems()
		for i,v in pairs(contextMenu.Items) do
			local cache = cachedItems[v]
			if cache ~= nil then
				cache.Parent = Options
				cache.LayoutOrder = i
			elseif v == 0 then
				local Separator = Instance.new("Frame")
				local Line = Instance.new("Frame")
	
				Separator.Name = "Separator"
				Separator.Parent = Options
				Separator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				Separator.BorderColor3 = Color3.fromRGB(40, 40, 40)
				Separator.BorderSizePixel = 0
				Separator.Size = UDim2.new(1, 0, 0, 3)
				Separator.LayoutOrder = i
	
				Line.Name = "Line"
				Line.Parent = Separator
				Line.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				Line.BorderSizePixel = 0
				Line.Position = UDim2.new(0, 5, 0, 1)
				Line.Size = UDim2.new(1, -10, 0, 1)

				cachedItems[v] = Separator
			else
				local Option = Instance.new("TextButton")
				local Title = Instance.new("TextLabel")
				--local Icon = Instance.new("ImageLabel")
	
				--local name, icon = unpack(v:split(":"))
	
				Option.Name = "Option"
				Option.Parent = Options
				Option.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				Option.BorderSizePixel = 0
				Option.Size = UDim2.new(1, 0, 0, 24)
				Option.Font = Enum.Font.SourceSans
				Option.Text = ""
				Option.TextColor3 = Color3.fromRGB(0, 0, 0)
				Option.TextSize = 14.000
				Option.LayoutOrder = i
			
				Title.Name = "Title"
				Title.Parent = Option
				Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Title.BackgroundTransparency = 1.000
				Title.Position = UDim2.new(0, 24, 0, 0)
				Title.Size = UDim2.new(0, 0, 1, 0)
				Title.ZIndex = 2
				Title.Font = Enum.Font.SourceSans
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 14.000
				Title.TextXAlignment = Enum.TextXAlignment.Left
			
				--[[ Not needed for now
				Icon.Name = "Icon"
				Icon.Parent = Option
				Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Icon.BackgroundTransparency = 1.000
				Icon.Image = icon and ("rbxassetid://" .. icon) or ""
				Icon.Size = UDim2.new(0, 24, 0, 24) ]]

				if type(v) == "table" then
					v:Configure(contextMenu, Option)
				else
					Title.Text = v
					Option.MouseButton1Click:Connect(function()
						contextMenu.Hide()
						contextMenu.Callback(v)
					end)
				end

				cachedItems[v] = Option
			end
		end
	end

	function contextMenu:Show()
		local p = handle.AbsolutePosition
		ContextMenu.Position = contextMenu.Offset and UDim2.new(0, p.X, 0, p.Y) + utils:scaleToOffset(handle, contextMenu.Offset) or UDim2.new(0, Mouse.X + 2, 0, Mouse.Y + 2)
		ContextMenu.Parent = parent
		contextMenu.Visible = true
	end
	function contextMenu:Hide()
		ContextMenu.Parent = nil
		contextMenu.Visible = false
	end
	function contextMenu:Toggle()
		contextMenu.Visible = not contextMenu.Visible
		if contextMenu.Visible then
			contextMenu:Show()
		else
			contextMenu:Hide()
		end
	end

	function contextMenu:Add(item, index)
		table.insert(contextMenu.Items, index, item)
	end
	function contextMenu:Remove(item)
		local index = type(item) == "number" and item or table.find(contextMenu.Items, item)
		cachedItems[contextMenu.Items[index]]:Destroy()
		cachedItems[contextMenu.Items[index]] = nil
		table.remove(contextMenu.Items, index)
		updateItems()
	end
	function contextMenu:Update(item, newItem)
		local index = type(item) == "number" and item or table.find(contextMenu.Items, item)
		cachedItems[contextMenu.Items[index]].Parent = nil
		contextMenu.Items[index] = newItem
		updateItems()
	end

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and utils:inArea(handle) and contextMenu.ShowOnLeftClick then
			contextMenu:Show()
		end
	end)

	Layout.Changed:Connect(updateLayout)
	UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard and not utils:inArea(ContextMenu) and ContextMenu.Parent then
			if contextMenu.HideOnFocusLoss then
				contextMenu:Hide()
			end
			if contextMenu.OnFocusLost then
				contextMenu.OnFocusLost()
			end
		end
	end)

	updateItems()
	updateLayout()
	return contextMenu
end

Library.MenuItem = {} do
	function Library.MenuItem.CheckBox(title, value, callback)
		local CheckBox = Instance.new("TextLabel")

		CheckBox.Name = "CheckBox"
		CheckBox.Size = UDim2.new(0, 24, 0, 24)
		CheckBox.TextColor3 = Color3.new(1, 1, 1)
		CheckBox.Text = value and "✓" or ""
		CheckBox.BackgroundTransparency = 1
		CheckBox.TextSize = 13

		local checkBox = {
			__Instance=nil,
			Type="CheckBox",
			Title=title,
			Checked=value or false,
			Callback=callback
		}

		function checkBox:Toggle(state)
			if state == nil then
				checkBox.Checked = not checkBox.Checked
			else
				checkBox.Checked = state
			end
			checkBox.ContextMenu:Hide()
			CheckBox.Text = checkBox.Checked and "✓" or ""
			if checkBox.Callback ~= nil then
				checkBox.Callback(state)
			else
				checkBox.ContextMenu.Callback(checkBox)
			end
		end

		function checkBox:Configure(contextMenu, option)
			checkBox.ContextMenu = contextMenu
			checkBox.__Instance = option
			CheckBox.Parent = option

			option.Title.Text = checkBox.Title
			option.MouseButton1Click:Connect(checkBox.Toggle)
		end

		return checkBox
	end
end

function Library:MenuBar(parent, position, options, callback)
	local MenuBar = Instance.new("Frame")
	local Layout = Instance.new("UIListLayout")
	
	MenuBar.Name = "MenuBar"
	MenuBar.Parent = parent
	MenuBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MenuBar.BackgroundTransparency = 1.000
	MenuBar.Position = position
	MenuBar.Size = UDim2.new(0, 0, 1, 0)
	
	Layout.Name = "Layout"
	Layout.Parent = MenuBar
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.SortOrder = Enum.SortOrder.LayoutOrder

	local root = parent:FindFirstAncestorWhichIsA("ScreenGui")
	local menuBar = {
		__Instance=MenuBar,
		Callback=callback,
		SelectedOption=nil,
		Options={}
	}

	for i, v in pairs(options) do
		local name, menuOptions = unpack(v)
		local Option = Instance.new("TextButton")
		local ContextMenu = Library:ContextMenu(Option, root, UDim2.new(0, 0, 1, 0), menuOptions, function(option)
			menuBar.SelectedOption = nil
			Option.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
			menuBar.Callback(name, option)
		end, false, false)

		Option.Name = "Option"
		Option.Parent = MenuBar
		Option.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
		Option.AutoButtonColor = false
		Option.BorderSizePixel = 0
		Option.Font = Enum.Font.SourceSans
		Option.Text = name
		Option.TextColor3 = Color3.fromRGB(255, 255, 255)
		Option.TextSize = 15
		Option.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		Option.Size = UDim2.new(0, utils:getBounds(Option).X + 12, 1, 0)

		local option = {
			__Instance=Option,
			ContextMenu=ContextMenu
		}

		ContextMenu.OnFocusLost = function()
			if not utils:inArea(Option) then
				menuBar.SelectedOption = nil
				Option.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
				ContextMenu:Hide()
			end
		end

		Option.MouseButton1Click:Connect(function()
			if menuBar.SelectedOption then
				ContextMenu:Hide()
				menuBar.SelectedOption = nil
			else
				ContextMenu:Show()
				menuBar.SelectedOption = option
			end
		end)

		Option.MouseEnter:Connect(function()
			if not menuBar.SelectedOption then
				return
			end
			for i,v in pairs(menuBar.Options) do
				if v ~= option then
					v.__Instance.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
					v.ContextMenu:Hide()
				end
			end
			menuBar.SelectedOption = option
			ContextMenu:Show()
		end)

		utils:setHovering(Option, {"BackgroundColor3"}, function()
			local selected = menuBar.SelectedOption == option
			return {
				Default=selected and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(33, 33, 33),
				Hovering=selected and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(40, 40, 40),
				ClickStarted=Color3.fromRGB(45, 45, 45),
				ClickEnded=selected and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(40, 40, 40)
			}
		end, 0)

		table.insert(menuBar.Options, option)
	end

	return menuBar
end

function Library:RecyclerFrame(parent, position, size, adapter)
	local Recycler = Instance.new("ScrollingFrame")

	Recycler.Name = "RecyclerFrame"
	Recycler.Position = position
	Recycler.Size = size
	Recycler.Parent = parent
	Recycler.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	Recycler.BorderSizePixel = 0
	Recycler.BorderColor3 = Color3.fromRGB(30, 136, 229)
	Recycler.BottomImage = "rbxassetid://6721574480"
	Recycler.CanvasSize = UDim2.new(0, 0, 0, 0)
	Recycler.MidImage = "rbxassetid://6721574480"
	Recycler.ScrollBarThickness = 6
	Recycler.ScrollBarImageTransparency = 0.4
	Recycler.TopImage = "rbxassetid://6721574480"

	local recycler = {
		__Instance=Recycler,
		Adapter=adapter,
		VisibleItems={},
		Items={}
	}
	local items = recycler.Items
	local visibleItems = recycler.VisibleItems
	local renderedItems = {}
	local searchKeyword;
	local fixedSize;

	local function getItem(position)
		local item = items[position]
		if item == nil then
			item = recycler.Adapter:OnCreateItem(position)
			items[position] = item
		end
		return item
	end

	local filteredItems = {}
	local verticalSize = Recycler.AbsoluteSize.Y
	local function renderItems()
		if recycler.Adapter ~= nil then
			local renderAgain = recycler.Adapter.RenderAgain
			local onRenderItem = recycler.Adapter.OnRenderItem
			local position = math.min(Recycler.CanvasPosition.Y, Recycler.CanvasSize.Y.Offset - verticalSize)

			if fixedSize then
				local topPosition = math.max(math.floor(position/fixedSize), 1)
				local endPosition = math.min(topPosition + math.floor(verticalSize/fixedSize) + 4, #filteredItems)

				for i,v in pairs(visibleItems) do
					if (i < topPosition or i > endPosition) then
						visibleItems[i].Parent = nil
						visibleItems[i] = nil
						if renderAgain then
							renderedItems[i] = nil
						end
					end
				end

				for i=topPosition, endPosition do
					if visibleItems[i] == nil then
						local position = searchKeyword and filteredItems[i][1] or i
						local item = getItem(position)

						item.Parent = Recycler
						item.Position = UDim2.new(0, 0, 0, (i-1)*fixedSize)
						item.LayoutOrder = position

						visibleItems[i] = item

						if renderedItems[i] == nil and onRenderItem ~= nil then
							recycler.Adapter:OnRenderItem(position, item, searchKeyword)
							renderedItems[i] = true
						end
					end
				end
			else

			end
		end
	end

	local function updateRecyclerCanvas()
		Recycler.CanvasSize = UDim2.new(0, 0, 0, #filteredItems*fixedSize - (adapter.Padding or 0))
	end

	local adapterDataRef;
	function recycler:SetAdapter(adapter)
		if adapter ~= nil then
			recycler.Adapter = adapter
			filteredItems = adapter.Data
			fixedSize = adapter.FixedSize + (adapter.Padding or 0)
			adapterDataRef = adapter.Data
			updateRecyclerCanvas()
		end
	end

	function recycler:Search(keyword)
		for i,v in pairs(visibleItems) do
			visibleItems[i].Parent = nil
			visibleItems[i] = nil
		end

		searchKeyword = keyword
		filteredItems = searchKeyword and recycler.Adapter:OnSearch(searchKeyword) or recycler.Adapter.Data
		renderedItems = {}

		updateRecyclerCanvas()
		renderItems()
	end

	function recycler:NotifyDataChange(keepUnchangedItems)
		for i,v in pairs(visibleItems) do
			visibleItems[i].Parent = nil
			visibleItems[i] = nil
		end

		local itemsRef = items
		items = {}

		if keepUnchangedItems then
			for i,v in pairs(recycler.Adapter.Data) do
				local index = utils:find(adapterDataRef, function(_,i) return utils:isEqual(v, i) end)
				items[i] = itemsRef[index]
			end
		end

		renderedItems = {}
		recycler.Items = items
		adapterDataRef = recycler.Adapter.Data
		filteredItems = searchKeyword and recycler.Adapter:OnSearch(searchKeyword) or recycler.Adapter.Data

		updateRecyclerCanvas()
		renderItems()
	end

	function recycler:GetItem(position)
		return getItem(position)
	end
	
	local lastPosition = 0
	Recycler.Changed:Connect(function(p)
		if recycler.Adapter ~= nil then
			if p == "CanvasPosition" then
				local position = math.floor(Recycler.CanvasPosition.Y)
				if lastPosition == 0 or (position ~= lastPosition and math.abs(lastPosition - position) > recycler.Adapter.FixedSize) then
					renderItems()
					lastPosition = position
				end
			elseif p == "AbsoluteSize" then
				verticalSize = Recycler.AbsoluteSize.Y
				renderItems()
			end
		end
	end)

	recycler.ForceRender = renderItems
	recycler:SetAdapter(adapter)
	return recycler
end

return Library