//
//  TBCoreDataCollectionViewController.h
//  eventfuel-admin
//
//  Created by Vasco d'Orey on 21/02/14.
//  Copyright (c) 2014 Tasboa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TBCoreDataCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

- (void)performFetch;

@end
