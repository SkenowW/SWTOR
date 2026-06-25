-- ============================================================
--  SW:TOR RP - MENU SÉLECTION DE FACTION (CLIENT)
--  Fichier: lua/autorun/client/cl_swtor_faction_menu.lua
--  Coller dans: garrysmod/lua/autorun/client/
-- ============================================================

if SERVER then return end

util.AddNetworkString = util.AddNetworkString or function() end  -- sécurité

-- ============================================================
--  OUVERTURE DU MENU DE FACTION
-- ============================================================

local function OpenFactionMenu()
    if IsValid(SWTOR_FactionMenu) then SWTOR_FactionMenu:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 800, 550

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw - W)/2, (sh - H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    SWTOR_FactionMenu = frame

    -- Fond
    frame.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, Color(8, 8, 20, 240))
        surface.SetDrawColor(100, 80, 40, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        -- Titre
        draw.SimpleText("CHOISISSEZ VOTRE VOIE", "SWTOR_HUD_Title",
            w/2, 40, Color(220, 180, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Star Wars: The Old Republic RP", "SWTOR_HUD_Medium",
            w/2, 70, Color(160, 160, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local factions = {
        {
            key   = "empire",
            name  = "Empire Sith",
            color = Color(200, 30, 30),
            desc  = "Dominez la galaxie par la Force Obscure.\nServez l'Empereur Sith sur Korriban\net Dromund Kaas.",
            emoji = "⚡",
        },
        {
            key   = "republique",
            name  = "République Galactique",
            color = Color(40, 120, 220),
            desc  = "Protégez la paix et la lumière.\nL'Ordre Jedi vous attend\nsur Coruscant.",
            emoji = "✦",
        },
        {
            key   = "mandalorien",
            name  = "Clan Mandalorien",
            color = Color(180, 140, 20),
            desc  = "Vivez par le code Resol'nare.\nGuerre, honneur, loyauté.\nMandalore vous appelle.",
            emoji = "🔱",
        },
    }

    local btnW = (W - 60) / #factions
    local btnH = 280
    local btnY = 100

    for i, factionData in ipairs(factions) do
        local bx = 20 + (i - 1) * (btnW + 10)

        local btn = vgui.Create("DButton", frame)
        btn:SetPos(bx, btnY)
        btn:SetSize(btnW, btnH)
        btn:SetText("")

        local hovered = false
        btn.OnCursorEntered = function() hovered = true  end
        btn.OnCursorExited  = function() hovered = false end

        btn.Paint = function(self, w, h)
            local fc = factionData.color
            local bg = hovered
                and Color(fc.r * 0.4, fc.g * 0.4, fc.b * 0.4, 230)
                or  Color(fc.r * 0.15, fc.g * 0.15, fc.b * 0.15, 200)

            draw.RoundedBox(10, 0, 0, w, h, bg)
            surface.SetDrawColor(fc.r, fc.g, fc.b, hovered and 255 or 150)
            surface.DrawOutlinedRect(0, 0, w, h, hovered and 2 or 1)

            -- Emoji / icône
            draw.SimpleText(factionData.emoji, "SWTOR_HUD_Title", w/2, 40,
                Color(fc.r, fc.g, fc.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Nom
            draw.SimpleText(factionData.name, "SWTOR_HUD_Big", w/2, 90,
                Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Description (multiline)
            local lines = string.Explode("\n", factionData.desc)
            for j, line in ipairs(lines) do
                draw.SimpleText(line, "SWTOR_HUD_Small", w/2, 125 + (j-1)*20,
                    Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Grades preview
            if SWTOR and SWTOR.Grades and SWTOR.Grades[factionData.key] then
                local grades = SWTOR.Grades[factionData.key]
                draw.SimpleText("Grades: " .. #grades, "SWTOR_HUD_Small", w/2, 210,
                    Color(fc.r, fc.g, fc.b, 200), TEXT_ALIGN_CENTER)
                -- Premiers grades
                for k = 1, math.min(3, #grades) do
                    draw.SimpleText("• " .. grades[k].name, "SWTOR_HUD_Small", w/2, 225 + (k-1)*18,
                        Color(180, 180, 180), TEXT_ALIGN_CENTER)
                end
                draw.SimpleText("... et plus", "SWTOR_HUD_Small", w/2, 280 - 20,
                    Color(120, 120, 120), TEXT_ALIGN_CENTER)
            end

            -- Bouton selection
            local btnBg = hovered
                and Color(fc.r, fc.g, fc.b, 220)
                or  Color(fc.r * 0.5, fc.g * 0.5, fc.b * 0.5, 180)
            draw.RoundedBox(6, 10, h - 44, w - 20, 34, btnBg)
            draw.SimpleText("REJOINDRE", "SWTOR_HUD_Big",
                w/2, h - 27, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local fKey = factionData.key
        btn.DoClick = function()
            surface.PlaySound("buttons/button14.wav")
            net.Start("SWTOR_SetFaction")
                net.WriteString(LocalPlayer():SteamID())
                net.WriteString(fKey)
            net.SendToServer()
            frame:Remove()
        end
    end

    -- Bas de page
    local note = vgui.Create("DLabel", frame)
    note:SetPos(0, H - 40)
    note:SetSize(W, 30)
    note:SetText("Ce choix peut être modifié par un administrateur. Votre progression sera sauvegardée.")
    note:SetFont("SWTOR_HUD_Small")
    note:SetContentAlignment(5)
    note:SetTextColor(Color(120, 120, 120))
end

-- ============================================================
--  MENU VOYAGE INTER-PLANÈTES
-- ============================================================

local function OpenTravelMenu()
    if not SWTOR or not SWTOR.Planets then return end
    if IsValid(SWTOR_TravelMenu) then SWTOR_TravelMenu:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 700, 480

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw - W)/2, (sh - H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("Navigation Inter-Planètes")
    frame:MakePopup()
    SWTOR_TravelMenu = frame

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(5, 10, 25, 245))
        surface.SetDrawColor(60, 80, 150, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 30, 10, 10)

    local localFaction = LocalPlayer().swtor_faction or ""

    for key, planet in pairs(SWTOR.Planets) do
        local isAccessible = (planet.faction == localFaction)
            or (planet.faction == "neutre")
            or (planet.type == "neutral")

        local pBtn = vgui.Create("DButton", scroll)
        pBtn:SetText("")
        pBtn:SetHeight(60)
        pBtn:Dock(TOP)
        pBtn:DockMargin(0, 2, 0, 0)

        local pKey = key
        local hov  = false
        pBtn.OnCursorEntered = function() hov = true  end
        pBtn.OnCursorExited  = function() hov = false end

        pBtn.Paint = function(self, w, h)
            local pc = planet.color or Color(100, 100, 100)
            local accessible = isAccessible
            local bg = accessible
                and (hov and Color(pc.r*0.4, pc.g*0.4, pc.b*0.4, 220)
                         or  Color(pc.r*0.2, pc.g*0.2, pc.b*0.2, 180))
                or Color(40, 40, 40, 150)

            draw.RoundedBox(6, 0, 0, w, h, bg)
            surface.SetDrawColor(pc.r, pc.g, pc.b, accessible and 180 or 60)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            draw.SimpleText(planet.name, "SWTOR_HUD_Big", 15, h/2 - 10,
                Color(255, 255, 255, accessible and 255 or 100),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            draw.SimpleText(planet.description:sub(1, 80) .. "...",
                "SWTOR_HUD_Small", 15, h/2 + 10,
                Color(180, 180, 180, accessible and 200 or 80),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Faction tag
            draw.SimpleText("[" .. string.upper(planet.faction) .. "]",
                "SWTOR_HUD_Small", w - 10, h/2,
                Color(pc.r, pc.g, pc.b, accessible and 255 or 80),
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            if not accessible then
                draw.SimpleText("🔒 Accès restreint", "SWTOR_HUD_Small", w/2, h/2,
                    Color(200, 80, 80, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        if isAccessible then
            pBtn.DoClick = function()
                net.Start("SWTOR_TeleportPlanet")
                    net.WriteString(pKey)
                net.SendToServer()
                frame:Remove()
            end
        end
    end
end

-- ============================================================
--  BINDS ET TOUCHES
-- ============================================================

-- F3 = Menu voyage
hook.Add("PlayerBindPress", "SWTOR_TravelBind", function(ply, bind, pressed)
    if pressed and bind == "toggle_duck" then  -- Remplacer par votre bind
        -- Désactivé par défaut, utiliser la commande ci-dessous
    end
end)

concommand.Add("swtor_travel", function()
    OpenTravelMenu()
end)

concommand.Add("swtor_faction_menu", function()
    OpenFactionMenu()
end)

-- Auto-ouvrir si pas de faction
hook.Add("InitPostEntity", "SWTOR_CheckFaction", function()
    timer.Simple(3, function()
        if not SWTOR then return end
        -- Vérifier via les données reçues du serveur
        if LocalData.faction == "" then
            OpenFactionMenu()
        end
    end)
end)

print("[SW:TOR RP] Menu Faction & Voyage chargés ✓")
print("  Commandes: swtor_travel | swtor_faction_menu")
