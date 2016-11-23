//
//  LoadTexture.cpp
//  seperableSSSS
//
//  Created by iaccepted on 16/4/13.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "LoadTexture.h"
#import <GLKit/GLKit.h>

std::vector<GLuint> LoadTexture::_textures;

static const char *getPath(const char *fileName)
{
    const char *path = [[[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:fileName] ofType:nullptr] UTF8String];
    return path;
}

GLuint LoadTexture::CreateSimpleTextureCubemap()
{
    GLuint texture_id;
    // Six 1x1 RGB faces
    GLubyte cubePixels[6][3] =
    {
        // Face 0 - Red
        255, 0, 0,
        // Face 1 - Green,
        0, 255, 0,
        // Face 2 - Blue
        0, 0, 255,
        // Face 3 - Yellow
        255, 255, 0,
        // Face 4 - Purple
        255, 0, 255,
        // Face 5 - White
        255, 255, 255
    };
    
    // Generate a texture object
    glGenTextures(1, &texture_id);
    
    // Bind the texture object
    glBindTexture(GL_TEXTURE_CUBE_MAP, texture_id);
    // Load the cube face - Positive X
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGB, 1, 1, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, &cubePixels[0]);
    // Load the cube face - Negative X
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGB, 1, 1, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, &cubePixels[1]);
    // Load the cube face - Positive Y
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGB, 1, 1, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, &cubePixels[2]);
    // Load the cube face - Negative Y
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGB, 1, 1, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, &cubePixels[3]);
    // Load the cube face - Positive Z
    glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGB, 1, 1, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, &cubePixels[4]);
    // Load the cube face - Negative Z
    glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGB, 1, 1, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, &cubePixels[5]);
    // Set the filtering mode
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    
    _textures.push_back(texture_id);
    return texture_id;
}

GLuint LoadTexture::CreateTextureCubemap(const char* fileName)
{
    gli::textureCube texture(gli::load_dds(getPath(fileName)));
    assert(!texture.empty());
    //printf("%d %d\n", texture.levels(), texture.layers());
    gli::gl GL;
    gli::gl::format const format = GL.translate(texture.format());
    //printf("%s\n\t%X %X %X\n", path, format.Internal, format.External, format.Type);
    GLuint textureName = 0;
    glGenTextures(1, &textureName);
    glBindTexture(GL_TEXTURE_CUBE_MAP, textureName);
    //auto l = texture.levels();
    //auto w = texture[0].dimensions().x;
    //auto h = texture[0].dimensions().y;
    glTexStorage2D(GL_TEXTURE_CUBE_MAP, GLint(texture.levels()),
                   format.Internal,
                   GLsizei(texture[0].dimensions().x),
                   GLsizei(texture[0].dimensions().y));
    
    assert(!gli::is_compressed(texture.format()));
    
    for (int face = 0; face < 6; face++)
        for (int level = 0; level < texture.levels(); ++level)
        {
            auto t = texture[face][level];
            glTexSubImage2D(
                            GL_TEXTURE_CUBE_MAP_POSITIVE_X + GLenum(face),
                            level,
                            0, 0,
                            GLsizei(t.dimensions().x),
                            GLsizei(t.dimensions().y),
                            format.External,
                            format.Type,
                            t.data()
                            );
        }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAX_LEVEL, 0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    _textures.push_back(textureName);
    return textureName;
}

GLuint LoadTexture::CreateTexture(const char* fileName, bool srgb)
{
    //Debug::LogInfo(path);
    
    gli::texture2D texture(gli::load_dds(getPath(fileName)));
    assert(!texture.empty());
    //printf("%d %d\n", Texture.levels(), Texture.layers());
    gli::gl GL;
    gli::gl::format const format = GL.translate(texture.format());
    //printf("%s\n\t%X %X %X\n", fileName, format.Internal, format.External, format.Type);
    GLuint texture_name = 0;
    glGenTextures(1, &texture_name);
    glBindTexture(GL_TEXTURE_2D, texture_name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, static_cast<GLint>(texture.levels() - 1));
    
    // hack
    int f = format.Internal;
    if (srgb && f == gli::gl::INTERNAL_RGBA8_UNORM)
    {
        //f = 0x8C4F;
        f = gli::gl::INTERNAL_SRGB8_ALPHA8;
    }
    
    // for beckman
    if (f == gli::gl::INTERNAL_RG8_UNORM)
    {
        f = gli::gl::INTERNAL_R8_UNORM;
    }
    
    glTexStorage2D(GL_TEXTURE_2D, static_cast<GLint>(texture.levels()),
                   f,
                   static_cast<GLsizei>(texture.dimensions().x),
                   static_cast<GLsizei>(texture.dimensions().y));
    
    if (gli::is_compressed(texture.format()))
    {
        
        for (std::size_t level = 0; level < texture.levels(); ++level)
        {
            glCompressedTexSubImage2D(GL_TEXTURE_2D, static_cast<GLint>(level),
                                      0, 0,
                                      static_cast<GLsizei>(texture[level].dimensions().x),
                                      static_cast<GLsizei>(texture[level].dimensions().y),
                                      f,
                                      static_cast<GLsizei>(texture[level].size()),
                                      texture[level].data());
        }
    }
    else
    {
        for (std::size_t Level = 0; Level < texture.levels(); ++Level)
        {
            glTexSubImage2D(GL_TEXTURE_2D, static_cast<GLint>(Level),
                            0, 0,
                            static_cast<GLsizei>(texture[Level].dimensions().x),
                            static_cast<GLsizei>(texture[Level].dimensions().y),
                            format.External,
                            format.Type,
                            texture[Level].data());
        }
    }
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    //glGenerateMipmap(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    _textures.push_back(texture_name);
    return texture_name;
}

GLuint LoadTexture::CreateTexture_patch(const char *fileName, unsigned int internal_format, unsigned int external_format, unsigned int type)
{
    gli::texture2D texture(gli::load_dds(getPath(fileName)));
    assert(!texture.empty());
    gli::gl GL;
    gli::gl::format const format = GL.translate(texture.format());
    printf("%s\n\t%X %X %X\n", fileName, format.Internal, format.External, format.Type);
    if (external_format == 0)
        external_format = format.External;
    if (type == 0)
        type = format.Type;
    GLuint texture_name = 0;
    glGenTextures(1, &texture_name);
    glBindTexture(GL_TEXTURE_2D, texture_name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, static_cast<GLint>(texture.levels() - 1));
    
    if (gli::is_compressed(texture.format()))
    {
        for (std::size_t level = 0; level < texture.levels(); ++level)
        {
            glCompressedTexImage2D(GL_TEXTURE_2D, static_cast<GLint>(level),
                                   internal_format,
                                   static_cast<GLsizei>(texture[level].dimensions().x),
                                   static_cast<GLsizei>(texture[level].dimensions().y),
                                   0,
                                   static_cast<GLsizei>(texture[level].size()),
                                   texture[level].data());
        }
    }
    else
    {
        for (std::size_t Level = 0; Level < texture.levels(); ++Level)
        {
            glTexImage2D(GL_TEXTURE_2D, static_cast<GLint>(Level),
                         internal_format,
                         static_cast<GLsizei>(texture[Level].dimensions().x),
                         static_cast<GLsizei>(texture[Level].dimensions().y),
                         static_cast<GLsizei>(0),
                         external_format, type,
                         texture[Level].data());
        }
    }
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    //glGenerateMipmap(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    _textures.push_back(texture_name);
    return texture_name;
}

GLuint LoadTexture::CreateTextureArray(char const* Filename)
{
    gli::texture2D Texture(gli::load_dds(Filename));
    assert(!Texture.empty());
    //printf("%d %d\n", Texture.levels(), Texture.layers());
    gli::gl GL;
    gli::gl::format const Format = GL.translate(Texture.format());
    GLuint texture_id = 0;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D_ARRAY, texture_id);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_MAX_LEVEL, static_cast<GLint>(Texture.levels() - 1));
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_SWIZZLE_R, Format.Swizzle[0]);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_SWIZZLE_G, Format.Swizzle[1]);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_SWIZZLE_B, Format.Swizzle[2]);
    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_SWIZZLE_A, Format.Swizzle[3]);
    glTexStorage3D(GL_TEXTURE_2D_ARRAY, static_cast<GLint>(Texture.levels()),
                   Format.Internal,
                   static_cast<GLsizei>(Texture.dimensions().x),
                   static_cast<GLsizei>(Texture.dimensions().y),
                   static_cast<GLsizei>(1));
    if (gli::is_compressed(Texture.format()))
    {
        for (std::size_t Level = 0; Level < Texture.levels(); ++Level)
        {
            glCompressedTexSubImage3D(GL_TEXTURE_2D_ARRAY, static_cast<GLint>(Level),
                                      0, 0, 0,
                                      static_cast<GLsizei>(Texture[Level].dimensions().x),
                                      static_cast<GLsizei>(Texture[Level].dimensions().y),
                                      static_cast<GLsizei>(1),
                                      Format.External,
                                      static_cast<GLsizei>(Texture[Level].size()),
                                      Texture[Level].data());
        }
    }
    else
    {
        for (std::size_t Level = 0; Level < Texture.levels(); ++Level)
        {
            glTexSubImage3D(GL_TEXTURE_2D_ARRAY, static_cast<GLint>(Level),
                            0, 0, 0,
                            static_cast<GLsizei>(Texture[Level].dimensions().x),
                            static_cast<GLsizei>(Texture[Level].dimensions().y),
                            static_cast<GLsizei>(1),
                            Format.External, Format.Type,
                            Texture[Level].data());
        }
    }
    _textures.push_back(texture_id);
    return texture_id;
}

GLuint LoadTexture::CreateTexture3D(const char* fileName)
{
    gli::texture3D texture(gli::load_dds(getPath(fileName)));
    assert(!texture.empty());
    //printf("%d %d\n", texture.levels(), texture.layers());
    gli::gl GL;
    gli::gl::format const format = GL.translate(texture.format());
    //printf("%d %d %d\n", texture.dimensions().x, texture.dimensions().y, texture.dimensions().z);
    GLuint texture_id = 0;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_3D, texture_id);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_BASE_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAX_LEVEL, static_cast<GLint>(texture.levels() - 1));
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, Format.Swizzle[0]);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_G, Format.Swizzle[1]);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, Format.Swizzle[2]);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_A, Format.Swizzle[3]);
    //glTexStorage3D(GL_TEXTURE_3D, static_cast<GLint>(texture.levels()),
    //	format.Internal,
    //	static_cast<GLsizei>(texture.dimensions().x),
    //	static_cast<GLsizei>(texture.dimensions().y),
    //	static_cast<GLsizei>(texture.dimensions().z));
    
    // hack
    int f = format.Internal;
    // for Noise.dds
    if (f == gli::gl::INTERNAL_RG8_UNORM)
    {
        f = gli::gl::INTERNAL_R8_UNORM;
    }
    
    if (gli::is_compressed(texture.format()))
    {
        for (std::size_t level = 0; level < texture.levels(); ++level)
        {
            glCompressedTexImage3D(GL_TEXTURE_3D, static_cast<GLint>(level),
                                   f,
                                   static_cast<GLsizei>(texture[level].dimensions().x),
                                   static_cast<GLsizei>(texture[level].dimensions().y),
                                   static_cast<GLsizei>(texture[level].dimensions().z),
                                   0,
                                   static_cast<GLsizei>(texture[level].size()),
                                   texture[level].data());
        }
    }
    else
    {
        for (std::size_t Level = 0; Level < texture.levels(); ++Level)
        {
            glTexImage3D(GL_TEXTURE_3D, static_cast<GLint>(Level),
                         f,
                         static_cast<GLsizei>(texture[Level].dimensions().x),
                         static_cast<GLsizei>(texture[Level].dimensions().y),
                         static_cast<GLsizei>(texture[Level].dimensions().z),
                         0,
                         //static_cast<GLsizei>(1),
                         format.External, format.Type,
                         texture[Level].data());
        }
    }
    //        check_gl_error();
    
    
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    //glGenerateMipmap(GL_TEXTURE_3D);
    glBindTexture(GL_TEXTURE_3D, 0);
    
    _textures.push_back(texture_id);
    
    return texture_id;
}

void LoadTexture::shut_down()
{
    glDeleteTextures((GLsizei)_textures.size(), &_textures[0]);
}

