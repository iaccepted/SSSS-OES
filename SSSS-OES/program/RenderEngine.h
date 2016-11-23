//
//  RenderEngine.h
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __SSSS_OES__RenderEngine__
#define __SSSS_OES__RenderEngine__
#include <OpenGLES/ES3/gl.h>
#include "RenderTarget.h"

class RenderEngine
{
public:
    static void drawTextureToScreen(GLuint texId);
    static void drawTexture(GLuint texId);
    
    static void init()
    {
        renderTarget.init();
    }

    
    static void setTarget(const ColorAttach *colorAttach, const DepthAttach *depthAttach );
    static void setTarget(int n, ColorAttach **colorAttachs, const DepthAttach *depthAttach);
    static void bindDefaultRenderbuffer()
    {
        RenderContext::reset();
    }

    
private:
    static RenderTarget renderTarget;
};

#endif /* defined(__SSSS_OES__RenderEngine__) */
