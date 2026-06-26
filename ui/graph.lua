-- luacheck: globals Graph CFG Physics

Graph = {}

local historial     = {}
local MAX_HISTORIAL = 2000

function Graph.update()
    local t  = Physics.tiempo()
    local vc = Physics.vc_actual()
    table.insert(historial, {t=t, v=vc})
    if #historial > MAX_HISTORIAL then table.remove(historial, 1) end
end

function Graph.reset()
    historial = {}
end

function Graph.draw(font_small)
    local G  = CFG.grafica
    local GX, GY, GW, GH = G.x, G.y, G.w, G.h
    local ventana = G.ventana

    love.graphics.setColor(G.bg_color)
    love.graphics.rectangle("fill", GX, GY, GW, GH, 6, 6)
    love.graphics.setColor(G.border_color)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", GX, GY, GW, GH, 6, 6)

    local ox, oy = GX+50, GY+16
    local gw, gh = GW-60, GH-36

    local t_cur = Physics.tiempo()
    local t_fin = math.max(t_cur, ventana)
    local t_ini = t_fin - ventana

    local vmin, vmax = Physics.rango_v()
    local v_rng = math.max(vmax - vmin, 0.5)

    local function px(t) return ox + ((t-t_ini)/ventana)*gw end
    local function py(v) return oy + gh - ((v-vmin)/v_rng)*gh end
    local function cy(y) return math.max(oy, math.min(oy+gh, y)) end

    -- Grilla
    love.graphics.setColor(G.grid_color)
    love.graphics.setLineWidth(1)
    for i = 0, 5 do
        love.graphics.line(ox+i*(gw/5), oy, ox+i*(gw/5), oy+gh)
    end
    for i = 0, 4 do
        love.graphics.line(ox, oy+i*(gh/4), ox+gw, oy+i*(gh/4))
    end

    -- Línea en 0V
    if vmin < 0 and vmax > 0 then
        love.graphics.setColor(0.4, 0.4, 0.6)
        love.graphics.line(ox, cy(py(0)), ox+gw, cy(py(0)))
    end

    -- Etiquetas Y
    love.graphics.setFont(font_small)
    for i = 0, 4 do
        local v = vmin + (1-i/4)*v_rng
        love.graphics.setColor(G.label_color)
        love.graphics.printf(string.format("%.2f",v), GX, oy+i*(gh/4)-6, 47, "right")
    end
    -- Etiquetas X
    for i = 0, 5 do
        local t = t_ini + i*(ventana/5)
        local x = ox + i*(gw/5)
        love.graphics.setColor(G.label_color)
        love.graphics.printf(string.format("%.1f",t), x-15, oy+gh+3, 30, "center")
    end

    -- Línea V punteada
    local vd = Physics.v_destino()
    local yd = cy(py(vd))
    love.graphics.setColor(0.9, 0.75, 0.2, 0.6)
    local x_cur = ox
    while x_cur < ox+gw do
        love.graphics.line(x_cur, yd, math.min(x_cur+8, ox+gw), yd)
        x_cur = x_cur + 16
    end
    love.graphics.setColor(0.9, 0.75, 0.2, 0.9)
    love.graphics.printf(string.format("V=%.2fV", vd), ox+gw-70, yd-14, 70, "right")

    -- Curva real
    if #historial >= 2 then
        love.graphics.setColor(G.curve_real)
        love.graphics.setLineWidth(2)
        for i = 1, #historial-1 do
            local p1, p2 = historial[i], historial[i+1]
            if p2.t >= t_ini and p1.t <= t_fin then
                love.graphics.line(
                    px(p1.t), cy(py(p1.v)),
                    px(p2.t), cy(py(p2.v)))
            end
        end
        love.graphics.setLineWidth(1)
    end

    -- Punto actual
    local vc  = Physics.vc_actual()
    love.graphics.setColor(G.dot_color)
    love.graphics.circle("fill", px(t_cur), cy(py(vc)), 5)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.circle("line", px(t_cur), cy(py(vc)), 5)

    -- Leyenda
    local dir = (vc < vd-0.001) and " cargando"
             or (vc > vd+0.001) and " descargando"
             or "= estable"
    love.graphics.setColor(G.tau_color)
    love.graphics.printf(
        string.format("t=%.4fs   Vc=%.4fV   Estado: %s", Physics.tau(), vc, dir),
        ox, oy+3, gw, "center")

    love.graphics.setColor(G.label_color)
    love.graphics.printf("Vc(V)", GX,       GY+2,      48, "center")
    love.graphics.printf("t(s)",  GX+GW-48, GY+GH-14,  48, "center")
end