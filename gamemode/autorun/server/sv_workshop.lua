-- ============================================================
--  SW:TOR RP — WORKSHOP SERVEUR (v2 — rb655 + wOS intégrés)
--  lua/autorun/server/sv_workshop.lua
-- ============================================================

if CLIENT then return end

-- ============================================================
--  MAP PRINCIPALE
-- ============================================================
resource.AddWorkshop("3292726511")  -- SWTOR MAP V4 (rp_swtortksv4)

-- ============================================================
--  COMBAT — SABRES LASER (rb655 — GRATUIT, le meilleur libre)
-- ============================================================
resource.AddWorkshop("111412589")   -- Star Wars Lightsabers (rb655) — lame 3D, sons, Force
resource.AddWorkshop("1783090970")  -- 121 Lightsabers SWTOR — poignées supplémentaires
resource.AddWorkshop("5796532")     -- Rubat Lightsabers — pack complémentaire

-- ============================================================
--  ANIMATIONS — wOS BASE (GRATUIT)
-- ============================================================
resource.AddWorkshop("1778514772")  -- wOS Animation Extension Base — REQUIS
resource.AddWorkshop("1797055019")  -- Blade Symphony Animations (wOS) — animations combat
resource.AddWorkshop("2091006906")  -- wOS Jedi/Sith Stances — postures par faction
resource.AddWorkshop("3223650050")  -- ASTRAL SWTOR Animations — animations SWTOR dédiées

-- ============================================================
--  BLASTERS
-- ============================================================
resource.AddWorkshop("563425624")   -- Star Wars Weapons Pack
resource.AddWorkshop("1674313060")  -- CS574 Star Wars Blasters (sons + modèles HD)

-- ============================================================
--  MODÈLES — SITH
-- ============================================================
resource.AddWorkshop("868022323")   -- Sith Warrior / Juggernaut / Marauder
resource.AddWorkshop("1209000314")  -- SWTOR Mega Pack (Darth Baras, Thanaton...)
resource.AddWorkshop("1537401284")  -- Sith Inquisitor, Assassin, Angel
resource.AddWorkshop("1926252625")  -- Sith Acolyte, Naïela, persos custom
resource.AddWorkshop("879799617")   -- Sith Troopers V2 + Imperial Officers

-- ============================================================
--  MODÈLES — JEDI / RÉPUBLIQUE
-- ============================================================
resource.AddWorkshop("1180350428")  -- Jedi vs Sith (Senya Tirall, Chevaliers...)
resource.AddWorkshop("813525929")   -- EGM SWTOR:RP (Maîtres Jedi CGI)
resource.AddWorkshop("694088822")   -- Jedi vs Sith RP classique
resource.AddWorkshop("2485124627")  -- SWTOR Content Pack (Havoc Trooper, Republic)

-- ============================================================
--  MODÈLES — MANDALORIEN
-- ============================================================
resource.AddWorkshop("937507580")   -- Boba/Jango Fett + Sith Troopers

-- ============================================================
--  PROPS & DÉCOR SWTOR
-- ============================================================
resource.AddWorkshop("1797130927")  -- Star Wars Props SWTOR
resource.AddWorkshop("3027345575")  -- VoidStudios Library

print("[SW:TOR RP] Workshop chargé ✓ (" ..
    "rb655 Lightsabers + wOS Animations + modèles SWTOR)")
