//
//  ShadowMap.h
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __SSSS_OES__ShadowMap__
#define __SSSS_OES__ShadowMap__
#include <OpenGLES/ES3/gl.h>
#include <glm/glm.hpp>

class ShadowMap {
public:
    void init();
    
    ShadowMap();
    ~ShadowMap();
    
    void begin(const glm::mat4 &view, const glm::mat4 &projection);
    void setWorldMatrix(const glm::mat4 &worldM);
    
    static glm::mat4 getViewProjectionTextureMatrix(const glm::mat4 &view, const glm::mat4 &projection);
    GLuint getDepthTex();
    GLuint getColorTex();
    
private:
    int width, height;
    glm::mat4 worldM;
    GLuint depthTex, _vao;
    GLuint colorTex;
    GLuint fbo;
};

#endif /* defined(__SSSS_OES__ShadowMap__) */
