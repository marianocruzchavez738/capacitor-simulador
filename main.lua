-- luacheck: globals love CFG Physics Panel Circuit Graph

require("config")
require("physics")
require("ui.panel")
require("ui.circuit")
require("ui.graph")

local font_small, font_med

function love.load()
    love.window.setIcon(love.image.newImageData("assets/icono.png"))
    love.window.setTitle("Simulador Circuito RC")
    love.window.setMode(800, 600)
    font_small = love.graphics.newFont(12)
    font_med   = love.graphics.newFont(14)
    love.keyboard.setTextInput(false)
    Physics.init(1000, 0.001, 5)
end

function love.update(dt)
    if Panel.corriendo() then
        Physics.update(dt, Panel.velocidad())
        Graph.update()
    end
end

function love.draw()
    love.graphics.setBackgroundColor(CFG.bg_color)
    love.graphics.setFont(font_med)
    love.graphics.setColor(0.60, 0.80, 1.0)
    love.graphics.printf("Simulador Circuito RC", 0, 12, 800, "center")

    Circuit.draw(font_small, font_med)
    Panel.draw(font_small, font_med)
    Graph.draw(font_small)
end

function love.mousepressed(mx, my, button)
    if button == 1 then Panel.mousepressed(mx, my) end
end

function love.keypressed(key)   Panel.keypressed(key)  end
function love.textinput(t)      Panel.textinput(t)     end