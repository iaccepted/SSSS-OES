
#include "RenderTarget.h"

void ColorAttach::init(int width, int height, GLenum internal_format, GLenum external_format, GLenum type)
{
    _width = width;
    _height = height;
    if (_width == 0) _width = RenderContext::_width;
    if (_height == 0) _height = RenderContext::_height;
    _internal_format = internal_format;
    _external_format = external_format;
    _type = type;
    
    glGenTextures(1, &_textureId);
    glBindTexture(GL_TEXTURE_2D, _textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, internal_format, _width, _height, 0, external_format, type, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    check_gl_error();
}

void DepthAttach::init(int width, int height)
{
    _width = width; _height = height;
    if (_width == 0) _width = RenderContext::_width;
    if (_height == 0) _height = RenderContext::_height;
    //int w = RenderContex::window_width;
    //int h = RenderContex::window_height;
    
    glGenTextures(1, &_depthTex);
    glBindTexture(GL_TEXTURE_2D, _depthTex);
    check_gl_error();
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, _width, _height, 0, GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, NULL);
    check_gl_error();
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    check_gl_error();
}

void RenderTarget::setTarget(const DepthAttach *depthAttach)
{
    bind();
    if (nullptr == depthAttach)
    {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, 0, 0);
        return;
    }
    check_gl_error();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, depthAttach->getDepthTex(), 0);
    check_gl_error();
    check_fbo_status();
    unbind();
}

void RenderTarget::setTarget(const ColorAttach *colorAttach)
{
    bind();
    if (nullptr == colorAttach)
    {
        //glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
        for (int i = 0; i < _texCount; i++)
        {
            glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i, GL_TEXTURE_2D, 0, 0);
        }
        _texCount = 0;
        return;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    _texCount = 1;
    glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorAttach->getColorTex(), 0);
    
    static GLenum draw_buffers[] = { GL_COLOR_ATTACHMENT0 };
    glDrawBuffers(_texCount, draw_buffers);
    check_fbo_status();
    check_gl_error();
    unbind();
}

void RenderTarget::setTarget(const int size, ColorAttach **colorAttaches)
{
    //glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    bind();
    _texCount = size;
    assert(1 <= _texCount && _texCount <= MAX_NUM_TEXTURES);
    for (int i = 0; i < _texCount; i++)
    {
        glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i, GL_TEXTURE_2D, colorAttaches[i]->getColorTex(), 0);
    }
    static GLenum draw_buffers[] = { GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2, GL_COLOR_ATTACHMENT3, GL_COLOR_ATTACHMENT4, GL_COLOR_ATTACHMENT5 };
    glDrawBuffers(_texCount, draw_buffers);
    check_fbo_status();
    check_gl_error();
    unbind();
    
}

