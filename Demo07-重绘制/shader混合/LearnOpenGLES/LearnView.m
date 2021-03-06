//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/11.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "LearnView.h"
#import "GLProgram.h"
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKit.h>

@interface LearnView()
@property (nonatomic , strong) EAGLContext* myContext;
@property (nonatomic , strong) CAEAGLLayer* myEagLayer;

@property (nonatomic , assign) GLuint myColorRenderBuffer;
@property (nonatomic , assign) GLuint myColorFrameBuffer;
@property (nonatomic , strong) GLProgram* mProgram;
@property (nonatomic , strong) GLProgram* mTextProgram;


@property (nonatomic , assign) GLuint myTexture0;
@property (nonatomic , assign) GLuint myTexture1;
@property (nonatomic , assign) GLuint myBuffer0;
@property (nonatomic , assign) GLuint myBuffer1;



- (void)setupLayer;

@end

@implementation LearnView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)update {
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self render];
}

- (void)customInit {
    [self setupLayer];
    
    [self setupContext];

    [self setupProgram];
    
    [self setupTextProgram];
}

- (void)render {
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.mProgram use];
    glBindBuffer(GL_ARRAY_BUFFER, self.myBuffer0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(1);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.mTextProgram use];
    glBindBuffer(GL_ARRAY_BUFFER, self.myBuffer1);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(1);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    
    
    
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setupProgram {
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    //读取文件路径
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    //加载shader
    self.mProgram = [[GLProgram alloc] initWithVertexShaderString:[NSString stringWithContentsOfFile:vertFile encoding:NSUTF8StringEncoding error:nil] fragmentShaderString:[NSString stringWithContentsOfFile:fragFile encoding:NSUTF8StringEncoding error:nil]];
    if (!self.mProgram.initialized)
    {
        [self.mProgram addAttribute:@"position"];
        [self.mProgram addAttribute:@"textCoordinate"];
        
        if (![self.mProgram link])
        {
            NSString *progLog = [self.mProgram programLog];
            NSLog(@"Program link log: %@", progLog);
            NSString *fragLog = [self.mProgram fragmentShaderLog];
            NSLog(@"Fragment shader compile log: %@", fragLog);
            NSString *vertLog = [self.mProgram vertexShaderLog];
            NSLog(@"Vertex shader compile log: %@", vertLog);
            self.mProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    GLuint texture0Uniform = [self.mProgram uniformIndex:@"myTexture0"];
    GLuint displayPositionAttribute = [self.mProgram attributeIndex:@"position"];
    GLuint displayTextureCoordinateAttribute = [self.mProgram attributeIndex:@"textCoordinate"];
    [self.mProgram use];
    glEnableVertexAttribArray(displayPositionAttribute);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);
    
    
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    glGenBuffers(1, &_myBuffer0);
    glBindBuffer(GL_ARRAY_BUFFER, _myBuffer0);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    
    glVertexAttribPointer(displayPositionAttribute, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(displayPositionAttribute);
    
    glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);
    
    //加载纹理
    [self setupFirstTexture:@"for_test"];
    glUniform1i(texture0Uniform, 0);
}



- (void)setupTextProgram {
    //读取文件路径
    NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shadervOther" ofType:@"vsh"];
    NSString* fragFile = [[NSBundle mainBundle] pathForResource:@"shaderfOther" ofType:@"fsh"];
    
    //加载shader
    self.mTextProgram = [[GLProgram alloc] initWithVertexShaderString:[NSString stringWithContentsOfFile:vertFile encoding:NSUTF8StringEncoding error:nil] fragmentShaderString:[NSString stringWithContentsOfFile:fragFile encoding:NSUTF8StringEncoding error:nil]];
    if (!self.mTextProgram.initialized)
    {
        [self.mTextProgram addAttribute:@"position"];
        [self.mTextProgram addAttribute:@"textCoordinate"];
        
        if (![self.mTextProgram link])
        {
            NSString *progLog = [self.mTextProgram programLog];
            NSLog(@"Program link log: %@", progLog);
            NSString *fragLog = [self.mTextProgram fragmentShaderLog];
            NSLog(@"Fragment shader compile log: %@", fragLog);
            NSString *vertLog = [self.mTextProgram vertexShaderLog];
            NSLog(@"Vertex shader compile log: %@", vertLog);
            self.mProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    GLuint texture1Uniform = [self.mTextProgram uniformIndex:@"myTexture1"];
    GLuint displayPositionAttribute = [self.mTextProgram attributeIndex:@"position"];
    GLuint displayTextureCoordinateAttribute = [self.mTextProgram attributeIndex:@"textCoordinate"];
    GLuint rotateMatrix = [self.mTextProgram uniformIndex:@"rotateMatrix"];
    [self.mTextProgram use];
    glEnableVertexAttribArray(displayPositionAttribute);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);
    
    
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        0.2f, -0.2f, -1.0f,     1.0f, 0.0f,
        -0.2f, 0.2f, -1.0f,     0.0f, 1.0f,
        -0.2f, -0.2f, -1.0f,    0.0f, 0.0f,
        0.2f, 0.2f, -1.0f,      1.0f, 1.0f,
        -0.2f, 0.2f, -1.0f,     0.0f, 1.0f,
        0.2f, -0.2f, -1.0f,     1.0f, 0.0f,
    };
    
    glGenBuffers(1, &_myBuffer1);
    glBindBuffer(GL_ARRAY_BUFFER, _myBuffer1);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    
    glVertexAttribPointer(displayPositionAttribute, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(displayPositionAttribute);
    
    glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);
    
    //加载纹理
    [self setupSecondTexture:@"abc"];
    
    glUniform1i(texture1Uniform, 1);

    glUniformMatrix4fv(rotateMatrix, 1, GL_FALSE, GLKMatrix4MakeZRotation(M_PI_4).m);
    
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}


- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];    
}


- (void)setupContext {
    // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    self.myContext = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    // 为 颜色缓冲区 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorRenderBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}


- (void)destoryRenderAndFrameBuffer
{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}




- (GLuint)setupFirstTexture:(NSString *)fileName {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &_myTexture0);
    glBindTexture(GL_TEXTURE_2D, self.myTexture0);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
//    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    return 0;
}



- (GLuint)setupSecondTexture:(NSString *)fileName {
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    glActiveTexture(GL_TEXTURE1);
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &(_myTexture1));
    glBindTexture(GL_TEXTURE_2D, self.myTexture1);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
//    glBindTexture(GL_TEXTURE_2D, 0);
    
    free(spriteData);
    return 0;
}
@end
