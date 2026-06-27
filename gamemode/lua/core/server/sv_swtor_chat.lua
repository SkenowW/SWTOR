-- ============================================================
--  SW:TOR RP — CHAT RP FORMATÉ
--  lua/autorun/server/sv_swtor_chat.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_RPChat")

-- ============================================================
--  HOOK CHAT PRINCIPAL
-- ============================================================
hook.Add("PlayerSay", "SWTOR_FormatChat", function(ply, text, team)
    local ltext = text

    -- ── /me action ────────────────────────────────────────
    if string.sub(ltext,1,4) == "/me " then
        local action  = string.sub(ltext, 5)
        local faction = SWTOR.Factions[ply.swtor_faction or ""]
        local fName   = faction and faction.shortname or "?"
        local gradeInfo = SWTOR.GetGrade(ply.swtor_faction or "", ply.swtor_grade or 1)
        local gName   = gradeInfo and gradeInfo.name or "?"

        net.Start("SWTOR_RPChat")
            net.WriteUInt(1, 4)  -- type 1 = /me
            net.WriteString(ply:Nick())
            net.WriteString(fName)
            net.WriteString(gName)
            net.WriteString(action)
        -- Portée limitée
        local receivers = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():Distance(ply:GetPos()) <= SWTOR.Config.RPChatRange then
                table.insert(receivers, p)
            end
        end
        net.Send(receivers)
        return ""
    end

    -- ── /rp texte RP ──────────────────────────────────────
    if string.sub(ltext,1,4) == "/rp " then
        local msg     = string.sub(ltext, 5)
        local faction = SWTOR.Factions[ply.swtor_faction or ""]
        local fName   = faction and faction.shortname or "?"
        local gradeInfo = SWTOR.GetGrade(ply.swtor_faction or "", ply.swtor_grade or 1)
        local gName   = gradeInfo and gradeInfo.name or "?"

        net.Start("SWTOR_RPChat")
            net.WriteUInt(2, 4)
            net.WriteString(ply:Nick())
            net.WriteString(fName)
            net.WriteString(gName)
            net.WriteString(msg)
        local receivers = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():Distance(ply:GetPos()) <= SWTOR.Config.RPChatRange then
                table.insert(receivers, p)
            end
        end
        net.Send(receivers)
        return ""
    end

    -- ── // OOC hors-RP ────────────────────────────────────
    if string.sub(ltext,1,3) == "// " then
        local msg = string.sub(ltext, 4)
        net.Start("SWTOR_RPChat")
            net.WriteUInt(3, 4)  -- type 3 = OOC
            net.WriteString(ply:Nick())
            net.WriteString("")
            net.WriteString("")
            net.WriteString(msg)
        net.Broadcast()
        return ""
    end

    -- ── Chat normal (formaté avec grade + faction) ────────
    local faction   = SWTOR.Factions[ply.swtor_faction or ""]
    local fColor    = faction and faction.color or Color(200,200,200)
    local gradeInfo = SWTOR.GetGrade(ply.swtor_faction or "", ply.swtor_grade or 1)
    local gName     = gradeInfo and gradeInfo.name or ""
    local title     = ply.swtor_title and ("[" .. ply.swtor_title .. "] ") or ""

    net.Start("SWTOR_RPChat")
        net.WriteUInt(0, 4)  -- type 0 = chat normal
        net.WriteString(ply:Nick())
        net.WriteString(faction and faction.shortname or "")
        net.WriteString(title .. gName)
        net.WriteString(text)
    net.Broadcast()
    return ""  -- Empêche le chat par défaut
end)

-- ============================================================
--  COMMANDES CHAT SPÉCIALES
-- ============================================================
hook.Add("PlayerSay", "SWTOR_ChatSpecial", function(ply, text)
    local ltext = string.lower(text)

    -- /annoncer (admin seulement)
    if string.sub(ltext,1,10) == "/annoncer " and SWTOR.IsAdmin(ply) then
        local msg = string.sub(text, 11)
        net.Start("SWTOR_RPChat")
            net.WriteUInt(4, 4)  -- type 4 = annonce
            net.WriteString("Administration")
            net.WriteString("SWTOR")
            net.WriteString("")
            net.WriteString(msg)
        net.Broadcast()
        return ""
    end

    -- /event (admin)
    if string.sub(ltext,1,7) == "/event " and SWTOR.IsAdmin(ply) then
        local msg = string.sub(text, 8)
        net.Start("SWTOR_RPChat")
            net.WriteUInt(5, 4)  -- type 5 = event
            net.WriteString("Événement Galactique")
            net.WriteString("EVENT")
            net.WriteString("")
            net.WriteString(msg)
        net.Broadcast()
        return ""
    end

    -- /do (description de la scène, local)
    if string.sub(ltext,1,4) == "/do " then
        local msg = string.sub(text, 5)
        net.Start("SWTOR_RPChat")
            net.WriteUInt(6, 4)  -- type 6 = /do
            net.WriteString(ply:Nick())
            net.WriteString("")
            net.WriteString("")
            net.WriteString(msg)
        local receivers = {}
        for _, p in ipairs(player.GetAll()) do
            if p:GetPos():Distance(ply:GetPos()) <= SWTOR.Config.RPChatRange then
                table.insert(receivers, p)
            end
        end
        net.Send(receivers)
        return ""
    end
end)

print("[SW:TOR] Système de chat RP chargé ✓")
