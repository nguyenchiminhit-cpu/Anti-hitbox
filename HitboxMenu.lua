local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local IMAGE_FILE = "hitbox_logo.jpg"
local IMAGE_ID = ""

local env = (getgenv and getgenv()) or shared
if env.HitboxMenuCleanup then
    pcall(env.HitboxMenuCleanup)
    env.HitboxMenuCleanup = nil
end

local old = (gethui and gethui() or CoreGui):FindFirstChild("HitboxMenuPro")
if old then
    old:Destroy()
end

local state = {
    enabled = false,
    rootSize = 10,
    headSize = 6,
    transparency = 0.7,
    color = Color3.fromRGB(255, 70, 70),
    root = true,
    head = true,
}

local ESP_RELOAD = 10
local ESP_COLOR = Color3.fromRGB(90, 220, 140)
local HEAD_PHYSICS = PhysicalProperties.new(0.01, 0.3, 0, 1, 1)

local esp = {
    active = false,
    nextReload = 0,
    items = {},
}

local originals = setmetatable({}, { __mode = "k" })
local connections = {}

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function round(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function tween(obj, time, props)
    TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local IMAGE_DATA = "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"

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function decode(data)
    data = data:gsub("[^" .. B64 .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then
            return ""
        end
        local r, f = "", (B64:find(x, 1, true) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then
            return ""
        end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

local function loadImage()
    local ok, result = pcall(function()
        if writefile and getcustomasset then
            if not (isfile and isfile(IMAGE_FILE)) then
                writefile(IMAGE_FILE, decode(IMAGE_DATA))
            end
            return getcustomasset(IMAGE_FILE)
        end
    end)
    if ok and result then
        return result
    end
    return IMAGE_ID
end

local imageSource = loadImage()

local PIXELS = "15211d142d25214136223b32182e262139301d2e281315140e0e0e0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0d0e161a191110111c2d28274a3f224136243f3622383020372f213830112a210f2f24113229214237213d34192e271219160c0c0c0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e0d0d1f2c282b4e421c3b31213830213830213830213830112f2710312910302b0e2f2313352a141e1a0c0a0b0e0e0e1110101010100e0e0e0e0e0e0f0e0e0e0e0e0e0e0e0e0e0e0f0e0e0f10101b2d2620393121373021383021383021383010302b12323212322b0f32261326201111111010101414141717171313131211111111111111111010101111101212121212121413141617161e332c2139302238312238321d3a3313342915353013343113312a18221e1817171b1b1a191b1c3129252e272516191a1b1c1d1d1d1e1c1c1d1616171414141716161819181817171b27221f3b33233b33263c331f3b3415362c15362a12352b152c271c1f1d1f20211e202024242263483d60453f352e2a3d34304c3a354637332e2e2c202324202222191a1a100f0f1314141e322c233b33243a32233a3215353315362b14372b17221e1c1a1b3329262d211d623b329d695a9a655988574b7b53488f60537d53435b3d334937324f3a302524210f1010100f0f1e2f2921393120372f213830163635163632163731181f1e1a18185c3b32704335975e51b78173b47f71b98274b58072bb8c7caa7f6d895e4d805d4a9771585a473815161715151420322b22393120372f213830173736183737173838111a1b211c1a5f4237714b3e9b705fb88778c28e80c69284c69787b8907f9f76658a65588264548468527c5f4b241f1d101011182924223a322137302138301a3a371939381738350f16151f1918593c307d5648956656aa7869c38f82cf9a8dc89788b58678bf8c7dc19381b0816f98705d8c6b52372d250d0d0e443b32243c341f3930213b321a3a391938381839360f1d1b2e1e1b8c5c4aae7a64ba8577b17a6bb67e6fcd9b8dc79385c18b7ea5776b8d6a5d996a59aa7b61a57e61493c2f30261fa76d5c31453a193e3420403d1a3a391a3938183a390d212048302787594669463b6247408e6155ad7660c69787c18f7cad7b697b50487c594f946a5aa17961a87f6465543e7d5847b37a6630453c1e413e2544441a3a391a3a39173837132a295d44399466529e6e5da47364a5745ea8755cb98a7aba8d77bc947abe8e7ac08972c39480bc9383b1836f80654da377608c6b5a1f3f3a2444432545441a3a381a3a37163736143133765749b6826bc18e78be8b72af7d63a6735fbb8c7eb58b75bc8f79c89786c9907fd2a192cb9c8cba867387665299775e695f4f1e443e2948422848401a3b301a3a2f1535311230317d5b4ec18a7bcb9988ca9787a57362af7b6dc99b8bc69686b68174ba8477c6877dd69e93d5a092be887085654c8b6d56595a4e2a4b4328403a223c36193a2f1637331638370d302f715447c8887dcb9387ba8172a96f64b77e72c0887bbe8579b67c70bf897cbf8478bd7f75cc8e85b87b688e644942463c1c3633213f3e25444327474416372d13312f172b280d2221503a32b47368b17364b27564a96d61a96b5eb87d70be8b7cba8b7abf8d7ac18c7dab7060b17462ae6f5b976550343f361c3b362748462a4b4430514b13382f1227231615141217173128239a6050ac6f59955d4e945a4fa56054b76e6abd7876b4736ca96e668d5d54af7462bf826cb577629568552a372e1a3b352646452b4b4433545113221f151d1a161918121213181515835245c2836da466588c4848af7674c99b96d0a59ec7938fa86c69a57064c08671c1846fbb7e677d5e4f142b2617322a2242402b4c4b355554132522161918100f100f0f0e05090a442f29b57764bc826e9d6459a25b59c3767ad08b8ebd7778b16e65bb8970be8974be816eae765f4b4a3e0e1a17121e19183030224040335050141e1d171b191717171313131212120f101068483fb37864a67263a4655ab76a65c27b76c08278c18d7dbd8c72bc8a73b17c68855f4d454e3f185a4c19615323534d2a62583a736a1514141212121212121112121213120e0f101413137353479e6b5bb2786cc3867acb9083d2978cce9483bb896fad7a629567576b533d66543f2887711999828cb9ac8eb2a761a6981819191715161715151a19191a1718191516161f1c2430286748399a6c5cc6887dd5978cd7988ec88d7ea2735c936252855747825d49805e44487c6502917783b1a397b6ab82b0a41618171829241d2d27111a180f2923153228144233333c3055302763423698695ab47e70b47d709e6c5d8e604d955f5196604f946c519d6e5157846a02967e239c83129575359e87"
local GRID = 24

local function buildPixelLogo(parent)
    parent.ClipsDescendants = true
    for i = 0, GRID * GRID - 1 do
        local hex = PIXELS:sub(i * 6 + 1, i * 6 + 6)
        make("Frame", {
            Size = UDim2.new(1 / GRID, 1, 1 / GRID, 1),
            Position = UDim2.new((i % GRID) / GRID, 0, math.floor(i / GRID) / GRID, 0),
            BackgroundColor3 = Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)),
            BorderSizePixel = 0,
        }, parent)
    end
end

local gui = make("ScreenGui", {
    Name = "HitboxMenuPro",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})

local parented = pcall(function()
    gui.Parent = gethui and gethui() or CoreGui
end)
if not parented or not gui.Parent then
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local espFolder = make("Folder", { Name = "ESP" }, gui)

local BG = Color3.fromRGB(15, 15, 21)
local PANEL = Color3.fromRGB(28, 28, 40)
local ACCENT = Color3.fromRGB(124, 98, 255)
local ACCENT_DARK = Color3.fromRGB(56, 44, 130)
local TEXT = Color3.fromRGB(240, 240, 250)
local MUTED = Color3.fromRGB(135, 135, 160)
local OFF = Color3.fromRGB(60, 60, 80)
local GREEN = Color3.fromRGB(80, 210, 130)

local MAIN_W, HEAD_H = 188, 34

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.new(0, MAIN_W, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 10, 0.5, 0),
    BackgroundColor3 = BG,
    BackgroundTransparency = 0.03,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
round(main, 14)
make("UIStroke", { Color = ACCENT, Thickness = 1.2, Transparency = 0.5 }, main)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, main)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, HEAD_H),
    BackgroundColor3 = ACCENT_DARK,
    BorderSizePixel = 0,
    LayoutOrder = 0,
}, main)
make("UIGradient", { Color = ColorSequence.new(ACCENT_DARK, PANEL) }, header)

local avatar = make("ImageLabel", {
    Size = UDim2.new(0, 22, 0, 22),
    Position = UDim2.new(0, 8, 0.5, -11),
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
    Image = imageSource,
    ScaleType = Enum.ScaleType.Crop,
}, header)
round(avatar, 11)

make("TextLabel", {
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(0, 36, 0, 0),
    BackgroundTransparency = 1,
    Text = "HITBOX",
    TextColor3 = TEXT,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local dot = make("Frame", {
    Size = UDim2.new(0, 8, 0, 8),
    Position = UDim2.new(0, 96, 0.5, -4),
    BackgroundColor3 = OFF,
    BorderSizePixel = 0,
}, header)
round(dot, 4)

local minBtn = make("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -30, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.6,
    Text = "–",
    TextColor3 = TEXT,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, header)
round(minBtn, 12)

local bubble = make("ImageButton", {
    Name = "Bubble",
    Size = UDim2.new(0, 44, 0, 44),
    AnchorPoint = Vector2.new(0, 0.5),
    Position = main.Position,
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
    Image = imageSource,
    ScaleType = Enum.ScaleType.Crop,
    Visible = false,
    AutoButtonColor = false,
}, gui)
round(bubble, 22)
make("UIStroke", { Color = ACCENT, Thickness = 2.5 }, bubble)

if imageSource == "" then
    buildPixelLogo(bubble)
    buildPixelLogo(avatar)
end

local tabWrap = make("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
}, main)

local seg = make("Frame", {
    Size = UDim2.new(1, -16, 0, 28),
    Position = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
}, tabWrap)
round(seg, 10)

local pageHolder = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 2,
}, main)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, pageHolder)
make("UIPadding", {
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
}, pageHolder)

local function makePage(order)
    local page = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Visible = false,
    }, pageHolder)
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    return page
end

local hitPage = makePage(1)
local espPage = makePage(2)

local tabs = {}

local function selectTab(name)
    for key, tab in pairs(tabs) do
        local active = key == name
        tab.page.Visible = active
        tween(tab.button, 0.15, {
            BackgroundTransparency = active and 0 or 1,
            TextColor3 = active and TEXT or MUTED,
        })
    end
end

local function makeTab(name, text, xScale, xOffset, page)
    local button = make("TextButton", {
        Size = UDim2.new(0.5, -4, 1, -6),
        Position = UDim2.new(xScale, xOffset, 0, 3),
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = MUTED,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, seg)
    round(button, 8)
    tabs[name] = { button = button, page = page }
    button.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
end

makeTab("hit", "Hitbox", 0, 3, hitPage)
makeTab("esp", "ESP", 0.5, 1, espPage)

local function panelRow(parent, height, class)
    local row = make(class or "Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
    }, parent)
    round(row, 10)
    return row
end

local function makeSwitch(parent, text, order, onChange)
    local row = panelRow(parent, 34, "TextButton")
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = order

    make("TextLabel", {
        Size = UDim2.new(1, -64, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = TEXT,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local track = make("Frame", {
        Size = UDim2.new(0, 42, 0, 22),
        Position = UDim2.new(1, -52, 0.5, -11),
        BackgroundColor3 = OFF,
        BorderSizePixel = 0,
    }, row)
    round(track, 11)

    local knob = make("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, track)
    round(knob, 8)

    local value = false
    row.MouseButton1Click:Connect(function()
        value = not value
        tween(track, 0.2, { BackgroundColor3 = value and ACCENT or OFF })
        tween(knob, 0.2, { Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
        onChange(value)
    end)
end

local function makeSlider(parent, order, title, min, max, start, decimals, onChange, key)
    local holder = panelRow(parent, 42)
    holder.LayoutOrder = order

    local labelX = 12
    if key then
        labelX = 34
        local check = make("TextButton", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 12, 0, 6),
            BackgroundColor3 = state[key] and ACCENT or OFF,
            Text = "",
            AutoButtonColor = false,
        }, holder)
        round(check, 7)
        check.MouseButton1Click:Connect(function()
            state[key] = not state[key]
            tween(check, 0.15, { BackgroundColor3 = state[key] and ACCENT or OFF })
        end)
    end

    make("TextLabel", {
        Size = UDim2.new(0.6, -labelX + 12, 0, 18),
        Position = UDim2.new(0, labelX, 0, 4),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = TEXT,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local valueLabel = make("TextLabel", {
        Size = UDim2.new(0.4, -12, 0, 18),
        Position = UDim2.new(0.6, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(start),
        TextColor3 = ACCENT,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, holder)

    local bar = make("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 30),
        BackgroundColor3 = Color3.fromRGB(48, 48, 66),
        BorderSizePixel = 0,
    }, holder)
    round(bar, 3)

    local fill = make("Frame", {
        Size = UDim2.new((start - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
    }, bar)
    round(fill, 3)

    local thumb = make("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(1, -8, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, fill)
    round(thumb, 8)

    local hit = make("TextButton", {
        Size = UDim2.new(1, 0, 1, -22),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 2,
    }, holder)

    local dragging = false
    local mult = 10 ^ decimals

    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = math.floor((min + (max - min) * rel) * mult + 0.5) / mult
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valueLabel.Text = tostring(value)
        onChange(value)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local status = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundTransparency = 1,
    Text = "Đang tắt",
    TextColor3 = MUTED,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    LayoutOrder = 7,
}, hitPage)

local function restore(part)
    local data = originals[part]
    if data and part.Parent then
        part.Size = data.Size
        part.Transparency = data.Transparency
        part.Color = data.Color
        part.Material = data.Material
        part.CanCollide = data.CanCollide
        part.Massless = data.Massless
        part.CustomPhysicalProperties = data.Physics
    end
    originals[part] = nil
end

local function restoreAll()
    for part in pairs(originals) do
        restore(part)
    end
end

local function apply(part, value)
    if not originals[part] then
        originals[part] = {
            Size = part.Size,
            Transparency = part.Transparency,
            Color = part.Color,
            Material = part.Material,
            CanCollide = part.CanCollide,
            Massless = part.Massless,
            Physics = part.CustomPhysicalProperties,
        }
        if part.Name == "Head" then
            part.Massless = true
            part.CustomPhysicalProperties = HEAD_PHYSICS
        end
    end
    local size = Vector3.new(value, value, value)
    if part.Size ~= size then
        part.Size = size
    end
    if part.Transparency ~= state.transparency then
        part.Transparency = state.transparency
    end
    if part.Color ~= state.color then
        part.Color = state.color
    end
    if part.Material ~= Enum.Material.Neon then
        part.Material = Enum.Material.Neon
    end
    if part.CanCollide then
        part.CanCollide = false
    end
end

local function setEnabled(value)
    state.enabled = value
    tween(dot, 0.2, { BackgroundColor3 = value and GREEN or OFF })
    if not value then
        restoreAll()
        status.Text = "Đang tắt"
        status.TextColor3 = MUTED
    end
end

makeSwitch(hitPage, "Bật hitbox", 1, setEnabled)

makeSlider(hitPage, 2, "Thân", 2, 50, state.rootSize, 0, function(v)
    state.rootSize = v
end, "root")

makeSlider(hitPage, 3, "Đầu", 2, 30, state.headSize, 0, function(v)
    state.headSize = v
end, "head")

makeSlider(hitPage, 4, "Độ trong suốt", 0, 1, state.transparency, 1, function(v)
    state.transparency = v
end)

local colorRow = panelRow(hitPage, 32)
colorRow.LayoutOrder = 5

local palette = {
    Color3.fromRGB(255, 70, 70),
    Color3.fromRGB(70, 140, 255),
    Color3.fromRGB(60, 220, 120),
    Color3.fromRGB(180, 90, 255),
    Color3.fromRGB(255, 255, 255),
}

local swatches = {}
for i, color in ipairs(palette) do
    local sw = make("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new((i - 0.5) / #palette, -11, 0.5, -11),
        BackgroundColor3 = color,
        Text = "",
        AutoButtonColor = false,
    }, colorRow)
    round(sw, 11)
    swatches[i] = make("UIStroke", {
        Color = Color3.new(1, 1, 1),
        Thickness = 2,
        Enabled = i == 1,
    }, sw)
    sw.MouseButton1Click:Connect(function()
        state.color = color
        for j, s in ipairs(swatches) do
            s.Enabled = j == i
        end
    end)
end

local espInfo = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "Thấy tất cả người chơi xuyên tường, tự tải lại mỗi " .. ESP_RELOAD .. " giây.",
    TextColor3 = MUTED,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 2,
}, espPage)

local espStatus = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundTransparency = 1,
    Text = "Đang tắt",
    TextColor3 = MUTED,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    LayoutOrder = 3,
}, espPage)

local function clearEsp(player)
    local item = esp.items[player]
    if item then
        item.box:Destroy()
        item.tag:Destroy()
        esp.items[player] = nil
    end
end

local function clearAllEsp()
    for player in pairs(esp.items) do
        clearEsp(player)
    end
end

local function buildEsp(player, root)
    local box = make("BoxHandleAdornment", {
        Adornee = root,
        AlwaysOnTop = true,
        ZIndex = 5,
        Size = Vector3.new(4, 6, 2),
        Transparency = 0.55,
        Color3 = ESP_COLOR,
    }, espFolder)
    local tag = make("BillboardGui", {
        Adornee = root,
        AlwaysOnTop = true,
        Size = UDim2.new(0, 130, 0, 34),
        StudsOffset = Vector3.new(0, 4.5, 0),
    }, espFolder)
    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = player.DisplayName,
        TextColor3 = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0.3,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
    }, tag)
    return { box = box, tag = tag, label = label, root = root }
end

local function setEsp(value)
    esp.active = value
    if value then
        esp.nextReload = os.clock() + ESP_RELOAD
    else
        clearAllEsp()
        espStatus.Text = "Đang tắt"
        espStatus.TextColor3 = MUTED
    end
end

makeSwitch(espPage, "Bật ESP", 1, setEsp)

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not state.enabled then
        if next(originals) then
            restoreAll()
        end
        return
    end
    local wanted = {}
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player ~= LocalPlayer and player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local root = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            if state.root and root then
                wanted[root] = state.rootSize
            end
            if state.head and head then
                wanted[head] = state.headSize
            end
            count = count + 1
        end
    end
    for part, value in pairs(wanted) do
        apply(part, value)
    end
    for part in pairs(originals) do
        if not wanted[part] then
            restore(part)
        end
    end
    status.Text = "Đang bật • " .. count .. " người chơi"
    status.TextColor3 = GREEN
end))

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not esp.active then
        return
    end
    local remaining = esp.nextReload - os.clock()
    if remaining <= 0 then
        clearAllEsp()
        esp.nextReload = os.clock() + ESP_RELOAD
        remaining = ESP_RELOAD
    end
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local item = esp.items[player]
            if item and item.root ~= root then
                clearEsp(player)
                item = nil
            end
            if root and not item then
                item = buildEsp(player, root)
                esp.items[player] = item
            end
            if item then
                count = count + 1
                local text = player.DisplayName
                if myRoot then
                    text = text .. "\n" .. math.floor((root.Position - myRoot.Position).Magnitude) .. "m"
                end
                item.label.Text = text
            end
        end
    end
    espStatus.Text = "Đang bật • " .. count .. " người • tải lại " .. math.ceil(remaining) .. "s"
    espStatus.TextColor3 = GREEN
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(player)
    clearEsp(player)
end))

local function makeDraggable(handle, target, onTap)
    local dragging = false
    local moved = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onTap then
                        onTap()
                    end
                end
            end)
        end
    end)

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                moved = true
            end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end))
end

local function collapse()
    bubble.Position = main.Position
    main.Visible = false
    bubble.Visible = true
end

local function expand()
    main.Position = bubble.Position
    bubble.Visible = false
    main.Visible = true
end

minBtn.MouseButton1Click:Connect(collapse)
makeDraggable(header, main)
makeDraggable(bubble, bubble, expand)

selectTab("hit")

pcall(function()
    local vu = game:GetService("VirtualUser")
    table.insert(connections, LocalPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end))
end)

env.HitboxMenuCleanup = function()
    for _, c in ipairs(connections) do
        c:Disconnect()
    end
    restoreAll()
    clearAllEsp()
    gui:Destroy()
end
