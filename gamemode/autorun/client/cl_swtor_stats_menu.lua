-- ============================================================
--  SW:TOR RP — MENU STATS (Force / Speed / Energie)
--  lua/autorun/client/cl_swtor_stats_menu.lua
-- ============================================================

if SERVER then return end

local function OpenStatsMenu()
    if LocalData.faction == "" then
        chat.AddText(Color(255,150,50), "[SW:TOR] Rejoignez une faction d'abord.")
        return
    end

    if IsValid(SWTOR_StatsMenu) then SWTOR_StatsMenu:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 480, 520

    local fData  = SWTOR and SWTOR.Factions and SWTOR.Factions[LocalData.faction]
    local fColor = fData and fData.color or Color(150,150,150)
    local cls    = SWTOR and SWTOR.Classes and SWTOR.Classes[LocalData.class]

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:MakePopup()
    SWTOR_StatsMenu = frame

    frame.Paint = function(s,w,h)
        draw.RoundedBox(10, 0, 0, w, h, Color(5,7,16,250))
        draw.RoundedBox(0,  0, 0, w, 60, Color(fColor.r*0.2, fColor.g*0.2, fColor.b*0.2, 240))
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 180)
        surface.DrawRect(0, 58, w, 2)
        draw.SimpleText("STATISTIQUES", "SWTOR_HUD_Title",
            w/2, 30, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 100)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    -- ── Infos joueur ───────────────────────────────────────
    local infoPanel = vgui.Create("DPanel", frame)
    infoPanel:SetPos(20, 68)
    infoPanel:SetSize(W-40, 55)
    infoPanel.Paint = function(s,w,h)
        draw.RoundedBox(6, 0, 0, w, h, Color(15,18,35,200))
        local ply     = LocalPlayer()
        local grades  = SWTOR and SWTOR.Grades and SWTOR.Grades[LocalData.faction]
        local gData   = grades and grades[LocalData.grade]
        local gName   = gData and gData.name or "N/A"
        draw.SimpleText((cls and cls.icon or "?") .. " " .. (cls and cls.name or "Aucune classe"),
            "SWTOR_HUD_Big", 12, 14, cls and cls.color or Color(200,200,200),
            TEXT_ALIGN_LEFT)
        draw.SimpleText("Grade " .. LocalData.grade .. " — " .. gName,
            "SWTOR_HUD_Small", 12, 34, Color(160,160,160), TEXT_ALIGN_LEFT)
        -- Points dispo (coin droit)
        local pts = LocalData.stat_points or 0
        local ptCol = pts > 0 and Color(220,200,50) or Color(100,100,100)
        draw.SimpleText(pts .. " point" .. (pts > 1 and "s" or "") .. " disponible" .. (pts > 1 and "s" or ""),
            "SWTOR_HUD_Medium", w-12, 26, ptCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- ── Les 3 stats ────────────────────────────────────────
    local statDefs = {
        {
            key   = "force",
            label = "FORCE",
            icon  = "⚔",
            color = Color(220, 60, 60),
            desc  = "Augmente les dégâts de mêlée, les HP maximum\net la puissance des sorts offensifs.",
            effects = {
                "+1.5 dmg mêlée par point",
                "+1.5 HP max par point",
                "Sorts Sith plus puissants",
            },
        },
        {
            key   = "speed",
            label = "RAPIDITÉ",
            icon  = "💨",
            color = Color(0, 200, 160),
            desc  = "Augmente la vitesse de déplacement, la cadence\nde tir et la précision au blaster.",
            effects = {
                "+0.8 vitesse de course",
                "-0.003s cooldown tir blaster",
                "Réduit le spread blaster",
            },
        },
        {
            key   = "energy",
            label = "ÉNERGIE",
            icon  = "✦",
            color = Color(80, 100, 220),
            desc  = "Augmente la réserve d'énergie pour les sorts,\nla régénération et les soins reçus.",
            effects = {
                "+2 énergie max par point",
                "+regen énergie hors combat",
                "Soins et sorts non-offensifs +",
            },
        },
    }

    for i, stat in ipairs(statDefs) do
        local sy  = 132 + (i-1) * 116
        local spn = vgui.Create("DPanel", frame)
        spn:SetPos(20, sy)
        spn:SetSize(W-40, 108)

        local statKey = stat.key
        local sc      = stat.color

        spn.Paint = function(s,w,h)
            draw.RoundedBox(8, 0, 0, w, h, Color(10,12,26,210))
            surface.SetDrawColor(sc.r, sc.g, sc.b, 80)
            surface.DrawOutlinedRect(0,0,w,h,1)
            -- Bande gauche
            surface.SetDrawColor(sc.r, sc.g, sc.b, 200)
            surface.DrawRect(0, 8, 3, h-16)

            -- Header
            draw.SimpleText(stat.icon .. "  " .. stat.label, "SWTOR_HUD_Big",
                14, 14, sc, TEXT_ALIGN_LEFT)

            -- Valeur actuelle / max
            local curVal = LocalData["stat_" .. statKey] or 10
            draw.SimpleText(curVal .. " / 50", "SWTOR_HUD_Big",
                w - 14, 14, Color(255,255,255), TEXT_ALIGN_RIGHT)

            -- Barre de progression
            local ratio = curVal / 50
            draw.RoundedBox(4, 14, 36, w-28, 10, Color(0,0,0,150))
            if ratio > 0 then
                draw.RoundedBox(4, 14, 36, math.max(8,(w-28)*ratio), 10,
                    Color(sc.r, sc.g, sc.b, 220))
            end

            -- Description
            local lines = string.Explode("\n", stat.desc)
            for j, l in ipairs(lines) do
                draw.SimpleText(l, "SWTOR_Small2", 14, 52+(j-1)*14,
                    Color(160,160,160), TEXT_ALIGN_LEFT)
            end

            -- Effets
            for j, e in ipairs(stat.effects) do
                draw.SimpleText("▸ " .. e, "SWTOR_Small2",
                    w*0.5+4, 52+(j-1)*14,
                    Color(sc.r*0.85, sc.g*0.85, sc.b*0.85, 200),
                    TEXT_ALIGN_LEFT)
            end
        end

        -- Bouton +1
        local addBtn = vgui.Create("DButton", spn)
        addBtn:SetPos(W-40-60, 56)
        addBtn:SetSize(56, 30)
        addBtn:SetText("")

        local sk = statKey
        addBtn.Paint = function(s,w,h)
            local pts  = LocalData.stat_points or 0
            local cur  = LocalData["stat_" .. sk] or 10
            local canAdd = pts > 0 and cur < 50
            draw.RoundedBox(5, 0, 0, w, h,
                canAdd and Color(sc.r*0.5, sc.g*0.5, sc.b*0.5, 220)
                        or Color(30,30,30,180))
            draw.SimpleText(canAdd and "+ 1" or "MAX", "SWTOR_HUD_Medium",
                w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        addBtn.DoClick = function()
            local pts = LocalData.stat_points or 0
            local cur = LocalData["stat_" .. sk] or 10
            if pts <= 0 then
                chat.AddText(Color(220,100,50), "[SW:TOR] Aucun point disponible.")
                return
            end
            if cur >= 50 then
                chat.AddText(Color(220,100,50), "[SW:TOR] Stat au maximum.")
                return
            end
            net.Start("SWTOR_SpendStat")
                net.WriteString(sk)
            net.SendToServer()
            surface.PlaySound("buttons/button15.wav")
            -- Update local immédiat (sera confirmé par SyncData)
            LocalData["stat_" .. sk] = cur + 1
            LocalData.stat_points    = pts - 1
        end
    end

    -- ── Bouton fermer ──────────────────────────────────────
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(20, H-48)
    closeBtn:SetSize(W-40, 36)
    closeBtn:SetText("")
    closeBtn.Paint = function(s,w,h)
        draw.RoundedBox(6,0,0,w,h,Color(30,30,50,200))
        draw.SimpleText("FERMER", "SWTOR_HUD_Medium",
            w/2, h/2, Color(180,180,180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function() frame:Remove() end
end

concommand.Add("swtor_stats",   OpenStatsMenu)
concommand.Add("swtor_profil",  OpenStatsMenu)

print("[SW:TOR] Menu stats chargé ✓ — commande: swtor_stats")
