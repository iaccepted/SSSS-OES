//
//  RenderTarget.h
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __SSSS_OES__RenderTarget__
#define __SSSS_OES__RenderTarget__
#include <OpenGLES/ES3/gl.h>
#include <assert.h>
#include <stdio.h>
#include "RenderContext.h"
#include "GLError.h"
#include <assert.h>

static const int MAX_NUM_TEXTURES = 5;

//framebuffer attachments define

class ColorAttach
{
public:
    ~ColorAttach()
    {
        if (_textureId != 0)
        {
            glDeleteTextures(1, &_textureId);
            _textureId = 0;
        }
    }
    
    void init(int width = 0,                    //width of texture
              int height = 0,
              GLenum internal_format = GL_RGBA,  //format
              GLenum external_format = GL_RGBA,
              GLenum type = GL_UNSIGNED_BYTE);   //data type
    GLuint getColorTex() const
    {
        return _textureId;
    }
private:
    GLuint _textureId = 0;
    
    int _width;
    int _height;
    
    // texture format, parms in glTexImage2D()
    GLenum _internal_format;
    GLenum _external_format;
    GLenum _type;
    
};


class DepthAttach
{
public:
    DepthAttach() {}
    
    ~DepthAttach()
    {
        if (_depthTex != 0)
        {
            glDeleteTextures(1, &_depthTex);
            _depthTex = 0;
        }
    }
    
    void init(int width = 0, int height = 0);
    
    GLuint getDepthTex() const
    {
        return _depthTex;
    }
    
private:
    GLuint _depthTex;
    int _width;
    int _height;
};


class RenderTarget
{
public:
    RenderTarget() {}
    
    virtual ~RenderTarget()
    {
        glDeleteFramebuffers(1, &_fbo);
    }
    
    void init(const int width = 0, const int height = 0)
    {
        _width = width;
        _height = height;
        if (_width == 0) _width = RenderContext::_width;
        if (_height == 0) _height = RenderContext::_height;
        _fbo = 0;
        glGenFramebuffers(1, &_fbo);
        check_gl_error();
    }
    
    void bind()
    {
        assert(_fbo != 0);
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    }
    
    void unbind()
    {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    
    void setTarget(const DepthAttach *depthAttach);
    void setTarget(const ColorAttach *colorAttach);
    void setTarget(const int size, ColorAttach **colorAttaches);
    static void check_fbo_status()
    {
        GLenum Status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (Status != GL_FRAMEBUFFER_COMPLETE)
        {
            printf("[ERROR] Frame Buffer error, status: 0x%x\n", Status);
        }
    }
    
private:
    int _texCount = 0;
    GLuint _fbo = 0;
    
    int _width;
    int _height;
};


#endif /* defined(__SSSS_OES__RenderTarget__) */
