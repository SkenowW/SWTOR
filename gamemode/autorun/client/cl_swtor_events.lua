-- ============================================================
--  SW:TOR RP — ÉVÉNEMENTS CLIENT (affichage cinématique)
--  lua/autorun/client/cl_swtor_events.lua
-- ============================================================

if SERVER then return end

local ActiveEvent = nil

net.Receive("SWTOR_GlobalEvent", function()
    local name = net.ReadString()
    local msg  = net.ReadString()

    -- Afficher en chat
    chat.AddText(
        Color(255,220,0),  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )
    chat.AddText(
        Color(255,200,0), "🌌 [ÉVÉNEMENT] ",
        Color(255,240,150), name .. ": ",
        Color(255,255,255), msg
    )
    chat.AddText(
        Color(255,220,0),  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )

    -- Affichage HUD cinématique
    ActiveEvent = {
        name  = name,
        msg   = msg,
        alpha = 255,
        end_t = CurTime() + 8,
    }

    surface.PlaySound("buttons/button17.wav")
end)

hook.Add("HUDPaint", "SWTOR_EventHUD", function()
    if not ActiveEvent then return end

    local remaining = ActiveEvent.end_t - CurTime()
    if remaining <= 0 then
        ActiveEvent = nil
        return
    end

    local sw, sh = ScrW(), ScrH()
    local alpha  = math.Clamp(remaining * 50, 0, 255)

    -- Fond semi-transparent en haut
    draw.RoundedBox(0, 0, sh * 0.08, sw, 70, Color(0,0,0, alpha * 0.7))

    -- Barre dorée en haut et en bas
    surface.SetDrawColor(200, 160, 20, alpha)
    surface.DrawRect(0, sh * 0.08,     sw, 2)
    surface.DrawRect(0, sh * 0.08 + 68, sw, 2)

    -- Texte
    draw.SimpleText("⚡ " .. ActiveEvent.name .. " ⚡",
        "SWTOR_HUD_Title", sw/2, sh*0.08 + 22,
        Color(255,220,50,alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    draw.SimpleText(ActiveEvent.msg,
        "SWTOR_HUD_Medium", sw/2, sh*0.08 + 50,
        Color(255,255,200,alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

print("[SW:TOR] Événements client chargés ✓")
