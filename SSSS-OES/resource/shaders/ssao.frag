#version 300 es

precision highp float;
precision mediump sampler2D;

in vec2 f_uv;

uniform sampler2D depthTex;
uniform sampler2D normalTex;
uniform sampler2D positionTex;
uniform sampler2D colorTex;
uniform mat4 iP;   //inverse of projection
uniform vec2 texSize;
uniform float radius;


float distanceThreshold = 5.0;

const int samplesCount = 12;

vec2 poisson[samplesCount];

layout (location = 0)out vec4 ocolor;


//0 vec2( -0.94201624,  -0.39906216 );
//1    vec2(  0.94558609, -0.76890725),
//2	vec2( -0.094184101, -0.92938870 ),
//3    vec2(  0.34495938,   0.29387760 ),
//4    vec2( -0.91588581,   0.45771432 ),
//5    vec2( -0.81544232,  -0.87912464 ),
//6    vec2( -0.38277543,   0.27676845 ),
//7    vec2(  0.97484398,   0.75648379 ),
//8    vec2(  0.44323325,  -0.97511554 ),
//9    vec2(  0.53742981,  -0.47373420 ),
//10    vec2( -0.26496911,  -0.41893023 ),
//11    vec2(  0.79197514,   0.19090188 ),
// 12   vec2( -0.24188840,   0.99706507 ),
// 13   vec2( -0.81409955,   0.91437590 ),
//  14  vec2(  0.19984126,   0.78641367 ),
//  15  vec2(  0.14383161,  -0.14100790 )


////重建点在view space中的坐标
vec3 calculatePosition(in vec2 uv2)
{
//    highp vec3 viewRay = vec3( -(uv2.x * 2.0 - 1.0) * winParames[0], uv2.y * 2.0 - 1.0, P[1][1]);
//    viewRay = normalize(viewRay);
//    highp float d = mix(winParames[1], winParames[2], texture2D(depthTex, uv2).r);
//    highp float t = d / viewRay.z;
//    return vec3( viewRay.x * t, viewRay.y * t, d );
    float z = texture(depthTex, uv2).r;
    vec3 scoord = vec3(uv2 * 2.0 - 1.0, z);
    vec4 co = iP * vec4(scoord, 1.0);
    co.xyz /= co.w;
    return co.xyz;
}

////重建点的法线信息
//vec3 minDiff(vec3 p, vec3 pa, vec3 pb)
//{
//    vec3 va = pa - p;
//    vec3 vb = pb - p;
//    
//    return (dot(va, va) < dot(vb, vb)) ? (va) : (vb);
//}
//
vec3 calculateNormal(in vec3 pos)
{
//    vec2 offset = 1.0 / texSize;
//    vec3 pr, pl, pt, pb;
//    
//    pr = calculatePosition(f_uv + vec2(offset.x, 0.0));
//    pl = calculatePosition(f_uv + vec2(-offset.x, 0.0));
//    pt = calculatePosition(f_uv + vec2(0.0, offset.y));
//    pb = calculatePosition(f_uv + vec2(0.0, -offset.y));
//    
//    vec3 pdux = normalize(minDiff(pos, pr, pl));
//    vec3 pduy = normalize(minDiff(pos, pt, pb));
//    
//    return cross(pdux, pduy);
    return normalize(cross(dFdx(pos), dFdy(pos)));
}

//采样偏移，poisson分布的随机数
void initPoisson()
{
    poisson[0] = vec2( -0.94201624,  -0.39906216 );
    poisson[1] = vec2(  0.94558609, -0.76890725 );
    poisson[2] = vec2( -0.094184101, -0.92938870 );
    poisson[3] = vec2(  0.34495938,   0.29387760 );
    poisson[4] = vec2( -0.91588581,   0.45771432 );
    poisson[5] = vec2( -0.81544232,  -0.87912464 );
    poisson[6] = vec2( -0.38277543,   0.27676845 );
    poisson[7] = vec2(  0.97484398,   0.75648379 );
    poisson[8] = vec2(  0.44323325,  -0.97511554 );
    poisson[9] = vec2(  0.53742981,  -0.47373420 );
    poisson[10] = vec2( -0.26496911,  -0.41893023 );
    poisson[11] = vec2(  0.79197514,   0.19090188 );
}

//有点问题，暂时没有启用ssao，若要启用，mainpass中要输出position 和 normal
void main()
{
    initPoisson();
    vec2 filterRadius = vec2(radius / texSize.x, radius / texSize.y);
//    highp vec3 viewPos = calculatePosition(f_uv);
    vec3 viewPos = texture(positionTex, f_uv).xyz;
//    vec3 viewNorm = texture(normalTex, f_uv).xyz;
    vec3 viewNorm = calculateNormal(viewPos);
    float ambientOcclusion = 0.0;
    for (int i = 0; i < samplesCount; ++i)
    {
        vec2 sampleTextcoord = f_uv + (poisson[i] * filterRadius);
//        vec3 samplePos = calculatePosition(sampleTextcoord);
        vec3 samplePos = texture(positionTex, sampleTextcoord).xyz;
        vec3 sampleDir = normalize(samplePos - viewPos);
        float dotNS = max(dot(viewNorm, sampleDir), 0.0);
        float distanceSV = distance(viewPos, samplePos);
        ambientOcclusion += max(0.0, dotNS * (1.0 / (1.0 + distanceSV)) * 2.6);
    }
    float factor = 1.0 - (ambientOcclusion / float(samplesCount));
//    factor = smoothstep(0.0, 1.0, factor);
//    ocolor = vec4(factor, factor, factor, 1.0) * texture(colorTex, f_uv);
//    ocolor = vec4(factor, factor, factor, 1.0);
//    ocolor = vec4(viewNorm, 1.0);
    ocolor = vec4(viewPos, 1.0);
//    ocolor = vec4((normalize(viewPos) + vec3(1.0)) * 0.5, 1.0);
//    ocolor = vec4(viewPos, 1.0);
//    ocolor = vec4(texture(depthTex, f_uv).rrr, 1.0);
}


//////测试边缘检测
//uniform highp mat3 ga;
//uniform highp mat3 gb;
//
//void main()
//{
//    highp float width = winParames[3];
//    highp float height = width / winParames[0];
//    
//    highp float g1 = 0.0, g2 = 0.0;
//    
//    for (int i = -1; i <= 1; ++i)
//    {
//        for (int j = -1; j <= 1; ++j)
//        {
//            highp vec2 offset = vec2(i, j) * vec2(1.0 / width, 1.0 / height);
//            highp float d = texture2D(depthTex, uv + offset).r;
//            g1 += ga[i + 1][j + 1] * d;
//            g2 += gb[i + 1][j + 1] * d;
//        }
//    }
//    
//    gl_FragColor = vec4(max(g1, g2));
//    gl_FragColor.a = 1.0;
//}
