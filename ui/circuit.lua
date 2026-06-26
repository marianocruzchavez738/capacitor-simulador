-- luacheck: globals Circuit CFG Physics

Circuit = {}

local img_cache = nil

function Circuit.draw(font_small, font_med)
    local cc = CFG.circuito



    if not img_cache then
        local ok, img = pcall(love.graphics.newImage, "assets/circuitov2.png")
        img_cache = ok and img or false
    end
    if img_cache then
        love.graphics.setColor(1,1,1)
        love.graphics.draw(img_cache, cc.x, cc.y, 0, cc.scale_x, cc.scale_y)
    else
        love.graphics.setColor(0.2, 0.3, 0.5)
        love.graphics.rectangle("fill", cc.x, cc.y, 400, 240, 6, 6)
        love.graphics.setColor(0.4, 0.6, 0.9)
        love.graphics.rectangle("line", cc.x, cc.y, 400, 240, 6, 6)
        love.graphics.setColor(0.6, 0.7, 0.9)
        love.graphics.printf("[ assets/circuitov2.png ]", cc.x, cc.y+110, 400, "center")
    end
    love.graphics.setColor(cc.label_color)
    love.graphics.setFont(font_small)
    love.graphics.printf(string.format("R=%.0fΩ",  Physics.r()),
        cc.label_r.x, cc.label_r.y, 200)
    love.graphics.printf(string.format("C=%.4fF",  Physics.c()),
        cc.label_c.x, cc.label_c.y, 200)
    love.graphics.printf(string.format("V=%.2fV",  Physics.v_destino()),
        cc.label_v.x, cc.label_v.y, 200)

    local vc = Physics.vc_actual()
    local vd = Physics.v_destino()
    local col = (vc < vd-0.001) and {0.3,0.9,1.0}
             or (vc > vd+0.001) and {1.0,0.5,0.3}
             or {0.4,1.0,0.5}
    love.graphics.setColor(col)
    love.graphics.setFont(font_med)
    love.graphics.printf(string.format("Vc = %.4f V", vc),
        cc.label_vc.x, cc.label_vc.y, 260, "center")
end