//
//  Medias+Extras.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Medias+Extras.h"
#import "Captions+Extras.h"
#import "Popups+Extras.h"
#import "Files+Extras.h"
#import "VPDaoV1.h"
#import "NSDictionary+SafeJson.h"

@implementation Medias (Extras)

+(Medias *)parseMediaFromDictionary:(NSDictionary *)dictionary forLanguage:(Languages *)language intoContext:(NSManagedObjectContext *)context {
    
    NSNumber *mediaId = dictionary[@"id"];
    NSError *error = nil;
    Medias *media = [[CoreDataTemplates getListForEntity:@"Medias" withPredicate:[NSPredicate predicateWithFormat:@"mediaId == %@", mediaId] forContext:context error:&error] firstObject];
    if (error) {
        DLog(@"error getting the media for parsing");
        
    }else if (media == nil){
        
        media = [NSEntityDescription insertNewObjectForEntityForName:@"Medias" inManagedObjectContext:context];
        [CoreDataTemplates mapKeys:[NSSet setWithArray:@[@"name", @"filename", @"filenameInBucket", @"audioLanguageId", @"bucketId", @"type", @"extension", @"bucketName"]]
                    fromDictionary:dictionary
                   toManagedObject:media];
        media.mediaId = mediaId;
        media.language = language;
        
        Files *file = [Files newFileForFilename:media.filenameInBucket extension:media.extension intoContext:context];
        [media setFile:file];
    }
    
    // Captions parse
    for (NSDictionary *d in dictionary[@"captions"]) {
        
        Captions *caption = [Captions parseCaptionFromDictionary:[d removeNullValues] forMedia:media intoContext:context];
        if (caption)
            [media addCaptionsObject:caption];
    }
    
    // Popups parse
    for (NSDictionary *d in dictionary[@"popups"]) {

        Popups *popup = [Popups parsePopupFromDictionary:[d removeNullValues] forMedia:media intoContext:context];
        if (popup)
            [media addPopupsObject:popup];
    }
    return media;
}

@end
