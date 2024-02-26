package rune

import "core:fmt"
import "core:c"

import gl "vendor:OpenGL"


Init :: proc(GL_VERSION_MAJOR, GL_VERSION_MINOR: int, set_proc_address: gl.Set_Proc_Address_Type) {

    // load the OpenGL procedures once an OpenGL context has been established
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, set_proc_address) 

    // -------------------------------------

    gl.Enable(gl.DEPTH_TEST);
    gl.DepthFunc(gl.LESS);
    gl.Enable(gl.CULL_FACE);
}

// ------------------------------------------------------------------------------

ClearWindow :: proc(xywh: [4]i32, clear_color: [4]f32){
    gl.Viewport(xywh[0], xywh[1], xywh[2], xywh[3])
	gl.ClearColor(clear_color[0], clear_color[1], clear_color[2], clear_color[3])
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

Viewport :: proc(x, y, width, height: i32) {
    gl.Viewport(x, y, width, height)
} 


SetPolygonMode :: proc(i: i32) {
    switch i {
    case 0:
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
    case 1:
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
    }
    
}