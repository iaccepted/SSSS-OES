//
//  ProgFactory.h
//  seperableSSSS
//
//  Created by iaccepted on 16/4/13.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __seperableSSSS__ProgFactory__
#define __seperableSSSS__ProgFactory__

#include <stdio.h>

class Program;

class ProgFactory
{
public:
    static Program showTexProg;
    static Program mainProg;
    static Program addSpecProg;
    static Program ssssProg;
    static Program shadowProg;
    static Program fxaaProg;
    static Program ssaoProg;
    
    static Program testProg;
    
    static void init();
};

#endif /* defined(__seperableSSSS__ProgFactory__) */
