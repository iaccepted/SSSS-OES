#version 300 es
precision mediump float;

out vec4 color;

void main()
{
    //on fly
    color = vec4(gl_FragCoord.www, 1.0);
}