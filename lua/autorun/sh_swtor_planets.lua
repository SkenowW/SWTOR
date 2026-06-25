-- ============================================================
--  SW:TOR RP - SYSTÈME DE PLANÈTES (5 planètes)
--  Fichier: lua/autorun/sh_swtor_planets.lua
--  Coller dans: garrysmod/lua/autorun/
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Planets = SWTOR.Planets or {}

-- ============================================================
--  DÉFINITION DES 5 PLANÈTES
--  2 Empire | 1 Jedi/République | 1 Mandalorien | 1 Neutre
-- ============================================================

SWTOR.Planets = {

    -- ─────────────────────────────────────────────
    --  PLANÈTE 1 : KORRIBAN  (Empire - Principale)
    -- ─────────────────────────────────────────────
    korriban = {
        name        = "Korriban",
        faction     = "empire",
        type        = "home",   -- home = planète principale de la faction
        description = "Berceau des Sith. Une planète aride et sombre où sont enterrés les anciens Seigneurs Sith. Les tombeaux résonnent de la Force Obscure.",
        color       = Color(180, 40, 40),
        icon        = "materials/swtor/planets/korriban.png",
        -- Positions de spawn (à ajuster selon votre map)
        spawns = {
            { pos = Vector(-1200, 500, 64),  ang = Angle(0, 180, 0), label = "Académie Sith" },
            { pos = Vector(-1400, 200, 64),  ang = Angle(0, 90, 0),  label = "Vallée des Sith" },
            { pos = Vector(-900,  800, 64),  ang = Angle(0, 270, 0), label = "Tombeau de Tulak Hord" },
        },
        -- Zones PVP autorisées sur cette planète
        pvp_zones = {
            { mins = Vector(-2000, 0, 0), maxs = Vector(-800, 1000, 512), label = "Zone de combat" },
        },
        ambient_sound = "music/swtor/korriban_ambient.mp3",
        sky_color     = Color(80, 20, 10),
        -- IDs Workshop pour les addons de décor de cette planète
        workshop_ids  = { "2485124627", "1797130927" },
    },

    -- ─────────────────────────────────────────────
    --  PLANÈTE 2 : DROMUND KAAS  (Empire - Secondaire)
    -- ─────────────────────────────────────────────
    dromund_kaas = {
        name        = "Dromund Kaas",
        faction     = "empire",
        type        = "secondary",
        description = "Capitale de l'Empire Sith. Une planète jungle perpétuellement couverte d'orages. Le siège du pouvoir impérial avec sa cité fortifiée.",
        color       = Color(140, 20, 140),
        icon        = "materials/swtor/planets/dromund_kaas.png",
        spawns = {
            { pos = Vector(500,  500, 64),  ang = Angle(0, 0, 0),   label = "Cité Impériale" },
            { pos = Vector(800,  200, 64),  ang = Angle(0, 90, 0),  label = "Temple Sith" },
            { pos = Vector(300,  900, 64),  ang = Angle(0, 180, 0), label = "Quartier des Ambassadeurs" },
            { pos = Vector(1100, 400, 64),  ang = Angle(0, 270, 0), label = "Hangar Impérial" },
        },
        pvp_zones = {
            { mins = Vector(0, 0, 0), maxs = Vector(2000, 2000, 512), label = "Jungle (Combat libre)" },
        },
        ambient_sound = "music/swtor/dromund_kaas_ambient.mp3",
        sky_color     = Color(40, 10, 60),
        workshop_ids  = { "2485124627", "1797130927" },
    },

    -- ─────────────────────────────────────────────
    --  PLANÈTE 3 : CORUSCANT  (République/Jedi)
    -- ─────────────────────────────────────────────
    coruscant = {
        name        = "Coruscant",
        faction     = "republique",
        type        = "home",
        description = "Capitale de la République Galactique. Une planète-ville aux mille niveaux. Le Temple Jedi y trône comme phare de lumière et de sagesse.",
        color       = Color(30, 100, 200),
        icon        = "materials/swtor/planets/coruscant.png",
        spawns = {
            { pos = Vector(200,  200, 64),  ang = Angle(0, 0, 0),   label = "Temple Jedi" },
            { pos = Vector(500,  200, 64),  ang = Angle(0, 90, 0),  label = "Sénat Galactique" },
            { pos = Vector(200,  500, 64),  ang = Angle(0, 180, 0), label = "Hangar Républicain" },
            { pos = Vector(-100, 200, 64),  ang = Angle(0, 270, 0), label = "Bas-Fonds (Niveau 1313)" },
        },
        pvp_zones = {
            { mins = Vector(-500, -500, 0), maxs = Vector(0, 0, 512), label = "Bas-Fonds (Non-sécurisé)" },
        },
        ambient_sound = "music/swtor/coruscant_ambient.mp3",
        sky_color     = Color(50, 80, 180),
        workshop_ids  = { "2485124627" },
    },

    -- ─────────────────────────────────────────────
    --  PLANÈTE 4 : MANDALORE  (Mandalorien)
    -- ─────────────────────────────────────────────
    mandalore = {
        name        = "Mandalore",
        faction     = "mandalorien",
        type        = "home",
        description = "Planète des guerriers Mandaloriens. Un monde de plaines arides et de canyons. Les clans s'y réunissent sous la bannière du Mand'alor.",
        color       = Color(180, 140, 20),
        icon        = "materials/swtor/planets/mandalore.png",
        spawns = {
            { pos = Vector(-200, -200, 64), ang = Angle(0, 45, 0),  label = "Citadelle Mandalore" },
            { pos = Vector(100,  -400, 64), ang = Angle(0, 135, 0), label = "Arène de Combat" },
            { pos = Vector(-400, 100,  64), ang = Angle(0, 315, 0), label = "Camp des Clans" },
        },
        pvp_zones = {
            { mins = Vector(-100, -300, 0), maxs = Vector(200, 0, 512), label = "Arène (PvP Total)" },
        },
        ambient_sound = "music/swtor/mandalore_ambient.mp3",
        sky_color     = Color(100, 80, 30),
        workshop_ids  = {},
    },

    -- ─────────────────────────────────────────────
    --  PLANÈTE 5 : NAR SHADDAA  (Neutre - Espace Criminal)
    -- ─────────────────────────────────────────────
    nar_shaddaa = {
        name        = "Nar Shaddaa",
        faction     = "neutre",
        type        = "neutral",
        description = "La Lune des Contrebandiers. Une planète-ville contrôlée par les Hutts où toutes les factions se côtoient. Commerce, espionnage et crime prospèrent ici.",
        color       = Color(100, 80, 20),
        icon        = "materials/swtor/planets/nar_shaddaa.png",
        spawns = {
            { pos = Vector(0,    0,   64), ang = Angle(0, 0, 0),   label = "Port Commercial" },
            { pos = Vector(300,  0,   64), ang = Angle(0, 90, 0),  label = "Cantina des Hutts" },
            { pos = Vector(0,    300, 64), ang = Angle(0, 180, 0), label = "Marché Noir" },
            { pos = Vector(-300, 0,   64), ang = Angle(0, 270, 0), label = "Zone d'Atterrissage" },
        },
        pvp_zones = {},  -- Nar Shaddaa est zone de paix (zone marchande)
        ambient_sound = "music/swtor/nar_shaddaa_ambient.mp3",
        sky_color     = Color(60, 40, 10),
        workshop_ids  = {},
    },
}

-- ============================================================
--  HELPERS PLANÈTES
-- ============================================================

--- Retourne la planète home d'une faction
function SWTOR.GetFactionHomePlanet(factionKey)
    local faction = SWTOR.Factions[factionKey]
    if not faction then return nil end
    return SWTOR.Planets[faction.planet_home]
end

--- Retourne toutes les planètes d'une faction
function SWTOR.GetFactionPlanets(factionKey)
    local result = {}
    for key, planet in pairs(SWTOR.Planets) do
        if planet.faction == factionKey then
            result[key] = planet
        end
    end
    return result
end

--- Vérifie si une position est dans une zone PVP d'une planète
function SWTOR.IsInPvPZone(planetKey, pos)
    local planet = SWTOR.Planets[planetKey]
    if not planet or not planet.pvp_zones then return false end
    for _, zone in ipairs(planet.pvp_zones) do
        if pos:WithinAABox(zone.mins, zone.maxs) then
            return true, zone.label
        end
    end
    return false
end

--- Retourne le spawn aléatoire d'une planète
function SWTOR.GetRandomSpawn(planetKey)
    local planet = SWTOR.Planets[planetKey]
    if not planet or not planet.spawns or #planet.spawns == 0 then return nil end
    return planet.spawns[math.random(1, #planet.spawns)]
end

print("[SW:TOR RP] Système de planètes chargé ✓ (" .. table.Count(SWTOR.Planets) .. " planètes)")
