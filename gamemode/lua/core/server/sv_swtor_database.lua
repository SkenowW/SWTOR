-- ============================================================
--  SW:TOR RP — BASE DE DONNÉES JOUEUR v2 (SQLite étendu)
--  Ajoute: class, force_stat, speed_stat, energy_stat, titles
--  lua/autorun/server/sv_swtor_database.lua
-- ============================================================

if CLIENT then return end

SWTOR = SWTOR or {}

-- ============================================================
--  INITIALISATION TABLE SQL (v2 — colonnes étendues)
-- ============================================================
function SWTOR.InitDatabase()
    -- Table principale
    sql.Query([[
        CREATE TABLE IF NOT EXISTS swtor_players (
            steamid      TEXT PRIMARY KEY,
            name         TEXT    DEFAULT 'Inconnu',
            faction      TEXT    DEFAULT '',
            class        TEXT    DEFAULT '',
            grade        INTEGER DEFAULT 1,
            xp           INTEGER DEFAULT 0,
            credits      INTEGER DEFAULT 500,
            planet       TEXT    DEFAULT '',
            kills        INTEGER DEFAULT 0,
            deaths       INTEGER DEFAULT 0,
            playtime     INTEGER DEFAULT 0,
            last_seen    INTEGER DEFAULT 0,
            model        TEXT    DEFAULT '',
            title        TEXT    DEFAULT '',
            inventory    TEXT    DEFAULT '',
            -- Stats joueur (base + progression)
            stat_force   INTEGER DEFAULT 10,
            stat_speed   INTEGER DEFAULT 10,
            stat_energy  INTEGER DEFAULT 10,
            -- Points de stat non distribués
            stat_points  INTEGER DEFAULT 0,
            -- Duels
            duels_won    INTEGER DEFAULT 0,
            duels_lost   INTEGER DEFAULT 0
        )
    ]])

    -- Migration si table ancienne (ajoute les colonnes manquantes sans erreur)
    local cols = {
        "class TEXT DEFAULT ''",
        "title TEXT DEFAULT ''",
        "inventory TEXT DEFAULT ''",
        "stat_force INTEGER DEFAULT 10",
        "stat_speed INTEGER DEFAULT 10",
        "stat_energy INTEGER DEFAULT 10",
        "stat_points INTEGER DEFAULT 0",
        "duels_won INTEGER DEFAULT 0",
        "duels_lost INTEGER DEFAULT 0",
    }
    for _, col in ipairs(cols) do
        sql.Query("ALTER TABLE swtor_players ADD COLUMN " .. col)
        -- Ignore l'erreur si la colonne existe déjà
    end

    print("[SW:TOR RP] Base de données v2 initialisée ✓")
end

-- ============================================================
--  CHARGEMENT
-- ============================================================
function SWTOR.LoadPlayer(ply)
    local sid = ply:SteamID()
    local row = sql.QueryRow("SELECT * FROM swtor_players WHERE steamid = " .. sql.SQLStr(sid))

    if row then
        ply.swtor_faction   = row.faction   or ""
        ply.swtor_class     = row.class     or ""
        ply.swtor_grade     = tonumber(row.grade)      or 1
        ply.swtor_xp        = tonumber(row.xp)         or 0
        ply.swtor_credits   = tonumber(row.credits)    or 500
        ply.swtor_planet    = row.planet    or ""
        ply.swtor_kills     = tonumber(row.kills)      or 0
        ply.swtor_deaths    = tonumber(row.deaths)     or 0
        ply.swtor_playtime  = tonumber(row.playtime)   or 0
        ply.swtor_model     = row.model     or ""
        ply.swtor_title     = row.title     or ""
        ply.swtor_stat_force  = tonumber(row.stat_force)  or 10
        ply.swtor_stat_speed  = tonumber(row.stat_speed)  or 10
        ply.swtor_stat_energy = tonumber(row.stat_energy) or 10
        ply.swtor_stat_points = tonumber(row.stat_points) or 0
        ply.swtor_duels_won   = tonumber(row.duels_won)   or 0
        ply.swtor_duels_lost  = tonumber(row.duels_lost)  or 0
        ply.swtor_inventory   = (row.inventory and row.inventory ~= "") and util.JSONToTable(row.inventory) or {}
    else
        -- Nouveau joueur — valeurs par défaut
        ply.swtor_faction     = ""
        ply.swtor_class       = ""
        ply.swtor_grade       = 1
        ply.swtor_xp          = 0
        ply.swtor_credits     = 500
        ply.swtor_planet      = ""
        ply.swtor_kills       = 0
        ply.swtor_deaths      = 0
        ply.swtor_playtime    = 0
        ply.swtor_model       = ""
        ply.swtor_title       = ""
        ply.swtor_stat_force  = 10
        ply.swtor_stat_speed  = 10
        ply.swtor_stat_energy = 10
        ply.swtor_stat_points = 0
        ply.swtor_duels_won   = 0
        ply.swtor_duels_lost  = 0
        ply.swtor_inventory   = {}

        sql.Query("INSERT INTO swtor_players (steamid, name) VALUES (" ..
            sql.SQLStr(sid) .. ", " .. sql.SQLStr(ply:Nick()) .. ")")
    end

    SWTOR.ApplyClassStats(ply)
    SWTOR.SyncPlayerData(ply)
    print("[SW:TOR RP] Joueur chargé: " .. ply:Nick() ..
          " | " .. (ply.swtor_faction or "—") ..
          " | " .. (ply.swtor_class   or "—"))
end

-- ============================================================
--  SAUVEGARDE
-- ============================================================
function SWTOR.SavePlayer(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID()
    local inv = ply.swtor_inventory or {}

    sql.Query(string.format([[
        UPDATE swtor_players SET
            name         = %s,
            faction      = %s,
            class        = %s,
            grade        = %d,
            xp           = %d,
            credits      = %d,
            planet       = %s,
            kills        = %d,
            deaths       = %d,
            playtime     = %d,
            last_seen    = %d,
            model        = %s,
            title        = %s,
            inventory    = %s,
            stat_force   = %d,
            stat_speed   = %d,
            stat_energy  = %d,
            stat_points  = %d,
            duels_won    = %d,
            duels_lost   = %d
        WHERE steamid = %s
    ]],
        sql.SQLStr(ply:Nick()),
        sql.SQLStr(ply.swtor_faction    or ""),
        sql.SQLStr(ply.swtor_class      or ""),
        ply.swtor_grade     or 1,
        ply.swtor_xp        or 0,
        ply.swtor_credits   or 0,
        sql.SQLStr(ply.swtor_planet     or ""),
        ply.swtor_kills     or 0,
        ply.swtor_deaths    or 0,
        ply.swtor_playtime  or 0,
        os.time(),
        sql.SQLStr(ply.swtor_model      or ""),
        sql.SQLStr(ply.swtor_title      or ""),
        sql.SQLStr(util.TableToJSON(inv)),
        ply.swtor_stat_force  or 10,
        ply.swtor_stat_speed  or 10,
        ply.swtor_stat_energy or 10,
        ply.swtor_stat_points or 0,
        ply.swtor_duels_won   or 0,
        ply.swtor_duels_lost  or 0,
        sql.SQLStr(sid)
    ))
end

-- ============================================================
--  SYNC RÉSEAU CLIENT
-- ============================================================
util.AddNetworkString("SWTOR_SyncData")
util.AddNetworkString("SWTOR_SetFaction")
util.AddNetworkString("SWTOR_SetGrade")
util.AddNetworkString("SWTOR_GiveCredits")
util.AddNetworkString("SWTOR_TeleportPlanet")
util.AddNetworkString("SWTOR_Notification")
util.AddNetworkString("SWTOR_SetClass")

function SWTOR.SyncPlayerData(ply)
    net.Start("SWTOR_SyncData")
        net.WriteString(ply.swtor_faction     or "")
        net.WriteString(ply.swtor_class       or "")
        net.WriteUInt(ply.swtor_grade         or 1,  8)
        net.WriteUInt(ply.swtor_xp            or 0,  32)
        net.WriteUInt(ply.swtor_credits       or 0,  32)
        net.WriteString(ply.swtor_planet      or "")
        net.WriteUInt(ply.swtor_kills         or 0,  16)
        net.WriteUInt(ply.swtor_deaths        or 0,  16)
        net.WriteUInt(ply.swtor_stat_force    or 10, 8)
        net.WriteUInt(ply.swtor_stat_speed    or 10, 8)
        net.WriteUInt(ply.swtor_stat_energy   or 10, 8)
        net.WriteUInt(ply.swtor_stat_points   or 0,  8)
        net.WriteString(ply.swtor_title       or "")
        net.WriteUInt(ply.swtor_duels_won     or 0,  16)
        net.WriteUInt(ply.swtor_duels_lost    or 0,  16)
    net.Send(ply)
end

-- ============================================================
--  APPLIQUER STATS DE CLASSE EN JEU
-- ============================================================
function SWTOR.ApplyClassStats(ply)
    if not IsValid(ply) then return end
    -- Déléguer à ApplyGradeStats défini dans sh_swtor_factions.lua
    if SWTOR.ApplyGradeStats then
        SWTOR.ApplyGradeStats(ply)
    else
        -- Fallback minimal si factions pas encore chargées
        ply:SetMaxHealth(250)
        ply:SetHealth(250)
        ply:SetArmor(0)
        ply:SetRunSpeed(150)
        ply:SetWalkSpeed(90)
    end
end

-- ============================================================
--  SET FACTION + CLASS
-- ============================================================
function SWTOR.SetFaction(ply, factionKey)
    if not SWTOR.Factions[factionKey] then
        return false, "Faction inconnue: " .. factionKey
    end
    ply.swtor_faction = factionKey
    ply.swtor_grade   = 1
    ply.swtor_class   = ""  -- Classe à choisir après

    local gradeInfo = SWTOR.GetGrade(factionKey, 1)
    if gradeInfo and gradeInfo.models and #gradeInfo.models > 0 then
        ply:SetModel(gradeInfo.models[1])
        ply.swtor_model = gradeInfo.models[1]
    end

    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)
    SWTOR.Notify(ply, "Faction rejointe: " .. SWTOR.Factions[factionKey].name .. " — Choisissez votre classe !", "success")

    -- Demander au client d'ouvrir le menu de classe
    net.Start("SWTOR_OpenClassMenu")
    net.Send(ply)
    return true
end

function SWTOR.SetClass(ply, classKey)
    if not SWTOR.Classes or not SWTOR.Classes[classKey] then
        return false, "Classe inconnue: " .. classKey
    end
    local cls = SWTOR.Classes[classKey]
    if cls.faction ~= ply.swtor_faction then
        return false, "Classe non disponible pour votre faction"
    end

    ply.swtor_class = classKey

    -- Stats de départ selon la classe
    ply.swtor_stat_force  = 10
    ply.swtor_stat_speed  = 10
    ply.swtor_stat_energy = 10
    ply.swtor_stat_points = 3  -- 3 points à distribuer dès le début

    -- Arme donnée par sv_swtor_rb655.lua (hook PlayerSpawn)
    timer.Simple(0.5, function()
        if IsValid(ply) then
            SWTOR.ApplyClassStats(ply)
        end
    end)

    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)
    SWTOR.Notify(ply, "Classe choisie: " .. cls.name .. " | " .. (cls.playstyle or ""), "success")
    return true
end

-- ============================================================
--  SET GRADE — avec vérification promo_req (mod/admin)
-- ============================================================
function SWTOR.SetGrade(ply, gradeIndex, promoter)
    local faction = ply.swtor_faction
    if not faction or faction == "" then return false, "Joueur sans faction" end

    local maxGrade = SWTOR.GetMaxGrade(faction)
    if gradeIndex < 1 or gradeIndex > maxGrade then
        return false, "Grade invalide (" .. gradeIndex .. "/" .. maxGrade .. ")"
    end

    local gradeInfo = SWTOR.GetGrade(faction, gradeIndex)
    if not gradeInfo then return false, "Grade introuvable" end

    -- Vérification permission si un promoteur est fourni
    if IsValid(promoter) then
        local req = gradeInfo.promo_req or "mod"
        if req == "admin" and not promoter:IsAdmin() then
            SWTOR.Notify(promoter,
                "❌ Grade réservé aux Administrateurs : " .. gradeInfo.name, "error")
            return false, "Permission insuffisante (admin requis)"
        end
        -- "mod" = au moins un flag de permission (IsSuperAdmin ou IsAdmin)
        if req == "mod" and not promoter:IsAdmin() and not promoter:IsSuperAdmin() then
            -- Vérifier permission custom "swtor_promote"
            local hasPerm = false
            if ULib and ULib.ucl and ULib.ucl.query then
                hasPerm = ULib.ucl.query(promoter, "swtor_promote")
            end
            if not hasPerm then
                SWTOR.Notify(promoter,
                    "❌ Permission insuffisante pour promouvoir : " .. gradeInfo.name, "error")
                return false, "Permission insuffisante (modérateur requis)"
            end
        end
    end

    -- Appliquer le grade
    ply.swtor_grade = gradeIndex

    -- Modèle du grade
    if gradeInfo.models and #gradeInfo.models > 0 then
        ply:SetModel(gradeInfo.models[1])
        ply.swtor_model = gradeInfo.models[1]
    end

    -- Appliquer HP/Vitesse/Armure/Arme/Aura
    SWTOR.ApplyClassStats(ply)
    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)

    -- Annonce
    local promoterName = IsValid(promoter) and promoter:Nick() or "Système"
    SWTOR.Notify(ply, "⬆ Grade : " .. gradeInfo.name .. " (par " .. promoterName .. ")", "success")
    if IsValid(promoter) and promoter ~= ply then
        SWTOR.Notify(promoter, "✔ " .. ply:Nick() .. " → " .. gradeInfo.name, "success")
    end

    -- Log global (visible par les admins dans leur console)
    print("[SW:TOR PROMO] " .. promoterName .. " → " ..
          ply:Nick() .. " : Grade " .. gradeIndex .. " (" .. gradeInfo.name .. ")")

    return true
end

function SWTOR.PromotePlayer(ply, promoter)
    return SWTOR.SetGrade(ply, (ply.swtor_grade or 1) + 1, promoter)
end
function SWTOR.DemotePlayer(ply, promoter)
    return SWTOR.SetGrade(ply, math.max(1, (ply.swtor_grade or 1) - 1), promoter)
end

function SWTOR.GiveCredits(ply, amount)
    ply.swtor_credits = (ply.swtor_credits or 0) + amount
    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)
end

function SWTOR.TeleportToPlanet(ply, planetKey)
    local planet = SWTOR.Planets[planetKey]
    if not planet then return false, "Planète inconnue" end
    local spawnData = SWTOR.GetRandomSpawn(planetKey)
    if not spawnData then return false, "Aucun spawn" end
    ply.swtor_planet = planetKey
    ply:SetPos(spawnData.pos)
    ply:SetEyeAngles(spawnData.ang)
    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)
    SWTOR.Notify(ply, "Bienvenue sur " .. planet.name .. "  —  " .. spawnData.label, "info")
    return true
end

function SWTOR.Notify(ply, message, notifType)
    net.Start("SWTOR_Notification")
        net.WriteString(message)
        net.WriteString(notifType or "info")
    net.Send(ply)
end

-- ============================================================
--  DISTRIBUTION DES POINTS DE STAT
-- ============================================================
util.AddNetworkString("SWTOR_SpendStat")
net.Receive("SWTOR_SpendStat", function(len, ply)
    local statName = net.ReadString()  -- "force" | "speed" | "energy"
    if (ply.swtor_stat_points or 0) <= 0 then
        SWTOR.Notify(ply, "Aucun point de stat disponible.", "error")
        return
    end
    local valid = { force = true, speed = true, energy = true }
    if not valid[statName] then return end

    local key = "swtor_stat_" .. statName
    local cap = 50  -- maximum 50 par stat
    if (ply[key] or 10) >= cap then
        SWTOR.Notify(ply, "Stat " .. statName .. " au maximum (" .. cap .. ").", "warning")
        return
    end

    ply[key] = (ply[key] or 10) + 1
    ply.swtor_stat_points = ply.swtor_stat_points - 1
    SWTOR.ApplyClassStats(ply)
    SWTOR.SavePlayer(ply)
    SWTOR.SyncPlayerData(ply)
    SWTOR.Notify(ply, "+" .. statName:upper() .. " → " .. ply[key] ..
                      " | " .. ply.swtor_stat_points .. " pts restants", "success")
end)

-- ============================================================
--  SALAIRES
-- ============================================================
timer.Create("SWTOR_Salary", SWTOR.Config and SWTOR.Config.SalaryInterval or 300, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.swtor_faction and ply.swtor_faction ~= "" then
            local gradeInfo = SWTOR.GetGrade(ply.swtor_faction, ply.swtor_grade or 1)
            if gradeInfo then
                SWTOR.GiveCredits(ply, gradeInfo.salary)
                SWTOR.Notify(ply, "Salaire: +" .. gradeInfo.salary .. " crédits", "credits")
            end
        end
    end
end)

-- ============================================================
--  HOOKS
-- ============================================================
hook.Add("PlayerInitialSpawn", "SWTOR_LoadPlayer", function(ply)
    timer.Simple(1.5, function()
        if IsValid(ply) then SWTOR.LoadPlayer(ply) end
    end)
end)

hook.Add("PlayerDisconnected", "SWTOR_SaveOnDisconnect", SWTOR.SavePlayer)

hook.Add("PlayerDeath", "SWTOR_DeathStats", function(victim, inflictor, attacker)
    if IsValid(victim) then
        victim.swtor_deaths = (victim.swtor_deaths or 0) + 1
        SWTOR.SavePlayer(victim)
    end
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        attacker.swtor_kills = (attacker.swtor_kills or 0) + 1
        attacker.swtor_xp    = (attacker.swtor_xp    or 0) + (SWTOR.Config and SWTOR.Config.KillBonus or 25)
        SWTOR.SavePlayer(attacker)
        SWTOR.SyncPlayerData(attacker)
    end
end)

hook.Add("PlayerSpawn", "SWTOR_ReapplyStats", function(ply)
    timer.Simple(0.3, function()
        if IsValid(ply) then
            SWTOR.ApplyClassStats(ply)
            if ply.swtor_model and ply.swtor_model ~= "" then
                ply:SetModel(ply.swtor_model)
            end
        end
    end)
end)

timer.Create("SWTOR_AutoSave", 120, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply.swtor_playtime = (ply.swtor_playtime or 0) + 120
            SWTOR.SavePlayer(ply)
        end
    end
end)

util.AddNetworkString("SWTOR_OpenClassMenu")
SWTOR.InitDatabase()
print("[SW:TOR RP] Database v2 + stats chargés ✓")
