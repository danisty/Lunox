--// Services
local Mouse = game.Players.LocalPlayer:GetMouse()
local TS = game:GetService("TweenService")
local TXTS = game:GetService("TextService")

local player = game.Players.LocalPlayer

local Utils = {}

function Utils:inArea(gO)
	return Mouse.X >= gO.AbsolutePosition.X and Mouse.X <= gO.AbsolutePosition.X + gO.AbsoluteSize.X
		and Mouse.Y >= gO.AbsolutePosition.Y and Mouse.Y <= gO.AbsolutePosition.Y + gO.AbsoluteSize.Y
end

function Utils:vInArea(v1, v2)
	return Mouse.X >= v1.X and Mouse.X <= v2.X and Mouse.Y >= v1.Y and Mouse.Y <= v2.Y
end

function Utils:find(t, val)
	local isFunc = type(val) == "function"
	for i,v in pairs(t) do
		if isFunc and val(i, v) or val == v then
			return i, v
		end
	end
end

function Utils:filter(t, f, tuple)
	local m = {}
	for i,v in pairs(t) do
		if f(v) then
			if tuple then
				table.insert(m, {i, v})
			elseif type(i) == "number" then
				table.insert(m, v)
			else
				m[i] = v
			end
		end
	end
	return m
end

function Utils:copy(t)
	local n = {}
	for i,v in pairs(t) do
		n[i] = v
	end
	return n
end

function Utils:isEqual(t1, t2)
	for i,v in pairs(t1) do
		if t2[i] ~= v then
			return false
		end
	end
	return true
end

function Utils:getSize(t)
	local c = 0
	for i,v in pairs(t) do
		c += 1
	end
	return c
end

function Utils:getBounds(gO, size)
	return TXTS:GetTextSize(gO.Text:gsub("<[^>]+>([^<]+)</%w+>", "%1"), gO.TextSize, gO.Font, size or Vector2.new(9999, 9999))
end

function Utils:scaleToOffset(gO, u)
	return UDim2.new(0, u.X.Scale * gO.AbsoluteSize.X + u.X.Offset, 0, u.Y.Scale * gO.AbsoluteSize.Y + u.Y.Offset)
end

function Utils:setHovering(gO, properties, colorRetriever, tweenDelay)
	local tweenInfo = TweenInfo.new(tweenDelay or .1, Enum.EasingStyle.Linear)
	gO.InputBegan:Connect(function(input)
		local colors = colorRetriever()
		if input.UserInputType == Enum.UserInputType.MouseButton1 and colors.ClickStarted then
			for i,v in pairs(properties) do
				TS:Create(gO, tweenInfo, {[v]=colors.ClickStarted}):Play()
			end
		end
	end)
	gO.InputEnded:Connect(function(input)
		local colors = colorRetriever()
		if input.UserInputType == Enum.UserInputType.MouseButton1 and colors.ClickEnded and Utils:inArea(gO) then
			for i,v in pairs(properties) do
				TS:Create(gO, tweenInfo, {[v]=colors.ClickEnded}):Play()
			end
		end
	end)
	gO.MouseEnter:Connect(function()
		local colors = colorRetriever()
		if colors.Hovering then
			for i,v in pairs(properties) do
				TS:Create(gO, tweenInfo, {[v]=colors.Hovering}):Play()
			end
		end
	end)
	gO.MouseLeave:Connect(function()
		local colors = colorRetriever()
		if colors.Default then
			for i,v in pairs(properties) do
				TS:Create(gO, tweenInfo, {[v]=colors.Default}):Play()
			end
		end
	end)
end

function Utils:getPath(instance)
	local path = ""
	local pathParts = {instance}

	while pathParts[#pathParts] ~= game do
		if pathParts[#pathParts].Parent == nil then
			return "nil"
		end
		local part = pathParts[#pathParts].Name:gsub("\n", "\\n"):gsub("\"", "\\\"")
		path = (part:match("[a-zA-Z_][a-zA-Z0-9_]+") == part and "." .. part or ('["%s"]'):format(part)) .. path
		pathParts[#pathParts+1] = pathParts[#pathParts].Parent
	end
	
	return ("game" .. path):gsub("game.Players." .. player.Name, "game.Players.LocalPlayer"):gsub("game.Workspace." .. player.Name, "game.Players.LocalPlayer.Character")
end

function Utils:fromPath(path)
	return loadstring("return " .. path)()
end

function Utils:fixIndex(index)
    local strIndex = (type(index) == "string" and index:gsub("\\", "\\\\") or tostring(index)):gsub("\"", "\\\"")
    return strIndex:match("[a-zA-Z_][a-zA-Z0-9_]*") == strIndex and "." .. strIndex or ("[%s]"):format(type(index) == "number" and strIndex or '"' .. strIndex .. '"')
end

function Utils:stringify(object) --// This is a compact mess, don't look at it for too long
	local objectType = typeof(object)
	local strObject = tostring(object)

	if objectType == "string" then
		return '"' .. object .. '"'
	elseif objectType == "boolean" or objectType == "number" or objectType == "string" then
		return strObject
	elseif objectType:find("Vector") or objectType == "UDim" or objectType == "Color3" or objectType == "CFrame" or objectType == "Rect" then
		return objectType .. ".new(" .. strObject .. ")"
	elseif objectType == "UDim2" then
		return objectType .. ".new(" .. strObject:gsub("{", ""):gsub("}", "") .. ")"
	elseif objectType == "Instance" then
		return object.Parent and Utils:getPath(object) or nil
	elseif objectType:find("Enum") then
		return objectType == "Enums" and "Enums" or (objectType == "Enum" and ("Enum." .. strObject) or strObject)
	elseif objectType == "Region3" then
		local position, size = object.CFrame.p, object.Size
		local minVector = position - size/2
		return ("Region3.new(%s, %s)"):format(Utils:stringify(minVector), Utils:stringify(minVector + size))
	elseif objectType == "NumberRange" then
		return "NumberRange.new(" .. strObject:sub(1, -2):gsub(" ", ", ") .. ")"
	elseif objectType == "ColorSequenceKeypoint" then
		return ("ColorSequenceKeypoint.new(%d, %s)"):format(object.Time, Utils:stringify(object.Value))
	elseif objectType == "NumberSequenceKeypoint" then
		return ("NumberSequenceKeypoint.new(%d, %d, %d)"):format(object.Time, object.Value, object.Envelope)
	elseif objectType == "ColorSequence" or objectType == "NumberSequence" then
		local keypoints = {}
		for i,v in pairs(object.Keypoints) do
			table.insert(keypoints, Utils:stringify(v))
		end
		return objectType .. ".new({" .. table.concat(keypoints, ", ") .. "})"
	elseif objectType == "TweenInfo" then
		return ("TweenInfo.new(%d, %s, %s, %d, %s, %d)"):format(object.Time, Utils:stringify(object.EasingStyle), Utils:stringify(object.EasingDirection), object.RepeatCount, tostring(object.Reverses), object.DelayTime)
	elseif objectType == "Ray" then
		return ("Ray.new(%s, %s)"):format(Utils:stringify(object.Origin), Utils:stringify(object.Direction))
	elseif objectType == "DateTime" then
		return "DateTime.fromUnixTimestampMillis(" .. strObject .. ")"
	end
end

return Utils