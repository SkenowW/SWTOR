-- gamemode/lua/core/client/temp_find_models.lua
-- TEMPORAIRE — supprimer après usage

if SERVER then return end

concommand.Add("swtor_findmodels_cl", function()
    local results = {}

    for _, folder in ipairs(select(2, file.Find("models/player/*", "GAME"))) do
        for _, f in ipairs(file.Find("models/player/" .. folder .. "/*.mdl", "GAME")) do
            table.insert(results, "models/player/" .. folder .. "/" .. f)
        end
        for _, subfolder in ipairs(select(2, file.Find("models/player/" .. folder .. "/*", "GAME"))) do
            for _, f in ipairs(file.Find("models/player/" .. folder .. "/" .. subfolder .. "/*.mdl", "GAME")) do
                table.insert(results, "models/player/" .. folder .. "/" .. subfolder .. "/" .. f)
            end
        end
    end

    file.Write("swtor_models_found.txt", table.concat(results, "\n"))

    chat.AddText(Color(80, 220, 80), "[SWTOR] " .. #results .. " modèles trouvés.")
    chat.AddText(Color(80, 220, 80), "[SWTOR] Fichier : garrysmod/data/swtor_models_found.txt")

    for _, v in ipairs(results) do
        print(v)
    end
end)

-- Debug : Lister toutes les armes disponibles
if CLIENT then
    print("--- DÉBUT DE RECHERCHE DES ARMES ---")
    local weapons = scripted_ents.GetSpawnable()
    for name, tbl in pairs(weapons) do
        if tbl.Base and tbl.Base:find("weapon") then
            print("[WEAPON DEBUG] Nom: " .. (tbl.PrintName or "Inconnu") .. " | Class: " .. name)
        end
    end
    print("--- FIN DE RECHERCHE ---")
end
