-- made by @mcs.s on discord

local Mk = {}

Mk.ink = {
	back = Color3.fromRGB(22, 23, 28),
	sheet = Color3.fromRGB(30, 32, 39),
	step = Color3.fromRGB(38, 41, 50),
	edge = Color3.fromRGB(58, 62, 74),
	text = Color3.fromRGB(232, 235, 242),
	dim = Color3.fromRGB(150, 156, 170),
	hot = Color3.fromRGB(255, 118, 138),
	cool = Color3.fromRGB(112, 196, 255),
}

function Mk.new(kind: string, props: { [string]: any }?, kids: { Instance }?): any
	local thing = Instance.new(kind)
	local dad: Instance? = nil
	if props then
		for key, val in props do
			if key == "Parent" then
				dad = val
			else
				(thing :: any)[key] = val
			end
		end
	end
	if kids then
		for _, kid in kids do
			kid.Parent = thing
		end
	end
	thing.Parent = dad
	return thing
end

function Mk.round(n: number): UICorner
	return Mk.new("UICorner", { CornerRadius = UDim.new(0, n) })
end

function Mk.edge(hue: Color3?, thick: number?): UIStroke
	return Mk.new("UIStroke", {
		Color = hue or Mk.ink.edge,
		Thickness = thick or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Mk.pad(n: number): UIPadding
	return Mk.new("UIPadding", {
		PaddingTop = UDim.new(0, n),
		PaddingBottom = UDim.new(0, n),
		PaddingLeft = UDim.new(0, n),
		PaddingRight = UDim.new(0, n),
	})
end

function Mk.stack(gap: number, across: boolean?): UIListLayout
	return Mk.new("UIListLayout", {
		Padding = UDim.new(0, gap),
		FillDirection = if across then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Mk.text(body: string, props: { [string]: any }?): TextLabel
	local base = {
		BackgroundTransparency = 1,
		Text = body,
		TextColor3 = Mk.ink.text,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
	}
	if props then
		for key, val in props do
			base[key] = val
		end
	end
	return Mk.new("TextLabel", base)
end

function Mk.btn(body: string, props: { [string]: any }?): TextButton
	local base = {
		BackgroundColor3 = Mk.ink.step,
		BorderSizePixel = 0,
		Text = body,
		TextColor3 = Mk.ink.text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		AutoButtonColor = true,
	}
	if props then
		for key, val in props do
			base[key] = val
		end
	end
	local out = Mk.new("TextButton", base, { Mk.round(6) })
	return out
end

function Mk.face(id: number, size: number): ImageLabel
	return Mk.new("ImageLabel", {
		BackgroundColor3 = Mk.ink.back,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", id),
	}, { Mk.round(math.floor(size / 2)) })
end

return Mk
