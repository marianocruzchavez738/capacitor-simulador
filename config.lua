-- luacheck: globals CFG
CFG = {
    bg_color = {0.06, 0.09, 0.18},

    circuito = {
        x=70, y=70, scale_x=0.7, scale_y=0.7,
        label_color     = {0.95, 0.95, 0.3},
        label_r  = {x=250, y=50},
        label_c  = {x=490, y=195},
        label_v  = {x=40,  y=195},
        label_vc = {x=150, y=300},
    },

    panel = {
        x=560, y=30, w=215, h=335,
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
        bg_color      = {0.03, 0.05, 0.12},
        border_color  = {0.25, 0.50, 0.95},
        grid_color    = {0.12, 0.18, 0.32},
        label_color   = {0.60, 0.72, 0.92},
        curve_real    = {0.18, 0.82, 1.00},
        dot_color     = {1.00, 0.28, 0.28},
        tau_color     = {0.38, 1.00, 0.52},
        ventana       = 10,
    },
}