module main
//check si y'a de l'air dans les lignes proches pour voir si update requise ou pas
// implementer les nouveaux déplacements
// trouver pk ca skip des particules ? #help ?
// nouveau syst de rendu sinon avec rect 


import sokol.sgl
import gg
import gx
import rand as rd
import math.bits
import math

const (
    win_width    = 1041
    win_height   = 1041
    bg_color     = gx.black

	
    pixel_size = 1
	nb_tiles = 700
	refresh = 65000
	sim_size = pixel_size * nb_tiles
    text_cfg = gx.TextCfg{color: gx.green, size: 20, align: .left, vertical_align: .top}
	x_offset = 30
	y_offset = 20
)

[inline]
fn color(nb u8) gx.Color{
	return match nb{
		0 {gx.white}
    	1 {gx.Color{66, 135, 245, 255}}
		2 {gx.black}
		else{gx.red}
	}
}

[inline]
fn u32n(max u32) int{
	mask := (u32(1) << (bits.len_32(max) + 1)) - 1
	for {
		value := default_rng.u32() & mask
		if value < max {
			return int(value)
		}
	}
	return 0
}

[inline]
fn custom_int_in_range(min int, max int) int{
	return min + u32n(u32(max-min))
}

struct App {
mut:
    gg    &gg.Context = unsafe { nil }
	tiles_states [][]u8 = [][]u8{len:nb_tiles, cap:nb_tiles, init:[]u8{len:nb_tiles, cap:nb_tiles, init:u8(0)}}  // [Ligne][colonne]
	water_tiles_coords [][]int 
	wall_tiles_coords [][]int 
	mouse_held bool
	mouse_coords [2]int 
	paint_type int = 1
	paint_size int = 6
}


fn main() {
    mut app := &App{
        gg: 0
    }
    app.gg = gg.new_context(
        width: win_width
        height: win_height
        create_window: true
		fullscreen: true
        window_title: '- Application -'
        user_data: app
        bg_color: bg_color
        frame_fn: on_frame
        event_fn: on_event
    )

    //lancement du programme/de la fenêtre
	/*
	mut w := 0
	mut x := 0
	mut y := 0
	for i, mut line in app.tiles_states{
		for j, mut tile in line{
			rnd := custom_int_in_range(0,20)
			if rnd < 10{
				w += 1
			}else if rnd < 20{
				tile = 1
				app.water_tiles_coords << [[i, j]]
				x += 1
			}else if rnd < 30{
				tile = 2
				app.wall_tiles_coords << [[i, j]]
				y += 1
			}
		}
	}
	println(w)
	println(x)
	println(y)*/
    app.gg.run()
}

[direct_array_access]
fn on_frame(mut app App) {
	//painting
	if app.mouse_held{
		for l in -app.paint_size..1+app.paint_size{
			for c in -app.paint_size..1+app.paint_size{
				if l*l+c*c < (app.paint_size*app.paint_size){
					if app.mouse_coords[0]+c < nb_tiles && app.mouse_coords[0]+c >= 0 && app.mouse_coords[1]+l < nb_tiles && app.mouse_coords[1]+l >= 0 {
						if app.paint_type == 1 && app.tiles_states[app.mouse_coords[1]+l][app.mouse_coords[0]+c] == 0{
							app.tiles_states[app.mouse_coords[1]+l][app.mouse_coords[0]+c] = 1
							if app.water_tiles_coords.len == 0 {
								app.water_tiles_coords << [[app.mouse_coords[1]+l, app.mouse_coords[0]+c]]
							}else{
								rnd := custom_int_in_range(0, app.water_tiles_coords.len)
								switch_tmp := app.water_tiles_coords[rnd]
								app.water_tiles_coords[rnd] = [app.mouse_coords[1]+l, app.mouse_coords[0]+c]
								app.water_tiles_coords << switch_tmp
							}
						}else if app.paint_type == 2 && app.tiles_states[app.mouse_coords[1]+l][app.mouse_coords[0]+c] == 0{
							app.tiles_states[app.mouse_coords[1]+l][app.mouse_coords[0]+c] = 2
							app.wall_tiles_coords << [[app.mouse_coords[1]+l, app.mouse_coords[0]+c]]
						}
					}
				}
			}
		}
	}

	//Process
	for mut w_coo in app.water_tiles_coords{
		i := w_coo[0]
		j := w_coo[1]
		if app.tiles_states[i][j] == 1{
			if i != app.tiles_states.len-1 && app.tiles_states[i+1][j] == 0{ // Haut
				if  j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{ // droite libre (+)
					if j != 0 && app.tiles_states[i][j-1] == 0{ // deux cotés libres + haut = descendre
						app.tiles_states[i][j]= 0
						app.tiles_states[i+1][j] = 1
						w_coo[0] += 1
					}else{ // que le droite + haut
						if custom_int_in_range(0,2) == 0{
							app.tiles_states[i][j]= 0
							app.tiles_states[i][j+1] = 1
							w_coo[1] += 1
						}else{
							app.tiles_states[i][j]= 0
							app.tiles_states[i+1][j] = 1
							w_coo[0] += 1
						}
					}
				}else{ // pas le droite (+)
					if j != 0 && app.tiles_states[i][j-1] == 0{  // gauche + haut
						if custom_int_in_range(0,2) == 0{
							app.tiles_states[i][j]= 0
							app.tiles_states[i][j-1] = 1
							w_coo[1] -= 1
						}else{
							app.tiles_states[i][j]= 0
							app.tiles_states[i+1][j] = 1
							w_coo[0] += 1
						}
					}else{
						//Aucun des deux, que le haut = descente
						app.tiles_states[i][j]= 0
						app.tiles_states[i+1][j] = 1
						w_coo[0] += 1
					}
				}
			}else{
				if  j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{ // droite libre (+)
					if j != 0 && app.tiles_states[i][j-1] == 0{ // deux cotés libres
						if custom_int_in_range(0,2) == 0{
							app.tiles_states[i][j]= 0
							app.tiles_states[i][j+1] = 1
							w_coo[1] += 1
						}else{
							app.tiles_states[i][j]= 0
							app.tiles_states[i][j-1] = 1
							w_coo[1] -= 1
						}
					}else{ // que le droite (+)
						app.tiles_states[i][j]= 0
						app.tiles_states[i][j+1] = 1
						w_coo[1] += 1
					}
				}else{ // pas le droite (+)
					if j != 0 && app.tiles_states[i][j-1] == 0{  // que le gauche (-)
						app.tiles_states[i][j]= 0
						app.tiles_states[i][j-1] = 1
						w_coo[1] -= 1
					}else{
						//Aucun des deux
						if i != 0 && app.tiles_states[i-1][j] == 0 && custom_int_in_range(0,5) == 0{
							app.tiles_states[i][j]= 0
							app.tiles_states[i-1][j] = 1
							w_coo[0] -= 1
						}
					}
				}
			}
		}
	}

    //Draw
	app.gg.begin()
	app.gg.draw_rect_filled(x_offset, y_offset-1, pixel_size*nb_tiles, pixel_size*nb_tiles, color(0))
		app.gg.end(how: .passthru)
	mut i := 0
	for (i+1)*refresh < app.water_tiles_coords.len{  // faire new syst avec check si la ligne est dj à jour (la même qu'à la frame d'avant) pi ptet essayer les rectangles de plusieurs pixels
		app.gg.begin()
		custom_draw_pixels(app.water_tiles_coords#[i*refresh..i+1*refresh], gx.Color{66, 135, 245, 255}, app.gg)
		i += 1
		app.gg.end(how: .passthru)
	}
	app.gg.begin()
	custom_draw_pixels(app.water_tiles_coords#[i*refresh..], gx.Color{66, 135, 245, 255}, app.gg)
	app.gg.end(how: .passthru)

	mut j := 0
	for (j+1)*refresh < app.wall_tiles_coords.len{  // New syst où pas de réaffichage du mur sis il était dj là avant
		app.gg.begin()
		custom_draw_pixels(app.wall_tiles_coords#[j*refresh..j+1*refresh], gx.black, app.gg)
		j += 1
		app.gg.end(how: .passthru)
	}
	app.gg.begin()
	custom_draw_pixels(app.wall_tiles_coords#[j*refresh..], gx.black, app.gg)
	app.gg.end(how: .passthru)
	
	app.gg.begin()
	app.gg.show_fps()
	app.gg.draw_rect_filled(40, 0, 220, 19, gx.black)
	app.gg.draw_text(40, 0, "Paint size: ${app.paint_size/2}, Paint type: ${app.paint_type}", text_cfg)
	app.gg.end(how: .passthru)
}

[direct_array_access; inline]
fn custom_draw_pixels(points [][]int, c gx.Color, ctx &gg.Context) {
	sgl.c4b(c.r, c.g, c.b, c.a)
	sgl.begin_points()
	for point in points {
		x, y := point[0], point[1]
		sgl.v2f(y * ctx.scale + x_offset, x * ctx.scale + y_offset)
	}
	sgl.end()
}

[inline]
fn custom_draw_pixel(x f32, y f32, c gx.Color, ctx &gg.Context) {
	sgl.c4b(c.r, c.g, c.b, c.a)

	sgl.begin_points()
	sgl.v2f(x * ctx.scale, y * ctx.scale)
	sgl.end()
}


fn on_event(e &gg.Event, mut app App){
    match e.typ {
        .key_down {
            match e.key_code {
                .escape {app.gg.quit()}
				.up{app.paint_type += 1}
				.down{app.paint_type -= 1}
                else {}
            }
        }
        .mouse_up {
            match e.mouse_button{
                .left{app.mouse_held = false}
                else{}
        	}
		}
        .mouse_down {
            match e.mouse_button{
                .left{app.mouse_held = true}
                else{}
        	}
		}
		.mouse_scroll{
			app.paint_size += int(math.sign(e.scroll_y))*2
		}
        else {}
    }
	if app.mouse_held{
		app.mouse_coords[0] = int(e.mouse_x) - x_offset
		app.mouse_coords[1] = int(e.mouse_y) - y_offset
	}
}
