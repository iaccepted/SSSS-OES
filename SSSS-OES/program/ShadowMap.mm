//
//  ShadowMap.cpp
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "ShadowMap.h"
#include "ProgFactory.h"
#include "Program.h"
#include "Model.h"
#include <glm/gtc/matrix_transform.hpp>
#include "RenderContext.h"
#include "GLError.h"


void ShadowMap::init()
{
    int _width = RenderContext::_width;
    int _height = RenderContext::_height;
    check_gl_error();
    glGenTextures(1, &depthTex);
    glBindTexture(GL_TEXTURE_2D, depthTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, _width, _height, 0, GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTex, 0);
    
//    GLenum Status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
//    if (Status != GL_FRAMEBUFFER_COMPLETE)
//    {
//        printf("[ERROR] Frame Buffer error, status: 0x%x\n", Status);
//    }

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

ShadowMap::ShadowMap()
{
    this->width = RenderContext::_width;
    this->height = RenderContext::_height;
}


ShadowMap::~ShadowMap()
{
}


void ShadowMap::begin(const glm::mat4 &view, const glm::mat4 &projection)
{
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    //RenderContext::reset();
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    Program &prog = ProgFactory::shadowProg;
    prog.use();
    
    glm::mat4 linearProjection = projection;
    glm::mat4 lightMVP = linearProjection * view * worldM;
    
    prog.setUniform("lightMVP", lightMVP);
    
    check_gl_error();
    Model::render();
    check_gl_error();
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

GLuint ShadowMap::getDepthTex()
{
    return this->depthTex;
}

GLuint ShadowMap::getColorTex()
{
    return this->colorTex;
}

glm::mat4 ShadowMap::getViewProjectionTextureMatrix(const glm::mat4 &view, const glm::mat4 &projection)
{
    static mat4 biasMatrix(
                           0.5, 0.0, 0.0, 0.0,
                           0.0, 0.5, 0.0, 0.0,
                           0.0, 0.0, 0.5, 0.0,
                           0.5, 0.5, 0.5, 1.0
                           );
    return biasMatrix * projection * view;
}

void ShadowMap::setWorldMatrix(const glm::mat4 &worldM)
{
    this->worldM = glm::translate(worldM, glm::vec3(0.0, 0.0, 0.0));
}
