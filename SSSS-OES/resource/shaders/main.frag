#version 300 es
precision highp float;
precision mediump sampler2DShadow;
precision highp sampler2D;

//calculate all lights effect in world space

#define N_LIGHTS 3

struct Light
{
    vec3 position;
    vec3 direction;
    float falloffStart;
    float falloffWidth;
    vec3 color;
    float attenuation;
    float farPlane;
    float bias;
    mat4 viewProjection;
};

//out vec2 f_uv;
//out vec3 w_normal;  //normal in world space->frag
//out vec3 w_position;//..
//out vec3 w_tan;     //..
//out vec3 w_bitan;   //transfer data instead calculate in fragment shader--faster
//out vec3 w_view;    //eye direction in world space

in vec2 f_uv;
in vec3 w_normal;
in vec3 w_position;
in vec3 w_tan;
in vec3 w_bitan;
in vec3 w_view;

uniform sampler2D diffuseTex;
uniform sampler2D specularAOTex;
uniform sampler2D normalTex;
uniform sampler2D beckmannTex;
uniform samplerCube irradianceTex;

uniform Light lights[N_LIGHTS];
uniform sampler2D depthTex[N_LIGHTS];
uniform sampler2DShadow shadowMap[N_LIGHTS];

//modify attribut
uniform float translucency;
uniform float sssWidth;
uniform float bumpiness;
uniform float ambient;
uniform float specularFreshnel;
uniform float specularIntensity;
uniform float specularRoughness;

uniform bool sssEnable;
uniform bool sssTranslucencyEnable;
layout (location = 0)out vec4 diffuseColor;
layout (location = 1)out float depth;
layout (location = 2)out vec4 specularColor;
//layout (location = 3)out vec3 gnorm;
//layout (location = 4)out vec3 gpos;


float getZ(float z)
{
//    float near = 0.1f;
//    float far = 10.0f;
//    return far * near / (far - z * (far - near));
    float far = 10.0f;
    float near = 0.1f;
    
    //return z * far * near / (far - z * (far - near));
    return 2.0 * far * near / (near + far - z * (far - near));
}

vec3 SSSStransmittance(
                       vec3 L,//vector  w_position to light
                       sampler2D map, //depth
                       mat4 lightViewProjection,
                       float farPlane
)
{
    float scale = 8.25 * (1.0 - translucency) / sssWidth;
    vec4 shrinkedPos = vec4(w_position - 0.005 * w_normal, 1.0);
    vec4 shadowPosition = lightViewProjection * shrinkedPos;
    float d1 = texture(map, shadowPosition.xy / shadowPosition.w).r;
    d1 = getZ(d1);
    float d2 = shadowPosition.z / shadowPosition.w;
    d2 = getZ(d2);
    float d = scale * abs(d1 - d2);
    
    float dd = -d * d;
    vec3 profile = vec3(0.233, 0.455, 0.649) * exp(dd / 0.0064) +
    vec3(0.1,   0.336, 0.344) * exp(dd / 0.0484) +
    vec3(0.118, 0.198, 0.0)   * exp(dd / 0.187)  +
    vec3(0.113, 0.007, 0.007) * exp(dd / 0.567)  +
    vec3(0.358, 0.004, 0.0)   * exp(dd / 1.99)   +
    vec3(0.078, 0.0,   0.0)   * exp(dd / 7.41);
    
    return profile * clamp(0.3 + dot(L, -w_normal), 0.0, 1.0);
}

vec3 bumpMap(vec2 uv)
{
    vec3 bump;
    bump.xy = -1.0 + 2.0 * texture(normalTex, uv).gr;
    bump.z = sqrt(1.0 - bump.x * bump.x - bump.y * bump.y);
    return normalize(bump);
}

float freshnelReflectance(vec3 H, vec3 V, float m)
{
    float base = 1.0 - dot(V, H);
    float exponential = pow(base, 5.0);
    return exponential + m * (1.0 - exponential);
}

float ks_skin_specular(vec3 N, vec3 L, vec3 V, float roughness)
{
    float result = 0.0;
    vec3 h = L + V;//no normalize
    vec3 H = normalize(h);
    
    float ndotl = max(dot(N, L), 0.0);
    float ndoth = max(dot(N, H), 0.0);
    
    float PH = pow(2.0 * texture(beckmannTex, vec2(ndoth, roughness)).r, 10.0f);
    float F = mix(0.25, freshnelReflectance(H, V, 0.028), specularFreshnel);
    float frSpec = max(PH * F / dot(H, H), 0.0);
    result = ndotl * frSpec;
    return result;
}

float shadowMapFunc(sampler2DShadow map, const int index)
{
//    //coordinate in homogeneous space
//    vec4 shadowUV = lights[index].viewProjection * vec4(w_position, 1.0f);
//    
//    //coordinate in 
//    shadowUV /= shadowUV.w;
//    float d1 = texture(map, shadowUV.xy).r;
//    float d2 = shadowUV.z;
//    
//    if (d1 < d2 - 0.0005)return 0.0;
//    return 1.0;
    return textureProj(map, lights[index].viewProjection * vec4(w_position, 1.0f));
}


void process(int index,//light index
             sampler2D depthTex, //depth texture
             vec4 albedo,  //diffusetex color
             float shadow, //shadow parameter , calculated by shadowMapFunc
             vec3 normal,
             vec3 view,    //eye dir
             float intensity,
             float roughness
             )
{
    //world space
    vec3 light = lights[index].position - w_position;
    float dist = length(light);
    light /= dist;
    
    float spot = dot(lights[index].direction, -light);
    if (spot > lights[index].falloffStart)
    {
        //attenuation
        float curve = min(pow(dist / lights[index].farPlane, 6.0), 1.0);
        float attenuation = mix(1.0 / (1.0 + lights[index].attenuation * dist * dist), 0.0, curve);
        
        //spot light falloff
        spot = clamp((spot - lights[index].falloffStart) / lights[index].falloffWidth, 0.0, 1.0);
        
        vec3 f1 = lights[index].color * attenuation * spot;
        vec3 f2 = albedo.rgb * f1;
        
        //diffuse and specular
        vec3 diffuse = vec3(clamp(dot(light, normal), 0.0, 1.0));
        float specular = intensity * ks_skin_specular(normal, light, view, roughness);
        
        specularColor.rgb += shadow * f1 * specular;
        diffuseColor.rgb += shadow * f2 * diffuse;
        
        diffuseColor.rgb += f2 * SSSStransmittance(light, depthTex, lights[index].viewProjection, lights[index].farPlane);
    }
}

void main()
{
    vec3 V = normalize(w_view);
    
    //flip y axis
    vec2 someUV = vec2(f_uv.x, 1.0 - f_uv.y);
    
    //calculate the tbn matrix
    vec3 tangent = normalize(w_tan);
    vec3 bitangent = normalize(w_bitan);
    mat3 tbn = mat3(tangent, bitangent, normalize(w_normal));
    
    vec3 tangentNormal = mix(vec3(0, 0, 1), bumpMap(someUV), bumpiness);
    vec3 normal  = tbn * tangentNormal;
    
    //fetch albedo, specular parameters and static ambient occlusion
    vec4 albedo = texture(diffuseTex, f_uv);
    vec3 specularAO = texture(specularAOTex, someUV).bgr;
    
    float occlusion = specularAO.b;
    float intensity = specularAO.r * specularIntensity;
    float roughness = specularAO.g / 0.3 * specularRoughness;
    
    diffuseColor = vec4(0.0, 0.0, 0.0, 0.0);
    specularColor = vec4(0.0, 0.0, 0.0, 0.0);
    
    float shadow[N_LIGHTS];
    shadow[0] = shadowMapFunc(shadowMap[0], 0);
    shadow[1] = shadowMapFunc(shadowMap[1], 1);
    shadow[2] = shadowMapFunc(shadowMap[2], 2);
    
//    opengles 3.0 on ios plat form don't support dynamic index, so, i changed this for
//    for (int i = 0; i < N_LIGHTS; ++i)
//    {
//        vec3 light = lights[i].position - w_position;
//        float dist = length(light);
//        light /= dist;
//        
//        
//        float spot = dot(lights[i].direction, -light);
//        if (spot > lights[i].falloffStart)
//        {
//            //attenuation
//            float curve = min(pow(dist / lights[i].farPlane, 6.0), 1.0);
//            float attenuation = mix(1.0 / (1.0 + lights[i].attenuation * dist * dist), 0.0, curve);
//            
//            //spot light falloff
//            spot = clamp((spot - lights[i].falloffStart) / lights[i].falloffWidth, 0.0, 1.0);
//            
//            vec3 f1 = lights[i].color * attenuation * spot;
//            vec3 f2 = albedo.rgb * f1;
//            
//            //diffuse and specular
//            vec3 diffuse = vec3(clamp(dot(light, normal), 0.0, 1.0));
//            float specular = intensity * ks_skin_specular(normal, light, V, roughness);
//            
//            specularColor.rgb += shadow[i] * f1 * specular;
//            diffuseColor.rgb += shadow[i] * f2 * diffuse;
//        }
//    }
    
    process(0, depthTex[0], albedo, shadow[0], normal, V, intensity, roughness);
    process(1, depthTex[1], albedo, shadow[1], normal, V, intensity, roughness);
    process(2, depthTex[2], albedo, shadow[2], normal, V, intensity, roughness);
    
    //add the ambient component
    diffuseColor.rgb += occlusion * ambient * albedo.rgb * texture(irradianceTex, normal).rgb;
    //diffuseColor.rgb = vec3(roughness);

    //the rate of light to sss
    specularColor.a = albedo.a;
    
    depth = gl_FragCoord.w;
    
    diffuseColor.a = 1.0;
    
//    gnorm = normalize(normal);
//    gpos = w_position;
}