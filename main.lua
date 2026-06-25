-- luacheck: globals love

-- ============================================================
--  CONFIGURACIÓN VISUAL
-- ============================================================
local CFG = {
    bg_color = {0.06, 0.09, 0.18},

    circuito = {
        x = 70, y = 70,
        scale_x = 0.7, scale_y = 0.7,
        label_color      = {0.95, 0.95, 0.3},
        label_font_size  = 13,
        -- posiciones de los labels sobre la imagen
        label_r  = {x=250, y=50},
        label_c  = {x=490, y=195},
        label_v  = {x=40,  y=195},
        label_vc = {x=150, y=300},
    },

    panel = {
        x=560, y=50, w=215, h=335,
        bg_color        = {0.08, 0.12, 0.24},
        border_color    = {0.25, 0.50, 0.95},
        title_color     = {0.55, 0.88, 1.00},
        label_color     = {0.70, 0.82, 1.00},
        input_bg        = {0.05, 0.08, 0.18},
        input_bg_active = {0.12, 0.20, 0.38},
        input_border    = {0.25, 0.50, 0.95},
        input_text      = {0.92, 0.96, 1.00},
    },

    btn_play = {
        x=578, y=315, w=84, h=30,
        color_play  = {0.08, 0.60, 0.32},
        color_pause = {0.72, 0.28, 0.08},
        text_color  = {1,1,1},
    },
    btn_reset = {
        x=674, y=315, w=84, h=30,
        color      = {0.32, 0.08, 0.58},
        text_color = {1,1,1},
    },

    grafica = {
        x=30, y=370, w=730, h=200,
        bg_color       = {0.03, 0.05, 0.12},
        border_color   = {0.25, 0.50, 0.95},
        grid_color     = {0.12, 0.18, 0.32},
        label_color    = {0.60, 0.72, 0.92},
        curve_teorica  = {0.18, 0.60, 0.28},
        curve_real     = {0.18, 0.82, 1.00},
        dot_color      = {1.00, 0.28, 0.28},
        tau_color      = {0.38, 1.00, 0.52},
        -- cuántos segundos muestra la ventana deslizante
        ventana        = 10,
    },
}

-- ============================================================
--  ESTADO FÍSICO
-- ============================================================
local resistor  = 1000
local voltaje   = 5        -- voltaje fuente actual (V_destino)
local capacitor = 0.001
local velocidad = 1

-- Capacitor: Vc(t) = V_dst + (Vc0 - V_dst)*exp(-t/tau)
-- Al cambiar parámetros en caliente, se reancla en el instante actual
local segmentos = {}   -- {t0, vc0, v_dst, R, C}  cada tramo
local tiempo    = 0    -- tiempo global continuo (nunca retrocede)
local corriendo = false

local campos = {
    {label="Resistencia (Ω)", key="R", value=tostring(resistor),  editando=false},
    {label="Voltaje (V)",     key="V", value=tostring(voltaje),   editando=false},
    {label="Capacitor (F)",  key="C", value=tostring(capacitor), editando=false},
    {label="Velocidad (x)",  key="S", value=tostring(velocidad), editando=false},
}

local historial     = {}   -- {t, v} puntos para dibujar
local MAX_HISTORIAL = 2000

local font_small, font_med

-- ============================================================
--  FÍSICA
-- ============================================================
local function tau_actual()
    return math.max(resistor * capacitor, 1e-12)
end

-- Vc en un segmento dado en tiempo absoluto t
local function vc_segmento(seg, t)
    local dt  = t - seg.t0
    local tau = math.max(seg.R * seg.C, 1e-12)
    return seg.v_dst + (seg.vc0 - seg.v_dst) * math.exp(-dt / tau)
end

-- Vc total en tiempo absoluto t (busca en segmentos)
local function vc_en(t)
    if #segmentos == 0 then return 0 end
    -- encuentra el segmento vigente en t
    local seg = segmentos[1]
    for _, s in ipairs(segmentos) do
        if s.t0 <= t then seg = s else break end
    end
    return vc_segmento(seg, t)
end

-- Vc actual
local function vc_actual()
    return vc_en(tiempo)
end

-- Añade un nuevo segmento desde ahora con los parámetros actuales
local function nuevo_segmento()
    local vc0 = (#segmentos > 0) and vc_actual() or 0
    table.insert(segmentos, {
        t0    = tiempo,
        vc0   = vc0,
        v_dst = voltaje,
        R     = resistor,
        C     = capacitor,
    })
end

-- ============================================================
--  APLICAR VALORES
-- ============================================================
local function leer_campos()
    for _, c in ipairs(campos) do
        local n = tonumber(c.value)
        if n then
            if c.key == "R" then resistor  = math.max(n, 0.001) end
            if c.key == "V" then voltaje   = n                   end
            if c.key == "C" then capacitor = math.max(n, 1e-12) end
            if c.key == "S" then velocidad = math.max(n, 0.01)  end
        end
    end
end

-- Aplica en caliente: crea nuevo segmento, tiempo sigue
local function aplicar_en_caliente()
    leer_campos()
    nuevo_segmento()
end

-- Reset total
local function reset_total()
    leer_campos()
    segmentos = {}
    historial = {}
    tiempo    = 0
    corriendo = false
    nuevo_segmento()
end

-- ============================================================
--  HELPERS
-- ============================================================
local function dentro(mx, my, x, y, w, h)
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

-- ============================================================
--  LOVE CALLBACKS
-- ============================================================
function love.load()
    love.window.setTitle("Simulador Circuito RC")
    love.window.setMode(800, 600)
    font_small = love.graphics.newFont(12)
    font_med   = love.graphics.newFont(14)
    love.keyboard.setTextInput(false)
    nuevo_segmento()
end

function love.update(dt)
    if not corriendo then return end
    tiempo = tiempo + dt * velocidad

    local vc = vc_actual()
    table.insert(historial, {t = tiempo, v = vc})
    if #historial > MAX_HISTORIAL then
        table.remove(historial, 1)
    end
end

-- ============================================================
--  DIBUJO: CIRCUITO
-- ============================================================
local function dibujar_circuito()
    local cc = CFG.circuito

    love.graphics.setColor(cc.label_color)
    love.graphics.setFont(font_small)
    love.graphics.printf(string.format("R=%.0fΩ", resistor),
        cc.label_r.x, cc.label_r.y, 200)
    love.graphics.printf(string.format("C=%.4fF", capacitor),
        cc.label_c.x, cc.label_c.y, 200)
    love.graphics.printf(string.format("V=%.2fV", voltaje),
        cc.label_v.x, cc.label_v.y, 200)

    -- imagen del circuito
    local ok, img = pcall(love.graphics.newImage, "circuitov2.png")
    if ok then
        love.graphics.setColor(1,1,1)
        love.graphics.draw(img, cc.x, cc.y, 0, cc.scale_x, cc.scale_y)
    else
        -- placeholder si no existe la imagen
        love.graphics.setColor(0.2, 0.3, 0.5)
        love.graphics.rectangle("fill", cc.x, cc.y, 400, 240, 6, 6)
        love.graphics.setColor(0.4, 0.6, 0.9)
        love.graphics.rectangle("line", cc.x, cc.y, 400, 240, 6, 6)
        love.graphics.setColor(0.6, 0.7, 0.9)
        love.graphics.printf("[ circuitov2.png ]", cc.x, cc.y+110, 400, "center")
    end

    -- Vc actual con color según sube/baja
    local vc  = vc_actual()
    local vd  = (#segmentos > 0) and segmentos[#segmentos].v_dst or voltaje
    local col = (vc < vd) and {0.3,0.9,1.0} or {1.0,0.5,0.3}
    love.graphics.setColor(col)
    love.graphics.setFont(font_med)
    love.graphics.printf(string.format("Vc = %.4f V", vc),
        cc.label_vc.x, cc.label_vc.y, 260, "center")
end

-- ============================================================
--  DIBUJO: PANEL
-- ============================================================
local function dibujar_panel()
    local P  = CFG.panel
    local BP = CFG.btn_play
    local BR = CFG.btn_reset

    love.graphics.setColor(P.bg_color)
    love.graphics.rectangle("fill", P.x, P.y, P.w, P.h, 8, 8)
    love.graphics.setColor(P.border_color)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", P.x, P.y, P.w, P.h, 8, 8)

    love.graphics.setColor(P.title_color)
    love.graphics.setFont(font_med)
    love.graphics.printf("Parámetros", P.x, P.y+10, P.w, "center")

    love.graphics.setColor(P.border_color[1], P.border_color[2], P.border_color[3], 0.35)
    love.graphics.line(P.x+12, P.y+32, P.x+P.w-12, P.y+32)

    local row_h = 48
    for _, campo in ipairs(campos) do
        local idx = _ -- silence warning; use loop var properly below
        _ = idx
        love.graphics.setColor(P.label_color)
        love.graphics.setFont(font_small)
    end
    -- redraw correctly
    for i, campo in ipairs(campos) do
        local ry = P.y + 40 + (i-1)*row_h

        love.graphics.setColor(P.label_color)
        love.graphics.setFont(font_small)
        love.graphics.printf(campo.label, P.x+10, ry, P.w-20)

        local bx, by, bw, bh = P.x+10, ry+16, P.w-20, 22
        love.graphics.setColor(campo.editando and P.input_bg_active or P.input_bg)
        love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)
        love.graphics.setColor(P.input_border)
        love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
        love.graphics.setColor(P.input_text)
        local tick = math.floor(love.timer.getTime()*2) % 2
        local cursor = campo.editando and (tick==0 and "|" or " ") or ""
        love.graphics.printf(campo.value .. cursor, bx+5, by+4, bw-10)
    end

    -- Botones
    love.graphics.setColor(corriendo and BP.color_pause or BP.color_play)
    love.graphics.rectangle("fill", BP.x, BP.y, BP.w, BP.h, 6,6)
    love.graphics.setColor(BP.text_color)
    love.graphics.setFont(font_med)
    love.graphics.printf(corriendo and "⏸ Pausa" or "▶ Play",
        BP.x, BP.y+7, BP.w, "center")

    love.graphics.setColor(BR.color)
    love.graphics.rectangle("fill", BR.x, BR.y, BR.w, BR.h, 6,6)
    love.graphics.setColor(BR.text_color)
    love.graphics.printf("↺ Reset", BR.x, BR.y+7, BR.w, "center")

    love.graphics.setColor(P.label_color)
    love.graphics.setFont(font_small)
    local tau = tau_actual()
    love.graphics.printf(
        string.format("t=%.2fs  τ=%.4fs  [Space]", tiempo, tau),
        P.x, BP.y+40, P.w, "center")
end

-- ============================================================
--  DIBUJO: GRÁFICA
-- ============================================================
local function dibujar_grafica()
    local G  = CFG.grafica
    local GX, GY, GW, GH = G.x, G.y, G.w, G.h
    local ventana = G.ventana

    love.graphics.setColor(G.bg_color)
    love.graphics.rectangle("fill", GX, GY, GW, GH, 6,6)
    love.graphics.setColor(G.border_color)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", GX, GY, GW, GH, 6,6)

    local ox, oy = GX+50, GY+16
    local gw, gh = GW-60, GH-36

    -- Rango de tiempo visible (ventana deslizante)
    local t_fin = math.max(tiempo, ventana)
    local t_ini = t_fin - ventana

    -- Rango de voltaje: abarca todos los V_dst conocidos + Vc actual
    local v_min, v_max = 0, 0
    for _, s in ipairs(segmentos) do
        v_min = math.min(v_min, s.v_dst, s.vc0)
        v_max = math.max(v_max, s.v_dst, s.vc0)
    end
    v_min = math.min(v_min, vc_actual()) - 0.5
    v_max = math.max(v_max, vc_actual()) + 0.5
    local v_rng = math.max(v_max - v_min, 0.5)

    local function px(t) return ox + ((t - t_ini)/ventana)*gw end
    local function py(v) return oy + gh - ((v - v_min)/v_rng)*gh end
    local function clamp_y(y) return math.max(oy, math.min(oy+gh, y)) end

    -- Grilla
    love.graphics.setColor(G.grid_color)
    love.graphics.setLineWidth(1)
    local GRID_X, GRID_Y = 5, 4
    for i = 0, GRID_X do
        local x = ox + i*(gw/GRID_X)
        love.graphics.line(x, oy, x, oy+gh)
    end
    for i = 0, GRID_Y do
        local y = oy + i*(gh/GRID_Y)
        love.graphics.line(ox, y, ox+gw, y)
    end

    -- Línea cero si está dentro del rango
    if v_min < 0 and v_max > 0 then
        love.graphics.setColor(0.4, 0.4, 0.6)
        local y0 = py(0)
        love.graphics.line(ox, y0, ox+gw, y0)
    end

    -- Etiquetas Y
    love.graphics.setFont(font_small)
    for i = 0, GRID_Y do
        local v = v_min + (1 - i/GRID_Y)*v_rng
        local y = oy + i*(gh/GRID_Y)
        love.graphics.setColor(G.label_color)
        love.graphics.printf(string.format("%.2f", v), GX, y-6, 47, "right")
    end
    -- Etiquetas X
    for i = 0, GRID_X do
        local t = t_ini + i*(ventana/GRID_X)
        local x = ox + i*(gw/GRID_X)
        love.graphics.setColor(G.label_color)
        love.graphics.printf(string.format("%.1f", t), x-15, oy+gh+3, 30, "center")
    end

    -- Línea V_destino actual (punteada visual: segmentos cortos)
    if #segmentos > 0 then
        local vd = segmentos[#segmentos].v_dst
        local yd = clamp_y(py(vd))
        love.graphics.setColor(0.9, 0.75, 0.2, 0.6)
        local dash = 8
        local x_cur = ox
        while x_cur < ox+gw do
            love.graphics.line(x_cur, yd, math.min(x_cur+dash, ox+gw), yd)
            x_cur = x_cur + dash*2
        end
        love.graphics.setColor(0.9, 0.75, 0.2, 0.9)
        love.graphics.printf(string.format("V∞=%.2fV", vd),
            ox+gw-70, yd-14, 70, "right")
    end

    -- Curva histórica real
    if #historial >= 2 then
        love.graphics.setColor(G.curve_real)
        love.graphics.setLineWidth(2)
        for i = 1, #historial-1 do
            local p1, p2 = historial[i], historial[i+1]
            if p2.t >= t_ini and p1.t <= t_fin then
                local x1 = px(p1.t)
                local x2 = px(p2.t)
                local y1 = clamp_y(py(p1.v))
                local y2 = clamp_y(py(p2.v))
                love.graphics.line(x1, y1, x2, y2)
            end
        end
        love.graphics.setLineWidth(1)
    end

    -- Punto actual
    local vc = vc_actual()
    local dot_x = px(tiempo)
    local dot_y = clamp_y(py(vc))
    love.graphics.setColor(G.dot_color)
    love.graphics.circle("fill", dot_x, dot_y, 5)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.circle("line", dot_x, dot_y, 5)

    -- Leyenda
    local tau = tau_actual()
    local vd  = (#segmentos > 0) and segmentos[#segmentos].v_dst or voltaje
    local dir = (vc < vd) and "↑ cargando" or (vc > vd and "↓ descargando" or "= estable")
    love.graphics.setColor(G.tau_color)
    love.graphics.setFont(font_small)
    love.graphics.printf(
        string.format("τ=%.4fs   Vc=%.4fV   %s", tau, vc, dir),
        ox, oy+3, gw, "center")

    -- Títulos ejes
    love.graphics.setColor(G.label_color)
    love.graphics.printf("Vc(V)",  GX,       GY+2,       48, "center")
    love.graphics.printf("t(s)",   GX+GW-48, GY+GH-14,  48, "center")
end

-- ============================================================
--  LOVE DRAW
-- ============================================================
function love.draw()
    love.graphics.setBackgroundColor(CFG.bg_color)
    love.graphics.setFont(font_med or love.graphics.getFont())

    love.graphics.setColor(0.60, 0.80, 1.0)
    love.graphics.printf("Simulador Circuito RC", 0, 12, 800, "center")

    dibujar_circuito()
    dibujar_panel()
    dibujar_grafica()
end

-- ============================================================
--  INPUT
-- ============================================================
function love.mousepressed(mx, my, button)
    if button ~= 1 then return end

    local BP = CFG.btn_play
    local BR = CFG.btn_reset

    if dentro(mx, my, BP.x, BP.y, BP.w, BP.h) then
        corriendo = not corriendo; return
    end
    if dentro(mx, my, BR.x, BR.y, BR.w, BR.h) then
        reset_total(); return
    end

    local P = CFG.panel
    local row_h = 48
    for i, campo in ipairs(campos) do
        local ry = P.y + 40 + (i-1)*row_h
        local bx, by, bw, bh = P.x+10, ry+16, P.w-20, 22
        if dentro(mx, my, bx, by, bw, bh) then
            for _, c in ipairs(campos) do c.editando = false end
            campo.editando = true
            love.keyboard.setTextInput(true)
            return
        end
    end

    for _, c in ipairs(campos) do
        if c.editando then
            c.editando = false
            love.keyboard.setTextInput(false)
            aplicar_en_caliente()
            return
        end
    end
end

function love.textinput(t)
    for _, campo in ipairs(campos) do
        if campo.editando then campo.value = campo.value .. t; return end
    end
end

function love.keypressed(key)
    if key == "backspace" then
        for _, campo in ipairs(campos) do
            if campo.editando then
                campo.value = campo.value:sub(1, -2); return
            end
        end
    elseif key == "return" then
        for _, campo in ipairs(campos) do
            if campo.editando then
                campo.editando = false
                love.keyboard.setTextInput(false)
                aplicar_en_caliente()
                return
            end
        end
    elseif key == "tab" then
        for i, campo in ipairs(campos) do
            if campo.editando then
                campo.editando = false
                aplicar_en_caliente()
                if campos[i+1] then
                    campos[i+1].editando = true
                    love.keyboard.setTextInput(true)
                else
                    love.keyboard.setTextInput(false)
                end
                return
            end
        end
    elseif key == "space" then
        local escribiendo = false
        for _, c in ipairs(campos) do if c.editando then escribiendo = true end end
        if not escribiendo then corriendo = not corriendo end
    end
end