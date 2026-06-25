-- ============================================================
--  SW:TOR RP — CANDIDATURES FACTION
--  lua/autorun/server/sv_swtor_applications.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_ApplyFaction")
util.AddNetworkString("SWTOR_ApplicationResult")
util.AddNetworkString("SWTOR_AdminReviewApp")
util.AddNetworkString("SWTOR_ApplicationsList")

SWTOR.Applications = SWTOR.Applications or {}

-- ============================================================
--  DÉPÔT DE CANDIDATURE
-- ============================================================
net.Receive("SWTOR_ApplyFaction", function(len, ply)
    local factionKey = net.ReadString()
    local motivation = net.ReadString()

    -- Vérifications
    if not SWTOR.Factions[factionKey] then
        net.Start("SWTOR_ApplicationResult")
            net.WriteString("error")
            net.WriteString("Faction inconnue.")
        net.Send(ply)
        return
    end

    if SWTOR.Config.AllowSelfJoin then
        -- Rejoindre directement
        SWTOR.SetFaction(ply, factionKey)
        net.Start("SWTOR_ApplicationResult")
            net.WriteString("success")
            net.WriteString("Vous avez rejoint " .. SWTOR.Factions[factionKey].name .. " !")
        net.Send(ply)
        return
    end

    -- Déjà en attente ?
    for _, app in ipairs(SWTOR.Applications) do
        if app.steamid == ply:SteamID() and app.status == "pending" then
            net.Start("SWTOR_ApplicationResult")
                net.WriteString("error")
                net.WriteString("Vous avez déjà une candidature en attente.")
            net.Send(ply)
            return
        end
    end

    local app = {
        steamid    = ply:SteamID(),
        name       = ply:Nick(),
        faction    = factionKey,
        motivation = motivation,
        status     = "pending",
        time       = os.time(),
    }
    table.insert(SWTOR.Applications, app)

    net.Start("SWTOR_ApplicationResult")
        net.WriteString("pending")
        net.WriteString("Candidature envoyée aux administrateurs. En attente d'approbation.")
    net.Send(ply)

    -- Notifier les admins
    for _, p in ipairs(player.GetAll()) do
        if p:IsAdmin() then
            p:ChatPrint("[SWTOR] 📋 Nouvelle candidature: " .. ply:Nick() ..
                        " → " .. SWTOR.Factions[factionKey].name)
            p:ChatPrint("  Motivation: " .. motivation)
            p:ChatPrint("  Commande: swtor_approve " .. ply:SteamID() ..
                        " | swtor_reject " .. ply:SteamID())
        end
    end
end)

-- ============================================================
--  APPROBATION / REFUS ADMIN
-- ============================================================
concommand.Add("swtor_approve", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local sid = args[1]
    if not sid then return end

    for i, app in ipairs(SWTOR.Applications) do
        if app.steamid == sid and app.status == "pending" then
            app.status = "approved"
            -- Trouver le joueur connecté
            for _, p in ipairs(player.GetAll()) do
                if p:SteamID() == sid then
                    SWTOR.SetFaction(p, app.faction)
                    net.Start("SWTOR_ApplicationResult")
                        net.WriteString("success")
                        net.WriteString("🎉 Candidature approuvée ! Bienvenue dans " ..
                            SWTOR.Factions[app.faction].name .. " !")
                    net.Send(p)
                    break
                end
            end
            if IsValid(ply) then
                ply:ChatPrint("[SWTOR] Candidature de " .. app.name .. " approuvée.")
            end
            return
        end
    end
    if IsValid(ply) then ply:ChatPrint("[SWTOR] Candidature introuvable.") end
end)

concommand.Add("swtor_reject", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local sid    = args[1]
    local reason = table.concat(args, " ", 2) or "Aucune raison fournie."
    if not sid then return end

    for i, app in ipairs(SWTOR.Applications) do
        if app.steamid == sid and app.status == "pending" then
            app.status = "rejected"
            for _, p in ipairs(player.GetAll()) do
                if p:SteamID() == sid then
                    net.Start("SWTOR_ApplicationResult")
                        net.WriteString("rejected")
                        net.WriteString("Candidature refusée: " .. reason)
                    net.Send(p)
                    SWTOR.Notify(p, "Candidature refusée: " .. reason, "error")
                    break
                end
            end
            if IsValid(ply) then
                ply:ChatPrint("[SWTOR] Candidature de " .. app.name .. " refusée.")
            end
            return
        end
    end
end)

concommand.Add("swtor_applications", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("=== SW:TOR — Candidatures en attente ===")
    local count = 0
    for _, app in ipairs(SWTOR.Applications) do
        if app.status == "pending" then
            count = count + 1
            printFn(string.format("  [%s] %s → %s | %s",
                app.steamid, app.name,
                SWTOR.Factions[app.faction] and SWTOR.Factions[app.faction].name or "?",
                app.motivation))
        end
    end
    if count == 0 then printFn("  Aucune candidature en attente.") end
end)

print("[SW:TOR] Candidatures chargées ✓")
