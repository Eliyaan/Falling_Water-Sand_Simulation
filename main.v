module main

import gg
import gx
import rand as rd // do not remove, using default_rng from it
import math.bits
import math

const (
    win_width    = 740
    win_height   = 740
    bg_color     = gx.rgb(148, 226, 213)

	
    pixel_size = 1
	nb_tiles = 680
	refresh = 65000
	sim_size = pixel_size * nb_tiles
    text_cfg = gx.TextCfg{color: gx.green, size: 20, align: .left, vertical_align: .top}
	x_offset = 30
	y_offset = 30
	blue = u32(0xFFFF_B700)
	blue_ni = int(0x00B7_FFFF) //non inverted
	black = u32(0x0000_00FF)
	black_ni = int(0x0000_00FF) //non inverted
	orange = u32(0xFF42_87F5)
	white = u32(0xFFFF_FFFF)
)

[inline]
fn color(nb u8) gx.Color{
	return match nb{
		0 {gx.white}
    	1 {gx.Color{66, 135, 245, 255}}  // 0x4287F5FF
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
	output := min + u32n(u32(max-min))
	assert output < max
	assert output >= min
	return output
}

struct App {
mut:
    gg    &gg.Context = unsafe { nil }
	tiles_states [nb_tiles][nb_tiles]u8 = [nb_tiles][nb_tiles]u8{init:[nb_tiles]u8{ init:u8(0)}}  // [Ligne][colonne]
	istream_idx int
	screen_pixels [nb_tiles][nb_tiles]u32 = [nb_tiles][nb_tiles]u32{init:[nb_tiles]u32{ init:u32(white)}}
	water_tiles_coords [][]int 
	wall_tiles_coords [][]int 
	mouse_held bool
	mouse_coords [2]int 
	paint_type int = 1
	paint_size int = 20
}


fn main() {
    mut app := &App{
        gg: 0
    }
    app.gg = gg.new_context(
        width: win_width
        height: win_height
        create_window: true
        window_title: 'Water/Sand simutation'
        user_data: app
        bg_color: bg_color
		init_fn: graphics_init
        frame_fn: on_frame
        event_fn: on_event
    )

    //lancement du programme/de la fenêtre
    app.gg.run()
}



//[direct_array_access]
fn on_frame(mut app App) {
	//painting
	app.paint_tiles()

	//Process
	app.process_tiles()
	
    //Draw
	app.gg.begin()
	// white square around the paint type chooser
	app.gg.draw_square_filled(3, 35*(app.paint_type), 24, gx.white)

	app.gg.draw_square_filled(5, 37, 20, gx.hex(blue_ni))
	app.gg.draw_square_filled(5, 72, 20, gx.hex(black_ni))
	app.draw()
	//app.gg.show_fps()
	//app.gg.draw_text(40, 0, "Paint size: ${app.paint_size/2}, Paint type: ${app.paint_type}, Nb water particles: ${app.water_tiles_coords.len}", text_cfg)
	app.gg.end()
}

fn (mut app App) process_tiles() {
	for mut w_coo in app.water_tiles_coords{
		i := w_coo[0]
		j := w_coo[1]
		if i < app.tiles_states.len-1 && app.tiles_states[i+1][j] == 0{ //bas libre
			if i != 0 && app.tiles_states[i-1][j] == 0{ // Haut libre = descendre
				if i < app.tiles_states.len-2 && app.tiles_states[i+2][j] == 0{
					app.tiles_states[i][j]= 0
					app.screen_pixels[i][j] = white
					app.tiles_states[i+2][j] = 1
					app.screen_pixels[i+2][j] = blue
					w_coo[0] += 2
				}else if i < app.tiles_states.len-1{
					app.tiles_states[i][j]= 0
					app.screen_pixels[i][j] = white
					app.tiles_states[i+1][j] = 1
					app.screen_pixels[i+1][j] = blue
					w_coo[0] += 1
				}
			}else{ // haut plein
				if j != 0 && app.tiles_states[i][j-1] == 0{  // gauche libre
					if j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{ // deux cotés libres = descendre
						if i != app.tiles_states.len-2 && app.tiles_states[i+2][j] == 0{
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i+2][j] = 1
							app.screen_pixels[i+2][j] = blue
							w_coo[0] += 2
						}else{
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i+1][j] = 1
							app.screen_pixels[i+1][j] = blue
							w_coo[0] += 1
						}
					}else{ // droite oqp et gauche libre et haut plein
						if custom_int_in_range(0, 2) == 0{
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i+1][j] = 1
							app.screen_pixels[i+1][j] = blue
							w_coo[0] += 1
						}else if custom_int_in_range(0, 2) == 0{
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i][j-1] = 1
							app.screen_pixels[i][j-1] = blue
							w_coo[1] -= 1
						}
					}
				}else{ // gauche oqp
					if j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{ // droite libre et gauche oqp et haut plein
						if custom_int_in_range(0, 2) == 0{
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i+1][j] = 1
							app.screen_pixels[i+1][j] = blue
							w_coo[0] += 1
						}else if custom_int_in_range(0, 2) == 0{
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i][j+1] = 1
							app.screen_pixels[i][j+1] = blue
							w_coo[1] += 1
						}
					}else{ // gauche et droite oqp et haut plein descendre parfois
						app.tiles_states[i][j]= 0
						app.screen_pixels[i][j] = white
						app.tiles_states[i+1][j] = 1
						app.screen_pixels[i+1][j] = blue
						w_coo[0] += 1
					}						
				}
			}
		}else{ // bas plein
			if j != 0 && app.tiles_states[i][j-1] == 0{  // gauche libre
				if j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{ // deux cotés libres 
					if i < app.tiles_states.len-1 && app.tiles_states[i+1][j+1] == 0 { // diag bas droite libre
						if app.tiles_states[i+1][j-1] == 0 {  // diag bas gauche libre
							if custom_int_in_range(0, 2) == 0{
								app.tiles_states[i][j]= 0
								app.screen_pixels[i][j] = white
								app.tiles_states[i+1][j+1] = 1
								app.screen_pixels[i+1][j+1] = blue
								w_coo[0] += 1
								w_coo[1] += 1
							}else{
								app.tiles_states[i][j]= 0
								app.screen_pixels[i][j] = white
								app.tiles_states[i+1][j-1] = 1
								app.screen_pixels[i+1][j-1] = blue
								w_coo[0] += 1
								w_coo[1] -= 1
							}
						}else{ // que diag bas droite libre
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i+1][j+1] = 1
							app.screen_pixels[i+1][j+1] = blue
							w_coo[0] += 1
							w_coo[1] += 1
						}
					}else{
						if i < app.tiles_states.len-1 && app.tiles_states[i+1][j-1] == 0 {  // que diag bas gauche libre
							app.tiles_states[i][j]= 0
							app.screen_pixels[i][j] = white
							app.tiles_states[i+1][j-1] = 1
							app.screen_pixels[i+1][j-1] = blue
							w_coo[0] += 1
							w_coo[1] -= 1
						}else{ // aucune diag libre mais 2 cotés libres
							if custom_int_in_range(0,2) == 0{
								app.tiles_states[i][j]= 0
								app.screen_pixels[i][j] = white
								app.tiles_states[i][j+1] = 1
								app.screen_pixels[i][j+1] = blue
								w_coo[1] += 1
							}else{
								app.tiles_states[i][j]= 0
								app.screen_pixels[i][j] = white
								app.tiles_states[i][j-1] = 1
								app.screen_pixels[i][j-1] = blue
								w_coo[1] -= 1
							}
						}
					}
				}else{ // que gauche
					app.tiles_states[i][j]= 0
					app.screen_pixels[i][j] = white
					app.tiles_states[i][j-1] = 1
					app.screen_pixels[i][j-1] = blue
					w_coo[1] -= 1
				}
			}else{ // pas gauche
				if j != nb_tiles-1 && app.tiles_states[i][j+1] == 0{// que droite libre
						app.tiles_states[i][j]= 0
						app.screen_pixels[i][j] = white
						app.tiles_states[i][j+1] = 1
						app.screen_pixels[i][j+1] = blue
						w_coo[1] += 1
				}
			}
		}
	}
}

fn (mut app App) paint_tiles() {
	if app.mouse_held{
		for l in -app.paint_size..1+app.paint_size{
			for c in -app.paint_size..1+app.paint_size{
				if l*l+c*c < (app.paint_size*app.paint_size){
					if app.mouse_coords[0]+c < nb_tiles && app.mouse_coords[0]+c >= 0 && app.mouse_coords[1]+l < nb_tiles && app.mouse_coords[1]+l >= 0 {
						if app.paint_type == 1 && app.tiles_states[app.mouse_coords[1]+l][app.mouse_coords[0]+c] == 0{
							app.tiles_states[app.mouse_coords[1]+l][app.mouse_coords[0]+c] = 1
							app.screen_pixels[app.mouse_coords[1]+l][app.mouse_coords[0]+c] = blue
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
							app.screen_pixels[app.mouse_coords[1]+l][app.mouse_coords[0]+c] = black
							app.wall_tiles_coords << [[app.mouse_coords[1]+l, app.mouse_coords[0]+c]]
						}
					}
				}
			}
		}
	}
}

fn (mut app App) draw() {
	mut istream_image := app.gg.get_cached_image_by_idx(app.istream_idx)
	istream_image.update_pixel_data(unsafe { &u8(&app.screen_pixels) })
	app.gg.draw_image(x_offset, y_offset, nb_tiles, nb_tiles, istream_image)
}


fn graphics_init(mut app App) {
	app.istream_idx = app.gg.new_streaming_image(nb_tiles, nb_tiles, 4, pixel_format: .rgba8)
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
