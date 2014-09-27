//
//  LoadProperties+Extras.m
//  SLE
//
//  Created by Cameron McCord on 8/19/14.
//  Copyright (c) 2014 Missionary Training Center. All rights reserved.
//

#import "LoadProperties+Extras.h"
#import "VPDaoV1.h"

@implementation LoadProperties (Extras)

+(void)setUploadingToNotUploadedForContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"LoadProperties" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"loadStatus == %@", LoadStatusUploading]];
	NSError *error = nil;
	NSArray *loadProperties = [context executeFetchRequest:fetchRequest error:&error];
	
	for (LoadProperties *lp in loadProperties) {
//		lp.loadStatus;
//		DLog(@"lp: %@", lp);
		lp.loadStatus = LoadStatusNotUploaded;
	}
	[CoreDataTemplates saveContext:context sender:self];
}

+(void)setDownloadingToNotDownloadedForContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"LoadProperties" inManagedObjectContext:context];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"loadStatus == %@", LoadStatusDownloading]];
	NSError *error = nil;
	NSArray *loadProperties = [context executeFetchRequest:fetchRequest error:&error];
	
	for (LoadProperties *lp in loadProperties) {
		lp.loadStatus = LoadStatusNotDownloaded;
	}
	[CoreDataTemplates saveContext:context sender:self];
}

@end
