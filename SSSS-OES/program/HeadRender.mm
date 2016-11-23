//
//  HeadRender.cpp
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "HeadRender.h"
#include "RenderContext.h"
#include "Model.h"
#include "ProgFactory.h"
#include "Global.h"
#include "RenderEngine.h"
#include <glm/gtc/matrix_transform.hpp>
#include "LoadTexture.h"
#include "Program.h"
#include "RenderTarget.h"
#include "GLError.h"

void HeadRender::init(unsigned int width, unsigned int height, GLKView *view)
{
    RenderContext::init(width, height, view);
    Quad::init();
    ProgFactory::init();
    Model::init("head_optimized.obj");
    RenderEngine::init();
    
    //load texture
    tex_head_diffuse = LoadTexture::CreateTexture("DiffuseMap_R8G8B8A8_1024_mipmaps.dds", true);
    tex_head_specularAO = LoadTexture::CreateTexture("SpecularAOMap.dds");
    tex_head_normal_map = LoadTexture::CreateTexture("NormalMap_RG16f_1024_mipmaps.dds");
    tex_sky = LoadTexture::CreateTextureCubemap("DiffuseMap.dds");
    tex_sky_irradiance_map = LoadTexture::CreateTextureCubemap("IrradianceMap.dds");
    tex_beckmann = LoadTexture::CreateTexture("BeckmannMap.dds");

    mainRT.init(RenderContext::_width, RenderContext::_height);
    check_gl_error();
    depthRT.init(RenderContext::_width, RenderContext::_height, GL_R8, GL_RED);
    check_gl_error();
    specularsRT.init(RenderContext::_width, RenderContext::_height);
    check_gl_error();
    tmpRT.init(RenderContext::_width, RenderContext::_height);
    check_gl_error();
    depth_stencil.init();
    check_gl_error();
    ssaoRT.init(RenderContext::_width, RenderContext::_height);
    check_gl_error();
    normalRT.init(RenderContext::_width, RenderContext::_height);
    check_gl_error();
    positionRT.init(RenderContext::_width, RenderContext::_height, GL_RGB16F, GL_RGB, GL_FLOAT);
    check_gl_error();
    
    renderTarget.init();
}

void HeadRender::shadowPass()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //glEnable(GL_CULL_FACE);
    glDisable(GL_STENCIL_TEST);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_POLYGON_OFFSET_FILL);
    glPolygonOffset(2.0f, 4.0f);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    auto modelMat = glm::scale(glm::mat4(1.0f), vec3(0.7f, 0.7f, 0.7f));
    modelMat = glm::translate(modelMat, glm::vec3(0, 0.2f, 0.425f));
    for (int i = 0; i < N_LIGHTS; ++i)
    {
        Light &l = RenderContext::lights[i];
        if (glm::length(l.color) > 0.0f) {
            l.shadowMap.setWorldMatrix(modelMat);
            l.shadowMap.begin(l.camera.getViewMatrix(), l.camera.getProjectionMatrix());
        }
    }
    glDisable(GL_POLYGON_OFFSET_FILL);
}

void HeadRender::mainPass()
{
    //set fbo and attachments
    static ColorAttach *rts[] = { &mainRT, &depthRT, &specularsRT, &normalRT, &positionRT};
    renderTarget.setTarget(3, rts);
    renderTarget.setTarget(&depth_stencil);
    renderTarget.bind();

    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_STENCIL_TEST);
    glStencilFunc(GL_ALWAYS, 1, 0xff);
    glStencilMask(0xff);
    
    RenderContext::_worldM = glm::scale(mat4(1.0f), vec3(0.7f, 0.7f, 0.7f)) * glm::translate(mat4(1.0f), vec3(0, 0.2f, 0.425f));
    glm::mat4 mvp = RenderContext::getmvp();
    
    //set program
    Program &prog = ProgFactory::mainProg;
    prog.use();
    
    
//    uniform sampler2D beckmannTex;
//    uniform sampler2D diffuseTex;
//    uniform sampler2D normalTex;
//    uniform sampler2D specularAOTex;
//    uniform samplerCube irradianceTex;
//    
//    uniform sampler2D depthTex0;
//    uniform sampler2D depthTex1;
//    uniform sampler2D depthTex2;
//    
//    uniform sampler2DShadow shadowMap0;
//    uniform sampler2DShadow shadowmap1;
//    uniform sampler2DShadow shadowMap2;
//    uniform Light lights[N_LIGHTS];
//    
//    //modify attribut
//    uniform float bumpiness;
//    uniform float ambient;
//    uniform float specularFreshnel;
//    uniform float specularIntensity;
//    uniform float specularRoughness;
//    uniform float translucency;
//    uniform float sssWidth;
//    
//    uniform bool sssEnable;
//    uniform bool sssTranslucencyEnable;
    
    prog.setUniform("M", RenderContext::_worldM);
    prog.setUniform("TIM", RenderContext::getTIM());
    prog.setUniform("MVP", mvp);
    prog.setUniform("camera_position", RenderContext::_camera->getEyePosition());
//    prog.setUniform("V", RenderContext::_camera->getViewMatrix());
    
    int texIndex = 0;
    //set 5 textures
    prog.setTexture("diffuseTex", tex_head_diffuse, texIndex++, GL_TEXTURE_2D);
    prog.setTexture("specularAOTex", tex_head_specularAO, texIndex++, GL_TEXTURE_2D);
    prog.setTexture("normalTex", tex_head_normal_map, texIndex++, GL_TEXTURE_2D);
    prog.setTexture("beckmannTex", tex_beckmann, texIndex++, GL_TEXTURE_2D);
    prog.setTexture("irradianceTex", tex_sky_irradiance_map, texIndex++, GL_TEXTURE_CUBE_MAP);
    
    
    prog.setUniform("sssWidth", sssWidth);
    prog.setUniform("translucency", translucency);
    prog.setUniform("specularIntensity", specularIntensity);
    prog.setUniform("specularRoughness", specularRoughness);
    prog.setUniform("specularFreshnel", specularFreshnel);
    prog.setUniform("bumpiness", bumpiness);
    prog.setUniform("ambient", ambient);
    
    
    
    //transfer light information
    char attrib_buff[64];
    for (int i = 0; i < N_LIGHTS; ++i) {
        Light &l = RenderContext::lights[i];
        Camera &lc = l.camera;
        const glm::vec3 &pos = lc.getEyePosition();
        
        sprintf(attrib_buff, "lights[%d].position", i);
        prog.setUniform(attrib_buff, pos);
        
        auto dir = lc.getLookAtPosition() - pos;
        dir = glm::normalize(dir);
        sprintf(attrib_buff, "lights[%d].direction", i);
        prog.setUniform(attrib_buff, dir);
        
        sprintf(attrib_buff, "lights[%d].falloffStart", i);
        prog.setUniform(attrib_buff, cos(0.5f * l.fov));
        
        sprintf(attrib_buff, "lights[%d].falloffWidth", i);
        prog.setUniform(attrib_buff, falloff_width);
        
        l.color = l.intensity * vec3(1, 1, 1);
        sprintf(attrib_buff, "lights[%d].color", i);
        prog.setUniform(attrib_buff, l.color);
        
        sprintf(attrib_buff, "lights[%d].attenuation", i);
        prog.setUniform(attrib_buff, l.attenuation);
        
        sprintf(attrib_buff, "lights[%d].farPlane", i);
        prog.setUniform(attrib_buff, RenderContext::_farPlane);
        
        sprintf(attrib_buff, "lights[%d].bias", i);
        prog.setUniform(attrib_buff, l.bias);
        
        sprintf(attrib_buff, "lights[%d].viewProjection", i);
        prog.setUniform(attrib_buff, ShadowMap::getViewProjectionTextureMatrix(lc.getViewMatrix(), lc.getProjectionMatrix()));
        
        sprintf(attrib_buff, "shadowMap[%d]", i);
        prog.setTexture(attrib_buff, l.shadowMap.getDepthTex(), texIndex++, GL_TEXTURE_2D);
        //glBindSampler(5 + i, ShadowMap::sampler_object_for_shadow_map);
        
        sprintf(attrib_buff, "depthTex[%d]", i);
        prog.setTexture(attrib_buff, l.shadowMap.getDepthTex(), texIndex++, GL_TEXTURE_2D);
        //glBindSampler(5 + N_LIGHTS + i, ShadowMap::sampler_object_for_depth_texutre);
    }
    
    
    //bind data and render
    Model::render();
    renderTarget.unbind();
}

void HeadRender::ssss()
{
    //set fbo and attachments
    renderTarget.setTarget(&tmpRT);
    renderTarget.setTarget(&depth_stencil);
    renderTarget.bind();

//    glEnable(GL_STENCIL_TEST);
//    glStencilFunc(GL_EQUAL, 1, 0xFF);
//    glStencilMask(0x00);
    glDisable(GL_DEPTH_TEST);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    //set program
    Program prog = ProgFactory::ssssProg;
    prog.use();
    
    int texIndex = 0;
    prog.setTexture("colorTex", mainRT.getColorTex(), texIndex++);
    prog.setTexture("dpethTex", depthRT.getColorTex(), texIndex++);
    prog.setTexture("strengthTex", specularsRT.getColorTex(), texIndex++);
    prog.setUniform("sssWidth", sssWidth);
    prog.setUniform("dir", glm::vec2(1.0, 0.0));
    prog.setUniform("initStencil", false);
    
    Quad::render();
    renderTarget.unbind();
    
    //vertical
    renderTarget.setTarget(&mainRT);
    renderTarget.setTarget(&depth_stencil);
    renderTarget.bind();
    
    glDisable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT);
    
    prog.setTexture("colorTex", tmpRT.getColorTex(), texIndex++);
    prog.setTexture("dpethTex", depthRT.getColorTex(), texIndex++);
    prog.setTexture("strengthTex", specularsRT.getColorTex(), texIndex++);
    prog.setUniform("sssWidth", sssWidth);
    prog.setUniform("dir", glm::vec2(0.0, 1.0));
    
    //bind data and render
    Quad::render();
    renderTarget.unbind();
}

void HeadRender::addSpecular()
{
    //set fbo and attachments
    renderTarget.setTarget(&mainRT);
    renderTarget.bind();
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    glDisable(GL_DEPTH_TEST);
    
    RenderEngine::drawTexture(specularsRT.getColorTex());
    renderTarget.unbind();
    glDisable(GL_BLEND);
}

void HeadRender::fxaa()
{
    //set fbo and attachments
    renderTarget.setTarget(&tmpRT);
    renderTarget.bind();
    
    //set program
    Program prog = ProgFactory::fxaaProg;
    prog.use();
    
    prog.setTexture("colorTex", mainRT.getColorTex(), 0);
    prog.setUniform("textSize", glm::vec2(RenderContext::_width, RenderContext::_height));
    
    //bind data and render
    Quad::render();
    
    renderTarget.unbind();
};

void HeadRender::ssao(ColorAttach *color)
{
    //set fbo and attachments
    renderTarget.setTarget(&ssaoRT);
    renderTarget.bind();
    
    //set program
    Program prog = ProgFactory::ssaoProg;
    prog.use();
    
    prog.setTexture("depthTex", depthRT.getColorTex(), 0);
    prog.setTexture("normalTex", normalRT.getColorTex(), 1);
    prog.setTexture("positionTex", positionRT.getColorTex(), 2);
    prog.setTexture("colorTex", color->getColorTex(), 3);
    prog.setUniform("iP", glm::inverse(RenderContext::_camera->getProjectionMatrix()));
    prog.setUniform("texSize", glm::vec2(RenderContext::_width, RenderContext::_height));
    
    prog.setUniform("radius", 5.0f);
    
    Quad::render();
    
    renderTarget.unbind();
}

void HeadRender::render()
{
    ColorAttach *pAttach = &mainRT;
    
    shadowPass();
//    check_gl_error();
    
    //main---->diffuse+specular+depth
    mainPass();
    check_gl_error();
    
    ssss();

    
    addSpecular();
    if (fxaaEnabled)
    {
        fxaa();
        pAttach = &tmpRT;
    }
    
//    RenderEngine::drawTextureToScreen((*pAttach).getColorTex());
    
    if (ssaoEnabled)
    {
        ssao(pAttach);
        pAttach = &ssaoRT;
    }
    
    

    RenderEngine::drawTextureToScreen(pAttach->getColorTex());
//    RenderEngine::drawTextureToScreen(normalRT.getColorTex());
}

void HeadRender::setFxaaEnabled(bool enabled)
{
    fxaaEnabled = enabled;
}