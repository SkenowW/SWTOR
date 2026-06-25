-- ============================================================
--  SW:TOR RP — ADMIN PANEL SERVEUR (réception net panel F4)
--  lua/autorun/server/sv_swtor_adminnet.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_AdminAction")
util.AddNetworkString("SWTOR_AdminGetPlayers")
util.AddNetworkString("SWTOR_AdminPlayersData")

-- ── Envoyer la liste des joueurs au demandeur ──────────────
net.Receive("SWTOR_AdminGetPlayers", function(len, ply)
    if not ply:IsAdmin() then return end

    local list = {}
    for _, p in ipairs(player.GetAll()) do
        table.insert(list, {
            name      = p:Nick(),
            steamid   = p:SteamID(),
            faction   = p.swtor_faction  or "",
            class     = p.swtor_class    or "",
            grade     = p.swtor_grade    or 1,
            credits   = p.swtor_credits  or 0,
            planet    = p.swtor_planet   or "",
            kills     = p.swtor_kills    or 0,
            deaths    = p.swtor_deaths   or 0,
            stat_f    = p.swtor_stat_force  or 10,
            stat_s    = p.swtor_stat_speed  or 10,
            stat_e    = p.swtor_stat_energy or 10,
        })
    end

    net.Start("SWTOR_AdminPlayersData")
        net.WriteString(util.TableToJSON(list))
    net.Send(ply)
end)

-- ── Réception des actions du panel ────────────────────────
net.Receive("SWTOR_AdminAction", function(len, ply)
    if not ply:IsAdmin() then
        SWTOR.Notify(ply, "Permission refusée.", "error")
        return
    end

    local action   = net.ReadString()
    local steamid  = net.ReadString()
    local value    = net.ReadString()

    -- Trouver le joueur cible
    local target = nil
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID() == steamid then
            target = p
            break
        end
    end

    if not IsValid(target) then
        SWTOR.Notify(ply, "Joueur introuvable (déconnecté?).", "error")
        return
    end

    local log = "[ADMIN] " .. ply:Nick() .. " → " .. action .. " sur " .. target:Nick()

    if action == "setfaction" then
        local ok, err = SWTOR.SetFaction(target, value)
        SWTOR.Notify(ply, ok and "Faction assignée: " .. value or err, ok and "success" or "error")

    elseif action == "promote" then
        local ok, err = SWTOR.PromotePlayer(target, ply)
        SWTOR.Notify(ply, ok and target:Nick() .. " promu !" or tostring(err),
            ok and "success" or "error")

    elseif action == "demote" then
        SWTOR.DemotePlayer(target, ply)
        SWTOR.Notify(ply, target:Nick() .. " rétrogradé.", "warning")

    elseif action == "setgrade" then
        local g = tonumber(value)
        if g then
            local ok, err = SWTOR.SetGrade(target, g, ply)
            SWTOR.Notify(ply, ok and "Grade " .. g .. " assigné" or tostring(err),
                ok and "success" or "error")
        end

    elseif action == "givecredits" then
        local amount = tonumber(value) or 0
        SWTOR.GiveCredits(target, amount)
        SWTOR.Notify(ply, "+" .. amount .. " cr donnés à " .. target:Nick(), "success")

    elseif action == "teleport" then
        local ok, err = SWTOR.TeleportToPlanet(target, value)
        SWTOR.Notify(ply, ok and target:Nick() .. " téléporté sur " .. value or tostring(err),
            ok and "success" or "error")

    elseif action == "kill" then
        target:Kill()
        SWTOR.Notify(ply, target:Nick() .. " tué par admin.", "warning")

    elseif action == "reset" then
        target.swtor_faction     = ""
        target.swtor_class       = ""
        target.swtor_grade       = 1
        target.swtor_xp          = 0
        target.swtor_credits     = 500
        target.swtor_kills       = 0
        target.swtor_deaths      = 0
        target.swtor_stat_force  = 10
        target.swtor_stat_speed  = 10
        target.swtor_stat_energy = 10
        target.swtor_stat_points = 0
        SWTOR.SavePlayer(target)
        SWTOR.SyncPlayerData(target)
        SWTOR.Notify(target, "Votre profil a été réinitialisé par un admin.", "warning")
        SWTOR.Notify(ply, target:Nick() .. " réinitialisé.", "success")

    elseif action == "notify" then
        local msg = value ~= "" and value or "Message de l'administration."
        SWTOR.Notify(target, msg, "info")
        SWTOR.Notify(ply, "Notification envoyée.", "success")
    end

    print(log .. " (" .. (value or "") .. ")")
end)

print("[SW:TOR] Admin net serveur chargé ✓")
