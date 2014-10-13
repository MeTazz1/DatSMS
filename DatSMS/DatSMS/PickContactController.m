//
//  PickContactController.m
//  DatSMS
//
//  Created by Christophe Dellac on 10/9/14.
//  Copyright (c) 2014 Christophe Dellac. All rights reserved.
//

#import "PickContactController.h"
#import "Recipient.h"
#import "AppDelegate.h"

@interface PickContactController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end

@implementation PickContactController

@synthesize contacts = _contacts;
@synthesize dat;

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    selectedIndex = [NSMutableArray new];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];

    UILabel *contactLoadedLabel = (UILabel*)[self.view viewWithTag:1];
    contactLoadedLabel.text = [NSString stringWithFormat:@"%lu contact loaded", (unsigned long)_contacts.count];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(0, 0, 42, 42);
    addBtn.center = CGPointMake(40, 60);
    addBtn.tag = 40;
    addBtn.alpha = 0.0f;
    [addBtn setBackgroundImage:[UIImage imageNamed:@"menuClose.png"] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:addBtn];
    [UIView animateWithDuration:0.35f animations:^{
        addBtn.alpha = 1.0f;
    }];
    
    UIButton *acceptBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    acceptBtn.frame = CGRectMake(0, 0, 42, 42);
    acceptBtn.center = CGPointMake(self.view.frame.size.width - 40, 60);
    acceptBtn.tag = 41;
    acceptBtn.alpha = 0.0f;
    [acceptBtn setBackgroundImage:[UIImage imageNamed:@"menuSelect.png"] forState:UIControlStateNormal];
    [acceptBtn addTarget:self action:@selector(acceptTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:addBtn];
    [self.view addSubview:acceptBtn];
}

- (void)dismissView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)acceptTapped
{
    for (NSNumber *index in selectedIndex)
    {
        BOOL exist = NO;
        for (Recipient *recipient in dat.recipients)
        {
            if ([recipient.phoneNumber isEqualToString:[_contacts[[index intValue]] objectForKey:@"phoneNumber"]])
                exist = YES;
        }
        if (exist == NO)
        {
            NSDictionary *recipe = _contacts[[index intValue]];
            Recipient *newRecip = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"Recipient"
                                   inManagedObjectContext:((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext];
            newRecip.fullname = [recipe objectForKey:@"fullname"];
            newRecip.phoneNumber = [recipe objectForKey:@"phoneNumber"];
            newRecip.picture = [recipe objectForKey:@"picture"];
            newRecip.datId = dat.datId;
            [dat.recipients addObject:newRecip];
        }
    }
    [(AppDelegate*)[UIApplication sharedApplication].delegate saveContext];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark - TableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([self indexSelected:indexPath.row] == NO)
    {
        ((UIImageView*)[cell viewWithTag:7]).image = [UIImage imageNamed:@"menuSelect.png"];
        [selectedIndex addObject:[NSNumber numberWithInteger:indexPath.row]];
    }
    else
    {
        ((UIImageView*)[cell viewWithTag:7]).image = nil;
        for (NSNumber *i in [selectedIndex copy])
        {
            if ([i intValue] == indexPath.row)
            {
                [selectedIndex removeObject:i];
            }
        }
    }
    [UIView animateWithDuration:0.35f animations:^{
        if (selectedIndex.count == 0)
            [[self view] viewWithTag:41].alpha = 0.0f;
        else
            [[self view] viewWithTag:41].alpha = 1.0f;

    }];
    
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    cell.backgroundColor = [UIColor clearColor];
    NSDictionary *recipient = _contacts[indexPath.row];
    ((UILabel*)[cell viewWithTag:5]).text = [recipient objectForKey:@"fullname"];
    ((UILabel*)[cell viewWithTag:4]).text = [recipient objectForKey:@"phoneNumber"];
    ((UIImageView*)[cell viewWithTag:6]).image = [recipient objectForKey:@"picture"];
    ((UIImageView*)[cell viewWithTag:6]).clipsToBounds = YES;
    ((UIImageView*)[cell viewWithTag:6]).layer.masksToBounds = YES;
    ((UIImageView*)[cell viewWithTag:6]).layer.cornerRadius = 37.5f;
    ((UIImageView*)[cell viewWithTag:6]).layer.borderColor = [[UIColor whiteColor] CGColor];
    ((UIImageView*)[cell viewWithTag:6]).layer.borderWidth = 2.0f;
    
    ((UIImageView*)[cell viewWithTag:7]).image = [self indexSelected:indexPath.row] == YES ? [UIImage imageNamed:@"menuSelect.png"] : nil;

    return cell;
}

- (BOOL)indexSelected:(NSInteger)index
{
    for (NSNumber *i in selectedIndex)
        if ([i intValue] == index)
            return YES;
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (int)_contacts.count;
}


@end
