-- ============================================================
--  SW:TOR RP - VESTIAIRE / SÉLECTEUR DE TENUE
--  Fichier: lua/autorun/client/cl_swtor_wardrobe.lua
--  Coller dans: garrysmod/lua/autorun/client/
--  Commande: swtor_wardrobe  (ou bind une touche)
-- ============================================================

if SERVER then return end

util.AddNetworkString = util.AddNetworkString or function() end

local function OpenWardrobe()
    if not SWTOR or not SWTOR.Outfits then
        chat.AddText(Color(255,100,100), "[SW:TOR] Données workshop non chargées.")
        return
    end

    local localFaction = LocalData and LocalData.faction or ""
    if localFaction == "" then
        chat.AddText(Color(255,150,50), "[SW:TOR] Vous devez choisir une faction d'abord.")
        return
    end

    local outfits = SWTOR.Outfits[localFaction]
    if not outfits then
        chat.AddText(Color(255,150,50), "[SW:TOR] Aucune tenue pour cette faction.")
        return
    end

    if IsValid(SWTOR_Wardrobe) then SWTOR_Wardrobe:Remove() end

    local sw, sh = ScrW(), ScrH()
    local W, H   = 500, 560

    local frame = vgui.Create("DFrame")
    frame:SetPos((sw - W)/2, (sh - H)/2)
    frame:SetSize(W, H)
    frame:SetTitle("Vestiaire — " .. (SWTOR.Factions[localFaction] and SWTOR.Factions[localFaction].name or ""))
    frame:MakePopup()
    SWTOR_Wardrobe = frame

    local fColor = SWTOR.Factions[localFaction] and SWTOR.Factions[localFaction].color or Color(150,150,150)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(8, 10, 22, 245))
        surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 160)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 30, 8, 8)

    for _, outfit in ipairs(outfits) do
        local row = vgui.Create("DButton", scroll)
        row:SetText("")
        row:SetHeight(46)
        row:Dock(TOP)
        row:DockMargin(0, 2, 0, 0)

        local hov = false
        row.OnCursorEntered = function() hov = true  end
        row.OnCursorExited  = function() hov = false end

        local outfitRef = outfit
        row.Paint = function(self, w, h)
            local bg = hov
                and Color(fColor.r * 0.35, fColor.g * 0.35, fColor.b * 0.35, 220)
                or  Color(15, 18, 35, 200)
            draw.RoundedBox(5, 0, 0, w, h, bg)
            if hov then
                surface.SetDrawColor(fColor.r, fColor.g, fColor.b, 180)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            draw.SimpleText(outfitRef.label, "SWTOR_HUD_Medium", 12, h/2,
                Color(230, 230, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            draw.SimpleText("Workshop: " .. outfitRef.wid, "SWTOR_HUD_Small", w - 10, h/2,
                Color(100, 100, 140), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        row.DoClick = function()
            -- Envoyer au serveur pour appliquer le modèle
            net.Start("SWTOR_SetModel")
                net.WriteString(outfitRef.model)
            net.SendToServer()
            surface.PlaySound("buttons/button15.wav")
            chat.AddText(fColor, "[SW:TOR] ", Color(255,255,255), "Tenue appliquée: " .. outfitRef.label)
            frame:Remove()
        end
    end
end

concommand.Add("swtor_wardrobe", OpenWardrobe)

-- Réception confirmation serveur
net.Receive("SWTOR_ModelApplied", function()
    local mdl = net.ReadString()
    chat.AddText(Color(80,200,80), "[SW:TOR] ✓ Modèle appliqué: " .. mdl)
end)

print("[SW:TOR RP] Vestiaire chargé ✓ — commande: swtor_wardrobe")
