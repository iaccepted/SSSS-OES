//
//  RenderEngine.cpp
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "RenderEngine.h"
#include "Model.h"
#include "ProgFactory.h"
#include "RenderContext.h"
#include "Program.h"

RenderTarget RenderEngine::renderTarget;

void RenderEngine::drawTextureToScreen(GLuint texId)
{
    RenderContext::reset();
    glDisable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    drawTexture(texId);
}

void RenderEngine::drawTexture(GLuint texId)
{
    Program &prog = ProgFactory::showTexProg;
    prog.use();
    prog.setTexture("tex", texId, 0);
    Quad::render();
}

void RenderEngine::setTarget(int n, ColorAttach **colorAttachs, const DepthAttach *depthAttach)
{
    renderTarget.setTarget(n, colorAttachs);
    renderTarget.setTarget(depthAttach);
}

void RenderEngine::setTarget(const ColorAttach *colorAttach, const DepthAttach *depthAttach)
{
    if (colorAttach == nullptr && depthAttach == nullptr)
    {
        renderTarget.unbind();
        return;
    }
    renderTarget.setTarget(colorAttach);
    renderTarget.setTarget(depthAttach);
}

