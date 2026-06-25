-- ============================================================
--  SW:TOR RP — CONFIG CENTRALE
--  lua/autorun/sh_swtor_config.lua
-- ============================================================

SWTOR = SWTOR or {}
SWTOR.Config = {

    -- Serveur
    ServerName      = "SW:TOR RP — Le Conflit Éternel",
    MOTD            = "Bienvenue dans la galaxie lointaine. Choisissez votre camp.",
    MaxPlayers      = 64,

    -- Économie
    StartCredits    = 500,          -- Crédits de départ
    SalaryInterval  = 300,          -- Salaire toutes les 5min (secondes)
    KillBonus       = 25,           -- XP par kill
    RPBonus         = 10,           -- XP par action RP (via commande admin)

    -- Combat
    FriendlyFire    = false,        -- Tir ami dans même faction
    PvPEnabled      = true,         -- PvP inter-factions activé
    RespawnTime     = 10,           -- Secondes avant respawn

    -- HP par faction/grade (multiplicateur)
    BaseHP          = 100,
    HPPerGrade      = 10,           -- +10 HP par grade
    MaxHP           = 300,

    -- Grades & XP
    XPPerGrade      = 1000,         -- XP pour monter de grade (auto-promote)
    AutoPromote     = false,        -- Monter auto si XP suffisant

    -- Chat
    RPChatRange     = 350,          -- Portée du /me et /rp (units)
    OOCChatPrefix   = "// ",        -- Préfixe hors-RP

    -- Map
    DefaultMap      = "rp_coruscant_v2",
    FallbackSpawn   = Vector(0, 0, 64),

    -- Candidatures
    AllowSelfJoin   = true,         -- Joueur peut choisir sa faction lui-même
    FactionLocked   = false,        -- Si true: faction assignée uniquement par admin
}

print("[SW:TOR] Config chargée ✓")
