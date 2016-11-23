//
//  Log.cpp
//  seperableSSSS
//
//  Created by iaccepted on 16/4/11.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#include "Log.h"

void Log::log(const char *err)
{
    printf("%s\n", err);
}

void Log::log(const int val)
{
    printf("%d\n", val);
}