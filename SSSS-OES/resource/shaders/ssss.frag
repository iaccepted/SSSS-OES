#version 300 es
precision mediump float;

// Texture used to fecth the SSS strength:
uniform sampler2D strengthTex;
/**
 * This is a SRGB or HDR color input buffer, which should be the final
 * color frame, resolved in case of using multisampling. The desired
 * SSS strength should be stored in the alpha channel (1 for full
 * strength, 0 for disabling SSS). If this is not possible, you an
 * customize the source of this value using SSSS_STREGTH_SOURCE.
 *
 * When using non-SRGB buffers, you
 * should convert to linear before processing, and back again to gamma
 * space before storing the pixels (see Chapter 24 of GPU Gems 3 for
 * more info)
 *
 * IMPORTANT: WORKING IN A NON-LINEAR SPACE WILL TOTALLY RUIN SSS!
 */
uniform sampler2D colorTex;

/**
 * The linear depth buffer of the scene, resolved in case of using
 * multisampling. The resolve should be a simple average to avoid
 * artifacts in the silhouette of objects.
 */
uniform sampler2D depthTex;

/**
 * This parameter specifies the global level of subsurface scattering
 * or, in other words, the width of the filter. It's specified in
 * world space units.
 */
uniform float sssWidth;

/**
 * Direction of the blur:
 *   - First pass:   vec2(1.0, 0.0)
 *   - Second pass:  vec2(0.0, 1.0)
 */
uniform vec2 dir;

/**
 * This parameter indicates whether the stencil buffer should be
 * initialized. Should be set to 'true' for the first pass if not
 * previously initialized, to enable optimization of the second
 * pass.
 */
uniform bool initStencil;

/**
 * The usual quad texture coordinates.
 */
in vec2 f_uv;

out vec4 out_color;

//#define SSSS_N_SAMPLES 17

// Configurable Defines

/**
 * SSSS_FOV must be set to the value used to render the scene.
 */
#ifndef SSSS_FOVY
#define SSSS_FOVY 20.0
#endif

/**
 * Light diffusion should occur on the surface of the object, not in a screen
 * oriented plane. Setting SSSS_FOLLOW_SURFACE to 1 will ensure that diffusion
 * is more accurately calculated, at the expense of more memory accesses.
 */
#ifndef SSSS_FOLLOW_SURFACE
#define SSSS_FOLLOW_SURFACE 0
#endif

/**
 * This define allows to specify a different source for the SSS strength
 * (instead of using the alpha channel of the color framebuffer). This is
 * useful when the alpha channel of the mian color buffer is used for something
 * else.
 */
#ifndef SSSS_STREGTH_SOURCE
#define SSSS_STREGTH_SOURCE (texture(colorTex, texcoord).a)
//#define SSSS_STREGTH_SOURCE (texture(strengthTex, texcoord).a)
#endif

/**
 * If SSSS_N_SAMPLES is defined at this point, a custom filter kernel must be
 * set by the runtime.
 */
#ifdef SSSS_N_SAMPLES
/**
 * Filter kernel layout is as follows:
 *   - Weights in the RGB channels.
 *   - Offsets in the A channel.
 */
uniform vec4 kernel[SSSS_N_SAMPLES];
#else
/**
 * Here you have ready-to-use kernels for quickstarters. Three kernels are
 * readily available, with varying quality.
 * To create new kernels take a look into SSS::calculateKernel, or simply
 * push CTRL+C in the demo to copy the customized kernel into the clipboard.
 *
 * Note: these preset kernels are not used by the demo. They are calculated on
 * the fly depending on the selected values in the interface, by directly using
 * SSS::calculateKernel.
 *
 * Quality ranges from 0 to 2, being 2 the highest quality available.
 * The quality is with respect to 1080p; for 720p Quality=0 suffices.
 */
#define SSSS_QUALITY 0

#if SSSS_QUALITY == 2
#define SSSS_N_SAMPLES 25
const vec4 kernel[] = vec4[] (
                                  vec4(0.530605, 0.613514, 0.739601, 0),
                                  vec4(0.000973794, 1.11862e-005, 9.43437e-007, -3),
                                  vec4(0.00333804, 7.85443e-005, 1.2945e-005, -2.52083),
                                  vec4(0.00500364, 0.00020094, 5.28848e-005, -2.08333),
                                  vec4(0.00700976, 0.00049366, 0.000151938, -1.6875),
                                  vec4(0.0094389, 0.00139119, 0.000416598, -1.33333),
                                  vec4(0.0128496, 0.00356329, 0.00132016, -1.02083),
                                  vec4(0.017924, 0.00711691, 0.00347194, -0.75),
                                  vec4(0.0263642, 0.0119715, 0.00684598, -0.520833),
                                  vec4(0.0410172, 0.0199899, 0.0118481, -0.333333),
                                  vec4(0.0493588, 0.0367726, 0.0219485, -0.1875),
                                  vec4(0.0402784, 0.0657244, 0.04631, -0.0833333),
                                  vec4(0.0211412, 0.0459286, 0.0378196, -0.0208333),
                                  vec4(0.0211412, 0.0459286, 0.0378196, 0.0208333),
                                  vec4(0.0402784, 0.0657244, 0.04631, 0.0833333),
                                  vec4(0.0493588, 0.0367726, 0.0219485, 0.1875),
                                  vec4(0.0410172, 0.0199899, 0.0118481, 0.333333),
                                  vec4(0.0263642, 0.0119715, 0.00684598, 0.520833),
                                  vec4(0.017924, 0.00711691, 0.00347194, 0.75),
                                  vec4(0.0128496, 0.00356329, 0.00132016, 1.02083),
                                  vec4(0.0094389, 0.00139119, 0.000416598, 1.33333),
                                  vec4(0.00700976, 0.00049366, 0.000151938, 1.6875),
                                  vec4(0.00500364, 0.00020094, 5.28848e-005, 2.08333),
                                  vec4(0.00333804, 7.85443e-005, 1.2945e-005, 2.52083),
                                  vec4(0.000973794, 1.11862e-005, 9.43437e-007, 3)
                                  );

#elif SSSS_QUALITY == 1
#define SSSS_N_SAMPLES 17
const vec4 kernel[] = vec4[] (
                                  vec4(0.536343, 0.624624, 0.748867, 0),
                                  vec4(0.00317394, 0.000134823, 3.77269e-005, -2),
                                  vec4(0.0100386, 0.000914679, 0.000275702, -1.53125),
                                  vec4(0.0144609, 0.00317269, 0.00106399, -1.125),
                                  vec4(0.0216301, 0.00794618, 0.00376991, -0.78125),
                                  vec4(0.0347317, 0.0151085, 0.00871983, -0.5),
                                  vec4(0.0571056, 0.0287432, 0.0172844, -0.28125),
                                  vec4(0.0582416, 0.0659959, 0.0411329, -0.125),
                                  vec4(0.0324462, 0.0656718, 0.0532821, -0.03125),
                                  vec4(0.0324462, 0.0656718, 0.0532821, 0.03125),
                                  vec4(0.0582416, 0.0659959, 0.0411329, 0.125),
                                  vec4(0.0571056, 0.0287432, 0.0172844, 0.28125),
                                  vec4(0.0347317, 0.0151085, 0.00871983, 0.5),
                                  vec4(0.0216301, 0.00794618, 0.00376991, 0.78125),
                                  vec4(0.0144609, 0.00317269, 0.00106399, 1.125),
                                  vec4(0.0100386, 0.000914679, 0.000275702, 1.53125),
                                  vec4(0.00317394, 0.000134823, 3.77269e-005, 2)
                                  );

#elif SSSS_QUALITY == 0
#define SSSS_N_SAMPLES 11
const vec4 kernel[] = vec4[] (
                                  vec4(0.560479, 0.669086, 0.784728, 0),
                                  vec4(0.00471691, 0.000184771, 5.07566e-005, -2),
                                  vec4(0.0192831, 0.00282018, 0.00084214, -1.28),
                                  vec4(0.03639, 0.0130999, 0.00643685, -0.72),
                                  vec4(0.0821904, 0.0358608, 0.0209261, -0.32),
                                  vec4(0.0771802, 0.113491, 0.0793803, -0.08),
                                  vec4(0.0771802, 0.113491, 0.0793803, 0.08),
                                  vec4(0.0821904, 0.0358608, 0.0209261, 0.32),
                                  vec4(0.03639, 0.0130999, 0.00643685, 0.72),
                                  vec4(0.0192831, 0.00282018, 0.00084214, 1.28),
                                  vec4(0.00471691, 0.000184771, 5.07565e-005, 2)
                                  );
#else
#error Quality must be one of {0,1,2}
#endif
#endif

void main()
{
    //out_color = SSSSBlurPS(uv, colorTex, depthTex, sssWidth, dir, initStencil);
    vec2 texcoord = f_uv;
    
    // Fetch color of current pixel:
    vec4 colorM = texture(colorTex, texcoord);
    
    // Initialize the stencil buffer in case it was not already available:
    if (initStencil) // (Checked in compile time, it's optimized away)
        if (SSSS_STREGTH_SOURCE == 0.0) discard;
    
    // Fetch linear depth of current pixel:
    //float depthM = texture(depthTex, texcoord).r;
    float depthM = 1.0 / texture(depthTex, texcoord).r;
    
    // Calculate the sssWidth scale (1.0 for a unit plane sitting on the
    // projection window):
    float distanceToProjectionWindow = 1.0 / tan(0.5 * radians(SSSS_FOVY));
    float scale = distanceToProjectionWindow / depthM;
    
    // Calculate the final step to fetch the surrounding pixels:
    vec2 finalStep = sssWidth * scale * dir;
    finalStep *= SSSS_STREGTH_SOURCE; // Modulate it using the alpha channel.
    finalStep *= 1.0 / 3.0; // Divide by 3 as the kernels range from -3 to 3.
    
    // Accumulate the center sample:
    vec4 colorBlurred = colorM;
    colorBlurred.rgb *= kernel[0].rgb;
    
    // Accumulate the other samples:
    for (int i = 1; i < SSSS_N_SAMPLES; i++) {
        // Fetch color and depth for current sample:
        vec2 offset = texcoord + kernel[i].a * finalStep;
        vec4 color = texture(colorTex, offset);
        
#if SSSS_FOLLOW_SURFACE == 1
        // If the difference in depth is huge, we lerp color back to "colorM":
        float depth = texture(depthTex, offset).r;
        float s = clamp(300.0f * distanceToProjectionWindow *
                               sssWidth * abs(depthM - depth));
        color.rgb = mix(color.rgb, colorM.rgb, s);
#endif
        
        // Accumulate:
        colorBlurred.rgb += kernel[i].rgb * color.rgb;
    }
    
    out_color = colorBlurred;
}
