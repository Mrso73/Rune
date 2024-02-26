package rune

import "core:fmt"

import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"

Mesh :: struct {
    vbo: u32,
    ebo: u32,
    vao: u32,

    program: u32,
    textureID: u32,
	indices_amount: i32,
    model_matrix: matrix[4,4]f32,
	uniforms: map[string]gl.Uniform_Info,
}

Vertex :: struct {
    pos: glm.vec3,
    col: glm.vec3,
    tex: glm.vec2,
}

Texture :: struct {
    data: [^]byte,
    width: i32,
    height: i32,
}


CreateCustomMesh :: proc(position: [3]f32, vertices: [dynamic]Vertex, indices: [dynamic]u16, txtr: Texture, vs_source := d_vertex_source, fs_source := d_fragment_source) -> Mesh {

    // Use the vertex and fragment shader to create a shader program
    program, program_ok := gl.load_shaders_source(vs_source, fs_source)
    if !program_ok {
		return Mesh{}
	}
    uniforms := gl.get_uniforms_from_program(program)

    // Create a texture
    textureID: u32
    gl.GenTextures(1, &textureID);
    gl.BindTexture(gl.TEXTURE_2D, textureID);

    if txtr.data != nil {
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, txtr.width, txtr.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, txtr.data)
        gl.GenerateMipmap(gl.TEXTURE_2D);
    } else {
        fmt.println("failed to load texture")
    }
     
    // -------------------------

    // Create a model matrix 
    pos := glm.vec3{ position[0], position[1], position[2] }
    model_matrix := glm.mat4{
        1,  0,  0,  0,
        0,  1,  0,  0,
        0,  0,  1,  0,
        0,  0,  0,  1,
    }
    model_matrix[3].xyz = pos.xyz

    // -------------------------    

    VAO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.BindVertexArray(VAO)


    VBO: u32
	gl.GenBuffers(1, &VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)
    
    // postion attribute
    gl.EnableVertexAttribArray(0)   
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))

    // color attribute
    gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	
    // texture coordinate attribute
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, tex))

     
    EBO: u32
    gl.GenBuffers(1, &EBO)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)

    return Mesh {
        vbo = VBO,
        ebo = EBO,
        vao = VAO,

        program = program,
        textureID = textureID,
        indices_amount = i32(len(indices)),
        model_matrix = model_matrix,
        uniforms = uniforms,
    }
}


DrawMesh :: proc(mesh: ^Mesh, camera: ^Camera) {
    gl.UseProgram(mesh.program)
    
    u_transform := GetProjectionMatrix(camera) * GetViewMatrix(camera) * mesh.model_matrix // Calculate the Model View Projection

    gl.UniformMatrix4fv(mesh.uniforms["mvp"].location, 1, false, &u_transform[0, 0]) // Apply the MVP matrix

    gl.ActiveTexture(gl.TEXTURE0) // Activate the texture unit first before binding texture
    gl.BindTexture(gl.TEXTURE_2D, mesh.textureID) // Bind the texture

    textureUniformLoc := gl.GetUniformLocation(mesh.program, "our_texture")
    gl.Uniform1i(textureUniformLoc, 0) // Texture unit 0

    gl.BindVertexArray(mesh.vao)
	gl.DrawElements(gl.TRIANGLES, mesh.indices_amount, gl.UNSIGNED_SHORT, nil) // Draw the mesh
}


DestroyMesh :: proc(mesh: ^Mesh) {
    gl.DeleteProgram(mesh.program)
    delete(mesh.uniforms)

    gl.DeleteTextures(1, &mesh.textureID)

    gl.DeleteVertexArrays(1, &mesh.vao)
    gl.DeleteBuffers(1, &mesh.vbo)
    gl.DeleteBuffers(1, &mesh.ebo)
}

d_vertex_source := `#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec3 a_color;

uniform mat4 mvp;

out vec3 v_color;

void main() {	
	gl_Position = mvp * vec4(a_position, 1.0);
	v_color = a_color;
}
`

d_fragment_source := `#version 330 core

in vec3 v_color;

out vec3 frag_color;

void main() {
	frag_color = v_color;
}
`