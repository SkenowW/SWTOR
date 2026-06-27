-- ============================================================
--  SW:TOR RP — CANDIDATURES FACTION (HARDENED v2)
--  lua/autorun/server/sv_swtor_applications.lua
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_ApplyFaction")
util.AddNetworkString("SWTOR_ApplicationResult")
-- Removed "SWTOR_AdminReviewApp" (Dead code)

SWTOR.Applications = SWTOR.Applications or {}

-- Initialisation SQL
sql.Query([[CREATE TABLE IF NOT EXISTS swtor_applications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    steamid TEXT,
    name TEXT,
    faction TEXT,
    motivation TEXT,
    status TEXT
)]])

-- Chargement robuste
local function LoadApplications()
    SWTOR.Applications = {}
    local rows = sql.Query("SELECT * FROM swtor_applications WHERE status = 'pending'")
    if rows == false then
        ErrorNoHalt("[SWTOR] Erreur SQL LoadApplications: " .. sql.LastError())
        return
    end
    rows = rows or {}
    for _, r in ipairs(rows) do
        table.insert(SWTOR.Applications, {
            steamid=r.steamid, name=r.name, faction=r.faction, 
            motivation=r.motivation, status=r.status
        })
    end
end
hook.Add("InitPostEntity", "SWTOR_LoadApps", LoadApplications)

-- ============================================================
--  DÉPÔT DE CANDIDATURE
-- ============================================================
net.Receive("SWTOR_ApplyFaction", function(len, ply)
    local factionKey = net.ReadString()
    local motivation = net.ReadString()

    if #motivation > 1000 then return end
    if not SWTOR.Factions[factionKey] then return end

    if SWTOR.Config.AllowSelfJoin then
        SWTOR.SetFaction(ply, factionKey)
        SWTOR.Notify(ply, "Vous avez rejoint " .. SWTOR.Factions[factionKey].name .. " !", "success")
        return
    end

    local check = sql.Query(string.format(
        "SELECT status FROM swtor_applications WHERE steamid = %s ORDER BY id DESC LIMIT 1",
        sql.SQLStr(ply:SteamID())
    ))
    if check and check[1] and check[1].status == "pending" then
        SWTOR.Notify(ply, "Vous avez déjà une candidature en attente.", "error")
        return
    end

    local ok = sql.Query(string.format(
        "INSERT INTO swtor_applications (steamid, name, faction, motivation, status) VALUES (%s, %s, %s, %s, 'pending')",
        sql.SQLStr(ply:SteamID()), sql.SQLStr(ply:Nick()), sql.SQLStr(factionKey), sql.SQLStr(motivation)
    ))
    if ok == false then
        ErrorNoHalt("[SWTOR] Echec insertion DB: " .. sql.LastError())
        SWTOR.Notify(ply, "Erreur serveur, réessayez plus tard.", "error")
        return
    end

    table.insert(SWTOR.Applications, {
        steamid = ply:SteamID(), name = ply:Nick(),
        faction = factionKey, motivation = motivation, status = "pending"
    })

    SWTOR.Notify(ply, "Candidature envoyée aux administrateurs.", "success")

    -- Notification admins connectés
    for _, p in ipairs(player.GetAll()) do
        if SWTOR.IsAdmin(p) then
            p:ChatPrint("[SWTOR] 📋 Nouvelle candidature : " .. ply:Nick() .. " → " .. SWTOR.Factions[factionKey].name)
        end
    end
end)

-- ============================================================
--  APPROBATION / REFUS ADMIN
-- ============================================================
concommand.Add("swtor_approve", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local sid = args[1]
    if not sid then return end

    for _, app in ipairs(SWTOR.Applications) do
        if app.steamid == sid and app.status == "pending" then
            local ok = sql.Query(string.format(
                "UPDATE swtor_applications SET status = 'approved' WHERE steamid = %s AND status = 'pending'",
                sql.SQLStr(sid)
            ))
            if ok == false then
                ErrorNoHalt("[SWTOR] Echec UPDATE approve: " .. sql.LastError())
                if IsValid(ply) then ply:ChatPrint("[SWTOR] Erreur DB.") end
                return
            end

            app.status = "approved"

            for _, p in ipairs(player.GetAll()) do
                if p:SteamID() == sid then
                    SWTOR.SetFaction(p, app.faction)
                    SWTOR.Notify(p, "🎉 Candidature approuvée ! Bienvenue dans " .. SWTOR.Factions[app.faction].name .. " !", "success")
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
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
    local sid = args[1]
    if not sid then return end
    local reason = table.concat(args, " ", 2)
    if reason == "" then reason = "Aucune raison fournie." end

    for _, app in ipairs(SWTOR.Applications) do
        if app.steamid == sid and app.status == "pending" then
            local ok = sql.Query(string.format(
                "UPDATE swtor_applications SET status = 'rejected' WHERE steamid = %s AND status = 'pending'",
                sql.SQLStr(sid)
            ))
            if ok == false then
                ErrorNoHalt("[SWTOR] Echec UPDATE reject: " .. sql.LastError())
                if IsValid(ply) then ply:ChatPrint("[SWTOR] Erreur DB.") end
                return
            end

            app.status = "rejected"

            for _, p in ipairs(player.GetAll()) do
                if p:SteamID() == sid then
                    SWTOR.Notify(p, "Candidature refusée : " .. reason, "error")
                    break
                end
            end

            if IsValid(ply) then
                ply:ChatPrint("[SWTOR] Candidature de " .. app.name .. " refusée.")
            end
            return
        end
    end

    if IsValid(ply) then ply:ChatPrint("[SWTOR] Candidature introuvable.") end
end)

concommand.Add("swtor_applications", function(ply, cmd, args)
    if IsValid(ply) and not SWTOR.IsAdmin(ply) then return end
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
