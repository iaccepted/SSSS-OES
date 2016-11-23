//
//  Model.cpp
//  SSSS-OES
//
//  Created by iaccepted on 16/4/18.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "Model.h"
#include <assert.h>
#import <GLKit/GLKit.h>
#import <glm/glm.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>
#include <assimp/Importer.hpp>
#include <iostream>
#include "GLError.h"

std::vector<Vertex> Model::vertices;
std::vector<GLuint> Model::indices;
GLuint Model::_vao;
GLuint Model::_vbo;
GLuint Model::_ebo;

static const char *getPath(const char *fileName)
{
    const char *path = [[[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:fileName] ofType:nullptr] UTF8String];
    return path;
}

GLuint Quad::_vao;
static float vertices[] =
{
    -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
    -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,
    1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
    -1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
    1.0f, -1.0f, 0.0f, 1.0f, 0.0f,
    1.0f, 1.0f, 0.0f, 1.0f, 1.0f
};

void Quad::init()
{
    bindData();
}

void Quad::bindData()
{
    GLuint vbo;
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
    
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (GLvoid *)0);
    
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (GLvoid *)(3 * sizeof(GLfloat)));
    
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void Quad::bind()
{
    assert(_vao != 0);
    glBindVertexArray(_vao);
}

void Quad::unbind()
{
    glBindVertexArray(0);
}

void Quad::render()
{
    bind();
    glDrawArrays(GL_TRIANGLES, 0, 6);
    unbind();
}

void Model::init(const char *fileName)
{
    loadScene(fileName);
    bindData();
}

void Model::loadScene(const char *fileName)
{
    const char *path = getPath(fileName);
    Assimp::Importer importer;
    
    const aiScene *scene = importer.ReadFile(path, aiProcess_JoinIdenticalVertices | aiProcess_SortByPType | aiProcess_GenSmoothNormals | aiProcess_CalcTangentSpace);
    
    if (!scene)
    {
        cerr << "Failed to load model!" << endl;
        exit(-2);
    }
    
    unsigned nVertices = 0;
    unsigned nTriangles = 0;
    
    unsigned nMeshes = scene->mNumMeshes;
    for (unsigned i = 0; i < nMeshes; ++i)
    {
        aiMesh *mesh = scene->mMeshes[i];
        nVertices += mesh->mNumVertices;
        nTriangles += mesh->mNumFaces;
    }
    
    vertices.reserve(nVertices);
    indices.reserve(3 * nTriangles);
    
    for (unsigned i = 0; i < nMeshes; ++i)
    {
        aiMesh *mesh = scene->mMeshes[i];
        
        unsigned mnVertices = mesh->mNumVertices;
        for (unsigned j = 0; j < mnVertices; ++j)
        {
            vertices.push_back(Vertex());
            aiVector3D v = mesh->mVertices[j];
            aiVector3D n = mesh->mNormals[j];
            aiVector3D uv = mesh->mTextureCoords[0][j];
            aiVector3D tangent = mesh->mTangents[j];
            aiVector3D bitangent = mesh->mBitangents[j];
            
            Vertex &cur = vertices.back();
            cur.position = glm::vec3(v.x, v.y, v.z);
            cur.normal = glm::vec3(n.x, n.y, n.z);
            cur.uv = glm::vec2(uv.x, uv.y);
            cur.tangent = glm::vec3(tangent.x, tangent.y, tangent.z);
            cur.bitangent = glm::vec3(bitangent.x, bitangent.y, bitangent.z);
        }
        
        unsigned mnFaces = mesh->mNumFaces;
        for (unsigned j = 0; j < mnFaces; ++j)
        {
            aiFace face = mesh->mFaces[j];
            indices.push_back(face.mIndices[0]);
            indices.push_back(face.mIndices[1]);
            indices.push_back(face.mIndices[2]);
        }
    }
    
//    cout << vertices.size() << endl;
//    cout << indices.size() << endl;
}

void Model::bindData()
{
    
    glGenVertexArrays(1, &_vao);
    glGenBuffers(1, &_vbo);
    glGenBuffers(1, &_ebo);
    
    glBindVertexArray(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * vertices.size(), &vertices[0], GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * indices.size(), &indices[0], GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
    glEnableVertexAttribArray(0);
    
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, normal));
    glEnableVertexAttribArray(1);
    
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, uv));
    glEnableVertexAttribArray(2);
    
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, tangent));
    glEnableVertexAttribArray(3);
    
    glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, bitangent));
    glEnableVertexAttribArray(4);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

}

void Model::bind()
{
    assert(_vao != 0);
    glBindVertexArray(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
}

void Model::unbind()
{
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

void Model::render()
{
    bind();
    glDrawElements(GL_TRIANGLES, (GLsizei)indices.size(), GL_UNSIGNED_INT, (GLvoid *)0);
    unbind();
    
    
}