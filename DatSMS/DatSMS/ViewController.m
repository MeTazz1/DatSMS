//
//  ViewController.m
//  DatSMS
//
//  Created by Christophe Dellac on 10/7/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import "ViewController.h"
#import "Dat.h"
#import "Recipient.h"
#import <AddressBook/AddressBook.h>
#import "MMProgressHUD.h"
#import "MMProgressHUDOverlayView.h"
#import "MMRadialProgressView.h"
#import "PickContactController.h"

#define ARC4RANDOM_MAX	0x100000000

#define INSIDE_CELL_SIZE_W 90
#define INSIDE_CELL_SIZE_H 90
#define SPACE_BETWEEN_CELL 20
#define INSIDE_SCROLL_TAG 100

@interface ViewController () <UIScrollViewAccessibilityDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;

@end

@implementation ViewController

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mainDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = [mainDelegate managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *datEntity = [NSEntityDescription
                                      entityForName:@"Dat" inManagedObjectContext:context];
    [fetchRequest setEntity:datEntity];
    NSArray *datsObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSEntityDescription *recipientEntity = [NSEntityDescription
                                            entityForName:@"Recipient" inManagedObjectContext:context];
    [fetchRequest setEntity:recipientEntity];
    
    _dats = [NSMutableArray new];
    for (Dat *dat in datsObjects) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datId = %@", dat.datId];
        [fetchRequest setPredicate:predicate];
        
        NSArray *recipientsObjects = [context executeFetchRequest:fetchRequest error:&error];
        
        dat.recipients = [NSMutableArray new];
        
        for (Recipient *recipient in recipientsObjects) {
            NSLog(@"Name: %@", recipient.fullname);
            NSLog(@"Message: %@", recipient.phoneNumber);
            [dat.recipients addObject:recipient];
        }
        [_dats insertObject:dat atIndex:0];
    }
    
    [self updateScrollView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    if ([[[UIApplication sharedApplication] keyWindow] viewWithTag:40] != nil)
    {
        [UIView animateWithDuration:0.35f animations:^{
            [[[UIApplication sharedApplication] keyWindow] viewWithTag:40].alpha = 1.0f;
        }];
    }
    else
    {
        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        addBtn.frame = CGRectMake(0, 0, 42, 42);
        addBtn.center = CGPointMake(40, 60);
        addBtn.tag = 40;
        [addBtn setBackgroundImage:[UIImage imageNamed:@"menuAdd.png"] forState:UIControlStateNormal];
        [addBtn addTarget:self action:@selector(addClicked) forControlEvents:UIControlEventTouchUpInside];
        
        [[[UIApplication sharedApplication] keyWindow] addSubview:addBtn];
    }
    [self updateScrollView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateInsideScrollView
{
    UIScrollView *insideScrollView = (UIScrollView*)[_scrollView viewWithTag:INSIDE_SCROLL_TAG + currentPage];
    [[insideScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self createInsideScrollViewAtIndex:currentPage];
}

- (void)updateScrollView
{
    nbPages = (int)_dats.count;
    [[_scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_scrollView setContentSize: CGSizeMake(_scrollView.bounds.size.width * nbPages, _scrollView.bounds.size.height)];
    
    int i = 0;
    for (Dat *dat in _dats)
    {
        [self create:dat forIndex:i];
        ++i;
    }
    currentPage = 0;
    [[[UIApplication sharedApplication] keyWindow] viewWithTag:40].alpha = 1.0f;
}

- (void)createInsideScrollViewAtIndex:(int)i
{
    UIScrollView *insideScrollView;
    if ([_scrollView viewWithTag:INSIDE_SCROLL_TAG + i] == nil)
        insideScrollView = [[UIScrollView alloc] init];
    else
        insideScrollView = (UIScrollView*)[_scrollView viewWithTag:INSIDE_SCROLL_TAG + i];
    
    [insideScrollView setFrame:CGRectMake(i * _scrollView.bounds.size.width, _scrollView.bounds.size.height - INSIDE_CELL_SIZE_H * 1.3, _scrollView.frame.size.width, INSIDE_CELL_SIZE_H * 1.3)];
    insideScrollView.backgroundColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.4f];
    [insideScrollView setContentSize:CGSizeMake(((INSIDE_CELL_SIZE_W + SPACE_BETWEEN_CELL) * (((Dat*)_dats[i]).recipients.count + 1)) + SPACE_BETWEEN_CELL, INSIDE_CELL_SIZE_H)];
    insideScrollView.showsHorizontalScrollIndicator = YES;
    insideScrollView.tintColor = [UIColor greenColor];
    insideScrollView.showsVerticalScrollIndicator = NO;
    insideScrollView.delegate = self;
    insideScrollView.tag = INSIDE_SCROLL_TAG + i;
    [_scrollView addSubview:insideScrollView];
    int index = 1;
    [self create:nil forIndex:0 inScrollView:insideScrollView];
    for (Recipient *recipient in ((Dat*)_dats[i]).recipients)
    {
        [self create:recipient forIndex:index++ inScrollView:insideScrollView];
    }
    
    if ([_scrollView viewWithTag:200 + i] == nil)
    {
        UILabel *contactedPeople = [[UILabel alloc] initWithFrame:CGRectMake(insideScrollView.frame.origin.x, insideScrollView.frame.origin.y - 20, insideScrollView.frame.size.width, 20)];
        contactedPeople.text = [NSString stringWithFormat:@"%lu people on this Dat", (unsigned long)((Dat*)_dats[i]).recipients.count];
        contactedPeople.backgroundColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.4f];
        contactedPeople.font = [UIFont fontWithName:@"Heiti SC" size:16];
        contactedPeople.textColor = [UIColor whiteColor];
        contactedPeople.tag = 200 + i;
        contactedPeople.textAlignment = NSTextAlignmentCenter;
        [_scrollView addSubview:contactedPeople];
    }
    else
        ((UILabel*)[_scrollView viewWithTag:200 + i]).text = [NSString stringWithFormat:@"%lu people on this Dat", (unsigned long)((Dat*)_dats[i]).recipients.count];

}

- (void)create:(Recipient*)recipient forIndex:(int)index inScrollView:(UIScrollView*)inScrollView
{
    if (index == 0)
    {
        UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addRecipientTapped:)];
        UIImageView *newLabel = [[UIImageView alloc] initWithFrame:CGRectMake(SPACE_BETWEEN_CELL + (index * (INSIDE_CELL_SIZE_W + SPACE_BETWEEN_CELL)), 15.0f, INSIDE_CELL_SIZE_W, INSIDE_CELL_SIZE_H)];
        newLabel.tag = 50 + index;
        newLabel.userInteractionEnabled = YES;
        newLabel.image = [UIImage imageNamed:@"menuAdd_small.png"];
        newLabel.layer.shadowOffset = CGSizeMake(0, 5);
        newLabel.contentMode = UIViewContentModeCenter;
        newLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
        newLabel.layer.shadowRadius = 10;
        newLabel.layer.masksToBounds = NO;
        newLabel.layer.shadowOpacity = 0.8;
        newLabel.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:0.8f];
        [newLabel addGestureRecognizer:handleTap];
        [inScrollView addSubview:newLabel];
    }
    else
    {
        UITapGestureRecognizer *handleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageContactTapped:)];
        UIImageView *newLabel = [[UIImageView alloc] initWithFrame:CGRectMake(SPACE_BETWEEN_CELL + (index * (INSIDE_CELL_SIZE_W + SPACE_BETWEEN_CELL)), 15.0f, INSIDE_CELL_SIZE_W, INSIDE_CELL_SIZE_H)];
        newLabel.tag = 50 + index;
        newLabel.image = recipient.picture;
        newLabel.userInteractionEnabled = YES;
        newLabel.contentMode = UIViewContentModeScaleToFill;
        newLabel.layer.shadowOffset = CGSizeMake(0, 5);
        newLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
        newLabel.layer.shadowRadius = 10;
        newLabel.layer.masksToBounds = NO;
        newLabel.layer.shadowOpacity = 0.8;
        [newLabel addGestureRecognizer:handleTap];
        
        UILabel *contactName = [[UILabel alloc] initWithFrame:CGRectMake(newLabel.frame.origin.x, newLabel.frame.size.height - 15, newLabel.frame.size.width, 30)];
        contactName.backgroundColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.4f];
        contactName.text = recipient.fullname;
        contactName.font = [UIFont fontWithName:@"Heiti SC" size:15];
        contactName.textColor = [UIColor whiteColor];
        contactName.textAlignment = NSTextAlignmentCenter;
        
        [inScrollView addSubview:newLabel];
        [inScrollView addSubview:contactName];
    }
}

- (void)create:(Dat*)dat forIndex:(int)i
{
    CGRect pageFrame;
    pageFrame = CGRectMake(i * _scrollView.bounds.size.width, 0.0f, _scrollView.bounds.size.width, _scrollView.bounds.size.height) ;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(pageFrame.origin.x + (pageFrame.size.width / 4), 20, pageFrame.size.width / 2, 90)];
    title.text = dat.title;
    title.numberOfLines = 3;
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont fontWithName:@"Heiti SC" size:17];
    title.textColor = [UIColor whiteColor];
    [_scrollView addSubview:title];
    
    UITextView *message = [[UITextView alloc] initWithFrame:CGRectMake(pageFrame.origin.x + 10, 130, pageFrame.size.width - 20, 110)];
    message.text = dat.message;
    message.textAlignment = NSTextAlignmentCenter;
    message.font = [UIFont fontWithName:@"Heiti SC" size:17];
    message.textColor = [UIColor whiteColor];
    message.backgroundColor = [UIColor clearColor];
    message.returnKeyType = UIReturnKeyDone;
    message.delegate = self;
    [_scrollView addSubview:message];
    
    [self createInsideScrollViewAtIndex:i];
    
    UIButton *sendMsgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendMsgBtn.frame = CGRectMake(0, 0, 50, 50);
    sendMsgBtn.center = CGPointMake(pageFrame.origin.x + (pageFrame.size.width / 4), [_scrollView viewWithTag:INSIDE_SCROLL_TAG + i].frame.origin.y - 70);
    [sendMsgBtn setBackgroundImage:[UIImage imageNamed:@"menuChat.png"] forState:UIControlStateNormal];
    [sendMsgBtn addTarget:self action:@selector(sendMsgClicked) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *clockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clockBtn.frame = CGRectMake(0, 0, 50, 50);
    clockBtn.center = CGPointMake(pageFrame.origin.x + (pageFrame.size.width - (pageFrame.size.width / 4)), [_scrollView viewWithTag:INSIDE_SCROLL_TAG + i].frame.origin.y - 70);
    [clockBtn setBackgroundImage:[UIImage imageNamed:@"menuClock.png"] forState:UIControlStateNormal];
    [clockBtn addTarget:self action:@selector(clockClicked) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteBtn.frame = CGRectMake(0, 0, 42, 42);
    deleteBtn.center = CGPointMake(pageFrame.origin.x + (pageFrame.size.width - 40), 60);
    [deleteBtn setBackgroundImage:[UIImage imageNamed:@"menuClose.png"] forState:UIControlStateNormal];
    [deleteBtn addTarget:self action:@selector(deleteClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [_scrollView addSubview:sendMsgBtn];
    [_scrollView addSubview:clockBtn];
    [_scrollView addSubview:deleteBtn];
}

#pragma mark -
#pragma mark UIScrollView delegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.35f animations:^{
        [[[UIApplication sharedApplication] keyWindow] viewWithTag:40].alpha = 1.0f;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    if (aScrollView.tag >= INSIDE_SCROLL_TAG)
    {
        
    }
    else
    {
        [UIView animateWithDuration:0.15f animations:^{
            [[[UIApplication sharedApplication] keyWindow] viewWithTag:40].alpha = .0f;
        }];
        CGFloat pageWidth = _scrollView.bounds.size.width;
        float fractionalPage = _scrollView.contentOffset.x / pageWidth;
        currentPage = (int)lround(fractionalPage);
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)aScrollView
{
    // if we are animating (triggered by clicking on the page control), we update the page control
}

#pragma mark -
#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.length == 0 && [text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        ((Dat*)_dats[currentPage]).message = textView.text;
        [mainDelegate saveContext];
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark - Actions

- (void)imageContactTapped:(UIGestureRecognizer*)gesture
{
    UIImageView *tapped = (UIImageView*)gesture.view;
    if (tapped.layer.borderColor == [[UIColor redColor] CGColor])
    {
        [mainDelegate.managedObjectContext deleteObject:[((Dat*)_dats[currentPage]).recipients objectAtIndex:tapped.tag - 51]];
        [mainDelegate saveContext];
        
        [((Dat*)_dats[currentPage]).recipients removeObjectAtIndex:tapped.tag - 51];
        [self updateInsideScrollView];
    }
    else
    {
        tapped.layer.borderColor = [[UIColor redColor] CGColor];
        tapped.layer.borderWidth = 2.0f;
        tapped.layer.shadowColor = [[UIColor redColor] CGColor];
    }
}

- (void)addClicked
{
    Dat *newDat = [NSEntityDescription
                insertNewObjectForEntityForName:@"Dat"
                inManagedObjectContext:mainDelegate.managedObjectContext];
    newDat.datId = [NSNumber numberWithInteger:_dats.count + 1];
    newDat.title = [NSString stringWithFormat:@"Dat %lu", _dats.count + 1];
    newDat.message = @" Click here to change de Dat's message";
    
    [_dats insertObject:newDat atIndex:0];
    [self updateScrollView];
    [mainDelegate saveContext];
}

- (void)sendMsgClicked
{
    NSLog(@"Sending msg for view %i", currentPage);
}

- (void)clockClicked
{
    NSLog(@"Clock for view %i", currentPage);
}

- (void)deleteClicked
{
    for (Recipient *recipient in ((Dat*)_dats[currentPage]).recipients)
        [mainDelegate.managedObjectContext deleteObject:recipient];
    [mainDelegate.managedObjectContext deleteObject:_dats[currentPage]];
    [mainDelegate saveContext];
    
    [_dats removeObjectAtIndex:currentPage];
    [self updateScrollView];
}

#pragma mark -
#pragma mark - ABAddressBook

- (void)addRecipientTapped:(UIGestureRecognizer*)gesture
{
    __block bool cancel = NO;
    NSMutableArray *contacts = [NSMutableArray new];
    
    if (_contacts.count == 0)
    {
        [MMProgressHUD setProgressViewClass:[MMRadialProgressView class]];
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleBalloon];
        [[MMProgressHUD sharedHUD] setOverlayMode:MMProgressHUDWindowOverlayModeGradient];
        [[[MMProgressHUD sharedHUD] overlayView] setOverlayColor:[[UIColor whiteColor] CGColor]];
        [MMProgressHUD showDeterminateProgressWithTitle:@"Loading contacts ..." status:nil confirmationMessage:@"Cancel ?" cancelBlock:^{
            [MMProgressHUD dismissWithError:@"Loading canceled"];
            cancel = YES;
        }];
        
        [[MMProgressHUD sharedHUD] setDismissAnimationCompletion:^{
            NSLog(@"I've been dismissed!");
            if (cancel == NO)
            {
                _contacts = [[NSArray alloc] initWithArray:contacts];
                PickContactController *pcc = [self.storyboard instantiateViewControllerWithIdentifier:@"PickContactController"];
                pcc.contacts = contacts;
                pcc.dat = _dats[currentPage];
                [UIView animateWithDuration:0.35f animations:^{
                    [[[UIApplication sharedApplication] keyWindow] viewWithTag:40].alpha = 0.0f;
                }];
                [self presentViewController:pcc animated:YES completion:nil];
            }
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CFErrorRef *error = nil;
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
            
            __block BOOL accessGranted = NO;
            if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
                dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    accessGranted = granted;
                    dispatch_semaphore_signal(sema);
                });
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                
            }
            else { // we're on iOS 5 or older
                accessGranted = YES;
            }
            
            if (accessGranted) {
                ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
                NSArray* allPeople = (__bridge NSArray*)ABAddressBookCopyArrayOfAllPeople(addressBook);
                CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
                
                for (int i = 0; i < nPeople; i++)
                {
                    if (cancel == NO)
                    {
                        ABRecordRef person = (__bridge ABRecordRef)(allPeople[i]);
                        NSString* firstName = (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
                        NSString* lastName = (__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
                        
                        NSData  *imgData = (__bridge NSData *)ABPersonCopyImageData(person);
                        UIImage *image = [UIImage imageWithData:imgData];
                        if (!image) {
                            image = [UIImage imageNamed:@"menuUser.png"];
                        }
                        
                        NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
                        
                        ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
                        for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++) {
                            
                            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
                            NSString *phoneNumber = (__bridge NSString *) phoneNumberRef;
                            [phoneNumbers addObject:phoneNumber];
                        }
                        
                        if (phoneNumbers.count > 0)
                        {
                            NSDictionary *contact = @{@"fullname" : [NSString stringWithFormat:@"%@ %@", firstName != nil ? firstName : @"", lastName != nil ? lastName : @""],
                                                      @"picture" : image,
                                                      @"phoneNumber" : phoneNumbers[0]
                                                      };
                            [contacts addObject:contact];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MMProgressHUD updateProgress:(((i * 100.f) / nPeople)) / 100.f];
                        });
                    }
                    else
                    {
                        return;
                    }
                }
            }
            else
            {
                NSLog(@"Cannot fetch Contacts :( ");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cancel == NO)
                {
                    [MMProgressHUD dismissWithSuccess:@"Done!"];
                }
            });
        });
    }
    else
    {
        PickContactController *pcc = [self.storyboard instantiateViewControllerWithIdentifier:@"PickContactController"];
        pcc.contacts = _contacts;
        pcc.dat = _dats[currentPage];
        [UIView animateWithDuration:0.35f animations:^{
            [[[UIApplication sharedApplication] keyWindow] viewWithTag:40].alpha = 0.0f;
        }];
        [self presentViewController:pcc animated:YES completion:nil];
        
    }
}

@end
