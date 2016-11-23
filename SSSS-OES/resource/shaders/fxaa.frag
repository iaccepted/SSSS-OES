//
//  blur.fsh
//  shadow
//
//  Created by iaccepted on 15/6/8.
//  Copyright (c) 2015年 iaccepted. All rights reserved.
//
#version 300 es
precision highp float;
precision mediump sampler2D;

in vec2 f_uv;

uniform sampler2D colorTex;
uniform vec2 textSize;//width and height

#define FXAA_REDUCE_MIN   (1.0 / 128.0)
#define FXAA_REDUCE_MUL   (1.0 / 8.0)
#define FXAA_SPAN_MAX      8.0

#define FXAA_EDGE_THRESHOLD (1.0/8.0)
#define FXAA_EDGE_THRESHLOD_MIN (1.0/32.0)

layout (location = 0)out vec4 ocolor;

void main()
{
    vec2 rate = 1.0 / textSize;
    
    vec4 color;
    vec3 rgbSW = texture(colorTex, f_uv + (vec2(-1.0, -1.0) * rate)).xyz;
    vec3 rgbSE = texture(colorTex, f_uv + (vec2(1.0, -1.0) * rate)).xyz;
    vec3 rgbNW = texture(colorTex, f_uv + (vec2(-1.0, 1.0) * rate)).xyz;
    vec3 rgbNE = texture(colorTex, f_uv + (vec2(1.0, 1.0) * rate)).xyz;

    vec4 textColor = texture(colorTex, f_uv);
    vec3 rgbM = textColor.xyz;
    float alpha = textColor.w;
    
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM = dot(rgbM, luma);
    float lumaMin = min(lumaM, min(min(lumaNE, lumaNW), min(lumaSE, lumaSW)));
    float lumaMax = max(lumaM, max(max(lumaNE, lumaNW), max(lumaSE, lumaSW)));
    
    float range = lumaMax - lumaMin;
    
    if (range < max(FXAA_EDGE_THRESHLOD_MIN, lumaMax * FXAA_EDGE_THRESHOLD))
    {
        ocolor = textColor;
        return;
    }
    
    //calculate the edge direction
    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
//    dir.y = ((lumaNE + lumaSE) - (lumaNW + lumaSW));
    dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));
    
    float dirReduce = max((lumaNW + lumaNE + lumaSE + lumaSW) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    
    dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX), dir * rcpDirMin)) / textSize;
//    dir = dir * rcpDirMin / textSize;
    
    
    vec3 rgbA = 0.5 * (texture(colorTex, f_uv + dir * (1.0 / 3.0 - 0.5)).xyz +
                       texture(colorTex, f_uv + dir * (2.0 / 3.0 - 0.5)).xyz);
    
    vec3 rgbB = rgbA * 0.5 + 0.25 * (texture(colorTex, f_uv + dir * (-0.5)).xyz +
                                     texture(colorTex, f_uv + dir * (0.5)).xyz);
    
    float lumaB = dot(rgbB, luma);
    
    if ((lumaB < lumaMin) || (lumaB > lumaMax))
    {
        color = vec4(rgbA, alpha);
    }
    else{
        color = vec4(rgbB, alpha);
    }
    ocolor = color;
}