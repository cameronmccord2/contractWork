//
//  NSDictionary+SafeJson.h
//  SLE
//
//  Created by Cameron McCord on 6/19/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SafeJson)

-(NSDictionary *)removeNullValues;

@end
