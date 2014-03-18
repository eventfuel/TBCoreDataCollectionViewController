//
//  TBCoreDataCollectionViewController.m
//  eventfuel-admin
//
//  Created by Vasco d'Orey on 21/02/14.
//  Copyright (c) 2014 Tasboa. All rights reserved.
//

#import "TBCoreDataCollectionViewController.h"

@interface TBCoreDataCollectionViewController ()

@property (nonatomic) BOOL beganUpdates;

@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *objectChanges;

@end

@implementation TBCoreDataCollectionViewController

#pragma mark - Properties

- (NSMutableArray *)sectionChanges
{
  if(!_sectionChanges) _sectionChanges = [NSMutableArray array];
  return _sectionChanges;
}

- (NSMutableArray *)objectChanges
{
  if(!_objectChanges) _objectChanges = [NSMutableArray array];
  return _objectChanges;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
}

#pragma mark - UICollectionVIew

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  
  id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
  return [sectionInfo numberOfObjects];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return nil;
}

#pragma mark - Fetched Results Controller

- (void)performFetch {
	if (self.fetchedResultsController) {
		if (self.fetchedResultsController.fetchRequest.predicate) {
			NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName, self.fetchedResultsController.fetchRequest.predicate);
		} else {
			NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName);
		}
		NSError *error;
		[self.fetchedResultsController performFetch:&error];
		NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
	} else {
		NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
	[self.collectionView reloadData];
	[self.collectionView layoutIfNeeded];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
	NSFetchedResultsController *oldfrc = _fetchedResultsController;
	if (newfrc != oldfrc) {
    oldfrc.delegate = nil;
		_fetchedResultsController = newfrc;
		newfrc.delegate = self;
		
		if (newfrc) {
			NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
			[self performFetch];
		} else {
			NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[self.collectionView reloadData];
		}
	}
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
  
  NSMutableDictionary *change = [NSMutableDictionary new];
  
  switch(type) {
    case NSFetchedResultsChangeInsert:
      change[@(type)] = @(sectionIndex);
      break;
    case NSFetchedResultsChangeDelete:
      change[@(type)] = @(sectionIndex);
      break;
  }
  
  [self.sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
  
  NSMutableDictionary *change = [NSMutableDictionary new];
  switch(type)
  {
    case NSFetchedResultsChangeInsert:
      change[@(type)] = newIndexPath;
      break;
    case NSFetchedResultsChangeDelete:
      change[@(type)] = indexPath;
      break;
    case NSFetchedResultsChangeUpdate:
      change[@(type)] = indexPath;
      break;
    case NSFetchedResultsChangeMove:
      change[@(type)] = @[indexPath, newIndexPath];
      break;
  }
  [self.objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  if ([self.sectionChanges count] > 0)
  {
    [self.collectionView performBatchUpdates:^{
      
      for (NSDictionary *change in self.sectionChanges)
      {
        [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
          
          NSFetchedResultsChangeType type = [key unsignedIntegerValue];
          switch (type)
          {
            case NSFetchedResultsChangeInsert:
              [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
              break;
            case NSFetchedResultsChangeDelete:
              [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
              break;
            case NSFetchedResultsChangeUpdate:
              [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
              break;
          }
        }];
      }
    } completion:nil];
  }
  
  if ([self.objectChanges count] > 0 && [self.sectionChanges count] == 0)
  {
    
    if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
      // This is to prevent a bug in UICollectionView from occurring.
      // The bug presents itself when inserting the first object or deleting the last object in a collection view.
      // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
      // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
      // http://openradar.appspot.com/12954582
      [self.collectionView reloadData];
      
    } else {
      
      [self.collectionView performBatchUpdates:^{
        
        for (NSDictionary *change in self.objectChanges)
        {
          [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
            
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            switch (type)
            {
              case NSFetchedResultsChangeInsert:
                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                break;
              case NSFetchedResultsChangeDelete:
                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                break;
              case NSFetchedResultsChangeUpdate:
                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                break;
              case NSFetchedResultsChangeMove:
                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                break;
            }
          }];
        }
      } completion:nil];
    }
  }
  
  [self.sectionChanges removeAllObjects];
  [self.objectChanges removeAllObjects];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
  __block BOOL shouldReload = NO;
  for (NSDictionary *change in self.objectChanges) {
    [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      NSFetchedResultsChangeType type = [key unsignedIntegerValue];
      NSIndexPath *indexPath = obj;
      switch (type) {
        case NSFetchedResultsChangeInsert:
          if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
            shouldReload = YES;
          } else {
            shouldReload = NO;
          }
          break;
        case NSFetchedResultsChangeDelete:
          if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
            shouldReload = YES;
          } else {
            shouldReload = NO;
          }
          break;
        case NSFetchedResultsChangeUpdate:
          shouldReload = NO;
          break;
        case NSFetchedResultsChangeMove:
          shouldReload = NO;
          break;
      }
    }];
  }
  
  return shouldReload;
}

@end
