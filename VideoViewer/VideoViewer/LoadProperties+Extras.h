//
//  LoadProperties+Extras.h
//  SLE
//
//  Created by Cameron McCord on 8/19/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "LoadProperties.h"

@interface LoadProperties (Extras)

+(void)setUploadingToNotUploadedForContext:(NSManagedObjectContext *)context;
+(void)setDownloadingToNotDownloadedForContext:(NSManagedObjectContext *)context;

@end
