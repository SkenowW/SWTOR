-- ============================================================
--  SW:TOR RP — UTILS
--  lua/autorun/sh_swtor_utils.lua  (partagé)
-- ============================================================
SWTOR = SWTOR or {}

-- Vérifie si le joueur a le droit d'accéder au panel admin
function SWTOR.IsAdmin(ply)
    if not IsValid(ply) then return false end

    -- 1. PONT HRP : Si le grade HRP est "fondateur", on autorise tout
    -- On utilise GetNWString pour lire la valeur synchronisée en temps réel
    local hrpRank = ply:GetNWString("swtor_hrp", "")
    if hrpRank == "fondateur" then 
        return true 
    end

    -- 2. Sécurité native (si tu deviens superadmin par ULX un jour)
    if ply:IsSuperAdmin() then return true end
    
    -- 3. Ton système de niveaux HRP (Admin = niv 3, Resp = niv 4, Fondateur = niv 5)
    local rankData = SWTOR.HRP.Ranks[hrpRank]
    if rankData and rankData.level >= 3 then
        return true
    end
    
    return false
end

