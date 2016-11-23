//
//  RenderContext.cpp
//  seperableSSSS
//
//  Created by iaccepted on 16/4/11.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#import "RenderContext.h"
#import "Camera.h"
#import "GLError.h"
#import <iostream>
#import <sstream>
#import <OpenGLES/ES3/gl.h>
#import "Global.h"

Camera *RenderContext::_camera;
GLKView *RenderContext::_view;
float RenderContext::_nearPlane;
float RenderContext::_farPlane;
Light RenderContext::lights[N_LIGHTS];
int RenderContext::_width;
int RenderContext::_height;
glm::mat4 RenderContext::_worldM;


void RenderContext::init(int width, int height, GLKView *view)
{
    _width = width;
    _height = height;
    _view = view;
    _nearPlane = NEAR_PLANE;
    _farPlane = FAR_PLANE;
    _worldM = glm::mat4(1.0f);
    _camera = new Camera();
    _camera->setProjection(glm::radians(20.0f), (float)width / height, _nearPlane, _farPlane);
    _camera->setViewportSize(glm::vec2(_width, _height));
    
    for (int i = 0; i < N_LIGHTS; ++i)
    {
        lights[i].init();
    }
    
    //init camera and lights
    loadPreset();
}

glm::mat4 RenderContext::getmvp()
{
    return _camera->getProjectionMatrix() * _camera->getViewMatrix() * _worldM;
}

void RenderContext::reset()
{
    [_view bindDrawable];
}

void RenderContext::update(float delta)
{
    _camera->frameMove(delta);
    for (int i = 0; i < N_LIGHTS; ++i)
    {
        lights[i].camera.frameMove(delta);
    }
}
void RenderContext::touchMoved(Controller controller, float dx, float dy)
{
    //std::cout << dx << "---" << dy << std::endl;
    if (controller == Controller::CAMERA)_camera->touchMoved(dx, dy);
    else if (controller == Controller::LIGHT0)lights[0].camera.touchMoved(dx, dy);
    else if (controller == Controller::LIGHT1)lights[1].camera.touchMoved(dx, dy);
    else lights[2].camera.touchMoved(dx, dy);
}

void RenderContext::scale(float s)
{
    _camera->scale(s);
}

void RenderContext::loadPreset()
{
    const char *path = [[[NSBundle mainBundle] pathForResource:@"Preset9.txt" ofType:nullptr] UTF8String];
    std::ifstream reader(path, std::ios::in);
    stringstream ss;
    ss << reader.rdbuf();
    ss >> (*_camera);
    _camera->build();
    
    for (int i = 0; i < N_LIGHTS; ++i)
    {
        ss >> lights[i];
    }
    
    reader.close();
}

