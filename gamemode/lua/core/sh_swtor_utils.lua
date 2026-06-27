-- ============================================================
--  SW:TOR RP — UTILS
--  lua/autorun/sh_swtor_utils.lua  (partagé)
-- ============================================================
SWTOR = SWTOR or {}

-- Vérifie si le joueur a le droit d'accéder au panel admin
function SWTOR.IsAdmin(ply)
    -- 1. Check GMod / ULX / SAM standards
    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
    
    -- 2. Check ton rang spécifique "Fondateur"
    if ply:GetUserGroup() == "fondateur" then return true end
    
    -- 3. Check par niveau HRP (si tu veux que les niveaux 3+ soient admins)
    local hrpKey = ply:GetNWString("swtor_hrp_rank", "")
    if hrpKey ~= "" and SWTOR.HRP.Ranks[hrpKey] then
        return SWTOR.HRP.Ranks[hrpKey].level >= 3 -- Niveaux 3, 4, 5
    end

    return false
end

