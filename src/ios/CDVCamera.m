//
//  CDVCamera.m
//  ImagePicker
//
//  Created by Wilson on 2017/8/16.
//  Copyright © 2017年 Wilson. All rights reserved.
//

#import "CDVCamera.h"
#import "AppDelegate.h"
#import "HTTPRequestManager.h"
#import "ZYQAssetPickerController.h"
#import <Photos/Photos.h>

CGFloat ActionSheetHeight = 160;
#define MAX_PHOTHO_NUMS 3
static NSString * FAILED = @"上传失败";

@interface CDVCamera ()<UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ZYQAssetPickerControllerDelegate>
{
    NSInteger _currentPhotoIndex;
    NSInteger _failedCount;
}
@property (nonatomic, weak) UIView * container;

@property (nonatomic, strong) NSMutableArray * data;

@property (nonatomic, weak) UIControl * mask;

@property (nonatomic, strong) CDVInvokedUrlCommand * command;

//上传完毕后返回的相片信息
@property (nonatomic, strong) NSMutableArray * photosResults;

//从相册中选择出来的相册数组
@property (nonatomic, strong) NSMutableArray * photosPicked;


@end

@implementation CDVCamera

- (void)dealloc {
    [self.photosResults removeAllObjects];
    [self.photosPicked removeAllObjects];
    
    self.photosPicked = nil;
    self.photosResults = nil;
}

- (void)openCamera:(CDVInvokedUrlCommand *)command {
    
    if(self.photosPicked) {
        [self.photosPicked removeAllObjects];
    }
    
    if(self.photosResults) {
        [self.photosResults removeAllObjects];
    }
    
    self.command = command;
    _currentPhotoIndex = 0;
    _failedCount = 0;
    
    NSLog(@"调用了native");
    
    NSArray * section1 = @[@"手机相册选择",@"拍照"];
    NSArray * section2 = @[@"取消"];
    [self.data addObject:section1];
    [self.data addObject:section2];
    
    if (self.mask == nil) {
        UIControl * mask = [[UIControl alloc] initWithFrame:self.viewController.view.frame];
        mask.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.2f];
        [mask setHidden:YES];
        mask.userInteractionEnabled = YES;
        [self.viewController.view addSubview:mask];
        [mask addTarget:self action:@selector(hideActionSheet) forControlEvents:UIControlEventTouchUpInside];
        self.mask = mask;
    }
    
    [self initActionSheet];
}

#pragma mark - UI init
- (void)hideActionSheet {
    [UIView animateWithDuration:0.25 animations:^{
        [self.mask setHidden:YES];
        [self.container setFrame:CGRectMake(0, self.viewController.view.frame.size.height, self.viewController.view.frame.size.width, ActionSheetHeight)];
    }];
}

- (void)showActionSheet {
    [UIView animateWithDuration:0.25 animations:^{
        [self.mask setHidden:NO];
        [self.container setFrame:CGRectMake(0, self.viewController.view.frame.size.height - ActionSheetHeight, self.viewController.view.frame.size.width, ActionSheetHeight)];
    }];
}

- (void)initActionSheet{
    
    //container
    if (self.container == nil) {
        UIView * container = [[UIView alloc] initWithFrame:CGRectMake(0, self.viewController.view.frame.size.height, self.viewController.view.frame.size.width, ActionSheetHeight)];
        container.backgroundColor = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1];
        [self.viewController.view addSubview:container];
        self.container = container;
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.container.frame), CGRectGetHeight(self.container.frame)) style:UITableViewStyleGrouped];
        NSLog(@"y = %lf - h = %lf", CGRectGetMinY(tableView.frame),CGRectGetHeight(tableView.frame));
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.scrollEnabled = NO;
        tableView.tableFooterView = [UIView new];
        tableView.separatorColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
        [self.container addSubview:tableView];
    }
    [self performSelector:@selector(showActionSheet) withObject:nil afterDelay:0.1];

}

#pragma mark - tableview - delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray * array = [self.data objectAtIndex:section];
    return array.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView * header = [UIView new];
    [header setBackgroundColor:[UIColor clearColor]];
    
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView * footer = [UIView new];
    [footer setBackgroundColor:[UIColor clearColor]];
    
    return footer;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (ActionSheetHeight - 10) / 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if(section == 0) {
        return 10.f;
    }
    return 0.1f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"camera-cell";
    UITableViewCell * cell  = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundView.backgroundColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    [cell.textLabel setFont:[UIFont fontWithName:@"Arial" size:17.f]];
    [cell.textLabel setTextColor:[UIColor colorWithRed:38/255.0f green:38/255.0f blue:38/255.0f alpha:1.0f]];
    [cell.textLabel setText: [[self.data objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == 0 && indexPath.row == 0) {
        //手机相册选择
        NSString * echo = [self.command argumentAtIndex:1];
        if([echo isEqualToString:@"single"]) {
            //单张图片处理
            [self takePictureFromLibrary];
        } else if([echo isEqualToString:@"multiple"]){
            //多张图片处理
            [self takeMultiplePhotosFromLibrary];
        } else {
            //异常
            [self uploadPhotosFailed];
        }
    } else if (indexPath.section == 0 && indexPath.row == 1) {
        //拍照
        [self takePicture];
    } else {
        //取消
        [self hideActionSheet];
    }
}

#pragma mark - image picker action
//从相册中读取多张
- (void)takeMultiplePhotosFromLibrary {
    ZYQAssetPickerController * picker = [[ZYQAssetPickerController alloc] init];
    //考虑到用户可能分次选择图片，所以需要把上一次选择过的数量减掉
    picker.maximumNumberOfSelection = MAX_PHOTHO_NUMS - self.photosPicked.count;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.showEmptyGroups = NO;
    picker.delegate = self;
    picker.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        if([[(ALAsset *)evaluatedObject valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
        {
            NSTimeInterval duration = [[(ALAsset *)evaluatedObject valueForProperty:ALAssetPropertyDuration] doubleValue];
            return duration >= 5;
        }
        else
            return YES;
    }];
    [self kPresentViewController:picker];
}

- (void)assetPickerController:(ZYQAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(int i = 0; i < assets.count; i++) {
            ALAsset * asset = assets[i];
            UIImage * sourceImage = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
            sourceImage = [self imageFixOrientationWithSourceImage:sourceImage];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.photosPicked addObject:sourceImage];
                
                if(i == assets.count - 1) {
                    //如果已经是最后一张图片了，就开始处理上传， 循环调接口逐个上传图片
                    [self uploadMultiplePhotos:self.photosPicked];
                }
            });
        }
    });
}

#pragma mark - 批量上传
- (void)uploadMultiplePhotos:(NSArray *)photos {
    
    if(_failedCount > 2) {
        //如果已经请求失败超过两次了，则停止请求
        [self uploadPhotosFailed];
        return;
    }
    
    NSString * echoStr = [self.command argumentAtIndex:0];
    if(echoStr == nil || ![echoStr length]) {
        //如果上传接口不存在，则return，返回javascript
        [self uploadPhotosFailed];
        return;
    }
    
    if(_currentPhotoIndex == photos.count) {
        //如果已经上传了最后一张图片，则停止递归,然后将最终上传结果回传到javascript
        if(self.photosResults && self.photosResults.count) {
            [self uploadPhotosSuccess];
        } else {
            [self uploadPhotosFailed];
        }
        return;
    }
    
    UIImage * image = [self imageFixOrientationWithSourceImage:[photos objectAtIndex:_currentPhotoIndex]];
    //将图片转换成base64字节流的方式传给javascript 压缩
    NSData * imageData = UIImageJPEGRepresentation(image, 0.3);
    
    //将base64的图片字符串回传给javascript
    NSString * encodedString = [imageData base64Encoding];
    
    //开始处理上传
    //用时间戳生成图片名
    NSDate * dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a = [dat timeIntervalSince1970] * 1000;
    NSString * phoneName = [NSString stringWithFormat:@"NEWUpload%.0f.JPG", a];
    NSArray * uplodPhotos = [NSArray arrayWithObject:image];
    
    NSDictionary * dict = @{@"contentType":@"image/jpeg",
                            @"fileName":phoneName,
                            @"body": encodedString,
                            @"cutSize":@"300,300"};
    
    [[HTTPRequestManager shareInstance] uploadWithUrl:echoStr params:dict photos:uplodPhotos progress:^(NSProgress *progress){
        
        CDVPluginResult * pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"0"];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
        
    } success:^(HTTPRequestManager *manager, id model) {
        
        NSArray * array = model;
        NSDictionary * dict = ( array && array.count ) ? [array firstObject] : @{};
        //请求成功后，把返回接口放到数组里
        if(dict && dict.count) {[self.photosResults addObject:dict];}
        
        //上传成功一张后，index++
        _currentPhotoIndex += 1;
        
        //逐张图片执行递归上传
        [self uploadMultiplePhotos:self.photosPicked];
        
    } failed:^(HTTPRequestManager *manager, NSError *error) {
        //请求失败了重新上传，失败两次后则停止上传
        _failedCount += 1;
        [self uploadMultiplePhotos:self.photosPicked];
        NSLog(@"%@",error);
    }];
}

//上传失败，返回失败信息
- (void)uploadPhotosFailed {
    CDVPluginResult * pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:FAILED];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
}

//上传成功，返回成功后的参数
- (void)uploadPhotosSuccess {
    CDVPluginResult * pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:self.photosResults];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
}

#pragma mark - 单张上传
//从相册中读取1张照片
- (void)takePictureFromLibrary {
    //判断用户是否已经打开了相机使用权限
    BOOL camera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    if(!camera) {
        
        //请在设置中开启相机使用权限
        return;
    }
    
    UIImagePickerController *imgPicker = [UIImagePickerController new];
    imgPicker.delegate = self;
    imgPicker.allowsEditing = YES;
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self performSelector:@selector(kPresentViewController:) withObject:imgPicker afterDelay:0.25];
}

//照相获取
- (void)takePicture {
    //判断用户是否已经打开了相机使用权限
    BOOL camera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (!granted) {
            [CDVUtils alertTitle:@"提示" content:@"您的相机权限未打开\n请在“设置>隐私>相机”中开启" showVC:self.viewController handler1:^(UIAlertAction *action) {
//                    NSURL *url = [NSURL URLWithString:@"App-Prefs:root"];
//                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
//                        [[UIApplication sharedApplication] openURL:url];
//                    }
            }];
        }
    }];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
    }];
    if(!camera) {
        
        //请在设置中开启相机使用权限
        return;
    }
    
    UIImagePickerController * imgPicker = [UIImagePickerController new];
    imgPicker.delegate = self;
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self performSelector:@selector(kPresentViewController:) withObject:imgPicker afterDelay:0.3];
}

//跳转到对应界面
- (void)kPresentViewController:(UIViewController *)vc {
    //关闭container
    [self hideActionSheet];
    //跳转到相册或相机界面
    [self.viewController presentViewController:vc animated:YES completion:nil];
}

//处理上传服务器后旋转90度的问题
- (UIImage *)imageFixOrientationWithSourceImage:(UIImage *)sourceImage {
    if(sourceImage.imageOrientation != UIImageOrientationUp) {
        UIGraphicsBeginImageContextWithOptions(sourceImage.size, NO, sourceImage.scale);
        
        [sourceImage drawInRect:(CGRect){0,0,sourceImage.size}];
        
        UIImage * normalImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        sourceImage = normalImage;
    }
    return sourceImage;
}

//获取图片
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    //在这个方法里可以进行图片的修改、保存、或者视频保存
    //UIImagePickerControllerOriginalImage 原始图片
    //UIImagePickerControllerEditedImage 编辑后图片
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    //将拍照的照片存入本地相册
    if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishedSavingToAlbumWithError:contextInfo:), NULL);
    } else if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    
    //处理上传服务器后旋转90度的问题
    image = [self imageFixOrientationWithSourceImage:image];
    UIImage *newImage = [self imageByScalingAndCroppingForSize:CGSizeMake(image.size.width*0.1, image.size.height*0.1) withSourceImage:image];
    //将图片转换成base64字节流的方式传给javascript 压缩
    NSData * imageData = UIImageJPEGRepresentation(newImage, 0.3);
    
    //将base64的图片字符串回传给javascript
    NSString * encodedString = [imageData base64Encoding];
    
    NSString * echoUrl = [self.command argumentAtIndex:0];
    __block CDVPluginResult * pluginResult = nil;
    if(echoUrl != nil && [echoUrl length] > 0) {
        //开始处理上传
        //用时间戳生成图片名
        NSDate * dat = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval a = [dat timeIntervalSince1970] * 1000;
        NSString * phoneName = [NSString stringWithFormat:@"NEWUpload%.0f.JPG", a];
        NSArray * photos = [NSArray arrayWithObject:image];
        
        NSDictionary * dict = @{@"contentType":@"image/jpeg",
                                @"fileName":phoneName,
                                @"body": encodedString,
                                @"cutSize":@"300,300"};
        
        [[HTTPRequestManager shareInstance] uploadWithUrl:echoUrl params:dict photos:photos progress:^(NSProgress *progress){
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"0"];
            [pluginResult setKeepCallbackAsBool:YES];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
            
        } success:^(HTTPRequestManager *manager, id model) {
            
            NSArray * array = model;
            NSDictionary * dict = ( array && array.count ) ? [array firstObject] : @{};
            
            NSString * echoType = [self.command argumentAtIndex:1];
            if([echoType isEqualToString:@"single"]) {
                //如果是头像设置，则以字段方式放回
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
                [pluginResult setKeepCallbackAsBool:YES];
            } else if ([echoType isEqualToString:@"multiple"]) {
                //如果是意见反馈，则已数组方式返回
                NSArray * array = [NSArray arrayWithObject:dict];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:array];
                [pluginResult setKeepCallbackAsBool:YES];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:FAILED];
                [pluginResult setKeepCallbackAsBool:YES];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
            
        } failed:^(HTTPRequestManager *manager, NSError *error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:FAILED];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
            NSLog(@"%@",error);
        }];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:FAILED];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    }

    //dismiss
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishedSavingToAlbumWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if(error) {
        NSLog(@"保存失败");
    } else {
        NSLog(@"保存成功");
    }
}

#pragma mark - image edit
/**
  * 图片压缩到指定大小
  * @param targetSize 目标图片的大小
  * @param sourceImage 源图片
  * @return 目标图片
  */
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize withSourceImage:(UIImage *)sourceImage
{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (widthFactor > heightFactor)
        scaleFactor = widthFactor; // scale to fit height
        else
        scaleFactor = heightFactor; // scale to fit width
        scaledWidth= width * scaleFactor;
        scaledHeight = height * scaleFactor;
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            }
        else if (widthFactor < heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width= scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil)
    NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - lazy init
- (NSMutableArray *)data {
    if(!_data) {
        _data = [NSMutableArray array];
    }
    return _data;
}

- (NSMutableArray *)photosResults {
    if(!_photosResults) {
        _photosResults = [NSMutableArray array];
    }
    return _photosResults;
}

- (NSMutableArray *)photosPicked {
    if(!_photosPicked) {
        _photosPicked = [NSMutableArray array];
    }
    return _photosPicked;
}

#pragma mark - universal - links
- (void)getUniversalLinks:(CDVInvokedUrlCommand *)command {
    CDVPluginResult * pluginResult = nil;
    
    NSString * echo = [[AppDelegate shareDelegate] universal_links];
    if(echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:echo];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearUniversalLinks:(CDVInvokedUrlCommand *)command {
    CDVPluginResult * pluginResult = nil;
    
    NSString * echo = [[AppDelegate shareDelegate] universal_links];
    if(echo && [echo length]) {
        [[AppDelegate shareDelegate] setUniversal_links:@""];
    }
    
    if(echo == nil || ![echo length]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"清除Universal Links成功"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"清除Universal Links失败"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
