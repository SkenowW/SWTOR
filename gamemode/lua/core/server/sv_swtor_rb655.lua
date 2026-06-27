-- ============================================================
--  SW:TOR RP — INTÉGRATION rb655 LIGHTSABERS
--  lua/autorun/server/sv_swtor_rb655.lua
--
--  rb655 = Star Wars Lightsabers Workshop ID 111412589
--  - Lame 3D avec rendu volumétrique
--  - Sons authentiques Star Wars
--  - Couleurs configurables
--  - Force powers intégrés (bouton F cycle)
--  On remplace nos SWEP maison par rb655 pour les animations
-- ============================================================

if CLIENT then return end

util.AddNetworkString("SWTOR_GiveSaber")

-- ============================================================
--  COULEURS DE LAME PAR FACTION / GRADE
-- ============================================================
local SaberColors = {
    -- Empire Sith
    empire = {
        default    = { r=255, g=20,  b=20  },  -- Rouge standard
        sorcier    = { r=180, g=0,   b=220 },  -- Violet Inquisiteur
        assassin   = { r=255, g=0,   b=80  },  -- Cramoisi Assassin
        darth      = { r=220, g=0,   b=0   },  -- Rouge sombre Darth
        empereur   = { r=20,  g=0,   b=0   },  -- Quasi noir Empereur
    },
    -- Jedi / République
    republique = {
        default    = { r=30,  g=120, b=255 },  -- Bleu Chevalier
        gardien    = { r=30,  g=150, b=255 },  -- Bleu clair Gardien
        sentinelle = { r=50,  g=200, b=80  },  -- Vert Sentinelle
        erudit     = { r=0,   g=220, b=180 },  -- Cyan Érudit
        ombre      = { r=20,  g=80,  b=220 },  -- Bleu nuit Ombre
        maitre     = { r=255, g=255, b=255 },  -- Blanc Grand Maître
        legende    = { r=240, g=220, b=100 },  -- Or Légende Jedi
    },
    -- Mandalorien
    mandalorien = {
        default    = { r=255, g=180, b=0   },  -- Orange/Or
    },
}

-- ============================================================
--  DONNER LE BON SABRE rb655 SELON LA CLASSE
-- ============================================================
local function GiveSaber(ply)
    local faction = ply.swtor_faction or ""
    local class   = ply.swtor_class   or ""
    local grade   = ply.swtor_grade   or 1

    -- Définir la couleur (logique inchangée)
    local col = { r=255, g=255, b=255 }
    if faction == "empire" then
        if class == "inquisiteur_sith" then col = SaberColors.empire.sorcier
        elseif class == "assassin" or string.find(class, "assassin") then col = SaberColors.empire.assassin
        elseif grade >= 23 then col = SaberColors.empire.empereur
        elseif grade >= 19 then col = SaberColors.empire.darth
        else col = SaberColors.empire.default end
    elseif faction == "republique" then
        if string.find(class, "gardien") then col = SaberColors.republique.gardien
        elseif string.find(class, "sentinelle") then col = SaberColors.republique.sentinelle
        elseif string.find(class, "erudit") then col = SaberColors.republique.erudit
        elseif string.find(class, "ombre") then col = SaberColors.republique.ombre
        elseif grade >= 24 then col = SaberColors.republique.legende
        elseif grade >= 17 then col = SaberColors.republique.maitre
        else col = SaberColors.republique.default end
    elseif faction == "mandalorien" then
        col = SaberColors.mandalorien.default
    end

    -- OPTIMISATION : On cherche si le joueur a déjà le sabre
    local wep = ply:GetWeapon("weapon_lightsaber")

    if IsValid(wep) then
        -- Le sabre est déjà là, on met juste à jour la couleur sans le supprimer
        wep:SetNWInt("cr", col.r)
        wep:SetNWInt("cg", col.g)
        wep:SetNWInt("cb", col.b)
        -- Pas besoin de Strip/Give, le changement est immédiat
    else
        -- Le sabre n'est pas là, on le donne
        ply:Give("weapon_lightsaber")
        
        -- On utilise un timer très court pour configurer l'arme une fois qu'elle est bien créée
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            local newWep = ply:GetWeapon("weapon_lightsaber")
            if IsValid(newWep) then
                newWep:SetNWInt("cr", col.r)
                newWep:SetNWInt("cg", col.g)
                newWep:SetNWInt("cb", col.b)
            end
        end)
    end
end

-- ============================================================
--  HOOK — Donner le sabre au spawn
-- ============================================================
hook.Add("PlayerSpawn", "SWTOR_GiveSaber", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        local faction = ply.swtor_faction or ""
        if faction == "" then return end

        local cls = SWTOR.Classes and SWTOR.Classes[ply.swtor_class or ""]

        -- Mandalorien → vibroblade + blaster (pas de sabre)
        if faction == "mandalorien" then
            ply:Give("swtor_vibroblade")
            ply:Give("swtor_blaster_dual")
            return
        end

        -- Voies avec blaster (Agent, Soldat, Contrebandier, Trooper)
        if cls and cls.default_weapon and
           (cls.default_weapon == "swtor_blaster_heavy" or
            cls.default_weapon == "swtor_blaster_dual"  or
            cls.default_weapon == "swtor_sniper") then
            ply:Give(cls.default_weapon)
            return
        end

        -- Voies avec sabre → rb655
        GiveSaber(ply)
    end)
end)

-- ============================================================
--  HOOK — Mettre à jour la couleur du sabre si grade change
-- ============================================================
hook.Add("SWTOR_GradeChanged", "SWTOR_UpdateSaberColor", function(ply)
    local wep = ply:GetWeapon("weapon_lightsaber")
    if IsValid(wep) then
        GiveSaber(ply)
    end
end)

-- ============================================================
--  COMMANDE — Forcer la mise à jour du sabre
-- ============================================================
concommand.Add("swtor_updatesaber", function(ply)
    if not IsValid(ply) then return end
    GiveSaber(ply)
    SWTOR.Notify(ply, "Sabre mis à jour.", "success")
end)

print("[SW:TOR] rb655 Lightsabers intégré ✓")
print("  Couleurs automatiques par faction/voie/grade")
