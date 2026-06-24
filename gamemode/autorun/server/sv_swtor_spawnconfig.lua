-- ============================================================
--  SW:TOR RP — OUTIL DE CONFIGURATION DES SPAWNS EN JEU
--  lua/autorun/server/sv_swtor_spawnconfig.lua
--  Permet à l'admin de poser les spawns directement sur la map
--  sans modifier les fichiers à la main
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_SpawnTool")
util.AddNetworkString("SWTOR_SpawnSaved")
util.AddNetworkString("SWTOR_SpawnsList")

-- ============================================================
--  SAUVEGARDE DES SPAWNS EN BASE DE DONNÉES
-- ============================================================
local function InitSpawnDB()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS swtor_spawns (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            planet   TEXT    NOT NULL,
            label    TEXT    NOT NULL,
            x        REAL    DEFAULT 0,
            y        REAL    DEFAULT 0,
            z        REAL    DEFAULT 0,
            ang      REAL    DEFAULT 0,
            is_default INTEGER DEFAULT 0
        )
    ]])
end
InitSpawnDB()

-- Charger les spawns depuis la DB et les injecter dans SWTOR.Planets
local function LoadSpawnsFromDB()
    local rows = sql.Query("SELECT * FROM swtor_spawns") or {}
    if #rows == 0 then return end

    for _, row in ipairs(rows) do
        local planet = SWTOR.Planets and SWTOR.Planets[row.planet]
        if planet then
            planet.spawns = planet.spawns or {}
            -- Éviter les doublons
            local exists = false
            for _, sp in ipairs(planet.spawns) do
                if sp.label == row.label then exists = true break end
            end
            if not exists then
                table.insert(planet.spawns, {
                    pos   = Vector(tonumber(row.x), tonumber(row.y), tonumber(row.z)),
                    ang   = Angle(0, tonumber(row.ang), 0),
                    label = row.label,
                    db_id = tonumber(row.id),
                })
            end
        end
    end
    print("[SW:TOR Spawns] " .. #rows .. " spawn(s) chargé(s) depuis la DB")
end

-- Charger au démarrage
timer.Simple(3, LoadSpawnsFromDB)

-- ============================================================
--  COMMANDES ADMIN POUR POSER LES SPAWNS
-- ============================================================

-- swtor_setspawn <planète> <label>
-- Pose un spawn à l'endroit exact où l'admin se trouve
concommand.Add("swtor_setspawn", function(ply, cmd, args)
    if not IsValid(ply) then print("[SPAWN] Commande côté serveur uniquement") return end
    if not ply:IsAdmin() then
        SWTOR.Notify(ply, "Permission refusée.", "error") return
    end

    local planetKey = args[1]
    local label     = table.concat(args, " ", 2)

    if not planetKey or planetKey == "" then
        ply:ChatPrint("[SPAWN] Usage: swtor_setspawn <planète> <label>")
        ply:ChatPrint("  Planètes: korriban | dromund_kaas | coruscant | mandalore | nar_shaddaa")
        ply:ChatPrint("  Ex: swtor_setspawn korriban Dortoir Sith")
        return
    end
    if not label or label == "" then label = "Spawn " .. planetKey end

    if not SWTOR.Planets or not SWTOR.Planets[planetKey] then
        ply:ChatPrint("[SPAWN] Planète inconnue: " .. planetKey)
        return
    end

    local pos = ply:GetPos()
    local ang = ply:GetAngles().y  -- Seulement la rotation Y (gauche/droite)

    -- Sauvegarder en DB
    sql.Query(string.format(
        "INSERT INTO swtor_spawns (planet, label, x, y, z, ang) VALUES (%s, %s, %f, %f, %f, %f)",
        sql.SQLStr(planetKey), sql.SQLStr(label),
        pos.x, pos.y, pos.z, ang
    ))

    -- Injecter immédiatement dans SWTOR.Planets
    SWTOR.Planets[planetKey].spawns = SWTOR.Planets[planetKey].spawns or {}
    table.insert(SWTOR.Planets[planetKey].spawns, {
        pos   = pos,
        ang   = Angle(0, ang, 0),
        label = label,
    })

    SWTOR.Notify(ply, "✅ Spawn posé: " .. label .. " sur " ..
        SWTOR.Planets[planetKey].name ..
        " (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ", " .. math.floor(pos.z) .. ")",
        "success")

    print("[SW:TOR Spawns] Nouveau spawn: " .. label ..
          " | " .. planetKey ..
          " | " .. pos.x .. " " .. pos.y .. " " .. pos.z)
end)

-- swtor_listspawns [planète]
concommand.Add("swtor_listspawns", function(ply, cmd, args)
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    local filter  = args[1]

    printFn("=== SW:TOR — Spawns configurés ===")
    if not SWTOR.Planets then printFn("Planètes non chargées") return end

    for key, planet in pairs(SWTOR.Planets) do
        if filter and filter ~= key then continue end
        local spawns = planet.spawns or {}
        printFn("[" .. planet.name .. " — " .. key .. "] " .. #spawns .. " spawn(s)")
        for i, sp in ipairs(spawns) do
            printFn("  " .. i .. ". " .. sp.label ..
                    " | " .. math.floor(sp.pos.x) ..
                    " " .. math.floor(sp.pos.y) ..
                    " " .. math.floor(sp.pos.z))
        end
    end
end)

-- swtor_delspawn <id_db>
concommand.Add("swtor_delspawn", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local id = tonumber(args[1])
    if not id then
        local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
        printFn("[SPAWN] Usage: swtor_delspawn <id>  (voir swtor_listspawns)")
        return
    end
    sql.Query("DELETE FROM swtor_spawns WHERE id = " .. id)
    -- Recharger depuis DB
    if SWTOR.Planets then
        for _, planet in pairs(SWTOR.Planets) do planet.spawns = {} end
    end
    LoadSpawnsFromDB()
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("[SPAWN] Spawn #" .. id .. " supprimé et rechargé.")
end)

-- swtor_clearspawns <planète>
concommand.Add("swtor_clearspawns", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local planetKey = args[1]
    if not planetKey then
        local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
        printFn("[SPAWN] Usage: swtor_clearspawns <planète>")
        return
    end
    sql.Query("DELETE FROM swtor_spawns WHERE planet = " .. sql.SQLStr(planetKey))
    if SWTOR.Planets and SWTOR.Planets[planetKey] then
        SWTOR.Planets[planetKey].spawns = {}
    end
    local printFn = IsValid(ply) and function(s) ply:ChatPrint(s) end or print
    printFn("[SPAWN] Spawns de " .. planetKey .. " supprimés.")
end)

print("[SW:TOR] Outil spawns chargé ✓")
print("  swtor_setspawn   <planète> <label>  — Poser un spawn ici")
print("  swtor_listspawns [planète]           — Lister les spawns")
print("  swtor_delspawn   <id>                — Supprimer un spawn")
print("  swtor_clearspawns <planète>          — Tout effacer")
