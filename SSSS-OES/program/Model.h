//
//  Model.h
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __SSSS_OES__Model__
#define __SSSS_OES__Model__
#include <OpenGLES/ES3/gl.h>
#include <glm/glm.hpp>
#include <vector>

using namespace std;

//feng zhuang the data used to draw a texture
class Quad
{
public:
    static void init();
    static void render();
    
    
private:
    static void bind();
    static void unbind();
    static void bindData();
    static GLuint _vao;
};

class Vertex
{
public:
    glm::vec3 position;
    glm::vec3 normal;
    glm::vec3 tangent;
    glm::vec3 bitangent;
    glm::vec2 uv;
};

class Model
{
public:
    static void init(const char *fileName);
    static void render();
    
private:
    static void loadScene(const char *fileName);
    static void bindData();
    static void bind();
    static void unbind();
    static std::vector<Vertex> vertices;
    static std::vector<GLuint> indices;
    
    static GLuint _vao, _vbo, _ebo;
};

#endif /* defined(__SSSS_OES__Model__) */
