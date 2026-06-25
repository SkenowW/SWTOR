-- ============================================================
--  SW:TOR RP — CLIENT rb655 LIGHTSABERS
--  lua/autorun/client/cl_swtor_rb655.lua
--  Configure rb655 automatiquement selon faction/grade
-- ============================================================

if SERVER then return end

-- ============================================================
--  AUTO-CONFIG rb655 À L'ÉQUIPEMENT DU SABRE
-- ============================================================
hook.Add("WeaponEquipped", "SWTOR_Rb655Config", function(wep, ply)
    if not IsValid(wep) or not IsValid(ply) then return end
    if wep:GetClass() ~= "weapon_lightsaber" then return end
    if ply ~= LocalPlayer() then return end

    -- Lire la couleur stockée en NWInt par le serveur
    local r = ply:GetNWInt("rb655_r", 255)
    local g = ply:GetNWInt("rb655_g", 30)
    local b = ply:GetNWInt("rb655_b", 30)

    -- Appliquer via les ConVars rb655
    RunConsoleCommand("rb655_color_r", tostring(r))
    RunConsoleCommand("rb655_color_g", tostring(g))
    RunConsoleCommand("rb655_color_b", tostring(b))

    -- Son d'activation selon faction
    local faction = LocalData and LocalData.faction or ""
    if faction == "empire" then
        RunConsoleCommand("rb655_sound_set", "kylo")   -- Son grave/menaçant
    elseif faction == "republique" then
        RunConsoleCommand("rb655_sound_set", "obi")    -- Son classique Jedi
    else
        RunConsoleCommand("rb655_sound_set", "1")      -- Standard
    end
end)

-- ============================================================
--  MISE À JOUR AUTOMATIQUE QUAND LE GRADE CHANGE
-- ============================================================
local lastGrade = 0
hook.Add("Think", "SWTOR_CheckGradeChange", function()
    if not LocalData then return end
    local grade = LocalData.grade or 1
    if grade ~= lastGrade then
        lastGrade = grade
        -- Demander une mise à jour du sabre au serveur
        RunConsoleCommand("swtor_updatesaber")
    end
end)

-- ============================================================
--  AFFICHAGE HUD rb655 — Remplacer l'indicateur sabre
-- ============================================================
hook.Add("HUDShouldDraw", "SWTOR_HideRb655HUD", function(name)
    -- Masquer les éléments HUD par défaut de rb655
    -- qui doubleraient notre HUD custom
    if name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
        local ply = LocalPlayer()
        if not IsValid(ply) then return end 
        
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) then return end

        local wep = LocalPlayer():GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_lightsaber" then
            return false
        end
    end
end)

print("[SW:TOR] rb655 Client configuré ✓")
