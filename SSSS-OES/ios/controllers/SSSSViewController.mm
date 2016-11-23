//
//  SSSSViewController.m
//  seperableSSSS
//
//  Created by iaccepted on 16/4/11.
//  Copyright (c) 2016年 iaccepted. All rights reserved.
//

#import "SSSSViewController.h"
#import "Log.h"
#import "RenderContext.h"
#import "HeadRender.h"
#import "LoadTexture.h"
#import "RenderEngine.h"
#import "GLError.h"


@interface SSSSViewController()
{
    HeadRender headRender;
    Controller controller;
    
    UISlider *lightIntensity[N_LIGHTS];
    UIButton *btns[N_LIGHTS + 1];
    
    UIButton *_preBtn;
    UISlider *_preSld;
    
    UILabel *fxaaLabel;
    UISwitch *fxaaSwitch;
}

@property (strong, nonatomic)EAGLContext *context;

@end

@implementation SSSSViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    self.context.multiThreaded = YES;
    
    if (!self.context)
    {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    self.preferredFramesPerSecond =60;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableColorFormat = GLKViewDrawableColorFormatSRGBA8888;
    view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    
    [self setupGL];
    [self initUI];
    [self bindEvents];
//    [self setupDisplayLink];
}

//- (void)setupDisplayLink
//{
//    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
//    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//}

- (void)selectBtn:(UIButton *)btn
{
    [_preBtn setBackgroundColor:[UIColor grayColor]];
    [btn setBackgroundColor:[UIColor greenColor]];
    //[_preSld setEnabled:FALSE];
    if (btn == btns[0])
    {
        controller = Controller::CAMERA;
        //NSLog(@"camera");
    }
    else if (btn == btns[1])
    {
        controller = Controller::LIGHT0;
        //[lightIntensity[0] setEnabled:TRUE];
        _preSld = lightIntensity[0];
        //NSLog(@"light0");
    }
    else if (btn == btns[2])
    {
        controller = Controller::LIGHT1;
        //[lightIntensity[1] setEnabled:TRUE];
        _preSld = lightIntensity[1];
        //NSLog(@"light1");
    }
    else// _light2Btn
    {
        controller = Controller::LIGHT2;
        //[lightIntensity[2] setEnabled:TRUE];
        _preSld = lightIntensity[2];
       // NSLog(@"light2");
    }
    
    _preBtn = btn;
}

- (void)sliderChanged:(UISlider *)sender
{
    //light.color = light.intensity * vec3(1.0, 1.0, 1.0); set when tranfer light information to shader,Demo.cpp  line 1344
    if (sender == lightIntensity[0])
    {
        RenderContext::lights[0].intensity = sender.value;
    }
    else if (sender == lightIntensity[1])
    {
        RenderContext::lights[1].intensity = sender.value;
    }
    else
    {
        RenderContext::lights[2].intensity = sender.value;
    }
}

- (void)fxaaFunc:(UISwitch *)sender
{
    if ([sender isOn])
    {
        headRender.setFxaaEnabled(YES);
        fxaaLabel.backgroundColor = [UIColor greenColor];
    }
    else
    {
        headRender.setFxaaEnabled(NO);
        fxaaLabel.backgroundColor = [UIColor grayColor];
    }
}

- (void)initUI
{
    //select buttons
    int x = 10, y = 10, w = 50, h = 30;
    NSString *titles[N_LIGHTS + 1] = {@"camera", @"light0", @"light1", @"light2"};
    for (int i = 0; i < N_LIGHTS + 1; ++i)
    {
        btns[i] = [[UIButton alloc] initWithFrame:CGRectMake(x, y, w, h)];
        [btns[i] setBackgroundColor:[UIColor grayColor]];
        [btns[i].layer setCornerRadius:10.0f];
        [btns[i] setTitle:titles[i] forState:UIControlStateNormal];
        btns[i].titleLabel.font = [UIFont systemFontOfSize:12.0f];
        [btns[i] addTarget:self action:@selector(selectBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btns[i]];
        y += (h + 10);
    }
    _preBtn = btns[0];
    controller = Controller::CAMERA;
    
    //light intensity
    for (int i = 0; i < N_LIGHTS; ++i)
    {
        CGPoint origin = btns[i + 1].frame.origin;
        lightIntensity[i] = [[UISlider alloc] initWithFrame:CGRectMake(origin.x + 60, origin.y + 10, 200, 5)];
        //lightIntensity[i].enabled = FALSE;
        lightIntensity[i].minimumValue = 0.0f;
        lightIntensity[i].maximumValue = 5.0f;
        lightIntensity[i].value = RenderContext::lights[i].color.r;
        [lightIntensity[i] addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:lightIntensity[i]];
    }
    _preSld = lightIntensity[0];
    [_preBtn setBackgroundColor:[UIColor greenColor]];
    
    x = 10;
    y = 10;
    //switch
    fxaaLabel = [[UILabel alloc] initWithFrame:CGRectMake(x + 90, y, w, h)];
    [fxaaLabel setText:@"FXAA"];
    [fxaaLabel setBackgroundColor:[UIColor grayColor]];
    [fxaaLabel.layer setCornerRadius:10.0f];
    [fxaaLabel.layer setMasksToBounds:YES];
    fxaaLabel.textColor = [UIColor whiteColor];
    fxaaLabel.font = [UIFont systemFontOfSize:12.0f];
    fxaaLabel.textAlignment = NSTextAlignmentCenter;
    fxaaSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(x + 150, y, 2 * w, h)];
    fxaaSwitch.on = NO;
    [fxaaSwitch addTarget:self action:@selector(fxaaFunc:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:fxaaLabel];
    [self.view addSubview:fxaaSwitch];
}

- (void)bindEvents
{
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panedEvent:)];
    [self.view addGestureRecognizer:panRecognizer];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchedEvent:)];
    [self.view addGestureRecognizer:pinchRecognizer];
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    //init static class such as RenderContex + Quad
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClearDepthf(1.0);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    //init headRender
    CGSize size = [[UIScreen mainScreen] bounds].size;
    glViewport(0, 0, 2 * size.width, 2 * size.height);
    headRender.init(2 * size.width, 2 * size.height, (GLKView *)self.view);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
}

- (void)dealloc
{
    [self tearDownGL];
    if ([EAGLContext currentContext] == self.context)
    {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//- (void)render:(id)sender
//{
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        RenderContext::update(0.1f);
//        headRender.render();
//    }];
//    
//}

////render part
- (void)update
{
//    NSLog(@"UPDATE");
    static UInt64 last = [[NSDate date] timeIntervalSince1970] * 1000;
    UInt64 now = [[NSDate date] timeIntervalSince1970] * 1000;
    
    float delta = (now - last) * 0.001;
    last = now;
    RenderContext::update(delta);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
//    NSLog(@"DRAW");
    headRender.render();
}

//touch events

- (void)panedEvent:(UIPanGestureRecognizer *)sender
{
    CGPoint dir = [sender translationInView:self.view];
    RenderContext::touchMoved(controller, dir.x, dir.y);
    //RenderContext::_camera->touchMoved(dir.x, dir.y);
    //NSLog(@"%f--%f", dir.x, dir.y);
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void)pinchedEvent:(UIPinchGestureRecognizer *)sender
{
    //NSLog(@"YES, PINCH");
    float s = [sender scale];
    
    //cout << "nochange :" <<s << endl;
    s = 1.0f/s;
    s = (s - 1) * 0.25 + 1.0f;
    //cout << "change :" << s << endl;
    RenderContext::scale(s);
}
@end
