#version 300 es

layout (location = 0)in vec3 v_position;
layout (location = 1)in vec3 v_normal;
layout (location = 2)in vec2 v_uv;
layout (location = 3)in vec3 v_tan;
layout (location = 4)in vec3 v_bitan;

out vec2 f_uv;
out vec3 w_normal;  //normal in world space->frag
out vec3 w_position;//..
out vec3 w_tan;     //..
out vec3 w_bitan;   //transfer data instead calculate in fragment shader  faster
out vec3 w_view;    //eye direction in world space


uniform mat4 MVP;   // projection * view * model
uniform mat4 M;     //model matrix
uniform mat4 TIM;   //transpose and inverse model matrix
uniform mat4 V; //view matrix
uniform vec3 camera_position;

void main()
{
    gl_Position = MVP * vec4(v_position, 1.0);
    
    f_uv = v_uv;
    //world space attributes
    w_position = vec3(M * vec4(v_position, 1.0));
    w_normal = mat3(TIM) * v_normal;
    w_view = camera_position - w_position;
    w_tan = mat3(TIM) * v_tan;
    w_bitan = mat3(TIM) * v_bitan;
}