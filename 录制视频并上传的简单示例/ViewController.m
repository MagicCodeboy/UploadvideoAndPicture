//
//  ViewController.m
//  录制视频并上传的简单示例
//
//  Created by lalala on 2017/5/31.
//  Copyright © 2017年 lsh. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "AFNetworking.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong) UIImagePickerController * imagePicker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //监测相关的权限 一般在使用相机和相册是都要在plist文件中添加相应的授权的字段↓
    //http://upload-images.jianshu.io/upload_images/2517029-367f526b5b6362d5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"支持相机");
    }
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        NSLog(@"支持图库");
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        NSLog(@"支持相片库");
    }
    self.imagePicker = [[UIImagePickerController alloc]init];
    
}
- (IBAction)clickImagePicker:(id)sender {
     [self createImagePickerWithBool:YES];
}
- (IBAction)clickSelectVideo:(id)sender {
     [self createImagePickerWithBool:NO];
}


-(void)createImagePickerWithBool:(BOOL)typeIsCamera{
    if (typeIsCamera) {
        //调用系统摄像 摄像头模式
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;//设置imagePicker的来源 这里设置为摄像头
        
        self.imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];//抽象的媒体格式（声音和视频）
        
        self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeLow;
        
        self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
        
        self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;//设置摄像头模式（拍照，录制视频）
        
        self.imagePicker.videoMaximumDuration = 30.0f;//这个参数设置允许录制的最大时长
        
        self.imagePicker.allowsEditing = YES;//允许编辑
        
        
    } else {
        //相册选择模式
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//设置imagePicker的来源 这里设置为摄像头
        
        self.imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];//抽象的媒体格式（声音和视频）
        
        self.imagePicker.allowsEditing = NO;//允许编辑
        
    }
    self.imagePicker.delegate = self;
    
    [self presentViewController:self.imagePicker animated:YES  completion:nil];
}
#pragma mark --获取视频信息的方法--
//此方法可以获取文件的大小，返回的是单位是KB。
-(CGFloat)getFileSize:(NSString *)path{
    NSLog(@"文件的路径%@",path);
    NSFileManager * fileManager = [NSFileManager defaultManager];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary * fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize]longLongValue];
        filesize = 1.0 * size/1024;
    } else {
        NSLog(@"找不到这个文件");
    }
    return filesize;
}
//这个方法获取的是视频文件的时长
-(CGFloat)getVideoLength:(NSURL *)url{
    AVAsset * avUrl = [AVAsset assetWithURL:url];
    CMTime time = [avUrl duration];
    int second = ceil(time.value/time.timescale);
    return second;
}

#pragma mark  --UIImagePickerControllerDelegate--Method
/*
 - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo NS_DEPRECATED_IOS(2_0, 3_0);
 - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info;
 - (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
 */
//选择图片完成 已经废弃的方法
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo {
//
//}
//选择文件完成时调用 选取的信息都在info中 info是一个字典  在这个方法中要把视频进行压缩 并显示大小和时长
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSURL * sourceUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    NSLog(@"%@",[NSString stringWithFormat:@"%f s",[self getVideoLength:sourceUrl]]);
    NSLog(@"%@",[NSString stringWithFormat:@"%.2f kb",[self getFileSize:[sourceUrl path]]]);
    NSURL * newVideoUrl; //一般.mp4
    NSDateFormatter * formater = [[NSDateFormatter alloc]init];//用时间给文件全名 以免重复 在测试的时候判断文件是否存在 若存在，则删除 重新生成文件即可
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    newVideoUrl  = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/output-%@.mp4",[formater stringFromDate:[NSDate date]]]];//这个是保存在app自己的沙盒路径里，后面可以选择是否在上传后删除掉。我建议删除掉，免得占空间
    //保存视频到相册（异步的线程）
    NSString * urlStr = [sourceUrl path];
    if (!urlStr) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlStr)) {
                UISaveVideoAtPathToSavedPhotosAlbum(urlStr, self, @selector(video:didFinishSavingWithError:contentInfo:), nil);
            }
        });
    }
    //压缩视频
    [self convertVideoQuailtyWithInputURL:sourceUrl outputURL:newVideoUrl completeHandler:nil];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}
//保存视频到相册
-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contentInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存视频过程中发生错误，错误的信息是:%@",error.localizedDescription);
    } else {
        NSLog(@"视频保存成功");
    }
}
- (void) convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                               outputURL:(NSURL*)outputURL
                         completeHandler:(void (^)(AVAssetExportSession*))handler
{
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    //  NSLog(resultPath);
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (exportSession.status) {
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"AVAssetExportSessionStatusCancelled");
                 break;
             case AVAssetExportSessionStatusUnknown:
                 NSLog(@"AVAssetExportSessionStatusUnknown");
                 break;
             case AVAssetExportSessionStatusWaiting:
                 NSLog(@"AVAssetExportSessionStatusWaiting");
                 break;
             case AVAssetExportSessionStatusExporting:
                 NSLog(@"AVAssetExportSessionStatusExporting");
                 break;
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"AVAssetExportSessionStatusCompleted");
                 NSLog(@"%@",[NSString stringWithFormat:@"%f s", [self getVideoLength:outputURL]]);
                 NSLog(@"%@", [NSString stringWithFormat:@"%.2f kb", [self getFileSize:[outputURL path]]]);
                 //UISaveVideoAtPathToSavedPhotosAlbum([outputURL path], self, nil, NULL);//这个是保存到手机相册
                 //这里弹出一个提示框，也可以直接上传视频
                 [self alertUploadVideo:outputURL];
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"AVAssetExportSessionStatusFailed");
                 break;
         }
         
     }];
    
}

-(void)alertUploadVideo:(NSURL*)URL{
    CGFloat size = [self getFileSize:[URL path]];
    NSString *message;
    NSString *sizeString;
    CGFloat sizemb= size/1024;
    if(size<=1024){
        sizeString = [NSString stringWithFormat:@"%.2fKB",size];
    }else{
        sizeString = [NSString stringWithFormat:@"%.2fMB",sizemb];
    }
    if(sizemb<=100){
        //上传的操作
        [self uploadVideo:URL];
//        [self uploadVideo:@"http://www.baidu.com/" parameters:nil fileData:nil name:@"file" fileName:[URL path] mimeType:@"video/quicktime" progress:^(NSProgress * progress) {
//             NSLog(@"%lf",1.0 * progress.completedUnitCount/progress.totalUnitCount);
//        } success:^(NSURLSessionDataTask * task, id responseObject) {
//            
//        } failure:^(NSURLSessionDataTask * task, NSError * error) {
//            
//        }];
    }
//    else {
//        message = [NSString stringWithFormat:@"视频%@，大于50MB会有点慢，确定上传吗？", sizeString];
//        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
//                                                                                  message: message
//                                                                           preferredStyle:UIAlertControllerStyleAlert];
//        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshwebpages" object:nil userInfo:nil];
//            [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//取消之后就删除，以免占用手机硬盘空间（沙盒）
//        }]];
//        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
////            [self uploadVideo:URL];
//        }]];
//        [self presentViewController:alertController animated:YES completion:nil];
//        
     else  {
        message = [NSString stringWithFormat:@"视频%@，超过100MB，不能上传，抱歉。", sizeString];
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil
                                                                                  message: message
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshwebpages" object:nil userInfo:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[URL path] error:nil];//取消之后就删除，以免占用手机硬盘空间
            
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
}
//上传视频的方法
-(void)uploadVideo:(NSString *)url parameters:(NSDictionary *)parameters fileData:(NSData*)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType progress:(void (^)(NSProgress* ))progress success:(void (^)(NSURLSessionDataTask* , id))success failure:(void (^)(NSURLSessionDataTask* , NSError* ))failure {
    //1.获取单利的网络管理对象
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    //2.选择返回值类型
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //设置相应数据支持的类型
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/css",@"text/plain", @"application/javascript",@"application/json", @"application/x-www-form-urlencoded", nil]];
    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //通过工程中的文件进行上传
//        [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
        //通过URL来获取路径 进入沙盒或者系统相册等进行上传
        [formData appendPartWithFileURL:[NSURL URLWithString:url] name:name fileName:fileName mimeType:mimeType error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //打印上传进度
        NSLog(@"%lf",1.0 * uploadProgress.completedUnitCount/uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"请求成功%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败：%@",error);
    }];
}
//获取视频的第一帧截图, 返回UIImage
//需要导入AVFoundation.h
- (UIImage*) getVideoPreViewImageWithPath:(NSURL *)videoPath
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoPath options:nil];
    AVAssetImageGenerator *gen     = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time   = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error  = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img   = [[UIImage alloc] initWithCGImage:image];
    return img;
}

//点击取消按钮
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}




#pragma mark 其他的视频上传的方法 ONE
//上传图片和视频
- (void)uploadImageAndMovieBaseModel:(NSString *)path {
    //获取文件的后缀名
    NSString *extension = [path componentsSeparatedByString:@"."].lastObject;
    //设置mimeType
    NSString *mimeType;
    //    if ([model.type isEqualToString:@"image"]) {
    //        mimeType = [NSString stringWithFormat:@"image/%@", extension];
    //    } else {
    mimeType = [NSString stringWithFormat:@"video/%@", extension];
    //    }
    //创建AFHTTPSessionManager
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置响应文件类型为JSON类型
    manager.responseSerializer  = [AFJSONResponseSerializer serializer];
    //初始化requestSerializer
    manager.requestSerializer   = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = nil;
    //设置timeout
    [manager.requestSerializer setTimeoutInterval:20.0];
    //设置请求头类型
    [manager.requestSerializer setValue:@"form/data" forHTTPHeaderField:@"Content-Type"];
    //设置请求头, 授权码
    [manager.requestSerializer setValue:@"YgAhCMxEehT4N/DmhKkA/M0npN3KO0X8PMrNl17+hogw944GDGpzvypteMemdWb9nlzz7mk1jBa/0fpOtxeZUA==" forHTTPHeaderField:@"Authentication"];
    //上传服务器接口
    NSString *url = [NSString stringWithFormat:@"http://xxxxx.xxxx.xxx.xx.x"];
    //开始上传
    [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData) {
        NSError *error;
        BOOL success = [formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:path fileName:path mimeType:mimeType error:&error];
        if (!success) {
            NSLog(@"appendPartWithFileURL error: %@", error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传进度: %f", uploadProgress.fractionCompleted);
    } success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        NSLog(@"成功返回: %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传失败: %@", error);
    }];
}

#pragma mark 其他的视频上传的方法 TWO
-(void)uploadVideo:(NSURL *)url{
    NSData * data = [NSData dataWithContentsOfURL:url];
    //1.获取单利的网络管理对象
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    //2.选择返回值类型
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //设置相应数据支持的类型
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/css",@"text/plain", @"application/javascript",@"application/json", @"application/x-www-form-urlencoded", nil]];
    [manager POST:@"http://www.baidu.com/"  parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //通过工程中的文件进行上传
            [formData appendPartWithFileData:data name:@"name" fileName:@"name.videp" mimeType:@"video/quicktime"];
        //通过URL来获取路径 进入沙盒或者系统相册等进行上传
//        [formData appendPartWithFileURL:[NSURL URLWithString:url] name:name fileName:fileName mimeType:mimeType error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //打印上传进度
        NSLog(@"进度%lf",1.0 * uploadProgress.completedUnitCount/uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"请求成功%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败：%@",error);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
