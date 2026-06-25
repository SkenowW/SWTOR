-- ============================================================
--  SW:TOR RP — GRADES HRP (Hors Roleplay)
--  lua/autorun/server/sv_swtor_hrp.lua
--  Système de modération avec permissions hiérarchiques
--  Visible dans le panel joueur (scoreboard Tab)
-- ============================================================

if CLIENT then return end

SWTOR.HRP = SWTOR.HRP or {}

-- ============================================================
--  DÉFINITION DES GRADES HRP
--  Du plus haut au plus bas
-- ============================================================
SWTOR.HRP.Ranks = {
    fondateur    = { level=5, label="Fondateur",     color=Color(255,50,50),    tag="[FONDATEUR]"    },
    responsable  = { level=4, label="Responsable",   color=Color(220,80,20),    tag="[RESPONSABLE]"  },
    administrateur={ level=3, label="Administrateur",color=Color(220,150,0),    tag="[ADMIN]"        },
    moderateur   = { level=2, label="Modérateur",    color=Color(80,160,255),   tag="[MOD]"          },
    animateur    = { level=1, label="Animateur",     color=Color(80,220,130),   tag="[ANIMATEUR]"    },
}

-- ============================================================
--  PERMISSIONS PAR GRADE
-- ============================================================
SWTOR.HRP.Permissions = {

    fondateur = {
        -- Tout sans restriction
        ban_temp       = true,
        ban_perm       = true,
        kick           = true,
        teleport       = true,
        noclip         = true,
        god            = true,
        invisible      = true,
        props          = true,
        set_tenue      = true,
        logs           = true,
        set_grade_rp   = true,  -- Peut set grade RP (rangs 1-24)
        set_hrp        = true,  -- Peut set grades HRP
        rcon           = true,
        announce       = true,
        set_faction    = true,
        give_credits   = true,
        manage_server  = true,  -- Restart, changement de map
    },

    responsable = {
        ban_temp       = true,
        ban_perm       = true,
        kick           = true,
        teleport       = true,
        noclip         = true,
        god            = true,
        invisible      = true,
        props          = true,
        set_tenue      = true,
        logs           = true,
        set_grade_rp   = true,
        set_hrp        = true,  -- Peut set animateur/modérateur/admin
        announce       = true,
        set_faction    = true,
        give_credits   = true,
        manage_server  = false, -- Pas de restart serveur
        rcon           = false,
    },

    administrateur = {
        ban_temp       = true,
        ban_perm       = true,
        kick           = true,
        teleport       = true,
        noclip         = true,
        god            = true,
        invisible      = true,
        props          = true,  -- Accès props pour events/animations
        set_tenue      = true,
        logs           = true,
        set_grade_rp   = true,  -- Grades admin RP (rangs 17-24)
        set_hrp        = false,
        announce       = true,
        set_faction    = true,
        give_credits   = true,
        manage_server  = false,
        rcon           = false,
    },

    moderateur = {
        ban_temp       = true,
        ban_perm       = false, -- Pas de ban définitif
        kick           = true,
        teleport       = true,
        noclip         = false,
        god            = false,
        invisible      = true,  -- Peut s'invisibiliser
        props          = false,
        set_tenue      = false,
        logs           = true,
        set_grade_rp   = true,  -- Grades modérateur RP (rangs 1-16)
        set_hrp        = false,
        announce       = false,
        set_faction    = true,
        give_credits   = false,
        manage_server  = false,
        rcon           = false,
    },

    animateur = {
        ban_temp       = false,
        ban_perm       = false,
        kick           = false,
        teleport       = true,
        noclip         = true,  -- Vol pour les animations
        god            = true,  -- Invincible pendant les events
        invisible      = true,
        props          = true,  -- Props pour les events
        set_tenue      = true,  -- Peut changer les tenues des joueurs
        logs           = false,
        set_grade_rp   = false,
        set_hrp        = false,
        announce       = true,  -- Peut faire des annonces event
        set_faction    = false,
        give_credits   = false,
        manage_server  = false,
        rcon           = false,
    },
}

-- ============================================================
--  DONNÉES EN MÉMOIRE + PERSISTANCE
-- ============================================================
local HRPData = {}  -- [steamid] = rankKey

local function LoadHRPData()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS swtor_hrp (
            steamid  TEXT PRIMARY KEY,
            rank     TEXT DEFAULT '',
            set_by   TEXT DEFAULT '',
            set_at   INTEGER DEFAULT 0
        )
    ]])
    local rows = sql.Query("SELECT * FROM swtor_hrp") or {}
    for _, row in ipairs(rows) do
        HRPData[row.steamid] = row.rank
    end
    print("[SW:TOR HRP] " .. table.Count(HRPData) .. " grades HRP chargés")
end

local function SaveHRPRank(steamid, rank, setBy)
    sql.Query("INSERT OR REPLACE INTO swtor_hrp (steamid, rank, set_by, set_at) VALUES (" ..
        sql.SQLStr(steamid) .. ", " .. sql.SQLStr(rank) .. ", " ..
        sql.SQLStr(setBy or "Système") .. ", " .. os.time() .. ")")
end

-- ============================================================
--  GETTERS
-- ============================================================
function SWTOR.HRP.GetRank(ply)
    if not IsValid(ply) then return nil end
    return HRPData[ply:SteamID()]
end

function SWTOR.HRP.GetRankData(ply)
    local rank = SWTOR.HRP.GetRank(ply)
    if not rank then return nil end
    return SWTOR.HRP.Ranks[rank]
end

function SWTOR.HRP.HasPerm(ply, perm)
    if not IsValid(ply) then return false end
    local rank = SWTOR.HRP.GetRank(ply)
    if not rank then return false end
    local perms = SWTOR.HRP.Permissions[rank]
    return perms and perms[perm] == true
end

function SWTOR.HRP.GetLevel(ply)
    local rank = SWTOR.HRP.GetRank(ply)
    if not rank then return 0 end
    return SWTOR.HRP.Ranks[rank] and SWTOR.HRP.Ranks[rank].level or 0
end

-- ============================================================
--  SET GRADE HRP (admin command)
-- ============================================================
util.AddNetworkString("SWTOR_HRPUpdate")
util.AddNetworkString("SWTOR_HRPSync")

function SWTOR.HRP.SetRank(target, rank, setter)
    if not IsValid(target) then return false, "Joueur invalide" end

    -- Vérifier setter
    if IsValid(setter) then
        -- Seul fondateur/responsable peuvent set grades HRP
        if not SWTOR.HRP.HasPerm(setter, "set_hrp") then
            return false, "Permission refusée — set_hrp requis"
        end
        -- Ne peut pas set un grade supérieur ou égal au sien
        local setterLevel = SWTOR.HRP.GetLevel(setter)
        local targetLevel = rank and SWTOR.HRP.Ranks[rank] and SWTOR.HRP.Ranks[rank].level or 0
        if targetLevel >= setterLevel then
            return false, "Impossible d'assigner un grade supérieur ou égal au vôtre"
        end
    end

    local sid = target:SteamID()

    if rank == "none" or rank == "" then
        HRPData[sid] = nil
        sql.Query("DELETE FROM swtor_hrp WHERE steamid = " .. sql.SQLStr(sid))
        SWTOR.HRP.SyncToClient(target, nil)
        SWTOR.Notify(target, "Votre grade HRP a été retiré.", "info")
        if IsValid(setter) then
            SWTOR.Notify(setter, "Grade HRP retiré de " .. target:Nick(), "success")
        end
        return true
    end

    if not SWTOR.HRP.Ranks[rank] then
        return false, "Grade HRP inconnu: " .. rank
    end

    HRPData[sid] = rank
    SaveHRPRank(sid, rank, IsValid(setter) and setter:Nick() or "Console")
    SWTOR.HRP.SyncToClient(target, rank)

    local rankData = SWTOR.HRP.Ranks[rank]
    SWTOR.Notify(target, "✦ Grade HRP assigné: " .. rankData.label, "success")
    if IsValid(setter) then
        SWTOR.Notify(setter, "✔ " .. target:Nick() .. " → " .. rankData.label, "success")
    end

    print("[SW:TOR HRP] " .. (IsValid(setter) and setter:Nick() or "Console") ..
          " → " .. target:Nick() .. " : " .. rankData.label)
    return true
end

function SWTOR.HRP.SyncToClient(ply, rank)
    net.Start("SWTOR_HRPUpdate")
        net.WriteString(rank or "")
    net.Send(ply)
    -- Broadcast aux autres pour affichage dans le scoreboard
    net.Start("SWTOR_HRPSync")
        net.WriteUInt(ply:EntIndex(), 16)
        net.WriteString(rank or "")
    net.Broadcast()
end

-- Envoyer tous les grades HRP aux nouveaux joueurs
hook.Add("PlayerInitialSpawn", "SWTOR_HRP_SendOnJoin", function(newPly)
    timer.Simple(2.5, function()
        if not IsValid(newPly) then return end
        -- Charger le rang depuis DB si connecté pour la première fois
        local sid  = newPly:SteamID()
        local rank = HRPData[sid]
        if rank then SWTOR.HRP.SyncToClient(newPly, rank) end
        -- Envoyer tous les rangs au nouvel arrivant
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and p ~= newPly then
                local r = HRPData[p:SteamID()]
                if r then
                    net.Start("SWTOR_HRPSync")
                        net.WriteUInt(p:EntIndex(), 16)
                        net.WriteString(r)
                    net.Send(newPly)
                end
            end
        end
    end)
end)

-- ============================================================
--  COMMANDES CONSOLE
-- ============================================================

-- swtor_sethrp <joueur> <grade>
concommand.Add("swtor_sethrp", function(ply, cmd, args)
    local targetName = args[1]
    local rankKey    = args[2]
    local printFn    = IsValid(ply) and function(s) ply:ChatPrint(s) end or print

    if not targetName or not rankKey then
        printFn("[HRP] Usage: swtor_sethrp <joueur> <grade>")
        printFn("  Grades: fondateur | responsable | administrateur | moderateur | animateur | none")
        return
    end

    -- Console = toujours autorisée
    local setter = IsValid(ply) and ply or nil

    -- Si c'est un joueur, vérifier permissions
    if IsValid(setter) then
        if SWTOR.HRP.GetLevel(setter) < 4 then  -- Moins que responsable
            printFn("[HRP] Permission refusée. Fondateur ou Responsable requis.")
            return
        end
    end

    local target = nil
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()):find(string.lower(targetName)) then
            target = p break
        end
    end
    if not IsValid(target) then
        printFn("[HRP] Joueur introuvable: " .. targetName) return
    end

    local ok, err = SWTOR.HRP.SetRank(target, rankKey, setter)
    printFn("[HRP] " .. (ok and "✔ Succès" or "✗ " .. (err or "Erreur")))
end)

-- swtor_listhrp
concommand.Add("swtor_listhrp", function(ply, cmd, args)
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("=== SW:TOR HRP — Grades actifs ===")
    for _, p in ipairs(player.GetAll()) do
        local r = HRPData[p:SteamID()]
        if r then
            local rd = SWTOR.HRP.Ranks[r]
            printFn("  " .. p:Nick() .. " → " .. (rd and rd.label or r))
        end
    end
    printFn("=== Grades disponibles ===")
    for key, rd in pairs(SWTOR.HRP.Ranks) do
        printFn("  " .. key .. " (niveau " .. rd.level .. ") — " .. rd.label)
    end
end)

-- ============================================================
--  REMPLACER IsAdmin() PAR LES PERMISSIONS HRP
--  Pour les commandes qui vérifient IsAdmin()
-- ============================================================

-- Override : IsAdmin() retourne true si niveau >= 3 (administrateur+)
local originalIsAdmin = FindMetaTable("Player").IsAdmin
FindMetaTable("Player").IsAdmin = function(ply)
    if originalIsAdmin(ply) then return true end  -- SuperAdmin GMod garde ses droits
    return SWTOR.HRP.GetLevel(ply) >= 3  -- Administrateur, Responsable, Fondateur
end

-- IsSuperAdmin() retourne true si niveau >= 4 (responsable+)
local originalIsSuperAdmin = FindMetaTable("Player").IsSuperAdmin
FindMetaTable("Player").IsSuperAdmin = function(ply)
    if originalIsSuperAdmin(ply) then return true end
    return SWTOR.HRP.GetLevel(ply) >= 4  -- Responsable, Fondateur
end

-- ============================================================
--  POUVOIR SPÉCIAUX — NOCLIP / INVISIBLE / GOD
-- ============================================================

-- Noclip (vol) — Responsable, Admin, Animateur
util.AddNetworkString("SWTOR_HRPNoclip")
net.Receive("SWTOR_HRPNoclip", function(len, ply)
    if not SWTOR.HRP.HasPerm(ply, "noclip") then
        SWTOR.Notify(ply, "Permission refusée — noclip.", "error") return
    end
    local state = not ply:GetMoveType() == MOVETYPE_NOCLIP
    ply:SetMoveType(state and MOVETYPE_NOCLIP or MOVETYPE_WALK)
    SWTOR.Notify(ply, state and "✈ Vol activé" or "✈ Vol désactivé", "info")
end)

-- Invisibilité — tous sauf joueur normal
util.AddNetworkString("SWTOR_HRPInvisible")
net.Receive("SWTOR_HRPInvisible", function(len, ply)
    if not SWTOR.HRP.HasPerm(ply, "invisible") then
        SWTOR.Notify(ply, "Permission refusée — invisible.", "error") return
    end
    ply.swtor_invisible = not ply.swtor_invisible
    ply:SetNoDraw(ply.swtor_invisible)
    ply:DrawShadow(not ply.swtor_invisible)
    SWTOR.Notify(ply, ply.swtor_invisible and "👻 Invisible" or "👁 Visible", "info")
end)

-- God mode — Admin+
util.AddNetworkString("SWTOR_HRPGod")
net.Receive("SWTOR_HRPGod", function(len, ply)
    if not SWTOR.HRP.HasPerm(ply, "god") then
        SWTOR.Notify(ply, "Permission refusée — god.", "error") return
    end
    ply.swtor_god = not ply.swtor_god
    ply:GodEnable()  -- Activer via hook
    SWTOR.Notify(ply, ply.swtor_god and "⭐ God Mode ON" or "⭐ God Mode OFF", "info")
end)

hook.Add("EntityTakeDamage", "SWTOR_GodMode", function(ent, dmginfo)
    if ent:IsPlayer() and ent.swtor_god then
        dmginfo:SetDamage(0)
    end
end)

-- ============================================================
--  BAN (temp + déf) — Modérateur minimum
-- ============================================================
util.AddNetworkString("SWTOR_HRPBan")
net.Receive("SWTOR_HRPBan", function(len, ply)
    local targetSID  = net.ReadString()
    local duration   = net.ReadUInt(32)   -- 0 = permanent
    local reason     = net.ReadString()

    local isPerm = duration == 0
    local perm   = isPerm and "ban_perm" or "ban_temp"

    if not SWTOR.HRP.HasPerm(ply, perm) then
        SWTOR.Notify(ply, "Permission refusée — " .. perm, "error") return
    end

    -- Trouver la cible
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID() == targetSID then
            local durationStr = isPerm and "permanent" or (duration/60 .. " minutes")
            game.ConsoleCommand("banid " .. duration .. " " .. p:SteamID() ..
                               " kick\n")
            -- Log
            print("[SW:TOR BAN] " .. ply:Nick() .. " a banni " ..
                  p:Nick() .. " (" .. durationStr .. ") — " .. reason)
            -- Notif serveur
            for _, pl in ipairs(player.GetAll()) do
                pl:ChatPrint("⛔ [BAN] " .. p:Nick() .. " banni " ..
                             durationStr .. " par " .. ply:Nick() ..
                             " — " .. reason)
            end
            break
        end
    end
end)

-- ============================================================
--  LOGS (visible par Modérateur+)
-- ============================================================
SWTOR.HRP.Logs = {}

function SWTOR.HRP.Log(type, message, ply)
    local entry = {
        time    = os.time(),
        type    = type,
        message = message,
        player  = IsValid(ply) and ply:Nick() or "Système",
    }
    table.insert(SWTOR.HRP.Logs, 1, entry)
    if #SWTOR.HRP.Logs > 200 then SWTOR.HRP.Logs[201] = nil end
end

-- Logger les promotions et actions importantes
hook.Add("PlayerDeath", "SWTOR_HRPLogDeath", function(victim, inflictor, attacker)
    local aName = IsValid(attacker) and attacker:IsPlayer() and attacker:Nick() or "Environnement"
    SWTOR.HRP.Log("combat", victim:Nick() .. " tué par " .. aName)
end)

hook.Add("PlayerDisconnected", "SWTOR_HRPLogDisconnect", function(ply)
    SWTOR.HRP.Log("connexion", ply:Nick() .. " s'est déconnecté")
end)

hook.Add("PlayerInitialSpawn", "SWTOR_HRPLogConnect", function(ply)
    SWTOR.HRP.Log("connexion", ply:Nick() .. " (" .. ply:SteamID() .. ") s'est connecté")
end)

-- Accès logs via net
util.AddNetworkString("SWTOR_HRPGetLogs")
util.AddNetworkString("SWTOR_HRPLogsData")

net.Receive("SWTOR_HRPGetLogs", function(len, ply)
    if not SWTOR.HRP.HasPerm(ply, "logs") then
        SWTOR.Notify(ply, "Logs : permission refusée.", "error") return
    end
    net.Start("SWTOR_HRPLogsData")
        net.WriteString(util.TableToJSON(SWTOR.HRP.Logs))
    net.Send(ply)
end)

-- ============================================================
--  INIT
-- ============================================================
LoadHRPData()
print("[SW:TOR HRP] Système de grades HRP chargé ✓")
print("  Grades: Fondateur > Responsable > Administrateur > Modérateur > Animateur")
print("  Commandes: swtor_sethrp <joueur> <grade> | swtor_listhrp")

-- ============================================================
--  RÉCEPTION PANEL HRP (depuis cl_swtor_hrp.lua)
-- ============================================================
util.AddNetworkString("SWTOR_SetHRPAdmin")

net.Receive("SWTOR_SetHRPAdmin", function(len, ply)
    if not SWTOR.HRP.HasPerm(ply, "set_hrp") then
        SWTOR.Notify(ply, "Permission refusée.", "error") return
    end
    local targetSID = net.ReadString()
    local rankKey   = net.ReadString()
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID() == targetSID then
            SWTOR.HRP.SetRank(p, rankKey, ply)
            return
        end
    end
    SWTOR.Notify(ply, "Joueur introuvable.", "error")
end)
