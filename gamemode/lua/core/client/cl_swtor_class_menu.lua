-- ============================================================
--  SW:TOR RP — MENU SÉLECTION DE CLASSE (CLIENT)
--  lua/autorun/client/cl_swtor_class_menu.lua
-- ============================================================

if SERVER then return end

util.AddNetworkString = util.AddNetworkString or function() end

-- Ouvrir automatiquement quand le serveur le demande
net.Receive("SWTOR_OpenClassMenu", function()
    timer.Simple(0.5, OpenClassMenu)
end)

function OpenClassMenu()
    if not SWTOR or not SWTOR.Classes then return end
    local faction = LocalPlayer():GetNWString("swtor_faction", "")
    if faction == "" then
        chat.AddText(Color(255,150,50), "[SW:TOR] Choisissez une faction d'abord.")
        return
    end

    -- Collecter les classes de la faction
    local classes = {}
    for key, cls in pairs(SWTOR.Classes) do
        if cls.faction == faction then
            table.insert(classes, { key = key, data = cls })
        end
    end
    table.sort(classes, function(a,b) return a.data.name < b.data.name end)

    if #classes == 0 then return end

    if IsValid(SWTOR_ClassMenu) then SWTOR_ClassMenu:Remove() end

    local sw, sh   = ScrW(), ScrH()
    local cols     = math.min(#classes, 2)
    local rows     = math.ceil(#classes / cols)
    local cardW    = 280
    local cardH    = 320
    local gap      = 16
    local padX     = 30
    local padY     = 80
    local W        = cols * cardW + (cols-1) * gap + padX*2
    local H        = rows * cardH + (rows-1) * gap + padY + 60

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw-W)/2, (sh-H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    SWTOR_ClassMenu = frame

    local fData  = SWTOR.Factions[faction]
    local fColor = fData and fData.color or Color(150,150,150)

    frame.Paint = function(s,w,h)
        -- Fond dégradé sombre
        draw.RoundedBox(12, 0, 0, w, h, Color(5,7,16,252))
        -- Bande de titre
        draw.RoundedBox(0, 0, 0, w, 70, Color(fColor.r*0.2, fColor.g*0.2, fColor.b*0.2, 240))
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 180)
        surface.DrawRect(0, 68, w, 2)
        -- Titre
        draw.SimpleText("CHOISISSEZ VOTRE CLASSE", "SWTOR_HUD_Title",
            w/2, 35, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(fData and fData.name or "", "SWTOR_HUD_Medium",
            w/2, 58, Color(fColor.r, fColor.g, fColor.b, 220),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Bordure
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 120)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    -- Créer les cartes de classe
    for i, cls in ipairs(classes) do
        local col  = ((i-1) % cols)
        local row  = math.floor((i-1) / cols)
        local cx   = padX + col * (cardW + gap)
        local cy   = padY + row * (cardH + gap)

        local card = vgui.Create("DButton", frame)
        card:SetPos(cx, cy)
        card:SetSize(cardW, cardH)
        card:SetText("")

        local hov      = false
        local clsData  = cls.data
        local clsKey   = cls.key
        local cColor   = clsData.color or fColor

        card.OnCursorEntered = function() hov = true  end
        card.OnCursorExited  = function() hov = false end

        card.Paint = function(s,w,h)
            -- Fond carte
            local bgAlpha = hov and 210 or 180
            draw.RoundedBox(10, 0, 0, w, h,
                Color(cColor.r*0.12, cColor.g*0.12, cColor.b*0.12, bgAlpha))
            -- Bordure (épaisse si hover)
            local bord = hov and 2 or 1
            surface.SetDrawColor(cColor.r, cColor.g, cColor.b, hov and 255 or 120)
            surface.DrawOutlinedRect(0, 0, w, h, bord)
            -- Accent haut
            surface.SetDrawColor(cColor.r, cColor.g, cColor.b, hov and 200 or 80)
            surface.DrawRect(0, 0, w, 3)

            -- Icône grande
            draw.SimpleText(clsData.icon or "?", "SWTOR_HUD_Title",
                w/2, 38, Color(cColor.r, cColor.g, cColor.b, 255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Nom classe
            draw.SimpleText(clsData.name, "SWTOR_HUD_Big",
                w/2, 72, Color(255,255,255), TEXT_ALIGN_CENTER)

            -- Description
            local words = string.Explode(" ", clsData.description or "")
            local line  = ""
            local lines = {}
            for _, word in ipairs(words) do
                local test = line == "" and word or line .. " " .. word
                if #test > 32 then
                    table.insert(lines, line)
                    line = word
                else
                    line = test
                end
            end
            if line ~= "" then table.insert(lines, line) end
            for j, l in ipairs(lines) do
                draw.SimpleText(l, "SWTOR_Small2",
                    w/2, 92 + (j-1)*16,
                    Color(180,180,180), TEXT_ALIGN_CENTER)
            end

            -- Séparateur
            local sepY = 165
            surface.SetDrawColor(cColor.r, cColor.g, cColor.b, 60)
            surface.DrawRect(12, sepY, w-24, 1)

            -- Stats visuelles (3 barres)
            local stats = clsData.stats
            if stats then
                local statDefs = {
                    { label="⚔ Force",  val=stats.hp,          maxV=300, col=Color(220,60,60)   },
                    { label="💨 Speed",  val=stats.speed,       maxV=260, col=Color(0,200,160)   },
                    { label="✦ Énergie",val=stats.force_max,   maxV=200, col=Color(80,100,220)   },
                }
                for k, st in ipairs(statDefs) do
                    local sy    = sepY + 12 + (k-1)*26
                    local ratio = math.Clamp(st.val / st.maxV, 0, 1)
                    local bw    = w - 24
                    -- Fond barre
                    draw.RoundedBox(4, 12, sy, bw, 12, Color(0,0,0,150))
                    -- Remplissage
                    if ratio > 0 then
                        draw.RoundedBox(4, 12, sy, math.max(12, bw*ratio), 12,
                            Color(st.col.r, st.col.g, st.col.b, 200))
                    end
                    draw.SimpleText(st.label, "SWTOR_Small2",
                        14, sy+6, Color(220,220,220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(math.floor(st.val), "SWTOR_Small2",
                        w-14, sy+6, Color(220,220,220), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end

            -- Playstyle
            local psY = sepY + 94
            surface.SetDrawColor(cColor.r, cColor.g, cColor.b, 40)
            surface.DrawRect(12, psY, w-24, 1)
            draw.SimpleText(clsData.playstyle or "", "SWTOR_Small2",
                w/2, psY + 10, Color(150,180,150), TEXT_ALIGN_CENTER)

            -- Abilities preview (premiers débloqués)
            local abY = psY + 26
            if clsData.abilities then
                local shown = 0
                for grade, ab in pairs(clsData.abilities) do
                    if shown >= 4 then break end
                    draw.SimpleText(ab.icon .. " " .. ab.name,
                        "SWTOR_Small2", 14, abY + shown*15,
                        Color(180,180,200), TEXT_ALIGN_LEFT)
                    shown = shown + 1
                end
            end

            -- Bouton sélectionner
            local btnY = h - 44
            draw.RoundedBox(6, 10, btnY, w-20, 34,
                hov and Color(cColor.r, cColor.g, cColor.b, 220)
                     or Color(cColor.r*0.5, cColor.g*0.5, cColor.b*0.5, 160))
            draw.SimpleText("CHOISIR CETTE CLASSE", "SWTOR_HUD_Medium",
                w/2, btnY+17, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        card.DoClick = function()
            surface.PlaySound("buttons/button15.wav")
            net.Start("SWTOR_SetClass")
                net.WriteString(clsKey)
            net.SendToServer()
            frame:Remove()
            -- Afficher confirmation
            chat.AddText(Color(80,220,80), "[SW:TOR] Classe choisie: " .. clsData.name)
            chat.AddText(Color(150,150,200), clsData.playstyle or "")
        end
    end

    -- Bas : note
    local noteY = H - 28
    local noteLbl = vgui.Create("DLabel", frame)
    noteLbl:SetPos(0, noteY - padY)
    noteLbl:SetSize(W, 20)
    noteLbl:SetText("Ce choix est permanent jusqu'à réinitialisation par un administrateur.")
    noteLbl:SetFont("SWTOR_Small2")
    noteLbl:SetContentAlignment(5)
    noteLbl:SetTextColor(Color(100,100,100))
end

concommand.Add("swtor_class_menu", OpenClassMenu)

print("[SW:TOR] Menu classe chargé ✓")
