//
//  Log.h
//  seperableSSSS
//
//  Created by iaccepted on 16/4/11.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#ifndef __seperableSSSS__Log__
#define __seperableSSSS__Log__

#include <stdio.h>

class Log
{
public:
    static void log(const char *err);
    static void log(const int val);
};

#endif /* defined(__seperableSSSS__Log__) */
