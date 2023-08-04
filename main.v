module main
import gg
import gx
import rand as rd

const (
    win_width    = 901
    win_height   = 901
    bg_color     = gx.black

	
    pixel_size = 4
	nb_tiles = 200
	sim_size = pixel_size * nb_tiles
    text_cfg = gx.TextCfg{color: gx.green, size: 20, align: .left, vertical_align: .top}
	color_map = {
    	0: gx.white
    	1: gx.Color{66, 135, 245, 255}
		2: gx.black
	}
)



struct App {
mut:
    gg    &gg.Context = unsafe { nil }
	tiles_states [][]u8 = [][]u8{len:nb_tiles, cap:nb_tiles, init:[]u8{len:nb_tiles, cap:nb_tiles, init:u8(0)}}  // [Ligne][colonne]
}


fn main() {
    mut app := &App{
        gg: 0
    }
    app.gg = gg.new_context(
        width: win_width
        height: win_height
        create_window: true
        window_title: '- Application -'
        user_data: app
        bg_color: bg_color
        frame_fn: on_frame
        event_fn: on_event
        sample_count: 6
    )

    //lancement du programme/de la fenêtre
	mut c := 0
	mut x := 0
	mut y := 0
	for i, mut line in app.tiles_states{
		for j, mut tile in line{
			tile = int(rd.int_in_range(0,28) or {panic(err)}/10)
			if tile == 0{
				c += 1
			}
			if tile == 1{
				x += 1
			}
			if tile == 2{
				y += 1
			}
		}
	}
	println(c)
	println(x)
	println(y)
    app.gg.run()
}


fn on_frame(mut app App) {
	//Process

	mut water := 0
	for i := app.tiles_states.len-1; i >= 0; i-- {
		for j, mut tile in app.tiles_states[i]{
			if tile == 1{
				water += 1
				if i != app.tiles_states.len-1 && app.tiles_states[i+1][j] == 0{
					tile = 0
					app.tiles_states[i+1][j] = 1
				}else{
					if  j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{ // droite libre (+)
						if j != 0 && app.tiles_states[i][j-1] == 0{ // deux cotés libres
							if rd.int_in_range(0,2) or {panic(err)} == 0{
								tile = 0
								app.tiles_states[i][j+1] = 1
							}else{
								tile = 0
								app.tiles_states[i][j-1] = 1
							}
						}else{ // que le droite (+)
							if rd.int_in_range(0,2) or {panic(err)} == 0{// si on enlevais le random ca coulerai tout le temps vers le coté libre
								tile = 0
								app.tiles_states[i][j+1] = 1
							}
						}
					}else{ // pas le droite (+)
						if j != 0 && app.tiles_states[i][j-1] == 0{  // que le gauche (-)
							if rd.int_in_range(0,2) or {panic(err)} == 0{// si on enlevais le random ca coulerai tout le temps vers le coté libre
								tile = 0
								app.tiles_states[i][j-1] = 1
							}
						}
						//Aucun des deux
						if i != 0 && app.tiles_states[i-1][j] == 0 && rd.int_in_range(0,10) or {panic(err)} == 0{
							tile = 0
							app.tiles_states[i-1][j] = 1
						}
					}
				}
			}
		}
	}

    //Draw
	for i, line in app.tiles_states{
		app.gg.begin()
		for j, tile in line{
			app.gg.draw_square_filled(j*pixel_size+30, i*pixel_size+20, pixel_size, color_map[tile])
		}
		app.gg.end(how: .passthru)
	}
	app.gg.begin()
	app.gg.show_fps()
	app.gg.draw_rect_filled(40, 0, 200, 20, gx.black)
	app.gg.draw_text(40, 0, "Water particles: ${water}", text_cfg)
	app.gg.end(how: .passthru)
}

fn on_event(e &gg.Event, mut app App){
    match e.typ {
        .key_down {
            match e.key_code {
                .escape {app.gg.quit()}
                else {}
            }
        }
        .mouse_up {
            match e.mouse_button{
                .left{}
                else{}
        }}
        else {}
    }
}