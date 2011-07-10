
#import <Cocoa/Cocoa.h>


@class Project;


@interface PaneViewController : NSViewController {
@protected
    Project             *_project;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil project:(Project *)project;

@property(nonatomic, readonly) NSString *uniqueId;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, getter=isActive) BOOL active;

- (void)paneWillShow;
- (void)paneDidShow;
- (void)paneWillHide;
- (void)paneDidHide;

@end