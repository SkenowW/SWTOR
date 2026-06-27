-- ============================================================
--  SW:TOR RP — INDICATEUR VISUEL DE COUP (CLIENT)
--  lua/autorun/client/cl_swtor_swingindicator.lua
--  Affiche le nom du coup + direction détectée en temps réel
-- ============================================================

if SERVER then return end

local CurrentMove  = nil
local MoveEndTime  = 0
local LastDir      = "neutral"
local DirChanged   = false
local DirChangeT   = 0

-- Réception du nom de coup depuis le serveur
net.Receive("SWTOR_SwingLabel", function()
    local name = net.ReadString()
    CurrentMove = name
    MoveEndTime = CurTime() + 0.8
end)

-- ── Flèche directionnelle selon ZQSD ──────────────────────
local DirArrows = {
    neutral    = "●",
    forward    = "▲",
    backward   = "▼",
    left       = "◄",
    right      = "►",
    fwd_left   = "◤",
    fwd_right  = "◥",
    back_left  = "◣",
    back_right = "◢",
    jump       = "⬆",
    duck       = "⬇",
}

local DirColors = {
    neutral    = Color(200, 200, 200),
    forward    = Color(100, 220, 100),  -- Vert = attaque offensive
    backward   = Color(100, 150, 220),  -- Bleu = riposte
    left       = Color(220, 180, 80),   -- Or = balayage
    right      = Color(220, 180, 80),
    fwd_left   = Color(150, 220, 150),
    fwd_right  = Color(220, 150, 100),  -- Orange = puissant
    back_left  = Color(180, 100, 220),  -- Violet = spin
    back_right = Color(180, 100, 220),
    jump       = Color(255, 200, 50),   -- Jaune = aérien
    duck       = Color(150, 200, 255),  -- Cyan = bas
}

-- ── Détecter la direction en temps réel (côté client) ─────
hook.Add("Think", "SWTOR_DetectDir", function()
    local myclass = LocalPlayer():GetNWString("swtor_class", "")
    if myclass == "" then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) then return end
    -- Vérifier que c'est une arme de mêlée SW:TOR
    local cls = wep:GetClass()
    if not cls:find("swtor_lightsaber") and cls ~= "swtor_vibroblade" then return end

    local dir = SWTOR.Combat and SWTOR.Combat.GetMoveDir and SWTOR.Combat.GetMoveDir()
    if dir and dir ~= LastDir then
        LastDir    = dir
        DirChanged = true
        DirChangeT = CurTime()
    end
end)

-- ── Paint : affichage HUD ─────────────────────────────────
hook.Add("HUDPaint", "SWTOR_SwingIndicator", function()
    local myclass = LocalPlayer():GetNWString("swtor_class", "")
    if myclass == "" then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) then return end
    local cls = wep:GetClass()
    if not cls:find("swtor_lightsaber") and cls ~= "swtor_vibroblade" then return end

    local sw, sh   = ScrW(), ScrH()
    local cx, cy   = sw/2, sh/2
    local now      = CurTime()
    local faction  = LocalPlayer():GetNWString("swtor_faction", "")
    local fData    = SWTOR and SWTOR.Factions and SWTOR.Factions[faction]
    local fColor   = fData and fData.color or Color(200,200,200)
    local style    = SWTOR.Combat and SWTOR.Combat.GetStyle and
                     SWTOR.Combat.GetStyle(LocalPlayer()) or "single"

    -- ── Rosace directionnelle (autour du crosshair) ───────
    local roseRadius = 42
    local dirs = {
        { d="forward",    x=0,     y=-1  },
        { d="backward",   x=0,     y=1   },
        { d="left",       x=-1,    y=0   },
        { d="right",      x=1,     y=0   },
        { d="fwd_left",   x=-0.7,  y=-0.7},
        { d="fwd_right",  x=0.7,   y=-0.7},
        { d="back_left",  x=-0.7,  y=0.7 },
        { d="back_right", x=0.7,   y=0.7 },
    }

    for _, d in ipairs(dirs) do
        local isActive = LastDir == d.d
        local alpha    = isActive and 220 or 40
        local size     = isActive and 14  or 9
        local dc       = DirColors[d.d]   or Color(200,200,200)
        local sx = cx + d.x * roseRadius
        local sy = cy + d.y * roseRadius

        -- Fond si actif
        if isActive then
            local fade = math.Clamp(1-(now-DirChangeT)*3, 0, 1)
            local fa   = math.floor(fade*180)
            draw.RoundedBox(size/2, sx-size/2, sy-size/2, size, size,
                Color(dc.r, dc.g, dc.b, fa))
        end

        draw.SimpleText(DirArrows[d.d] or "?", "SWTOR_HUD_Small",
            sx, sy,
            Color(dc.r, dc.g, dc.b, alpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- ── Style d'arme (petit badge) ────────────────────────
    local styleLabels = {
        single  = "SABRE",
        dual    = "DUAL",
        double  = "STAFF",
        vibro   = "VIBRO",
    }
    local styleColors = {
        single  = Color(200, 80,  80),
        dual    = Color(220, 100, 220),
        double  = Color(220, 60,  60),
        vibro   = Color(180, 180, 200),
    }
    local sLabel = styleLabels[style] or style
    local sColor = styleColors[style] or fColor
    local badgeW = 52
    local badgeH = 18
    local badgeX = cx - badgeW/2
    local badgeY = cy + roseRadius + 10

    draw.RoundedBox(4, badgeX, badgeY, badgeW, badgeH, Color(0,0,0,140))
    surface.SetDrawColor(sColor.r, sColor.g, sColor.b, 160)
    surface.DrawOutlinedRect(badgeX, badgeY, badgeW, badgeH, 1)
    draw.SimpleText(sLabel, "SWTOR_Small2",
        cx, badgeY+badgeH/2,
        Color(sColor.r, sColor.g, sColor.b, 220),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- ── Nom du coup (flash après frappe) ──────────────────
    if CurrentMove and now < MoveEndTime then
        local t     = MoveEndTime - now
        local alpha = math.Clamp(t * 180, 0, 220)
        local y     = cy - roseRadius - 28

        -- Fond
        local tw = #CurrentMove * 7 + 20
        draw.RoundedBox(5, cx-tw/2, y-10, tw, 22,
            Color(0,0,0, math.floor(alpha*0.7)))
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, math.floor(alpha*0.6))
        surface.DrawOutlinedRect(cx-tw/2, y-10, tw, 22, 1)

        draw.SimpleText(CurrentMove, "SWTOR_HUD_Medium",
            cx, y+1,
            Color(255,230,130,alpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- ── Indicateur BLOCAGE actif ──────────────────────────
    if LocalPlayer():KeyDown(IN_ATTACK2) then
        local bAlpha = math.abs(math.sin(now*4))*80+140
        draw.SimpleText("🛡 GARDE", "SWTOR_HUD_Medium",
            cx, cy + roseRadius + 34,
            Color(100, 180, 255, bAlpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- ── Combo counter ─────────────────────────────────────
    local wepCombo = IsValid(wep) and wep.ComboCount or 0
    if wepCombo and wepCombo > 1 then
        local cAlpha = math.Clamp((CurTime() - (IsValid(wep) and wep.LastSwingT or 0)) * -2 + 2, 0, 1) * 220
        local cCol   = wepCombo >= 4 and Color(255,100,50) or
                       wepCombo >= 3 and Color(255,200,50) or
                       Color(200,220,150)
        draw.SimpleText("COMBO x" .. wepCombo, "SWTOR_HUD_Big",
            cx + roseRadius + 20, cy - 8,
            Color(cCol.r, cCol.g, cCol.b, cAlpha),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)

print("[SW:TOR] Indicateur de coup visuel chargé ✓")

-- ============================================================
--  INDICATEUR PARADE (MAJ enfoncée = icône parade visible)
-- ============================================================
hook.Add("HUDPaint", "SWTOR_ParryIndicator", function()
    local myclass = LocalPlayer():GetNWString("swtor_class", "")
    if myclass == "" then return end
    local wep = LocalPlayer():GetActiveWeapon()
    if not IsValid(wep) or not wep.SaberStyle then return end

    local sw, sh = ScrW(), ScrH()
    local cx, cy = sw/2, sh/2

    -- Détecter MAJ
    local isMAJ = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)

    if isMAJ then
        local now    = CurTime()
        local pulse  = math.abs(math.sin(now * 6)) * 60 + 180
        local style  = wep.SaberStyle or "single"

        local styleLabel = {
            single = "PARADE",
            dual   = "ESQUIVE",
            double = "BLOC TOTAL",
            vibro  = "CONTRE",
        }
        local styleColor = {
            single = Color(100, 160, 255),
            dual   = Color(180, 100, 255),
            double = Color(50,  200, 255),
            vibro  = Color(200, 160, 50),
        }
        local lbl  = styleLabel[style] or "PARADE"
        local col  = styleColor[style] or Color(100,160,255)

        -- Fond
        local tw = #lbl * 9 + 24
        draw.RoundedBox(6, cx-tw/2, cy+55, tw, 26,
            Color(0, 0, 0, 160))
        surface.SetDrawColor(col.r, col.g, col.b, pulse)
        surface.DrawOutlinedRect(cx-tw/2, cy+55, tw, 26, 2)

        -- Texte
        draw.SimpleText("🛡 " .. lbl, "SWTOR_HUD_Medium",
            cx, cy+68,
            Color(col.r, col.g, col.b, pulse),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Cercle de garde autour du crosshair
        local radius = 28
        local steps  = 24
        local filled = 1.0  -- Plein tant que MAJ enfoncée
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(pulse * 0.5))
        for i = 0, math.floor(steps * filled) - 1 do
            local a1 = math.rad(i/steps*360 - 90)
            local a2 = math.rad((i+1)/steps*360 - 90)
            surface.DrawLine(
                cx + math.cos(a1)*radius, cy + math.sin(a1)*radius,
                cx + math.cos(a2)*radius, cy + math.sin(a2)*radius)
        end
    end
end)
