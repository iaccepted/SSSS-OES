#version 300 es

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;

out vec2 f_uv;

void main()
{
    gl_Position = vec4(position, 1.0);
    f_uv = vec2(uv.x, uv.y);
}