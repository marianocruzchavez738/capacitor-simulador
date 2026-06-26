-- luacheck: globals Panel CFG Physics

Panel = {}

local campos = {
    {label="Resistencia (Ω)", key="R", valores="1000",  editando=false},
    {label="Voltaje (V)",     key="V", valores="5",     editando=false},
    {label="Capacitor (F)",  key="C", valores="0.001", editando=false},
    {label="Velocidad (x)",  key="S", valores="1",     editando=false},
}
local velocidad = 1
local corriendo = false

local function dentro(mx, my, x, y, w, h)
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

local function leer_campos()
    local vals = {}
    for _, c in ipairs(campos) do
        vals[c.key] = tonumber(c.valores)
    end
    return vals
end

function Panel.corriendo()   return corriendo  end
function Panel.velocidad()   return velocidad  end
function Panel.get_campos()  return campos     end

function Panel.draw(font_small, font_med)
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
        local tick   = math.floor(love.timer.getTime()*2) % 2
        local cursor = campo.editando and (tick==0 and "|" or " ") or ""
        love.graphics.printf(campo.valores .. cursor, bx+5, by+4, bw-10)
    end

    love.graphics.setColor(corriendo and BP.color_pause or BP.color_play)
    love.graphics.rectangle("fill", BP.x, BP.y, BP.w, BP.h, 6, 6)
    love.graphics.setColor(BP.text_color)
    love.graphics.setFont(font_med)
    love.graphics.printf(corriendo and "Pausa" or "Play",
        BP.x, BP.y+7, BP.w, "center")

    love.graphics.setColor(BR.color)
    love.graphics.rectangle("fill", BR.x, BR.y, BR.w, BR.h, 6, 6)
    love.graphics.setColor(BR.text_color)
    love.graphics.printf("Reset", BR.x, BR.y+7, BR.w, "center")

    love.graphics.setColor(P.label_color)
    love.graphics.setFont(font_small)
    love.graphics.printf(
        string.format("t=%.2fs  t=%.4fs  [Space]",
            Physics.tiempo(), Physics.tau()),
        P.x, BP.y+40, P.w, "center")
end

function Panel.mousepressed(mx, my)
    local BP = CFG.btn_play
    local BR = CFG.btn_reset
    local P  = CFG.panel

    if dentro(mx, my, BP.x, BP.y, BP.w, BP.h) then
        corriendo = not corriendo; return
    end

    if dentro(mx, my, BR.x, BR.y, BR.w, BR.h) then
        local v = leer_campos()
        velocidad = math.max(v.S or 1, 0.01)
        Physics.reset(
            math.max(v.R or 1000, 0.001),
            math.max(v.C or 0.001, 1e-12),
            v.V or 5)
        corriendo = false
        return
    end

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

    -- click fuera → aplicar en caliente
    for _, c in ipairs(campos) do
        if c.editando then
            c.editando = false
            love.keyboard.setTextInput(false)
            local v = leer_campos()
            velocidad = math.max(v.S or velocidad, 0.01)
            Physics.cambiar_parametros(
                math.max(v.R or Physics.r(),  0.001),
                math.max(v.C or Physics.c(),  1e-12),
                v.V or Physics.v_destino())
            return
        end
    end
end

local function confirmar_campo(idx)
    campos[idx].editando = false
    love.keyboard.setTextInput(false)
    local v = leer_campos()
    velocidad = math.max(v.S or velocidad, 0.01)
    Physics.cambiar_parametros(
        math.max(v.R or Physics.r(),  0.001),
        math.max(v.C or Physics.c(),  1e-12),
        v.V or Physics.v_destino())
end

function Panel.keypressed(key)
    if key == "backspace" then
        for _, c in ipairs(campos) do
            if c.editando then c.valores = c.valores:sub(1,-2); return end
        end
    elseif key == "return" then
        for i, c in ipairs(campos) do
            if c.editando then confirmar_campo(i); return end
        end
    elseif key == "tab" then
        for i, c in ipairs(campos) do
            if c.editando then
                confirmar_campo(i)
                if campos[i+1] then
                    campos[i+1].editando = true
                    love.keyboard.setTextInput(true)
                end
                return
            end
        end
    elseif key == "space" then
        local escribiendo = false
        for _, c in ipairs(campos) do if c.editando then escribiendo=true end end
        if not escribiendo then corriendo = not corriendo end
    end
end

function Panel.textinput(t)
    for _, c in ipairs(campos) do
        if c.editando then c.valores = c.valores .. t; return end
    end
end