//
//  CDVCamera.h
//  ImagePicker
//
//  Created by Wilson on 2017/8/16.
//  Copyright © 2017年 Wilson. All rights reserved.
//

#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>

@interface CDVCamera : CDVPlugin

//打开相机
- (void)openCamera:(CDVInvokedUrlCommand *)command;

//获取universal-links的返回值
- (void)getUniversalLinks:(CDVInvokedUrlCommand *)command;

//清除universal-links的值
- (void)clearUniversalLinks:(CDVInvokedUrlCommand *)command;

@end
