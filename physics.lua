-- luacheck: globals Physics

--[[
  FÍSICA DEL CIRCUITO RC
  ─────────────────────────────────────────────────────────────
  El capacitor siempre avanza hacia el voltaje fuente (V∞):

      Vc(t) = V∞ + (Vc_inicial - V∞) × e^(−Δt / τ)

  donde τ = R × C  (tau, constante de tiempo)

  Cuando el usuario cambia R, C o V en caliente, se crea un
  nuevo "tramo" que parte desde el Vc actual, así la curva
  nunca salta.
--]]

Physics = {}

-- Estado interno
local tramos = {}              -- historial de tramos de simulación
local reloj  = 0               -- tiempo global en segundos
local R, C, V = 1000, 0.001, 5 -- parámetros actuales

-- ─── Matemática ───────────────────────────────────────────────

local function tau(r, c)
    return math.max(r * c, 1e-12)
end

local function vc_en_tramo(tramo, t)
    local dt = t - tramo.t0
    return tramo.v_dst + (tramo.vc0 - tramo.v_dst) * math.exp(-dt / tau(tramo.R, tramo.C))
end

-- ─── Tramos ───────────────────────────────────────────────────

local function tramo_activo(t)
    local vigente = tramos[1]
    for _, tr in ipairs(tramos) do
        if tr.t0 <= t then vigente = tr else break end
    end
    return vigente
end

local function nuevo_tramo(vc_inicio)
    table.insert(tramos, { t0=reloj, vc0=vc_inicio, v_dst=V, R=R, C=C })
end

-- ─── Interfaz pública ─────────────────────────────────────────

function Physics.init(r, c, v)
    R, C, V = r, c, v
    reloj   = 0
    tramos  = {}
    nuevo_tramo(0)   -- capacitor empieza descargado
end

function Physics.update(dt, velocidad)
    reloj = reloj + dt * velocidad
end

function Physics.vc_actual()
    if #tramos == 0 then return 0 end
    return vc_en_tramo(tramo_activo(reloj), reloj)
end

function Physics.vc_en(t)
    if #tramos == 0 then return 0 end
    return vc_en_tramo(tramo_activo(t), t)
end

function Physics.cambiar_parametros(r, c, v)
    local vc = Physics.vc_actual()
    R, C, V = r, c, v
    nuevo_tramo(vc)
end

function Physics.reset(r, c, v)
    R, C, V = r, c, v
    reloj  = 0
    tramos = {}
    nuevo_tramo(0)
end

-- Getters
function Physics.tiempo()    return reloj          end
function Physics.tau()       return tau(R, C)      end
function Physics.v_destino() return V              end
function Physics.r()         return R              end
function Physics.c()         return C              end

function Physics.rango_v()
    local vmin, vmax = 0, 0
    for _, tr in ipairs(tramos) do
        vmin = math.min(vmin, tr.v_dst, tr.vc0)
        vmax = math.max(vmax, tr.v_dst, tr.vc0)
    end
    local vc = Physics.vc_actual()
    return math.min(vmin, vc) - 0.5,
           math.max(vmax, vc) + 0.5
end