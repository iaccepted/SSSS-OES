//
//  ProgFactory.cpp
//  seperableSSSS
//
//  Created by iaccepted on 16/4/13.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "ProgFactory.h"
#include "Program.h"
#import <UIKit/UIKit.h>

static const char *getPath(const char *fileName)
{
    const char *path = [[[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:fileName] ofType:nullptr] UTF8String];
    return path;
}

Program ProgFactory::showTexProg;
Program ProgFactory::mainProg;
Program ProgFactory::addSpecProg;
Program ProgFactory::ssssProg;
Program ProgFactory::shadowProg;
Program ProgFactory::testProg;
Program ProgFactory::fxaaProg;
Program ProgFactory::ssaoProg;

void ProgFactory::init()
{
    showTexProg.compileShaderFromFile(getPath("showTex.vert"), getPath("showTex.frag"));
    shadowProg.compileShaderFromFile(getPath("shadowMap.vert"), getPath("shadowMap.frag"));
    mainProg.compileShaderFromFile(getPath("main.vert"), getPath("main.frag"));
    ssssProg.compileShaderFromFile(getPath("ssss.vert"), getPath("ssss.frag"));
    fxaaProg.compileShaderFromFile(getPath("fxaa.vert"), getPath("fxaa.frag"));
    ssaoProg.compileShaderFromFile(getPath("ssao.vert"), getPath("ssao.frag"));
}