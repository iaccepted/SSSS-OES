//
//  HeadRender.h
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __SSSS_OES__HeadRender__
#define __SSSS_OES__HeadRender__

#include <GLKit/GLKit.h>
#include "Model.h"
#include <glm/glm.hpp>
#include "RenderTarget.h"

class HeadRender
{
public:
    void init(unsigned int width, unsigned int height, GLKView *view);
    void setFxaaEnabled(bool enabled);
    void shadowPass();
    void mainPass();
    void ssss();
    void addSpecular();
    void fxaa();
    void render();
    void ssao(ColorAttach *color);
    
private:
    //G buffer
    ColorAttach normalRT;
    ColorAttach positionRT;
    
    ColorAttach mainRT;
    ColorAttach depthRT;
    ColorAttach specularsRT;
    ColorAttach tmpRT;
    ColorAttach ssaoRT;
    RenderTarget renderTarget;
    
    DepthAttach depth_stencil;
    
    GLuint tex_head_diffuse;
    GLuint tex_head_specularAO;
    GLuint tex_head_normal_map;
    GLuint tex_sky;
    GLuint tex_sky_irradiance_map;
    GLuint tex_beckmann;
    
    bool fxaaEnabled = false;
    bool separate_speculars = false;
    bool enable_ssss = true;
    bool enable_sss_translucency = true;
    bool ssaoEnabled = false;
    float sssWidth = 0.012f;
    glm::vec3 sss_strength = glm::vec3(0.48f, 0.41f, 0.28f);
    glm::vec3 sss_falloff = glm::vec3(1.0f, 0.37f, 0.3f);
    float translucency = 0.88f;	
    
    double speed = 1;
    float specularIntensity = 1.88f;
    float specularRoughness = 0.3f;
    float specularFreshnel = 0.82f;
    float bumpiness = 0.9f;
    float ambient = 0.80f; // 0.61f
    
    float falloff_width = 0.1f;
};

#endif /* defined(__SSSS_OES__HeadRender__) */
