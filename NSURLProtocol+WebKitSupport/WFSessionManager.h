//
//  WFSessionManager.h
//  WenFang
//
//  Created by sam.hu on 2017/6/6.
//  Copyright © 2017年 maili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WFSessionManager : NSObject


+(instancetype)instanceManager;


-(NSString *)readCurrentCookie;

-(void)saveSession:(NSURL *)url;

-(void)reset;

@end
