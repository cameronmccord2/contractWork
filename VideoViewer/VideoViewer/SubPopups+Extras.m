//
//  SubPopups+Extras.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "SubPopups+Extras.h"
#import "Files+Extras.h"
#import "Popups+Extras.h"

@implementation SubPopups (Extras)

+(SubPopups *)parseSubPopupFromDictionary:(NSDictionary *)dictionary forPopup:(Popups *)popup intoContext:(NSManagedObjectContext *)context {
    
    NSNumber *subPopupId = dictionary[@"id"];
    NSError *error = nil;
    SubPopups *subPopup = [[CoreDataTemplates getListForEntity:@"SubPopups" withPredicate:[NSPredicate predicateWithFormat:@"subPopupId == %@", subPopupId] forContext:context error:&error] firstObject];
    if (error) {
        DLog(@"error getting the media for parsing");
        
    }else if (subPopup == nil){
        
        subPopup = [NSEntityDescription insertNewObjectForEntityForName:@"SubPopups" inManagedObjectContext:context];
        [CoreDataTemplates mapKeys:[NSSet setWithArray:@[@"bucketId", @"bucketName", @"popupText", @"endTime", @"startTime", @"extension", @"filename", @"filenameInBucket", @"popupId"]]
                    fromDictionary:dictionary
                   toManagedObject:subPopup];
        [subPopup setBucketName:popup.bucketName];
        [subPopup setSubPopupId:subPopupId];
        [subPopup setPopup:popup];
        
        Files *file = [Files newFileForFilename:subPopup.filenameInBucket extension:subPopup.extension intoContext:context];
        [subPopup setFile:file];
    }
    return subPopup;
}

@end
