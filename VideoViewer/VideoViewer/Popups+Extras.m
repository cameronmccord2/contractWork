//
//  Popups+Extras.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Popups+Extras.h"
#import "Medias.h"
#import "SubPopups+Extras.h"
#import "Files+Extras.h"
#import "NSDictionary+SafeJson.h"

@implementation Popups (Extras)

+(Popups *)parsePopupFromDictionary:(NSDictionary *)dictionary forMedia:(Medias *)media intoContext:(NSManagedObjectContext *)context {
    
    NSNumber *popupId = dictionary[@"id"];
    NSError *error = nil;
    Popups *popup = [[CoreDataTemplates getListForEntity:@"Popups" withPredicate:[NSPredicate predicateWithFormat:@"popupId == %@", popupId] forContext:context error:&error] firstObject];
    if (error) {
        DLog(@"error getting the popup for parsing");
        
    }else if (popup == nil){
    
        popup = [NSEntityDescription insertNewObjectForEntityForName:@"Popups" inManagedObjectContext:context];
        [CoreDataTemplates mapKeys:[NSSet setWithArray:@[@"displayName", @"popupText", @"mediaId", @"languageId", @"startTime", @"endTime", @"filename", @"bucketId", @"filenameInBucket", @"extension", @"bucketName"]]
                    fromDictionary:dictionary
                   toManagedObject:popup];
        [popup setPopupId:popupId];
        [popup setLanguage:media.language];
        [popup setMedia:media];
        
        Files *file = [Files newFileForFilename:popup.filenameInBucket extension:popup.extension intoContext:context];
        [popup setFile:file];
        
        for (NSDictionary *d in dictionary[@"subPopups"]) {
            SubPopups *subPopup = [SubPopups parseSubPopupFromDictionary:[d removeNullValues] forPopup:popup intoContext:context];
            if (subPopup)
                [popup addSubPopupsObject:subPopup];
        }
    }
    return popup;
}

@end
