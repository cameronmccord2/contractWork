//
//  Captions+Extras.m
//  VideoViewer
//
//  Created by Cameron McCord on 9/27/14.
//  Copyright (c) 2014 Cameron McCord. All rights reserved.
//

#import "Captions+Extras.h"
#import "Medias+Extras.h"

@implementation Captions (Extras)

+(Captions *)parseCaptionFromDictionary:(NSDictionary *)dictionary forMedia:(Medias *)media intoContext:(NSManagedObjectContext *)context {
    
    NSNumber *captionId = dictionary[@"id"];
    NSError *error = nil;
    Captions *caption = [[CoreDataTemplates getListForEntity:@"Captions" withPredicate:[NSPredicate predicateWithFormat:@"captionId == %@", captionId] forContext:context error:&error] firstObject];
    if (error) {
        DLog(@"error getting the caption for parsing");
        
    }else if (caption == nil){

        Captions *caption = [NSEntityDescription insertNewObjectForEntityForName:@"Captions" inManagedObjectContext:context];
        [caption setCaptionId:captionId];
        [CoreDataTemplates mapKeys:[NSSet setWithArray:@[@"caption", @"mediaId", @"startTime", @"endTime", @"languageId", @"type"]]
                    fromDictionary:dictionary
                   toManagedObject:caption];
        [caption setLanguage:media.language];
        [caption setMedia:media];
    }
    return caption;
}

@end
