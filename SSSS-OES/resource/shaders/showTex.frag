#version 300 es
precision mediump float;

in vec2 f_uv;

layout(location = 0)out vec4 color;

uniform sampler2D tex;

void main()
{
    color = vec4(texture(tex, f_uv).rgb, 1.0f);
    
//    if (color.r >= 1.0f)
//    {
//        color.rgb = vec3(1.0f, 1.0f, 1.0f);
//    }
//    else
//    {
//        color.rgb *= 0.2;
//    }
}