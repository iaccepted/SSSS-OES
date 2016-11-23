//
//  LoadTexture.h
//  seperableSSSS
//
//  Created by iaccepted on 16/4/13.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __seperableSSSS__LoadTexture__
#define __seperableSSSS__LoadTexture__

#include <vector>
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>
#include <gli/gli.hpp>

class LoadTexture
{
public:
    static GLuint CreateTexture3D(const char* path);
    static GLuint CreateTextureArray(char const* Filename);
    static GLuint CreateTexture_patch(const char* path, unsigned int internal_format, unsigned int external_format, unsigned int type);
    static GLuint CreateTexture(const char* path, bool srgb = false);
    static GLuint CreateTextureCubemap(const char* path);
    static GLuint CreateSimpleTextureCubemap();
    static void shut_down();
        
private:
    LoadTexture();
    
    static std::vector<GLuint> _textures;
};


#endif /* defined(__seperableSSSS__LoadTexture__) */
