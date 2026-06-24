-- ============================================================
--  SW:TOR RP — HUD PRINCIPAL v3 (Force / Speed / Energie)
--  lua/autorun/client/cl_swtor_hud.lua
--  Refait pour intégrer les 3 stats, la classe, et les barres
-- ============================================================

if SERVER then return end

-- ── Fonts ──────────────────────────────────────────────────
surface.CreateFont("SWTOR_HUD_Big",    { font = "Trebuchet MS", size = 22, weight = 700 })
surface.CreateFont("SWTOR_HUD_Medium", { font = "Trebuchet MS", size = 16, weight = 600 })
surface.CreateFont("SWTOR_HUD_Small",  { font = "Trebuchet MS", size = 13, weight = 400 })
surface.CreateFont("SWTOR_HUD_Title",  { font = "Trebuchet MS", size = 28, weight = 900 })
surface.CreateFont("SWTOR_Notif",      { font = "Trebuchet MS", size = 17, weight = 600 })
surface.CreateFont("SWTOR_Small2",     { font = "Trebuchet MS", size = 12, weight = 400 })
surface.CreateFont("SWTOR_HUD_Icon",   { font = "Trebuchet MS", size = 18, weight = 900 })

-- ── Données locales (reçues du serveur) ───────────────────
LocalData = {
    faction     = "",
    class       = "",
    grade       = 1,
    xp          = 0,
    credits     = 0,
    planet      = "",
    kills       = 0,
    deaths      = 0,
    stat_force  = 10,
    stat_speed  = 10,
    stat_energy = 10,
    stat_points = 0,
    title       = "",
    duels_won   = 0,
    duels_lost  = 0,
}

-- Énergie actuelle (interpolée côté client)
local CurrentEnergy  = 100
local MaxEnergy      = 100
local EnergySmooth   = 100

-- HP et Armure smooth
local HPSmooth       = 100
local ArmorSmooth    = 0

-- ── Réception sync ────────────────────────────────────────
net.Receive("SWTOR_SyncData", function()
    LocalData.faction     = net.ReadString()
    LocalData.class       = net.ReadString()
    LocalData.grade       = net.ReadUInt(8)
    LocalData.xp          = net.ReadUInt(32)
    LocalData.credits     = net.ReadUInt(32)
    LocalData.planet      = net.ReadString()
    LocalData.kills       = net.ReadUInt(16)
    LocalData.deaths      = net.ReadUInt(16)
    LocalData.stat_force  = net.ReadUInt(8)
    LocalData.stat_speed  = net.ReadUInt(8)
    LocalData.stat_energy = net.ReadUInt(8)
    LocalData.stat_points = net.ReadUInt(8)
    LocalData.title       = net.ReadString()
    LocalData.duels_won   = net.ReadUInt(16)
    LocalData.duels_lost  = net.ReadUInt(16)

    -- Recalc max energy selon classe
    local cls = SWTOR and SWTOR.Classes and SWTOR.Classes[LocalData.class]
    MaxEnergy = (cls and cls.stats.force_max or 100) +
                math.floor(LocalData.stat_energy * 2)
end)

-- ── Notifications ─────────────────────────────────────────
local Notifications = {}

net.Receive("SWTOR_Notification", function()
    local msg  = net.ReadString()
    local type = net.ReadString()
    local typeColors = {
        success = Color(50,  200, 80),
        warning = Color(230, 180, 0),
        error   = Color(220, 50,  50),
        info    = Color(80,  160, 255),
        credits = Color(220, 180, 20),
    }
    table.insert(Notifications, 1, {
        msg   = msg,
        color = typeColors[type] or Color(200, 200, 200),
        born  = CurTime(),
        life  = 5,
    })
    if #Notifications > 6 then Notifications[#Notifications] = nil end
end)

-- ============================================================
--  UTILITAIRES HUD
-- ============================================================
local function GetFaction()
    if not SWTOR or not SWTOR.Factions then return nil end
    return SWTOR.Factions[LocalData.faction]
end

local function GetClass()
    if not SWTOR or not SWTOR.Classes then return nil end
    return SWTOR.Classes[LocalData.class]
end

local function GetGradeName()
    local grades = SWTOR and SWTOR.Grades and SWTOR.Grades[LocalData.faction]
    if not grades then return "N/A" end
    local g = grades[LocalData.grade]
    return g and g.name or "N/A"
end

local function GetPlanetName()
    local p = SWTOR and SWTOR.Planets and SWTOR.Planets[LocalData.planet]
    return p and p.name or "Espace"
end

-- Barre standard avec animation smooth
local function DrawBar(x, y, w, h, ratio, fillColor, bgColor, label, labelColor)
    ratio = math.Clamp(ratio, 0, 1)
    -- Fond
    draw.RoundedBox(h/2, x, y, w, h, bgColor or Color(0, 0, 0, 140))
    -- Remplissage avec coins arrondis
    if ratio > 0.01 then
        local fw = math.max(h, w * ratio)
        draw.RoundedBox(h/2, x, y, fw, h, fillColor)
    end
    -- Texte centré
    if label then
        draw.SimpleText(label, "SWTOR_Small2",
            x + w/2, y + h/2,
            labelColor or Color(255,255,255,200),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Barre avec valeur numérique
local function DrawStatBar(x, y, w, h, val, maxVal, col, icon)
    local ratio = maxVal > 0 and val/maxVal or 0
    draw.RoundedBox(h/2, x, y, w, h, Color(0,0,0,150))
    if ratio > 0.02 then
        draw.RoundedBox(h/2, x, y, math.max(h, w*ratio), h, col)
    end
    draw.SimpleText(icon .. " " .. math.floor(val) .. "/" .. math.floor(maxVal),
        "SWTOR_Small2", x + w/2, y + h/2,
        Color(255,255,255,210), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- ============================================================
--  PAINT PRINCIPAL
-- ============================================================
hook.Add("HUDPaint", "SWTOR_MainHUD", function()
    if LocalData.faction == "" then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local sw, sh   = ScrW(), ScrH()
    local faction  = GetFaction()
    local cls      = GetClass()
    local fCol     = faction and faction.color or Color(150,150,150)
    local cCol     = cls and cls.color or fCol
    local fr       = fCol.r; local fg = fCol.g; local fb = fCol.b

    local hp       = ply:Health()
    local maxhp    = ply:GetMaxHealth()
    local armor    = ply:Armor()

    -- Smooth HP et Armor
    HPSmooth    = math.Approach(HPSmooth,    hp,    5)
    ArmorSmooth = math.Approach(ArmorSmooth, armor, 3)

    -- Energie courante (interpolée)
    local rawEnergy = ply.swtor_current_energy or MaxEnergy
    EnergySmooth = math.Approach(EnergySmooth, rawEnergy, 2)

    -- ════════════════════════════════════════════════════════
    --  PANNEAU GAUCHE — Identité & stats
    -- ════════════════════════════════════════════════════════
    local panW = 270
    local panH = 220
    local px   = 15
    local py   = sh - panH - 15

    -- Ombre portée
    draw.RoundedBox(10, px+3, py+3, panW, panH, Color(0,0,0,80))
    -- Fond
    draw.RoundedBox(10, px, py, panW, panH, Color(6, 8, 18, 210))
    -- Accent couleur faction (barre gauche)
    surface.SetDrawColor(fr, fg, fb, 220)
    surface.DrawRect(px, py + 10, 3, panH - 20)
    -- Bordure fine
    surface.SetDrawColor(fr, fg, fb, 100)
    surface.DrawOutlinedRect(px, py, panW, panH, 1)

    -- Ligne titre faction
    surface.SetDrawColor(fr, fg, fb, 80)
    surface.DrawRect(px, py, panW, 30)
    draw.SimpleText(faction and faction.name or "?", "SWTOR_HUD_Medium",
        px + panW/2, py + 15,
        Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Classe et grade
    local className = cls and cls.name or "Aucune classe"
    local classIcon = cls and cls.icon or "?"
    draw.SimpleText(classIcon .. " " .. className, "SWTOR_HUD_Medium",
        px + 12, py + 40, cCol, TEXT_ALIGN_LEFT)
    draw.SimpleText("Grade " .. LocalData.grade .. " — " .. GetGradeName(),
        "SWTOR_HUD_Small", px + 12, py + 58, Color(180,180,180), TEXT_ALIGN_LEFT)

    -- Titre si présent
    if LocalData.title and LocalData.title ~= "" then
        draw.SimpleText("✦ " .. LocalData.title, "SWTOR_HUD_Small",
            px + 12, py + 74, Color(220, 180, 50), TEXT_ALIGN_LEFT)
    end

    -- ── HP Bar ────────────────────────────────────────────
    local by = py + 88
    local bw = panW - 24
    local bx2 = px + 12

    -- HP (rouge → vert selon ratio)
    local hpRatio = HPSmooth / math.max(maxhp, 1)
    local hpCol = Color(
        math.floor(220 * (1 - hpRatio)),
        math.floor(180 * hpRatio),
        40
    )
    DrawBar(bx2, by, bw, 14, hpRatio, hpCol, Color(0,0,0,140),
        "HP  " .. math.floor(HPSmooth) .. " / " .. maxhp)

    -- Armure
    DrawBar(bx2, by + 18, bw, 11, ArmorSmooth / 100,
        Color(60, 120, 220), Color(0,0,0,140),
        "Armure  " .. math.floor(ArmorSmooth) .. " / 100")

    -- ── 3 BARRES DE STATS ─────────────────────────────────
    local sBy = by + 34
    local sBw = (bw - 8) / 3

    -- FORCE (rouge/violet — dégâts mêlée + HP)
    local forceRatio = (LocalData.stat_force or 10) / 50
    DrawStatBar(bx2,          sBy, sBw, 24, LocalData.stat_force or 10, 50,
        Color(200, 40, 40, 200), "⚔")

    -- SPEED (cyan/vert — vitesse + cadence)
    DrawStatBar(bx2 + sBw + 4, sBy, sBw, 24, LocalData.stat_speed or 10, 50,
        Color(0, 200, 160, 200), "💨")

    -- ENERGIE (bleu/violet — sorts + réserve)
    DrawStatBar(bx2 + (sBw+4)*2, sBy, sBw, 24, LocalData.stat_energy or 10, 50,
        Color(80, 80, 220, 200), "✦")

    -- Points à distribuer
    if (LocalData.stat_points or 0) > 0 then
        local pulse = math.abs(math.sin(CurTime() * 3)) * 100 + 155
        draw.SimpleText("+" .. LocalData.stat_points .. " points à distribuer !",
            "SWTOR_HUD_Small", px + panW/2, sBy + 30,
            Color(220, 200, 50, pulse), TEXT_ALIGN_CENTER)
        draw.SimpleText("swtor_stats",
            "SWTOR_Small2", px + panW/2, sBy + 44,
            Color(150, 150, 150), TEXT_ALIGN_CENTER)
    end

    -- ── BARRE ÉNERGIE (Force/Sorts) ───────────────────────
    local eBy = sBy + (LocalData.stat_points > 0 and 62 or 42)
    local energyColor = LocalData.faction == "empire"      and Color(180, 40, 220)
                     or LocalData.faction == "republique"  and Color(50, 150, 255)
                     or LocalData.faction == "mandalorien" and Color(200, 150, 30)
                     or Color(100, 100, 200)
    DrawBar(bx2, eBy, bw, 13, EnergySmooth / math.max(MaxEnergy, 1),
        energyColor, Color(0,0,0,140),
        "Énergie  " .. math.floor(EnergySmooth) .. " / " .. MaxEnergy)

    -- XP
    local xpNeeded = (LocalData.grade or 1) * 1000
    local xpRatio  = ((LocalData.xp or 0) % xpNeeded) / xpNeeded
    DrawBar(bx2, eBy + 17, bw, 8, xpRatio,
        Color(140, 60, 220, 180), Color(0,0,0,100),
        "XP vers grade " .. (LocalData.grade + 1))

    -- ════════════════════════════════════════════════════════
    --  PANNEAU DROITE — Crédits, planète, stats combat
    -- ════════════════════════════════════════════════════════
    local rpW = 185
    local rpH = 90
    local rpx = sw - rpW - 15
    local rpy = sh - rpH - 15

    draw.RoundedBox(8, rpx+2, rpy+2, rpW, rpH, Color(0,0,0,70))
    draw.RoundedBox(8, rpx, rpy, rpW, rpH, Color(6,8,18,200))
    surface.SetDrawColor(fr, fg, fb, 80)
    surface.DrawOutlinedRect(rpx, rpy, rpW, rpH, 1)

    draw.SimpleText("💰 " .. LocalData.credits .. " cr",
        "SWTOR_HUD_Medium", rpx + 10, rpy + 14,
        Color(220, 180, 40), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("📍 " .. GetPlanetName(),
        "SWTOR_HUD_Small", rpx + 10, rpy + 34,
        Color(150, 200, 255), TEXT_ALIGN_LEFT)
    draw.SimpleText("⚔ " .. (LocalData.kills or 0) .. "  💀 " .. (LocalData.deaths or 0),
        "SWTOR_HUD_Small", rpx + 10, rpy + 52,
        Color(200, 200, 200), TEXT_ALIGN_LEFT)
    if (LocalData.duels_won or 0) + (LocalData.duels_lost or 0) > 0 then
        draw.SimpleText("Duels: " .. (LocalData.duels_won or 0) .. "W / " .. (LocalData.duels_lost or 0) .. "L",
            "SWTOR_Small2", rpx + 10, rpy + 68,
            Color(160, 160, 160), TEXT_ALIGN_LEFT)
    end

    -- ════════════════════════════════════════════════════════
    --  INDICATEUR PLANÈTE (centre haut)
    -- ════════════════════════════════════════════════════════
    local planet = SWTOR and SWTOR.Planets and SWTOR.Planets[LocalData.planet]
    if planet then
        local pCol  = planet.color or Color(100,100,100)
        local pName = planet.name
        local pw    = 220
        local ph    = 28
        local ppx   = sw/2 - pw/2
        local ppy   = 8

        draw.RoundedBox(6, ppx+1, ppy+1, pw, ph, Color(0,0,0,80))
        draw.RoundedBox(6, ppx, ppy, pw, ph, Color(8,10,22,200))
        surface.SetDrawColor(pCol.r, pCol.g, pCol.b, 150)
        surface.DrawOutlinedRect(ppx, ppy, pw, ph, 1)
        draw.SimpleText("📍 " .. pName, "SWTOR_HUD_Medium",
            sw/2, ppy + ph/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Zone PVP
        if planet.pvp_zones then
            for _, zone in ipairs(planet.pvp_zones) do
                if ply:GetPos():WithinAABox(zone.mins, zone.maxs) then
                    local pulse = math.abs(math.sin(CurTime() * 2.5)) * 120 + 135
                    draw.SimpleText("⚔ ZONE PVP — " .. zone.label,
                        "SWTOR_HUD_Medium",
                        sw/2, ppy + ph + 10,
                        Color(220, 50, 50, pulse), TEXT_ALIGN_CENTER)
                    break
                end
            end
        end
    end

    -- ════════════════════════════════════════════════════════
    --  NOTIFICATIONS (droite, remontent)
    -- ════════════════════════════════════════════════════════
    local now = CurTime()
    local nCount = 0
    for i = #Notifications, 1, -1 do
        local n = Notifications[i]
        if not n then continue end
        local age       = now - n.born
        local remaining = n.life - age
        if remaining <= 0 then
            table.remove(Notifications, i)
        else
            nCount = nCount + 1
            local alpha = math.Clamp(remaining * 80, 0, 220)
            local nx    = sw - 340
            local ny    = sh - 110 - (nCount * 32)

            draw.RoundedBox(6, nx, ny, 320, 26, Color(6,8,18,alpha*0.8))
            surface.SetDrawColor(n.color.r, n.color.g, n.color.b, alpha * 0.6)
            surface.DrawRect(nx, ny, 3, 26)
            draw.SimpleText(n.msg, "SWTOR_Notif",
                nx + 14, ny + 13,
                Color(n.color.r, n.color.g, n.color.b, alpha),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- ════════════════════════════════════════════════════════
    --  CROSSHAIR FACTION
    -- ════════════════════════════════════════════════════════
    local cx, cy = sw/2, sh/2
    local csz    = 6
    local cgap   = 4
    local ccol   = LocalData.faction == "empire"      and Color(220, 60, 60, 200)
                or LocalData.faction == "republique"  and Color(60, 130, 220, 200)
                or LocalData.faction == "mandalorien" and Color(200, 160, 30, 200)
                or Color(220, 220, 220, 180)

    surface.SetDrawColor(ccol)
    surface.DrawRect(cx - csz - cgap, cy - 1, csz, 2)
    surface.DrawRect(cx + cgap,        cy - 1, csz, 2)
    surface.DrawRect(cx - 1, cy - csz - cgap, 2, csz)
    surface.DrawRect(cx - 1, cy + cgap,        2, csz)
    surface.DrawRect(cx - 1, cy - 1, 2, 2)
end)

-- ============================================================
--  MASQUER HUD PAR DÉFAUT
-- ============================================================
hook.Add("HUDShouldDraw", "SWTOR_HideDefault", function(name)
    local hidden = {
        "CHudHealth", "CHudBattery", "CHudAmmo",
        "CHudSecondaryAmmo", "CHudCrosshair",
    }
    for _, v in ipairs(hidden) do
        if name == v then return false end
    end
end)

-- ============================================================
--  SCOREBOARD TAB
-- ============================================================
hook.Add("ScoreboardShow", "SWTOR_Scoreboard", function()
    if IsValid(SWTOR_ScoreboardPanel) then SWTOR_ScoreboardPanel:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 820, 520

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("SW:TOR RP — Tableau de la Galaxie")
    frame:SetDraggable(true)
    frame:MakePopup()
    SWTOR_ScoreboardPanel = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(10,0,0,w,h,Color(6,8,18,245))
        surface.SetDrawColor(100,80,40,160)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(6,6,6,6)

    -- Header
    local hdr = vgui.Create("DPanel", scroll)
    hdr:SetHeight(28)
    hdr:Dock(TOP)
    hdr.Paint = function(s,w,h)
        draw.RoundedBox(4,0,0,w,h,Color(20,22,45,220))
        local cols = {
            {0.02,"Joueur"},{0.22,"Faction"},{0.40,"Classe"},
            {0.56,"Grade"},{0.72,"Planète"},{0.85,"Crédits"},{0.93,"K/D"}
        }
        for _, c in ipairs(cols) do
            draw.SimpleText(c[2],"SWTOR_HUD_Small", w*c[1]+4, 14,
                Color(180,180,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local plys = player.GetAll()
    table.sort(plys, function(a,b)
        return (a.swtor_kills or 0) > (b.swtor_kills or 0)
    end)

    for _, p in ipairs(plys) do
        local row     = vgui.Create("DPanel", scroll)
        row:SetHeight(32)
        row:Dock(TOP)
        row:DockMargin(0,1,0,0)

        local faction   = SWTOR and SWTOR.Factions and SWTOR.Factions[p.swtor_faction or ""]
        local fCol      = faction and faction.color or Color(100,100,100)
        local cls       = SWTOR and SWTOR.Classes   and SWTOR.Classes[p.swtor_class or ""]
        local cIcon     = cls and cls.icon or "?"
        local cName     = cls and cls.name or "Aucune"
        local fName     = faction and faction.shortname or "?"
        local grades    = SWTOR and SWTOR.Grades and SWTOR.Grades[p.swtor_faction or ""]
        local gData     = grades and grades[p.swtor_grade or 1]
        local gName     = gData and gData.name or "?"
        local planet    = SWTOR and SWTOR.Planets and SWTOR.Planets[p.swtor_planet or ""]
        local pName     = planet and planet.name or "?"
        local isMe      = p == LocalPlayer()

        row.Paint = function(s,w,h)
            draw.RoundedBox(4,0,0,w,h,
                isMe and Color(30,40,70,200) or Color(12,14,28,180))
            -- Accent faction gauche
            draw.RoundedBox(0,0,0,3,h,fCol)

            -- Grade HRP au-dessus du nom dans le scoreboard
        local hrpRD = nil
        if _G.PlayerRanks then
            local hrpKey = _G.PlayerRanks[p:EntIndex()]
            if hrpKey and SWTOR and SWTOR.HRP and SWTOR.HRP.Ranks then
                hrpRD = SWTOR.HRP.Ranks[hrpKey]
            end
        end
                local data = {
                {0.02, p:Nick()},
                {0.22, fName},
                {0.40, cIcon .. " " .. cName:sub(1,16)},
                {0.56, gName:sub(1,18)},
                {0.72, pName},
                {0.85, (p.swtor_credits or 0) .. " cr"},
                {0.93, (p.swtor_kills or 0) .. "/" .. (p.swtor_deaths or 0)},
            }
            for _, d in ipairs(data) do
                draw.SimpleText(d[2], "SWTOR_Small2", w*d[1]+5, h/2,
                    Color(220,220,220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            -- Barres mini stats à droite
            local bx = w - 10
        end
    end

    return true
end)

hook.Add("ScoreboardHide", "SWTOR_HideSB", function()
    if IsValid(SWTOR_ScoreboardPanel) then SWTOR_ScoreboardPanel:Remove() end
end)

print("[SW:TOR] HUD v3 chargé ✓ (Force / Speed / Energie)")
