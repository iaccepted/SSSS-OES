//
//  RenderContext.h
//  seperableSSSS
//
//  Created by iaccepted on 16/4/11.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __seperableSSSS__RenderContext__
#define __seperableSSSS__RenderContext__

#include "Camera.h"
#include <iostream>
#include <fstream>
#import <glm/glm.hpp>
#import <GLKit/GLKit.h>
#include "ShadowMap.h"
#include "Global.h"

using namespace std;

typedef enum
{
    CAMERA = 0, LIGHT0, LIGHT1, LIGHT2
}Controller;

const float PI = 3.1415926536f;

class Light;

class RenderContext
{
public:
    static Camera *_camera;
    static Light lights[N_LIGHTS];
    static GLKView *_view;
    static int _width;
    static int _height;
    static float _farPlane;
    static float _nearPlane;
    static glm::mat4 _worldM;
    
    static void init(int width, int height, GLKView *view);
    static void reset();
    static void update(float delta);
    static void touchMoved(Controller controller, float dx, float dy);
    static void scale(float s);
    static glm::mat4 getmvp();
    static glm::mat4 getTIM()
    {
        return glm::transpose(glm::inverse(_worldM));
    }
    
private:
    static void loadPreset();
    
};

class Light
{
public:
    Light(){}
    void init()
    {
        fov = 45.0f * PI / 180.f;
        falloffWidth = 0.05f;
        attenuation = 1.0f / 128.0f;
        
        bias = -0.01f;
        
        camera.setDistance(2.0);
        camera.setProjection(fov, 1.0f, RenderContext::_nearPlane, RenderContext::_farPlane);
        color = vec3(0.0f, 0.0f, 0.0f);
        intensity = 0.0f;
        shadowMap.init();
        camera.setViewportSize(RenderContext::_width, RenderContext::_height);
    }
    
    friend std::ostream& operator <<(std::ostream &os, const Light &light)
    {
        os << light.camera;
        os << light.color.x << std::endl;
        os << light.color.y << std::endl;
        os << light.color.z << std::endl;
        
        return os;
    }
    
    friend std::istream& operator >>(std::istream &is, Light &light)
    {
        is >> light.camera;
        is >> light.color.x;
        is >> light.color.y;
        is >> light.color.z;
        light.intensity = light.color.x;
        
        light.camera.build();
        
        return is;
    }
    
    ShadowMap shadowMap;
    Camera camera;
    float fov;
    float falloffWidth;
    float intensity;
    glm::vec3 color;
    float attenuation;
    float bias;
    
};

#endif /* defined(__seperableSSSS__RenderContext__) */
